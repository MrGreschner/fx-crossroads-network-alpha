extends Node
const C=preload("res://scripts/waylight_catalog.gd")
const P=preload("res://scripts/waylight_progress.gd")
var game:Node2D
var progress=P.new()
var expedition=preload("res://scripts/waylight_expedition.gd").new()
var overcharge=preload("res://scripts/waylight_overcharge.gd").new()
var combat=preload("res://scripts/waylight_combat.gd").new()
var window:CanvasLayer
var launching=false
var kind=""
var realm=""
var settled=false
var save_timer=0.0
var last_result=""
var rng=RandomNumberGenerator.new()
var utc_for_test=-1.0
func setup(owner:Node2D)->void:
 game=owner;progress.legacy=game.legacy;progress.state();expedition.manager=self;overcharge.manager=self;combat.manager=self;rng.randomize()
 for pair in [["waylight_reed","reed_stalker"],["waylight_crab","sluice_crab"]]:
  var definition:Dictionary=game.enemy_types.get(pair[1],{}).duplicate(true)
  definition["id"]=pair[0];definition["name"]=str(definition.get("name",pair[1]))+" echo";definition["expansion_only"]=false
  game.enemy_types[pair[0]]=definition;game.load_sprite_pair(str(definition.get("sprite",pair[1])))
 preload("res://scripts/between_actors.gd").install(game,false)
 preload("res://scripts/veilbound_pursuers.gd").install(game,false)
 game.realms["between"]=JSON.parse_string(FileAccess.get_file_as_string("res://content/regions/between.json"))
func now()->float:return utc_for_test if utc_for_test>=0 else Time.get_unix_time_from_system()
func today()->int:return C.day_number(now())
func ticket()->Dictionary:return progress.state().run
func special()->bool:return not kind.is_empty()
func between()->bool:return kind in ["between","attunement"]
func active()->bool:return special() and not settled and game.mode=="run"
func launch(type:String,tier:int=1)->String:
 if game.mode!="town":return "Return to town before starting an expedition."
 var id=C.featured(today()) if type=="overcharge" else "between"
 var issue=progress.pay_ticket(type,id,tier,rng.randi_range(1,2000000000),today())
 if not issue.is_empty():return issue
 return resume()
func resume()->String:
 if game.mode!="town" or ticket().is_empty():return "No saved expedition to resume."
 if ticket().has("coop"):return launch_coop(str(ticket().kind),int(ticket().tier),ticket())
 # Legacy guardian tickets retain their haul as a normal Between expedition.
 # Earned attunement is grandfathered; only fresh solo seal trials can grant it now.
 if str(ticket().kind)=="attunement" and not ticket().has("trial_version"):
  ticket().kind="between";progress.save()
 var data=ticket().duplicate(true)
 if not game.characters.has(str(data.hero)):return "That expedition hero is missing. Restore their custom project before resuming."
 if is_instance_valid(window):window.close()
 game.legacy.close()
 game.selected_character=str(data.hero);kind="";settled=false;last_result="";combat.reset()
 launching=true;game.start_run(false,str(data.realm));launching=false
 if game.mode!="run" or game.region_id!=str(data.realm):return "Could not start. Your paid expedition is retained for Resume."
 kind=str(data.kind);realm=str(data.realm)
 if between():expedition.start();game.boss_spawned=true
 else:overcharge.start()
 if not data.checkpoint.is_empty():restore(data.checkpoint)
 else:game.health=game.max_health()
 game.message="THE BETWEEN • gather Waylight and return to the entrance to bank it" if between() else "OVERCHARGED • "+overcharge.description()
 if type_trial():game.message="ATTUNEMENT • level 10 • collect six Crossing Seals from Wardens in rings 3–5, then extract"
 game.message_time=7;game.mobile.reset_controls();game.update_camera();checkpoint();return ""
func type_trial()->bool:return kind=="attunement" and int(ticket().get("trial_version",0))==2
func forfeit()->String:
 if ticket().is_empty():return "No expedition to forfeit."
 if ticket().has("coop"):return preload("res://network/expedition_profile.gd").forfeit(game)
 if kind.is_empty():
  # Recover the last bankable haul from a suspended expedition without simulating it.
  var t=ticket();var old_kind=kind;kind=str(t.kind)
  var world=t.checkpoint.get("world",{});var text=progress.settle(false,int(world.get("carried",0)),int(world.get("farthest",0)),false,0);kind=old_kind;return text
 return finish(false)
func finish(won:bool)->String:
 if settled:return last_result
 settled=true
 last_result=progress.settle(won,expedition.carried if between() else 0,expedition.farthest if between() else 0,expedition.guardian if between() else false,overcharge.completed() if kind=="overcharge" else 0,expedition.trial_report() if kind=="attunement" else {"conclave":overcharge.conclave.completed()} if kind=="overcharge" else {})
 return last_result
func entering(id:String)->void:
 if id=="town" and special():
  if not settled:game.message=finish(false);game.message_time=8
  kind="";realm="";settled=false;combat.reset()
func started()->void:
 combat.reset()
 if game.mode=="run":game.health=game.max_health()
func spawn(type:String,p:Vector2,factor:float,boss:bool)->Dictionary:
 type=preload("res://scripts/between_actors.gd").type_for(type) if between() else type
 var def:Dictionary=game.enemy_types.get(type,{})
 game.load_sprite_pair(str(def.get("sprite",type)))
 game.next_enemy_uid+=1
 var hp=(240.0 if boss else float(def.get("health",65)))*factor
 return {"pos":p,"hp":hp,"max_hp":hp,"type":type,"boss":boss,"uid":game.next_enemy_uid,"attack_timer":1.2,"secondary_timer":3.5,"windup":0.0,"sprite":"bramble_boss" if boss else str(def.get("sprite",type))}
func step(delta:float)->void:
 if game.mode!="run" or game.menu!="":return
 combat.step(delta)
 if game.menu!="":return
 if active():
  if between():expedition.step(delta)
  else:overcharge.step(delta)
  save_timer+=delta
  if save_timer>=5:save_timer=0;checkpoint()
func defeated(foe:Dictionary)->bool:
 if kind=="overcharge":overcharge.conclave.defeated(foe)
 combat.killed()
 if active() and between():expedition.defeated(foe);return true
 return false
func incoming(amount:float,blocked:bool)->float:
 if active() and between() and game.position_in_world.distance_to(expedition.ORIGIN)<105:return 0
 if active():amount*=1+(.15*int(ticket().tier) if kind=="overcharge" else .08*expedition.farthest)
 return combat.incoming(amount,blocked)
func checkpoint()->void:
 if not active() or ticket().is_empty() or game.health<=0:return
 var values={}
 for key in ["position_in_world","health","level","highest_level","experience","kills","gold","run_time","bonus_health","bonus_damage","bonus_speed","upgrade","mastery","inventory","boss_spawned","boss_defeated","boss_split_triggered","next_enemy_uid","dealt_damage","damage_taken","bounty_earned"]:values[key]=pack(game.get(key))
 values["enemies"]=pack(game.enemies);values["world"]=pack(expedition.snapshot() if between() else overcharge.snapshot());values["food"]=game.provisions.packed
 ticket()["checkpoint"]=values;progress.save()
func restore(v:Dictionary)->void:
 for key in ["position_in_world","health","level","highest_level","experience","kills","gold","run_time","bonus_health","bonus_damage","bonus_speed","upgrade","mastery","boss_spawned","boss_defeated","boss_split_triggered","next_enemy_uid","dealt_damage","damage_taken","bounty_earned"]:
  if v.has(key):game.set(key,unpack(v[key]))
 game.inventory.assign(v.get("inventory",[]));game.enemies.assign(unpack(v.get("enemies",[])))
 if between():
  for foe in game.enemies:preload("res://scripts/between_actors.gd").normalize(foe)
 game.provisions.packed=str(v.get("food",""));game.provisions.save()
 # Cancel transient attacks safely; cooldown floor prevents reload-to-repeat specials.
 game.cooldowns={"primary":1.0,"secondary":5.0,"special":8.0};game.invulnerable_time=1.0
 if between():expedition.restore(unpack(v.get("world",{})))
 else:overcharge.restore(unpack(v.get("world",{})))
 game.health=clampf(float(game.health),1,game.max_health());game.update_camera()
func pack(v:Variant)->Variant:
 if v is Vector2 or v is Vector2i:return {"vector2":[v.x,v.y]}
 if v is Color:return {"rgba":v.to_html()}
 if v is Dictionary:
  var d={}
  for key in v:d[str(key)]=pack(v[key])
  return d
 if v is Array:
  var a=[]
  for value in v:a.append(pack(value))
  return a
 if v is StringName:return str(v)
 if v is String or v is bool or v is int or v is float or v==null:return v
 return null
func unpack(v:Variant)->Variant:
 if v is Dictionary:
  if v.size()==1 and v.get("vector2") is Array and v.vector2.size()==2:return Vector2(float(v.vector2[0]),float(v.vector2[1]))
  if v.size()==1 and v.get("rgba") is String:return Color(v.rgba)
  var d={}
  for key in v:d[key]=unpack(v[key])
  return d
 if v is Array:
  var a=[]
  for value in v:a.append(unpack(value))
  return a
 return v
func open(tab:int=0)->void:
 if game.mode!="town":return
 if is_instance_valid(window):window.close()
 window=preload("res://scripts/waylight_ui.gd").new();game.add_child(window);window.setup(self,tab)
func draw_world(g:Node2D,camera:Vector2)->void:
 combat.draw_on(g,camera)
 if kind=="overcharge" and game.mode=="run":overcharge.draw_on(g,camera)
func draw_fog(g:Node2D,camera:Vector2)->void:
 if between() and game.mode=="run":expedition.draw_fog(g,camera)
func draw_hud(g:Node2D)->void:
 if not active():
  if game.mode=="run" and not game.practice and game.menu.is_empty():
   var assisted=not combat.items().is_empty()
   if assisted or bool(progress.state().fair):
    g.draw_rect(Rect2(24,94,295,25),Color(.04,.10,.14,.90));g.draw_string(g.font,Vector2(34,112),"RELICS ACTIVE • separate time records" if assisted else "COMPETITION • relics disabled",HORIZONTAL_ALIGNMENT_LEFT,-1,13,Color("#dccdab"))
  return
 var objective_top=preload("res://scripts/hud_layout.gd").objective_top(g)
 var box=Rect2(24,objective_top+(60 if kind=="overcharge" and game.adventure.immersive.active else 0),390,79);g.draw_rect(box,Color(.04,.10,.14,.94));g.draw_rect(box,Color("#86bdb7"),false,1)
 if between():
  var cell=expedition.current;var home=(expedition.ORIGIN-game.position_in_world)
  g.draw_string(g.font,box.position+Vector2(12,23),"WAYLIGHT %d carried • %d banked" % [expedition.carried,progress.state().shards],HORIZONTAL_ALIGNMENT_LEFT,-1,17,Color("#e8dfa8"))
  g.draw_string(g.font,box.position+Vector2(12,46),"Ring %d • %s" % [maxi(absi(cell.x),absi(cell.y)),expedition.THEMES[expedition.chunks[expedition.key(cell)].theme].name],HORIZONTAL_ALIGNMENT_LEFT,-1,15,Color("#a8d1ca"))
  g.draw_string(g.font,box.position+Vector2(12,66),"Seals %d/6 • %02d:%02d • return to extract" % [expedition.seals(),int(expedition.trial_seconds)/60,int(expedition.trial_seconds)%60] if expedition.trial() else "Entrance: %dm • extraction keeps all; defeat banks half" % int(home.length()/32),HORIZONTAL_ALIGNMENT_LEFT,-1,13,Color("#c1d3d8"))
  expedition.draw_map(g);game.adventure.pursuers.draw_hud(g)
  var p=Vector2(g.VIEW.x-104,150);g.draw_line(p,p+home.normalized()*22,Color("#f2dfa4"),4,true);g.draw_string(g.font,p+Vector2(-35,35),"HOME",HORIZONTAL_ALIGNMENT_LEFT,-1,13,Color("#f2dfa4"))
 else:
  g.draw_string(g.font,box.position+Vector2(12,23),"OVERCHARGE TIER %d • %d / %d optional events" % [ticket().tier,overcharge.completed(),overcharge.events.size()],HORIZONTAL_ALIGNMENT_LEFT,-1,16,Color("#e8d2a9"))
  g.draw_string(g.font,box.position+Vector2(12,45),"Relic eligible" if ticket().eligible else "Attunement required for relic drops",HORIZONTAL_ALIGNMENT_LEFT,-1,14,Color("#b9d6d2"))
  var target=Vector2.ZERO;var closest=INF
  for event in overcharge.events:
   if event.state!="complete" and event.at.distance_to(game.position_in_world)<closest:target=event.at;closest=event.at.distance_to(game.position_in_world)
  g.draw_string(g.font,box.position+Vector2(12,65),("CONCLAVE CACHE SECURED • finish the realm" if overcharge.conclave.completed() else "CONCLAVE • %d / 4 champions defeated" % overcharge.conclave.state.get("dead",[]).size()) if overcharge.conclave.state.get("members",[]).size()==4 else "Next optional event: %dm" % int(closest/32) if closest<INF else "Optional events complete • defeat the realm boss",HORIZONTAL_ALIGNMENT_LEFT,-1,13,Color("#c1d3d8"))
  if closest<INF:g.draw_line(box.position+Vector2(360,48),box.position+Vector2(360,48)+(target-game.position_in_world).normalized()*18,Color("#d8b4ea"),3,true)
func _notification(what:int)->void:
 if what==NOTIFICATION_APPLICATION_FOCUS_OUT and game!=null:checkpoint()

func dev_kit()->void:
 if not bool(game.legacy.data.get("teacher",false)):return
 var s=progress.state();s.shards=300;s.dust=50;s.attuned=true;s.best_ring=6;s.expeditions=maxi(1,int(s.expeditions))
 for type in C.RELICS:
  var id="preview-"+str(type)
  if not progress.item(id).is_empty():continue
  s.relics.append({"id":id,"type":str(type),"value":C.RELICS[type].range[1],"rank":0,"stat":"power","roll":2,"tier":1,"source":"fishing" if type=="master_fisher" else "grove"})
 progress.save()

func launch_coop(type:String,tier:int=1,saved:Dictionary={})->String:
 if type=="attunement":return "Attunement Challenge is a solo expedition. Explore The Between together in its normal mode."
 if game.mode!="town":return "Return to town before starting co-op."
 var gate=progress.entry_issue(type) if saved.is_empty() else ""
 if not gate.is_empty():return gate
 if not ticket().is_empty() and saved.is_empty():return "Resume or forfeit your current expedition first."
 if is_instance_valid(window):window.close()
 game.legacy.close()
 var root=get_tree().root
 root.set_meta("fx_mode","coop");root.set_meta("fx_realm",type);root.set_meta("fx_expedition_tier",tier);root.set_meta("fx_hero",str(saved.get("hero",game.selected_character)))
 if not saved.is_empty():root.set_meta("fx_coop_resume",saved.coop.duplicate(true))
 get_tree().change_scene_to_file("res://network/client.tscn")
 return ""

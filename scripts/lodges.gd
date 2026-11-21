extends Node
const Grounds=preload("res://scripts/challenge_grounds308.gd")
const C=preload("res://scripts/lodge_catalog.gd")
const UI=preload("res://scripts/studio_ui.gd")
const CHALLENGE=Vector2(-1030,540)
const GATHER=Vector2(2800,655)
const APPLE_TREE=GATHER+Vector2(-200,15)
const CHEMIST=Vector2(-100,1680)
var game:Node
var active=false
var challenge_type=0
var variant=0
var weekly_key=""
var elapsed=0.0
var wave=0
var spawn_clock=0.0
var hit_baseline=0.0
var hazards:Array=[]
var hazard_clock=0.0
var courier=Vector2.ZERO
var courier_hp=100.0
var courier_distance=0.0
var courier_checkpoints:PackedFloat32Array
var boss_time=0.0
var grounds:RefCounted
var end_button:Button
var rule=0
var saved_gold=100
var end_ui:CanvasLayer
var clock_label:Label
var progress:ProgressBar
var notice=""
var page=""
var challenge_page=0
var refresh_clock=0.0
var ui_clock:Label
var job_widgets:Array=[]
var visual_textures:Dictionary={}
var tree_shake=0.0
var tree_drop=0.0
var uid=980000
func setup(owner:Node)->void:
 game=owner
 for id in C.INGREDIENTS.keys()+C.RECIPES.keys():visual_textures[id]=preload("res://scripts/source_art.gd").texture("res://assets/lodges/"+id+".svg")
 visual_textures.apple_tree=preload("res://scripts/town_nature243.gd").texture("apple")
 for id in ["gather","apothecary"]:visual_textures[id]=preload("res://scripts/town_shops242.gd").texture(id)
 visual_textures.challenge=preload("res://scripts/town_landmarks241.gd").texture("lodge")
func state()->Dictionary:return game.legacy.lodge_economy.state()
func blocked(p:Vector2)->bool:
 if Rect2(APPLE_TREE-Vector2(15,36),Vector2(30,32)).has_point(p):return true
 if Rect2(CHALLENGE-Vector2(225,240),Vector2(450,195)).has_point(p):return true
 for entry in [CHALLENGE,GATHER,CHEMIST]:
  if Rect2(entry-Vector2(120,230),Vector2(240,195)).has_point(p):return true
 return false
func interact()->bool:
 if game.position_in_world.distance_to(APPLE_TREE)<65:
  game.hint="E • Knock on apple tree (20% chance • empty food slot)"
  if Input.is_action_just_pressed("interact"):knock_tree()
  return true
 for pair in [[CHALLENGE,"challenge","Challenge Lodge"],[GATHER,"gather","Gatherers’ Lodge"],[CHEMIST,"apothecary","Willowglass Apothecary"]]:
  if game.position_in_world.distance_to(pair[0])>85:continue
  game.hint="E • "+str(pair[2])
  if Input.is_action_just_pressed("interact"):open(str(pair[1]))
  return true
 return false
func knock_tree()->void:
 if not game.provisions.packed.is_empty():game.provisions.garden_notice("Empty your food slot before knocking. Your current food is safe.");return
 var s=state();var now=game.legacy.lodge_economy.now()
 if now<float(s.get("apple_next",0)):game.provisions.garden_notice("Let the tree rest • %d seconds until another knock." % ceili(float(s.apple_next)-now));return
 tree_shake=.6
 s.apple_next=now+300;game.legacy.lodge_economy.save()
 if randf()<.20:
  tree_drop=1.0
  game.provisions.packed="lodge_apple";game.provisions.paid=0;game.provisions.save();game.provisions.garden_notice("An apple dropped! Packed in your food slot • restores 20 HP once.")
  game.add_float_text(APPLE_TREE-Vector2(20,70),"APPLE!",Color("#c6e6a0"))
 else:game.provisions.garden_notice("A few leaves fell… no apple. Try again in 5 minutes.")
func image(parent:Node,id:String,size:Vector2=Vector2(48,48))->void:
 var pic=TextureRect.new();pic.texture=visual_textures.get(id);pic.custom_minimum_size=size;pic.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;pic.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;parent.add_child(pic)
func label(parent:Node,text:String,size:int=17)->Label:
 var l=game.presentation.label(parent,text,size);l.size_flags_horizontal=Control.SIZE_EXPAND_FILL;return l
func button(parent:Node,text:String,callback:Callable)->Button:return game.presentation.button(parent,text,callback)
func card(parent:Node,title:String,text:String="")->VBoxContainer:return UI.card(parent,title,text)
func result(text:String)->void:notice=text;open(page)
func open(which:String)->void:
 page=which;job_widgets.clear();ui_clock=null
 game.presentation.window({"challenge":"CHALLENGE LODGE","gather":"GATHERERS’ LODGE","apothecary":"WILLOWGLASS APOTHECARY"}[page],"lodge_"+page)
 var body=game.presentation.content;var header=HBoxContainer.new();body.add_child(header);image(header,page,Vector2(70,65) if page=="challenge" else Vector2(120,110))
 label(header,{"challenge":"Realm champion duels and five challenge grounds • level 10, all skills ready. Earn medals and cosmetic rewards. Gear and food are set aside until you return.","gather":"Send a crew, let it forage while you play, then claim its findings. Trips continue while this device is closed. Rare seeds are a chance, never guaranteed.","apothecary":"Turn gathered ingredients into single-use potions. Carry one potion in its own consumable slot, alongside three equipment items. Click the bottle or press 4 during combat."}[page],19)
 if page=="challenge" and challenge_page>=C.TYPES.size()+1:header.hide()
 if not notice.is_empty():label(body,notice,18).modulate=Color("#eed18e")
 var nav=HBoxContainer.new();body.add_child(nav)
 if page!="challenge":
  for item in [["gather","Gathering"],["apothecary","Brewing"]]:button(nav,item[1],open.bind(item[0]))
 if page=="challenge":challenge_menu(body)
 elif page=="gather":gather_menu(body)
 else:brew_menu(body)
func challenge_menu(body:Node)->void:
 # Navigation is outside the details scroll, so every style is visible immediately.
 var scroll=body.get_parent();var frame=scroll.get_parent()
 var nav=GridContainer.new();nav.name="ChallengeCategories";nav.columns=3;nav.add_theme_constant_override("h_separation",8);nav.add_theme_constant_override("v_separation",6);frame.add_child(nav);frame.move_child(nav,1)
 var titles=["This week's trials"]
 for spec in C.TYPES:titles.append(str(spec.name))
 titles.append("Hero Challenges");titles.append("Hero Goals");titles.append("Hero Journeys")
 for n in titles.size():
  var choose=button(nav,titles[n],func():challenge_page=n;call_deferred("open","challenge"));choose.toggle_mode=true;choose.button_pressed=challenge_page==n;choose.custom_minimum_size.y=35;choose.size_flags_horizontal=Control.SIZE_EXPAND_FILL;choose.add_theme_font_size_override("font_size",15)
  if n==challenge_page:UI.accent(choose)
 if challenge_page==C.TYPES.size()+1:preload("res://scripts/hero_unlocks371.gd").draw_menu(game,body);return
 if challenge_page==C.TYPES.size()+3:preload("res://scripts/hero_journeys373.gd").draw_menu(game,body);return
 if challenge_page==C.TYPES.size()+2:preload("res://scripts/hero_goals372.gd").draw_menu(game,body);return
 var record=state()
 label(body,"Medal points: %d    •    Bronze 1 / Silver 2 / Gold 3" % game.legacy.lodge_economy.medal_total(),16)
 if challenge_page==0:
  var done=record.weekly.get(C.week(),[]).size()
  label(body,"THIS WEEK • %d / 3 completed" % done,22)
  label(body,"Complete these three trials for the Weekly Lantern cosmetic until Sunday. Choose any of the five styles above for more adventures.",16)
  for task in C.weekly():
   var row=HBoxContainer.new();body.add_child(row);var spec=C.TYPES[int(task.type)]
   label(row,str(spec.name)+" • "+["Gentle","Adventurous","Daring"][int(task.variant)],17)
   button(row,"Play again" if str(task.key) in record.weekly.get(C.week(),[]) else "Play trial",start.bind(int(task.type),int(task.variant),str(task.key)))
 else:
  var index=challenge_page-1;var spec:Dictionary=C.TYPES[index]
  var box=card(body,str(spec.name),str(spec.text));label(box,"Recommended: "+str(spec.recommend),16)
  label(box,"CHOOSE YOUR INTENSITY",15)
  var row=HBoxContainer.new();box.add_child(row)
  for v in 3:
   var medals=int(record.medals.get(str(spec.id)+":"+str(v),0));var action=button(row,["Gentle","Adventurous","Daring"][v]+(" • "+["","Bronze","Silver","Gold"][medals] if medals else ""),start.bind(index,v,""));action.size_flags_horizontal=Control.SIZE_EXPAND_FILL
  var place:Dictionary=Grounds.catalog_entry(index)
  label(box,str(place.title),19).modulate=Color("#f1d69c")
  var art=TextureRect.new()
  art.texture=Grounds.preview(index)
  art.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
  art.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
  art.custom_minimum_size=Vector2(0,230)
  box.add_child(art)
 var rewards=HBoxContainer.new();body.add_child(rewards)
 button(rewards,"Weekly reward progress",game.legacy.weekly.open_board)
 button(rewards,"Your earned cosmetics",game.legacy.cosmetics.open_picker)
func trial_card(body:Node,index:int,v:int,key:String)->void:
 var box=card(body,str(C.TYPES[index].name)+" • "+["Gentle","Adventurous","Daring"][v],str(C.TYPES[index].text))
 var done=key in state().weekly.get(C.week(),[])
 button(box,"Completed • play again" if done else "Play featured trial",start.bind(index,v,key))
func pantry(parent:Node)->void:
 var row=GridContainer.new();row.columns=3;row.size_flags_horizontal=Control.SIZE_EXPAND_FILL;parent.add_child(row)
 for id in C.INGREDIENTS:
  var box=HBoxContainer.new();box.custom_minimum_size.x=300;box.size_flags_horizontal=Control.SIZE_EXPAND_FILL;row.add_child(box);image(box,id);label(box,str(C.INGREDIENTS[id].name)+"\n"+str(int(state().ingredients.get(id,0))),16)
func gather_menu(body:Node)->void:
 button(body,"Fishing fish bait • use your gathered ingredients",func():game.presentation.close();game.menu="";game.fishing.open_workshop())
 pantry(body);label(body,"YOUR CREWS • "+str(state().jobs.size())+" / "+str(state().get("crew",2))+" busy",22)
 ui_clock=label(body,"",16)
 for index in state().jobs.size():
  var job:Dictionary=state().jobs[index];var box=card(body,str(C.ROUTES[job.route].name));var meter=ProgressBar.new();meter.custom_minimum_size.y=18;box.add_child(meter)
  var text=label(box,"",16);var claim=button(box,"Claim findings",func():result(game.legacy.lodge_economy.claim(index)));job_widgets.append({"job":job,"bar":meter,"text":text,"button":claim})
 label(body,"SEND A CREW",22)
 for id in C.ROUTES:
  var r:Dictionary=C.ROUTES[id];var box=card(body,str(r.name)+" • "+str(int(r.seconds)/60)+" minutes");var row=HBoxContainer.new();box.add_child(row)
  for ingredient in r.finds:image(row,ingredient);label(row,str(r.finds[ingredient])+" × "+str(C.INGREDIENTS[ingredient].name),15)
  label(box,str(int(float(r.chance)*100))+"% chance of a new garden seed",15)
  var send=button(box,"Send crew",func():result(game.legacy.lodge_economy.dispatch(id)));send.disabled=state().jobs.size()>=int(state().get("crew",2))
 if int(state().get("crew",2))<3:
  button(body,"Hire third crew • 8 Willow Bark + 4 Mooncap",func():
   var needs={"willow":8,"mooncap":4}
   if not game.legacy.lodge_economy.can_pay(needs):result("Gather more Willow Bark and Mooncap first.");return
   game.legacy.lodge_economy.pay(needs);state().crew=3;game.legacy.lodge_economy.save();result("A third crew is ready!"))
 label(body,"Seeds discovered: "+str(state().seeds.size())+" / 4 • plant them at the Seed House",17)
 update_timers()
func brew_menu(body:Node)->void:
 pantry(body);label(body,"Apothecary tier "+str(state().tier)+" / 3",22)
 if int(state().tier)<3:
  var text="4 Willow Bark + 3 Sunleaf" if int(state().tier)==1 else "6 Mooncap + 4 Glowwing + 4 Ember Petals"
  button(body,"Upgrade • "+text,func():result(game.legacy.lodge_economy.upgrade()))
 if not state().brew.is_empty():
  var job:Dictionary=state().brew;var box=card(body,"Brewing • "+str(C.RECIPES[job.id].name));var meter=ProgressBar.new();meter.custom_minimum_size.y=18;box.add_child(meter);var text=label(box,"",16);var claim=button(box,"Collect bottle",func():result(game.legacy.lodge_economy.claim_brew()));job_widgets.append({"job":job,"bar":meter,"text":text,"button":claim});update_timers()
 for id in C.RECIPES:
  var recipe:Dictionary=C.RECIPES[id];var box=card(body,str(recipe.name)+" • Tier "+str(recipe.tier),str(recipe.description));var row=HBoxContainer.new();box.add_child(row);image(row,id)
  var costs=[]
  for ingredient in recipe.needs:costs.append(str(recipe.needs[ingredient])+" "+str(C.INGREDIENTS[ingredient].name))
  if recipe.has("fish"):costs.append("1 kept "+str(preload("res://scripts/fishing_catalog.gd").fish()[recipe.fish].name)+" (ordinary, not favourite/displayed)")
  label(row," + ".join(costs)+"\n"+str(int(recipe.seconds))+"s brew • "+str(int(state().potions.get(id,0)))+" bottles stored",16)
  var actions=HBoxContainer.new();box.add_child(actions)
  var brew=button(actions,"Brew bottle",func():result(game.legacy.lodge_economy.brew(id)));brew.disabled=int(state().tier)<int(recipe.tier) or not state().brew.is_empty() or not game.legacy.lodge_economy.can_brew(recipe)
  var pack=button(actions,"Pack for next run",func():result(game.legacy.lodge_economy.pack(game,id)));pack.disabled=int(state().potions.get(id,0))==0 or not preload("res://scripts/supply_slots.gd").can_add(game.loadout,id,game.items)
func update_timers()->void:
 if is_instance_valid(ui_clock):ui_clock.text="Crew trips use real time on this device. Claim each trip once."
 for widget in job_widgets:
  if not is_instance_valid(widget.bar):continue
  var job:Dictionary=widget.job;var remaining=maxf(0,float(job.end)-game.legacy.lodge_economy.now());widget.bar.value=clampf(100*(game.legacy.lodge_economy.now()-float(job.start))/maxf(1,float(job.end)-float(job.start)),0,100);widget.text.text="Ready to collect!" if remaining<=0 else "%d:%02d remaining" % [int(remaining)/60,int(remaining)%60];widget.button.disabled=remaining>0
func start(index:int,v:int,key:String="")->void:
 if active:return
 challenge_type=clampi(index,0,4)
 variant=clampi(v,0,2)
 weekly_key=key
 elapsed=0
 wave=0
 spawn_clock=0
 hazard_clock=0
 hazards.clear()
 courier_hp=100
 courier_distance=0
 boss_time=0
 rule=0
 saved_gold=game.gold
 game.presentation.close()
 game.mistglass_rift.chosen=[]
 game.mistglass_rift.launch()
 if not game.mistglass_rift.active:return
 grounds=Grounds.new()
 grounds.setup(challenge_type)
 active=true
 game.mistglass_rift.end_button.visible=false
 game.inventory.clear()
 game.provisions.packed=""
 game.level=10
 game.highest_level=10
 game.health=game.max_health()
 game.enemies.clear()
 game.region.name=C.TYPES[challenge_type].name
 game.region.size=grounds.layout.size
 game.position_in_world=Grounds.vec(grounds.layout.spawn)
 courier=grounds.trail.sample_baked(0)
 courier_checkpoints.clear()
 if challenge_type==2:
  for site in range(1,grounds.layout.landmarks.size()):
   courier_checkpoints.append(grounds.trail.get_closest_offset(grounds.point(site)))
 hit_baseline=game.damage_taken
 game.obstacles.assign(grounds.colliders)
 game.decorations.clear()
 game.build_scenery()
 game.update_camera()
 build_hud()
 refresh_hud()
 game.message=""
 game.message_time=0
 if challenge_type==0 or challenge_type==3:spawn_group(3)

func trial_bounds()->Rect2:
 return grounds.bounds

func build_hud()->void:
 if is_instance_valid(end_ui):end_ui.queue_free()
 end_ui=CanvasLayer.new();end_ui.layer=59;game.add_child(end_ui)
 clock_label=Label.new();clock_label.position=Vector2(22,165);clock_label.add_theme_font_size_override("font_size",20);clock_label.modulate=Color("#f8dda0");end_ui.add_child(clock_label)
 progress=ProgressBar.new();progress.position=Vector2(22,192);progress.size=Vector2(290,10);progress.show_percentage=false;end_ui.add_child(progress)
 end_button=Button.new()
 end_button.text="End challenge"
 end_button.size=Vector2(170,44)
 UI.apply(end_button)
 end_ui.add_child(end_button)
 end_button.pressed.connect(func():
  var dialog=ConfirmationDialog.new();dialog.title="Leave this challenge?";dialog.dialog_text="This attempt will not earn a medal.";dialog.ok_button_text="Return to lodge";end_ui.add_child(dialog);dialog.confirmed.connect(func():dialog.queue_free();finish(false,true));dialog.canceled.connect(dialog.queue_free);dialog.popup_centered(Vector2i(440,150)))
func spawn_group(count:int)->void:
 var roster=["bramble","moth","bramble"]
 var anchor:Vector2=game.position_in_world
 if challenge_type==2:anchor=grounds.trail.sample_baked(courier_distance+140)
 if challenge_type==4:anchor=grounds.point(mini(wave,2))
 for n in mini(count,14-game.enemies.size()):
  spawn_enemy(str(roster[posmod(wave+n,roster.size())]),false,anchor,n)
 wave+=1

func spawn_point(anchor:Vector2,slot:int,boss:bool)->Vector2:
 var bounds:Rect2=trial_bounds().grow(-24)
 var player:Vector2=game.position_in_world
 var angle=randf()*TAU
 for radius in ([70,130,210,285] if boss or challenge_type==4 else [330,410,265,190]):
  for attempt in 12:
   var candidate=anchor+Vector2.from_angle(angle+float(attempt)*TAU/12+slot*1.5)*radius
   if not bounds.has_point(candidate) or not game.clear_of_obstacles(candidate,28):continue
   if candidate.distance_to(player)<145:continue
   if game.enemies.any(func(foe):return candidate.distance_to(foe.pos)<70):continue
   if game.shot_path_clear(anchor,candidate):return candidate
 # Secondary search handles arrivals near a collider or a very narrow corner.
 for attempt in 36:
  var candidate=player+Vector2.from_angle(angle+float(attempt)*TAU/36)*210
  if bounds.has_point(candidate) and game.clear_of_obstacles(candidate,28):return candidate
 return bounds.get_center()

func spawn_enemy(kind:String,boss:bool,anchor:Vector2,slot:int=0)->void:
 var def:Dictionary=game.enemy_types.get(kind,game.enemy_types.get("bramble",{})).duplicate(true);var sprite=str(def.get("sprite",kind));game.load_sprite_pair(sprite)
 if boss:
  def={"health":260+variant*70,"speed":85+variant*10,"damage":12+variant*2,"behaviour":"ranged","shot_damage":9+variant*2,"shot_speed":210,"shot_cooldown":2.1}
  var names=["Grove Guardian","Quarry Warden","Frostbound Captain"];sprite=["bramble_boss","sunfield_boss","goalie"][mini(wave,2)]
  if not game.art.has(sprite+"_0"):sprite="bramble_boss"
  game.load_sprite_pair(sprite);def.name=names[mini(wave,2)]
 else:def.health=45+variant*14;def.speed=85+variant*10;def.damage=9+variant*2
 var pos:=spawn_point(anchor,slot,boss)
 uid+=1;var hp=float(def.health)
 game.enemies.append({"uid":uid,"type":"boss" if boss else kind,"name":str(def.get("name",kind.capitalize())),"sprite":sprite,"pos":pos,"hp":hp,"max_hp":hp,"boss":boss,"rift":true,"rift_definition":def,"rift_secondary":["stomp","fireball","frostburst"][mini(wave,2)] if boss else "stomp","attack_timer":1.5,"secondary_timer":3.5,"windup":0.0,"strike_flash":0.0})
func boss_round()->void:
 if wave>=3:finish(true);return
 if wave>0:game.health=minf(game.max_health(),game.health+game.max_health()*.15);game.add_float_text(game.position_in_world-Vector2(15,60),"+15% HP",Color("#a5e0b1"))
 game.enemy_shots.clear()
 spawn_enemy("bramble",true,grounds.point(wave))
 wave+=1
func tick(delta:float)->void:
 if not active or not game.menu.is_empty():return
 elapsed+=delta
 if elapsed>300:finish(false);return
 spawn_clock-=delta;hazard_clock-=delta
 if challenge_type==1:
  if not game.enemies.is_empty():boss_time+=delta
  elif wave>=3 or game.position_in_world.distance_to(grounds.point(wave))<=275:boss_round()
  if not active:return
 elif challenge_type==4:
  if game.kills>=12:finish(true);return
  if game.enemies.is_empty() and game.position_in_world.distance_to(grounds.point(mini(wave,2)))<=290:
   spawn_group(6 if wave==2 else 3)
 elif challenge_type==2:
  if courier_hp<=0:finish(false);return
  var length:float=grounds.trail.get_baked_length()
  if game.position_in_world.distance_to(courier)<180:
   courier_distance=minf(length,courier_distance+delta*length/100.0)
   courier=grounds.trail.sample_baked(courier_distance)
  if courier_distance>=length:finish(true);return
  if spawn_clock<=0 and game.enemies.size()<8:
   spawn_clock=12-variant*2
   spawn_group(2)
 else:
  if elapsed>=120:finish(true);return
  if spawn_clock<=0 and game.enemies.size()<10:spawn_clock=9-variant;spawn_group(2)
  if challenge_type==3:
   rule=mini(3,int(elapsed/30))
   if rule==1:
    for shot in game.enemy_shots:shot.speed=310
   elif rule==2 and game.position_in_world.distance_to(grounds.point(1))<65:game.health=minf(game.max_health(),game.health+delta*2)
   elif rule==3:game.haste_time=.2;game.haste_multiplier=1.15
 if challenge_type in [3,4] and hazard_clock<=0:
  hazard_clock=3.2 if challenge_type==4 else 5.0
  hazards.append({"pos":game.position_in_world,"age":0.0,"hit":false,"radius":52+variant*6})
 for i in range(hazards.size()-1,-1,-1):
  hazards[i].age+=delta
  if hazards[i].age>=1.2 and not hazards[i].hit:
   hazards[i].hit=true
   if game.position_in_world.distance_to(hazards[i].pos)<float(hazards[i].radius):game.take_player_damage(10+variant*2,"",{"name":"Lodge ward","attack":"Marked strike","environment":true})
   if not active:return
  if hazards[i].age>1.65:hazards.remove_at(i)
 refresh_hud()

func refresh_hud()->void:
 if not is_instance_valid(clock_label):return
 var objective:String
 var count:float
 var waiting:bool=game.enemies.is_empty()
 match challenge_type:
  1:
   var site:int=mini(wave if waiting else wave-1,2)
   objective=("Reach " if waiting else "Round %d / 3 • " % wave)+grounds.site_name(site)
   count=(wave if waiting else wave-1)*100.0/3.0
  2:
   var next_site:int=courier_checkpoints.size()
   for i in courier_checkpoints.size():
    if courier_distance<courier_checkpoints[i]:
     next_site=i+1
     break
   objective="Courier %d HP • Toward %s" % [maxi(0,int(courier_hp)),grounds.site_name(next_site)]
   if game.position_in_world.distance_to(courier)>=180:objective="Courier waiting • return to its lantern circle"
   count=100*courier_distance/grounds.trail.get_baked_length()
  4:
   objective="%d / 12 defeated" % game.kills
   if waiting:objective+=" • Reach "+grounds.site_name(mini(wave,2))
   count=100*game.kills/12.0
  _:
   objective="%ds to survive" % maxi(0,120-int(elapsed))
   if challenge_type==3:objective+=" • "+["Marked strikes","Quick projectiles","Healing Spring","Fleet feet"][rule]
   count=elapsed/1.2
 clock_label.text=grounds.layout.title+"  /  "+objective
 progress.value=count
 end_button.position=Vector2(game.VIEW.x-190,104)

func courier_hit(from:Vector2,to:Vector2,damage:float)->bool:
 if challenge_type!=2 or courier_hp<=0:return false
 if Geometry2D.get_closest_point_to_segment(courier,from,to).distance_to(courier)>23:return false
 courier_hp=maxf(0,courier_hp-damage)
 return true

func finish(won:bool,abandoned:bool=false)->void:
 if not active:return
 var medal=1
 if won:
  var damage=game.damage_taken-hit_baseline
  medal=3 if damage<=game.max_health()*.2 else 2 if damage<=game.max_health()*.6 else 1
  if challenge_type==2:medal=3 if courier_hp>=90 else 2 if courier_hp>=65 else 1
  if challenge_type==1:medal=3 if boss_time<=120 else 2 if boss_time<=210 else 1
  game.legacy.lodge_economy.medal(str(C.TYPES[challenge_type].id)+":"+str(variant),medal,weekly_key)
 var damage_done=int(game.dealt_damage);var defeated=game.kills;var last=game.last_defeat.duplicate(true);active=false;hazards.clear();grounds=null
 var r=game.mistglass_rift;r.active=false;r.lobs.clear();r.blasts.clear();game.loadout.assign(r.saved_pack);game.provisions.packed=r.saved_food;game.gold=saved_gold;game.inventory.clear();game.enemies.clear();game.enemy_shots.clear();game.bullets.clear();game.allies.clear();game.menu="";game.enter_region("town");game.position_in_world=CHALLENGE+Vector2(0,40);game.update_camera();game.health=game.max_health()
 if is_instance_valid(end_ui):end_ui.queue_free();end_ui=null
 game.presentation.window("CHALLENGE COMPLETE • "+["","BRONZE","SILVER","GOLD"][medal] if won else "CHALLENGE ENDED" if abandoned else "DEFEATED • TRY AGAIN","lodge_result")
 if not won and not abandoned:preload("res://scripts/defeat_credit.gd").card(game.presentation.content,game,last)
 label(game.presentation.content,str(C.TYPES[challenge_type].name)+" • "+str(int(elapsed))+" seconds • "+str(damage_done)+" damage • "+str(defeated)+" defeated",20)
 label(game.presentation.content,"Medals and cosmetics only. Your realm, arena and mastery records are unchanged.",17)
 if won:
  game.journey.cue("victory");label(game.presentation.content,"Gold targets are 120s of combat in Boss Rush, 90+ courier HP, or at most 20% of max HP lost in the other trials.",16)
  if game.legacy.lodge_economy.weekly_earned():label(game.presentation.content,"Weekly Lantern earned! Equip it in Cosmetics.",20)
 button(game.presentation.content,"Play again",start.bind(challenge_type,variant,weekly_key));button(game.presentation.content,"Return to lodge",open.bind("challenge"));button(game.presentation.content,"Explore town",game.presentation.close)
func draw_map(c:Node2D,camera:Vector2)->void:
 var visible:=Rect2(camera,game.VIEW)
 if challenge_type in [1,4] and game.enemies.is_empty():grounds.marker(c,grounds.point(mini(wave,2)),camera)
 if challenge_type==3 and rule==2:grounds.marker(c,grounds.point(1),camera)
 if challenge_type==2:grounds.marker(c,courier,camera)
 for hazard in hazards:
  if not visible.grow(100).has_point(hazard.pos):continue
  var p:Vector2=hazard.pos-camera;var radius=float(hazard.radius);var tint=Color("#e5b96b") if not hazard.hit else Color("#ec826b")
  c.draw_circle(p,radius,Color(tint,.12));c.draw_arc(p,radius,0,TAU,32,tint,2,true)
  c.draw_arc(p,radius+4,-PI*.5,-PI*.5+TAU*minf(1,float(hazard.age)/1.2),24,tint,3,true)
 if challenge_type==2 and visible.grow(180).has_point(courier):
  var p=courier-camera;c.draw_arc(p,180,0,TAU,40,Color(.9,.8,.4,.12),1,true);c.draw_texture_rect(game.art.get("ram_idle",game.art.get("ram_0")),Rect2(p-Vector2(18,36),Vector2(36,48)),false)
  c.draw_rect(Rect2(p+Vector2(-14,10),Vector2(28,8)),Color("#625441"));c.draw_rect(Rect2(p+Vector2(-12,11),Vector2(24*courier_hp/100,5)),Color("#99c68c"));c.draw_rect(Rect2(p+Vector2(13,-18),Vector2(12,14)),Color("#b78f64"))
 if challenge_type==3 and rule==2 and visible.grow(65).has_point(grounds.point(1)):
  var p=grounds.point(1)-camera;c.draw_circle(p,65,Color(.4,.8,.6,.14));c.draw_arc(p,65,0,TAU,32,Color("#91cdae"),2,true)
func draw_town(c:Node2D,camera:Vector2)->void:
 for pair in [[CHALLENGE,"challenge","CHALLENGE LODGE"],[GATHER,"gather","GATHERERS’ LODGE"],[CHEMIST,"apothecary","WILLOWGLASS APOTHECARY"]]:
  var p:Vector2=pair[0]-camera
  if not Rect2(Vector2.ZERO,game.VIEW).grow(330).has_point(p):continue
  var dimensions=Vector2(500,310) if pair[1]=="challenge" else Vector2(320,290) if pair[1]=="gather" else Vector2(290,270)
  if pair[1]=="challenge":preload("res://scripts/town_landmarks241.gd").draw(c,"lodge",camera)
  else:
   preload("res://scripts/town_shops242.gd").draw_rect(c,pair[1],Rect2(p-Vector2(dimensions.x*.5,dimensions.y+15),dimensions))
   game.town_upgrade.label(c,UI.FONT,p+Vector2(0,-10),str(pair[2]))
  c.draw_arc(p,26,0,TAU,24,Color("#e3c888") if game.position_in_world.distance_to(pair[0])<85 else Color(.7,.7,.5,.35),1.5,true)
  if pair[1]=="gather":
   var total=state().jobs.size()
   for n in total:
    var q=p+Vector2(-92+n*34,-46);c.draw_circle(q,5,Color("#b9ce8b"));c.draw_line(q,q+Vector2(0,-10),Color("#e7cf95"),2,true)
  elif pair[1]=="apothecary" and not state().brew.is_empty():
   for n in 3:c.draw_circle(p+Vector2(74+sin(game.visual_clock+n)*5,-95-fposmod(game.visual_clock*13+n*10,34)),3,Color(.7,.85,.7,.4))
 var tree=APPLE_TREE-camera
 if Rect2(Vector2.ZERO,game.VIEW).grow(160).has_point(tree):
  preload("res://scripts/town_nature243.gd").tree(c,"apple",Rect2(tree-Vector2(55,135)+Vector2(sin(game.visual_clock*32)*tree_shake*5,0),Vector2(110,135)),APPLE_TREE)
  if tree_drop>0:
   var apple=tree+Vector2(26,-90+(1-tree_drop)*95);c.draw_circle(apple,5,Color("#df8c69"));c.draw_line(apple-Vector2(0,4),apple-Vector2(-2,8),Color("#7d6d48"),2,true)
  c.draw_arc(tree,20,0,PI,18,Color(.8,.88,.5,.35),1.5,true)
func _process(delta:float)->void:
 tree_shake=maxf(0,tree_shake-delta);tree_drop=maxf(0,tree_drop-delta)
 if active:
  if game.mode!="run" or not game.mistglass_rift.active:
   active=false
   grounds=null
   if is_instance_valid(end_ui):end_ui.queue_free();end_ui=null
   return
  if game.menu.is_empty():tick(delta)
  elif is_instance_valid(end_button):end_button.position=Vector2(game.VIEW.x-190,104)
 refresh_clock-=delta
 if refresh_clock<=0:refresh_clock=1;update_timers()

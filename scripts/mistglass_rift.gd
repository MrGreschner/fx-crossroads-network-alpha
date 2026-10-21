extends CanvasLayer
## Isolated practice battles, chosen from encountered enemy archetypes.
const UI=preload("res://scripts/studio_ui.gd")
var game:Node
var active=false
var panel:PanelContainer
var selected:Dictionary={}
var entries:Array=[]
var total_label:Label
var start_button:Button
var details:VBoxContainer
var spins:Dictionary={}
var chosen:Array=[]
var countdown=0.0
var saved_pack:Array=[]
var saved_food=""
var lobs:Array=[]
var blasts:Array=[]
var end_button:Button
var countdown_label:Label
func setup(owner:Node)->void:
 game=owner;layer=58;countdown_label=Label.new();add_child(countdown_label);countdown_label.add_theme_font_size_override("font_size",54);countdown_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;countdown_label.vertical_alignment=VERTICAL_ALIGNMENT_CENTER;countdown_label.mouse_filter=Control.MOUSE_FILTER_IGNORE;countdown_label.modulate=Color("#ffd786");countdown_label.hide()
func build_end_button()->void:
 end_button=Button.new();end_button.text="END BATTLE";end_button.custom_minimum_size=Vector2(180,44);add_child(end_button);UI.apply(end_button);UI.accent(end_button);end_button.hide()
 end_button.pressed.connect(func():
  var dialog=ConfirmationDialog.new();dialog.title="End this practice battle?";dialog.dialog_text="Return to town. You can replay the same lineup afterwards.";dialog.ok_button_text="End battle";add_child(dialog);dialog.confirmed.connect(func():finish(false,true);dialog.queue_free());dialog.canceled.connect(dialog.queue_free);dialog.popup_centered(Vector2i(450,160)))
func open()->void:
 game.town_services.close();game.presentation.close();game.menu="rift_builder";game.mobile.reset_controls()
 if is_instance_valid(panel):panel.queue_free()
 panel=PanelContainer.new();panel.size=Vector2(1100,670);add_child(panel);UI.apply(panel);UI.enter(panel)
 var col=VBoxContainer.new();panel.add_child(col);var header=HBoxContainer.new();col.add_child(header)
 game.hero_workshop.label(header,"MISTGLASS RIFT • BUILD A BATTLE",25).size_flags_horizontal=Control.SIZE_EXPAND_FILL
 game.hero_workshop.button(header,"Close",close)
 game.hero_workshop.label(col,"Your current hero at level 10 • up to 10 enemies of 3 kinds • practice, no profile rewards",17)
 var query=LineEdit.new();query.placeholder_text="Search encountered enemies…";col.add_child(query)
 var split=HBoxContainer.new();split.size_flags_vertical=Control.SIZE_EXPAND_FILL;col.add_child(split)
 var scroll=ScrollContainer.new();scroll.custom_minimum_size.x=550;scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;split.add_child(scroll);preload("res://scripts/touch_list_scroll.gd").attach(scroll).form_controls=true
 var rows=VBoxContainer.new();rows.size_flags_horizontal=Control.SIZE_EXPAND_FILL;scroll.add_child(rows)
 var right=ScrollContainer.new();right.size_flags_horizontal=Control.SIZE_EXPAND_FILL;right.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;split.add_child(right);details=VBoxContainer.new();details.size_flags_horizontal=Control.SIZE_EXPAND_FILL;right.add_child(details)
 var book=game.town_services.field_guide;book.game=game;entries=book.known_entries();selected.clear();spins.clear()
 for entry in entries:
  var key=entry_key(entry);var row=HBoxContainer.new();row.set_meta("search_name",book.enemy_name(entry).to_lower());rows.add_child(row)
  var b=game.hero_workshop.button(row,book.enemy_name(entry),inspect.bind(entry));b.size_flags_horizontal=Control.SIZE_EXPAND_FILL;b.icon=game.catalog_ui.portrait(entry.realm,entry.kind);b.expand_icon=true;b.add_theme_constant_override("icon_max_width",42);b.custom_minimum_size.y=62;b.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS
  var spin=SpinBox.new();spin.min_value=0;spin.max_value=10;spin.step=1;spin.custom_minimum_size.x=100;row.add_child(spin);spins[key]=spin
  spin.value_changed.connect(func(value:float):choose(entry,int(value)))
 query.text_changed.connect(func(value:String):
  for row in rows.get_children():row.visible=value.strip_edges().is_empty() or value.to_lower() in str(row.get_meta("search_name","")))
 if entries.is_empty():game.hero_workshop.label(rows,"Meet enemies in a realm to add them here. Game Dev mode opens the full catalogue.",19)
 else:inspect(entries[0])
 var footer=HBoxContainer.new();col.add_child(footer);total_label=game.hero_workshop.label(footer,"",18);total_label.size_flags_horizontal=Control.SIZE_EXPAND_FILL
 start_button=game.hero_workshop.button(footer,"Enter the blue rift",begin);UI.accent(start_button);refresh()
func entry_key(entry:Dictionary)->String:return str(entry.kind)
func choose(entry:Dictionary,count:int)->void:
 var key=entry_key(entry);var proposed=selected.duplicate(true)
 if count==0:proposed.erase(key)
 else:proposed[key]={"entry":entry,"count":count}
 var total=0
 for value in proposed.values():total+=int(value.count)
 if total>10 or proposed.size()>3:
  spins[key].set_value_no_signal(int(selected.get(key,{}).get("count",0)));total_label.text="Maximum: 10 enemies / 3 kinds. Reduce another slot first.";return
 selected=proposed;refresh();inspect(entry)
func refresh()->void:
 var total=0
 for value in selected.values():total+=int(value.count)
 total_label.text=str(total)+" / 10 enemies • "+str(selected.size())+" / 3 kinds";start_button.disabled=total==0
func inspect(entry:Dictionary)->void:
 game.hero_workshop.clear(details);var book=game.town_services.field_guide
 var image=TextureRect.new();image.texture=game.catalog_ui.portrait(entry.realm,entry.kind);image.custom_minimum_size=Vector2(100,100);image.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;image.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;details.add_child(image)
 game.hero_workshop.label(details,book.enemy_name(entry),25);game.hero_workshop.label(details,book.description(entry),17)
 game.hero_workshop.label(details,"Rift echoes keep the enemy's base stats and combat role. Scripted realm puzzles and boss phases are represented by a readable sparring pattern here.",15)
func close()->void:
 if is_instance_valid(panel):panel.queue_free();panel=null
 if game.menu=="rift_builder":game.menu=""
 game.mobile.reset_controls()
func begin()->void:
 if selected.is_empty():return
 chosen=selected.values().duplicate(true);launch()
func launch()->void:
 close();lobs.clear();blasts.clear();saved_pack=game.loadout.duplicate();saved_food=game.provisions.packed
 game.realms["mistglass_rift"]=JSON.parse_string(FileAccess.get_file_as_string("res://content/regions/mistglass_rift.json"))
 game.start_run(false,"mistglass_rift");game.region.size=[game.VIEW.x,game.VIEW.y];game.position_in_world=Vector2(game.VIEW.x*.28,game.VIEW.y*.6);game.camera=Vector2.ZERO;active=true;countdown=3;game.level=10;game.highest_level=10;game.boss_spawned=true;game.enemies.clear();game.menu="rift_countdown"
 var slot=0;var book=game.town_services.field_guide;book.game=game
 for value in chosen:
  var entry:Dictionary=value.entry;var def:Dictionary=book.stats(entry);var boss=game.catalog_ui.is_boss(entry.realm,entry.kind)
  var sprite=str(entry.kind).substr(5) if str(entry.kind).begins_with("boss:") else str(def.get("sprite",entry.kind));game.load_sprite_pair(sprite)
  for n in int(value.count):
   var hp=float(def.get("health",250 if boss else 80));if hp<=0:hp=250 if boss else 80
   var enemy={"uid":950000+slot,"type":"boss" if boss else str(entry.kind),"name":book.enemy_name(entry),"sprite":sprite,"pos":Vector2(game.VIEW.x*.58+(slot%3)*100,230+floorf(slot/3.0)*110),"hp":hp,"max_hp":hp,"boss":boss,"rift":true,"rift_definition":def,"rift_secondary":str(game.realms.get(entry.realm,{}).get("boss_secondary","stomp")),"attack_timer":1.0+slot*.1,"secondary_timer":3.0,"windup":0.0,"strike_flash":0.0}
   game.enemies.append(enemy);slot+=1
 game.message="MISTGLASS RIFT • defeat your selected echoes";game.message_time=5
func step(delta:float)->void:
 if not active:return
 for n in range(game.enemy_shots.size()-1,-1,-1):
  if not Rect2(45,190,game.VIEW.x-90,game.VIEW.y-235).has_point(game.enemy_shots[n].pos):game.enemy_shots.remove_at(n)
 step_lobs(delta)
 if not active:return
 for index in game.enemies.size():
  if index>=game.enemies.size():return
  var foe:Dictionary=game.enemies[index];var d:Dictionary=foe.rift_definition;var key=game.adventure.combat.npc_key(foe)
  foe.strike_flash=maxf(0,float(foe.strike_flash)-delta)
  if game.adventure.combat.stunned(key):continue
  var target:Vector2=game.lodges.courier if game.lodges.active and game.lodges.challenge_type==2 and foe.pos.distance_to(game.lodges.courier)<foe.pos.distance_to(game.position_in_world) else game.position_in_world
  var diff:Vector2=target-foe.pos;var distance=diff.length();var behavior=str(d.get("behaviour","melee"));var ranged=game.adventure.combat.ranged_enemy(foe,d)
  var direction=game.adventure.combat.ranged_direction(foe,target) if ranged else diff.normalized()
  game.move_enemy_around_obstacles(foe,direction*float(d.get("speed",90))*game.adventure.combat.speed_factor(key)*delta,bool(d.get("flying",false)))
  foe.pos=foe.pos.clamp(Vector2(70,220),game.VIEW-Vector2(70,65))
  foe.attack_timer=maxf(0,float(foe.attack_timer)-delta);foe.secondary_timer=maxf(0,float(foe.secondary_timer)-delta)
  if behavior=="summoner" and foe.secondary_timer<=0 and game.enemies.size()<16:
   foe.secondary_timer=float(d.get("summon_cooldown",7))
   var child_def=game.enemy_types.get(str(d.get("summon_type","bramble")),game.enemy_types.get("bramble",{})).duplicate(true)
   for n in 2:
    if game.enemies.size()>=16:break
    var hp=float(child_def.get("health",35))
    game.enemies.append({"uid":game.next_enemy_uid,"type":str(d.get("summon_type","bramble")),"name":str(child_def.get("name","Echo minion")),"sprite":str(child_def.get("sprite","bramble")),"pos":(foe.pos+Vector2(50 if n==0 else -50,30)).clamp(Vector2(70,220),game.VIEW-Vector2(70,65)),"hp":hp,"max_hp":hp,"boss":false,"rift":true,"summoned":true,"rift_definition":child_def,"rift_secondary":"stomp","attack_timer":1.2,"secondary_timer":5.0,"windup":0.0,"strike_flash":0.0});game.next_enemy_uid+=1
  if "heal" in str(d.get("custom_attack","")) and foe.secondary_timer<=0:
   foe.secondary_timer=5
   for friend in game.enemies:
    if friend.pos.distance_to(foe.pos)<180:friend.hp=minf(float(friend.max_hp),float(friend.hp)+float(d.get("heal_amount",15)))
  if foe.windup>0:
   foe.windup-=delta
   if foe.windup<=0:
    foe.strike_flash=.35;foe.strike_direction=diff.normalized()
    if distance<175:game.take_player_damage(float(d.get("damage",d.get("boss_damage",15))),"",preload("res://scripts/defeat_credit.gd").resolve(game,key,"Rift echo • shockwave"))
    if not active or not game.menu.is_empty():return
  elif bool(foe.boss) and foe.secondary_timer<=0:
   foe.windup=.85;foe.secondary_timer=4.5
   if foe.rift_secondary in ["fireball","seekerstorm","sunburst","frostburst","sporeburst"]:
    foe.windup=0
    for ray in 6:projectile(foe,Vector2.RIGHT.rotated(ray*TAU/6),float(d.get("damage",16)),220)
  elif foe.attack_timer<=0 and game.stealth_time<=0:
   if ranged and distance<650:
    if d.get("custom_attack","")=="lob":
     lob(foe,game.position_in_world);foe.attack_timer=float(d.get("skill_cooldown",4))
    else:
     projectile(foe,diff.normalized(),float(d.get("shot_damage",d.get("damage",10))),float(d.get("shot_speed",250)));foe.attack_timer=float(d.get("shot_cooldown",2.0))
    foe.strike_flash=.3;foe.strike_direction=diff.normalized()
    if behavior in ["burst_ranged","dual_ranged"]:
     for angle in ([-.18,.18] if behavior=="burst_ranged" else [.16]):projectile(foe,diff.normalized().rotated(angle),float(d.get("damage",10)),250)
   elif distance<70:
    foe.strike_flash=.35;foe.strike_direction=diff.normalized();foe.attack_timer=1.3
    if game.lodges.active and game.lodges.challenge_type==2 and target==game.lodges.courier:game.lodges.courier_hp-=float(d.get("damage",18))
    else:game.take_player_damage(float(d.get("damage",18)),key)
    if not active or not game.menu.is_empty():return
 if game.enemies.is_empty() and not (game.lodges!=null and game.lodges.active):finish(true)
func projectile(foe:Dictionary,direction:Vector2,amount:float,speed:float)->void:
 if preload("res://scripts/ice_projectiles.gd").matches(str(foe.get("type",""))):
  preload("res://scripts/ice_projectiles.gd").fire(game,foe,direction,foe.rift_definition);return
 if game.enemy_shots.size()>=80:return
 game.enemy_shots.append({"credit":preload("res://scripts/defeat_credit.gd").resolve(game,game.adventure.combat.npc_key(foe),"Rift echo • projectile"),"pos":foe.pos,"direction":direction,"damage":amount,"speed":speed,"distance":0.0,"homing":str(foe.rift_definition.get("behaviour",""))=="homing"})
func lob(foe:Dictionary,target:Vector2)->void:
 if lobs.size()>=24:return
 var d:Dictionary=foe.rift_definition
 lobs.append({"start":foe.pos,"target":target,"age":0.0,"flight":clampf(foe.pos.distance_to(target)/maxf(100,float(d.get("lob_speed",280))),.6,2),"radius":float(d.get("blast_radius",80)),"damage":float(d.get("damage",12)),"color":str(d.get("attack_color","#ace09b")),"credit":preload("res://scripts/defeat_credit.gd").resolve(game,game.adventure.combat.npc_key(foe),"Lobbed blast")})
func step_lobs(delta:float)->void:
 for n in range(blasts.size()-1,-1,-1):
  blasts[n].time-=delta
  if blasts[n].time<=0:blasts.remove_at(n)
 for n in range(lobs.size()-1,-1,-1):
  var shot:Dictionary=lobs[n];shot.age+=delta
  if shot.age<shot.flight:continue
  lobs.remove_at(n);blasts.append({"pos":shot.target,"radius":shot.radius,"color":shot.color,"time":.35})
  if game.position_in_world.distance_to(shot.target)<=shot.radius:game.take_player_damage(shot.damage,"",shot.credit)
  if not active:return
func damage(index:int,amount:float)->void:
 if index<0 or index>=game.enemies.size():return
 var foe:Dictionary=game.enemies[index];var actual=minf(maxf(amount,0),float(foe.hp));foe.hp-=actual;game.dealt_damage+=actual;game.enemy_flashes[int(foe.uid)]=.16;game.adventure.combat.feedback.hit(foe.pos,actual)
 if foe.hp<=0:game.enemies.remove_at(index);game.kills+=1
func finish(won:bool,abandoned:bool=false)->void:
 if game.lodges!=null and game.lodges.active:game.lodges.finish(won,abandoned);return
 if not active:return
 active=false;lobs.clear();blasts.clear();game.message="";game.message_time=0;game.loadout.assign(saved_pack);game.provisions.packed=saved_food;game.menu="";game.enter_region("town");game.health=game.max_health()
 game.presentation.window("BATTLE ENDED" if abandoned else "RIFT CLEARED" if won else "DEFEATED • MISTGLASS RIFT","rift_result")
 if not won and not abandoned:preload("res://scripts/defeat_credit.gd").card(game.presentation.content,game,game.last_defeat)
 game.presentation.label(game.presentation.content,"Practice damage: "+str(int(game.dealt_damage))+" • Enemies defeated: "+str(game.kills)+". No profile progress awarded.",21)
 game.presentation.button(game.presentation.content,"Replay this battle",func():game.presentation.close();launch())
 game.presentation.button(game.presentation.content,"Change the enemy lineup",open)
 game.presentation.button(game.presentation.content,"Explore town",game.presentation.close)
func draw_on(c:Node2D,camera:Vector2)->void:
 if not active:return
 if game.lodges!=null and game.lodges.active:game.lodges.draw_map(c,camera);return
 var view:Vector2=game.VIEW
 var center=Vector2(view.x*.5,(view.y+170)*.5)-camera
 c.draw_rect(Rect2(-camera,view),Color("#132d3b"))
 var oval=PackedVector2Array()
 for n in 65:
  var a=n*TAU/64;oval.append(center+Vector2(cos(a)*(view.x*.47),sin(a)*(view.y-185)*.46))
 c.draw_colored_polygon(oval,Color("#2c4552"));c.draw_polyline(oval,Color("#668e98"),5,true)
 for ring in [0,1]:
  var outline=PackedVector2Array()
  for n in 49:
   var a=n*TAU/48;outline.append(center+Vector2(cos(a)*(view.x*.4-ring*35),sin(a)*(view.y-220)*.38-ring*15))
  c.draw_polyline(outline,Color(.55,.8,.84,.13),1.5,true)
 for n in 12:
  var a=n*TAU/12;var p=center+Vector2(cos(a)*view.x*.39,sin(a)*(view.y-220)*.38)
  c.draw_arc(p,6,0,PI*1.6,8,Color("#93b9ad"),1.2,true);c.draw_line(p-Vector2(0,9),p-Vector2(0,15),Color("#b4c7a8"),1.2,true)
 for n in 18:
  var p=Vector2(70+posmod(n*127,int(view.x-140)),210+posmod(n*83,int(maxf(100,view.y-290))))-camera
  c.draw_line(p,p+Vector2(21,6),Color(.52,.65,.66,.12),1)
 # Flowing mist and rising motes replace the digital grid.
 for n in 8:
  var p=center+Vector2(sin(game.visual_clock*.15+n*1.9)*view.x*.37,cos(game.visual_clock*.2+n)*90)
  c.draw_arc(p,35+n*5,0,PI,16,Color(.5,.8,.84,.07),7,true)
 for p in [Vector2(60,205),Vector2(view.x-60,205),Vector2(60,view.y-50),view-Vector2(60,50)]:
  var q:Vector2=p-camera;c.draw_circle(q,20,Color(.35,.8,.9,.10));c.draw_arc(q,15,game.visual_clock*.2,game.visual_clock*.2+TAU*.8,24,Color("#7bc4c5"),2,true)
 for shot in lobs:
  var progress=clampf(float(shot.age)/float(shot.flight),0,1);var point:Vector2=shot.start.lerp(shot.target,progress)-Vector2(0,sin(progress*PI)*110)
  c.draw_circle(shot.target-camera,shot.radius,Color(Color(shot.color),.15));c.draw_arc(shot.target-camera,shot.radius,0,TAU,24,Color(shot.color),2);c.draw_circle(point-camera,10,Color(shot.color));c.draw_circle(point-camera,4,Color.WHITE)
 for blast in blasts:c.draw_arc(blast.pos-camera,blast.radius*(1.0-float(blast.time)/.35),0,TAU,24,Color(blast.color),6,true)

func _process(delta:float)->void:
 if not is_instance_valid(end_button):build_end_button()
 end_button.visible=active and not (game.lodges!=null and game.lodges.active)
 if active:
  end_button.position=Vector2(game.VIEW.x-204,104)
  game.region.size=[game.VIEW.x,game.VIEW.y]
  game.position_in_world=game.position_in_world.clamp(Vector2(65,220),game.VIEW-Vector2(65,65))
 countdown_label.visible=active and game.menu=="rift_countdown"
 if countdown_label.visible:
  var view=get_viewport().get_visible_rect().size;countdown_label.position=Vector2(0,view.y*.42);countdown_label.size=Vector2(view.x,100);countdown_label.text=("CHALLENGE STARTS IN " if game.lodges.active else "RIFT OPENS IN ")+str(int(ceil(countdown)))
 if is_instance_valid(panel):
  var view=get_viewport().get_visible_rect().size;var fit=minf(1,minf((view.x-20)/1100,(view.y-20)/670));panel.scale=Vector2.ONE*fit;panel.position=(view-Vector2(1100,670)*fit)*.5
 if active and game.menu=="rift_countdown":
  countdown=maxf(0,countdown-delta);game.message="RIFT OPENS IN "+str(int(ceil(countdown)));game.message_time=1
  if countdown<=0:game.menu="";game.message="" if game.lodges.active else "MISTGLASS RIFT • defeat your selected echoes";game.message_time=0 if game.lodges.active else 4;game.mobile.reset_controls()
func _unhandled_input(event:InputEvent)->void:
 if is_instance_valid(panel) and event is InputEventKey and event.pressed and event.keycode==KEY_ESCAPE:close();get_viewport().set_input_as_handled()

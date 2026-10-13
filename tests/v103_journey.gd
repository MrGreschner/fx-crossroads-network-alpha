extends SceneTree
var failures:=0
func check(value:bool,message:String)->void:
 if not value:failures+=1;print("FAIL: ",message)
func _initialize()->void:call_deferred("run")
func run()->void:
 root.set_meta("fx_intro_seen",true)
 var a=load("res://scenes/arcade.tscn").instantiate();root.add_child(a);await process_frame;a.set_process(false);a.party_tools.set_process(false);a.legacy.set_process(false)
 a._set_mode("descent");a._solo();a.start_countdown=0
 for floor in [5,10,15,20,30,40]:
  a.floor_number=floor;a._make_floor()
  check(a.descent.combat_count()==1,"exactly one boss on floor "+str(floor))
  check(a.opponents.all(func(e):return bool(e.get("depth_boss",false))),"boss floor has no extra units")
  if floor==30:check(a.opponents[0].type=="depth_sovereign","floor 30 sovereign")
 a.floor_number=30;a._make_floor();a.opponents[0].pos=Vector2(1300,700);a.positions[a.my_id]=Vector2(1150,850);a.local_pos=a.positions[a.my_id];var old:Vector2=a.opponents[0].pos
 a.descent.step(.1);check(old.distance_to(a.opponents[0].pos)>0,"sovereign moves")
 var kinds:Array=[]
 for n in 4:
  a.opponents[0].attack_timer=0;a.descent.step(.01)
  for w in a.descent.warnings:
   if not kinds.has(w.kind):kinds.append(w.kind)
  a.descent.warnings.clear()
 check(kinds.size()==4,"sovereign has four different attacks")
 a.levels[a.my_id]=11;a.descent.reward(a.my_id,11);a.descent.reward(a.my_id,12)
 var hp:int=a._max_hp(a.my_id);a.health[a.my_id]=50;a._apply_choice(a.my_id,"depth_health")
 check(a._max_hp(a.my_id)==hp+18 and a.health[a.my_id]==68,"post-10 health reward heals and increases max")
 a._apply_choice(a.my_id,"depth_power");check(is_equal_approx(a.descent.power(a.my_id),1.025),"post-10 power reward")
 a._apply_choice(a.my_id,"depth_power");check(int(a.descent.state(a.my_id).power)==1,"can't spend reward twice")
 for n in 12:
  a.descent.reward(a.my_id,13+n);a._apply_choice(a.my_id,"depth_cooldown")
 check(is_equal_approx(a.descent.cooldown(a.my_id),.8) and int(a.descent.pending[a.my_id])==2,"cooldown is capped and preserves pending points")
 a.attack_branch[a.my_id]="primary";a.mastery_choice[a.my_id]="special";a.session_menu.page="";a.shop_open="";a.presentation.page="";a.level_cards._process(.1)
 check(a.level_cards.panel.visible and a.level_cards.choices.size()==3,"post-10 responsive choice panel")
 var before:int=a.kills.get(a.my_id,0);var stats:Dictionary=a.contributions.get(a.my_id,{}).duplicate(true);a.health[a.my_id]=30
 a.opponents.append({"health_gem":true,"uid":123,"type":"vitality_geode","pos":a.local_pos,"hp":1,"max_hp":1,"boss":false,"lane":0})
 var count:int=a.descent.combat_count();a._hit_enemy(a.opponents.size()-1,20,a.my_id)
 check(a.health[a.my_id]==60 and a.kills.get(a.my_id,0)==before,"gem heals without counting as enemy kill")
 check(a.contributions.get(a.my_id,{})==stats,"gem is not damage or spell-healing mastery")
 check(a.descent.combat_count()==count,"gem cannot block floor completion")
 a.legacy.data.teacher=false;a.legacy.card.descent_cleared(30,1);check(int(a.legacy.card.state().descent_best)==30 and a.legacy.card.descent_tier()==4,"solo descent trophy counts cleared floor")
 check(a.legacy.card.valid(a.legacy.card.state()),"portable card accepts new badge record")
 var data:Dictionary=a._snapshot();check(data.descent.pending.has(a.my_id),"descent choices replicate")
 a.queue_free();await process_frame
 var g=load("res://scenes/main.tscn").instantiate();root.add_child(g);await process_frame;g.set_process(false);g.legacy.set_process(false);g.session_menu.resume();g.presentation.close();g.level=10;g.character_id="tova";g.hero=g.characters.tova;g.mode="town"
 check(not g.adventure.combat.passive("solo","waylight_life"),"Tova aura disabled in town")
 g.character_id="wick";g.hero=g.characters.wick;check(not g.adventure.combat.v98.candle("solo"),"Wick aura inactive in town")
 g.enter_region("honeyglass");g.session_menu.resume();g.mode="run";g.menu="";var world=g.adventure.immersive
 check(world.floor_geometry.size()==world.data.floors.size() and not world.solid_bins.is_empty(),"prepared honeyglass geometry")
 for pos in [Vector2(420,3700),Vector2(7800,1200),Vector2(0,0),Vector2(3100,2200)]:
  var original:=false
  for floor in world.data.floors:
   if floor.has("rect") and world.r(floor.rect).grow(-16).has_point(pos):original=true
   elif floor.has("poly") and Geometry2D.is_point_in_polygon(pos,world.polygon(floor.poly)):original=true
  check(world.floor_at(pos)==original,"prepared floors preserve geometry")
 await process_frame;g.queue_redraw();await process_frame
 check(world.floor_layers.size()==world.data.floors.size()+1,"retained floor draw layers created once")
 var count_layers:int=world.floor_layers.size();g.queue_redraw();await process_frame;check(world.floor_layers.size()==count_layers,"floor layers reused")
 g.enter_region("folded_coast");g.mode="run";g.menu="";check(g.enemies.any(func(e):return e.type=="crease_sentry"),"Folded Coast has new enemy")
 g.enter_region("moonveil");g.mode="run";g.menu="";check(g.enemies.any(func(e):return e.type=="lunar_usher"),"Moonveil has new enemy")
 var enemy:Dictionary=g.enemies.filter(func(e):return e.type=="lunar_usher")[0];g.position_in_world=enemy.pos+Vector2(150,0);enemy.v103_timer=0;g.adventure.additions.step(.1)
 check(not g.adventure.additions.warnings.is_empty(),"Lunar Usher telegraphs its spotlight")
 var ui=preload("res://scripts/device_test.gd").new();g.add_child(ui);ui.setup(g);ui.running=false;ui.frames=[.016,.016,.016,.06];check("Measured" in ui.summary() and "Frames over 50 ms: 1" in ui.summary(),"diagnostics readable summary")
 ui.queue_free();g.queue_free();await process_frame
 print("v103 journey failures: ",failures);quit(failures)

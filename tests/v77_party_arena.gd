extends SceneTree
var failures:=0
class FakeChannel extends RefCounted:
 var packets:Array=[]
 func get_ready_state()->int:return WebRTCDataChannel.STATE_OPEN
 func put_packet(bytes:PackedByteArray)->int:packets.append(JSON.parse_string(bytes.get_string_from_utf8()));return OK
class FakePeer extends RefCounted:
 func close()->void:pass
func check(ok:bool,label:String)->void:
 if not ok:failures+=1;print("FAIL: ",label)
func _initialize()->void:call_deferred("run")
func run()->void:
 var g=load("res://scenes/arcade.tscn").instantiate();root.add_child(g);await process_frame;g.set_process(false);g.party_tools.set_process(false)
 g._solo();g.started=false;g._set_mode("arena");g._add_player("friend",1);g.roster.append({"id":"friend","name":"Friend"});g.lobby_heroes.friend="book"
 var picked:=0
 for n in g.hero_picker.item_count:
  if str(g.hero_picker.get_item_metadata(n))=="cat":picked=n
 g.party_tools.change_hero(picked);check(g.selected_hero=="cat" and g.hero_ids[g.my_id]=="cat","change own hero without leaving room")
 for id in g.arena_world.MAPS:
  for n in g.arena_map_picker.item_count:
   if str(g.arena_map_picker.get_item_metadata(n))==id:g.arena_map_picker.select(n)
  g.opening_picker.set_pressed_no_signal(false);g._start_match()
  check(g.levels[g.my_id]==10 and g.levels.friend==10,id+" all heroes begin at ten")
  check(g.arena_world.map_id==id,id+" chosen map built")
  for player in g.positions:check(g._clear_path(g.positions[player],g.positions[player]),id+" safe spawn")
  var packet:Dictionary=JSON.parse_string(JSON.stringify(g._snapshot()));check(packet.arena_world.map==id,"map serializes "+id)
  g.started=false
 g.opening_picker.set_pressed_no_signal(true);g._start_match();check(g.levels[g.my_id]==1 and g.levels.friend==1,"Opening Act restores level-one match")
 g.opening_picker.set_pressed_no_signal(false);g.arena_map="sand";g.arena_world.setup(g,"sand");check(g.arena_world.slow(Vector2(850,720))==.55,"quicksand slows")
 g.arena_world.setup(g,"storm");var phases:Array=[]
 for d in g.arena_world.drones:phases.append(d.phase)
 check(phases==[0.0,12.0,24.0],"three staggered drones")
 g.positions[g.my_id]=Vector2(650,600);g.local_pos=g.positions[g.my_id];g.health[g.my_id]=100;g.invincible_until[g.my_id]=0
 g.arena_world.clock=36;g.arena_world.drones[0].pos=[650,600];g.arena_world.step(.21);check(g.health[g.my_id]<100 and g.arena_world.slow(g.local_pos)==.3,"orb damages and strongly slows")
 g.arena_world.setup(g,"forest");check(g.opponents.size()==8 and g.opponents.filter(func(e:Dictionary)->bool:return bool(e.get("boss",false))).size()==2,"forest has enemies and two minibosses")
 for n in 60:g.arena_world.step(.1)
 check(g.arena_world.flowers.size()>0 and g.missiles.size()>0,"flowers grow and fire")
 g._set_mode("descent");g._start_match();g.floor_number=4;g.levels[g.my_id]=7;g.health[g.my_id]=43;var previous:String=g.match_id
 g.party_tools.late_pending.newcomer=30.0;g.roster.append({"id":"newcomer","name":"New"});var channel=FakeChannel.new();g.links.newcomer={"peer":FakePeer.new(),"channel":channel}
 g._packet("newcomer",{"type":"hero","hero":"cat","build":{},"food":""})
 check(g.levels.newcomer==1 and g.xp.newcomer==0 and g.hero_ids.newcomer=="cat","late arrival has own hero and level one")
 check(g.floor_number==4 and g.levels[g.my_id]==7 and g.health[g.my_id]==43 and g.match_id==previous,"late arrival preserves host progress")
 check(channel.packets[0].type=="late_start" and channel.packets[1].floor==4,"late start followed by current authoritative state")
 g._packet("newcomer",{"type":"hero","hero":"book"});check(g.hero_ids.newcomer=="cat","cannot switch hero during battle")
 var guest=load("res://scenes/arcade.tscn").instantiate();root.add_child(guest);await process_frame;guest.set_process(false);guest.party_tools.set_process(false);guest.role="guest";guest.host_id="solo";guest.my_id="newcomer";guest.roster.assign(g.roster);guest._add_player("newcomer",2)
 guest._packet("solo",channel.packets[0]);guest._packet("solo",channel.packets[1]);check(guest.floor_number==4 and guest.levels.newcomer==1 and guest.health.solo==43,"guest joins current floor without upgrading itself")
 var build:Dictionary=g.legacy.sanitize_build({"points":4,"tuning":[-2,2,-2]});check(build.tuning==[-2,2,0],"signed tuning bounded by absolute point budget")
 var stats:Dictionary=g.legacy.authored_stats("ram","primary",{"damage":100,"cooldown":1},{"tuning":[-2,0,0]});check(is_equal_approx(stats.damage,92) and is_equal_approx(stats.cooldown,.9),"speed slider trades damage for cooldown")
 var main=load("res://scenes/main.tscn").instantiate();root.add_child(main);await process_frame;main.set_process(false);main.presentation.close();main.respawn_clinic=true;main.enter_region("town")
 main.legacy.record("ram").points=4;main.legacy.open_hero("ram")
 var sliders:Array=main.legacy.root.find_children("*","HSlider",true,false)
 check(sliders.size()==3,"three real mastery sliders")
 sliders[0].value=-2;sliders[1].value=2;sliders[2].value=2
 check(int(main.legacy.record("ram").tuning[0])==-2 and int(main.legacy.record("ram").tuning[1])==2 and int(main.legacy.record("ram").tuning[2])==0,"slider callbacks preserve signed values and refuse overspending")
 main.legacy.close();main.start_run(false,"grove");main.health=0;main.finish_run(false);main.presentation.return_to_town()
 check(main.region_id=="town" and main.health>0,"real death returns to healer with health restored")
 check(main.can_stand_at(main.position_in_world),"healer respawn is walkable")
 for d in [Vector2(30,0),Vector2(-30,0),Vector2(0,30),Vector2(0,-30)]:check(main.can_stand_at(main.position_in_world+d),"healer spawn has escape clearance")
 for node in [g,guest,main]:
  if node.get("links")!=null:node.links.clear()
  node.queue_free()
 await process_frame;await create_timer(.2).timeout;print("v77 party/arena failures: ",failures);quit(failures)

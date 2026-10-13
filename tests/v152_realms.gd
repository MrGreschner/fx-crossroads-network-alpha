extends SceneTree
const ACCESS=preload("res://scripts/realm_access.gd")
var checks:=0
var failures:=0
func check(ok:bool,title:String)->void:
 checks+=1
 if not ok:failures+=1;print("FAIL • ",title)
func _initialize()->void:call_deferred("run")
func run()->void:
 root.set_meta("fx_intro_seen",true);root.set_meta("fx_tutorial_offered",true)
 var g=load("res://scenes/main.tscn").instantiate();root.add_child(g);current_scene=g
 for n in 10:await process_frame
 g.set_process(false);g.legacy.set_process(false);g.presentation.close();g.session_menu.resume();g.menu="";g.legacy.data=g.legacy.defaults();g.legacy.mine.setup(g.legacy)
 check(ACCESS.unlocked(g.legacy,"grove") and ACCESS.unlocked(g.legacy,"quarry"),"both opening realms available")
 check(not ACCESS.unlocked(g.legacy,"honeyglass") and not ACCESS.unlocked(g.legacy,"ice"),"later steps locked")
 g.legacy.clear_adventure("ram","quarry");check(ACCESS.unlocked(g.legacy,"honeyglass") and ACCESS.unlocked(g.legacy,"elementary"),"either opening win opens second pair")
 g.legacy.clear_adventure("ram","elementary");check(ACCESS.unlocked(g.legacy,"sunfield") and ACCESS.unlocked(g.legacy,"ice"),"either second pair opens moderate pair")
 check(not ACCESS.unlocked(g.legacy,"petalbrook"),"medium still locked")
 g.legacy.clear_adventure("ram","ice");check(ACCESS.unlocked(g.legacy,"petalbrook"),"either moderate win opens medium")
 for id in ["folded_coast","moonveil"]:g.legacy.clear_adventure("ram",id)
 check(not ACCESS.unlocked(g.legacy,"space"),"two medium wins insufficient")
 g.legacy.clear_adventure("ram","moonveil");check(not ACCESS.unlocked(g.legacy,"space"),"repeat medium win insufficient")
 g.legacy.clear_adventure("ram","petalbrook");check(ACCESS.unlocked(g.legacy,"space"),"three different mediums open challenging")
 g.legacy.clear_adventure("ram","space");check(ACCESS.unlocked(g.legacy,"brasslock"),"one challenging opens hard")
 for id in ["brasslock","silverfall","clockwork_orchard"]:g.legacy.clear_adventure("ram",id)
 check(not ACCESS.unlocked(g.legacy,"astral_rift"),"three hard wins insufficient")
 g.legacy.clear_adventure("ram","lantern_marsh");check(ACCESS.unlocked(g.legacy,"astral_rift"),"four hard wins open expert")
 g.legacy.clear_adventure("ram","astral_rift");check(not ACCESS.unlocked(g.legacy,"shattered_oath"),"one expert insufficient")
 g.legacy.clear_adventure("ram","ebonwake");check(ACCESS.unlocked(g.legacy,"shattered_oath"),"two experts open Extreme")
 g.presentation.tutorial_end(true,false);check(g.presentation.content.find_children("*","Button",true,false).any(func(b):return b.text.begins_with("Start first adventure")),"tutorial Grove shortcut")
 g.presentation.close();root.set_meta("fx_dev_match",true)
 for id in ["grove","quarry","ice"]:
  g.start_run(false,id);g.set_process(false);g.menu=""
  check(g.enemies.size()>=28 and g.enemies.size()<=34,id+" finite paced roster")
  check(g.can_stand_at(g.position_in_world),id+" arrival clear")
  for e in g.enemies:check(g.can_stand_at(e.pos),id+" defender not in obstacle")
  var nearest:=INF
  for e in g.enemies:nearest=minf(nearest,g.position_in_world.distance_to(e.pos))
  check(nearest>=550,id+" calm arrival")
  for p in g.region.route_points:check(g.can_stand_at(Vector2(p[0],p[1])),id+" clear route waypoint")
 for id in ["sunfield","petalbrook"]:
  g.start_run(false,id);g.menu="";var world=g.adventure.immersive;var origin:Vector2=world.v(world.data.spawn)
  check(world.can_stand(origin),id+" arrival")
  check(world.can_stand(origin),id+" playable before guardian seal")
  for e in world.data.spawns:
   check(world.can_stand(world.v(e.pos)),id+" defender valid "+str(e.pos))
   check(not world.route(origin,world.v(e.pos)).is_empty(),id+" defender reachable "+str(e.pos))
  if id=="sunfield":check(world.data.grass.is_empty(),"no animated tall grass draw loops")
  world.step(.01);check(g.enemies.size()==world.data.spawns.size(),id+" all authored enemies seeded")
  for n in range(g.enemies.size()-1,-1,-1):g.damage_enemy(n,100000)
  g.menu="";world.step(.01);check(world.boss_live and g.enemies.size()==1,id+" guardian after patrols")
  check(not world.route(origin,world.v(world.data.exit)).is_empty(),id+" boss glade reachable after seal opens")
  var boss:Dictionary=g.enemies[0];var before:Vector2=boss.pos;g.position_in_world=world.advance(before,Vector2(-250,0));world.step(.2);check(boss.pos.distance_to(before)>1,id+" guardian moves")
 for id in ["saffron_hopper","silk_spinner","dewcap_guard","brass_sapper","keywing_courier"]:
  check(g.enemy_types.has(id),id+" registered")
  for pose in ["idle","walk1","walk2","attack"]:check(g.art.get(id+"_"+pose)!=null,id+" "+pose+" artwork")
 g.start_run(false,"ice");var ice=g.adventure.polish
 var p:=Vector2(2000,800);var slide:Vector2=ice.motion("solo",p,Vector2(20,0),.1);slide=ice.motion("solo",p,Vector2(0,20),.1)
 check(slide.x>18 and slide.y<2,"ice retains entry direction despite sharp turn")
 check(ice.motion("solo",Vector2(1000,900),Vector2(0,20),.1)==Vector2(0,20),"snow restores ordinary control")
 g.start_run(false,"shattered_oath");g.menu="";var adv=g.adventure
 for n in 4:
  var origin:Vector2=adv.vec(adv.trials[n].origin);g.enemies.clear();g.position_in_world=origin+Vector2(2120,1400)
  adv.spawn(["briar_matron","kiln_knight","mirror_oracle","storm_archon"][n],origin+Vector2(2400,1400),600,true,n)
  var boss:Dictionary=g.enemies[-1];boss.expansion_boss=true;var before:Vector2=boss.pos;adv.step(.1)
  check(boss.pos.distance_to(before)>1,"Oath guardian "+str(n)+" moves")
 g.start_run(false,"grove");g.menu="";g.enemies.clear();adv.spawn("boss",Vector2(900,960),500,true);g.position_in_world=Vector2(1180,960)
 var stalled:Dictionary=g.enemies[-1];var before:Vector2=stalled.pos
 for n in 15:adv.polish.bosses(.1)
 check(stalled.pos.distance_to(before)>1,"shared watchdog unsticks unhandled boss")
 var key:String=adv.combat.npc_key(stalled);adv.combat.apply_status(key,"stun",2,"solo");before=stalled.pos;adv.polish.bosses(.3);check(stalled.pos==before,"stunned bosses remain stunned")
 g.queue_free();current_scene=null
 for n in 4:await process_frame
 root.set_meta("fx_mode","coop");root.set_meta("fx_realm","ice");root.set_meta("fx_hero","ram")
 var a=load("res://scenes/arcade.tscn").instantiate();root.add_child(a);current_scene=a
 for n in 10:await process_frame
 a.set_process(false);a.party_tools.auto_solo=false;a.role="host";a.my_id="p1";a.host_id="p1";a.roster.assign([{"id":"p1","name":"First"},{"id":"p2","name":"Second"}]);a._add_player("p1",0);a._add_player("p2",1);a._start_match();a.start_countdown=0
 check(a.adventure.polish.id=="ice","co-op has same ice mechanics")
 a.opponents.clear();a.wave=1;a._spawn_wave(100);var first:float=a.opponents[-1].pos.x
 a.opponents.clear();a.wave=2;a._spawn_wave(100);check(a.opponents[0].pos.x>first,"co-op second stage uses later markers")
 a.opponents.clear();a.wave=3;a._spawn_wave(100);check(a.opponents[-1].boss and a.opponents[-1].pos.x>5500,"co-op boss in final rink")
 for id in ["brass_sapper","keywing_courier"]:check(a.art.get(id+"_idle")!=null,"co-op new enemy art "+id)
 a.queue_free();current_scene=null
 for n in 4:await process_frame
 root.remove_meta("fx_dev_match")
 print("V152 ",checks," checks / ",failures," failures");quit(1 if failures else 0)

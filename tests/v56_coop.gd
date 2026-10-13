extends SceneTree
var failures:int=0
func check(ok:bool,label:String)->void:
 if not ok:failures+=1;print("FAIL: ",label)
func _initialize()->void:call_deferred("run")
func party()->Node:
 var game=load("res://scenes/arcade.tscn").instantiate();root.add_child(game);await process_frame;game.set_process(false)
 game._set_mode("defense");game._solo();game._set_mode("arena");game._start_match();game.field_obstacles.clear();game.obstacle_grid.clear();return game
func run()->void:
 var host=await party();host._add_player("friend",1);host.hero_ids.friend="dustdevil";host.levels.friend=6
 host.positions.friend=Vector2(1000,1000);host.positions[host.my_id]=Vector2(1000,800);host.local_pos=host.positions[host.my_id]
 var kit=host.adventure.combat.v56
 host._packet("friend",{"type":"pos","x":1000,"y":1000,"hero":"dustdevil","primary_held":true,"primary_angle":0})
 host._packet("friend",{"type":"attack","style":"primary","angle":0})
 check(kit.intakes.has("friend"),"remote primary starts intake")
 host.mode="defense"
 check(not kit.catch_shot(Vector2(1100,1000),Vector2(1010,1000),host.my_id,25,"#ffffff"),"allied shots are not captured")
 host.mode="arena"
 check(kit.catch_shot(Vector2(1100,1000),Vector2(1010,1000),host.my_id,25,"#ffffff"),"rival shots can be captured")
 var data:Dictionary=JSON.parse_string(JSON.stringify(host._snapshot()))
 var guest=await party();guest.role="guest";guest.host_id=host.my_id;guest.my_id="friend";guest.match_id=host.match_id;guest._packet(host.my_id,data)
 check(guest.adventure.combat.v56.intakes.has("friend") and guest.adventure.combat.v56.intakes.friend.has("captured"),"guest receives stored projectile")
 var before:int=guest.adventure.combat.projectiles.size();guest.adventure.combat.v56.holding("friend",false,Vector2.DOWN)
 check(guest.adventure.combat.projectiles.size()==before,"guest never creates authoritative returned shots")
 host._packet("friend",{"type":"pos","x":1000,"y":1000,"hero":"dustdevil","primary_held":false,"primary_angle":PI/2})
 check(not kit.intakes.has("friend") and host.adventure.combat.projectiles.size()==1,"release packet fires once on host")
 check(host.adventure.combat.projectiles.size()==1 and absf(host.adventure.combat.projectiles[0].aim[1]-1)<.00001,"host uses release aim")
 kit.reset();host.adventure.combat.projectiles.clear();host.hero_ids.friend="cloudloom"
 host.adventure.combat.cast("friend",host.characters.cloudloom.special,Vector2.RIGHT,28)
 data=JSON.parse_string(JSON.stringify(host._snapshot()));guest._packet(host.my_id,data)
 check(guest.adventure.combat.v56.storms.size()==1,"weather spell replicates")
 for game in [host,guest]:
  for voice in game.journey.voices:voice.stop()
  game.queue_free()
 await create_timer(.3).timeout
 print("v56 multiplayer: ",failures," failures");quit(1 if failures else 0)

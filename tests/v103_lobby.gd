extends SceneTree
var failures:=0
func check(value:bool,message:String)->void:
 if not value:failures+=1;print("FAIL: ",message)
func _initialize()->void:call_deferred("run")
func run()->void:
 root.set_meta("fx_intro_seen",true)
 var a=load("res://scenes/arcade.tscn").instantiate();root.add_child(a);await process_frame;a.set_process(false);a.party_tools.set_process(false);a.legacy.set_process(false)
 a._set_mode("arena");a._solo();a.start_countdown=0
 a.started=false;a.roster.assign([{"id":a.my_id,"name":"Host"},{"id":"guest","name":"Guest"}]);a.positions.guest=Vector2.ZERO;a.bot_count=3;a.arena_seats=2;a._update_lobby_settings()
 check(a.arena_seats==5 and a.fighters().size()==5,"adding three bots keeps both human members and expands seats")
 a.bot_count=1;a._update_lobby_settings();check(a.fighters().size()==3 and not a.positions.has("bot:2"),"removed bots leave roster and combat state")
 a.spectator_host=true;a._update_lobby_settings();check(a.fighters().size()==2 and not a.positions.has(a.my_id),"spectator frees host fighter seat")
 a.spectator_host=false;a._update_lobby_settings();check(a.positions.has(a.my_id),"host rejoins fighter seat without rehosting")
 for map in a.arena_world.MAPS:
  a.arena_world.setup(a,map);a._rebuild_grid();a.positions.clear()
  for slot in 8:
   var pos:Vector2=a._spawn_player(slot)
   check(a._clear_path(pos,pos) and a._clear_path(pos,pos+Vector2(24,0)) and a._clear_path(pos,pos-Vector2(24,0)),"safe spawn footprint "+map+" seat "+str(slot))
   a.positions["seat"+str(slot)]=pos
 # Force an obstacle at the desired point: centre and full footprint must be relocated.
 a.field_obstacles.assign([{"pos":Vector2(200,200),"radius":80.0,"kind":"tree"}]);a._rebuild_grid();a.positions.clear();var pos:Vector2=a._safe_arena_spawn(Vector2(200,200),0)
 check(pos.distance_to(Vector2(200,200))>104 and a._clear_path(pos,pos),"tree spawn relocates to open ground")
 check(a.characters.wick.primary.damage==18 and a.characters.wick.special.count==16,"Wick balance data loaded")
 a.queue_free();await process_frame
 print("v103 lobby failures: ",failures);quit(1 if failures else 0)

extends SceneTree
var failures:=0
func check(ok:bool,label:String)->void:
 if not ok:failures+=1;print("FAIL: ",label)
func _initialize()->void:call_deferred("run")
func run()->void:
 var g=load("res://scenes/arcade.tscn").instantiate();root.add_child(g);await process_frame;g.set_process(false);g.party_tools.set_process(false);g.legacy.set_process(false)
 g._set_mode("arena");g.role="host";g.my_id="host";g.host_id="host";g.arena_seats=8;g.spectator_host=true;g.roster.assign([{"id":"host","name":"Teacher"}]);g._add_player("host",0)
 for n in 8:
  var id="p"+str(n);g.roster.append({"id":id,"name":"Student "+str(n+1)});g._add_player(id,n);g.hero_ids[id]=["ram","book","cat","snail","kite","ripplejaw","gopher","nullweaver"][n];g.lobby_heroes[id]=g.hero_ids[id];g.teams[id]=n%2
 check(g.fighters().size()==8 and g.positions.size()==8,"spectator is separate ninth connection")
 check(g._teams_ready(),"balanced 4v4 teams ready")
 g.rule_picker.select(1)
 for map in range(5):
  g.arena_map_picker.select(map);g._start_match()
  for id in g.positions:check(g._clear_path(g.positions[id],g.positions[id]),"safe eight-player spawn map "+str(map)+" "+str(id))
 g.arena_map_picker.select(1);g._start_match()
 check(not g.positions.has("host") and not g.health.has("host"),"host has no targetable body")
 check(g.match_party_size==8,"party scaling excludes spectator")
 var starts:Array=[]
 for pos in g.positions.values():
  check(not starts.has(pos),"unique spawn for all eight fighters");starts.append(pos)
 check(g.start_countdown==5,"match has visible ready countdown")
 var rec=g.legacy.data.duplicate(true);g._track_card_progress();check(g.legacy.data==rec,"spectator earns no card progress")
 var config:Dictionary=g.match_config();check(config.spectator and config.seats==8,"start and reconnect carry format")
 var packet:Dictionary=g._snapshot();check(packet.players.size()==8 and not packet.players.has("host"),"snapshot contains fighters only")
 var guest=load("res://scenes/arcade.tscn").instantiate();root.add_child(guest);await process_frame;guest.set_process(false);guest.party_tools.set_process(false);guest.legacy.set_process(false)
 guest.role="guest";guest.my_id="p0";guest.host_id="host";guest._add_player("p0",0);guest._set_mode("arena");guest._receive_lobby(g._lobby_packet())
 check(guest.roster.size()==9 and guest.fighters().size()==8,"guest accepts nine connection lobby")
 guest._packet("host",config);guest._packet("host",packet)
 check(guest.positions.size()==8 and not guest.positions.has("host"),"guest simulation excludes spectator")
 check(not guest.spectating() and guest.spectator_host,"guest remains playable")
 # Keep the real process path running without fabricated peer recovery checks.
 g.recovery=null;g.start_countdown=0
 for n in 8:g.positions["p"+str(n)]=g.FIELD.size*.5+Vector2.from_angle(n*TAU/8)*140
 for kind in ["primary","secondary","special"]:
  for id in g.positions:
   var aim:Vector2=(g.FIELD.size*.5-g.positions[id]).normalized()
   g._attack(id,kind,aim,g.FIELD.size*.5)
  for tick in 40:g._process(.05)
 check(not g.positions.has("host"),"process never reinserts spectator")
 g.end_match("Arena test complete");check(g.legacy.data==rec,"spectator gets no result rewards")
 guest.queue_free();g.queue_free();await process_frame
 print("v81 arena failures: ",failures);quit(failures)

extends SceneTree
var failures=0
func check(ok:bool,label:String)->void:
 if not ok:failures+=1;print("FAIL: ",label)
func _initialize()->void:call_deferred("run")
func run()->void:
 for action in ["primary","secondary","special"]:
  if not InputMap.has_action(action):InputMap.add_action(action)
 root.set_meta("fx_intro_seen",true);root.set_meta("fx_tutorial_offered",true)
 var g=load("res://scenes/arcade.tscn").instantiate();root.add_child(g)
 for n in 8:await process_frame
 g.set_process(false);g.party_tools.set_process(false);g.party_tools.auto_solo=false;g.legacy.set_process(false)
 check(g.arena_map=="sand" and str(g.arena_map_picker.get_item_metadata(g.arena_map_picker.selected))=="sand","sand default and selected UI")
 check(g.ai_difficulty=="medium" and g.difficulty_picker.selected==1,"medium remains default")
 g._set_mode("arena");g.role="host";g.my_id="host";g.host_id="host";g.roster.assign([{"id":"host","name":"Host"}]);g._add_player("host",0);g.bot_count=1
 g.difficulty_picker.item_selected.emit(0)
 check(g.ai_difficulty=="easy","easy selectable in lobby")
 g._start_match();g.start_countdown=0
 g.positions.host=Vector2(950,900);g.positions["bot:0"]=Vector2(1200,900)
 g.bots.step(.7)
 check(g.bots.states.has("bot:0") and float(g.bots.states["bot:0"].think)==.65,"easy bot slower decisions")
 check(float(g.bots.states["bot:0"].ability_cd)>0,"easy bot ability pacing")
 var packet=g._lobby_packet();g.role="guest";g._receive_lobby(packet)
 check(g.ai_difficulty=="easy" and g.difficulty_picker.selected==0,"easy lobby roundtrip")
 g.role="host";g.bot_count=0;g.arena_map_picker.select(3);g._start_match();g.start_countdown=0
 check(g.opponents.size()==4,"forest three enemies and one miniboss")
 g.arena_map_picker.select(0);g._start_match();g.start_countdown=0;g.wave_timer=0;g._simulate(.01)
 check(g.opponents.size()==2 and g.wave_timer==18,"coliseum smaller reinforcements")
 for n in 3:g.wave_timer=0;g._simulate(.01)
 check(g.opponents.size()==6,"coliseum enemy cap")
 check(g.bots.difficulty("invalid")=="medium","invalid difficulty defaults medium")
 for voice in g.journey.voices:voice.stop()
 g.queue_free();await process_frame;await create_timer(.3).timeout;print("v153 arena: ",failures," failures");quit(failures)

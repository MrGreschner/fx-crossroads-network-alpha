extends SceneTree
var failures:=0
func check(ok:bool,label:String)->void:
 if not ok:failures+=1;print("FAIL: ",label)
func _initialize()->void:call_deferred("run")
func run()->void:
 root.set_meta("fx_intro_seen",true)
 var g=load("res://scenes/main.tscn").instantiate();root.add_child(g);await process_frame
 g.set_process(false);g.presentation.asked=true;g.presentation.close();g.session_menu.resume()
 g.selected_character="basketball";g.hero_hall.test_hero()
 check(g.practice and g.character_id=="basketball" and g.level==10,"Test hero starts selected hero in level-ten training")
 g.position_in_world=g.training_yard.HERO_BOOK
 var event:=InputEventAction.new();event.action="interact";event.pressed=true;Input.parse_input_event(event);Input.flush_buffered_events()
 g.handle_run(0);Input.action_release("interact")
 check(g.menu=="characters","book pedestal opens Character Hall")
 await process_frame
 check(g.hero_hall.panel.visible,"native Character Hall remains available in training")
 g.hero_hall.select("ram");g.hero_hall.close()
 check(g.practice and g.character_id=="ram" and g.position_in_world==g.training_yard.HERO_BOOK,"switching hero returns to the same training spot")
 check(g.characters.size()>=74,"all 74 heroes retained")
 for player in g.find_children("*","AudioStreamPlayer",true,false):player.stop()
 g.queue_free();await process_frame;await process_frame
 print("v108 training failures: ",failures);quit(1 if failures else 0)

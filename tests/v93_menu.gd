extends SceneTree
var failures:=0
func check(ok:bool,description:String)->void:
 if not ok:failures+=1;print("FAIL: ",description)
func _initialize()->void:call_deferred("run")
func run()->void:
 root.set_meta("fx_intro_seen",true)
 var g=load("res://scenes/main.tscn").instantiate();root.add_child(g);await process_frame;g.set_process(false);g.legacy.set_process(false);g.presentation.asked=true;g.presentation.close();g.profile.tutorial_seen=true
 var m=g.session_menu;m.open("main");await process_frame
 check(m.gallery.visible and m.backdrop.color.a==1,"main is opaque, separate title page")
 check(m.gallery.heroes.size()==24 and m.gallery.creatures.size()>5,"cached hero and enemy gallery")
 check(m.panel.size==Vector2(520,640),"compact centered main navigation")
 var actions:Array=[]
 for c in m.body.get_children():
  if c is Button:actions.append(c.text)
  if c is HBoxContainer:
   for b in c.get_children():actions.append(b.text)
 check("Upload profile" in actions and "Download profile" in actions and "New player" in actions,"profile actions retained")
 var t:float=m.gallery.clock;m.gallery._process(.3);check(m.gallery.clock>t,"title motion advances")
 m.open("pause");check(not m.gallery.visible and m.backdrop.color.a<1,"pause retains translucent adventure background")
 m.resume();check(g.menu.is_empty(),"resume removes input block")
 check(g.town_scenery.trees.all(func(p):return not (p.x<270 and p.y>290 and p.y<1420)),"no border trees on western ridge")
 check(g.can_stand_at(Vector2(230,805)) and g.can_stand_at(Vector2(550,1550)),"cave and postal interaction accessible")
 check(not g.can_stand_at(Vector2(430,1400)),"new post facade matches building collision")
 g.queue_free();await process_frame
 var a=load("res://scenes/arcade.tscn").instantiate();root.add_child(a);await process_frame;a.set_process(false);a.legacy.set_process(false);a.presentation.set_process(false);a.party_tools.set_process(false)
 a.session_menu.open("main");check(a.session_menu.gallery.creatures.size()>5,"multiplayer title uses enemy registry safely")
 a.session_menu.profile_action(true);check(a.session_menu.message.text.contains("town"),"live profile restriction retained")
 a.session_menu.resume();check(a.shop_open.is_empty(),"live menu resumes input")
 for player in a.find_children("*","AudioStreamPlayer",true,false):player.stop()
 a.queue_free();await process_frame;await process_frame;print("v93 menu failures: ",failures);quit(failures)

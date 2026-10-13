extends SceneTree
var failures:=0
func check(value:bool,title:String)->void:
 if not value:failures+=1;print("FAIL: ",title)
func _initialize()->void:call_deferred("run")
func run()->void:
 root.set_meta("fx_intro_seen",true)
 var g=load("res://scenes/main.tscn").instantiate();root.add_child(g);await process_frame
 g.presentation.asked=true;g.presentation.close();g.session_menu.resume();g.set_process(false)
 check(g.presentation.starter_role("ram")=="Melee","starter label is attack role, not attack name")
 check("Summoner" in g.presentation.starter_role("basketball"),"starter label includes summoner role")
 g.mobile.enabled=true;g.mobile.menu_state="";g.mobile._process(.01)
 var m=g.mobile
 check(m.round_actions.size()==3,"secondary, special and dodge circular controls")
 for b in m.round_actions:
  check(b.size==Vector2(120,120),"large square bounds for circular button")
  check(m.hit_button(b,b.get_global_rect().get_center()),"round centre accepts touch")
  check(not m.hit_button(b,b.position+Vector2(1,1)),"corners outside circle do not accept touch")
  b.button_down.emit();check(Input.is_action_pressed(m.round_actions[b]),"hold action works");b.button_up.emit();check(not Input.is_action_pressed(m.round_actions[b]),"release action works")
 var interact:Button
 for b in m.buttons:
  if b.text=="Interact":interact=b
 interact.button_down.emit();check(Input.is_action_pressed("interact"),"rectangular interact retains input");m.reset_controls();check(not Input.is_action_pressed("interact"),"reset releases controls")
 var secondary:Button
 for b in m.buttons:
  if b.text=="Secondary":secondary=b
 var touch:=InputEventScreenTouch.new();touch.index=1;touch.pressed=true;touch.position=m.move_center+Vector2(40,0);m._input(touch)
 touch=InputEventScreenTouch.new();touch.index=2;touch.pressed=true;touch.position=secondary.get_global_rect().get_center();m._input(touch)
 check(m.movement.x>0 and Input.is_action_pressed("secondary"),"movement and ability can be held by separate fingers")
 touch.pressed=false;m._input(touch);check(not Input.is_action_pressed("secondary") and m.movement.x>0,"release ability preserves movement finger")
 m.reset_controls()
 g.tutorial.start("ram");g.set_process(false);g.tutorial.wave=1;g.tutorial.defeated=2;g.level=2
 g.enemies.assign([{"uid":900012,"hp":1,"pos":Vector2(650,380)}]);g.tutorial.damage(0,10)
 check(g.level==3 and g.presentation.page=="unlock_celebration" and g.menu=="presentation","secondary unlock opens pausing popup")
 check(g.mobile.blocked(),"unlock modal blocks underlying touch")
 g.presentation.close();g.tutorial.defeated=6;g.level=5;g.enemies.assign([{"uid":900013,"hp":1,"pos":Vector2(650,380)}]);g.tutorial.damage(0,10)
 check(g.presentation.page=="unlock_celebration" and g.level==6,"special unlock popup")
 g.presentation.close();g.tutorial.finish(false,true);g.presentation.close();g.enter_region("town")
 var guide=g.town_services.field_guide;guide.game=g
 g.legacy.data.encounters={};check(guide.known_entries().is_empty(),"unknown foes remain hidden")
 g.legacy.data.encounters={"grove":["archer","bramble"],"quarry":["archer"]}
 var entries:Array=guide.known_entries();check(entries.size()==2,"guide deduplicates encountered enemy")
 var entry:Dictionary=entries.filter(func(e):return e.kind=="archer")[0]
 check(entry.places.size()==2 and guide.stats(entry).damage==9,"guide preserves places and authored damage")
 check("projectiles" in guide.description(entry),"guide explains ranged behaviour")
 g.menu="arcane_tower";g.town_services._process(.01);await process_frame
 check(g.town_services.panel.visible and g.mobile.blocked(),"Mistglass opens native guide and blocks movement overlay")
 guide.query="Thorn";guide.render_rows();check(guide.rows.get_child_count()==1,"search filters discovered enemies")
 g.town_services.close();check(g.menu.is_empty(),"guide closes cleanly")
 for player in g.find_children("*","AudioStreamPlayer",true,false):player.stop();player.stream=null
 await create_timer(.1).timeout;g.queue_free();await process_frame;await process_frame
 print("v113 failures: ",failures);quit(1 if failures else 0)

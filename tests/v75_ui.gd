extends SceneTree
var failures:=0
func check(ok:bool,label:String)->void:
 if not ok:failures+=1;print("FAIL: ",label)
func _initialize()->void:call_deferred("run")
func run()->void:
 root.set_meta("fx_intro_seen",true)
 var g=load("res://scenes/main.tscn").instantiate();root.add_child(g);await process_frame;g.set_process(false);g.legacy.set_process(false)
 g.legacy.data=g.legacy.defaults();g.legacy.open_hero("ripplejaw");await process_frame;await process_frame
 var cards:HBoxContainer=g.legacy.body.get_child(2)
 check(cards.get_child_count()==2,"two adjacent technique cards")
 check(cards.size.x<=g.legacy.body.size.x+1,"cards fit available width")
 check(cards.get_child(0).size.x>300 and cards.get_child(1).size.x>300,"cards usable width")
 var before:Dictionary=g.legacy.payload("ripplejaw");g.legacy.data.teacher=true;g.legacy.render();await process_frame
 g.legacy.technique_toggle("ripplejaw");g.legacy.final_toggle("ripplejaw")
 check(g.legacy.payload("ripplejaw").technique and g.legacy.payload("ripplejaw").final_technique,"independent equip buttons")
 g.legacy.close();g.menu="";g.town_polish.open(g);await process_frame
 var ch=g.town_polish
 check(ch.CHIME_LEVELS.size()==6,"five additional challenges")
 for level in 6:
  ch.challenge=level;ch.restart()
  var count:int=int(ch.CHIME_LEVELS[level].count)
  for pattern in 5:
   for note in count:
    ch.phase=ch.target_phase(note);ch.strike()
   # Further taps cannot add points after the final chime of a pattern.
   var score:int=ch.hits;ch.strike();check(ch.hits==score,"extra taps ignored")
   ch.step((1-ch.phase)/float(ch.CHIME_LEVELS[level].speed)+.01)
  check(not ch.playing and ch.hits==5*count,"perfect challenge "+str(level))
  check(ch.next_button.disabled==(level==5),"next level availability")
 ch.challenge=5;ch.restart()
 for n in 5:ch.step(1.1)
 check(ch.hits==0 and not ch.playing and ch.next_button.disabled,"missed chimes fail without waiting forever")
 ch.challenge=2;ch.restart();ch.phase=.01;ch.strike();check(ch.hits==0 and ch.note==1,"early strike consumes note")
 g.menu="";ch.step(.01);await process_frame;check(not is_instance_valid(ch.panel),"touch menu cleanup")
 print("v75 UI/chime failures: ",failures);g.queue_free();await process_frame;await create_timer(.45).timeout;quit(failures)

extends SceneTree
const S=preload("res://scripts/learning_store.gd")
const A=preload("res://scripts/education_access.gd")
var checks=0
var failures=0
func check(ok:bool,note:String)->void:
 checks+=1;print("PASS • " if ok else "FAIL • ",note)
 if not ok:failures+=1
func _initialize()->void:call_deferred("run")
func run()->void:
 var previous=A.state();var learning=S.load_data()
 A.unlock("student");A.unlock("teacher")
 root.set_meta("fx_intro_seen",true);root.set_meta("fx_tutorial_offered",true)
 var g=load("res://scenes/main.tscn").instantiate();root.add_child(g);current_scene=g
 for n in 8:await process_frame
 g.presentation.close();g.session_menu.resume();g.menu="";g.set_process(false)
 for place in [preload("res://scripts/idle_mine_town.gd").ENTRY,preload("res://scripts/studio_town.gd").ENTRY,Vector2(-1080,1200),Vector2(260,1165)]:check(g.can_stand_at(place),"walkable relocated entrance "+str(place))
 check(preload("res://scripts/idle_mine_town.gd").ENTRY.x<-1000,"mine on mountain frontage")
 check(g.town_places.any(func(v):return v.menu=="descent_entrance" and v.pos==Vector2(-1080,1200)),"Descent interaction follows cave")
 for code in S.catalog():
  check(S.stages(code).all(func(st):return st.id not in ["routines","competencies","pathway"]),code+" no repetitive journal prompts")
 var old=S.fresh();old.enabled=true;old.work.DES1020={"entries":[{"stage":"routines","text":"Existing archived journal","time":S.stamp(),"order":1}],"refs":[]};old.next=2
 check(S.valid(old),"older journal evidence preserved and valid")
 var advice=preload("res://scripts/assessment_advice.gd");var empty=S.fresh();var w=S.work(empty,"DES1020");var low=advice.module(empty,"DES1020",w)
 for stage in S.stages("DES1020"):w.entries.append({"stage":stage.id,"text":"Explanation of design choices","time":S.stamp(),"order":1})
 check(advice.module(empty,"DES1020",w).score>low.score,"suggestion responds to missing evidence")
 check(empty.submissions.is_empty(),"suggested mark never records teacher grades")
 for value in [.75,1.0,1.25]:g.media.set_normal_zoom(value);check(is_equal_approx(g.media.factor(),value),"normal zoom "+str(value))
 g.media.enable();g.media.zoom=.5;g.media.control_visible=false;g.media.update_visible()
 check(is_equal_approx(g.media.factor(),.5) and not g.media.panel.visible and g.media.restore_button.visible,"Media minimized without leaving mode; half zoom works")
 g.media.restore_button.pressed.emit();check(g.media.control_visible,"touch restore control works")
 g.media.active=false;root.remove_meta("fx_media_mode");g.media.set_normal_zoom(1)
 var buttons=[]
 for spec in [[g.presentation.adventure_button,"adventures"],[g.session_menu.menu_button,"menu"],[g.legacy.get_node("Quick"),"profile"]]:
  preload("res://scripts/town_top_bar.gd").place(spec[0],spec[1],Vector2(1280,720));buttons.append(spec[0].get_global_rect())
 check(buttons[0].end.x<buttons[1].position.x and buttons[1].end.x<buttons[2].position.x,"uniform top buttons leave education space")
 var wins=g.legacy.card.state().arena.standard.wins;g.legacy.card.state().arena.standard.wins=10;check(g.arena_town.wins(g)>=10,"Grand stadium unlocked at ten wins");g.legacy.card.state().arena.standard.wins=wins
 for view in [Vector2i(1280,720),Vector2i(896,414)]:
  root.size=view
  for n in 30:await process_frame
  var area=root.get_visible_rect()
  var tools=root.get_node("FXEducationTools")
  var rects=[g.presentation.adventure_button.get_global_rect(),g.session_menu.menu_button.get_global_rect(),tools.row.get_global_rect(),g.legacy.get_node("Quick").get_global_rect()]
  for i in rects.size():
   check(area.encloses(rects[i]),"top control inside screen "+str(view)+" / "+str(i))
   if i>0:check(not rects[i-1].intersects(rects[i]),"top controls do not overlap "+str(view)+" / "+str(i))
 root.size=Vector2i(1280,720)
 g.hero_workshop.open(true)
 for n in 5:await process_frame
 var room=g.hero_workshop.room
 check(room.stations.size()==6,"six academy workstations")
 check(room.progress("DES1020")>=0 and room.progress("DES1020")<=1,"module gauge includes work and writing")
 room.open_progress();check(is_instance_valid(room.progress_panel),"progress workstation opens module gauges");room.progress_panel.queue_free();await process_frame
 room.player=Vector2(450,520);room._process(0);await process_frame
 check(not g.hero_workshop.active and g.menu=="","walking out academy returns to town")
 check(A.revoke("student") and not A.state().student and not S.load_data().enabled,"student access revocation persists")
 check(A.revoke("teacher") and not A.state().teacher,"teacher access revocation persists")
 preload("res://scripts/profile_store.gd").write(A.PATH,previous);S.save(learning)
 print("V145 ",checks," checks / ",failures," failures");quit(1 if failures else 0)

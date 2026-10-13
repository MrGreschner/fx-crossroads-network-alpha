extends SceneTree
var failures:=0
func check(ok:bool,message:String)->void:
 if not ok:failures+=1;print("FAIL: ",message)
func _initialize()->void:call_deferred("run")
func run()->void:
 root.set_meta("fx_intro_seen",true)
 var g=load("res://scenes/main.tscn").instantiate();root.add_child(g);await process_frame;g.set_process(false);g.legacy.set_process(false);g.presentation.asked=true;g.presentation.close();g.session_menu.resume()
 check(g.characters.vesper.special.duration==4,"Vesper veil is four seconds")
 g.menu="journey_cosmetics";var ui=g.journey.cosmetics_ui;ui._process(0);await process_frame;check(ui.panel.visible,"native cosmetics panel opens")
 var old:String=g.journey.data.title;ui.equip(4,false);check(g.journey.data.title==old,"locked title cannot be equipped")
 g.journey.unlock("Grovekeeper");ui.equip(2,false);ui.equip(2,true);check(g.journey.data.title=="Grovekeeper" and g.journey.data.colour==2,"title and ribbon buttons equip earned selections")
 g.menu="";ui._process(0);check(not ui.panel.visible,"cosmetics panel closes without intercepting gameplay")
 g.legacy.open_page("elder");check(g.legacy.ELDER_TOPICS.size()>=10,"Elder knows all modern gameplay categories");g.legacy.answer("How do I play battlegrounds?");check(g.legacy.notice.text.contains("barracks"),"freeform battleground guidance")
 g.legacy.answer("How do I join friends?");check(not g.legacy.notice.text.contains("Join Random") and g.legacy.notice.text.contains("Public Rooms"),"Elder uses current public room flow")
 g.legacy.close()
 var scenery=g.town_scenery;check(not g.can_stand_at(scenery.POND),"new pond water remains blocked")
 check(scenery.POND.y-100>215,"pond shore clears the north fence")
 check(scenery.POND.y+100<450,"pond shoreline clears the first mountain peak")
 for tree in scenery.trees:check(not Rect2(tree-Vector2(55,115),Vector2(110,145)).intersects(Rect2(scenery.POND-Vector2(164,105),Vector2(328,210))),"tree crown clears pond garden")
 for point in [Vector2(414,420),Vector2(325,455),Vector2(285,488),Vector2(290,550)]:check(g.can_stand_at(point),"pond walking path stays open "+str(point))
 g.queue_free();await process_frame;await process_frame
 var a=load("res://scenes/arcade.tscn").instantiate();root.add_child(a);await process_frame;a.set_process(false);a.party_tools.set_process(false);a.legacy.set_process(false);a.presentation.asked=true;a.presentation.close();a.session_menu.resume();a._set_mode("arena");a.bot_count=1;a._solo();a.start_countdown=0
 a.update_arena_notice(0);check(a.arena_notice_left==5,"arena notice starts with five seconds")
 for n in 12:a.update_arena_notice(.5)
 check(a.arena_notice_left==0,"identical status text fades despite repeated snapshots")
 a.status_label.text="New game event";a.update_arena_notice(.1);check(a.arena_notice_left==5,"new events get their own short notice")
 var board=a.respawn_board;board._process(.1);check(board.toggle.visible and not board.panel.visible,"alive arena player has scoreboard button")
 board.toggle.pressed.emit();board._process(.1);check(board.panel.visible and board.heading.text=="LIVE MATCH LEADERS","manual live scoreboard opens")
 board.toggle.pressed.emit();board._process(.1);check(not board.panel.visible,"scoreboard toggles closed")
 a.health[a.my_id]=0;a.respawn_at[a.my_id]=Time.get_ticks_msec()+2000;board._process(.1);check(board.panel.visible and board.heading.text.contains("Respawn"),"automatic respawn scoreboard remains")
 a.health[a.my_id]=50;board._process(.1);check(not board.panel.visible,"auto scoreboard closes on respawn")
 a.queue_free();await process_frame;await process_frame;print("v97 additions failures: ",failures);quit(failures)

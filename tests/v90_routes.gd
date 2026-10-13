extends SceneTree
var failures:=0
func check(ok:bool,label:String)->void:
 if not ok:failures+=1;print("FAIL: ",label)
func _initialize()->void:call_deferred("run")
func run()->void:
 root.set_meta("fx_intro_seen",true)
 var g=load("res://scenes/main.tscn").instantiate();root.add_child(g);await process_frame;g.set_process(false);g.legacy.set_process(false);g.presentation.asked=true;g.presentation.close();g.session_menu.resume()
 for id in g.legacy.PROJECTS:g.legacy.data.town[id]=true
 var seen:Dictionary={};var queue:Array[Vector2i]=[Vector2i(45,32)];seen[queue[0]]=true;var cursor:=0
 while cursor<queue.size():
  var cell:Vector2i=queue[cursor];cursor+=1
  for off in [Vector2i.UP,Vector2i.DOWN,Vector2i.LEFT,Vector2i.RIGHT]:
   var next:Vector2i=cell+off
   if next.x<1 or next.y < -26 or next.x>=154 or next.y>=111 or seen.has(next):continue
   if g.can_stand_at(Vector2(next)*20):seen[next]=true;queue.append(next)
 var targets:Array=[]
 for entry in g.town_places:targets.append([entry.pos,str(entry.menu)])
 for entry in [[Vector2(2640,1160),"east quest forest"],[g.town_polish.DOOR,"chimehouse east bank"],[Vector2(1775,1550),"fellowship"],[Vector2(400,1720),"relay"],[Vector2(1720,480),"observatory"],[Vector2(2200,1580),"mill"],[Vector2(1370,1940),"ox garden"],[Vector2(230,1330),"closed mine approach"]]:targets.append(entry)
 for entry in targets:
  var point:Vector2=entry[0];var near:=false
  for off in [Vector2i.ZERO,Vector2i.UP,Vector2i.DOWN,Vector2i.LEFT,Vector2i.RIGHT]:
   if seen.has(Vector2i(roundi(point.x/20),roundi(point.y/20))+off):near=true
  check(g.can_stand_at(point) and near,"all-upgrades accessible: "+str(entry[1]))
 # Guide replay uses the real selector, not a separate tutorial copy.
 g.enter_region("practice");g.menu="training_guide";g.town_services._process(.1)
 for b in g.town_services.body.get_children():
  if b is Button and b.text.begins_with("REPLAY"):b.pressed.emit()
 check(g.presentation.page=="starter","guide replay opens first-nine selector")
 g.presentation.close();g.menu="food";g.catalog_ui._process(.1);await process_frame;await process_frame
 var bar:VScrollBar=g.catalog_ui.scroll.get_v_scroll_bar();check(bar.max_value>bar.page,"shop has scrollable native content");bar.value=bar.max_value;check(g.catalog_ui.scroll.scroll_vertical>0,"native scrollbar controls list")
 g.catalog_ui.close();g.enter_region("honeyglass");var w=g.adventure.immersive;w.stage=1;w.rebuild_grid()
 var start:Vector2=w.v(w.data.spawn)
 for spawn in w.data.spawns:check(w.route(start,w.v(spawn.pos)).size()>0,"honeyglass route to "+str(spawn.type))
 check(w.route(start,w.v(w.data.exit)).size()>0,"honeyglass route to boss exit")
 g.queue_free();await process_frame;print("v90 routes failures: ",failures);quit(failures)

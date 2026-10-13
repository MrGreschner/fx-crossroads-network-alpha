extends SceneTree
var failures:=0
var g:Node
func check(ok:bool,title:String)->void:
 if not ok:failures+=1;print("FAIL: ",title)
func _initialize()->void:call_deferred("run")
func touch(helper:Node,p:Vector2,pressed:bool,index:int=7)->void:
 var e:=InputEventScreenTouch.new();e.position=p;e.pressed=pressed;e.index=index;helper.handle(e)
func drag(helper:Node,p:Vector2,index:int=7)->void:
 var e:=InputEventScreenDrag.new();e.position=p;e.index=index;helper.handle(e)
func helper_of(s:ScrollContainer)->Node:
 for child in s.get_children():
  if child.get_script()==load("res://scripts/touch_list_scroll.gd"):return child
 return null
func point(c:Control,p:Vector2)->Vector2:return c.get_global_transform_with_canvas()*p
func run()->void:
 root.set_meta("fx_intro_seen",true);root.set_meta("fx_tutorial_offered",true)
 g=load("res://scenes/main.tscn").instantiate();root.add_child(g);current_scene=g
 await process_frame;g.set_process(false);g.presentation.close();g.session_menu.resume();g.menu="characters"
 for n in 4:await process_frame
 var hall:Node=g.hero_hall;hall.set_process(false);hall.panel.scale=Vector2(.5,.5)
 for n in 3:await process_frame
 var h:Node=helper_of(hall.scroller);check(h!=null,"hero list has touch helper")
 var p:=point(hall.scroller,Vector2(180,120));var selected:String=g.selected_character
 touch(h,p,true);check(g.selected_character==selected,"touch down does not select row")
 drag(h,p-Vector2(0,80));check(hall.scroller.scroll_vertical>=150,"scaled list follows finger")
 touch(h,p-Vector2(0,80),false);check(g.selected_character==selected,"drag release does not select")
 var before:int=hall.scroller.scroll_vertical;h._process(.03);check(hall.scroller.scroll_vertical>before,"swipe glides briefly after release")
 h.cancel();hall.scroller.scroll_vertical=0;await process_frame
 var target:Button=hall.rows.get_child(1).get_child(0).get_child(1)
 var target_id:String=hall.shown[1];p=point(target,target.size*.5)
 touch(h,p,true);touch(h,p,false);check(g.selected_character==target_id,"tap still selects hero")
 var emulated:=InputEventMouseButton.new();emulated.device=-1;emulated.position=p;emulated.button_index=MOUSE_BUTTON_LEFT;emulated.pressed=true
 check(h.handle(emulated),"synthetic mouse does not select a second time")
 hall.close();g.menu="portal"
 for n in 4:await process_frame
 var cat:Node=g.catalog_ui;cat.set_process(false);cat.panel.scale=Vector2(.5,.5)
 for n in 3:await process_frame
 h=helper_of(cat.scroll);p=point(cat.scroll,Vector2(150,110));var row:int=cat.selected
 touch(h,p,true);drag(h,p-Vector2(0,60));touch(h,p-Vector2(0,60),false)
 check(cat.scroll.scroll_vertical>=100 and cat.selected==row,"realm list swipe scrolls without changing selection")
 h.cancel();cat.scroll.scroll_vertical=0;await process_frame
 target=cat.rows.get_child(1);p=point(target,target.size*.5);touch(h,p,true);touch(h,p,false);check(cat.selected==1,"realm tap selects row")
 check(helper_of(hall.right_scroller)!=null,"hero details also swipe")
 for menu in ["supplies","food"]:
  g.menu=menu;cat.context=menu;cat.render();await process_frame;await process_frame
  var gold:int=g.gold;p=point(cat.scroll,Vector2(150,100));h.cancel();cat.scroll.scroll_vertical=0;touch(h,p,true);drag(h,p-Vector2(0,70));touch(h,p-Vector2(0,70),false)
  check(cat.scroll.scroll_vertical>0,"shop swipe "+menu);check(g.gold==gold,"swiping does not buy "+menu)
 h.cancel();cat.scroll.scroll_vertical=0;p=point(cat.scroll,Vector2(150,100));var previous_gold:int=g.gold
 var down:=InputEventScreenTouch.new();down.index=11;down.position=p;down.pressed=true;root.push_input(down,true)
 var slide:=InputEventScreenDrag.new();slide.index=11;slide.position=p-Vector2(0,70);slide.relative=Vector2(0,-70);root.push_input(slide,true)
 var up:=InputEventScreenTouch.new();up.index=11;up.position=slide.position;up.pressed=false;root.push_input(up,true)
 check(cat.scroll.scroll_vertical>0 and g.gold==previous_gold,"viewport input routes swipe through real UI without buying")
 h.cancel();cat.panel.hide();touch(h,p,true);check(h.finger==-1,"hidden menu cannot capture touch")
 for a in g.find_children("*","AudioStreamPlayer",true,false):a.stop();a.stream=null
 g.queue_free();await process_frame;await process_frame;await create_timer(.2).timeout
 print("v122 failures: ",failures);quit(1 if failures else 0)

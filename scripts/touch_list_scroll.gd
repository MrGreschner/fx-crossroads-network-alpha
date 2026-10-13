extends Node
## Capture touch before row buttons: drag scrolls, release without a drag selects.
var form_controls:=false
var scroller:ScrollContainer
var finger:=-1
var start:=Vector2.ZERO
var last:=Vector2.ZERO
var last_msec:=0
var moved:=false
var tapped:BaseButton
var offset:=0.0
var velocity:=0.0
var suppress_mouse_until:=0
const DRAG_PIXELS=12.0
static func attach(target:ScrollContainer)->Node:
 var helper:Node=load("res://scripts/touch_list_scroll.gd").new()
 helper.scroller=target;target.add_child(helper);helper.set_process(false)
 return helper
func contains(control:Control,point:Vector2)->bool:
 return control.is_visible_in_tree() and Rect2(Vector2.ZERO,control.size).has_point(control.get_global_transform_with_canvas().affine_inverse()*point)
func button_at(node:Node,point:Vector2)->BaseButton:
 var children:=node.get_children();children.reverse()
 for child in children:
  if child is Control and not child.is_visible_in_tree():continue
  var found:=button_at(child,point)
  if found!=null:return found
 if node is BaseButton and not node.disabled and contains(node,point):return node
 return null
func form_at(node:Node,point:Vector2)->bool:
 for child in node.get_children():
  if child is Control and not child.is_visible_in_tree():continue
  if form_at(child,point):return true
 return node is Control and (node is LineEdit or node is TextEdit or node is Slider or node is SpinBox or node is OptionButton or node is ColorPickerButton) and contains(node,point)
func cancel()->void:
 finger=-1;tapped=null;velocity=0;set_process(false)
func apply_scroll(value:float)->void:
 var bar:VScrollBar=scroller.get_v_scroll_bar()
 offset=clampf(value,0,maxf(0,bar.max_value-bar.page));scroller.scroll_vertical=roundi(offset)
func handle(event:InputEvent)->bool:
 if scroller==null or not scroller.is_visible_in_tree():cancel();return false
 if event is InputEventMouse and event.device==-1 and Time.get_ticks_msec()<suppress_mouse_until and (finger>=0 or contains(scroller,event.position)):return true
 if event is InputEventScreenTouch:
  if event.pressed:
   if finger>=0 or not contains(scroller,event.position):return false
   # Preserve native thumb dragging for anyone who prefers the scrollbar.
   if contains(scroller.get_v_scroll_bar(),event.position):return false
   if form_controls and form_at(scroller,event.position):return false
   finger=event.index;start=event.position;last=start;last_msec=Time.get_ticks_msec();moved=false;velocity=0;offset=float(scroller.scroll_vertical);tapped=button_at(scroller,start);set_process(true);suppress_mouse_until=Time.get_ticks_msec()+400
   return true
  if event.index!=finger:return false
  var action:BaseButton=tapped;var select:bool=not moved and event.position.distance_to(start)<DRAG_PIXELS
  finger=-1;tapped=null;suppress_mouse_until=Time.get_ticks_msec()+400
  if select:
   velocity=0;set_process(false)
   if is_instance_valid(action) and not action.disabled and action.is_visible_in_tree() and contains(action,event.position):
    if action.toggle_mode:
     if form_controls:action.button_pressed=not action.button_pressed
     else:action.set_pressed_no_signal(not action.button_pressed)
    action.pressed.emit()
  return true
 if event is InputEventScreenDrag and event.index==finger:
  var now:=Time.get_ticks_msec();var elapsed:float=maxf(.016,(now-last_msec)/1000.0)
  if not moved and event.position.distance_to(start)>=DRAG_PIXELS:moved=true
  if moved:
   var scale_y:float=maxf(.01,scroller.get_global_transform_with_canvas().y.length())
   var dy:float=(last.y-event.position.y)/scale_y
   apply_scroll(offset+dy);velocity=lerpf(velocity,clampf(dy/elapsed,-2400,2400),.5)
  last=event.position;last_msec=now;suppress_mouse_until=now+400
  return true
 return false
func _input(event:InputEvent)->void:
 if handle(event):get_viewport().set_input_as_handled()
func _process(delta:float)->void:
 if not scroller.is_visible_in_tree():cancel();return
 if finger>=0:return
 if absf(velocity)<15:velocity=0;set_process(false);return
 var before:=offset;apply_scroll(offset+velocity*minf(delta,.05))
 velocity=move_toward(velocity,0,2200*delta)
 if is_equal_approx(before,offset):velocity=0;set_process(false)
func _notification(what:int)->void:
 if what==NOTIFICATION_APPLICATION_FOCUS_OUT:cancel()

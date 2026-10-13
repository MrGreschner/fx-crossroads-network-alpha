extends Node
## Native browser input for touch chat and hero search. Never saved or sent over the network.
var field:LineEdit
var bridge:JavaScriptObject
var input_callback:JavaScriptObject
var submit_callback:JavaScriptObject
var timer:=0.0
func setup(edit:LineEdit,submit_hint:String="send")->void:
 field=edit
 if not OS.has_feature("web") or not bool(JavaScriptBridge.eval("navigator.maxTouchPoints>0 || matchMedia('(pointer:coarse)').matches",true)):
  set_process(false);return
 field.virtual_keyboard_enabled=false
 JavaScriptBridge.eval(FileAccess.get_file_as_string("res://web/elder_input.js"),true)
 bridge=JavaScriptBridge.get_interface("window").fxElderTyping
 input_callback=JavaScriptBridge.create_callback(receive_text)
 submit_callback=JavaScriptBridge.create_callback(submit_text)
 bridge.changed=input_callback;bridge.submitted=submit_callback
 bridge.configure(field.text,field.placeholder_text,field.secret,field.max_length if field.max_length>0 else 1000,submit_hint)
func receive_text(args:Array)->void:
 if is_instance_valid(field) and not args.is_empty():
  field.text=str(args[0]).left(field.max_length) if field.max_length>0 else str(args[0]);field.text_changed.emit(field.text)
func submit_text(args:Array)->void:
 receive_text(args)
 if is_instance_valid(field):field.text_submitted.emit(field.text)
func _process(delta:float)->void:
 if bridge==null or not is_instance_valid(field):return
 timer-=delta
 if timer>0:return
 timer=.08
 var rect:Rect2=field.get_global_rect();var view:Vector2=field.get_viewport_rect().size
 var shown:=field.is_visible_in_tree()
 var ancestor:Node=field.get_parent()
 while ancestor!=null:
  if ancestor is Control and ancestor.clip_contents and not ancestor.get_global_rect().encloses(rect):shown=false
  ancestor=ancestor.get_parent()
 bridge.value(field.text)
 bridge.place(rect.position.x,rect.position.y,rect.size.x,rect.size.y,view.x,view.y,shown)
func _exit_tree()->void:
 if bridge!=null:bridge.dispose();bridge=null

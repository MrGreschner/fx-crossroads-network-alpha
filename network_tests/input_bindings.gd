extends SceneTree
func _initialize()->void:call_deferred("run")
func run()->void:
 var g=load("res://network/client.tscn").instantiate();root.add_child(g);current_scene=g
 await process_frame
 var failures=0
 for binding in [["move_left",KEY_A],["move_right",KEY_D],["move_up",KEY_W],["move_down",KEY_S],["special",KEY_SPACE],["dodge",KEY_SHIFT],["interact",KEY_E]]:
  var event=InputEventKey.new();event.physical_keycode=binding[1];event.pressed=true
  Input.parse_input_event(event);Input.flush_buffered_events()
  if not Input.is_action_pressed(binding[0]):failures+=1;push_error("Unbound key: "+binding[0])
  event=event.duplicate();event.pressed=false;Input.parse_input_event(event);Input.flush_buffered_events()
 for binding in [["primary",MOUSE_BUTTON_LEFT],["secondary",MOUSE_BUTTON_RIGHT]]:
  var event=InputEventMouseButton.new();event.button_index=binding[1];event.pressed=true
  Input.parse_input_event(event);Input.flush_buffered_events()
  if not Input.is_action_pressed(binding[0]):failures+=1;push_error("Unbound mouse: "+binding[0])
  event=event.duplicate();event.pressed=false;Input.parse_input_event(event);Input.flush_buffered_events()
 print("Physical input checks: ",failures," failures")
 quit(1 if failures else 0)

extends SceneTree
var failures=0
func check(ok:bool,message:String)->void:
 print("PASS: " if ok else "FAIL: ",message)
 if not ok:failures+=1
func _initialize()->void:call_deferred("run")
func run()->void:
 root.set_meta("fx_intro_seen",true);root.set_meta("fx_tutorial_offered",true)
 var game=load("res://scenes/main.tscn").instantiate();root.add_child(game);current_scene=game;await process_frame;game.set_process(false);game.presentation.close();game.session_menu.resume()
 var w=game.hero_workshop;w.open();w.open_lab();await process_frame
 var lab=w.lab
 lab.animation_editor();await process_frame
 var dialog:CanvasLayer
 for child in lab.get_children():
  if child.get_script()==preload("res://scripts/studio_frames.gd"):dialog=child
 lab.edit_frame(0,dialog);await process_frame
 check(not dialog.visible,"animation window hides during frame editing")
 var editor:CanvasLayer
 for child in lab.get_children():
  if child.has_signal("saved"):editor=child
 var encoded=editor.canvas.encoded()
 # Reproduce the screenshot: parent window disappears before frame is saved.
 dialog.queue_free();await process_frame
 editor.saved.emit(encoded);editor.queue_free();await process_frame
 check(lab.attack.animation.size()==1,"save succeeds after parent window is freed")
 for child in lab.get_children():
  if child.get_script()==preload("res://scripts/studio_frames.gd"):dialog=child
 lab.edit_frame(0,dialog);await process_frame
 for child in lab.get_children():
  if child.has_signal("saved"):editor=child
 editor.queue_free();await process_frame;await process_frame
 check(is_instance_valid(dialog) and dialog.visible,"cancel returns to animation window")
 lab.edit_frame(1,dialog);await process_frame
 for child in lab.get_children():
  if child.has_signal("saved"):editor=child
 editor.saved.emit(encoded);editor.queue_free();await process_frame
 check(lab.attack.animation.size()==2,"normal save adds a second frame")
 check(preload("res://scripts/workshop_project.gd").validate_attack(lab.attack).is_empty(),"saved animation validates")
 game.queue_free();await process_frame;await process_frame
 print("V125 failures: ",failures);quit(1 if failures else 0)

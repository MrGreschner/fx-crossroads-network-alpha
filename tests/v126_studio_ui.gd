extends SceneTree
const UI=preload("res://scripts/studio_ui.gd")
var failures=0
func check(ok:bool,message:String)->void:
 print("PASS: " if ok else "FAIL: ",message)
 if not ok:failures+=1
func _initialize()->void:call_deferred("run")
func run()->void:
 var briefs=JSON.parse_string(FileAccess.get_file_as_string("res://content/studio/assignments.json"))
 check(briefs.size()==6,"assignment board has all six requested project areas")
 for entry in briefs:check(entry.has("summary") and entry.has("body") and entry.has("task") and entry.has("deliver") and entry.has("criteria"),"complete assignment brief: "+str(entry.title))
 for size in [Vector2i(1280,720),Vector2i(960,540),Vector2i(640,360)]:
  var view=SubViewport.new();view.size=size;root.add_child(view)
  var page=UI.lesson(view,"CLASSROOM ASSIGNMENT BOARD","Build, test and explain.",briefs)
  for n in 8:await process_frame
  var rect=Rect2(page.panel.position,page.panel.size*page.panel.scale)
  check(rect.position.x>=0 and rect.position.y>=0 and rect.end.x<=size.x and rect.end.y<=size.y,"assignment modal stays in viewport "+str(size))
  for i in briefs.size():page.show_topic(i);check(page.selected==i and page.content.get_child_count()==6,"topic opens all five information cards: "+str(i))
  view.queue_free();await process_frame
 root.set_meta("fx_intro_seen",true);root.set_meta("fx_tutorial_offered",true)
 var game=load("res://scenes/main.tscn").instantiate();root.add_child(game);current_scene=game;await process_frame;game.set_process(false);game.presentation.close();game.session_menu.resume()
 var w=game.hero_workshop;w.project=preload("res://scripts/workshop_project.gd").fresh();w.open();w.enter_classroom();await process_frame
 w.room.player=w.room.board-Vector2(0,-30);Input.action_press("interact");await process_frame;Input.action_release("interact");await process_frame
 check(is_instance_valid(w.room.assignments),"physical classroom board opens with E")
 var start=w.room.player;w.room.touch_move=Vector2.RIGHT;await process_frame;w.room.touch_move=Vector2.ZERO;check(w.room.player==start,"reading assignment board keeps classroom movement still")
 var key=InputEventKey.new();key.keycode=KEY_ESCAPE;key.pressed=true;w.room.assignments._input(key);await process_frame
 check(not is_instance_valid(w.room.assignments) and w.active,"Escape closes notes while keeping Studio open")
 w.room.queue_free();await process_frame;w.show_hub();w.hub.hide();w.panel.show()
 w.design_lesson();await process_frame
 var notes:Node
 for child in w.get_children():
  if child.get_script()==preload("res://scripts/studio_notes.gd"):notes=child
 check(is_instance_valid(notes) and notes.topics.size()==4,"design lesson opens its own four-topic page without pixel editor")
 notes.queue_free();await process_frame;w.open_lab();await process_frame
 w.lab.attack.animation=[]
 var image=Image.create(16,16,false,Image.FORMAT_RGBA8);image.fill(Color("#edcf91"));var png=Marshalls.raw_to_base64(image.save_png_to_buffer())
 for i in 8:w.lab.attack.animation.append(png)
 w.lab.animation_editor();await process_frame
 var frames:Node
 for child in w.lab.get_children():
  if child.get_script()==preload("res://scripts/studio_frames.gd"):frames=child
 for n in 8:await process_frame
 check(is_instance_valid(frames) and frames.panel.size.y<=root.get_visible_rect().size.y,"eight-frame editor fits screen and scrolls its thumbnails")
 check(game.manifest.characters.size()==80,"official roster unchanged")
 game.queue_free();await process_frame;await process_frame
 print("V126 failures: ",failures);quit(1 if failures else 0)

extends SceneTree
const Examples=preload("res://scripts/studio_examples.gd")
var failures=0
func check(ok:bool,label:String)->void:
 print("PASS: " if ok else "FAIL: ",label)
 if not ok:failures+=1
func _initialize()->void:call_deferred("run")
func run()->void:
 for kind in ["hero","ability","enemy","behavior"]:
  var examples=Examples.all(kind);check(examples.size()==5,"five "+kind+" examples")
  for example in examples:
   var issue=preload("res://scripts/workshop_project.gd").validate(example) if kind=="hero" else preload("res://scripts/workshop_project.gd").validate_attack(example) if kind=="ability" else preload("res://scripts/studio_enemy_project.gd").validate(example) if kind=="enemy" else preload("res://scripts/studio_behavior.gd").validate(example)
   check(issue.is_empty(),"valid portable "+kind+" example")
   if kind in ["hero","enemy"]:check((example.hero.art if kind=="hero" else example.art).size()==4,"example has four poses")
  var chosen=Examples.random_example(kind);check(examples.any(func(value:Dictionary):return (value.hero.name==chosen.hero.name if kind=="hero" else value.name==chosen.name)),"random first draft from curated set")
 var image=Image.create(320,180,false,Image.FORMAT_RGB8);image.fill(Color("#43726c"));var bytes=image.save_jpg_to_buffer(.5);FileAccess.open("res://content/workshop/classroom-test.jpg",FileAccess.WRITE).store_buffer(bytes)
 var cast=root.get_node("FXClassroom");check(cast.seats.get_child_count()==31,"31 seats plus separate teacher heading")
 cast.packet({"type":"class_joined","id":"student","host":false,"code":"CLABCDEF"});cast.packet({"type":"class_status","roster":[{"id":"student","name":"Student"}],"started":true})
 check(paused and cast.view.visible,"student gameplay pauses under a view-only overlay")
 cast.packet({"type":"class_frame","image":Marshalls.raw_to_base64(bytes),"seq":1});check(cast.picture.texture!=null,"shared JPEG reaches student screen")
 cast.packet({"type":"class_frame","image":Marshalls.raw_to_base64(bytes),"seq":0});check(cast.received_sequence==1,"older frames ignored")
 cast.leave();check(not paused and cast.picture.texture==null,"leaving restores controls and clears shared image")
 cast.packet({"type":"class_joined","id":"student","host":false,"code":"CLABCDEF"});cast.packet({"type":"class_start"});cast.packet({"type":"class_closed","message":"Teacher finished"});check(not paused and cast.panel.visible,"teacher leaving returns students to their own game")
 print("CLASSROOM / EXAMPLES failures: ",failures);quit(failures)

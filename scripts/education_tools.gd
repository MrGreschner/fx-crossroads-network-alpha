extends CanvasLayer
const A=preload("res://scripts/education_access.gd")
var canvas:Control
var row:HBoxContainer
var student:CheckButton
var teacher:CheckButton
var spotlight=false
var point=Vector2(-100,-100)
var age=0.0
var tick=0.0
func _ready()->void:
 layer=105;canvas=Control.new();canvas.mouse_filter=Control.MOUSE_FILTER_IGNORE;var overlay=CanvasLayer.new();overlay.layer=145;add_child(overlay);overlay.add_child(canvas);canvas.draw.connect(paint);process_mode=Node.PROCESS_MODE_ALWAYS;row=HBoxContainer.new();add_child(row);preload("res://scripts/studio_ui.gd").apply(row)
 student=CheckButton.new();student.text="Student";row.add_child(student);student.add_theme_font_size_override("font_size",15);student.toggled.connect(func(on:bool):A.toggle("student",on))
 teacher=CheckButton.new();teacher.text="Teacher";row.add_child(teacher);teacher.add_theme_font_size_override("font_size",15);teacher.toggled.connect(func(on:bool):A.toggle("teacher",on))
 for b in row.get_children():
  b.custom_minimum_size=Vector2(134,44)
  for name in ["normal","hover","pressed","disabled","focus"]:
   var skin=StyleBoxEmpty.new();skin.content_margin_left=3;skin.content_margin_right=3;skin.content_margin_top=5;skin.content_margin_bottom=5;b.add_theme_stylebox_override(name,skin)
func legacy()->Node:
 var scene=get_tree().current_scene
 return scene.legacy if scene!=null and "legacy" in scene else null
func _process(dt:float)->void:
 age=maxf(0,age-dt);tick+=dt
 if tick>.4:
  tick=0;var s=A.state();student.visible=s.student;student.set_pressed_no_signal(s.student_on);teacher.visible=s.teacher and not s.student;teacher.set_pressed_no_signal(s.teacher_on)
  var l=legacy();row.visible=l!=null and "menu" in l.game and (s.student or s.teacher) and l.game.mode=="town" and l.game.menu=="" and l.game.session_menu.page.is_empty()
  preload("res://scripts/town_top_bar.gd").place(row,"education",get_viewport().get_visible_rect().size)
 canvas.queue_redraw()
func _input(event:InputEvent)->void:
 if spotlight and event is InputEventMouseButton and event.pressed and event.button_index==MOUSE_BUTTON_LEFT:
  spotlight=false;point=event.position;age=8;get_viewport().set_input_as_handled()
func paint()->void:
 if age<=0:return
 canvas.draw_circle(point,36,Color(1,.85,.3,.13));canvas.draw_arc(point,38+sin(age*4)*3,0,TAU,48,Color(1,.85,.3,minf(1,age)),3)

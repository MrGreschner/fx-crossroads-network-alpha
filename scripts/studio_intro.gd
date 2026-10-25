extends Control
var clock=0.0
var font:Font=preload("res://assets/fonts/CrossroadsUI.ttf")
var actors:Array=[]
func _ready()->void:
 set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);mouse_filter=Control.MOUSE_FILTER_STOP;z_index=100
 for sprite in ["ram","cat"]:
  for frame in ["walk1","walk2"]:actors.append(preload("res://scripts/core_hero_art.gd").texture(sprite,str(frame)))
func _process(delta:float)->void:
 clock+=delta;modulate.a=clampf((3-clock)/.45,0,1);queue_redraw()
 if clock>=3:queue_free()
func _gui_input(event:InputEvent)->void:
 if event is InputEventMouseButton and event.pressed:queue_free()
func _draw()->void:
 draw_rect(Rect2(Vector2.ZERO,size),Color("#0c2432"))
 var c=size*.5
 for i in 12:
  var p=c+Vector2(cos(i*TAU/12+clock*.2),sin(i*TAU/12+clock*.2))*Vector2(330,140)
  draw_circle(p,3,Color("#63a8b1"))
 draw_arc(c,210,0,TAU,64,Color("#294857"),2)
 draw_string(font,c+Vector2(-205,-105),"CROSSROADS STUDIO",HORIZONTAL_ALIGNMENT_CENTER,410,32,Color("#f1d59d"))
 draw_string(font,c+Vector2(-210,135),"Imagine. Build. Test. Make it yours.",HORIZONTAL_ALIGNMENT_CENTER,420,20,Color("#a9d9dc"))
 for i in 2:
  var p=c+Vector2(-145+i*290,sin(clock*8+i)*4)
  if actors.size()>i*2+1:draw_texture_rect(actors[i*2+int(clock*7)%2],Rect2(p-Vector2(30,45),Vector2(60,75)),false)
  draw_arc(p,44,-PI*.5,TAU*clampf(clock/2,0,1)-PI*.5,32,Color("#dfba6e"),3)
 var phase=fmod(clock,1.3)/1.3;var shot=c+Vector2(-95+phase*190,-8+sin(phase*PI)*-30)
 draw_circle(shot,8,Color("#8fcce4"));draw_line(shot-Vector2(22,0),shot,Color("#e4f4e8"),3)
 for i in 4:draw_arc(c+Vector2(145,0),20+i*8,-clock+i*.4,PI-clock+i*.4,20,Color(.8,.65,.4,.2),2)
 draw_string(font,c+Vector2(-160,170),"Click to skip",HORIZONTAL_ALIGNMENT_CENTER,320,14,Color("#81a6b1"))

extends Node2D
## Draw-only HUD notice: no Control, minimum size, focus, mouse capture or modal.
var message:=""
var size:=Vector2(600,58)
var font=preload("res://assets/fonts/CrossroadsUI.ttf")
func _draw()->void:
 draw_style_box(preload("res://scripts/studio_ui.gd").box("#203e47","#f2d184",8,8),Rect2(Vector2.ZERO,size))
 var words=message.split(" ");var lines:Array[String]=[];var line:=""
 for word in words:
  var next: String=word if line.is_empty() else line+" "+word
  if font.get_string_size(next,HORIZONTAL_ALIGNMENT_LEFT,-1,15).x>size.x-24 and not line.is_empty():lines.append(line);line=word
  else:line=next
 if not line.is_empty():lines.append(line)
 for n in mini(3,lines.size()):draw_string(font,Vector2(12,20+n*18),lines[n],HORIZONTAL_ALIGNMENT_LEFT,size.x-24,15,Color("#ffe3a3"))

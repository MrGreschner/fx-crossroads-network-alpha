extends SceneTree
func _initialize()->void:
 for pose in ["idle","walk1","walk2","attack"]:
  var image:=Image.new()
  var error:=image.load_svg_from_string(FileAccess.get_file_as_string("res://assets/hearth_herald_"+pose+".svg"))
  if error!=OK:quit(1);return
  image.save_png("res://assets/hearth_herald_"+pose+".png")
  var alias:String="hearth_herald_0" if pose=="idle" else "hearth_herald_1" if pose=="walk1" else "hearth_herald_2" if pose=="walk2" else ""
  if not alias.is_empty():image.save_png("res://assets/"+alias+".png")
  if pose=="idle":image.save_png("res://assets/hearth_herald.png")
 quit()

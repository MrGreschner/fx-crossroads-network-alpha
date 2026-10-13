extends SceneTree
func _initialize()->void:
 for path in ["education_access","education_room","education_tools","education_guide","education_ipo","education_wire","learning_auto","teacher_store","teacher_dashboard","learning_page"]:
  var s=load("res://scripts/"+path+".gd");print(path," ",s!=null and s.can_instantiate())
 quit()

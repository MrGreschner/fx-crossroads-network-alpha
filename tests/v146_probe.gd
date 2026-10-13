extends SceneTree
func _initialize()->void:
 for path in ["studio_world_project","studio_world_canvas","studio_raster_editor","studio_realm_test","studio_world_lab","studio_finalize","hero_workshop"]:
  var s=load("res://scripts/"+path+".gd");print(path," ",s.can_instantiate() if s!=null else false)
 quit()

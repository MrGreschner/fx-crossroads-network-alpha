extends RefCounted
static func texture(id:String)->Texture2D:
 return preload("res://scripts/source_art.gd").texture("res://assets/v191_item_"+id+".svg")

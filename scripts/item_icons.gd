extends RefCounted
static func texture(id:String)->Texture2D:
 var updated=preload("res://scripts/item_art245.gd").texture(id)
 if updated!=null:return updated
 return preload("res://scripts/source_art.gd").texture("res://assets/v191_item_"+id+".svg")

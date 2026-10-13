extends RefCounted
static var cached:Dictionary={}
static func data()->Dictionary:
 if cached.is_empty():cached=JSON.parse_string(FileAccess.get_file_as_string("res://content/mine-catalog.json"))
 return cached
static func biome(depth:int)->Dictionary:
 var choice:Dictionary=data().biomes[0]
 for item in data().biomes:if depth>=int(item.depth):choice=item
 return choice

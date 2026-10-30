extends RefCounted
static var data:Dictionary={}
static func load_book()->Dictionary:
 if data.is_empty():data=JSON.parse_string(FileAccess.get_file_as_string("res://content/descent203.json"))
 return data
static func profile(kind:String)->Dictionary:return load_book().enemies.get(kind,{})
static func guardian(floor:int)->String:
 return "ds_lava_heart" if floor>100 else str(load_book().boss[clampi(floor/10-1,0,9)]) if floor%10==0 else str(load_book().mid[clampi(floor/10,0,9)])
static func pool(floor:int)->Array:
 var result:Array=[]
 for key in load_book().ordinary:
  if int(profile(key).unlock)<=floor and key!="ds_wickcaller":result.append(key)
 return result

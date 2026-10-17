extends RefCounted
## Baked row runs avoid rebuilding authored collision grids during match start.
## Every room still owns its own mutable AStarGrid2D. Data changes use the fallback.
## Bump FORMAT and regenerate if collision algorithms change; authored data hashes itself.
const FORMAT=1
static var loaded:Dictionary={}
static var timings:Dictionary={}
static func populate(grid:AStarGrid2D,key:String,source:String,solid:Callable)->void:
 var began=Time.get_ticks_usec();var signature=(str(FORMAT)+source).sha256_text()
 var path="res://content/network_navigation/"+key+".json"
 var tree=Engine.get_main_loop() as SceneTree
 var bake=tree!=null and tree.root.has_meta("fx_bake_navigation")
 var value=loaded.get(key,{})
 if not bake and value.is_empty() and FileAccess.file_exists(path):
  var parsed=JSON.parse_string(FileAccess.get_file_as_string(path))
  if parsed is Dictionary:value=parsed;loaded[key]=value
 var size=grid.region.size
 var usable=not bake and value.get("signature","")==signature and int(value.get("width",0))==size.x and int(value.get("height",0))==size.y
 grid.fill_solid_region(grid.region,false)
 if usable:
  for run in value.get("runs",[]):grid.fill_solid_region(Rect2i(int(run[0]),int(run[1]),int(run[2]),1),true)
 else:
  var runs=[]
  for y in size.y:
   var start=-1
   for x in size.x+1:
    var blocked=x<size.x and bool(solid.call(grid.get_point_position(Vector2i(x,y))))
    if blocked and start<0:start=x
    if not blocked and start>=0:
     grid.fill_solid_region(Rect2i(start,y,x-start,1),true);runs.append([start,y,x-start]);start=-1
  if bake:
   DirAccess.make_dir_recursive_absolute("res://content/network_navigation")
   var file=FileAccess.open(path,FileAccess.WRITE)
   file.store_string(JSON.stringify({"format":FORMAT,"signature":signature,"width":size.x,"height":size.y,"runs":runs}));file.close()
 timings[key]={"cached":usable,"milliseconds":(Time.get_ticks_usec()-began)/1000.0,"cells":size.x*size.y}

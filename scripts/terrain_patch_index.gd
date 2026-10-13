extends RefCounted
## Broad phase for cold terrain tiles. Preserve patch order when paths overlap.
const CELL=256
var bins:Dictionary={}
var ready=false
var candidate_checks=0
func invalidate()->void:bins.clear();ready=false;candidate_checks=0
func build(patches:Array)->void:
 bins.clear()
 for index in patches.size():
  var points:PackedVector2Array=patches[index].polygon
  if points.size()<3:continue
  var box=Rect2(points[0],Vector2.ZERO)
  for point in points:box=box.expand(point)
  for x in range(floori(box.position.x/CELL),floori(box.end.x/CELL)+1):
   for y in range(floori(box.position.y/CELL),floori(box.end.y/CELL)+1):
    var cell=Vector2i(x,y)
    if not bins.has(cell):bins[cell]=[]
    bins[cell].append(index)
 ready=true
func tile(point:Vector2,base:String,patches:Array)->String:
 if not ready:build(patches)
 var result=base
 for index in bins.get(Vector2i(floori(point.x/CELL),floori(point.y/CELL)),[]):
  candidate_checks+=1
  if Geometry2D.is_point_in_polygon(point,patches[index].polygon):result=str(patches[index].tile)
 return result

extends RefCounted
## Display-only geometry. No collision, reach, hero stats or movement are changed.
const Core=preload("res://scripts/core_hero_art.gd")
static var bounds:Dictionary={}
static var atlas_bounds:Dictionary={}
static func normalized(texture:Texture2D)->Rect2:
 if texture==null:return Rect2(.2,.15,.6,.75)
 var key=texture.get_instance_id()
 if bounds.has(key):return bounds[key]
 var result=Rect2()
 Core.prepare_atlas()
 if texture is AtlasTexture and texture.atlas==Core.atlas:
  if atlas_bounds.is_empty():
   for entry in Core.atlas_frames.values():
    var r:Array=entry.rect;var b:Array=entry.bounds
    atlas_bounds[str(Rect2(r[0],r[1],r[2],r[3]))]=Rect2(float(b[0])/80,float(b[1])/80,float(b[2])/80,float(b[3])/80)
  result=atlas_bounds.get(str(texture.region),Rect2())
 if result.size==Vector2.ZERO:
  var image=texture.get_image()
  if image!=null:
   var used=image.get_used_rect();var size=Vector2(image.get_size());result=Rect2(Vector2(used.position)/size,Vector2(used.size)/size)
 if result.size==Vector2.ZERO:result=Rect2(.2,.15,.6,.75)
 if bounds.size()>=512:bounds.clear()
 bounds[key]=result
 return result
static func body(texture:Texture2D,rect:Rect2,angle:float=0,pivot:Vector2=Vector2.ZERO)->Rect2:
 var b=normalized(texture);var result=Rect2(rect.position+rect.size*b.position,rect.size*b.size)
 if is_zero_approx(angle):return result
 var points=[result.position,Vector2(result.end.x,result.position.y),result.end,Vector2(result.position.x,result.end.y)]
 var first:Vector2=pivot+(points[0]-pivot).rotated(angle);var rotated=Rect2(first,Vector2.ZERO)
 for p in points:rotated=rotated.expand(pivot+(p-pivot).rotated(angle))
 return rotated
static func reference_rect(sprite:String)->Rect2:
 var r=Rect2(-28,-42,56,64)
 if sprite=="basketball":r=Rect2(-19,-16,38,38)
 elif sprite=="ripplejaw":r=Rect2(-32,-36,64,56)
 elif sprite=="velvetwing":r.position.y-=8
 elif sprite=="navigator":r.position.y-=3
 return Core.body_rect(sprite,r,0)
static func crown(b:Rect2)->Vector2:return Vector2(b.get_center().x,b.position.y-10)
static func title(b:Rect2,has_crown:bool=false)->Vector2:return Vector2(b.get_center().x,b.position.y-(38 if has_crown else 15))
static func side(b:Rect2,right:bool=true,lane:int=0)->Vector2:
 return Vector2(b.end.x+24 if right else b.position.x-25,b.position.y+8+lane*28)

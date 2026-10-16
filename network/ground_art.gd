extends RefCounted
## Shared imported artwork; no runtime textures, viewports, physics or lifetimes.
const ATLAS=preload("res://assets/fx_ground_atlas.svg")
const FRAME=128
const EDGE=56.0
var drawn=0
var culled=0
var magma=0
var poison=0
var shadows=0
func begin()->void:
 drawn=0;culled=0;magma=0;poison=0;shadows=0
func visible(point:Vector2,radius:float,view:Vector2)->bool:
 # Padding includes the antialiased outline and half-circle decorations.
 return Rect2(Vector2.ZERO,view).grow(maxf(0,radius)*1.15+32).has_point(point)
func draw_on(c:Node2D,point:Vector2,radius:float,fade:float,clock:float,kind:String,view:Vector2)->void:
 if not visible(point,radius,view):culled+=1;return
 if radius<=0 or fade<=0:return
 var frame=posmod(int(floor(clock*12)),16) if kind=="magma" else 0
 var row=0 if kind=="magma" else 1
 var extent=radius*FRAME/EDGE
 c.draw_texture_rect_region(ATLAS,Rect2(point-Vector2.ONE*extent*.5,Vector2.ONE*extent),Rect2(frame*FRAME,row*FRAME,FRAME,FRAME),Color(1,1,1,clampf(fade,0,1)),false,true)
 drawn+=1
 if kind=="magma":magma+=1
 else:poison+=1
func shadow(c:Node2D,point:Vector2)->void:
 c.draw_texture_rect_region(ATLAS,Rect2(point+Vector2(-23,11.1),Vector2(46,13.8)),Rect2(8,264,112,112),Color.WHITE,false,true)
 shadows+=1
func counters()->Dictionary:return {"drawn":drawn,"culled":culled,"magma":magma,"poison":poison,"shadows":shadows}

extends Control
var media:Node
func _ready()->void:
 mouse_filter=Control.MOUSE_FILTER_IGNORE;set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
func frame()->Rect2:
 var ratio:float=media.ratio();var r=Rect2(Vector2.ZERO,size)
 if size.x/maxf(1,size.y)>ratio:r.size.x=size.y*ratio;r.position.x=(size.x-r.size.x)*.5
 else:r.size.y=size.x/ratio;r.position.y=(size.y-r.size.y)*.5
 return r
func _draw()->void:
 if media==null or not media.enabled() or media.capturing:return
 var r=frame();var c=Color(1,.91,.7,.45)
 if media.aspect!=0:draw_rect(r,c,false,1)
 if media.guide==1:
  for f in [1.0/3,2.0/3]:
   draw_line(r.position+Vector2(r.size.x*f,0),r.position+Vector2(r.size.x*f,r.size.y),c,1)
   draw_line(r.position+Vector2(0,r.size.y*f),r.position+Vector2(r.size.x,r.size.y*f),c,1)
 elif media.guide==2:
  draw_line(r.position+Vector2(r.size.x*.5,0),r.position+Vector2(r.size.x*.5,r.size.y),c,1)
  draw_line(r.position+Vector2(0,r.size.y*.5),r.position+Vector2(r.size.x,r.size.y*.5),c,1)
 elif media.guide==3:draw_rect(Rect2(r.position+r.size*.05,r.size*.9),c,false,1)

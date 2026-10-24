extends Control
var history:Array=[]
func _draw()->void:
 var r=Rect2(Vector2(8,8),size-Vector2(16,16));draw_style_box(preload("res://scripts/studio_ui.gd").box("#193d48","#45656b",8,8),r)
 var font=preload("res://assets/fonts/CrossroadsUI.ttf");draw_string(font,Vector2(24,34),"ACTUAL OPERATING PROFIT • by workday",HORIZONTAL_ALIGNMENT_LEFT,-1,15,Color("#dce9df"))
 if history.is_empty():draw_string(font,Vector2(24,76),"Complete openings to build your own trend.",HORIZONTAL_ALIGNMENT_LEFT,-1,16,Color("#c6d8d9"));return
 var records=history.slice(maxi(0,history.size()-12));var max_value=1.0
 for h in records:max_value=maxf(max_value,absf(float(h.profit)))
 draw_string(font,Vector2(24,55),"Green: profit • coral: loss • range ±%.0f" % max_value,HORIZONTAL_ALIGNMENT_LEFT,-1,12,Color("#afcad0"))
 var zero=size.y*.58;var width=(size.x-64)/records.size();var span=size.y*.25
 draw_line(Vector2(24,zero),Vector2(size.x-24,zero),Color("#709399"),1)
 for i in records.size():
  var h=records[i];var value=float(h.profit)/max_value*span;var x=32+i*width
  draw_rect(Rect2(Vector2(x,minf(zero,zero-value)),Vector2(maxf(3,width-8),maxf(2,absf(value)))),Color("#8fcea6") if value>=0 else Color("#e9a18c"))
  draw_string(font,Vector2(x,size.y-16),str(int(h.day)),HORIZONTAL_ALIGNMENT_LEFT,-1,12,Color("#d1e3e4"))

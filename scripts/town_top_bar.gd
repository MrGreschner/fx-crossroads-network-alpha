extends RefCounted
## Shared positions and scale keep all top controls on one row.
static func education()->bool:
 var state=preload("res://scripts/education_access.gd").state()
 return state.student or state.teacher
static func place(button:Control,slot:String,view:Vector2)->void:
 var widths={"adventures":122.0,"menu":78.0,"education":134.0,"profile":235.0,"sound":108.0}
 var slots=["adventures","menu"]
 if education():slots.append("education")
 slots.append("profile");slots.append("sound")
 var total=0.0
 for key in slots:total+=widths[key]+8
 var fit=minf(1.0,maxf(.55,(view.x-250)/total))
 var left=view.x-total*fit
 for key in slots:
  if key==slot:
   button.scale=Vector2.ONE*fit;button.position=Vector2(left,8);button.custom_minimum_size=Vector2(widths[key],44);button.size=Vector2(widths[key],44)
   return
  left+=(widths[key]+8)*fit

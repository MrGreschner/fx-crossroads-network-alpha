extends RefCounted
## A walk-out opening at the existing Training Yard return point. No new collision.
static func draw(c:CanvasItem,p:Vector2)->void:
 # A short trail joins the yard to the west, framed by two low fence ends.
 c.draw_colored_polygon(PackedVector2Array([p+Vector2(-170,-35),p+Vector2(-15,-46),p+Vector2(72,-34),p+Vector2(72,36),p+Vector2(-25,44),p+Vector2(-170,33)]),Color("#a89a73"))
 for n in 5:
  var q=p+Vector2(-147+n*37,(-3 if n%2 else 5))
  c.draw_colored_polygon(PackedVector2Array([q+Vector2(-12,-10),q+Vector2(9,-12),q+Vector2(14,7),q+Vector2(-9,11)]),Color("#c9b996"))
  c.draw_line(q+Vector2(-9,10),q+Vector2(11,7),Color("#8f8b70"),2,true)
 for side in [-1,1]:
  var end=p+Vector2(0,side*65);var outer=p+Vector2(0,side*119)
  for height in [9,21]:c.draw_line(end-Vector2(0,height),outer-Vector2(0,height),Color("#9b8260"),5,true)
  for at in [end,outer]:
   c.draw_rect(Rect2(at+Vector2(-4,-31),Vector2(8,38)),Color("#7e7158"));c.draw_line(at+Vector2(-3,-29),at+Vector2(3,-29),Color("#d0b996"),3,true)
 var sign=p+Vector2(45,-68)
 c.draw_rect(Rect2(sign+Vector2(-3,2),Vector2(6,31)),Color("#84745a"))
 c.draw_colored_polygon(PackedVector2Array([sign+Vector2(-48,-18),sign+Vector2(-37,-30),sign+Vector2(42,-30),sign+Vector2(42,-7),sign+Vector2(-37,-7)]),Color("#74674f"))
 c.draw_line(sign+Vector2(-35,-28),sign+Vector2(39,-28),Color("#c9b48c"),2,true)
 c.draw_string(ThemeDB.fallback_font,sign+Vector2(-31,-13),"TO TOWN",HORIZONTAL_ALIGNMENT_LEFT,-1,12,Color("#f2e3bc"))
 c.draw_string_outline(ThemeDB.fallback_font,p+Vector2(-52,88),"TRAINING YARD EXIT",HORIZONTAL_ALIGNMENT_LEFT,-1,13,3,Color("#344b40"))
 c.draw_string(ThemeDB.fallback_font,p+Vector2(-52,88),"TRAINING YARD EXIT",HORIZONTAL_ALIGNMENT_LEFT,-1,13,Color("#f2e3bc"))

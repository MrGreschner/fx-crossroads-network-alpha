extends RefCounted
## Shared regional pictograms. Their sizes express settlement rank, never world footprints.
const SPECS={
 "town":{"size":Vector2(36,28),"offset":Vector2(-12,-11),"route":0},
 "harbour":{"size":Vector2(26,22),"offset":Vector2(0,-10),"route":2},
 "wilds":{"size":Vector2(26,22),"offset":Vector2(0,-10),"route":3},
 "bay":{"size":Vector2(18,16),"offset":Vector2(11,-11),"route":1}
}
const WALL=Color("#c8b18a")
const EDGE=Color("#796f59")
const ROOF=Color("#637f87")
static func box(key:String,anchor:Vector2)->Rect2:
 var s:Dictionary=SPECS[key]
 return Rect2((anchor+Vector2(s.offset)-Vector2(s.size.x*.5,s.size.y)).round(),s.size)
static func rect(c:CanvasItem,p:Vector2,s:Vector2,color:Color)->void:c.draw_rect(Rect2(p,s),color)
static func house(c:CanvasItem,p:Vector2,w:int,h:int,roof:Color)->void:
 rect(c,p+Vector2(1,4),Vector2(w-2,h-4),WALL)
 rect(c,p+Vector2(w-3,5),Vector2(2,h-5),Color("#ad9977"))
 c.draw_line(p+Vector2(1,h-1),p+Vector2(w-2,h-1),EDGE,1)
 var shape=PackedVector2Array([p+Vector2(0,5),p+Vector2(0,3),p+Vector2(2,3),p+Vector2(2,1),p+Vector2(4,1),p+Vector2(4,0),p+Vector2(w-5,0),p+Vector2(w-5,1),p+Vector2(w-3,1),p+Vector2(w-3,3),p+Vector2(w-1,3),p+Vector2(w-1,5)])
 c.draw_colored_polygon(shape,roof)
 c.draw_line(p+Vector2(1,5),p+Vector2(w-2,5),roof.darkened(.15),1)
 rect(c,p+Vector2(3,7),Vector2(2,3),Color("#e5d3a1"))
 if w>11:rect(c,p+Vector2(w-5,7),Vector2(2,3),Color("#e5d3a1"))
 rect(c,p+Vector2(floori(w*.5)-1,h-5),Vector2(3,5),Color("#796951"))
static func draw(c:CanvasItem,key:String,anchor:Vector2)->void:
 var r=box(key,anchor);var p=r.position
 # One common palette, stepped roofs and coloured contours for all settlement marks.
 if key=="town":
  house(c,p+Vector2(1,11),10,16,ROOF)
  house(c,p+Vector2(25,11),10,16,ROOF)
  house(c,p+Vector2(10,5),16,22,ROOF)
  rect(c,p+Vector2(5,23),Vector2(26,4),Color("#b8a37f"))
  rect(c,p+Vector2(15,21),Vector2(6,6),Color("#796951"))
  rect(c,p+Vector2(18,0),Vector2(1,5),EDGE);rect(c,p+Vector2(19,0),Vector2(5,2),Color("#a9b48b"))
 elif key in ["harbour","wilds"]:
  house(c,p+Vector2(1,5),13,16,ROOF)
  house(c,p+Vector2(13,8),12,13,ROOF)
  if key=="harbour":
   rect(c,p+Vector2(21,0),Vector2(1,7),EDGE);rect(c,p+Vector2(22,1),Vector2(3,2),Color("#9ab6b2"))
   rect(c,p+Vector2(10,19),Vector2(15,2),Color("#aa8f66"));rect(c,p+Vector2(11,21),Vector2(1,1),EDGE);rect(c,p+Vector2(23,21),Vector2(1,1),EDGE)
  else:
   rect(c,p+Vector2(22,5),Vector2(1,6),EDGE);rect(c,p+Vector2(20,2),Vector2(5,5),Color("#758d6d"));rect(c,p+Vector2(21,0),Vector2(3,3),Color("#98a480"))
   rect(c,p+Vector2(1,21),Vector2(23,1),Color("#93a17b"))
 else:
  house(c,p,18,14,ROOF)
  rect(c,p+Vector2(8,13),Vector2(9,2),Color("#aa8f66"));rect(c,p+Vector2(10,15),Vector2(1,1),EDGE);rect(c,p+Vector2(16,15),Vector2(1,1),EDGE)

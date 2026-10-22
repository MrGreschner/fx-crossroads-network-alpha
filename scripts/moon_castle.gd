extends RefCounted
## Shared authored geometry: identical floors in solo, co-op and rendering.
const FLOORS=[Rect2(100,2100,1600,1000),Rect2(1450,1700,2100,1800),Rect2(3200,2250,1800,600),Rect2(4700,1600,2600,2000),Rect2(2050,700,650,1200),Rect2(1600,400,1800,650),Rect2(2200,3300,650,1300),Rect2(1700,4200,1800,800),Rect2(3900,2800,800,1400),Rect2(3300,3700,1700,900),Rect2(5300,700,750,1200),Rect2(5000,350,1900,700)]
const FOUNTAINS=[Vector2(2500,2450),Vector2(6000,2500),Vector2(4200,4180)]
static func open(p:Vector2)->bool:
 var on_floor=false
 for r in FLOORS:
  if r.grow(-18).has_point(p):on_floor=true;break
 if not on_floor:return false
 for f in FOUNTAINS:
  if p.distance_to(f)<150:return false
 return true
static func draw(c:Node2D,cam:Vector2)->void:
 var view=Rect2(cam,c.get_viewport_rect().size+Vector2(200,200)).grow(180)
 c.draw_rect(Rect2(-cam,Vector2(7600,5600)),Color('#172b3a'))
 # Lake is an actual unwalkable body of water beside the southern moon garden.
 c.draw_rect(Rect2(Vector2(4710,3200)-cam,Vector2(2890,2400)),Color('#254a63'))
 for x in range(int(cam.x/100)*100,int(cam.x+view.size.x),100):
  for y in range(int(cam.y/100)*100,int(cam.y+view.size.y),100):
   var p=Vector2(x+50,y+50)
   if p.x>4750 and p.y>3200:c.draw_arc(p-cam,27,0,PI,10,Color('#4f7188'),2)
 for r in FLOORS:
  if not view.intersects(r):continue
  c.draw_rect(Rect2(r.position-cam-Vector2(14,14),r.size+Vector2(28,28)),Color('#a197bd'))
  c.draw_rect(Rect2(r.position-cam,r.size),Color('#4a415f'))
  var clip=r.intersection(view)
  for x in range(int(clip.position.x/96)*96,int(clip.end.x),96):
   for y in range(int(clip.position.y/96)*96,int(clip.end.y),96):
    var p=Vector2(x,y)
    if r.has_point(p):
     var tile=r.intersection(Rect2(p,Vector2(94,94)));c.draw_rect(Rect2(tile.position-cam,tile.size),Color('#625674') if (x/96+y/96)%2==0 else Color('#554965'))
  c.draw_rect(Rect2(r.position-cam+Vector2(24,24),r.size-Vector2(48,48)),Color('#bda978'),false,3)
 # Rich ballroom rugs, ornate arches and paired pillars keep doors legible.
 for center in [Vector2(2500,2450),Vector2(6000,2500)]:
  c.draw_rect(Rect2(center-Vector2(680,540)-cam,Vector2(1360,1080)),Color('#513b62'))
  c.draw_rect(Rect2(center-Vector2(680,540)-cam,Vector2(1360,1080)),Color('#c4ac7d'),false,6)
  for off in [Vector2(-820,-600),Vector2(820,-600),Vector2(-820,600),Vector2(820,600)]:
   var p=center+off-cam;c.draw_circle(p,38,Color('#333044'));c.draw_circle(p-Vector2(0,10),27,Color('#b4aac4'));c.draw_circle(p-Vector2(0,20),16,Color('#e0d1ac'))
 # Ballroom mosaics, candle standards and chandeliers give the large rooms scale.
 for center in [Vector2(2500,2450),Vector2(6000,2500)]:
  for x in [-480,-240,0,240,480]:
   for y in [-360,-120,120,360]:
    var p=center+Vector2(x,y)
    if not view.has_point(p) or p.distance_to(center)<190:continue
    var q=p-cam;c.draw_colored_polygon(PackedVector2Array([q+Vector2(0,-34),q+Vector2(28,0),q+Vector2(0,34),q+Vector2(-28,0)]),Color('#6a537b'))
    c.draw_arc(q,12,0,TAU,16,Color('#ac94b0'),1)
  for x in [-720,720]:
   for y in [-380,0,380]:
    var q=center+Vector2(x,y)-cam
    if not view.has_point(q+cam):continue
    c.draw_circle(q+Vector2(0,6),16,Color('#342f40'));c.draw_line(q,q-Vector2(0,58),Color('#c0a478'),6)
    for offset in [-17,0,17]:
     c.draw_line(q-Vector2(0,43),q+Vector2(offset,-57),Color('#c0a478'),3);c.draw_circle(q+Vector2(offset,-62),5,Color('#f2d8a1'))
  for y in [-450,450]:
   var q=center+Vector2(0,y)-cam
   c.draw_line(q-Vector2(0,75),q-Vector2(0,25),Color('#393044'),3);c.draw_arc(q-Vector2(0,20),78,0,PI,24,Color('#d1b582'),5)
   for j in 7:
    var v=Vector2.from_angle(j*PI/6)*72;q+=Vector2.ZERO;c.draw_circle(q+v-Vector2(0,20),5,Color('#f1d7a3'))
 # Low garden walls, moon tiles and balustrades emphasise the real shoreline.
 for j in 12:
  var q=Vector2(4990,3710+j*90)-cam
  if not view.has_point(q+cam):continue
  if j in [3,4,5]:continue
  c.draw_line(q-Vector2(0,18),q+Vector2(0,18),Color('#c0b5c7'),7);c.draw_circle(q-Vector2(0,20),7,Color('#e3d3bc'))
 for f in FOUNTAINS:
  if not view.has_point(f):continue
  var p=f-cam
  c.draw_circle(p,153,Color('#b8acc5'));c.draw_circle(p,135,Color('#224d6b'));c.draw_arc(p,122,0,TAU,60,Color('#87c6d4'),5)
  c.draw_circle(p,61,Color('#c9b9d2'));c.draw_circle(p,49,Color('#386784'));c.draw_circle(p-Vector2(0,36),23,Color('#e8ddc8'))
  for j in 8:
   var a=j*TAU/8;c.draw_line(p+Vector2.from_angle(a)*45-Vector2(0,35),p+Vector2.from_angle(a)*108,Color('#9dd6e1'),3)
 for rect in [Rect2(1800,460,1400,480),Rect2(1850,4350,1400,480),Rect2(5160,430,1500,450)]:
  c.draw_rect(Rect2(rect.position-cam,rect.size),Color('#374f50'))
  for j in 5:
   var p=rect.position+Vector2(130+j*270,rect.size.y*.5)-cam;c.draw_circle(p,65,Color('#6b6384'));c.draw_circle(p,38,Color('#b99cbf'))
 # The castle facade above the second ballroom, with deliberately odd moon spires.
 for j in 5:
  var p=Vector2(4820+j*490,1450)-cam
  c.draw_rect(Rect2(p-Vector2(48,160),Vector2(96,240)),Color('#8d83a7'))
  c.draw_colored_polygon(PackedVector2Array([p+Vector2(-78,-160),p+Vector2(12,-310-j%2*65),p+Vector2(78,-160)]),Color('#504064'))
  c.draw_circle(p-Vector2(0,193),19,Color('#f2e5b5'));c.draw_circle(p-Vector2(-9,198),17,Color('#504064'))
 for p in [Vector2(850,2200),Vector2(3400,2310),Vector2(4850,1750)]:
  var q=p-cam
  c.draw_arc(q,120,PI,TAU,30,Color('#c7b2ce'),19);c.draw_line(q-Vector2(120,0),q+Vector2(-120,130),Color('#a79abb'),20);c.draw_line(q+Vector2(120,0),q+Vector2(120,130),Color('#a79abb'),20)
 for item in [[Vector2(450,2450),'MOONVEIL • THE MASQUERADE'],[Vector2(1890,1920),'THE FIRST DANCE'],[Vector2(4900,1800),'MIRROR MARQUIS • GRAND BALLROOM'],[Vector2(3460,3940),'MOONWATER GARDEN'],[Vector2(1750,680),'WHISPER COURT']]:
  if view.has_point(item[0]):c.draw_string(ThemeDB.fallback_font,item[0]-cam,item[1],HORIZONTAL_ALIGNMENT_LEFT,-1,21,Color('#eadbb8'))

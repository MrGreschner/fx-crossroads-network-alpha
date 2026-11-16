extends RefCounted
## Town ice is separate from the frozen section of Oldwater Lake.
const SEASON=preload("res://scripts/winter_art353.gd")
const ART=preload("res://scripts/season_art_atlas.gd")
const UI=preload("res://scripts/studio_ui.gd")
const ROOT="res://assets/winter358/"
const POND=Vector2(200,365)
const POND_RADII=Vector2(200,112)
const COCOA=Vector2(433,526)
const STALL=Rect2(389,451,88,71)
const FOOD="hot_chocolate"
const HOLES={
 "town_pond":{"at":Vector2(234,406),"bank":Vector2(234,432),"name":"Town Pond Ice Hole"},
 "town_river":{"at":Vector2(2421,1340),"bank":Vector2(2475,1340),"name":"East Bridge Ice Hole"},
 "town_dawn":{"at":Vector2(2421,480),"bank":Vector2(2475,480),"name":"Northern Dawn Ice Hole · 4–6 am"}
}
const PROPS={
 "drift":Rect2(0,12,64,30),
 "snowman":Rect2(64,7,48,63),
 "fort":Rect2(112,4,96,48),
 "mug":Rect2(208,5,44,34)
}
const DECOR=[
 ["fort",Vector2(113,545),Vector2(103,52)],
 ["snowman",Vector2(307,528),Vector2(47,61)],
 ["snowman",Vector2(1190,868),Vector2(39,51)],
 ["drift",Vector2(116,500),Vector2(56,25)],
 ["drift",Vector2(366,498),Vector2(48,22)],
 ["drift",Vector2(480,567),Vector2(56,24)],
 ["drift",Vector2(713,891),Vector2(70,30)],
 ["drift",Vector2(1040,859),Vector2(62,27)],
 ["drift",Vector2(1440,1880),Vector2(73,34)],
 ["drift",Vector2(-1090,1059),Vector2(75,34)],
 ["drift",Vector2(2475,1389),Vector2(50,23)]
]
static var mug:AtlasTexture

static func pond_contains(p:Vector2)->bool:
 return ((p-POND)/POND_RADII).length_squared()<1.0

static func rescue_thawed_pond(g:Node2D)->void:
 if not pond_contains(g.position_in_world) or SEASON.active(g):return
 var direction:Vector2=(g.position_in_world-POND).normalized()
 if direction.is_zero_approx():direction=Vector2.DOWN
 for radius in [1.12,1.32,1.6]:
  for i in [0,1,-1,2,-2,3,-3,4]:
   var point=POND+direction.rotated(i*PI/4.0)*POND_RADII*radius
   if not g.can_stand_at(point):continue
   g.position_in_world=point
   g.update_camera()
   return

static func ice_spot(spot:Dictionary)->Dictionary:
 var hole:Dictionary=HOLES.get(str(spot.id),{})
 if hole.is_empty():return spot
 var result=spot.duplicate()
 result.name=hole.name
 result.bank=[hole.bank.x,hole.bank.y]
 result.water=[hole.at.x,hole.at.y]
 result.ice=true
 return result

static func texture(id:String)->Texture2D:
 return ART.texture(ROOT,id)

static func draw_hole(c:CanvasItem,p:Vector2)->void:
 for rim in [[17,Color("#dcecee")],[13,Color("#547e91")],[10,Color("#274b5e")]]:
  var oval=PackedVector2Array()
  for n in 16:oval.append((p+Vector2.from_angle(n*TAU/16)*Vector2(rim[0],rim[0]*.62)).round())
  c.draw_colored_polygon(oval,rim[1])
 c.draw_line(p+Vector2(-5,-2),p+Vector2(4,-2),Color("#759da5"),1.0)

static func river_strip(c:Node2D,r:Rect2,view:Rect2)->void:
 var from=maxf(r.position.y,floorf(view.position.y/20)*20)
 var to=minf(r.end.y,ceilf(view.end.y/20)*20)
 if to<=from:return
 for side in [-1,1]:
  var outer=r.position.x if side==-1 else r.end.x
  var bank=PackedVector2Array([Vector2(outer,from)])
  var seam=PackedVector2Array()
  var uv=PackedVector2Array([bank[0]/128])
  var middle=r.get_center().x
  var rows=range(int(from),int(to),20)
  rows.append(int(to))
  for y in rows:
   var crooked=sin(y*.019)*11+sin(y*.051)*4
   var gap=clampf(7+sin(y*.008)*10+sin(y*.032)*5,0,23)
   var p=Vector2(middle+crooked+side*gap,y).round()
   bank.append(p)
   seam.append(p)
   uv.append(p/128)
  bank.append(Vector2(outer,to))
  uv.append(bank[-1]/128)
  c.draw_polygon(bank,PackedColorArray([Color("#b6cdd5")]),uv,texture("ice"))
  c.draw_polyline(seam,Color("#405e70"),2.0)

static func draw_pond(c:Node2D,outline:PackedVector2Array,uv:PackedVector2Array)->void:
 c.draw_polygon(outline,PackedColorArray([Color.WHITE]),uv,texture("ice"))
 for n in 5:
  var at=POND+Vector2(-137+n*66,8*cos(n*5)-24*sin(n*.91))
  c.draw_polyline(PackedVector2Array([at,at+Vector2(14,2),at+Vector2(23,-5),at+Vector2(40,5)]),Color("#7ca3b5"),1)
  c.draw_line(at+Vector2(23,-5),at+Vector2(25,-15),Color("#b2d0d9"),1)

static func draw_town(g:Node2D,camera:Vector2)->void:
 if not SEASON.active(g):return
 var view=Rect2(camera,g.VIEW).grow(60)
 for decor in DECOR:
  var at:Vector2=decor[1]
  var size:Vector2=decor[2]
  var rect=Rect2(at-Vector2(size.x/2,size.y),size)
  if view.intersects(rect):g.draw_texture_rect_region(texture("props"),Rect2(rect.position-camera,size),PROPS[decor[0]])
 if view.intersects(STALL):draw_stand(g,COCOA-camera)
 for id in ["town_river","town_dawn"]:
  var at:Vector2=HOLES[id].bank+Vector2(22,-32)
  if not view.has_point(at):continue
  var p=at-camera
  g.draw_line(p,p+Vector2(0,32),Color("#6c5141"),3)
  g.draw_rect(Rect2(p-Vector2(34,10),Vector2(68,16)),Color("#5c5149"))
  g.draw_string(UI.FONT,p+Vector2(-32,2),"THIN ICE",HORIZONTAL_ALIGNMENT_CENTER,64,11,Color("#ffe6b0"))

static func draw_stand(g:Node2D,p:Vector2)->void:
 g.draw_rect(Rect2(p-Vector2(43,57),Vector2(86,53)),Color("#5b453d"))
 g.draw_rect(Rect2(p-Vector2(40,50),Vector2(80,39)),Color("#866451"))
 for n in 7:
  g.draw_line(p+Vector2(-32+n*11,-46),p+Vector2(-32+n*11,-14),Color("#735744"),1)
 g.draw_rect(Rect2(p-Vector2(47,34),Vector2(94,8)),Color("#b28a66"))
 g.draw_colored_polygon(PackedVector2Array([p+Vector2(-49,-58),p+Vector2(-35,-75),p+Vector2(35,-75),p+Vector2(49,-58)]),Color("#d9e9e8"))
 g.draw_rect(Rect2(p-Vector2(48,59),Vector2(96,14)),Color("#365c60"))
 g.draw_string(UI.FONT,p+Vector2(-46,-48),"HOT CHOCOLATE",HORIZONTAL_ALIGNMENT_CENTER,92,11,Color("#f7dfb8"))
 for side in [-1,1]:
  g.draw_texture_rect_region(texture("props"),Rect2(p+Vector2(side*19-10,-44),Vector2(24,18)),PROPS.mug)
  var rise=fposmod(g.town_life.clock*.55+side*.21,1.0)
  g.draw_rect(Rect2(p+Vector2(side*19+sin(rise*TAU)*3,-46-rise*14),Vector2(3,4)),Color(.91,.95,.92,(1-rise)*.53))

static func interact(g:Node2D)->bool:
 if not SEASON.active(g) or g.position_in_world.distance_to(COCOA)>70:return false
 g.hint="E • Hot Chocolate Stand"
 if Input.is_action_just_pressed("interact"):shop(g)
 return true

static func shop(g:Node2D)->void:
 var ui=g.presentation
 ui.window("Hot Chocolate Stand","town_conversation")
 var heading=HBoxContainer.new()
 ui.content.add_child(heading)
 if mug==null:
  mug=AtlasTexture.new()
  mug.atlas=texture("props")
  mug.region=PROPS.mug
 var icon=TextureRect.new()
 icon.texture=mug
 icon.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
 icon.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
 icon.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
 icon.custom_minimum_size=Vector2(68,52)
 heading.add_child(icon)
 ui.label(heading,"Hot Chocolate",25)
 var food:Dictionary=g.provisions.defs[FOOD]
 ui.label(ui.content,str(food.description),18)
 ui.label(ui.content,"Food slot • "+g.provisions.name_of(g.provisions.packed),16)
 var cost:int=g.provisions.price(FOOD)
 var buy:Button=ui.button(ui.content,"Pack hot chocolate • %d CC" % cost,func():
  if g.provisions.buy(FOOD):shop(g))
 buy.disabled=not g.provisions.packed.is_empty() or g.gold<cost
 UI.accent(buy)
 if not g.provisions.packed.is_empty():
  ui.button(ui.content,"Empty food slot",func():
   g.provisions.refund()
   shop(g))

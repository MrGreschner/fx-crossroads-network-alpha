extends RefCounted
## Small map illustrations reuse the town's matte pixel sprites; geometry is deterministic.
const DATA=preload("res://scripts/atlas_data377.gd")
const NATURE=preload("res://scripts/town_nature243.gd")
const MARINA=preload("res://scripts/marina_art250.gd")
static var materials:Dictionary={}
static func material(id:String)->Texture2D:
 if not materials.has(id):
  var im=Image.new();im.load_png_from_buffer(FileAccess.get_file_as_bytes("res://assets/training303/"+id+".png"))
  var t=CanvasTexture.new();t.diffuse_texture=ImageTexture.create_from_image(im);t.texture_repeat=CanvasItem.TEXTURE_REPEAT_ENABLED;materials[id]=t
 return materials[id]
static func land(c:Control)->void:
 var winter=c.season=="Winter"
 c.draw_rect(c.MAP,Color("#d9ded0") if winter else Color("#bec49a"))
 c.draw_texture_rect(material("grass"),c.MAP,true,Color(1,1,1,.075 if winter else .16))
 for i in 48:
  var p=Vector2(20+posmod(i*73,604),41+posmod(i*59,271));c.draw_line(p,p+Vector2(5,0),Color(.36,.43,.3,.08),1)
static func water(c:Control,points:PackedVector2Array,ice:bool=false)->void:
 c.draw_colored_polygon(points,Color("#9cbfc6") if ice else Color("#6b9fa8"))
 var edge=points.duplicate();edge.append(points[0]);c.draw_polyline(edge,Color("#c5d1b4"),3,true);c.draw_polyline(edge,Color("#567e80"),1,true)
static func tree(c:Control,p:Vector2,s:float=1,deciduous:bool=false)->void:
 var art=NATURE.texture("ancient" if deciduous else "pine")
 var h=23*s;var w=(24 if deciduous else 15)*s
 c.draw_ellipse_shadow(p) if c.has_method("draw_ellipse_shadow") else c.draw_line(p+Vector2(-3,1),p+Vector2(4,1),Color(.2,.3,.23,.2),3)
 c.draw_texture_rect(art,Rect2(p-Vector2(w*.5,h),Vector2(w,h)),false,Color("#dde8df") if c.season=="Winter" else Color.WHITE)
 if c.season=="Winter":c.draw_line(p+Vector2(-3,-h*.6),p+Vector2(3,-h*.6),Color("#eef3e6"),2)
static func label(c:Control,p:Vector2,text:String,size:int=12,tint:Color=Color("#2f4847"))->void:
 var extent=ThemeDB.fallback_font.get_string_size(text,HORIZONTAL_ALIGNMENT_LEFT,-1,size)
 var box=StyleBoxFlat.new();box.bg_color=Color(.93,.9,.76,.94);box.border_color=Color(.55,.55,.4,.55);box.set_border_width_all(1);box.set_corner_radius_all(3)
 c.draw_style_box(box,Rect2(p+Vector2(-4,-size-2),extent+Vector2(8,6)))
 c.caption(p,text,size,tint)
static func trail(c:Control,points:PackedVector2Array,width:float=4)->void:
 c.draw_polyline(points,Color("#8b7958"),width+2,true);c.draw_polyline(points,Color("#e5cf9d"),width,true)
static func dashed(c:Control,points:PackedVector2Array,tint:Color,step:float=7)->void:
 var phase=0.0
 for i in range(1,points.size()):
  var a=points[i-1];var b=points[i];var length=a.distance_to(b);var t=0.0
  while t<length:
   var n=minf(length-t,step-phase)
   if fposmod(phase,step*2)<step*.6:c.draw_line(a.move_toward(b,t),a.move_toward(b,t+n*.65),tint,2,true)
   t+=n;phase=fposmod(phase+n,step)
static func dock(c:Control,r:Rect2)->void:
 c.draw_rect(Rect2(r.position+Vector2(1,2),r.size),Color(.18,.29,.3,.25));c.draw_rect(r,Color("#9b7d55"));c.draw_rect(r,Color("#705e47"),false,1)
 if r.size.x>r.size.y:
  for x in range(int(r.position.x)+3,int(r.end.x),5):c.draw_line(Vector2(x,r.position.y+1),Vector2(x,r.end.y-1),Color("#ceb285"),1)
 else:
  for y in range(int(r.position.y)+3,int(r.end.y),5):c.draw_line(Vector2(r.position.x+1,y),Vector2(r.end.x-1,y),Color("#ceb285"),1)
static func boat(c:Control,p:Vector2,scale:float=1)->void:
 c.polygon([p+Vector2(-11,-4)*scale,p+Vector2(10,-4)*scale,p+Vector2(14,0)*scale,p+Vector2(8,5)*scale,p+Vector2(-9,5)*scale],Color("#6d6052"))
 c.draw_line(p+Vector2(-7,-2)*scale,p+Vector2(8,-2)*scale,Color("#c5a577"),2*scale)
 c.draw_line(p+Vector2(0,-1)*scale,p+Vector2(0,-17)*scale,Color("#6e624d"),1.5*scale)
 c.polygon([p+Vector2(2,-16)*scale,p+Vector2(11,-5)*scale,p+Vector2(2,-5)*scale],Color("#e6d5ac"))
static func local(c:Control)->void:
 land(c)
 var bay=c.area=="bay"
 var b=DATA.BAY;var port=DATA.PORT;var coast=DATA.COAST
 if bay:
  b.prepare_geometry();var shape=PackedVector2Array()
  for p in b.water_shape:shape.append(c.point(p))
  water(c,shape)
  if c.season=="Winter":
   shape=PackedVector2Array()
   for p in b.ice_shape:shape.append(c.point(p))
   water(c,shape,true)
   for spot in b.SNOW:
    var at=c.point(Vector2(spot[0],spot[1]));var size=Vector2(spot[2],spot[3])/c.field().size*c.MAP.size
    c.draw_style_box(round_box("#e8ede1"),Rect2(at-size*.5,size))
  for i in 24:
   var p=Vector2(1955+posmod(i*79,250),-3900+posmod(i*173,2850));tree(c,c.point(p),.7)
   p=Vector2(b.bank_x(b.BANKS_EAST,p.y)+140+posmod(i*139,380),p.y)
   if b.BOUNDS.has_point(p):tree(c,c.point(p),.72+float(i%3)*.08,i%4==0)
 else:
  coast.prepare();var shape=PackedVector2Array()
  for p in coast.layout.coast:shape.append(c.point(Vector2(p[0],p[1])))
  shape.append(c.point(Vector2(2820,3830)));shape.append(c.point(Vector2(2900,4310)));shape.append(c.point(Vector2(1080,4310)));shape.append(c.point(Vector2(1080,3734)))
  water(c,shape)
  var river=PackedVector2Array()
  for p in coast.layout.west_bank:river.append(c.point(Vector2(p[0],p[1])))
  for n in range(coast.layout.east_bank.size()-1,-1,-1):
   var p=coast.layout.east_bank[n];river.append(c.point(Vector2(p[0],p[1])))
  water(c,river)
  for i in range(1,coast.layout.ridge_foot.size()):
   var a=coast.layout.ridge_foot[i-1];var p=c.point(Vector2(a[0],a[1]));var q=c.point(Vector2(coast.layout.ridge_foot[i][0],coast.layout.ridge_foot[i][1]))
   c.draw_line(p-Vector2(4,0),q-Vector2(4,0),Color("#9a9b88"),13,true);c.draw_line(p,q,Color("#6f8279"),3,true)
   c.draw_line(p-Vector2(3,1),p+Vector2(-10,6),Color("#66766b"),1)
  for i in 22:
   var p=c.point(Vector2(1090+posmod(i*37,160),2910+posmod(i*151,850)));tree(c,p,.72,i%3==0)
 for route in DATA.roads(c.area):
  var line=PackedVector2Array()
  for p in route:line.append(c.point(p))
  if line.size()>1:trail(c,line,2)
 var decks=[b.DOCK,b.FERRY_DOCK] if bay else coast.layout.docks
 for r in decks:dock(c,Rect2(c.point(r.position),c.point(r.end)-c.point(r.position)))
 if bay:
  var base=c.point(b.CABIN.position+b.CABIN.size*Vector2(.5,1));cabin(c,Rect2(base-Vector2(16,26),Vector2(32,26)))
  if c.season!="Winter":boat(c,c.point(b.BERTH+Vector2(-15,-60)),.8);boat(c,c.point(b.FERRY+Vector2(-80,25)),.65)
  c.draw_circle(c.point(b.CAMP),3,Color("#ad7851"));c.draw_circle(c.point(b.CAMP),1.4,Color("#e5bd78"))
 else:
  for building in port.BUILDINGS:
   var rect:Rect2=building[1];c.draw_texture_rect(NATURE.seasonal_texture(building[0],c.season),Rect2(c.point(rect.position),c.point(rect.end)-c.point(rect.position)),false)
  var office=Rect2(c.point(port.OFFICE_FRAME.position),c.point(port.OFFICE_FRAME.end)-c.point(port.OFFICE_FRAME.position));c.draw_texture_rect(preload("res://scripts/winter_buildings383.gd").texture("marina","bait_stall",c.season,preload("res://scripts/marina_art250.gd").texture("bait_stall")),office,false)
  boat(c,c.point(Vector2(1740,4020)),.85);boat(c,c.point(Vector2(2150,4030)),.85)
  label(c,Vector2(25,62),"CLIFFSIDE PORT",10)
 c.compass(Vector2(608,67))
 # Quiet water marks stay away from entrances and piers.
 for i in 14:
  var p=Vector2(25+posmod(i*61,595),65+posmod(i*47,244));var world=c.world(p)
  var wet=not b.bare_ground(world,false) if bay else world.y>coast.coast_at(clampf(world.x,1170,2128))
  if wet and not (bay and c.season=="Winter"):c.draw_arc(p,5,.3,2.5,8,Color(.78,.9,.85,.45),1,true)
static func cabin(c:Control,rect:Rect2)->void:
 c.draw_texture_rect(NATURE.seasonal_texture("cliff_cottage",c.season),rect,false)
 var wall=Rect2(rect.position+rect.size*Vector2(.09,.48),rect.size*Vector2(.82,.48))
 c.draw_rect(wall,Color("#76543d"))
 for n in 4:
  var y=wall.position.y+n*wall.size.y/4;c.draw_line(Vector2(wall.position.x,y),Vector2(wall.end.x,y),Color("#b2875c"),1)
 c.draw_rect(Rect2(wall.position+wall.size*Vector2(.37,.2),wall.size*Vector2(.22,.8)),Color("#4c4137"))
static func round_box(tint:String)->StyleBoxFlat:
 var b=StyleBoxFlat.new();b.bg_color=Color(tint);b.set_corner_radius_all(7);return b
static func hill(c:Control,p:Vector2,s:float=1)->void:
 # Rounded, stepped contours and short strata marks keep the ridge in the map's matte style.
 var outline=[Vector2(-20,15),Vector2(-17,5),Vector2(-13,5),Vector2(-13,-3),Vector2(-8,-3),Vector2(-8,-11),Vector2(-2,-16),Vector2(5,-14),Vector2(10,-5),Vector2(14,-5),Vector2(18,5),Vector2(22,15)]
 var points=[]
 for q in outline:points.append(p+q*s)
 c.polygon(points,Color("#909980"));c.polygon([p+Vector2(-2,-16)*s,p+Vector2(5,-14)*s,p+Vector2(10,-5)*s,p+Vector2(14,-5)*s,p+Vector2(18,5)*s,p+Vector2(22,15)*s,p+Vector2(3,9)*s,p+Vector2(0,0)*s],Color("#b8b99a"))
 c.draw_polyline(PackedVector2Array([p+Vector2(-15,8)*s,p+Vector2(-7,8)*s,p+Vector2(-3,4)*s]),Color("#738574"),s,true)
 c.draw_polyline(PackedVector2Array([p+Vector2(3,11)*s,p+Vector2(12,13)*s,p+Vector2(19,13)*s]),Color("#d1c9a6"),s,true)
static func snowy_peak(c:Control,p:Vector2,s:float)->void:
 hill(c,p,s)
 var snow=[]
 for q in [Vector2(-13,-3),Vector2(-8,-3),Vector2(-8,-11),Vector2(-2,-16),Vector2(5,-14),Vector2(10,-5),Vector2(14,-5),Vector2(10,-1),Vector2(6,-3),Vector2(2,1),Vector2(-2,-4),Vector2(-8,0)]:snow.append(p+q*s)
 c.polygon(snow,Color("#e9eee4"));c.draw_line(p+Vector2(-2,-14)*s,p+Vector2(3,-5)*s,Color("#c7d9d8"),s,true)
static func frontier(c:Control)->void:
 # Uneven pale chart washes suggest more terrain beyond the surveyed margins.
 c.polygon([Vector2(12,32),Vector2(157,32),Vector2(146,46),Vector2(118,42),Vector2(97,55),Vector2(73,47),Vector2(51,60),Vector2(25,53),Vector2(12,76)],Color(.72,.77,.68,.22))
 c.polygon([Vector2(12,32),Vector2(29,57),Vector2(21,86),Vector2(37,117),Vector2(25,146),Vector2(33,179),Vector2(20,213),Vector2(28,244),Vector2(12,284)],Color(.69,.74,.64,.22))
 c.polygon([Vector2(399,32),Vector2(638,32),Vector2(638,66),Vector2(614,51),Vector2(584,60),Vector2(553,45),Vector2(526,54),Vector2(493,43),Vector2(467,52),Vector2(431,43)],Color(.72,.77,.68,.22))
static func stream(c:Control,points:PackedVector2Array,width:float)->void:
 c.draw_polyline(points,Color("#c5d1b4"),width+4,true);c.draw_polyline(points,Color("#587f82"),width+2,true);c.draw_polyline(points,Color("#80aeb4"),width,true)
static func region(c:Control)->void:
 var geo=preload("res://scripts/atlas_geography378.gd")
 land(c)
 frontier(c)
 for row in geo.WEST_HILLS:hill(c,row[0],row[1])
 var western_woods=RandomNumberGenerator.new();western_woods.seed=379017
 for i in 85:
  var p=Vector2(western_woods.randf_range(19,181),western_woods.randf_range(64,274))
  if p.x>139 and p.y<150:continue
  var blocked=false
  for row in geo.WEST_HILLS:
   if p.distance_to(row[0])<15*float(row[1]):blocked=true
  if not blocked:tree(c,p,.62+float(i%4)*.09,i%3==0)
 var coast=PackedVector2Array([Vector2(12,286),Vector2(58,282),Vector2(105,290),Vector2(145,289),Vector2(190,300),Vector2(240,301),Vector2(278,291),Vector2(316,294),Vector2(356,280),Vector2(405,285),Vector2(448,276),Vector2(482,280),Vector2(526,274),Vector2(580,280),Vector2(607,281),Vector2(638,274),Vector2(638,318),Vector2(12,318)])
 water(c,coast)
 var lake=PackedVector2Array([Vector2(155,61),Vector2(209,43),Vector2(270,47),Vector2(330,42),Vector2(377,57),Vector2(396,80),Vector2(391,101),Vector2(368,123),Vector2(342,132),Vector2(314,147),Vector2(303,166),Vector2(287,166),Vector2(279,144),Vector2(250,132),Vector2(211,127),Vector2(176,109),Vector2(163,84)])
 water(c,lake,c.season=="Winter")
 stream(c,PackedVector2Array(geo.TOWN_RIVER),10)
 stream(c,PackedVector2Array([Vector2(305,263),Vector2(337,278),Vector2(357,292)]),7)
 stream(c,PackedVector2Array([Vector2(309,268),Vector2(294,286),Vector2(303,300)]),4)
 # Wayfarer's independent headwater is EAST of a continuous wooded watershed ridge.
 c.draw_circle(Vector2(529,93),5,Color("#6b9fa8"));stream(c,PackedVector2Array(geo.WILDS_RIVER),6)
 for branch in geo.STREAMS:stream(c,PackedVector2Array(branch.points),1.7)
 for p in geo.DIVIDE:hill(c,p,.95)
 for row in geo.SNOW_PEAKS:snowy_peak(c,row[0],row[1])
 # Woodland follows the regional river and trails; settlement symbols are not street plans.
 for i in 150:
  var p=Vector2(347+posmod(i*43,277),70+posmod(i*71,199))
  if p.x<405 and p.y<153:continue
  if p.distance_to(Vector2(412,123))<31:continue
  if p.distance_to(geo.WILDS)<26:continue
  if p.x>598:continue
  var clear=false
  var lines=[geo.EAST_ROAD,geo.NORTH_TRAIL,geo.WILDS_RIVER,geo.DIVIDE]
  for branch in geo.STREAMS:lines.append(branch.points)
  for route in lines:
   for n in range(1,route.size()):
    if Geometry2D.get_closest_point_to_segment(p,route[n-1],route[n]).distance_to(p)<(15 if route==geo.DIVIDE else 10):clear=true
  if not clear:tree(c,p,.65+float(i%4)*.10,i%6==0)
 for p in [Vector2(340,164),Vector2(342,246),Vector2(347,261),Vector2(351,179),Vector2(353,230)]:tree(c,p,.78)
 for i in 16:
  var p=Vector2(141+posmod(i*31,133),148+posmod(i*47,130))
  if p.distance_to(geo.TOWN)>25 and p.distance_to(Vector2(246,280))>30:tree(c,p,.62,i%3==0)
 trail(c,PackedVector2Array(geo.EAST_ROAD),3)
 trail(c,PackedVector2Array(geo.NORTH_TRAIL),2)
 dashed(c,PackedVector2Array([Vector2(346,165),Vector2(367,146),Vector2(386,125)]),Color("#ac7841"),6)
 trail(c,PackedVector2Array(geo.SOUTH_TRAIL),2)
 dashed(c,PackedVector2Array([Vector2(258,251),Vector2(250,265),Vector2(246,280)]),Color("#ac7841"),6)
 for p in [Vector2(346,165),Vector2(258,251)]:c.polygon([p+Vector2(0,-4),p+Vector2(4,0),p+Vector2(0,4),p+Vector2(-4,0)],Color("#bd9154"))
 dock(c,geo.TOWN_BRIDGE)
 var ferry=Color("#476d86",.45 if c.season=="Winter" else .9)
 dashed(c,PackedVector2Array([Vector2(301,214),Vector2(303,209),Vector2(302,177),Vector2(307,151),Vector2(350,130),Vector2(374,119),c.routes[1][1]]),ferry,7)
 dashed(c,PackedVector2Array([Vector2(301,214),Vector2(295,233),Vector2(299,256),Vector2(307,273),Vector2(273,281),c.routes[2][1]]),ferry,7)
 # All four places use the same regional symbol family and explicit rank sizes.
 var symbols=preload("res://scripts/atlas_symbols381.gd")
 for key in symbols.SPECS:
  symbols.draw(c,key,c.routes[int(symbols.SPECS[key].route)][1])
 boat(c,Vector2(415,303),.85)
 for i in 20:
  var p=Vector2(25+posmod(i*31,600),297+posmod(i*17,17))
  if p.distance_to(Vector2(477,299))>36:c.draw_arc(p,5,.3,2.6,8,Color("#b4d1c3"),1,true)
 label(c,Vector2(445,51),"WOODLAND RIDGE",9)
 label(c,Vector2(521,68),"SNOWY HEIGHTS",9)
 label(c,Vector2(24,51),"UNCHARTED REACHES",9)
 var offsets=[Vector2(-119,16),Vector2(17,5),Vector2(-111,11),Vector2(-50,28),Vector2(-55,-15),Vector2(17,5)]
 for i in c.routes.size():
  var p:Vector2=c.routes[i][1];c.draw_circle(p,9,Color("#355b5b"));c.draw_arc(p,9,0,TAU,24,Color("#f2dfac"),1.5,true)
  c.caption(p+Vector2(-3,4),str(i+1),11,Color("#fff2c7"))
  if c.selected==i:c.draw_arc(p,13,0,TAU,24,Color("#a6763e"),2,true)
  label(c,p+offsets[i],str(c.routes[i][0]),12)
 var here=DATA.AREAS.find(DATA.current_area(c.player))
 if here>=0:
  var p:Vector2=c.routes[here][1];c.polygon([p+Vector2(0,-20),p+Vector2(5,-15),p+Vector2(0,-10),p+Vector2(-5,-15)],Color("#f4e5ae"))
 c.compass(Vector2(608,67))

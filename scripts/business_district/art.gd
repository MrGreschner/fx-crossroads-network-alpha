extends RefCounted
const C=preload("res://scripts/business_district/catalog.gd")
const FONT=preload("res://assets/fonts/CrossroadsUI.ttf")
static var actor_sources:Dictionary={}
static var actor_textures:Dictionary={}
static func actor(index:int,pose:int)->Texture2D:
 var key=str(index)+":"+str(clampi(pose,0,9))
 if actor_textures.has(key):return actor_textures[key]
 if actor_sources.is_empty():actor_sources=JSON.parse_string(FileAccess.get_file_as_string("res://content/business-actors.json"))
 var info=C.person(index) if index>=0 else {};var base=8 if index==-1 else posmod(-index-2,8) if index<0 else ["ram","badger","cat","newt","human","fox","hare","owl"].find(info.species)
 var svg:String=actor_sources[str(maxi(0,base))+":"+str(clampi(pose,0,9))]
 if index>=100:
  var original=C.all().staff[maxi(0,base)];svg=svg.replace(original.coat,"#"+str(info.coat).trim_prefix("#").left(6)).replace(original.skin,"#"+str(info.skin).trim_prefix("#").left(6))
  var badge='<circle cx="'+str(12+posmod(index,8))+'" cy="24" r="2" fill="#e8d3a0"/>'
  svg=svg.replace('</svg>',badge+'</svg>')
 var im=Image.new();im.load_svg_from_string(svg);var texture=ImageTexture.create_from_image(im);actor_textures[key]=texture
 if actor_textures.size()>900:actor_textures.clear();actor_textures[key]=texture
 return texture
static func ink(c:CanvasItem,p:Vector2,t:String,size:int=15,col:Color=Color("#e9dfc5"))->void:c.draw_string(FONT,p,t,HORIZONTAL_ALIGNMENT_LEFT,-1,size,col)
static func rect(c:CanvasItem,p:Vector2,s:Vector2,col:Color)->void:c.draw_rect(Rect2(p,s),col)
static func rounded(c:CanvasItem,r:Rect2,col:Color,radius:int=6,border:Color=Color(0,0,0,0))->void:
 var skin=StyleBoxFlat.new();skin.bg_color=col;skin.set_corner_radius_all(radius)
 if border.a>0:skin.border_color=border;skin.set_border_width_all(2)
 c.draw_style_box(skin,r)
static func ellipse(c:CanvasItem,p:Vector2,s:Vector2,col:Color)->void:
 var pts=PackedVector2Array()
 for n in 24:pts.append(p+Vector2(cos(n*TAU/24)*s.x,sin(n*TAU/24)*s.y))
 c.draw_colored_polygon(pts,col)
static func box(c:CanvasItem,p:Vector2,s:Vector2,col:Color,h:float=12)->void:
 rect(c,p+Vector2(3,5),s,Color(0,0,0,.17));rect(c,p-Vector2(0,h),s,col)
 c.draw_colored_polygon(PackedVector2Array([p+Vector2(0,s.y-h),p+Vector2(s.x,s.y-h),p+s,p+Vector2(0,s.y)]),col.darkened(.25))
 c.draw_line(p-Vector2(0,h),p+Vector2(s.x,-h),col.lightened(.2),2,true)
static func pot(c:CanvasItem,p:Vector2,col:Color=Color("#709365"))->void:
 ellipse(c,p+Vector2(2,4),Vector2(15,7),Color(0,0,0,.15));box(c,p-Vector2(10,6),Vector2(20,15),Color("#a8795d"),12)
 for d in [Vector2(-8,-25),Vector2(8,-29),Vector2(0,-35)]:c.draw_line(p-Vector2(0,12),p+d,Color("#526f57"),3,true);ellipse(c,p+d,Vector2(10,6),col)
static func tree(c:CanvasItem,p:Vector2,type:int=0)->void:
 ellipse(c,p+Vector2(12,5),Vector2(46,17),Color(0,0,0,.14));c.draw_line(p,p-Vector2(4,68),Color("#786247"),13);c.draw_line(p-Vector2(3,33),p+Vector2(25,-66),Color("#786247"),6)
 for pair in [[-25,-64,29],[9,-84,35],[32,-58,30],[-7,-48,28]]:
  var at=p+Vector2(pair[0],pair[1]);ellipse(c,at,Vector2(pair[2],pair[2]*.72),Color("#647d56") if type%2==0 else Color("#a7a169"));c.draw_arc(at-Vector2(2,5),pair[2]*.7,3.7,5.6,12,Color("#bdc591",.35),3,true)
static func lantern(c:CanvasItem,p:Vector2,night:bool)->void:
 c.draw_line(p,p-Vector2(0,70),Color("#485f61"),5);c.draw_line(p-Vector2(5,70),p+Vector2(11,-70),Color("#485f61"),4)
 rect(c,p+Vector2(5,-70),Vector2(12,19),Color("#4d605f"));rect(c,p+Vector2(8,-67),Vector2(6,12),Color("#f4cf80") if night else Color("#b9bd9d"))
 if night:
  for n in range(3,0,-1):ellipse(c,p+Vector2(10,-58),Vector2(23*n,18*n),Color(1,.75,.35,.025))
static func goods(c:CanvasItem,p:Vector2,kind:String,n:int=3,scale:float=1)->void:
 for j in mini(n,8):
  var q=p+Vector2((j%4)*15,(j/4)*13)*scale
  match kind:
   "cook":
    ellipse(c,q,Vector2(9,5)*scale,Color("#eee0bb"));ellipse(c,q-Vector2(0,2)*scale,Vector2(7,4)*scale,Color("#a1774b"));c.draw_circle(q+Vector2(2,-3)*scale,2*scale,Color("#719064"))
   "fish":
    ellipse(c,q,Vector2(10,4)*scale,Color("#9cc4c1"));c.draw_colored_polygon(PackedVector2Array([q+Vector2(8,0)*scale,q+Vector2(15,-5)*scale,q+Vector2(15,5)*scale]),Color("#799eaa"));c.draw_circle(q-Vector2(5,0)*scale,1.2*scale,Color("#314e5a"))
   "tailor":
    c.draw_colored_polygon(PackedVector2Array([q+Vector2(-8,-7)*scale,q+Vector2(-3,-10)*scale,q+Vector2(3,-10)*scale,q+Vector2(9,-5)*scale,q+Vector2(5,-1)*scale,q+Vector2(4,8)*scale,q+Vector2(-5,8)*scale,q+Vector2(-5,-1)*scale,q+Vector2(-10,-3)*scale]),[Color("#b58eae"),Color("#8aa6ae"),Color("#d1bd7d")][j%3])
   "grower":
    for x in [-3,3]:c.draw_circle(q+Vector2(x,0)*scale,5*scale,Color("#b68166") if j%2 else Color("#a9b575"));c.draw_line(q-Vector2(0,3)*scale,q-Vector2(0,9)*scale,Color("#78955f"),2*scale)
   "artisan","miner":
    c.draw_line(q+Vector2(-6,6)*scale,q+Vector2(3,-7)*scale,Color("#ab8558"),4*scale);c.draw_line(q+Vector2(-3,-6)*scale,q+Vector2(8,-3)*scale,Color("#8dabad"),6*scale)
   "courier":box(c,q-Vector2(7,3)*scale,Vector2(13,9)*scale,Color("#c0a475"),5*scale);c.draw_line(q-Vector2(1,8)*scale,q+Vector2(-1,5)*scale,Color("#efe0b9"),2*scale)
   "rental":c.draw_line(q+Vector2(-7,7)*scale,q+Vector2(-5,-10)*scale,Color("#8d7855"),3*scale);c.draw_line(q+Vector2(7,7)*scale,q+Vector2(5,-10)*scale,Color("#8d7855"),3*scale);c.draw_line(q-Vector2(5,4)*scale,q+Vector2(5,-4)*scale,Color("#b7a17a"),2*scale)
   _:box(c,q-Vector2(6,2)*scale,Vector2(12,8)*scale,Color("#c6ac79"),7*scale)
static func fixture(c:CanvasItem,o:Vector2,kind:String,col:Color,level:int=0)->void:
 if kind=="cook":
  box(c,o,Vector2(85,46),Color("#75817c"),23);rect(c,o+Vector2(4,-23),Vector2(77,39),Color("#424f53"))
  for x in [21,61]:ellipse(c,o+Vector2(x,-3),Vector2(14,9),Color("#b1b9a5"));ellipse(c,o+Vector2(x,-5),Vector2(10,6),Color("#61594b"))
  box(c,o+Vector2(84,8),Vector2(28,33),Color("#a78b65"),18);goods(c,o+Vector2(96,-6),"grower",1)
 elif kind=="tailor":
  box(c,o,Vector2(100,43),Color("#a88e70"),20);rect(c,o+Vector2(12,-15),Vector2(43,29),Color("#b29cb5"));box(c,o+Vector2(60,-5),Vector2(27,14),Color("#526467"),16);c.draw_arc(o+Vector2(78,-17),11,0,TAU,16,Color("#9caba6"),3,true)
 elif kind=="fish":
  box(c,o,Vector2(100,43),Color("#8ba7a8"),23);rect(c,o+Vector2(5,-17),Vector2(90,30),Color("#cadbd0"));goods(c,o+Vector2(18,-4),"fish",4)
 elif kind=="grower":
  box(c,o,Vector2(100,43),Color("#8e9b6a"),20);goods(c,o+Vector2(15,-7),"grower",7)
 elif kind=="miner":
  box(c,o,Vector2(100,44),Color("#6f7879"),23);c.draw_rect(Rect2(o+Vector2(10,-10),Vector2(33,25)),Color("#464e50"));ellipse(c,o+Vector2(27,5),Vector2(12,8),Color("#df9c57"));c.draw_line(o+Vector2(65,-4),o+Vector2(91,-4),Color("#9dacad"),10)
 elif kind=="rental":
  box(c,o,Vector2(100,43),Color("#8d9f91"),20);goods(c,o+Vector2(23,-4),"rental",3)
 elif kind=="courier":
  box(c,o,Vector2(100,43),Color("#a68a69"),20);goods(c,o+Vector2(20,-5),"courier",5)
 else:
  box(c,o,Vector2(100,43),Color("#a48a69"),20);goods(c,o+Vector2(18,-6),"artisan" if kind=="artisan" else "merchant",3)
 if level>0:
  box(c,o+Vector2(116,4),Vector2(30,37),col.darkened(.2),36)
  for y in [-26,-14,-2]:c.draw_line(o+Vector2(121,y),o+Vector2(140,y),col.lightened(.4),2)
  if kind=="cook":
   c.draw_colored_polygon(PackedVector2Array([o+Vector2(-3,-60),o+Vector2(86,-60),o+Vector2(75,-78),o+Vector2(9,-78)]),Color("#8faaa2"));rect(c,o+Vector2(25,-95),Vector2(32,18),Color("#718b87"))
  if level>1:
   box(c,o+Vector2(0,48),Vector2(105,21),col,11);goods(c,o+Vector2(13,39),kind,mini(level+1,4))
  if level>2:
   for x in [12,83]:c.draw_circle(o+Vector2(x,53),7,Color("#e1cb89"));c.draw_circle(o+Vector2(x,53),3,col.darkened(.4))
  rect(c,o+Vector2(-3,44),Vector2(108,5),col);ink(c,o+Vector2(5,65),"UPGRADED "+str(level),10,col.lightened(.3))
static func ground(c:CanvasItem,night:bool)->void:
 rect(c,Vector2(-200,-150),Vector2(3400,3500),Color("#79856a"))
 for y in range(0,3400,32):
  for x in range(0,2350,32):
   if posmod(x*17+y*11,97)<18:rect(c,Vector2(x+3,y+2),Vector2(3,5),Color("#9ba17d",.5))
 for y in [60,680,1300,1920,2540,3160]:
  rect(c,Vector2(35,y),Vector2(2280,90),Color("#c6b99c"))
  for x in range(40,2300,36):
   c.draw_line(Vector2(x,y+5),Vector2(x-12,y+84),Color("#a99e84",.4),1)
   for yy in [27,53]:c.draw_line(Vector2(x-10,y+yy),Vector2(x+23,y+yy),Color("#a99e84",.3),1)
 for x in [38,752,1472,2192]:
  rect(c,Vector2(x,130),Vector2(64,3150),Color("#c6b99c"))
  for y in range(140,3250,40):c.draw_line(Vector2(x+3,y),Vector2(x+60,y),Color("#a99e84",.35),1)
 rect(c,Vector2(-100,-70),Vector2(2600,90),Color("#557f89"));c.draw_line(Vector2(-100,22),Vector2(2500,22),Color("#c1b68f"),8)
 for v in C.ventures():
  var p=C.plot(v.id)
  tree(c,p+Vector2(-48,400));lantern(c,p+Vector2(590,420),night);pot(c,p+Vector2(607,50))
  box(c,p+Vector2(60,500),Vector2(95,22),Color("#927e61"),12);pot(c,p+Vector2(190,515))
static func premises(c:CanvasItem,v:Dictionary,b:Dictionary,selected:bool,night:bool)->void:
 c.draw_set_transform(C.plot(v.id),0,Vector2.ONE*1.3)
 var p=Vector2.ZERO;var owned=not b.is_empty();var accent=Color(v.colors[0]);var dark=Color(v.colors[1]);var pale=Color(v.colors[2])
 # Cutaway premises: back roof, side walls and an open trading floor.
 rounded(c,Rect2(p+Vector2(6,20),Vector2(446,325)),Color(0,0,0,.14),8)
 rounded(c,Rect2(p-Vector2(6,10),Vector2(452,333)),Color("#4f6560") if selected else Color("#8d9075"),8)
 rect(c,p,Vector2(440,310),Color("#d2c3a0"));rect(c,p+Vector2(9,12),Vector2(422,290),Color("#b7a184"))
 for y in range(15,304,21):
  c.draw_line(p+Vector2(10,y),p+Vector2(430,y),Color("#897c65",.38),1)
  for x in range(20+(y%3)*12,430,80):c.draw_line(p+Vector2(x,y),p+Vector2(x,y+20),Color("#897c65",.25),1)
 rect(c,p+Vector2(0,-45),Vector2(440,72),Color("#d9cdb2"));rect(c,p+Vector2(-4,15),Vector2(12,290),dark);rect(c,p+Vector2(432,15),Vector2(12,290),dark)
 c.draw_colored_polygon(PackedVector2Array([p+Vector2(-16,-45),p+Vector2(18,-95),p+Vector2(421,-95),p+Vector2(457,-45)]),dark)
 for x in range(25,430,27):c.draw_line(p+Vector2(x,-88),p+Vector2(x-12,-48),accent.lightened(.18),2)
 rounded(c,Rect2(p+Vector2(70,-43),Vector2(302,42)),dark.darkened(.18),4)
 ink(c,p+Vector2(88,-16),b.get("name",v.name).left(26),21,pale)
 # Timber cornices, wall seams and patterned roof keep the cutaway grounded in town.
 for y in [-78,-62]:c.draw_line(p+Vector2(3,y),p+Vector2(440,y),dark.lightened(.15),1)
 for y in [-39,-9]:
  for x in range(5,433,65):c.draw_line(p+Vector2(x,y),p+Vector2(x,y+24),Color("#a89d82",.4),1)
 rect(c,p+Vector2(0,14),Vector2(440,7),dark.lightened(.12))
 # Back windows and receiving bay.
 for x in [22,370]:
  rect(c,p+Vector2(x,-30),Vector2(45,46),Color("#657a77"));rect(c,p+Vector2(x+4,-26),Vector2(37,38),Color("#d8bb7a") if night else Color("#9db9b2"));c.draw_line(p+Vector2(x+22,-26),p+Vector2(x+22,13),pale,2)
 rect(c,p+Vector2(300,30),Vector2(103,63),Color("#7e8771"));ink(c,p+Vector2(307,49),"RECEIVING",10,Color("#e0dbb9"))
 if owned:
  var layout=int(b.layout);var craft=Vector2(30 if layout!=1 else 207,92)
  if not b.has("operations"):fixture(c,p+craft,v.icon,accent,int(b.equipment))
  # Distinct silhouettes and furniture for every trade.
  if v.id=="kitchen":
   c.draw_arc(p+Vector2(380,138),23,0,TAU,20,dark,5);box(c,p+Vector2(360,138),Vector2(40,33),pale,13)
   for x in [61,356]:
    box(c,p+Vector2(x,256),Vector2(45,25),Color("#ac8b63"),13)
    for xx in [-9,48]:ellipse(c,p+Vector2(x+xx,267),Vector2(8,6),accent)
  elif v.id=="clothier":
   for x in [29,310]:
    c.draw_line(p+Vector2(x,233),p+Vector2(x,193),dark,4);c.draw_line(p+Vector2(x+76,233),p+Vector2(x+76,193),dark,4);c.draw_line(p+Vector2(x,193),p+Vector2(x+76,193),dark,3);goods(c,p+Vector2(x+16,210),"tailor",4)
   ellipse(c,p+Vector2(175,89),Vector2(17,7),dark);c.draw_line(p+Vector2(175,90),p+Vector2(175,48),dark,3);goods(c,p+Vector2(175,55),"tailor",1,1.7)
  elif v.id=="workshop":
   rect(c,p+Vector2(24,25),Vector2(130,40),Color("#7d725a"))
   for x in range(34,148,16):c.draw_line(p+Vector2(x,32),p+Vector2(x+5,50),Color("#bec5b2"),4)
   box(c,p+Vector2(285,146),Vector2(110,38),Color("#8c7759"),20);goods(c,p+Vector2(300,131),"artisan",5)
  elif v.id=="fishery":
   box(c,p+Vector2(285,135),Vector2(110,45),Color("#88a9a5"),28)
   rect(c,p+Vector2(291,109),Vector2(98,33),Color("#bdcfca"));goods(c,p+Vector2(302,122),"fish",5)
  elif v.id=="garden":
   for x in [26,323]:
    box(c,p+Vector2(x,150),Vector2(82,33),Color("#9b845f"),19);goods(c,p+Vector2(x+12,137),"grower",6)
   pot(c,p+Vector2(180,74));pot(c,p+Vector2(225,75))
  elif v.id=="mine":
   for x in [35,330]:
    box(c,p+Vector2(x,151),Vector2(73,38),Color("#776c60"),15)
    for n in 4:c.draw_colored_polygon(PackedVector2Array([p+Vector2(x+8+n*14,136),p+Vector2(x+17+n*14,120),p+Vector2(x+28+n*14,137)]),[Color("#9aa4a0"),Color("#b5a67e"),Color("#838f9c")][n%3])
  elif v.id=="store":
   for x in [25,300]:
    box(c,p+Vector2(x,131),Vector2(105,43),Color("#9e8966"),35)
    for y in [98,122]:goods(c,p+Vector2(x+12,y),"merchant",6)
  elif v.id=="courier":
   rect(c,p+Vector2(25,23),Vector2(170,48),Color("#c5bc99"));c.draw_polyline(PackedVector2Array([p+Vector2(42,45),p+Vector2(87,33),p+Vector2(105,56),p+Vector2(170,39)]),accent,3,true)
   for x in [40,87,170]:c.draw_circle(p+Vector2(x,44),4,dark)
   box(c,p+Vector2(295,150),Vector2(105,35),Color("#9c8569"),20);goods(c,p+Vector2(310,133),"courier",6)
  elif v.id=="rental":
   for x in [31,330]:goods(c,p+Vector2(x+14,151),"rental",3,1.5)
   for x in [70,130,190]:c.draw_line(p+Vector2(x,25),p+Vector2(x,63),dark,3);rect(c,p+Vector2(x-7,47),Vector2(14,20),Color("#d2c17b"))
  # Stock is drawn in the live layer; workbench and till stay static.
  box(c,p+Vector2(146,205),Vector2(144,37),dark,27);rect(c,p+Vector2(152,179),Vector2(132,28),pale)
  box(c,p+Vector2(249,187),Vector2(22,18),Color("#526d70"),18);rect(c,p+Vector2(252,169),Vector2(16,10),Color("#b5d2bb"))
  var shelf_x=300 if layout!=2 else 75
  box(c,p+Vector2(shelf_x,248),Vector2(93,23),accent.darkened(.12),18)
  # Display improvements make the sales area visibly richer.
  if b.display>0:
   for x in [26,400]:pot(c,p+Vector2(x,290),accent.lightened(.12))
   rounded(c,Rect2(p+Vector2(151,253),Vector2(135,35)),accent.darkened(.2),3);ink(c,p+Vector2(161,276),"LOCAL FAVOURITES",10,pale)
  if b.cold>0:
   box(c,p+Vector2(350,67),Vector2(52,61),Color("#adc4bd"),30);rect(c,p+Vector2(356,43),Vector2(40,44),Color("#7facae"));c.draw_line(p+Vector2(364,57),p+Vector2(364,73),pale,3)
  # Individual street-front silhouettes: a real cart, fabric canopy and trade fixtures.
  if v.id=="kitchen":
   var cart=p+Vector2(80,375)
   for x in [-35,36]:c.draw_circle(cart+Vector2(x,9),10,Color("#495754"));c.draw_circle(cart+Vector2(x,9),5,Color("#b6a27c"))
   box(c,cart-Vector2(49,24),Vector2(98,30),Color("#a87753"),14)
   for x in [-49,49]:c.draw_line(cart+Vector2(x,-11),cart+Vector2(x,-73),dark,3)
   for x in range(-55,55,14):rect(c,cart+Vector2(x,-78),Vector2(14,18),accent if (x+55)/14%2==0 else pale)
   c.draw_line(cart+Vector2(-55,-60),cart+Vector2(55,-60),dark,2);goods(c,cart-Vector2(27,37),"cook",4)
  elif v.id=="clothier":
   for x in range(16,426,32):rect(c,p+Vector2(x,306),Vector2(32,14),accent if x%64==16 else pale)
  elif v.id=="fishery":
   c.draw_line(p+Vector2(7,-21),p+Vector2(-39,-21),dark,3);c.draw_line(p+Vector2(-30,-20),p+Vector2(-30,4),dark,2);ellipse(c,p+Vector2(-30,12),Vector2(28,13),dark);goods(c,p+Vector2(-40,12),"fish",1,1.5)
  elif v.id=="mine":
   box(c,p+Vector2(374,-58),Vector2(32,26),Color("#78766c"),55);rect(c,p+Vector2(370,-118),Vector2(40,10),dark)
  elif v.id=="courier":
   box(c,p+Vector2(377,343),Vector2(34,18),accent,37);rect(c,p+Vector2(382,311),Vector2(24,4),dark)
  elif v.id=="rental":goods(c,p+Vector2(367,354),"rental",3,1.5)
  elif v.id=="garden":
   for x in [120,330]:pot(c,p+Vector2(x,348),accent)
  ink(c,p+Vector2(130,343),v.kind.to_upper(),11,Color("#354e50"))
 else:
  rounded(c,Rect2(p+Vector2(100,100),Vector2(240,104)),Color("#ede0bb"),6,dark)
  ink(c,p+Vector2(121,134),"PREMISES AVAILABLE",17,dark);ink(c,p+Vector2(121,162),v.kind,15,dark);ink(c,p+Vector2(121,187),"Inspect assets & acquisition",13,dark)
  for x in [30,360]:box(c,p+Vector2(x,227),Vector2(48,34),Color("#a98b63"),19)
 # Street-front border, entry and chalkboard.
 for x in [0,285]:rect(c,p+Vector2(x,310),Vector2(155,5),dark)
 pot(c,p+Vector2(10,346));pot(c,p+Vector2(432,346))
 if owned:
  box(c,p+Vector2(35,332),Vector2(63,10),Color("#8b765a"),43);rect(c,p+Vector2(40,292),Vector2(53,34),Color("#304e50"));ink(c,p+Vector2(47,314),"OPEN" if b.open else "CLOSED",10,Color("#d7d7a6"))
 if selected:rounded(c,Rect2(p-Vector2(10,-315),Vector2(460,3)),Color("#edcd83"),1)
 c.draw_set_transform(Vector2.ZERO)
static func person(c:CanvasItem,p:Vector2,index:int,pose:int,scale:float=1,fade:float=1)->void:
 ellipse(c,p+Vector2(2,1),Vector2(12,5)*scale,Color(0,0,0,.16*fade))
 c.draw_texture_rect(actor(index,pose),Rect2(p-Vector2(24,62)*scale,Vector2(48,64)*scale),false,Color(1,1,1,fade))

static var glow:Texture2D
static func night_lights(c:CanvasItem)->void:
 if glow==null:
  var gradient=Gradient.new();gradient.offsets=PackedFloat32Array([0,.3,.7,1]);gradient.colors=PackedColorArray([Color(1,.64,.23,.35),Color(1,.55,.18,.20),Color(1,.50,.15,.06),Color(1,.50,.15,0)])
  var texture=GradientTexture2D.new();texture.gradient=gradient;texture.width=128;texture.height=128;texture.fill=GradientTexture2D.FILL_RADIAL;texture.fill_from=Vector2(.5,.5);texture.fill_to=Vector2(1,.5);glow=texture
 for y in [162,782,1402,2022,2642,3262]:
  for x in [70,790,1510,2230]:c.draw_texture_rect(glow,Rect2(Vector2(x+50,y-49)-Vector2(110,85),Vector2(220,170)),false)
 for v in C.ventures():
  for x in [44,392]:c.draw_texture_rect(glow,Rect2(C.plot(v.id)+Vector2(x,-5)-Vector2(55,45),Vector2(110,90)),false)

static var icon_sources:Dictionary={}
static var icon_cache:Dictionary={}
static func item_texture(key:String,kind:String)->Texture2D:
 var id=kind+":"+key
 if icon_cache.has(id):return icon_cache[id]
 if icon_sources.is_empty():icon_sources=JSON.parse_string(FileAccess.get_file_as_string("res://content/business-icons.json"))
 var im=Image.new();im.load_svg_from_string(icon_sources.get(id,icon_sources.values()[0]));var texture=ImageTexture.create_from_image(im);icon_cache[id]=texture;return texture

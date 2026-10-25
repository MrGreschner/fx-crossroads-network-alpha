extends RefCounted
## Original articulated vector art. Gait follows distance travelled; attacks have
## anticipation, strike and recovery poses. No purchased artwork is embedded.
const INK=Color("#202532")
static var atlases:Dictionary={}
static func poly(c:CanvasItem,points:Array,col:Color,line:float=2.0)->void:
 var ps=PackedVector2Array(points)
 var lo=Vector2(INF,INF);var hi=Vector2(-INF,-INF)
 for point in ps:lo=lo.min(point);hi=hi.max(point)
 var colours=PackedColorArray()
 for point in ps:
  var t=clampf(((point.x-lo.x)/maxf(1,hi.x-lo.x)+(point.y-lo.y)/maxf(1,hi.y-lo.y))*.5,0,1)
  colours.append(col.lightened(.15*(1-t)).darkened(.17*t))
 c.draw_polygon(ps,colours)
 if line>0:ps.append(ps[0]);c.draw_polyline(ps,INK,line,true)
static func oval(c:CanvasItem,p:Vector2,r:Vector2,col:Color,outline:bool=true)->void:
 var points=PackedVector2Array()
 for n in 20:points.append(p+Vector2(cos(n*TAU/20)*r.x,sin(n*TAU/20)*r.y))
 var colours=PackedColorArray()
 for point in points:
  var light=clampf(.5+(point.x-p.x)/maxf(1,r.x)*.23+(point.y-p.y)/maxf(1,r.y)*.36,0,1)
  colours.append(col.lightened(.25*(1-light)).darkened(.28*light))
 c.draw_polygon(points,colours)
 if outline:points.append(points[0]);c.draw_polyline(points,INK,2.1,true)
static func gem(c:CanvasItem,p:Vector2,size:float,col:Color)->void:
 poly(c,[p+Vector2(-size*.6,0),p+Vector2(-size*.25,-size),p+Vector2(size*.45,-size*.7),p+Vector2(size*.65,size*.3),p+Vector2(0,size*.65)],col)
 poly(c,[p+Vector2(-size*.25,-size),p,p+Vector2(size*.45,-size*.7)],col.lightened(.35),0)
 c.draw_line(p,p+Vector2(0,size*.65),col.darkened(.35),2,true)
static func eye(c:CanvasItem,p:Vector2,col:Color,blink:bool=false)->void:
 if blink:c.draw_line(p-Vector2(3,0),p+Vector2(3,0),INK,2,true)
 else:
  oval(c,p,Vector2(4,4),INK,false);c.draw_circle(p+Vector2(0,1),2,col);c.draw_circle(p+Vector2(-1,0),.8,Color.WHITE)
static func limb(c:CanvasItem,a:Vector2,b:Vector2,tip:Vector2,col:Color,width:float=5)->void:
 c.draw_polyline(PackedVector2Array([a,b,tip]),INK,width+3,true)
 c.draw_polyline(PackedVector2Array([a,b,tip]),col,width,true)
 c.draw_line(a,b,col.lightened(.23),maxf(1,width*.25),true)
static func lantern(c:CanvasItem,p:Vector2,clock:float,scale_value:float=1)->void:
 transform(c,p,0,Vector2.ONE*scale_value)
 c.draw_arc(Vector2(0,-17),7,PI,TAU,12,Color("#cab480"),2,true)
 poly(c,[Vector2(-9,-15),Vector2(9,-15),Vector2(11,12),Vector2(-11,12)],Color("#2d383c"))
 poly(c,[Vector2(-6,-10),Vector2(6,-10),Vector2(7,8),Vector2(-7,8)],Color("#f1ae4a"),0)
 c.draw_line(Vector2(0,-10),Vector2(0,8),Color("#f9e5a1"),3,true)
 poly(c,[Vector2(-3,6),Vector2(-4,-1),Vector2(1,-7-sin(clock*9)*2),Vector2(4,3)],Color("#fff1b4"),0)
 c.draw_line(Vector2(-11,12),Vector2(11,12),Color("#c5a773"),4,true)
 transform(c,Vector2.ZERO)
static func enemy(c:CanvasItem,e:Dictionary,clock:float,alpha:float=1)->void:
 if not bool(e.get("vector_source",false)) and cached_enemy(c,e,clock,alpha):return
 var kind:String=e.get("form",e.kind);var big:bool=kind in ["foreman","wickeater"]
 var gait:float=float(e.get("gait",0));var moving:bool=float(e.get("moving",0))>.05
 var walk:float=sin(gait) if moving else 0.0
 var wind:float=clampf(1-float(e.get("left",0))/maxf(.01,float(e.get("total",1))),0,1) if not str(e.get("action","")).is_empty() else 0.0
 var strike:float=sin(clampf(float(e.get("strike",0))/.3,0,1)*PI)
 var size:float=float(e.get("body_scale",1.0))*float(e.get("art_scale",1.0))
 var tint:Color=Color(e.color);var face:float=-1.0 if float(e.get("facing",1))<0 else 1.0
 transform(c,e.pos,0,Vector2.ONE)
 oval(c,Vector2(0,12),Vector2(25*size,10*size),Color(0,0,0,.23),false)
 var collapse:float=float(e.get("collapse",0))
 transform(c,e.pos+Vector2(0,-8-absf(walk)*2-strike*4),collapse*.8,Vector2(face*size,size*(1-collapse*.65)))
 var flash:bool=float(e.get("hurt",0))>0
 if flash:tint=tint.lightened(.5)
 # Colours are drawn with alpha by the world canvas on death, not new textures.
 if kind=="nibbler":
  var tail=PackedVector2Array([Vector2(-5,6),Vector2(-28,2),Vector2(-42,-10+sin(gait)*5),Vector2(-47,-23)])
  c.draw_polyline(tail,INK,6,true);c.draw_polyline(tail,Color("#aa7978"),3,true)
  for side in [-1,1]:
   for n in 2:
    var x=side*(16+n*2);var step=sin(gait+n*PI+side)*5 if moving else 0.0
    limb(c,Vector2(x*.5,n*17-10),Vector2(x,n*17-4),Vector2(x+side*5,n*17+step+2),tint.darkened(.25),5)
  oval(c,Vector2(0,-4),Vector2(22,27),tint);oval(c,Vector2(-6,-13),Vector2(12,16),tint.lightened(.20),false)
  for side in [-1,1]:
   oval(c,Vector2(side*14,-9),Vector2(8,10),tint.lightened(.05));oval(c,Vector2(side*14,-9),Vector2(4,5),Color("#b77f85"),false)
  oval(c,Vector2(0,15+strike*5),Vector2(17,15),tint.lightened(.15));eye(c,Vector2(-9,10),Color("#ffdb85"));eye(c,Vector2(9,10),Color("#ffdb85"));oval(c,Vector2(0,23),Vector2(5,3),INK,false)
  c.draw_line(Vector2(-6,25),Vector2(-2,28),Color("#f2e6c3"),2,true);c.draw_line(Vector2(6,25),Vector2(2,28),Color("#f2e6c3"),2,true)
 elif kind=="glimmerwing":
  var flap=sin(clock*11+e.uid)*9;var fold=wind*12
  for side in [-1,1]:
   poly(c,[Vector2(side*7,-13),Vector2(side*(40-fold),-30+flap),Vector2(side*(47-fold),9+flap*.5),Vector2(side*30,1),Vector2(side*19,14),Vector2(side*7,7)],tint.darkened(.3))
   poly(c,[Vector2(side*9,-10),Vector2(side*(38-fold),-25+flap),Vector2(side*27,-3),Vector2(side*17,8)],tint,0)
   c.draw_line(Vector2(side*9,-9),Vector2(side*(38-fold),-25+flap),tint.lightened(.45),2,true)
  oval(c,Vector2(0,-1),Vector2(11,21),Color("#4b536c"));poly(c,[Vector2(-10,-13),Vector2(-13,-29),Vector2(-2,-18),Vector2(5,-18),Vector2(13,-29),Vector2(10,-9)],tint)
  eye(c,Vector2(-5,-7),Color("#e4f8ff"));eye(c,Vector2(5,-7),Color("#e4f8ff"));gem(c,Vector2(0,8),7,Color("#a5e8f0"))
 elif kind=="ironback":
  for side in [-1,1]:
   for n in 3:
    var foot=sin(gait+n*PI*.75+side)*6 if moving else 0.0
    limb(c,Vector2(side*15,n*15-21),Vector2(side*30,n*15-25+foot),Vector2(side*37,n*17-15+foot),tint.darkened(.35),4)
  oval(c,Vector2(0,-5),Vector2(26,32),tint.darkened(.3));oval(c,Vector2(-3,-9),Vector2(22,28),tint);oval(c,Vector2(-9,-17),Vector2(9,15),tint.lightened(.35),false)
  c.draw_line(Vector2(0,-34),Vector2(0,19),tint.darkened(.45),3,true)
  for n in 3:c.draw_line(Vector2(-20,n*12-21),Vector2(-2,n*12-17),tint.lightened(.18),2,true)
  oval(c,Vector2(0,23),Vector2(16,12),Color("#47434c"))
  for side in [-1,1]:
   eye(c,Vector2(side*8,22),Color("#ffd983"));limb(c,Vector2(side*13,21),Vector2(side*26,28-wind*24),Vector2(side*17,39-wind*23+strike*10),Color("#e5d5b1"),6)
 elif kind=="sneak":
  for side in [-1,1]:
   var step=sin(gait+side*PI*.5)*9 if moving else 0.0
   limb(c,Vector2(side*7,3),Vector2(side*13,15-step*.4),Vector2(side*12,28+step),Color("#4e6173"),7)
  # A curled lizard tail and triangular cloak make the thief identifiable.
  c.draw_polyline(PackedVector2Array([Vector2(-3,5),Vector2(-24,6),Vector2(-30,-8),Vector2(-20,-15)]),Color("#8aa092"),6,true)
  poly(c,[Vector2(-16,-22),Vector2(12,-24),Vector2(23,14),Vector2(-22,18)],Color("#4c5b70"))
  poly(c,[Vector2(-15,-18),Vector2(0,-28),Vector2(16,-18),Vector2(10,-1),Vector2(-13,1)],tint)
  oval(c,Vector2(0,-12),Vector2(12,12),Color("#6a8b82"));eye(c,Vector2(-6,-12),Color("#f8d778"));eye(c,Vector2(6,-12),Color("#f8d778"))
  for side in [-1,1]:limb(c,Vector2(side*12,-5),Vector2(side*24,3),Vector2(side*25,16-strike*12),tint.darkened(.1),5)
  c.draw_line(Vector2(-11,-26),Vector2(-22,-38),Color("#b8c8d0"),3,true)
 elif kind=="mender":
  for side in [-1,1]:
   var step=walk*side*5
   limb(c,Vector2(side*5,3),Vector2(side*9,16),Vector2(side*15,25+step),Color("#c6b896"),6)
   limb(c,Vector2(side*8,-1),Vector2(side*24,7-wind*15),Vector2(side*27,1-wind*20),tint,4)
  oval(c,Vector2(0,-1),Vector2(11,25),Color("#d1c29d"));eye(c,Vector2(-5,3),Color("#424b41"));eye(c,Vector2(5,3),Color("#424b41"))
  poly(c,[Vector2(-34,-15),Vector2(-27,-34),Vector2(-13,-44),Vector2(10,-43),Vector2(29,-30),Vector2(35,-14),Vector2(18,-7),Vector2(-15,-7)],tint)
  poly(c,[Vector2(-29,-19),Vector2(-21,-34),Vector2(-10,-40),Vector2(8,-39),Vector2(18,-26),Vector2(9,-20)],tint.lightened(.3),0)
  for spot in [Vector2(-20,-25),Vector2(6,-33),Vector2(22,-19)]:oval(c,spot,Vector2(4,3),Color("#e6d8b1"),false)
  c.draw_line(Vector2(-28,-13),Vector2(28,-13),tint.darkened(.35),3,true)
 elif kind=="larva":
  for n in range(5,-1,-1):
   var at=Vector2(sin(gait+n*.6)*5 if moving else sin(clock+n)*1.5,n*9-35)
   oval(c,at,Vector2(15+n*.7,10),tint.darkened(n*.035))
   for side in [-1,1]:c.draw_line(at+Vector2(side*10,3),at+Vector2(side*(23+sin(gait+n)*3),9),Color("#685c7d"),3,true)
   if n%2==0:gem(c,at+Vector2(-3,-6),8,tint.lightened(.3))
  oval(c,Vector2(0,14),Vector2(20,14),tint.lightened(.12));eye(c,Vector2(-8,14),Color("#e9e5ff"));eye(c,Vector2(8,14),Color("#e9e5ff"));c.draw_arc(Vector2(0,21),6,0,PI,10,INK,2,true)
 elif kind=="caller":
  for side in [-1,1]:
   limb(c,Vector2(side*7,0),Vector2(side*14,15),Vector2(side*16,28+walk*side*5),tint.darkened(.3),6)
   limb(c,Vector2(side*13,-12),Vector2(side*26,-1-wind*15),Vector2(side*25,15-wind*26),tint,6)
  poly(c,[Vector2(-20,21),Vector2(-15,-18),Vector2(1,-30),Vector2(19,-16),Vector2(25,21),Vector2(4,13)],Color("#3e6b70"))
  oval(c,Vector2(0,-14),Vector2(18,20),Color("#d5c7ac"));oval(c,Vector2(-8,-15),Vector2(5,8),INK,false);oval(c,Vector2(8,-15),Vector2(5,8),INK,false)
  eye(c,Vector2(-8,-14),Color("#91eee0"));eye(c,Vector2(8,-14),Color("#91eee0"))
  for side in [-1,1]:limb(c,Vector2(side*11,-25),Vector2(side*25,-38),Vector2(side*27,-53),Color("#b5c1b2"),5)
  c.draw_arc(Vector2(0,7),9,PI*.15,PI*.85,10,Color("#d6e4bd"),3,true)
 elif kind in ["brute","foreman"]:
  var foreman=kind=="foreman";var hot=bool(e.get("enraged",false));var stone=tint if not hot else tint.lerp(Color("#eb9055"),.55)
  for side in [-1,1]:
   var step=walk*side*8
   limb(c,Vector2(side*12,3),Vector2(side*20,19-step*.4),Vector2(side*24,31+step),stone.darkened(.3),13)
   oval(c,Vector2(side*24,31+step),Vector2(14,8),stone.darkened(.18))
  poly(c,[Vector2(-25,12),Vector2(-31,-17),Vector2(-15,-38),Vector2(13,-39),Vector2(29,-19),Vector2(24,14)],stone)
  poly(c,[Vector2(-25,-17),Vector2(-12,-33),Vector2(8,-33),Vector2(0,-9)],stone.lightened(.24),0)
  for side in [-1,1]:
   var hand=Vector2(side*(35+strike*5),12-wind*35+strike*17)
   limb(c,Vector2(side*22,-20),Vector2(side*36,-7-wind*14),hand,stone.darkened(.12),14)
   oval(c,hand,Vector2(14,13),stone)
   for n in 3:c.draw_line(hand+Vector2((n-1)*6,2),hand+Vector2((n-1)*7,13),Color("#e1d3b1"),3,true)
  oval(c,Vector2(0,-26),Vector2(19,17),stone.darkened(.2))
  for side in [-1,1]:eye(c,Vector2(side*8,-25),Color("#ffd079") if hot else Color("#a4eee1"))
  if foreman:
   oval(c,Vector2(0,-16),Vector2(11,8),Color("#9a8371"));oval(c,Vector2(0,-14),Vector2(6,4),Color("#403945"),false)
   for side in [-1,1]:c.draw_line(Vector2(side*7,-13),Vector2(side*16,-9),Color("#ccbaa0"),1.5,true)
   oval(c,Vector2(0,-39),Vector2(21,10),Color("#6e7d83"));gem(c,Vector2(0,-42),9,Color("#a6d9da"))
   var grip=Vector2(33,8-wind*28);var end=grip+Vector2(14,-48).rotated(-strike*1.9)
   c.draw_line(grip,end,INK,7,true);c.draw_line(grip,end,Color("#b6a478"),4,true);c.draw_line(end+Vector2(-21,0),end+Vector2(15,2),Color("#b3c9cd"),7,true)
  else:
   for point in [Vector2(-15,-27),Vector2(17,-8),Vector2(0,5)]:gem(c,point,10,Color("#f6b66d") if hot else Color("#9aa9ba"))
 elif kind=="wickeater":
  for n in range(5,-1,-1):
   var at=Vector2(sin(clock*2+n*.6)*8,n*15-64)
   for side in [-1,1]:
    var step=sin(gait+n*.85+side)*7
    limb(c,at+Vector2(side*12,0),at+Vector2(side*27,-10+step),at+Vector2(side*36,7+step),Color("#a77a68"),4)
   oval(c,at,Vector2(22-n*.9,15),tint.darkened(n*.04));oval(c,at+Vector2(-5,-4),Vector2(13-n*.8,7),tint.lightened(.15),false)
   gem(c,at+Vector2(0,-4),6,Color("#eea75c"))
  oval(c,Vector2(0,17),Vector2(27,23),Color("#624754"));poly(c,[Vector2(-24,9),Vector2(-16,-2),Vector2(16,-2),Vector2(24,9),Vector2(15,22),Vector2(-15,22)],tint)
  for side in [-1,1]:
   eye(c,Vector2(side*11,10),Color("#ffe79d"));limb(c,Vector2(side*17,24),Vector2(side*31,36-wind*12),Vector2(side*13,42+strike*10),Color("#e0c498"),7)
  c.draw_line(Vector2(-4,25),Vector2(-7,33),Color("#f3d68d"),3,true);c.draw_line(Vector2(4,25),Vector2(7,33),Color("#f3d68d"),3,true)
 elif kind in ["crab","spider","scorpion","mantis"]:
  var legs=4 if kind=="spider" else 3
  for side in [-1,1]:
   for n in legs:
    var lift=sin(gait+n*1.8+side)*7 if moving else 0.0
    limb(c,Vector2(side*13,n*9-20),Vector2(side*(30+n*2),n*13-30+lift),Vector2(side*(43-n*2),n*17-20+lift),tint,4)
  oval(c,Vector2(0,-12),Vector2(23,24) if kind=="crab" else Vector2(16,25),tint)
  if kind=="spider":oval(c,Vector2(0,-30),Vector2(24,19),tint.darkened(.15))
  if kind=="scorpion":
   for n in 6:oval(c,Vector2(sin(n*.5)*25,-28-n*6+wind*7),Vector2(7,8),tint.darkened(n*.04))
   gem(c,Vector2(17,-66+wind*7),9,Color("#e6c582"))
  if kind=="mantis":poly(c,[Vector2(-12,-15),Vector2(0,-48),Vector2(13,-15),Vector2(5,17),Vector2(-5,17)],tint)
  for side in [-1,1]:
   var hand=Vector2(side*(31+strike*8),17-wind*27)
   limb(c,Vector2(side*9,-1),Vector2(side*30,-7),hand,tint,6)
   poly(c,[hand+Vector2(-9,-3),hand+Vector2(0,16),hand+Vector2(7,-6),hand],tint.lightened(.2))
   eye(c,Vector2(side*8,4),Color("#f7d9a1"))
 elif kind in ["slug","snail","leech","shark","salamander","hydra"]:
  for n in range(7,-1,-1):
   var at=Vector2(sin(gait+n*.65)*7*(1.0 if moving else .25),-n*7)
   oval(c,at,Vector2(18-n*.8,12),tint.darkened(n*.025))
   if kind=="salamander" and n in [1,5]:
    for side in [-1,1]:limb(c,at+Vector2(side*9,0),at+Vector2(side*25,7),at+Vector2(side*32,13+walk*side*4),tint,5)
  if kind=="snail":
   oval(c,Vector2(0,-26),Vector2(29,27),tint.darkened(.15))
   for n in range(1,18):
    var a=n*.45;var b=(n-1)*.45;c.draw_line(Vector2(cos(b),sin(b))*(n-1)*1.25+Vector2(0,-26),Vector2(cos(a),sin(a))*n*1.25+Vector2(0,-26),tint.lightened(.35),3,true)
  if kind=="shark":
   poly(c,[Vector2(-10,-17),Vector2(-26,-37),Vector2(-20,-5)],tint.darkened(.3));poly(c,[Vector2(10,-17),Vector2(26,-37),Vector2(20,-5)],tint.darkened(.3));poly(c,[Vector2(-6,-30),Vector2(0,-61),Vector2(9,-24)],tint.lightened(.2))
  var heads=3 if kind=="hydra" else 1
  for n in heads:
   var at=Vector2((n-1)*20 if heads>1 else 0,6+sin(clock*2+n)*2)
   if heads>1:limb(c,Vector2.ZERO,at-Vector2(0,14),at,tint,9)
   oval(c,at,Vector2(13,13),tint.lightened(.12))
   for side in [-1,1]:eye(c,at+Vector2(side*6,0),Color("#ffe6a0"))
   c.draw_arc(at+Vector2(0,6),7,0,PI,10,INK,3,true)
 elif kind in ["jelly","wisp","urchin","bell","totem","angel"]:
  var sway=sin(clock*3)*3
  if kind=="urchin":
   for n in 12:gem(c,Vector2.from_angle(n*TAU/12)*25,13,tint.lightened(.1))
  if kind in ["jelly","wisp"]:
   for n in 6:limb(c,Vector2((n-2.5)*6,-3),Vector2((n-2.5)*8+sin(clock*3+n)*5,13),Vector2((n-2.5)*9+sin(clock*3+n)*7,30),tint.lightened(.2),3)
  if kind=="angel":
   for side in [-1,1]:
    for n in 4:poly(c,[Vector2(side*5,-12),Vector2(side*(36+n*3),-39+n*17+sway),Vector2(side*(28+n*2),-13+n*16),Vector2(side*5,9)],tint.darkened(n*.06))
  if kind=="totem":
   for n in 3:poly(c,[Vector2(-19,-n*20),Vector2(-15,-19-n*20),Vector2(16,-20-n*20),Vector2(21,-n*20)],tint.darkened(n*.04))
  elif kind=="bell":
   poly(c,[Vector2(-28,16),Vector2(-17,-11),Vector2(-16,-34),Vector2(14,-35),Vector2(19,-10),Vector2(29,16)],tint);oval(c,Vector2(0,17),Vector2(28,7),tint.darkened(.4));oval(c,Vector2(sway,21),Vector2(7,8),Color("#d7bf86"))
  else:oval(c,Vector2(0,-13+sway),Vector2(25,27),tint)
  for side in [-1,1]:eye(c,Vector2(side*8,-12+sway),Color("#defaff"))
  gem(c,Vector2(0,-31+sway),8,tint.lightened(.5))
 elif kind in ["mole","mimic","rootling","tortoise","owl","drake"]:
  for side in [-1,1]:
   limb(c,Vector2(side*10,0),Vector2(side*19,14),Vector2(side*25,22+walk*side*6),tint.darkened(.2),8)
   if kind in ["owl","drake"]:
    poly(c,[Vector2(side*8,-25),Vector2(side*45,-40+sin(clock*5)*8),Vector2(side*35,9),Vector2(side*14,4)],tint.darkened(.15))
   else:limb(c,Vector2(side*12,-14),Vector2(side*29,-4-wind*12),Vector2(side*(34+strike*8),16-wind*22),tint,8)
  if kind=="mimic":
   poly(c,[Vector2(-25,16),Vector2(-25,-15),Vector2(23,-15),Vector2(26,16)],tint);poly(c,[Vector2(-27,-17),Vector2(-23,-37-wind*10),Vector2(22,-37-wind*10),Vector2(27,-17)],tint.lightened(.2))
   for x in range(-18,22,9):poly(c,[Vector2(x,-17),Vector2(x+4,-8+strike*5),Vector2(x+7,-17)],Color("#eee0bc"))
  elif kind=="rootling":
   poly(c,[Vector2(-18,14),Vector2(-12,-39),Vector2(0,-30),Vector2(14,-48),Vector2(23,15)],tint)
   for side in [-1,1]:limb(c,Vector2(side*8,-24),Vector2(side*26,-37),Vector2(side*32,-50),tint,4)
  else:
   oval(c,Vector2(0,-15),Vector2(27,29),tint)
   if kind=="tortoise":
    oval(c,Vector2(0,-22),Vector2(25,22),tint.darkened(.25))
    for at in [Vector2(0,-23),Vector2(-13,-16),Vector2(13,-16)]:gem(c,at,10,tint.lightened(.15))
   if kind=="owl":
    for side in [-1,1]:oval(c,Vector2(side*12,-22),Vector2(11,13),Color("#d6cbb3"))
   if kind=="drake":
    for side in [-1,1]:poly(c,[Vector2(side*12,-31),Vector2(side*24,-52),Vector2(side*21,-24)],Color("#d0b793"))
  for side in [-1,1]:eye(c,Vector2(side*9,-12),Color("#e9dd9d"))
 # Guardian equipment changes their outline and articulation, rather than recolouring them.
 var ornament=int(e.get("ornament",0))
 if ornament>0:
  for side in [-1,1]:
   var at=Vector2(side*25,-20)
   if ornament%4==0:
    for n in 3:gem(c,at+Vector2(side*n*5,-n*12),10+n*2,tint.lightened(.3))
   elif ornament%4==1:
    var end=at+Vector2(side*(11+strike*15),-30-wind*12)
    limb(c,at,at+Vector2(side*9,-10),end,Color("#c9b383"),4);c.draw_line(end-Vector2(12,0),end+Vector2(13,0),tint.lightened(.4),6,true)
   elif ornament%4==2:
    poly(c,[at,at+Vector2(side*23,-19),at+Vector2(side*35,17),at+Vector2(side*7,30)],tint.darkened(.18))
    gem(c,at+Vector2(side*16,8),8,tint.lightened(.4))
   else:
    for n in 3:limb(c,at,at+Vector2(side*(20+n*5),-20+n*15),at+Vector2(side*(29+n*5),-28+n*21+walk*4),tint.lightened(.1),3)
  gem(c,Vector2(0,-48-(ornament%3)*4),9+(ornament%3)*2,Color("#e9d9a3"))

 transform(c,Vector2.ZERO)

static func cached_enemy(c:CanvasItem,e:Dictionary,clock:float,alpha:float)->bool:
 var kind:=str(e.kind)
 if not atlases.has(kind):
  var path="res://assets/descent203/"+kind+".png"
  var img=Image.new()
  if not FileAccess.file_exists(path) or img.load_png_from_buffer(FileAccess.get_file_as_bytes(path))!=OK:return false
  atlases[kind]=ImageTexture.create_from_image(img)
 var cell=Vector2(e.get("cell",[128,160])[0],e.get("cell",[128,160])[1])
 var row=0;var frame=posmod(int(clock*5),8)
 if float(e.get("collapse",0))>0:row=3;frame=mini(7,int(float(e.collapse)*8))
 elif not str(e.get("action","")).is_empty():row=2;frame=mini(3,int((1-float(e.get("left",0))/maxf(.01,float(e.get("total",1))))*4))
 elif float(e.get("strike",0))>0:row=2;frame=clampi(4+int((1-float(e.strike)/.3)*4),4,7)
 elif float(e.get("moving",0))>.05:row=1;frame=posmod(int(float(e.get("gait",0))/TAU*8),8)
 var facing=-1.0 if float(e.get("facing",1))<0 else 1.0
 transform(c,e.pos,0,Vector2(facing,1)*float(e.get("art_scale",1)))
 var tint=Color(1,1,1,alpha)
 if float(e.get("hurt",0))>0:tint=Color(1,.65,.57,alpha)
 if bool(e.get("enraged",false)):tint=Color(1,.76,.59,alpha)
 c.draw_texture_rect_region(atlases[kind],Rect2(-Vector2(cell.x*.5,cell.y*.70),cell),Rect2(Vector2(frame,row)*cell,cell),tint)
 transform(c,Vector2.ZERO)
 return true

static func transform(c:CanvasItem,p:Vector2,angle:float=0,scale_value:Vector2=Vector2.ONE)->void:
 if c.has_method("world_transform"):c.world_transform(p,angle,scale_value)
 else:c.draw_set_transform(p,angle,scale_value)

static func spell(c:Node2D,shot:Dictionary,p:Vector2,clock:float)->bool:
 var kind=str(shot.get("stats",{}).get("descent_visual",""))
 if kind.is_empty():return false
 var tint=Color(str(shot.get("color","#c5dfe9")));var a=Vector2(float(shot.aim[0]),float(shot.aim[1]));var b=a.orthogonal()
 c.draw_line(p-a*22,p,Color(tint,.25),5,true)
 if kind in ["mender","slug","rootling"]:
  for n in 3:
   var at=p+Vector2.from_angle(n*TAU/3+clock*3)*5;c.draw_circle(at,4,tint);c.draw_circle(at-Vector2(1,1),1.4,tint.lightened(.6))
 elif kind in ["larva","bell","jelly"]:
  c.draw_arc(p,7,0,TAU,16,tint,2,true);c.draw_arc(p,11+sin(clock*8)*2,clock,clock+PI,16,Color(tint,.5),1.5,true);c.draw_circle(p,3,tint.lightened(.5))
 elif kind in ["wisp","tortoise","drake","salamander"]:
  c.draw_colored_polygon(PackedVector2Array([p+a*9,p+b*7,p-a*(16+sin(clock*15)*5),p-b*7]),tint);c.draw_circle(p,4,Color("#ffe2ac"))
 elif kind in ["owl","angel"]:
  c.draw_line(p-a*12,p+a*9,tint.lightened(.5),2,true)
  for n in 4:
   var at=p-a*n*4;c.draw_line(at,at-a*6+b*(8-n),tint,2,true);c.draw_line(at,at-a*6-b*(8-n),tint.darkened(.2),2,true)
 elif kind in ["spider","caller"]:
  for n in 5:
   var dir=Vector2.from_angle(n*TAU/5+clock*4);c.draw_line(p,p+dir*9,tint,2,true)
  c.draw_circle(p,3,tint.lightened(.4))
 elif kind in ["scorpion","hydra","leech"]:
  c.draw_colored_polygon(PackedVector2Array([p+a*14,p-a*7+b*5,p-a*3,p-a*7-b*5]),tint.lightened(.25))
 else:
  c.draw_colored_polygon(PackedVector2Array([p+a*12,p+b*6,p-a*9,p-b*6]),tint);c.draw_line(p-a*5,p+a*8,tint.lightened(.55),2,true)
 return true

static func companion_texture(kind:String,pose:String)->Texture2D:
 var spec=preload("res://scripts/descent203_book.gd").profile(kind)
 if spec.is_empty():return null
 if not atlases.has(kind):
  var img=Image.new();var path="res://assets/descent203/"+kind+".png"
  if not FileAccess.file_exists(path) or img.load_png_from_buffer(FileAccess.get_file_as_bytes(path))!=OK:return null
  atlases[kind]=ImageTexture.create_from_image(img)
 var cell=Vector2(spec.cell[0],spec.cell[1]);var row=1 if pose.begins_with("walk") else 2 if pose=="attack" else 0;var frame=4 if pose=="walk2" else 6 if pose=="attack" else 0
 var texture=AtlasTexture.new();texture.atlas=atlases[kind];texture.region=Rect2(Vector2(frame,row)*cell+Vector2(cell.x*.5-52,cell.y*.7-65),Vector2(104,112));return texture

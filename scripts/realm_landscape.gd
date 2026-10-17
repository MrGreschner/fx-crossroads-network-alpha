extends Control
## Small, static, theme-specific illustrations; no viewport, particle or map simulation.
var game:Node
var realm="grove"
const THEMES={
 "grove":["forest","#244b43","#3c705b","#87b97b"],"quarry":["quarry","#403c4a","#795a56","#ffbb72"],
 "honeyglass":["garden","#41645c","#93ac69","#f0ca71"],"elementary":["school","#9fbac5","#8f9d77","#e3bb6d"],
 "sunfield":["sunflower","#8cb8ba","#a1ae5c","#f7da6e"],"ice":["rink","#354c6d","#82b8cf","#d1edf5"],
 "folded_coast":["coast","#3b637c","#578c9b","#d8d9b4"],"moonburrow":["burrow","#262b48","#486563","#b9c7b6"],
 "moonveil":["masquerade","#302c51","#666185","#d7bedb"],"petalbrook":["canopy","#456d6c","#75a391","#efb5cf"],
 "middle_school":["school","#536c87","#7b8997","#b6c9df"],"space":["orbital","#111c38","#2f446c","#8fd6e7"],
 "zombie":["quarantine","#263c38","#5b6c54","#bbcf70"],"lantern_marsh":["marsh","#223f45","#4c7563","#edcf82"],
 "silverfall":["waterfall","#547d8d","#69a1aa","#cbf0e8"],"confluence":["foundry","#273d52","#526875","#efb475"],
 "brasslock":["borough","#445465","#917e61","#daba72"],"clockwork_orchard":["orchard","#53615c","#82946a","#d2b069"],
 "high_school":["school","#425263","#717d89","#c8ac81"],"neon_crucible":["neon","#201d39","#493c6a","#72ebda"],
 "astral_rift":["astral","#181b3e","#4f4276","#bea7ef"],"chimevault":["vault","#273f59","#5b7f91","#d2e8dc"],
 "ebonwake":["ship","#1b344c","#365975","#acced9"],"shattered_oath":["ruins","#292a45","#5e5673","#c1a6d2"],
 "wayfarer":["trail","#355d57","#6c9677","#d4be86"]}
func _ready()->void:mouse_filter=Control.MOUSE_FILTER_IGNORE;clip_contents=true
static func theme(id:String)->Array:return THEMES.get(id,THEMES.grove)
func polygon(points:Array,color:Color)->void:draw_colored_polygon(PackedVector2Array(points),color)
func tree(at:Vector2,colour:Color,round_top:bool=false)->void:
 draw_line(at,at-Vector2(0,26),Color("#344c48"),4,true)
 if round_top:
  for n in 3:draw_circle(at+Vector2((n-1)*9,-29-abs(n-1)*3),13,colour)
 else:polygon([at+Vector2(-14,-10),at-Vector2(0,49),at+Vector2(14,-10)],colour)
func gear(at:Vector2,colour:Color,radius:float=16)->void:
 draw_arc(at,radius,0,TAU,22,colour,5,true);draw_circle(at,4,colour)
 for n in 8:
  var d=Vector2.from_angle(n*TAU/8);draw_line(at+d*(radius-1),at+d*(radius+6),colour,5,true)
func _draw()->void:
 var cfg=theme(realm);var style=str(cfg[0]);var sky=Color(cfg[1]);var land=Color(cfg[2]);var accent=Color(cfg[3])
 var w=size.x;var h=size.y
 draw_rect(Rect2(Vector2.ZERO,size),sky)
 if style in ["orbital","astral","neon","ship","masquerade","burrow","ruins"]:
  for n in 19:draw_circle(Vector2(fposmod(n*71.3+realm.hash()%99,maxf(1,w)),9+posmod(n*29,52)),1 if n%3 else 1.7,Color(accent,.6))
  draw_circle(Vector2(w*.82,25),15,accent.lightened(.15))
 else:draw_circle(Vector2(w*.82,25),18,accent)
 polygon([Vector2(0,h),Vector2(0,h*.68),Vector2(w*.19,h*.31),Vector2(w*.40,h*.69),Vector2(w*.67,h*.32),Vector2(w,h*.71),Vector2(w,h)],land.darkened(.25))
 polygon([Vector2(0,h*.84),Vector2(w*.3,h*.62),Vector2(w*.6,h*.81),Vector2(w,h*.64),Vector2(w,h),Vector2(0,h)],land)
 match style:
  "forest","trail":
   for n in 9:tree(Vector2(21+n*w/9,h*.88+sin(n*2)*9),accent.darkened(.25 if n%2 else .1),n%3==0)
   polygon([Vector2(w*.19,h),Vector2(w*.29,h*.68),Vector2(w*.37,h*.60),Vector2(w*.39,h*.66),Vector2(w*.34,h*.72),Vector2(w*.29,h)],Color("#c6ac7b"))
   if style=="trail":draw_line(Vector2(w*.55,h*.75),Vector2(w*.64,h*.75),accent,4,true);draw_line(Vector2(w*.59,h*.75),Vector2(w*.59,h*.48),accent,3,true)
  "quarry":
   for n in 7:
    var p=Vector2(n*w/6,h*.85);polygon([p+Vector2(-33,20),p+Vector2(-18,-36-n%3*8),p+Vector2(7,-47),p+Vector2(35,20)],Color("#544a50"))
   draw_polyline(PackedVector2Array([Vector2(w*.35,h),Vector2(w*.42,h*.85),Vector2(w*.37,h*.73),Vector2(w*.55,h*.68)]),Color("#ed9864"),9,true)
  "garden","canopy","sunflower":
   for n in 15:
    var p=Vector2(15+n*w/15,h*.84+sin(n*1.7)*8);draw_line(p,p-Vector2(0,24),Color("#496e50"),2,true)
    for k in 5:draw_circle(p-Vector2(0,26)+Vector2.from_angle(k*TAU/5)*5,4,accent if n%3 else accent.lightened(.18))
    draw_circle(p-Vector2(0,26),3,Color("#7e6744"))
   if style=="canopy":
    draw_line(Vector2(w*.23,0),Vector2(w*.19,h*.85),Color("#5b7864"),12,true);draw_line(Vector2(w*.75,0),Vector2(w*.81,h*.85),Color("#5b7864"),12,true)
    for n in 8:draw_circle(Vector2(n*w/7,7),30,Color("#6f9f85"))
   if style=="garden":
    for n in 4:polygon([Vector2(w*.2+n*60,h*.7),Vector2(w*.2+n*60+8,h*.4),Vector2(w*.2+n*60+20,h*.7)],Color("#b8d5b3"))
  "rink":
   draw_style_box(preload("res://scripts/studio_ui.gd").box("#b5dbe6","#e2f0e8",22,2),Rect2(w*.13,h*.4,w*.74,h*.52))
   draw_arc(Vector2(w*.5,h*.67),19,0,TAU,22,Color("#9c7d8d"),2,true);draw_line(Vector2(w*.5,h*.42),Vector2(w*.5,h*.91),Color("#9c7d8d"),2,true)
   for x in [.2,.8]:draw_rect(Rect2(w*x-12,h*.57,24,24),Color("#4b7c98"),false,2)
  "coast","waterfall","marsh","ship":
   draw_rect(Rect2(0,h*.64,w,h*.36),land.lightened(.1))
   for n in 14:draw_line(Vector2(n*w/14,h*.76+sin(n)*10),Vector2(n*w/14+23,h*.76+sin(n)*10),Color(accent,.35),1.5,true)
   if style=="waterfall":
    draw_rect(Rect2(w*.3,h*.25,w*.12,h*.65),accent.darkened(.18));draw_rect(Rect2(w*.33,h*.25,w*.06,h*.65),accent)
    draw_arc(Vector2(w*.36,h*.89),28,0,PI,20,accent,3,true)
   elif style=="coast":
    for n in 3:draw_arc(Vector2(w*(.18+n*.28),h*.77),29,PI,TAU,24,accent,9,true)
   elif style=="marsh":
    for n in 7:
     var p=Vector2(23+n*w/7,h*.85);draw_line(p,p-Vector2(0,47),Color("#3a5d56"),5,true);draw_circle(p-Vector2(0,45),5,accent)
   else:
    var p=Vector2(w*.48,h*.68);polygon([p+Vector2(-66,0),p+Vector2(60,0),p+Vector2(39,27),p+Vector2(-45,27)],Color("#817b6d"));draw_line(p,p-Vector2(0,57),accent,3,true);polygon([p-Vector2(0,57),p+Vector2(0,-10),p+Vector2(43,-12)],Color("#96acae"))
  "school","borough","quarantine","foundry","neon":
   var floors=1 if realm=="elementary" else 3 if realm=="high_school" else 2
   for n in 5:
    var p=Vector2(w*.1+n*w*.17,h*.85);var height=34+posmod(n*13+realm.hash(),20)+floors*5
    draw_rect(Rect2(p-Vector2(0,height),Vector2(w*.13,height)),land.lightened(.13))
    for k in 3:draw_rect(Rect2(p+Vector2(6+k*w*.032,-height+9),Vector2(w*.018,8)),accent)
   if style=="quarantine":
    draw_line(Vector2(0,h*.91),Vector2(w,h*.91),accent,3,true)
    for n in 18:draw_line(Vector2(n*w/18,h*.87),Vector2(n*w/18,h*.97),accent,2,true)
   elif style=="foundry":
    for x in [.27,.65]:gear(Vector2(w*x,h*.63),accent,19)
    draw_line(Vector2(w*.12,h*.91),Vector2(w*.88,h*.91),accent,5,true)
   elif style=="neon":
    draw_polyline(PackedVector2Array([Vector2(0,h*.96),Vector2(w*.28,h*.96),Vector2(w*.35,h*.79),Vector2(w*.66,h*.79),Vector2(w*.75,h*.96),Vector2(w,h*.96)]),accent,3,true)
   elif style=="borough":gear(Vector2(w*.5,h*.36),accent,16)
  "burrow":
   for n in 4:
    var p=Vector2(w*(.15+n*.23),h*.91);draw_circle(p-Vector2(0,12),27,land.lightened(.1));draw_circle(p-Vector2(0,6),17,sky);draw_circle(p+Vector2(3,-8),4,accent)
  "masquerade","vault","ruins":
   var tint=land.lightened(.3)
   for n in 5:
    var x=w*(.12+n*.19);draw_rect(Rect2(x-8,h*.3,16,h*.62),tint);draw_arc(Vector2(x+w*.095,h*.41),w*.095,PI,TAU,20,tint,7,true)
   if style=="masquerade":
    for x in [.12,.88]:draw_rect(Rect2(w*x-12,0,24,h*.65),Color("#9b647d"))
    draw_line(Vector2(w*.18,12),Vector2(w*.82,12),accent,2,true)
   elif style=="ruins":polygon([Vector2(w*.7,h*.3),Vector2(w*.8,h*.3),Vector2(w*.75,h*.62),Vector2(w*.67,h*.7)],sky)
   else:draw_circle(Vector2(w*.5,h*.47),16,accent);draw_arc(Vector2(w*.5,h*.47),24,0,TAU,24,accent,2,true)
  "orbital","astral":
   for n in 5:
    var p=Vector2(w*(.08+n*.21),h*.67+sin(n*2)*13);polygon([p+Vector2(-26,-4),p+Vector2(30,-4),p+Vector2(13,18),p+Vector2(-17,13)],land.lightened(.15))
   if style=="orbital":
    draw_arc(Vector2(w*.53,h*.4),30,0,TAU,28,accent,5,true);draw_line(Vector2(w*.53-43,h*.4),Vector2(w*.53+43,h*.4),accent,3,true)
   else:
    draw_polyline(PackedVector2Array([Vector2(w*.5,8),Vector2(w*.45,h*.3),Vector2(w*.56,h*.5),Vector2(w*.48,h*.79),Vector2(w*.51,h)]),accent,3,true)
  "orchard":
   for n in 7:
    var p=Vector2(25+n*w/7,h*.88);tree(p,land.lightened(.18),true);gear(p-Vector2(0,29),accent,10)
 # Quiet inset border finishes each illustration without adding another navigation control.
 draw_rect(Rect2(Vector2(1,1),size-Vector2(2,2)),Color(accent,.3),false,1)

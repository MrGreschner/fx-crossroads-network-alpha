extends RefCounted
## Stadium growth uses genuine recorded PvP match wins; practice bots do not award them.
const CENTER=Vector2(260,1090)
var font:Font=preload("res://assets/fonts/CrossroadsUI.ttf")
func wins(g:Node)->int:
 var record=g.legacy.card.state().arena
 return int(record.standard.wins)+int(record.random.wins)
func draw_on(g:Node2D,camera:Vector2)->void:
 if not Rect2(camera,g.VIEW).grow(230).has_point(CENTER):return
 var grand=wins(g)>=10;var p=CENTER-camera;var width=175.0 if grand else 145.0
 # Broad marble forecourt, tiered seats and open sand ring.
 g.draw_rect(Rect2(p+Vector2(-width-28,66),Vector2(width*2+56,54)),Color("#b8aa87"))
 for n in 3:g.draw_line(p+Vector2(-width-22,80+n*12),p+Vector2(width+22,80+n*12),Color("#dfcda7"),3)
 var outer=PackedVector2Array();var inner=PackedVector2Array()
 for n in 65:
  var a=n*TAU/64;outer.append(p+Vector2(cos(a)*width,sin(a)*74));inner.append(p+Vector2(cos(a)*(width-32),sin(a)*48))
 g.draw_colored_polygon(outer,Color("#d0bea0"));g.draw_polyline(outer,Color("#526170"),5,true)
 for tier in 3:
  var seat=PackedVector2Array()
  for n in 33:
   var a=PI+n*PI/32;seat.append(p+Vector2(cos(a)*(width-13-tier*11),sin(a)*(66-tier*11)))
  g.draw_polyline(seat,Color("#8c8276"),3,true)
 g.draw_colored_polygon(inner,Color("#d4af76"));g.draw_polyline(inner,Color("#edd8ad"),2,true)
 # Barrel vaults on a curved front wall.
 for n in 13:
  var x=-width+10+n*(width*2-20)/12;var depth=sqrt(maxf(0,1-pow(x/width,2)))*49
  var q=p+Vector2(x,27+depth)
  g.draw_rect(Rect2(q-Vector2(11,21),Vector2(22,45)),Color("#bcaa8b"));g.draw_arc(q-Vector2(0,14),8,PI,TAU,12,Color("#efe0bd"),3,true)
  g.draw_rect(Rect2(q-Vector2(7,14),Vector2(14,27)),Color("#4a5259"));g.draw_line(q+Vector2(-11,24),q+Vector2(11,24),Color("#e5d1a7"),3)
 var door=p+Vector2(0,68);g.draw_rect(Rect2(door-Vector2(20,20),Vector2(40,40)),Color("#253e49"));g.draw_arc(door-Vector2(0,20),20,PI,TAU,20,Color("#eed5a4"),4,true)
 for side in [-1,1]:
  var mast=p+Vector2(side*(width+12),35);g.draw_line(mast,mast-Vector2(0,146 if grand else 114),Color("#5d635e"),5)
  var flag=mast-Vector2(0,140 if grand else 108);var wave=sin(Time.get_ticks_msec()*.002+side)*3
  g.draw_colored_polygon(PackedVector2Array([flag,flag+Vector2(35,5+wave),flag+Vector2(35,37+wave),flag+Vector2(0,47)]),Color("#d3ae61") if grand else Color("#628fa5"))
  g.draw_line(flag+Vector2(10,13),flag+Vector2(25,29),Color("#f1deaf"),3);g.draw_line(flag+Vector2(25,13),flag+Vector2(10,29),Color("#f1deaf"),3)
 if grand:
  for side in [-1,1]:
   var pillar=p+Vector2(side*(width+32),35);g.draw_rect(Rect2(pillar-Vector2(8,76),Vector2(16,112)),Color("#e4d3ac"));g.draw_rect(Rect2(pillar-Vector2(13,82),Vector2(26,9)),Color("#cfb575"));g.draw_circle(pillar-Vector2(0,94),12,Color("#e5c56f"))
  for n in 7:g.draw_circle(p+Vector2(-90+n*30,-50),2,Color("#e9c978"))
 var title="GRAND GLADIATOR ARENA" if grand else "GLADIATOR ARENA"
 g.draw_rect(Rect2(p+Vector2(-151,124),Vector2(302,28)),Color("#243c47"));g.draw_rect(Rect2(p+Vector2(-151,124),Vector2(302,28)),Color("#ccb682"),false,1)
 g.draw_string(font,p+Vector2(-146,144),title,HORIZONTAL_ALIGNMENT_CENTER,292,17,Color("#f2dca0"))
 g.draw_string(font,p+Vector2(-130,173),"10 PvP wins • Grand stadium" if grand else str(wins(g))+" / 10 PvP wins to upgrade",HORIZONTAL_ALIGNMENT_CENTER,260,14,Color("#d1dfd3"))

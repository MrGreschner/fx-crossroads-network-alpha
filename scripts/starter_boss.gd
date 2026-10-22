extends RefCounted
## Stationary, direction-locked melee tells shared by solo and co-op.
const WINDUP=0.95
const REACH=86.0
const HALF_ANGLE=1.05
static func managed(realm:String,enemy:Dictionary)->bool:
 return realm in ["grove","quarry"] and bool(enemy.get("boss",false)) and not bool(enemy.get("expansion_boss",false))
static func advance(enemy:Dictionary,target:Vector2,delta:float,can_attack:bool=true)->int:
 # 0: pursuit, 1: charge, 2: impact this frame.
 var remaining:float=float(enemy.get("melee_warning",0))
 if remaining>0:
  enemy.melee_warning=maxf(0,remaining-delta)
  if float(enemy.melee_warning)>0:return 1
  enemy.attack_timer=1.55
  enemy.strike_flash=.35
  enemy.strike_direction=Vector2(float(enemy.get("melee_x",0)),float(enemy.get("melee_y",1)))
  return 2
 if can_attack and float(enemy.get("attack_timer",0))<=0 and float(enemy.get("windup",0))<=0 and (enemy.pos as Vector2).distance_to(target)<78:
  var aim:Vector2=(target-(enemy.pos as Vector2)).normalized()
  if aim==Vector2.ZERO:aim=Vector2.DOWN
  enemy.melee_warning=WINDUP;enemy.melee_x=aim.x;enemy.melee_y=aim.y
  return 1
 return 0
static func hits(enemy:Dictionary,target:Vector2)->bool:
 var diff:Vector2=target-(enemy.pos as Vector2)
 var aim=Vector2(float(enemy.get("melee_x",0)),float(enemy.get("melee_y",1)))
 return diff.length()<=REACH and (diff.length()<1 or diff.normalized().dot(aim)>=cos(HALF_ANGLE))
static func draw_warning(c:Node2D,enemy:Dictionary,at:Vector2)->void:
 if str(c.get("mode"))=="descent":return
 var remaining:float=float(enemy.get("melee_warning",0))
 if remaining<=0:return
 var angle=Vector2(float(enemy.get("melee_x",0)),float(enemy.get("melee_y",1))).angle()
 var polygon=PackedVector2Array([at])
 for n in 25:polygon.append(at+Vector2.RIGHT.rotated(angle-HALF_ANGLE+2*HALF_ANGLE*n/24.0)*REACH)
 c.draw_colored_polygon(polygon,Color(1,.37,.13,.20+.15*(1-remaining/WINDUP)))
 c.draw_arc(at,REACH,angle-HALF_ANGLE,angle+HALF_ANGLE,24,Color("#ffd38a"),3,true)
 c.draw_arc(at,REACH*(1-remaining/WINDUP),angle-HALF_ANGLE,angle+HALF_ANGLE,24,Color("#ffae60"),2,true)
 c.draw_string(ThemeDB.fallback_font,at+Vector2(-35,-72),"DODGE!",HORIZONTAL_ALIGNMENT_LEFT,-1,17,Color("#ffe3ac"))

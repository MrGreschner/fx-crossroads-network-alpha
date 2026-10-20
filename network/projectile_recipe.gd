extends RefCounted
## Cosmetic launch recipes for immediate projectile families across the roster.
## Delayed casts/channels retain their authored timing; they are never fast-forwarded.
static func seeds(stats:Dictionary,aim:Vector2,origin:Vector2,combat:Node,owner:String)->Array:
 var style=str(stats.get("style",""));var s:Dictionary=stats.duplicate(true)
 var supported=["navigator_bolt","projectile","ranged","homing","apiary_needle","ricochet_projectile","spiral_shot","split_lance","cross_shot","rolling_snow","magnet_pin","corkscrew_key","latchline","echo_brand","facet_spear","lantern_comet","rune_hammer","tea_shot","threaded_needles","time_dart","v91_pistol","wick_fire","mirror_fan"]
 if style not in supported:return []
 var custom=style not in ["projectile","ranged"] or bool(s.get("released_hold",false))
 var count=clampi(int(s.get("count",1)),1,8)
 if style=="homing" and combat.passive(owner,"twin_orbs"):count=2
 if style=="cross_shot":count=4
 if style=="mirror_fan":count=3;s.spread=.23;s.mirror_shard=true
 if style=="tea_shot":count=2;s.tea_drop=true
 if style=="threaded_needles":count=2
 if style=="facet_spear":s.mirror_shard=true;s.speed=480
 if style=="lantern_comet":s.lantern_comet=true;s.speed=300;s.range=1200
 if style=="rune_hammer":s.rune_hammer=true
 var result=[]
 for n in count:
  var direction=aim.rotated((n-(count-1)*.5)*float(s.get("spread",0)))
  var p=origin+direction*26
  if style=="cross_shot":direction=aim.rotated(n*PI*.5);p=origin+direction*26
  if style=="tea_shot":direction=aim.rotated((n*2-1)*.13)
  if style=="threaded_needles":
   p=origin+aim*28+aim.orthogonal()*(n*2-1)*34
   if not combat.path_clear(origin,p):p=origin+aim*20
   direction=(origin+aim*190-p).normalized()
  var art={}
  if custom:art={"pos":[p.x,p.y],"aim":[direction.x,direction.y],"base_aim":[direction.x,direction.y],"origin":[p.x,p.y],"radius":float(s.get("projectile_radius",12)),"style":style if style in ["homing","spiral_shot","ricochet_projectile","split_lance","rolling_snow","magnet_pin","corkscrew_key","latchline","time_dart"] else "pellet","stats":s,"color":str(s.get("color","#edf7ff")),"distance":0.0,"speed":float(s.get("speed",480))}
  result.append({"p":p,"v":direction*float(s.get("speed",420)),"color":str(s.get("color","#ffd985")),"range":float(s.get("range",480)),"radius":float(s.get("projectile_radius",7)),"art":art,"index":n})
 return result

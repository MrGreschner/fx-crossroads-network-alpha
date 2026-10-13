extends RefCounted
const EFFECTS={"balanced":"Damage + healing + impact size","damage":"More damage","size":"Larger hit / area size","reach":"Longer reach / travel","speed":"Faster projectile","count":"Extra projectiles (max 5)","healing":"More healing","knockback":"Stronger knockback"}
static func apply(a:Dictionary,factor:float)->void:
 a.charged=factor
 match a.get("charge_effect","balanced"):
  "balanced":a.damage*=1+factor*.6;a.heal*=1+factor*.3;a.radius*=1+factor*.2
  "damage":a.damage*=1+factor*.6
  "size":a.radius*=1+factor*.4;a.charge_size=factor*.8;if a.get("category")=="melee":a.range*=1+factor*.4
  "reach":a.range*=1+factor*.6
  "speed":a.speed*=1+factor*.7
  "count":a.count=mini(5,int(a.count)+int(factor*2))
  "healing":a.heal*=1+factor*.7
  "knockback":a.knockback=factor*110
 if factor>=.95 and a.get("max_charge_status","none")!="none":a.status=a.max_charge_status

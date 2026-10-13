extends RefCounted
var arena:Node
var still=0.0
var clock=0.0
var casts=0
var last_position=Vector2.ZERO
func setup(a:Node)->void:arena=a;still=0;clock=0;casts=0;last_position=a.player
func key()->String:return str(arena.hero.get("passive","none"))
func tick(delta:float)->void:
 still=still+delta if arena.player.distance_to(last_position)<.1 else 0.0;last_position=arena.player;clock+=delta
 if key()=="radiance" and clock>=8:
  clock=0;var a=arena.Project.attack("heal_wave");a.heal=6;a.radius=float(arena.hero.get("passive_radius",100));arena.heal_at(arena.player,a);arena.flash(arena.player,a.radius,Color("#d4e7a3"))
 if key()=="packmend":
  for m in arena.minions:m.hp=minf(float(m.get("max_hp",40)),float(m.hp)+delta)
func damage_multiplier(a:Dictionary,target:Dictionary)->float:
 var k=key()
 if k=="executioner" and float(target.hp)<=float(target.get("max_hp",200))*.3:return 1.1
 if k=="steadyhand" and still>=.6:return 1.1
 if k=="momentum" and arena.moving and a.name==arena.hero.primary.name:return 1.1
 if k=="patient_power" and float(a.get("charged",0))>=.9:return 1.12
 return 1.0
func cooldown(kind:String,a:Dictionary)->float:return .9 if key()=="quickdraw" and kind=="primary" and float(a.charge)==0 else 1.0
func heal_multiplier()->float:return 1.2 if key()=="ebbflow" and arena.health<float(arena.hero.max_health)*.5 else 1.0
func reduction()->float:
 if key()=="guardian" and arena.health<float(arena.hero.max_health)*.35:return .15
 if key()=="bulwark" and still>=.8:return .12
 if key()=="packguard":return minf(.1,arena.minions.size()*.02)
 return 0.0
func defeated()->void:
 if key()=="bloodthread":arena.restore(3)
 if key()=="scavenger":
  for slot in arena.cooldowns:arena.cooldowns[slot]=maxf(0,arena.cooldowns[slot]-.5)
func cast()->void:
 casts+=1
 if key()=="nova_echo" and casts%5==0:
  var a=arena.Project.attack("spin");a.damage=6;a.radius=70;arena.pulse(arena.player,a);arena.flash(arena.player,70,Color("#d6bcf0"))
func received()->void:
 if not key() in ["chill_retaliation","toxic_thorns"]:return
 var i=arena.closest(arena.player,65)
 if i>=0:
  var a=arena.Project.attack();a.damage=0;a.status="slow" if key()=="chill_retaliation" else "poison";a.status_duration=2;a.status_damage=1;arena.hurt(i,a)

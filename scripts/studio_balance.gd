extends RefCounted
## Conservative build budgets, not a guarantee of competitive fairness.
const VERSION=1
const LIMITS={"primary":34.0,"secondary":20.0,"special":14.0}
static func attack_cost(a:Dictionary)->float:
 if a.get("style")=="custom":
  var effective=preload("res://scripts/studio_script.gd").compile(str(a.get("program","")))
  if not effective.error.is_empty():return INF
  a=a.duplicate(true)
  for key in effective.variables:
   if a.has(key):a[key]=effective.variables[key]
 var hit=maxf(0,float(a.get("damage",0)))+float(a.get("heal",0))*1.3
 hit+=float(a.get("status_damage",0))*float(a.get("status_duration",0)) if a.get("status","none") in ["burn","poison","bleed"] else 0
 if a.get("status","none")=="stun" or a.get("max_charge_status","none")=="stun":hit+=float(a.get("status_duration",1))*12
 var count=1.0;var style=str(a.get("style","melee"))
 if style in ["spread","burst","ring_shots","chain","summon"]:count=float(a.get("count",1))
 if style=="custom":
  var compiled=preload("res://scripts/studio_script.gd").compile(str(a.get("program","")))
  if not compiled.error.is_empty():return INF
  count=32 if str(a.get("program","")).begins_with("# @structured") else 1
  for charged in [false,true]:
   for targets in [false,true]:count=maxf(count,preload("res://scripts/studio_script.gd").actions(compiled.instructions,charged,targets,0,[],int(a.get("count",1))).size())
  # Programs may emit persistent fields, piercing hits or summons: reserve their worst-case budget.
  count*=maxf(1,float(a.get("count",1)))*maxf(1,float(a.get("duration",1)))
 if style in ["flame","poison_zone","burn_zone","siphon","summon","heal_zone"]:count*=maxf(1,float(a.get("duration",1)))
 if style in ["block","buff_zone","slow_aura","stun_zone","vortex"]:hit+=12*float(a.get("duration",1))
 if style=="summon" or style=="custom":hit+=float(a.get("minion_damage",7))*maxf(1,float(a.get("minion_health",30))/30)
 if a.get("status")=="slow":hit+=float(a.get("status_duration",1))*3
 hit+=float(a.get("knockback",0))/20
 var reach=1+maxf(0,float(a.get("range",180))-120)/900
 var area=1+maxf(0,float(a.get("radius",70))-40)/180
 var charge=1.7 if float(a.get("charge",0))>0 else 1.0
 return (hit+2)*count*reach*area*charge*maxf(1,1/float(a.get("minion_interval",1)))*(1+float(a.get("lifesteal",0))/100)/maxf(.3,float(a.get("cooldown",1)))
static func sync_code(a:Dictionary)->void:
 if str(a.get("program","")).begins_with("# @structured"):return
 if a.get("style")!="custom":return
 var lines=str(a.get("program","")).split("\n")
 for key in ["damage","heal","cooldown","range","radius","count","duration"]:
  var found=false
  for i in lines.size():
   if lines[i].strip_edges().begins_with("let "+key+" ="):lines[i]="let "+key+" = "+str(a.get(key,1));found=true;break
  if not found:lines.insert(0,"let "+key+" = "+str(a.get(key,1)))
 a.program="\n".join(lines)
static func enforce_attack(a:Dictionary,limit:float=34)->void:
 # Longer reach/area and higher damage spend the same rate budget.
 a.forced_balance=true
 sync_code(a)
 var cost=attack_cost(a)
 if not is_finite(cost):return
 if cost>limit:
  a.cooldown=minf(20,ceilf(float(a.cooldown)*cost/limit*10)/10)
  for n in 100:
   if attack_cost(a)<=limit+.001:break
   a.damage=maxf(0,float(a.damage)*.92);a.heal=maxf(0,float(a.heal)*.92)
   if n>40:a.duration=maxf(.5,float(a.duration)*.94);a.status_duration=maxf(.5,float(a.status_duration)*.94);a.count=maxi(1,int(a.count)-1)
   sync_code(a)
static func body_cost(h:Dictionary,enemy:bool=false)->float:
 return float(h.get("health" if enemy else "max_health",120))/120*float(h.get("speed",230))/230/(1-clampf(float(h.get("defence",0)),0,.25))
static func enforce_body(h:Dictionary,health_key:String="max_health")->void:
 var cap=1.0 if health_key=="max_health" else 1.5
 if body_cost(h,health_key=="health")<=cap:return
 if h.get("balance_tradeoff","speed")=="defence":
  h.defence=clampf(1-float(h.get(health_key,120))/120*float(h.speed)/230/cap,0,.25)
 var max_speed=230*cap*120/float(h.get(health_key,120))*(1-float(h.get("defence",0)))
 h.speed=maxf(100 if health_key=="max_health" else 40,minf(float(h.speed),max_speed))
 if body_cost(h,health_key=="health")>cap:h[health_key]=120*cap*230/float(h.speed)*(1-float(h.get("defence",0)))
static func enforce_hero(p:Dictionary)->void:
 if not p.get("forced_balance",false):return
 enforce_body(p.hero)
 for key in LIMITS:enforce_attack(p.hero[key],LIMITS[key])
 for t in p.techniques:enforce_attack(t.attack,LIMITS[t.slot])
static func hero_checked(p:Dictionary)->bool:
 if not p.get("forced_balance",false) or not preload("res://scripts/workshop_project.gd").validate(p).is_empty():return false
 if body_cost(p.hero)>1.001:return false
 for key in LIMITS:
  if attack_cost(p.hero[key])>LIMITS[key]+.01:return false
 for t in p.techniques:
  if attack_cost(t.attack)>LIMITS[t.slot]+.01:return false
 # A custom behaviour changes paths and impacts; portable code is permitted but its worst-case rate is reserved above.
 return true
static func toggle(parent:Node,value:Dictionary,callback:Callable)->CheckButton:
 var button=CheckButton.new();button.text="Forced Balance";button.button_pressed=bool(value.get("forced_balance",false));button.tooltip_text="Checked build budgets. Damage, reach and area trade against cooldown. Health and protection trade against speed. Not a competitive fairness certificate.";parent.add_child(button)
 button.toggled.connect(func(on:bool):value.forced_balance=on;callback.call())
 return button

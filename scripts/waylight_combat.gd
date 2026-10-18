extends RefCounted
const C=preload("res://scripts/waylight_catalog.gd")
const X=preload("res://scripts/relic_extensions.gd")
var extra={"timers":{},"extra_hits":0}
var manager:Node
var timers={}
var queue=[]
var embers=[]
var hit_count=0
var empowered=0.0
var shield=0.0
var shield_time=0.0
var processing=false
func reset()->void:extra={"timers":timers,"extra_hits":0};timers.clear();queue.clear();embers.clear();hit_count=0;empowered=0;shield=0;shield_time=0
func enabled()->bool:
 var g=manager.game
 return g.mode=="run" and not g.practice and not g.trial and not g.tutorial.active and not bool(manager.progress.state().fair) and not (g.lodges!=null and g.lodges.active) and not (g.mistglass_rift!=null and g.mistglass_rift.active) and not (g.continuation!=null and g.continuation.active)
func items()->Array:
 var result=[]
 if not enabled():return result
 for id in manager.progress.state().equipped:
  var v=manager.progress.item(str(id))
  if not v.is_empty():result.append(v)
 return result
func bonus(stat:String)->float:
 var total=0.0
 for v in items():
  if str(v.stat)==stat:total+=C.stat_bonus(v)
 return minf(total,.06 if stat=="power" else .08 if stat=="vitality" else .04)
func value(type:String)->float:
 for v in items():
  if str(v.type)==type:return C.effective(v)
 return 0
func damage(amount:float)->float:
 var result=amount*(1+bonus("power"))
 if enabled() and not processing:result*=X.damage(extra_state(),extra_values(),manager.game.health/manager.game.max_health())
 if enabled() and empowered>0 and not processing:result*=1+value("thornroot")/100.0;empowered=0
 if enabled() and not processing and float(timers.get("prism_charge",0))>0:result*=1+value("prism_comb")/100;timers.prism_charge=0
 return result
func incoming(amount:float,blocked:bool)->float:
 if not enabled():return amount
 amount=X.incoming(extra_state(),extra_values(),amount)
 if manager.game.health>manager.game.max_health()*.80:amount*=1-value("sunward")/100
 if manager.game.health<manager.game.max_health()*.35:amount*=1-value("quarry_heart")/100
 if shield_time>0 and shield>0:
  var absorbed=minf(shield,amount);shield-=absorbed;amount-=absorbed
 if amount>0 and value("thornroot")>0 and float(timers.get("thornroot",0))<=0:empowered=5;timers.thornroot=6
 return amount
func hit(foe:Dictionary,amount:float)->void:
 if not enabled() or processing or amount<=0:return
 extended("hit",foe)
 hit_count+=1
 if value("stormglass")>0 and hit_count>=5 and float(timers.get("stormglass",0))<=0:
  hit_count=0;timers.stormglass=5;queue.append({"uid":int(foe.uid),"damage":value("stormglass"),"at":foe.pos})
 if value("frost_lens")>0 and float(timers.get("frost_lens",0))<=0:
  timers.frost_lens=6;manager.game.adventure.combat.apply_status(manager.game.adventure.combat.npc_key(foe),"slow",value("frost_lens"),"solo",.20)
func killed()->void:
 if processing:return
 if enabled():extended("kill")
 if enabled() and value("sunseed")>0 and float(timers.get("sunseed",0))<=0:timers.sunseed=10;shield=maxf(shield,value("sunseed"));shield_time=maxf(shield_time,4)
 if enabled() and value("grove_seed")>0 and float(timers.get("grove_seed",0))<=0:
  timers.grove_seed=8;var g=manager.game;g.health=minf(g.max_health(),g.health+value("grove_seed"));g.add_float_text(g.position_in_world-Vector2(20,50),"ROOTWARDEN",Color("#a8deb1"))
func dodge()->void:
 if enabled():extended("dodge")
 if enabled() and value("prism_comb")>0 and float(timers.get("prism_comb",0))<=0:timers.prism_comb=8;timers.prism_charge=4
 if enabled() and value("emberstep")>0 and float(timers.get("emberstep",0))<=0:
  timers.emberstep=6;embers.append({"at":manager.game.position_in_world,"time":3.0,"tick":0.0,"damage":value("emberstep")})
func food()->void:
 if enabled():extended("food")
 if not enabled():return
 if value("nectar_vial")>0 and float(timers.get("nectar_vial",0))<=0:timers.nectar_vial=8;manager.game.health=minf(manager.game.max_health(),manager.game.health+value("nectar_vial"))
 var strength=maxf(value("river_pearl"),value("master_fisher"))
 if strength>0:shield=maxf(shield,strength);shield_time=5
func step(delta:float)->void:
 for id in timers:timers[id]=maxf(0,float(timers[id])-delta)
 empowered=maxf(0,empowered-delta);shield_time=maxf(0,shield_time-delta)
 if not enabled():queue.clear();embers.clear();shield=0;shield_time=0;return
 var g=manager.game;processing=true
 var work=queue.duplicate();queue.clear()
 for proc in work:
  for i in g.enemies.size():
   if int(g.enemies[i].uid)==int(proc.uid):g.damage_enemy(i,float(proc.damage));break
  g.attack_effects.append({"center":proc.at,"radius":40.0,"time":.2,"color":"#bfbaff"})
 for i in range(embers.size()-1,-1,-1):
  var ember=embers[i];ember.time-=delta;ember.tick-=delta
  if ember.time<=0:embers.remove_at(i);continue
  if ember.tick<=0:
   ember.tick=1
   for j in range(g.enemies.size()-1,-1,-1):
    if g.enemies[j].pos.distance_to(ember.at)<65:g.damage_enemy(j,float(ember.damage))
 processing=false
func draw_on(g:Node2D,camera:Vector2)->void:
 for ember in embers:
  var p:Vector2=ember.at-camera;g.draw_circle(p,65,Color(1,.5,.2,.12));g.draw_arc(p,65,0,TAU,32,Color(1,.68,.4,.5),2,true)
 if shield_time>0 and shield>0:g.draw_arc(g.position_in_world-camera-Vector2(0,18),35,0,TAU,32,Color("#b8e5e2"),2,true)

func extra_state()->Dictionary:
 extra.timers=timers;return extra
func extra_values()->Dictionary:
 var out={}
 for id in X.IDS:out[id]=value(id)
 return out
func extended(event:String,foe:Dictionary={})->void:
 var g=manager.game
 for command in X.event(event,extra_state(),extra_values(),str(g.character_id)):
  match str(command.kind):
   "shield":shield=maxf(shield,float(command.value));shield_time=maxf(shield_time,float(command.duration))
   "heal":g.health=minf(g.max_health(),g.health+float(command.value))
   "slow":
    if not foe.is_empty():g.adventure.combat.apply_status(g.adventure.combat.npc_key(foe),"slow",float(command.duration),"solo",float(command.value))
   "echo":
    if foe.is_empty():continue
    queue.append({"uid":int(foe.uid),"damage":float(command.value),"at":foe.pos})
    if bool(command.chain):
     var count=0
     for other in g.enemies:
      if int(other.uid)!=int(foe.uid) and other.pos.distance_to(foe.pos)<=130:
       queue.append({"uid":int(other.uid),"damage":float(command.value)*.5,"at":other.pos});count+=1
       if count>=2:break

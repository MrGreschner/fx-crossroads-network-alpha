extends RefCounted
const C=preload("res://scripts/waylight_catalog.gd")
var game:Node
var loadouts={}
var states={}
var processing=false
func setup(g:Node,offers:Dictionary)->void:
 game=g;loadouts.clear();states.clear()
 for id in offers:
  loadouts[id]=offers[id].get("relics",[]).duplicate(true);states[id]={"timers":{},"hits":0,"empowered":0.0,"shield":0.0,"shield_time":0.0,"embers":[]}
func value(id:String,type:String)->float:
 for item in loadouts.get(id,[]):
  if str(item.type)==type:return C.effective(item)
 return 0
func bonus(id:String,stat:String)->float:
 var total=0.0
 for item in loadouts.get(id,[]):
  if str(item.stat)==stat:total+=C.stat_bonus(item)
 return minf(total,.06 if stat=="power" else .08 if stat=="vitality" else .04)
func damage(id:String,amount:float)->float:
 var result=amount*(1+bonus(id,"power"));var s:Dictionary=states.get(id,{})
 if not s.is_empty() and float(s.empowered)>0 and not processing:result*=1+value(id,"thornroot")/100;s.empowered=0.0
 if not s.is_empty() and not processing and float(s.timers.get("prism_charge",0))>0:result*=1+value(id,"prism_comb")/100;s.timers.prism_charge=0.0
 return result
func incoming(id:String,amount:float)->float:
 var s:Dictionary=states.get(id,{})
 if s.is_empty():return amount
 if int(game.health.get(id,0))>game._max_hp(id)*.80:amount*=1-value(id,"sunward")/100
 if int(game.health.get(id,0))<game._max_hp(id)*.35:amount*=1-value(id,"quarry_heart")/100
 if float(s.shield_time)>0:
  var absorbed=minf(float(s.shield),amount);s.shield-=absorbed;amount-=absorbed
 if amount>0 and value(id,"thornroot")>0 and float(s.timers.get("thornroot",0))<=0:s.empowered=5.0;s.timers.thornroot=6.0
 return amount
func hit(id:String,foe:Dictionary,amount:float)->void:
 if processing or amount<=0 or not states.has(id):return
 var s:Dictionary=states[id];s.hits+=1
 if value(id,"frost_lens")>0 and float(s.timers.get("frost_lens",0))<=0:
  s.timers.frost_lens=6.0;game.adventure.combat.apply_status(game.adventure.combat.npc_key(foe),"slow",value(id,"frost_lens"),id,.20)
 if value(id,"stormglass")>0 and int(s.hits)>=5 and float(s.timers.get("stormglass",0))<=0:
  s.hits=0;s.timers.stormglass=5.0;processing=true
  for n in game.opponents.size():
   if int(game.opponents[n].uid)==int(foe.uid):game._hit_enemy(n,value(id,"stormglass"),id);break
  processing=false;game._emit_effect({"pos":foe.pos,"radius":40.0,"time":.2,"color":"#bfbaff"})
func killed(id:String)->void:
 var s:Dictionary=states.get(id,{})
 if not s.is_empty() and value(id,"sunseed")>0 and float(s.timers.get("sunseed",0))<=0:s.timers.sunseed=10.0;s.shield=maxf(float(s.shield),value(id,"sunseed"));s.shield_time=maxf(float(s.shield_time),4)
 if s.is_empty() or value(id,"grove_seed")<=0 or float(s.timers.get("grove_seed",0))>0:return
 s.timers.grove_seed=8.0;game._heal(id,id,int(value(id,"grove_seed")))
func dodge(id:String)->void:
 var s:Dictionary=states.get(id,{})
 if not s.is_empty() and value(id,"prism_comb")>0 and float(s.timers.get("prism_comb",0))<=0:s.timers.prism_comb=8.0;s.timers.prism_charge=4.0
 if s.is_empty() or value(id,"emberstep")<=0 or float(s.timers.get("emberstep",0))>0:return
 s.timers.emberstep=6.0;s.embers.append({"at":game.positions[id],"time":3.0,"tick":0.0,"damage":value(id,"emberstep")})
func food(id:String)->void:
 var s:Dictionary=states.get(id,{});var strength=maxf(value(id,"river_pearl"),value(id,"master_fisher"))
 if not s.is_empty() and value(id,"nectar_vial")>0 and float(s.timers.get("nectar_vial",0))<=0:s.timers.nectar_vial=8.0;game._heal(id,id,int(value(id,"nectar_vial")))
 if not s.is_empty() and strength>0:s.shield=maxf(float(s.shield),strength);s.shield_time=5.0
func step(dt:float)->void:
 processing=true
 for id in states:
  var s:Dictionary=states[id]
  for key in s.timers:s.timers[key]=maxf(0,float(s.timers[key])-dt)
  s.empowered=maxf(0,float(s.empowered)-dt);s.shield_time=maxf(0,float(s.shield_time)-dt)
  for n in range(s.embers.size()-1,-1,-1):
   var e:Dictionary=s.embers[n];e.time-=dt;e.tick-=dt
   if float(e.time)<=0:s.embers.remove_at(n);continue
   if float(e.tick)<=0:
    e.tick=1.0
    for foe in range(game.opponents.size()-1,-1,-1):
     if game.opponents[foe].pos.distance_to(e.at)<65:game._hit_enemy(foe,float(e.damage),str(id))
 processing=false
func visuals()->Array:
 var out=[]
 for id in states:
  var s:Dictionary=states[id]
  for ember in s.embers:out.append({"at":[ember.at.x,ember.at.y],"radius":65,"color":"#eb925e"})
  if float(s.shield_time)>0 and float(s.shield)>0 and game.positions.has(id):out.append({"at":[game.positions[id].x,game.positions[id].y],"radius":35,"color":"#b8e5e2"})
 return out

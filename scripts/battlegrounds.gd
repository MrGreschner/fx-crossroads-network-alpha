extends RefCounted
## Host-authoritative armies. Bounded population and 10 Hz strategic simulation.
const SIZE=Vector2(6800,4400)
const MAPS={"woodland":"Verdant Front","warzone":"Iron Rain"}
const FACTIONS=["Ram Alliance","Ironhollow Legion"]
const TYPES=["foot","archer","healer","catapult","mage","berserker","tank","longbow"]
const LABELS=["Foot soldiers","Archers","Healers","Catapults","Mages","Berserkers","Shield tanks","Long-range scouts"]
const COSTS=[90,130,160,240,220,200,230,240]
const HP=[115,75,90,150,85,155,300,70]
const DAMAGE=[14,12,0,30,21,24,10,22]
const REACH=[55,340,310,510,290,60,58,630]
const SPEED=[115,110,105,80,110,135,80,95]
const UPGRADES=["melee","ranged","healing","vitality","production"]
var game:Node
var map_id:="woodland"
var lanes:=4
var clock:=0.0
var accumulator:=0.0
var army_time:=0.0
var unit_phase:=0
var uid:=0
var income:=0.0
var air_timer:=8.0
var units:Dictionary={}
var unit_grid:Dictionary={}
var unit_grid_dirty:=true
var bases:Dictionary={}
var owners:Dictionary={}
var bombs:Array=[]
var shots:Array=[]
var heart_hp:Array=[2600.0,2600.0]
var winner:=-1
var work:Dictionary={"units_ms":0.0,"max_units_ms":0.0,"step_ms":0.0}
func setup(g:Node)->void:
 preload("res://scripts/battleground_art.gd").warm()
 game=g;map_id=game.bg_map;lanes=game.bg_team_size
 clock=0;accumulator=0;army_time=0;unit_phase=0;uid=0;income=0;air_timer=8;units.clear();unit_grid.clear();unit_grid_dirty=true;bases.clear();owners.clear();bombs.clear();shots.clear();heart_hp=[2600.0,2600.0];winner=-1;work={"units_ms":0.0,"max_units_ms":0.0,"step_ms":0.0}
 var slots:Dictionary={0:0,1:0}
 for member in game.fighters():
  var id:=str(member.id);var team:=int(game.teams.get(id,0));var lane:=int(slots[team]);slots[team]+=1
  owners[id]=str(team)+":"+str(lane)
  bases[owners[id]]={"owner":id,"team":team,"lane":lane,"pos":barrack_pos(team,lane),"hp":950.0,"max_hp":950.0,"timer":1.0,"counts":[2,0,0,0,0,0,0,0],"queue":[],"recruit_cursor":0,"recruit_timer":0.0,"upgrades":{"melee":0,"ranged":0,"healing":0,"vitality":0,"production":0}}
 game.world_buildings.append({"name":"Supplies","pos":SIZE*.5,"kind":"shop"})
 # Tree/sandbag islands leave continuous march lanes and cross-lane routes.
 for lane in range(lanes-1):
  var y:float=(lane_y(lane)+lane_y(lane+1))*.5
  for x in [1800,2450,4350,5000]:
   for offset in [-65,0,65]:game.field_obstacles.append({"pos":Vector2(x+offset,y),"radius":36.0,"kind":"tree" if map_id=="woodland" else "rock"})
 for lane in lanes:
  for x in [1250,2150,4650,5550]:
   for side in [-1,1]:
    for n in 3:game.field_obstacles.append({"pos":Vector2(x+(n-1)*65,lane_y(lane)+side*(240+abs(n-1)*25)),"radius":30.0,"kind":"tree" if map_id=="woodland" else "rock"})
func lane_y(lane:int)->float:return 700.0+float(lane)*3000.0/maxi(1,lanes-1)
func barrack_pos(team:int,lane:int)->Vector2:return Vector2(550 if team==0 else 6250,lane_y(lane))
func heart_pos(team:int)->Vector2:return Vector2(180 if team==0 else 6620,2200)
func spawn(id:String)->Vector2:
 var b:Dictionary=bases.get(owners.get(id,""),{})
 return (b.get("pos",Vector2(550,700)) as Vector2)+Vector2(90 if int(b.get("team",0))==0 else -90,90)
func actor(key:String)->Dictionary:
 if units.has(key):return {"pos":units[key].pos,"alive":float(units[key].hp)>0,"bg":key}
 if key.begins_with("bgbase:"):
  var b:Dictionary=bases.get(key.trim_prefix("bgbase:"),{})
  if not b.is_empty():return {"pos":b.pos,"alive":float(b.hp)>0,"bg":key,"structure":true}
 if key.begins_with("bgheart:"):
  var side:=int(key.trim_prefix("bgheart:"));return {"pos":heart_pos(side),"alive":heart_hp[side]>0,"bg":key,"structure":true}
 return {}
func side_of(owner:String)->int:
 if owner.begins_with("bgarmy:"):return side_of(owner.trim_prefix("bgarmy:"))
 if units.has(owner):return int(units[owner].team)
 return int(game.teams.get(owner,bases.get(owners.get(owner,""),{}).get("team",-1)))
func hostile(owner:String)->Array[String]:
 var result:Array[String]=[];var side:=side_of(owner)
 if side<0:return result
 for key in units:
  if int(units[key].team)!=side and float(units[key].hp)>0:result.append(str(key))
 for key in bases:
  if int(bases[key].team)!=side and float(bases[key].hp)>0:result.append("bgbase:"+str(key))
 var other:=1-side
 # Enemy heart is shielded until every barracks on that side is destroyed.
 if not shielded(other):result.append("bgheart:"+str(other))
 return result
func shielded(side:int)->bool:
 for b in bases.values():
  if int(b.team)==side and float(b.hp)>0:return true
 return false
func damage(key:String,amount:float,source:String)->void:
 if game.role!="host" or winner>=0 or amount<=0 or not is_finite(amount):return
 var side:=side_of(source)
 if units.has(key):
  var u:Dictionary=units[key]
  if side==int(u.team):return
  if game.positions.has(source):amount*=game.adventure.combat.war_multiplier(source);amount=game.legacy.critical(source,amount,u.pos)
  var dealt:=minf(float(u.hp),amount);u.hp=maxf(0,float(u.hp)-amount)
  game.adventure.combat.v90.on_hit(source,dealt)
  if game.positions.has(source):game._stat(source,"damage",dealt);game._apply_lifesteal(source,dealt);game._damage_feedback(u.pos,dealt)
  if float(u.hp)<=0:
   if not bool(u.get("converted",false)):game.adventure.combat.morrow.fallen({"pos":u.pos,"type":"bramble","corpse_sprite":"ram" if int(u.team)==0 else "bramble"})
   var owner:=str(units.get(source,{}).get("owner",source)).trim_prefix("bgarmy:");
   if not bool(u.get("converted",false)):
    reward(owner,12+int(u.kind)*2,8)
    if game.kills.has(owner):game.kills[owner]=int(game.kills[owner])+1
    if game.arena_records.has(owner):game.arena_records[owner].npc_kills+=1
   units.erase(key);game.adventure.combat.statuses.erase(key)
 elif key.begins_with("bgbase:"):
  var b:Dictionary=bases.get(key.trim_prefix("bgbase:"),{})
  if b.is_empty() or side==int(b.team):return
  b.hp=maxf(0,float(b.hp)-amount)
  if float(b.hp)<=0 and not bool(b.get("rewarded",false)):
   b.rewarded=true
   for id in game.positions:
    if int(game.teams.get(id,-1))==1-int(b.team):reward(str(id),100,60)
   game._emit_effect({"pos":b.pos,"radius":140.0,"time":1.0,"color":"#ffb95d"})
 elif key.begins_with("bgheart:"):
  var team:=int(key.trim_prefix("bgheart:"))
  if side==team or shielded(team):return
  heart_hp[team]=maxf(0,float(heart_hp[team])-amount)
  if heart_hp[team]<=0:winner=1-team;game.end_match(FACTIONS[winner]+" wins • Enemy heart destroyed")
func reward(owner:String,money:int,experience:int)->void:
 if not game.gold.has(owner):return
 game.gold[owner]=int(game.gold[owner])+money
 game.xp[owner]=int(game.xp.get(owner,0))+experience
 level_up(owner)
func knock(key:String,direction:Vector2,distance:float)->void:
 if units.has(key):units[key].pos=game._move_actor(units[key].pos,direction*minf(distance,150));unit_grid_dirty=true
func step(delta:float)->void:
 clock+=delta;army_time=clock;accumulator+=delta
 var strategic=accumulator>=.1
 var dt:=minf(accumulator,.2) if strategic else 0.0
 if strategic:
  accumulator=0;income+=dt
  if income>=3:
   income-=3
   for id in game.gold:game.gold[id]=int(game.gold[id])+6
  for key in bases:
   var b:Dictionary=bases[key]
   if float(b.hp)<=0:continue
   b.timer=float(b.timer)-dt
   if float(b.timer)<=0 and b.get("queue",[]).is_empty():
    b.timer=18.0-int(b.upgrades.production)*1.5;enqueue_wave(b)
   b.recruit_timer=float(b.get("recruit_timer",0))-dt
   if float(b.recruit_timer)<=0 and not b.get("queue",[]).is_empty():
    var kind=int(b.queue[0])
    if spawn_unit(b,kind,0):b.queue.pop_front();b.recruit_cursor=(kind+1)%TYPES.size();b.recruit_timer=.18
 # Spread 10 Hz soldier decisions over six authority frames. A full 192-unit
 # army schedules at most 32 ordinary decisions per 60 Hz frame, not one burst.
 var work_begin=Time.get_ticks_usec()
 if delta>=.08:tick_units(minf(delta,.2)) # Coarse deterministic fixtures / legacy stalls.
 else:
  unit_phase=(unit_phase+1)%6;tick_units(.1,unit_phase)
 work.units_ms=(Time.get_ticks_usec()-work_begin)/1000.0;work.max_units_ms=maxf(float(work.max_units_ms),float(work.units_ms))
 tick_shots(delta);tick_bombs(delta);work.step_ms=(Time.get_ticks_usec()-work_begin)/1000.0
 for id in game.positions:
  if int(game.health.get(id,0))<=0 and Time.get_ticks_msec()>=int(game.respawn_at.get(id,9223372036854775807)):
   game.health[id]=game._max_hp(str(id));game.positions[id]=spawn(str(id));game.invincible_until[id]=Time.get_ticks_msec()+1600
   if game.has_method("network_relocate"):game.network_relocate(str(id),game.positions[id])
   if id==game.my_id:game.local_pos=game.positions[id]
   elif not game.has_method("network_relocate"):game._send_channel(str(id),{"type":"teleport","point":[game.positions[id].x,game.positions[id].y]})
func enqueue_wave(b:Dictionary)->void:
 var counts:Array=b.counts.duplicate();var queue=[];var start=int(b.get("recruit_cursor",0))
 # Interleave types. A full army retains the unspawned tail, so scouts and berserkers cannot starve.
 for round_index in 6:
  for offset in TYPES.size():
   var kind=(start+offset)%TYPES.size()
   if round_index<int(counts[kind]):queue.append(kind)
 b.queue=queue
func owner_count(owner:String)->int:
 var count=0
 for unit in units.values():
  if str(unit.owner)==owner:count+=1
 return count
func spawn_unit(b:Dictionary,kind:int,n:int)->bool:
 # 24 soldiers per owner; replacements resume when existing troops fall.
 var owned:=0;var phases=[0,0,0,0,0,0]
 for u in units.values():
  phases[int(u.get("phase",0))]+=1
  if str(u.owner)==str(b.owner):owned+=1
 if kind<0 or kind>=TYPES.size() or owned>=24 or units.size()>=lanes*2*24:return false
 uid+=1;unit_grid_dirty=true
 var key:="bgunit:"+str(uid);var hp:float=HP[kind]*(1+.12*int(b.upgrades.vitality))
 units[key]={"owner":str(b.owner),"team":int(b.team),"lane":int(b.lane),"kind":kind,"pos":b.pos+Vector2((95+n*12)*(1 if int(b.team)==0 else -1),float((uid%5)-2)*26),"hp":hp,"max_hp":hp,"cooldown":float(uid%5)*.12,"sample_time":clock,"last_step":clock,"phase":phases.find(phases.min()),"last_x":b.pos.x+(95+n*12)*(1 if int(b.team)==0 else -1),"last_y":b.pos.y+float((uid%5)-2)*26,"walk":0.0,"moving":false,"facing":1 if int(b.team)==0 else -1,"attack_at":-10.0}
 return true
func hostile_near(owner:String,point:Vector2,radius:float)->Array[String]:
 var result:Array[String]=[];var side:=side_of(owner)
 if side<0:return result
 if unit_grid_dirty:rebuild_unit_grid()
 var candidates=nearby_units(point,radius)
 candidates.sort_custom(func(a,b):return int(str(a).trim_prefix("bgunit:"))<int(str(b).trim_prefix("bgunit:")))
 for key in candidates:
  if units.has(key) and int(units[key].team)!=side and float(units[key].hp)>0:result.append(str(key))
 for key in bases:
  if int(bases[key].team)!=side and float(bases[key].hp)>0 and point.distance_to(bases[key].pos)<=radius:result.append("bgbase:"+str(key))
 var other:=1-side
 if not shielded(other) and point.distance_to(heart_pos(other))<=radius:result.append("bgheart:"+str(other))
 return result
func nearest(u:Dictionary)->String:
 var best:="";var distance:=720.0;var side:=int(u.team)
 for id in game.positions:
  if int(game.teams.get(id,-1))==side or int(game.health.get(id,0))<=0:continue
  var d:float=u.pos.distance_to(game.positions[id])
  if d<distance:distance=d;best="p:"+str(id)
 for summon in game.adventure.combat.v59.target_points():
  var owner:String=game.adventure.combat.v59.rival_id(str(summon))
  if not game._rival(str(u.owner),owner):continue
  var p:Vector2=game.adventure.combat.v59.target_position(str(summon));var d:float=u.pos.distance_to(p)
  if d<distance:distance=d;best="p:"+str(summon)
 for key in nearby_units(u.pos,720):
  if not units.has(key):continue
  var other:Dictionary=units[key]
  if int(other.team)==side:continue
  var d:float=u.pos.distance_to(other.pos)
  if d<distance:distance=d;best=str(key)
 if best.is_empty():
  var key:=str(1-side)+":"+str(u.lane)
  if bases.has(key) and float(bases[key].hp)>0:best="bgbase:"+key
  else:
   for other in bases:
    if int(bases[other].team)!=side and float(bases[other].hp)>0:best="bgbase:"+str(other);break
   if best.is_empty():best="bgheart:"+str(1-side)
 return best
func tick_units(dt:float,phase:int=-1)->void:
 rebuild_unit_grid()
 for key in units.keys():
  if not units.has(key) or phase>=0 and int(units[key].get("phase",0))!=phase:continue
  var u:Dictionary=units[key];var kind:=int(u.kind);var unit_dt=dt if phase<0 else clampf(clock-float(u.get("last_step",clock-.1)),0,.2);u.last_step=clock;u.sample_time=clock;u.cooldown=float(u.cooldown)-unit_dt
  if bool(u.get("converted",false)):
   u.expires=float(u.get("expires",0))-unit_dt
   if float(u.expires)<=0:units.erase(key);game.adventure.combat.statuses.erase(key);continue
  if game.adventure.combat.stunned(str(key)):continue
  var target:=nearest(u);var a:Dictionary=game.adventure.combat.actor(target)
  if a.is_empty():continue
  var reach:float=REACH[kind];var delta_pos:Vector2=a.pos-u.pos;var distance:=delta_pos.length()
  if kind==2:
   if float(u.cooldown)<=0:
    heal_near(u);u.cooldown=1.4
   reach=230
  var desired:=Vector2.ZERO
  if distance>reach:desired=delta_pos.normalized()
  elif kind in [1,2,3,4,7] and distance<reach*.55:desired=-delta_pos.normalized()
  # Separation prevents a lane from collapsing into one overlapping sprite.
  var separation:=Vector2.ZERO
  for other_key in nearby_units(u.pos,30):
   if other_key==key or not units.has(other_key):continue
   var v:Vector2=u.pos-units[other_key].pos
   if v.length_squared()<900 and v.length_squared()>1:separation+=v.normalized()*.35
  var speed:float=SPEED[kind]*game.adventure.combat.speed_factor(str(key))
  var before:Vector2=u.pos;u.last_x=before.x;u.last_y=before.y;u.last_walk=float(u.get("walk",0))
  u.pos=game._move_actor(before,(desired+separation).limit_length(1)*speed*unit_dt)
  var moved:Vector2=u.pos-before;u.moving=moved.length_squared()>.04;u.walk=float(u.get("walk",0))+moved.length()*.13
  if absf(moved.x)>.1:u.facing=1 if moved.x>0 else -1
  if kind!=2 and distance<=reach+15 and float(u.cooldown)<=0 and game._clear_path(u.pos,a.pos):
   var b:Dictionary=bases.get(owners.get(str(u.owner),""),{});var upgrades:Dictionary=b.get("upgrades",{})
   var amount:float=DAMAGE[kind]*(1+.12*int(upgrades.get("melee" if kind in [0,5,6] else "ranged",0)))
   u.attack_at=clock
   u.cooldown=1.0 if kind==5 else 2.7 if kind==3 else 1.6
   if kind in [0,5,6]:hit(target,amount,str(key));game._emit_effect({"pos":a.pos,"radius":24.0,"time":.15,"color":"#fbd290"})
   elif kind==3:
    uid+=1;shots.append({"uid":uid,"pos":u.pos,"target":target,"end":a.pos,"owner":"bgarmy:"+str(u.owner),"team":int(u.team),"damage":amount,"speed":340.0 if kind==3 else 500.0,"radius":100.0 if kind==3 else 65.0 if kind==4 else 0.0,"life":3.0})
   else:game.adventure.combat.launch_projectile("bgarmy:"+str(u.owner),u.pos,delta_pos.normalized(),{"range":reach+90,"speed":450,"splash_radius":65 if kind==4 else 0,"splash_damage":amount*.45,"color":"#a4e6ed" if int(u.team)==0 else "#f8a181"},amount)
 unit_grid_dirty=true
func heal_near(u:Dictionary)->void:
 var upgrades:Dictionary=bases.get(owners.get(str(u.owner),""),{}).get("upgrades",{})
 var amount:float=8*(1+.15*int(upgrades.get("healing",0)))
 var target:="";var lowest:=1.0
 for key in nearby_units(u.pos,310):
  if not units.has(key):continue
  var a:Dictionary=units[key];var ratio:float=float(a.hp)/float(a.max_hp)
  if int(a.team)==int(u.team) and u.pos.distance_to(a.pos)<310 and ratio<lowest:lowest=ratio;target=str(key)
 for id in game.positions:
  var ratio:float=float(game.health.get(id,0))/maxi(1,game._max_hp(str(id)))
  if int(game.teams.get(id,-1))==int(u.team) and ratio>0 and ratio<lowest and u.pos.distance_to(game.positions[id])<310:lowest=ratio;target="p:"+str(id)
 if units.has(target):units[target].hp=minf(float(units[target].max_hp),float(units[target].hp)+amount)
 elif target.begins_with("p:"):game._heal(str(u.owner),target.substr(2),int(amount))
 if not target.is_empty():u.attack_at=clock;game._emit_effect({"pos":game.adventure.combat.actor(target).pos,"radius":23.0,"time":.3,"color":"#8bf2b1"})
func hit(target:String,amount:float,source:String)->void:
 if target.begins_with("p:"):
  game.adventure.combat.damage(target,amount,source)
 else:damage(target,amount,source)
func tick_shots(dt:float)->void:
 for index in range(shots.size()-1,-1,-1):
  var s:Dictionary=shots[index];s.life=float(s.life)-dt
  var a:Dictionary=game.adventure.combat.actor(str(s.target));var finish:Vector2=s.end
  var travel:float=float(s.speed)*dt
  if s.pos.distance_to(finish)<=travel:
   if float(s.radius)>0:blast(finish,float(s.radius),float(s.damage),str(s.owner),int(s.team))
   elif not a.is_empty() and (a.pos as Vector2).distance_to(finish)<35:hit(str(s.target),float(s.damage),str(s.owner))
   shots.remove_at(index)
  elif float(s.life)<=0:shots.remove_at(index)
  else:s.pos=s.pos.move_toward(finish,travel)
func blast(pos:Vector2,radius:float,amount:float,source:String,side:int,cause:Dictionary={})->void:
 for id in game.positions:
  if int(game.teams.get(id,-1))!=side and int(game.health.get(id,0))>0 and pos.distance_to(game.positions[id])<radius:game._hurt(str(id),amount,source,"",cause)
 for key in units.keys():
  if int(units[key].team)!=side and pos.distance_to(units[key].pos)<radius:damage(str(key),amount,source)
 game._emit_effect({"pos":pos,"radius":radius,"time":.4,"color":"#ffae65"})
func tick_bombs(dt:float)->void:
 if map_id!="warzone":return
 air_timer-=dt
 if air_timer<=0:
  air_timer=7.0
  var lane:=randi_range(0,lanes-1);var x:=randf_range(1300,5500)
  for n in 3:
   uid+=1;bombs.append({"uid":uid,"pos":Vector2(x+(n-1)*200,lane_y(lane)+randf_range(-100,100)),"time":2.5+n*.25,"radius":130.0})
 for index in range(bombs.size()-1,-1,-1):
  var b:Dictionary=bombs[index];b.time=float(b.time)-dt
  if float(b.time)<=0:blast(b.pos,float(b.radius),45,"enemy",-1,preload("res://scripts/defeat_credit.gd").hazard("Iron Rain airstrike"));bombs.remove_at(index)
func price(b:Dictionary,key:String)->int:
 if key.begins_with("unit:"):
  var k:=TYPES.find(key.trim_prefix("unit:"))
  return COSTS[k]*(1+int(b.counts[k])) if k>=0 else 0
 return 100+int(b.upgrades.get(key,0))*70
func buy(id:String,key:String)->bool:
 if game.role!="host" or not game.started or game.start_countdown>0 or int(game.health.get(id,0))<=0:return false
 var b:Dictionary=bases.get(owners.get(id,""),{})
 if b.is_empty() or float(b.hp)<=0 or (game.positions[id] as Vector2).distance_to(b.pos)>240:return false
 var kind:=TYPES.find(key.trim_prefix("unit:")) if key.begins_with("unit:") else -1
 if kind<0 and key not in UPGRADES:return false
 if kind>=0 and int(b.counts[kind])>= (6 if kind==0 else 3):return false
 if kind<0 and int(b.upgrades[key])>=4:return false
 var cost:=price(b,key)
 if int(game.gold.get(id,0))<cost:return false
 game.gold[id]=int(game.gold[id])-cost
 if kind>=0:b.counts[kind]=int(b.counts[kind])+1
 else:b.upgrades[key]=int(b.upgrades[key])+1
 game._stat(id,"upgrades",1)
 return true
func interact(id:String)->bool:
 var b:Dictionary=bases.get(owners.get(id,""),{})
 if not b.is_empty() and float(b.hp)>0 and (game.positions.get(id,Vector2.ZERO) as Vector2).distance_to(b.pos)<240:open_shop();return true
 return false
func open_shop(notice:String="")->void:
 var b:Dictionary=bases.get(owners.get(game.my_id,""),{})
 if b.is_empty():return
 game.presentation.window("MY BARRACKS • "+FACTIONS[int(b.team)],"battlegrounds")
 game.presentation.label(game.presentation.content,"CC: "+str(game.gold.get(game.my_id,0))+" • Next march in %ds • %d / 24 active • %d queued" % [ceili(maxf(0,float(b.timer))),owner_count(game.my_id),b.get("queue",[]).size()],18)
 if not notice.is_empty():game.presentation.label(game.presentation.content,notice,19)
 var grid:=GridContainer.new();grid.columns=2;game.presentation.content.add_child(grid)
 for k in TYPES.size():
  var key:String="unit:"+str(TYPES[k]);var label:String=LABELS[k]+" ×"+str(int(b.counts[k]))+" • +1 / "+str(price(b,key))+" CC"
  var button=game.presentation.button(grid,label,request_buy.bind(key));button.custom_minimum_size=Vector2(370,44)
  button.tooltip_text="Heals nearby allies" if k==2 else "Splash siege damage" if k==3 else "Long reach, fragile" if k==7 else "Recruits march automatically and fight the opposing army."
 game.presentation.label(game.presentation.content,"ARMY UPGRADES • apply to future troops",19)
 for key in UPGRADES:
  var text:=str(key).capitalize()+" "+str(int(b.upgrades[key]))+"/4 • "+str(price(b,str(key)))+" CC"
  if key=="production":text+=" • Faster reinforcements"
  game.presentation.button(game.presentation.content,text,request_buy.bind(str(key)))
func request_buy(key:String)->void:
 if game.role=="host":
  var success:=buy(game.my_id,key);game.presentation.close();open_shop("Upgraded!" if success else "Need more CC, upgrade capped, or move closer to your barracks.")
 elif game.has_method("request_battleground_order"):game.request_battleground_order(key)
 else:game._send_channel(game.host_id,{"type":"bg_upgrade","key":key});game.presentation.close();game.status_label.text="Barracks order sent. Press E to view your updated army."
func snapshot()->Dictionary:
 var payload:Dictionary={"map":map_id,"lanes":lanes,"clock":clock,"army_time":army_time,"work":work,"owners":owners,"hearts":heart_hp,"winner":winner,"units":{},"bases":{},"shots":[],"bombs":[]}
 for key in units:payload.units[key]=units[key].duplicate();payload.units[key].pos=[snappedf(units[key].pos.x,.01),snappedf(units[key].pos.y,.01)];payload.units[key].erase("last_step");payload.units[key].erase("phase")
 for key in bases:payload.bases[key]=bases[key].duplicate(true);payload.bases[key].pos=[bases[key].pos.x,bases[key].pos.y]
 for key in ["shots","bombs"]:
  for value in shots if key=="shots" else bombs:
   var copy:Dictionary=value.duplicate();copy.pos=[roundi(value.pos.x),roundi(value.pos.y)]
   if copy.has("end"):copy.end=[copy.end.x,copy.end.y]
   payload[key].append(copy)
 return payload
func receive(data:Dictionary)->void:
 if data.is_empty():return
 data=data.duplicate(true);work=data.get("work",work)
 map_id=str(data.get("map","woodland"));lanes=clampi(int(data.get("lanes",4)),3,4);clock=float(data.get("clock",clock));owners=data.get("owners",{});heart_hp=data.get("hearts",[2600,2600]);winner=int(data.get("winner",-1));units=data.get("units",{});bases=data.get("bases",{});shots=data.get("shots",[]);bombs=data.get("bombs",[])
 for collection in [units,bases]:
  for key in collection:collection[key].pos=Vector2(float(collection[key].pos[0]),float(collection[key].pos[1]))
 for collection in [shots,bombs]:
  for value in collection:
   value.pos=Vector2(float(value.pos[0]),float(value.pos[1]))
   if value.has("end"):value.end=Vector2(float(value.end[0]),float(value.end[1]))
func draw_world(canvas:Node2D)->void:
 var view:Dictionary=game._battleground_view() if game.has_method("_battleground_view") else {}
 var draw_units:Dictionary=view.get("units",units);var draw_shots:Array=view.get("shots",shots);var draw_bombs:Array=view.get("bombs",bombs);var draw_clock:float=float(view.get("clock",clock))
 var cam:Vector2=game.camera;var visible:=Rect2(cam-Vector2(120,120),game.VIEW+Vector2(240,240));var font:=ThemeDB.fallback_font
 for lane in lanes:
  var y:=lane_y(lane)
  canvas.draw_line(Vector2(350,y)-cam,Vector2(6450,y)-cam,Color("#b3a572") if map_id=="woodland" else Color("#776b5c"),240)
  canvas.draw_line(Vector2(350,y)-cam,Vector2(6450,y)-cam,Color("#d0bc87") if map_id=="woodland" else Color("#655d53"),170)
  for x in range(900,6000,140):
   var p:=Vector2(x,y)-cam
   if not visible.has_point(Vector2(x,y)):continue
   if map_id=="woodland":
    for n in 3:
     var mark:=p+Vector2((n-1)*27,(posmod(x+lane*35,70)-35)+n*18);canvas.draw_rect(Rect2(mark,Vector2(14,6)),Color("#aa9467"))
   else:
    canvas.draw_rect(Rect2(p-Vector2(26,3),Vector2(52,6)),Color("#bcb091"))
    for offset in [-65,65]:canvas.draw_line(p+Vector2(-55,offset),p+Vector2(55,offset),Color("#454844"),3)
  for x in [1450,2850,3950,5350]:
   var p:=Vector2(x,y+160)
   if not visible.has_point(p):continue
   if map_id=="woodland":canvas.draw_rect(Rect2(p-cam-Vector2(32,18),Vector2(64,36)),Color("#6f5740"));canvas.draw_line(p-cam-Vector2(55,0),p-cam+Vector2(55,0),Color("#e3ca89"),4)
   else:
    canvas.draw_circle(p-cam,65,Color("#514c44"));canvas.draw_circle(p-cam,45,Color("#383a36"))
    for n in 4:canvas.draw_rect(Rect2(p-cam+Vector2(n*20-40,60),Vector2(18,13)),Color("#a99874"))
    canvas.draw_line(p-cam+Vector2(-55,78),p-cam+Vector2(55,78),Color("#b3bba8"),2)
 for x in [1700,3400,5100]:
  canvas.draw_line(Vector2(x,500)-cam,Vector2(x,3900)-cam,Color("#aa9c73") if map_id=="woodland" else Color("#6c6255"),95)
 for gap in range(lanes-1):
  var y:float=(lane_y(gap)+lane_y(gap+1))*.5
  for x in [1150,2200,4600,5650]:
   var p:=Vector2(x,y)-cam
   if not visible.has_point(Vector2(x,y)):continue
   if map_id=="woodland":
    canvas.draw_circle(p,80,Color(.15,.35,.3,.6));canvas.draw_circle(p,53,Color("#356f77"));canvas.draw_arc(p,48,0,PI,18,Color(.5,.8,.8,.3),2)
    for n in 4:canvas.draw_circle(p+Vector2.from_angle(n*1.6)*75,4,Color("#ead79c"))
   else:
    canvas.draw_rect(Rect2(p-Vector2(70,30),Vector2(140,60)),Color("#3b3c37"));canvas.draw_rect(Rect2(p-Vector2(80,40),Vector2(160,16)),Color("#8b8572"))
    canvas.draw_rect(Rect2(p+Vector2(-12,-10),Vector2(24,20)),Color("#19242a"));canvas.draw_line(p+Vector2(-80,45),p+Vector2(80,45),Color("#bac0b6"),2)
    for n in 6:canvas.draw_line(p+Vector2(-70+n*25,36),p+Vector2(-60+n*25,54),Color("#bac0b6"),2)
 if map_id=="warzone" and not draw_bombs.is_empty():
  var plane:=Vector2(fposmod(draw_clock*650,SIZE.x),350)-cam
  canvas.draw_colored_polygon(PackedVector2Array([plane+Vector2(0,-28),plane+Vector2(16,0),plane+Vector2(80,24),plane+Vector2(12,16),plane+Vector2(6,54),plane+Vector2(-6,54),plane+Vector2(-12,16),plane+Vector2(-80,24),plane+Vector2(-16,0)]),Color("#bbc1af"))
 for side in 2:
  canvas.draw_line(Vector2(550 if side==0 else 6250,400)-cam,Vector2(550 if side==0 else 6250,4000)-cam,Color("#a59675"),200)
  var p:=heart_pos(side)-cam;var tint:=Color("#78cce8") if side==0 else Color("#ef9876")
  canvas.draw_circle(p,85,Color("#253e4b"));canvas.draw_arc(p,90,0,TAU,40,tint,5);canvas.draw_rect(Rect2(p-Vector2(30,60),Vector2(60,110)),tint)
  canvas.draw_string(font,p-Vector2(100,108),FACTIONS[side],HORIZONTAL_ALIGNMENT_CENTER,200,19,Color.WHITE)
  canvas.draw_string(font,p+Vector2(-90,125),"SHIELDED" if shielded(side) else "HEART "+str(int(heart_hp[side])),HORIZONTAL_ALIGNMENT_CENTER,180,18,tint)
 for key in bases:
  var b:Dictionary=bases[key];var p:Vector2=b.pos-cam
  if not visible.has_point(b.pos):continue
  var tint:=Color("#8ccbd8") if int(b.team)==0 else Color("#ce836c")
  if float(b.hp)>0:
   game._sprite("town_gate",b.pos-Vector2(115,140),Vector2(230,195),Color.WHITE if int(b.team)==0 else Color("#efb4a2"))
  else:canvas.draw_rect(Rect2(p-Vector2(90,35),Vector2(180,65)),Color("#584a40"));canvas.draw_circle(p,24,Color("#313c3b"))
  for x in [-135,135]:
   canvas.draw_line(p+Vector2(x,-100),p+Vector2(x,45),Color("#8b7560"),5)
   canvas.draw_colored_polygon(PackedVector2Array([p+Vector2(x,-100),p+Vector2(x+35,-80),p+Vector2(x,-60)]),tint)
  canvas.draw_rect(Rect2(p+Vector2(145,10),Vector2(75,20)),Color("#a58152"))
  for n in 3:canvas.draw_circle(p+Vector2(160+n*20,6),7,Color("#9bc9be"))
  canvas.draw_string(font,p+Vector2(135,50),"UPGRADES",HORIZONTAL_ALIGNMENT_LEFT,-1,12,Color("#ead19a"))
  canvas.draw_string(font,p+Vector2(-100,-110),player_name(str(b.owner)),HORIZONTAL_ALIGNMENT_CENTER,200,17,Color.WHITE)
  canvas.draw_rect(Rect2(p+Vector2(-65,63),Vector2(130,8)),Color("#302a25"));canvas.draw_rect(Rect2(p+Vector2(-65,63),Vector2(130*maxf(0,float(b.hp))/950.0,8)),tint)
  if str(b.owner)==game.my_id and float(b.hp)>0:
   canvas.draw_string(font,p+Vector2(-100,98),"E • My army",HORIZONTAL_ALIGNMENT_CENTER,200,18,Color("#ffe29a"))
   var queue:Array=b.get("queue",[]);var count=owner_count(str(b.owner));var cycle=18.0-int(b.upgrades.production)*1.5
   canvas.draw_rect(Rect2(p+Vector2(-100,109),Vector2(200,5)),Color("#283d48"));canvas.draw_rect(Rect2(p+Vector2(-100,109),Vector2(200*clampf(1-float(b.timer)/cycle,0,1),5)),Color("#8ccbd8"))
   var pending="Next march: %ds" % ceili(maxf(0,float(b.timer)))
   if not queue.is_empty():pending=("Army full • waiting: " if count>=24 else "Recruiting: ")+str(LABELS[int(queue[0])])
   canvas.draw_string(font,p+Vector2(-150,133),pending,HORIZONTAL_ALIGNMENT_CENTER,300,14,Color("#e3d9b4"))
   canvas.draw_string(font,p+Vector2(-150,151),"%d / 24 active • %d queued" % [count,queue.size()],HORIZONTAL_ALIGNMENT_CENTER,300,13,Color("#b4d0d1"))
 var middle:=SIZE*.5-cam
 canvas.draw_circle(middle,150,Color(.2,.42,.46,.2))
 canvas.draw_rect(Rect2(middle-Vector2(90,20),Vector2(180,65)),Color("#8c714b"))
 canvas.draw_colored_polygon(PackedVector2Array([middle+Vector2(-105,-30),middle+Vector2(-80,-85),middle+Vector2(80,-85),middle+Vector2(105,-30)]),Color("#d1c294"))
 for n in 6:canvas.draw_rect(Rect2(middle+Vector2(-80+n*28,-85),Vector2(14,55)),Color("#698b83"))
 for x in [-90,90]:canvas.draw_line(middle+Vector2(x,-35),middle+Vector2(x,50),Color("#8d7657"),6)
 for n in 5:canvas.draw_circle(middle+Vector2(-60+n*30,-10),7,Color("#8ed0d2") if n%2 else Color("#e0b888"))
 canvas.draw_circle(middle+Vector2(0,-46),11,Color("#c5b494"));canvas.draw_rect(Rect2(middle+Vector2(-10,-37),Vector2(20,21)),Color("#648384"))
 canvas.draw_string(font,middle+Vector2(-150,-105),"CENTRAL MARKET • E",HORIZONTAL_ALIGNMENT_CENTER,300,21,Color("#ffe6a2"))
 for u in draw_units.values():
  if visible.has_point(u.pos):
   var point:Vector2=u.pos
   if view.is_empty():point=Vector2(float(u.get("last_x",point.x)),float(u.get("last_y",point.y))).lerp(point,clampf((clock-float(u.get("sample_time",clock)))/.1,0,1))
   var visual=u.duplicate()
   if view.is_empty():visual.walk=lerpf(float(u.get("last_walk",u.get("walk",0))),float(u.get("walk",0)),clampf((clock-float(u.get("sample_time",clock)))/.1,0,1))
   draw_unit(canvas,visual,point-cam,draw_clock)
 for s in draw_shots:
  if visible.has_point(s.pos):canvas.draw_circle(s.pos-cam,8 if float(s.radius)>0 else 4,Color("#ffca73") if int(s.team)==0 else Color("#eb8eab"))
 for b in draw_bombs:
  var p:Vector2=b.pos-cam;var colour:=Color(1,.25,.14,.25+.2*absf(sin(draw_clock*8)))
  canvas.draw_circle(p,float(b.radius),colour);canvas.draw_arc(p,float(b.radius),0,TAU,40,Color("#ff9d65"),3)
  canvas.draw_line(p-Vector2(20,0),p+Vector2(20,0),Color.WHITE,2);canvas.draw_line(p-Vector2(0,20),p+Vector2(0,20),Color.WHITE,2)
  canvas.draw_circle(p-Vector2(0,maxf(0,float(b.time))*150),10,Color("#282a2c"))
func player_name(id:String)->String:
 for member in game.roster:
  if str(member.id)==id:return str(member.name)
 return "Barracks"
func draw_unit(c:Node2D,u:Dictionary,p:Vector2,draw_clock:float=-1)->void:
 preload("res://scripts/battleground_art.gd").draw_unit(c,u,p,clock if draw_clock<0 else draw_clock)
func draw_hud(c:Node2D)->void:
 var font:=ThemeDB.fallback_font
 c.draw_rect(Rect2(20,100,860,38),Color(.04,.1,.14,.9))
 c.draw_string(font,Vector2(32,126),"BATTLEGROUNDS • "+MAPS.get(map_id,"Front")+" • Hearts "+str(int(heart_hp[0]))+" : "+str(int(heart_hp[1]))+" • "+str(units.size())+" troops",HORIZONTAL_ALIGNMENT_LEFT,880,21,Color("#ffe2a3"))
 c.draw_string(font,Vector2(24,game.VIEW.y-120),"Destroy barracks, then the heart. E at your barracks: recruit / upgrade. E in the middle: items.",HORIZONTAL_ALIGNMENT_LEFT,1100,14,Color("#efdfb7"))
 var area:=Rect2(game.VIEW.x-225,145,200,130);c.draw_rect(area,Color(.03,.1,.14,.85))
 for b in bases.values():c.draw_rect(Rect2(area.position+(b.pos/SIZE)*area.size-Vector2(3,3),Vector2(6,6)),Color("#75cced") if int(b.team)==0 else Color("#ef9270"))
 for u in units.values():c.draw_circle(area.position+(u.pos/SIZE)*area.size,1.5,Color("#75cced") if int(u.team)==0 else Color("#ef9270"))
 for id in game.positions:
  if game.adventure.combat.visible_owner(str(id)):c.draw_circle(area.position+(game.positions[id]/SIZE)*area.size,3,Color.WHITE if id==game.my_id else Color("#78cbea") if int(game.teams.get(id,0))==0 else Color("#eea57a"))

func level_up(id:String)->void:
 while int(game.levels.get(id,1))<10:
  var target:=5+int(game.levels.get(id,1))*3
  if int(game.xp.get(id,0))<target:break
  game.xp[id]=int(game.xp[id])-target;game.levels[id]=int(game.levels[id])+1

func convert(owner:String,key:String)->void:
 if not units.has(key) or side_of(owner)==int(units[key].team) or not game.positions.has(owner):return
 var u:Dictionary=units[key]
 if (game.positions[owner] as Vector2).distance_to(u.pos)>380:return
 for other in units.keys():
  if bool(units[other].get("converted",false)) and str(units[other].owner)==owner:units.erase(other)
 reward(owner,12+int(u.kind)*2,8)
 u.owner=owner;u.team=side_of(owner);u.converted=true;u.expires=8.0;u.hp=minf(float(u.hp),90);u.max_hp=minf(float(u.max_hp),90)
 game._emit_effect({"pos":u.pos,"radius":55.0,"time":.6,"color":"#aaedbe"})

func help()->void:
 game.presentation.window("BATTLEGROUNDS • Build an army together","battlegrounds_help")
 for line in ["1 • Host a 3v3 or 4v4 room. Tap a team side; both teams must be full before Start.","2 • You own one barracks. It sends two foot soldiers every 18 seconds. Visit it with E to add recruits or upgrade the army.","3 • CC arrives steadily; kills earn extra CC and hero XP. Build more troops, improve their stats, or buy hero items.","4 • Healers support your frontline. Archers and scouts keep their distance; catapults and mages deal splash damage. Mix roles with teammates.","5 • The only item market is at the map's centre. Fight for access. Your hero respawns after seven seconds.","6 • Destroy every opposing barracks to remove the heart's shield, then destroy the heart to win.","IRON RAIN • Orange floor circles warn of incoming bombs. They hit both armies and both teams. Move out before impact."]:
  game.presentation.label(game.presentation.content,line,20)
 game.presentation.label(game.presentation.content,"Army limit: 24 active troops per player. All eight unit types can be recruited together. Upgrades last for this match; hero mastery is retained.",17)

func rebuild_unit_grid()->void:
 unit_grid_dirty=false;unit_grid.clear()
 for key in units:
  var p:Vector2=units[key].pos;var cell:=Vector2i(floori(p.x/256),floori(p.y/256))
  if not unit_grid.has(cell):unit_grid[cell]=[]
  unit_grid[cell].append(key)
func nearby_units(p:Vector2,radius:float)->Array:
 var result:Array=[];var reach:=radius+24
 for x in range(floori((p.x-reach)/256),floori((p.x+reach)/256)+1):
  for y in range(floori((p.y-reach)/256),floori((p.y+reach)/256)+1):result.append_array(unit_grid.get(Vector2i(x,y),[]))
 return result

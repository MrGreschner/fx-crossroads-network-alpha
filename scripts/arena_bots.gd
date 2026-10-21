extends Node
## Three fixed kits keep bot simulation predictable and inexpensive. Host only.
const Brain=preload("res://scripts/combat_brain.gd")
const IDS=["npc_sable","npc_bastion","npc_cinder","npc_lumen","npc_thorn","npc_iona","npc_flint"]
const ROLES=["Duelist","Bulwark","Caster","Healer","Vanguard","Ranger","Artillery"]
const NAMES=["Sable Voss","Brass Bastion","Cinder Oracle","Lumen Vale","Thorn Reedwarden","Iona Stormglass","Flint Gearwright"]
var game:Node
var states:Dictionary={}
var damage_seen:=0.0
static func difficulty(value:Variant)->String:return str(value) if str(value) in ["easy","medium","hard"] else "medium"
func is_bot(id:String)->bool:return id.begins_with("bot:")
func setup(g:Node)->void:
 game=g
 for n in IDS.size():
  game.characters[IDS[n]]=game._json("res://content/npc_heroes/"+IDS[n]+".json")
  for pose in ["idle","walk1","walk2","attack"]:game.art[IDS[n]+"_"+pose]=preload("res://scripts/source_art.gd").texture("res://assets/"+IDS[n]+"_"+pose+".svg")
static func clean_plan(value:Variant)->Array:
 if not value is Array or value.size()>7:return []
 var result=[]
 for entry in value:
  if not entry is Dictionary or str(entry.get("hero","")) not in IDS:return []
  var side=entry.get("team")
  if not (side is int or side is float) or not is_finite(float(side)) or float(side)!=floorf(float(side)) or int(side) not in [0,1]:return []
  result.append({"hero":str(entry.hero),"team":int(entry.team)})
 return result
func sync_lobby()->void:
 if game.role!="host":return
 var plan=game.bot_plan
 if not preload("res://network/party_rules.gd").allows_ai(game.mode):plan=[];game.bot_plan=[];game.bot_count=0
 if plan.is_empty() and game.bot_count>0:
  for n in mini(7,game.bot_count):plan.append({"hero":IDS[n%IDS.size()],"team":(n+1)%2 if game.mode in ["arena","battlegrounds"] else 0})
 game.bot_count=plan.size()
 for index in range(game.roster.size()-1,-1,-1):
  var id=str(game.roster[index].id)
  if is_bot(id) and int(id.trim_prefix("bot:"))>=plan.size():
   game.roster.remove_at(index)
   for mapping in [game.positions,game.health,game.hero_ids,game.lobby_heroes,game.lobby_builds,game.teams,states]:mapping.erase(id)
 for n in plan.size():
  var id="bot:"+str(n);var hero=str(plan[n].hero);var label=NAMES[IDS.find(hero)]+" [AI]"
  var found=false
  for member in game.roster:
   if str(member.id)==id:member.name=label;found=true
  if not found:game.roster.append({"id":id,"name":label})
  if not game.positions.has(id):game._add_player(id,game.fighters().size()-1)
  game.hero_ids[id]=hero;game.lobby_heroes[id]=hero;game.lobby_builds[id]={};game.teams[id]=int(plan[n].team) if game.mode in ["arena","battlegrounds"] else 0
func reset()->void:states.clear();damage_seen=0
func practice_progress()->void:
 if game.spectating() or bool(game.legacy.data.teacher):return
 var total:=float(game.contributions.get(game.my_id,{}).get("damage",0))
 var added:=maxf(0,total-damage_seen);damage_seen=maxf(damage_seen,total)
 if added>0:
  var record:Dictionary=game.legacy.record(str(game.hero_ids.get(game.my_id,game.selected_hero)))
  record.damage=float(record.damage)+added
func step(delta:float)->void:
 if game.role!="host" or not game.started or game.start_countdown>0:return
 for n in game.bot_count:
  var id="bot:"+str(n)
  if not game.positions.has(id) or int(game.health.get(id,0))<=0:states.erase(id);continue
  if game.arena_world.shatter.active():
   var shatter_state:Dictionary=states.get(id,{})
   states[id]=shatter_state;game.arena_world.shatter.bot_step(id,delta,shatter_state);continue
  var combat:Node=game.adventure.combat
  if combat.stunned("p:"+id):continue
  var state:Dictionary=states.get(id,{"think":.1+n*.045,"wish":Vector2.ZERO,"side":1.0 if n%2 else -1.0,"dash_cd":2.0,"dash":0.0,"shop":0.0})
  states[id]=state;state.think-=delta;state.dash_cd=maxf(0,state.dash_cd-delta);state.shop=maxf(0,state.shop-delta)
  var origin:Vector2=game.positions[id];var kit:Dictionary=game.characters[game.hero_ids[id]]
  var hard=game.ai_difficulty=="hard";var easy=game.ai_difficulty=="easy"
  if state.think<=0:
   state.think=.22 if hard else .65 if easy else .38
   var near=origin;var distance=INF;var target=""
   var options=[]
   if game.mode in ["arena","battlegrounds"]:
    for other in game.positions:
     if game._rival(id,str(other)) and game.arena_world.extra.can_see(id,game.positions[other]) and Time.get_ticks_msec()>=int(game.stealth_until.get(other,0)):options.append({"id":str(other),"pos":game.positions[other]})
   else:
    for enemy in game.opponents:
     if float(enemy.hp)>0:options.append({"id":"enemy:"+str(enemy.get("uid",0)),"pos":enemy.pos})
   if game.mode=="battlegrounds":
    for key in game.battlegrounds.hostile(id):
     var actor=game.battlegrounds.actor(key)
     if not actor.is_empty():options.append({"id":key,"pos":actor.pos})
   for candidate in options:
    var d=origin.distance_to(candidate.pos)
    if d<distance:distance=d;near=candidate.pos;target=str(candidate.id)
   var ally_goal=origin;var ally_distance=INF;var wounded=false
   for other in game.positions:
    if str(other)==id or game.mode in ["arena","battlegrounds"] and game._rival(id,str(other)):continue
    if int(game.health.get(other,0))>0:
     var d=origin.distance_to(game.positions[other])
     if d<ally_distance:ally_distance=d;ally_goal=game.positions[other]
     if d<250 and float(game.health[other])/maxf(1,game._max_hp(str(other)))<.7:wounded=true
   var neighbours=[]
   for other in game.positions:
    if str(other)!=id:neighbours.append(game.positions[other])
   var melee=str(kit.primary.style) in ["melee","kick","spin"]
   var wish=Brain.spacing(origin,near,60 if melee else 220,115 if melee else 360,float(game.health[id])/maxf(1,game._max_hp(id)),state.side) if target!="" else (ally_goal-origin).normalized() if ally_distance>200 and ally_distance<INF else Vector2.ZERO
   if game.mode not in ["arena","battlegrounds"] and distance>850 and ally_distance>260 and ally_distance<INF:wish=(ally_goal-origin).normalized()
   game.revive_held[id]=false
   if game.mode not in ["arena","battlegrounds"]:
    for other in game.downed:
     if not game.positions.has(other):continue
     var offset:Vector2=game.positions[other]-origin
     if offset.length()<500:
      wish=offset.normalized() if offset.length()>90 else Vector2.ZERO;game.revive_held[id]=offset.length()<130;break
   if game.mode=="battlegrounds":wish=strategy(id,origin,wish,state)
   if game.arena_world.objective.active():
    var goal=game.arena_world.objective.bot_goal(id,origin,near,state)
    wish=(goal-origin).normalized() if origin.distance_to(goal)>35 else Vector2.ZERO
   var danger=false
   for shot in game.missiles:
    if str(shot.owner)==id or game.positions.has(shot.owner) and (game.mode not in ["arena","battlegrounds"] or not game._rival(id,str(shot.owner))):continue
    var offset:Vector2=origin-shot.pos
    if offset.length()<170 and (shot.direction as Vector2).dot(offset.normalized())>.88:danger=true;break
   if danger and state.dash_cd<=0:
    state.dash=.18;state.dash_cd=8.0 if easy else 4.0;wish=(near-origin).normalized().orthogonal()*float(state.side);game.invincible_until[id]=Time.get_ticks_msec()+160
   state.wish=Brain.steer(origin,wish,game._clear_path,neighbours,state.side)
   if game.mode=="arena" and game.arena_world.extra.active():state.wish=game.arena_world.extra.bot_wish(id,origin,state.wish,near)
   var aim=(near-origin).normalized().rotated(sin(game.run_time+n)*(.15 if easy else .04))
   game.aim_angles[id]=aim.angle()
   if target!="" and game._clear_path(origin,near):
    if distance<float(kit.primary.range)-8:game._attack(id,"primary",aim,near)
    if str(kit.secondary.style)=="heal_wave":
     if wounded or float(game.health[id])/game._max_hp(id)<.65:game._attack(id,"secondary",aim,near)
    elif str(kit.secondary.style)=="block":
     if danger or distance<180:game._attack(id,"secondary",aim,near)
    elif distance<float(kit.secondary.get("range",450)):game._attack(id,"secondary",aim,near)
    if str(kit.special.style)=="heal_wave":
     if wounded:game._attack(id,"special",aim,near)
    elif distance<float(kit.special.get("range",450)) and (str(kit.special.style)!="charge" or distance>100):game._attack(id,"special",aim,near)
   elif str(kit.get("ai_role",""))=="healer" and (wounded or float(game.health[id])/game._max_hp(id)<.65):game._attack(id,"special",Vector2.RIGHT,ally_goal)
  if game.charges.has(id):continue
  var speed=float(kit.speed)*combat.speed_factor("p:"+id)*game.arena_world.slow(origin)*game.arena_world.objective.carrier_factor(id)*(.9 if easy else 1.0)
  if state.dash>0:speed=520*game.arena_world.objective.carrier_factor(id);state.dash=maxf(0,state.dash-delta)
  game.positions[id]=game._move_actor(origin,(state.wish as Vector2)*speed*delta)
func strategy(id:String,origin:Vector2,wish:Vector2,state:Dictionary)->Vector2:
 var bg=game.battlegrounds;var base:Dictionary=bg.bases.get(bg.owners.get(id,""),{})
 if base.is_empty():return wish
 var low=float(game.health[id])/game._max_hp(id)<.3
 var budget=int(game.gold.get(id,0));var at_base=origin.distance_to(base.pos)<220
 var choices=["unit:archer","unit:healer","production","unit:catapult","unit:tank","vitality","ranged","melee","unit:lancer","unit:standard" if int(base.team)==0 else "unit:mossbinder"]
 var affordable=false
 for key in choices:
  var k=bg.TYPES.find(str(key).trim_prefix("unit:"))
  var capped=int(base.counts[k])>=(6 if k==0 else 3) if k>=0 else int(base.upgrades[key])>=4
  if not capped and budget>=bg.price(base,key):affordable=true
 if float(base.hp)>0 and state.shop<=0 and at_base:
  var start=int(state.get("order",0))
  for i in choices.size():
   var next=(start+i)%choices.size()
   if bg.buy(id,choices[next]):state.order=(next+1)%choices.size();state.shop=15.0;break
 var capital:Vector2=bg.heart_pos(int(base.team));var threat=false
 for enemy in bg.units.values():
  if int(enemy.team)!=int(base.team) and (enemy.pos as Vector2).distance_to(capital)<650:threat=true;break
 var order="capital" if threat else "base" if bg.owner_count(id)<6 else "enemy_base" if int(state.get("order",0))%2==0 else "enemy_capital"
 if bg.clock>float(state.get("command_at",0)):
  bg.command.execute(id,"order:"+order);state.command_at=bg.clock+8
 if low:
  if float(base.hp)>0:bg.command.execute(id,"order:recall")
  return bg.command.direction("hero:"+id,origin,capital)
 if affordable and budget>=400 and state.shop<=0 and float(base.hp)>0 and not at_base:return bg.command.direction("hero:"+id,origin,base.pos)
 if threat:return bg.command.direction("hero:"+id,origin,capital)
 # Defend threatened home barracks before chasing far-away heroes.
 for unit in bg.units.values():
  if int(unit.team)!=int(base.team) and (unit.pos as Vector2).distance_to(base.pos)<500:return bg.command.direction("hero:"+id,origin,unit.pos)
 var destination=bg.heart_pos(1-int(base.team)) if order=="enemy_capital" else bg.command.goal({"owner":id,"team":int(base.team),"lane":int(base.lane),"order":"enemy_base"})
 if origin.distance_to(destination)>450:return bg.command.direction("hero:"+id,origin,destination)
 return wish

extends Node
## Three fixed kits keep bot simulation predictable and inexpensive. Host only.
const Brain=preload("res://scripts/combat_brain.gd")
const IDS=["npc_sable","npc_bastion","npc_cinder"]
const NAMES=["Sable Voss","Brass Bastion","Cinder Oracle"]
var game:Node
var states:Dictionary={}
var damage_seen:=0.0
static func difficulty(value:Variant)->String:return str(value) if str(value) in ["easy","medium","hard"] else "medium"
func is_bot(id:String)->bool:return id.begins_with("bot:")
func setup(g:Node)->void:
 game=g
 for n in 3:
  game.characters[IDS[n]]=game._json("res://content/npc_heroes/"+IDS[n]+".json")
  for pose in ["idle","walk1","walk2","attack"]:game.art[IDS[n]+"_"+pose]=preload("res://scripts/source_art.gd").texture("res://assets/"+IDS[n]+"_"+pose+".svg")
func sync_lobby()->void:
 if game.role!="host":return
 for index in range(game.roster.size()-1,-1,-1):
  var id:=str(game.roster[index].id)
  if is_bot(id) and (game.mode!="arena" or int(id.trim_prefix("bot:"))>=game.bot_count):
   game.roster.remove_at(index)
   for mapping in [game.positions,game.health,game.hero_ids,game.lobby_heroes,game.lobby_builds,game.teams,states]:mapping.erase(id)
 if game.mode!="arena":return
 for n in game.bot_count:
  var id:="bot:"+str(n)
  var exists:=false
  for member in game.roster:
   if str(member.id)==id:exists=true
  if not exists:game.roster.append({"id":id,"name":NAMES[n]+" [AI]"})
  if not game.positions.has(id):game._add_player(id,game.fighters().size()-1)
  game.hero_ids[id]=IDS[n];game.lobby_heroes[id]=IDS[n];game.lobby_builds[id]={}
  if not game.teams.has(id) or int(game.teams[id])<0:game.teams[id]=(n+1)%2
func reset()->void:states.clear();damage_seen=0
func practice_progress()->void:
 if game.spectating() or bool(game.legacy.data.teacher):return
 var total:=float(game.contributions.get(game.my_id,{}).get("damage",0))
 var added:=maxf(0,total-damage_seen);damage_seen=maxf(damage_seen,total)
 if added>0:
  var record:Dictionary=game.legacy.record(str(game.hero_ids.get(game.my_id,game.selected_hero)))
  record.damage=float(record.damage)+added
func step(delta:float)->void:
 if game.mode!="arena" or game.role!="host" or not game.started or game.start_countdown>0:return
 for n in game.bot_count:
  var id:="bot:"+str(n)
  if not game.positions.has(id) or int(game.health.get(id,0))<=0:states.erase(id);continue
  var combat:Node=game.adventure.combat
  if combat.stunned("p:"+id):continue
  var state:Dictionary=states.get(id,{"think":.18+n*.04,"target":"","wish":Vector2.ZERO,"dash":0.0,"dash_cd":2.0,"observed":Vector2.ZERO,"velocity":Vector2.ZERO,"ability_cd":0.0,"side":1.0 if n%2 else -1.0})
  states[id]=state;state.think=float(state.think)-delta;state.dash_cd=maxf(0,float(state.dash_cd)-delta)
  state.ability_cd=maxf(0,float(state.get("ability_cd",0))-delta)
  var origin:Vector2=game.positions[id]
  var hard:bool=game.ai_difficulty=="hard"
  var easy:bool=game.ai_difficulty=="easy"
  var reaction:float=.18 if hard else .65 if easy else .36
  if float(state.think)<=0:
   state.think=reaction
   var best:="";var score:=-INF
   for other in game.positions:
    if not game._rival(id,str(other)) or Time.get_ticks_msec()<int(game.stealth_until.get(other,0)):continue
    var distance:float=origin.distance_to(game.positions[other])
    var value:float=1000-distance+(120 if str(other)==str(state.target) else 0)
    if value>score:score=value;best=str(other)
   if best.is_empty():state.wish=Vector2.ZERO;state.target="";continue
   var goal:Vector2=game.positions[best]
   state.velocity=(goal-(state.observed as Vector2))/reaction if best==str(state.target) else Vector2.ZERO
   state.observed=goal;state.target=best
   var distance:=origin.distance_to(goal)
   var visible:bool=game._clear_path(origin,goal)
   var wish:Vector2=Brain.spacing(origin,goal,55 if n==1 else 230,85 if n==1 else 370,float(game.health[id])/game._max_hp(id),float(state.side))
   var neighbours:Array=[]
   for other in game.positions:
    if str(other)!=id and int(game.health.get(other,0))>0:neighbours.append(game.positions[other])
   state.wish=Brain.steer(origin,wish,game._clear_path,neighbours,float(state.side))
   var danger:=false
   for shot in game.missiles:
    if str(shot.owner)==id or game.positions.has(shot.owner) and not game._rival(id,str(shot.owner)):continue
    var offset:Vector2=origin-shot.pos
    if offset.length()<190 and (shot.direction as Vector2).dot(offset.normalized())>.86:danger=true;break
   if not danger:
    for shot in combat.projectiles:
     if str(shot.owner)==id or game.positions.has(shot.owner) and not game._rival(id,str(shot.owner)):continue
     var offset:Vector2=origin-combat.vec(shot.pos)
     if offset.length()<190 and combat.vec(shot.get("aim",[0,0])).dot(offset.normalized())>.86:danger=true;break
   for warning in game.arena_world.warnings:
    var center:Vector2=game.arena_world.point(warning.pos)
    var escape:Vector2=origin-center
    if str(warning.kind)=="stripe":
     var distance_to_line:float=absf(escape.x if bool(warning.vertical) else escape.y)
     if distance_to_line>100:continue
     escape=Vector2(1 if escape.x>=0 else -1,0) if bool(warning.vertical) else Vector2(0,1 if escape.y>=0 else -1)
    elif escape.length()>float(warning.radius)+35:continue
    if escape.is_zero_approx():escape=Vector2.RIGHT
    state.wish=Brain.steer(origin,escape.normalized(),game._clear_path,neighbours,float(state.side));break
   if danger and float(state.dash_cd)<=0:
    state.dash=.22;state.dash_cd=3.5 if hard else 9.0 if easy else 6.0;state.wish=Brain.steer(origin,(goal-origin).normalized().orthogonal()*float(state.side),game._clear_path,neighbours,float(state.side))
    game.invincible_until[id]=Time.get_ticks_msec()+180
    game._emit_effect({"pos":origin,"end":origin+(state.wish as Vector2)*110,"style":"line","color":"#acd7dc","time":.25})
   if visible:
    var predicted:Vector2=Brain.lead(origin,goal,(state.velocity as Vector2)*(.95 if hard else .1 if easy else .5),420)
    var aim:Vector2=(predicted-origin).normalized().rotated(sin(game.run_time*2+n)*(.025 if hard else .23 if easy else .11))
    var kit:Dictionary=game.characters[IDS[n]]
    # Defensive reactions, closers and area attacks have distinct utilities.
    if not easy or float(state.ability_cd)<=0:
     if n==1 and (danger or distance<150) and float(game.health[id])/game._max_hp(id)<.65:game._attack(id,"secondary",aim,goal)
     elif n!=1 and distance<500:game._attack(id,"secondary",aim,predicted)
     if (n==1 and distance>110 and distance<350) or (n!=1 and distance<470):game._attack(id,"special",aim,predicted)
     state.ability_cd=2.5 if easy else 0.0
    if distance<float(kit.primary.range)-15:game._attack(id,"primary",aim,predicted)
  if game.charges.has(id):continue
  var speed:float=float(game.characters[IDS[n]].speed)*combat.speed_factor("p:"+id)*game.arena_world.slow(origin)
  if game.ai_difficulty=="easy":speed*=.9
  if float(state.dash)>0:speed=560;state.dash=maxf(0,float(state.dash)-delta)
  game.positions[id]=game._move_actor(origin,(state.wish as Vector2)*speed*delta)

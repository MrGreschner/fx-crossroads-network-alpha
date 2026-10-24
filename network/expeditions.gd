extends Node
const C=preload("res://scripts/waylight_catalog.gd")
const Profile=preload("res://network/expedition_profile.gd")
const Layout=preload("res://scripts/waylight_expedition.gd")
var game:Node2D
var conclave=preload("res://scripts/roaming_conclave.gd").new()
var kind=""
var config={}
var expedition=Layout.new()
var relics=preload("res://network/expedition_relics.gd").new()
var offers={}
var events=[]
var warnings=[]
var visuals=[]
var modifier=0
var surge_timer=6.0
var stream_clock=0.0
var clock=0.0
var revision=0
var received_revision=-1
var fog_rows=[]
var fog_dirty=true
var current_killer=""
var outcome={}
var settlement=""
var initialized=false
var events_planned=false
func setup(g:Node2D)->void:
 game=g;expedition.manager=self;relics.game=g
 game.realm_picker.add_item("The Between");game.realm_picker.set_item_metadata(game.realm_picker.item_count-1,"between")
 preload("res://scripts/between_actors.gd").install(game,true)
 preload("res://scripts/veilbound_pursuers.gd").install(game,true)
 game.regions.between=JSON.parse_string(FileAccess.get_file_as_string("res://content/regions/between.json"))
 for pair in [["waylight_reed","reed_stalker"],["waylight_crab","sluice_crab"]]:
  var def:Dictionary=game.enemy_defs.get(pair[1],{}).duplicate(true);def.id=pair[0];game.enemy_defs[pair[0]]=def
  for pose in ["idle","walk1","walk2","attack"]:game.art[str(pair[0])+"_"+pose]=game.art.get(str(pair[1])+"_"+pose)
func special()->bool:return kind in ["between","attunement","overcharge"]
func between()->bool:return kind in ["between","attunement"]
func ticket()->Dictionary:return {"seed":int(config.get("seed",1)),"tier":int(config.get("tier",1)),"layout_version":int(config.get("layout_version",3)),"depth":int(config.get("depth",6))}
func pack(v:Variant)->Variant:return v
func configure(data:Dictionary)->void:
 events_planned=false
 conclave.setup(game,true,int(data.get("seed",1)),int(data.get("tier",1)))
 config=data.duplicate(true);kind=str(config.get("kind",""));initialized=false;outcome={};settlement="";events=[];warnings=[];visuals=[];offers=config.get("offers",{});relics.setup(game,offers)
 expedition.chunks.clear();expedition.dead.clear();expedition.collected.clear();expedition.sleeping.clear();expedition.explored.clear();expedition.carried=0;expedition.farthest=0;expedition.guardian=false;expedition.current=Vector2i.ZERO
 revision=0;received_revision=-1;fog_rows=[];fog_dirty=true;stream_clock=0;clock=0;surge_timer=6;modifier=posmod(int(config.get("seed",1)),3)
func start()->void:
 if not special() or initialized:return
 initialized=true
 game.status_label.text="Explore together; return to the entrance to bank your shared haul." if between() else "Defeat the guardian, then use the exit. Watch for marked surges."
 if between():stream(game.dedicated)
 elif game.dedicated:
  plan_events()
  scale_foes()
func plan_events()->void:
 if events_planned or game.opponents.is_empty():return
 events_planned=true
 var foes=game.opponents.duplicate()
 for n in 2:
  if foes.is_empty():break
  var at:Vector2=foes[mini(foes.size()-1,int(foes.size()*(.35+n*.35)))].pos
  if at.distance_to(game.positions.values()[0])<350:continue
  if not events.is_empty() and at.distance_to(events[0].at)<300:continue
  events.append({"at":at,"type":posmod(int(config.seed)+n,3),"state":"waiting","progress":0.0,"id":n})
func active_points()->Array:
 var out=[]
 for id in game.positions:
  if int(game.health.get(id,0))>0:out.append(game.positions[id])
 return out
func stream(authority:bool)->void:
 var points=active_points()
 if points.is_empty():return
 var wanted={};var active={};var centers=[]
 for point in points:
  var here=expedition.cell_at(point);centers.append(here)
  if authority:expedition.farthest=maxi(expedition.farthest,maxi(absi(here.x),absi(here.y)))
  for y in range(here.y-2,here.y+3):
   for x in range(here.x-2,here.x+3):
    if maxi(absi(x),absi(y))>expedition.max_ring():continue
    var cell=Vector2i(x,y);wanted[expedition.key(cell)]=cell
    if maxi(absi(x-here.x),absi(y-here.y))<=1:active[expedition.key(cell)]=true
 for key in expedition.chunks.keys():
  if not wanted.has(key):expedition.chunks.erase(key)
 for key in wanted:
  if not expedition.chunks.has(key):expedition.chunks[key]=expedition.layout(wanted[key])
 if not authority:return
 for n in range(game.opponents.size()-1,-1,-1):
  var foe:Dictionary=game.opponents[n]
  if bool(foe.get("veilbound",false)):continue
  if not active.has(expedition.key(expedition.cell_at(foe.pos))):
   if foe.has("between_id"):expedition.sleeping[str(foe.between_id)]=foe.duplicate(true)
   game.opponents.remove_at(n)
 var present={}
 for foe in game.opponents:present[str(foe.get("between_id",""))]=true
 var order=active.keys()
 order.sort_custom(func(a,b):return nearest_cell(wanted[a],centers)<nearest_cell(wanted[b],centers))
 for key in order:
  var data:Dictionary=expedition.chunks[key]
  for entry in data.foes:
   var id=str(entry.id)
   if expedition.dead.has(id):continue
   if present.has(id):
    if bool(entry.boss):
     for existing in game.opponents:
      if str(existing.get("between_id",""))==id:preload("res://scripts/between_guardians.gd").configure(existing,int(data.theme));break
    continue
   if game.opponents.size()>=64:continue
   var foe:Dictionary=expedition.sleeping.get(id,{})
   if not foe.is_empty():expedition.sleeping.erase(id)
   else:
    var pos=Vector2(entry.pos[0],entry.pos[1]);var type=str(entry.type)
    if not expedition.open(pos):pos=data.center
    if bool(entry.boss):type=preload("res://scripts/between_guardians.gd").TYPES[int(data.theme)]
    var hp=(240.0 if entry.boss else float(game.enemy_defs.get(type,{}).get("health",65)))*(1+float(data.ring)*.18)*1.55
    foe={"pos":pos,"hp":hp,"max_hp":hp,"type":type,"boss":bool(entry.boss),"uid":abs(hash(str(config.id)+id)),"attack_timer":1.2,"secondary_timer":3.5,"windup":0.0,"skill_timer":2.0,"skill_step":0,"between_id":id,"ring":int(data.ring)}
   if bool(entry.boss):preload("res://scripts/between_guardians.gd").configure(foe,int(data.theme))
   game.opponents.append(foe);present[id]=true
func nearest_cell(cell:Vector2i,centers:Array)->int:
 var nearest=100
 for center in centers:nearest=mini(nearest,maxi(absi(cell.x-center.x),absi(cell.y-center.y)))
 return nearest
func reveal()->void:
 for point in active_points():
  var cell=Vector2i(point/96)
  for y in range(cell.y-4,cell.y+5):
   for x in range(cell.x-4,cell.x+5):
    var key=expedition.key(Vector2i(x,y))
    if Vector2(x*96+48,y*96+48).distance_to(point)<365 and not expedition.explored.has(key):expedition.explored[key]=true;fog_dirty=true
 if fog_dirty:revision+=1;fog_dirty=false;fog_rows=encode_fog()
func encode_fog()->Array:
 var rows={};var result=[]
 for key in expedition.explored:
  var parts=str(key).split(",");var x=int(parts[0]);var y=int(parts[1])
  if not rows.has(y):rows[y]=[]
  rows[y].append(x)
 for y in rows:
  var xs:Array=rows[y];xs.sort();var first=int(xs[0]);var last=first
  for n in range(1,xs.size()):
   if int(xs[n])==last+1:last=int(xs[n])
   else:result.append([int(y),first,last]);first=int(xs[n]);last=first
  result.append([int(y),first,last])
 return result
func step(dt:float)->void:
 if not special() or not game.started:return
 clock+=dt;stream_clock+=dt
 if not game.dedicated:
  if between():
   if stream_clock>=.18:stream_clock=0;stream(false)
   expedition.pulse+=dt;expedition.reveal=1.0;expedition.current=expedition.cell_at(game.local_pos)
  return
 relics.step(dt)
 if between():
  if stream_clock>=.18:stream_clock=0;stream(true);reveal()
  for key in expedition.chunks:
   var d:Dictionary=expedition.chunks[key]
   if int(d.ring)==0 or expedition.collected.has(key):continue
   var near=false
   for p in active_points():
    if p.distance_to(d.crystal)<68:near=true;break
   if not near:continue
   var guarded=false
   for foe in game.opponents:
    if foe.pos.distance_to(d.crystal)<230:guarded=true;break
   if not guarded:expedition.collected[key]=true;expedition.carried+=Layout.deposit_value(int(d.ring));game.status_label.text="Gathered Waylight • %d shared. Return together to extract." % expedition.carried
 else:step_overcharge(dt)
func defeated(foe:Dictionary)->void:
 if not special():return
 relics.killed(current_killer)
 if kind=="overcharge":conclave.defeated(foe)
 if not between() or not foe.has("between_id") or bool(foe.get("summoned",false)) or bool(foe.get("converted",false)):return
 var id=str(foe.between_id)
 if expedition.dead.has(id):return
 expedition.dead[id]=true;expedition.sleeping.erase(id);expedition.carried+=8 if bool(foe.boss) else 1
 if id.ends_with(":trial"):expedition.guardian=true
 for player in game.positions:
  var xp=(50 if foe.boss else 10)-(12 if foe.boss else 1) if str(player)==current_killer else 50 if foe.boss else 10
  game.xp[player]=int(game.xp.get(player,0))+xp
  while int(game.levels.get(player,1))<10 and int(game.xp[player])>=5+int(game.levels[player])*3:
   game.xp[player]-=5+int(game.levels[player])*3;game.levels[player]+=1
func interact(id:String)->bool:
 if not between():return false
 if not game.positions.has(id) or game.positions[id].distance_to(Layout.ORIGIN)>=130:return false
 for actor in game.positions:
  if int(game.health.get(actor,0))<=0 or game.positions[actor].distance_to(Layout.ORIGIN)>=150:
   game.status_label.text="Bring both living players back to the entrance to extract together.";return true
  if game.gateway!=null and game.gateway.identities.has(actor) and int(game.gateway.identities[actor].connection)<0:game.status_label.text="Waiting for your partner to reconnect before extraction.";return true
 game.end_match("Expedition extracted • shared Waylight banked");return true
func scale_foes()->void:
 for foe in game.opponents:
  if foe.get("waylight_scaled",false):continue
  var factor=[1.25,1.6,2.0][int(config.tier)-1]+(.1 if modifier==2 else 0)
  foe.hp=float(foe.hp)*factor;foe.max_hp=float(foe.max_hp)*factor;foe.waylight_scaled=true
func step_overcharge(dt:float)->void:
 plan_events();conclave.step(dt)
 scale_foes();surge_timer-=dt
 for event in events:
  var near=INF
  for point in active_points():near=minf(near,point.distance_to(event.at))
  if event.state=="waiting" and near<350:
   event.state="active"
   for n in range(4 if int(event.type)==2 else 3):
    if game.opponents.size()>=64:break
    var pos:Vector2=event.at+Vector2.from_angle(n*TAU/4)*100
    if not game._clear_path(pos,pos):pos=event.at
    game.adventure.spawn("bramble" if game.realm_id=="grove" else "imp" if game.realm_id=="quarry" else "frostling",pos,95*1.3,false)
    game.opponents[-1].waylight_event=int(event.id);game.opponents[-1].summoned=true
  if event.state!="active":continue
  var remaining=game.opponents.filter(func(foe):return int(foe.get("waylight_event",-1))==int(event.id)).size()
  if remaining==0 and int(event.type)==1 and near<160:event.progress=float(event.progress)+dt
  if remaining==0 and (int(event.type)!=1 or float(event.progress)>=12):event.state="complete"
 if surge_timer<=0:
  surge_timer=9
  for point in active_points():
   var boss=game.opponents.any(func(foe):return bool(foe.boss) and foe.pos.distance_to(point)<650)
   if boss or modifier==0 and not game.opponents.is_empty():warnings.append({"at":point,"time":1.2,"radius":72.0})
 for n in range(warnings.size()-1,-1,-1):
  var warning:Dictionary=warnings[n];warning.time-=dt
  if float(warning.time)<=0:
   warnings.remove_at(n)
   for id in game.positions:
    if game.positions[id].distance_to(warning.at)<float(warning.radius):game._hurt(str(id),10+int(config.tier)*3,"enemy","",preload("res://scripts/defeat_credit.gd").hazard("Overcharge surge"))
 if modifier==1:
  for foe in game.opponents:foe.attack_timer=maxf(0,float(foe.get("attack_timer",0))-dt*.12)
func completed_events()->int:return events.filter(func(e):return str(e.state)=="complete").size()
func finish(won:bool)->void:
 if not special() or not outcome.is_empty():return
 outcome={"id":str(config.id),"finished":true,"won":won,"carried":expedition.carried,"farthest":expedition.farthest,"guardian":expedition.guardian,"events":completed_events()}
func snapshot()->Dictionary:
 if not special():return {}
 var state={"id":str(config.id),"kind":kind,"carried":expedition.carried,"farthest":expedition.farthest,"guardian":expedition.guardian,"conclave_complete":conclave.completed(),"conclave":conclave.state,"events":completed_events(),"finished":not outcome.is_empty(),"won":bool(outcome.get("won",false)),"collected":expedition.collected,"fog_revision":revision,"fog":fog_rows,"optional":[],"warnings":[],"visuals":relics.visuals()}
 for e in events:var copy=e.duplicate();copy.at=[e.at.x,e.at.y];state.optional.append(copy)
 for e in warnings:var copy=e.duplicate();copy.at=[e.at.x,e.at.y];state.warnings.append(copy)
 return state
func receive(state:Dictionary)->void:
 if not special() or str(state.get("id",""))!=str(config.id):return
 conclave.restore(state.get("conclave",conclave.state))
 expedition.carried=int(state.get("carried",0));expedition.farthest=int(state.get("farthest",0));expedition.guardian=bool(state.get("guardian",false));expedition.collected=state.get("collected",{}).duplicate()
 if int(state.get("fog_revision",0))!=received_revision:
  received_revision=int(state.get("fog_revision",0));expedition.explored.clear()
  for row in state.get("fog",[]):
   for x in range(int(row[1]),int(row[2])+1):expedition.explored[expedition.key(Vector2i(x,int(row[0])))]=true
  expedition.fog_camera=Vector2.INF
 events=state.get("optional",[]).duplicate(true);warnings=state.get("warnings",[]).duplicate(true);visuals=state.get("visuals",[]).duplicate(true)
 for collection in [events,warnings]:
  for e in collection:e.at=Vector2(float(e.at[0]),float(e.at[1]))
 if state.get("finished",false):outcome=state.duplicate(true)
 if between():game.legacy.cosmetics.competitive.explore(str(config.id),expedition.collected)
 var text=Profile.record(game,state)
 if not text.is_empty():settlement=text
func draw_world()->void:
 if kind=="overcharge":conclave.draw_on(game,game.camera)
 for e in events:
  var at:Vector2=e.at-game.camera;game.draw_arc(at,65,0,TAU,24,Color("#9ae0bf") if e.state=="complete" else Color("#cca4e9"),3);game.draw_string(game.font,at+Vector2(-90,88),["Charged pack","Hold the spring","Guardian ritual"][int(e.type)]+(" • complete" if e.state=="complete" else ""),HORIZONTAL_ALIGNMENT_LEFT,-1,14,Color("#e5d3e9"))
 for warning in warnings:game.draw_circle(warning.at-game.camera,float(warning.radius),Color(1,.5,.25,.2));game.draw_arc(warning.at-game.camera,float(warning.radius),0,TAU,32,Color("#ffd397"),3)
 for v in visuals:game.draw_arc(Vector2(float(v.at[0]),float(v.at[1]))-game.camera,float(v.radius),0,TAU,24,Color(v.color),3)
 if between():expedition.draw_fog(game,game.camera)
func draw_hud()->void:
 if not special() or not game.started:return
 var text="THE BETWEEN • %d shared shards • ring %d • return together + E" % [expedition.carried,expedition.farthest] if between() else "OVERCHARGE T%d • %d optional events complete • surges marked on ground" % [int(config.tier),completed_events()]
 if game.mobile.enabled:text="BETWEEN • %d shards • ring %d • return + Interact" % [expedition.carried,expedition.farthest] if between() else "OVERCHARGE T%d • %d bonus events complete" % [int(config.tier),completed_events()]
 if kind=="overcharge" and conclave.state.get("members",[]).size()==4:text="OVERCHARGE T%d • %d events • %s" % [int(config.tier),completed_events(),"CONCLAVE CACHE SECURED • finish realm" if conclave.completed() else "CONCLAVE %d/4 defeated" % conclave.state.get("dead",[]).size()]
 var y=preload("res://scripts/hud_layout.gd").objective_top(game,true)+(60 if kind=="overcharge" and game.adventure.immersive.active else 0)
 game.draw_rect(Rect2(20,y,minf(900,game.VIEW.x-40),31),Color(.03,.08,.12,.94));game.draw_string(game.font,Vector2(30,y+21),text,HORIZONTAL_ALIGNMENT_LEFT,game.VIEW.x-60,16,Color("#d8e9c7"))
 if between():expedition.draw_map(game);game.adventure.pursuers.draw_hud(game)

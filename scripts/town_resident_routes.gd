extends RefCounted
## Deterministic weekly schedules on the shared town calendar; no progression writes.
const N=preload("res://scripts/town_neighborhood.gd")
const ORIGIN=Vector2(-1400,-560)
const CELL=32.0
const JOBS=[
 {"at":Vector2(-180,775),"task":"shop","inside":true,"label":"Market"},
 {"at":Vector2(-1000,2080),"task":"read","inside":true,"label":"Academy"},
 {"at":Vector2(1375,1520),"task":"guard","inside":true,"label":"Ramguard"},
 {"at":Vector2(1006,1640),"task":"water","inside":false,"label":"Seedhouse"},
 {"at":Vector2(2800,655),"task":"deliver","inside":true,"label":"Gatherers' Lodge"},
 {"at":Vector2(2000,2020),"task":"fish","inside":true,"label":"Ripple & Reel"},
 {"at":Vector2(-1080,800),"task":"repair","inside":true,"label":"Deepwell Mine"},
 {"at":Vector2(-530,1375),"task":"read","inside":true,"label":"Studio"}]
# A small subset of the existing residents keeps moving between scheduled events.
# The real clock still drives the town. Paths are cached, never searched each frame.
const DAY_ERRANDS={0:0,4:1,8:2,12:3,16:4}
const NIGHT_ERRANDS={2:0,14:2}
const ERRANDS=[
 [{"at":Vector2(760,850),"task":"shop","label":"Morning provisions"},{"at":Vector2(1180,850),"task":"deliver","label":"Town deliveries"},{"at":Vector2(1470,1180),"task":"rest","label":"Service street"},{"at":Vector2(760,1180),"task":"lunch","label":"Food stand rounds"}],
 [{"at":Vector2(-180,900),"task":"shop","label":"Market errands"},{"at":Vector2(-580,775),"task":"deliver","label":"Market office parcels"},{"at":Vector2(-815,825),"task":"repair","label":"Exchange collection"},{"at":Vector2(-850,900),"task":"rest","label":"Western street"}],
 [{"at":Vector2(900,1740),"task":"deliver","label":"Seedhouse deliveries"},{"at":preload("res://scripts/town_refresh46.gd").REST,"task":"rest","label":"Wayfarer’s Rest"},{"at":Vector2(1600,1740),"task":"shop","label":"Southern errands"},{"at":Vector2(1700,2080),"task":"deliver","label":"Marina parcels"}],
 [{"at":Vector2(1650,1180),"task":"shop","label":"Service street shopping"},{"at":Vector2(2110,1180),"task":"rest","label":"Riverside stroll"},{"at":Vector2(2510,1150),"task":"deliver","label":"East-bank parcels"},{"at":Vector2(1800,1790),"task":"read","label":"Town notices"}],
 [{"at":Vector2(1470,1180),"task":"shop","label":"Afternoon provisions"},{"at":Vector2(1180,850),"task":"deliver","label":"Civic square parcels"},{"at":Vector2(760,850),"task":"rest","label":"Civic square stroll"},{"at":Vector2(760,1180),"task":"lunch","label":"Food stand rounds"}]
]
var circuits:Dictionary={}
var circuit_builds=0
var navigation=AStarGrid2D.new()
var plans:Array=[]
var ready=false
var setup_ms=0.0
var owner:Node
var unreachable:Array=[]
func setup(g:Node,residents:Array[Dictionary])->void:
 if ready:return
 var started=Time.get_ticks_usec();owner=g
 navigation.region=Rect2i(0,0,141,107);navigation.cell_size=Vector2.ONE*CELL;navigation.offset=ORIGIN+Vector2.ONE*CELL*.5
 navigation.diagonal_mode=AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
 navigation.default_compute_heuristic=AStarGrid2D.HEURISTIC_OCTILE;navigation.default_estimate_heuristic=AStarGrid2D.HEURISTIC_OCTILE;navigation.update()
 var streets=preload("res://scripts/town_plan.gd").ROADS+N.ROADS
 for y in navigation.region.size.y:
  for x in navigation.region.size.x:
   var id=Vector2i(x,y);var p=navigation.get_point_position(id)
   var solid=p.y<225 or (p.y>2270 and not Rect2(1050,2150,1180,660).has_point(p)) or not g.can_stand_at(p)
   if not solid:
    for offset in [Vector2(9,0),Vector2(-9,0),Vector2(0,9),Vector2(0,-9)]:
     if not g.can_stand_at(p+offset):solid=true;break
   navigation.set_point_solid(id,solid)
   if solid:continue
   var cost=3.5
   for route in streets:
    for n in range(1,route.size()):
     if Geometry2D.get_closest_point_to_segment(p,route[n-1],route[n]).distance_to(p)<35:cost=1.0;break
    if cost==1.0:break
   navigation.set_point_weight_scale(id,cost)
 for index in residents.size():plans.append({})
 ready=true;setup_ms=(Time.get_ticks_usec()-started)/1000.0
func usable(p:Vector2)->Vector2i:
 var at=Vector2i(floori((p.x-ORIGIN.x)/CELL),floori((p.y-ORIGIN.y)/CELL))
 at.x=clampi(at.x,0,navigation.region.size.x-1);at.y=clampi(at.y,0,navigation.region.size.y-1)
 var best=at;var distance=INF
 for radius in range(0,5):
  for y in range(at.y-radius,at.y+radius+1):
   for x in range(at.x-radius,at.x+radius+1):
    var id=Vector2i(x,y)
    if not navigation.is_in_boundsv(id) or navigation.is_point_solid(id):continue
    var d=navigation.get_point_position(id).distance_squared_to(p)
    if d<distance:distance=d;best=id
  if distance<INF:return best
 return best
func route_to(a:Vector2,b:Vector2)->PackedVector2Array:
 var path=navigation.get_point_path(usable(a),usable(b))
 if path.is_empty():return path
 # Real doorsteps are already collision-checked; avoid a visible jump on arrival.
 path.insert(0,a);path.append(b)
 return path
func errand_circuit(id:int)->Dictionary:
 if circuits.has(id):return circuits[id]
 var stops:Array=ERRANDS[id];var legs=[];var seconds=0.0
 for n in stops.size():
  var start=navigation.get_point_position(usable(stops[n].at));var target:Dictionary=stops[(n+1)%stops.size()]
  var at=navigation.get_point_position(usable(target.at));var path=route_to(start,at)
  if path.is_empty():unreachable.append("Errand circuit "+str(id)+" to "+str(target.label));return {}
  var lengths=[];var distance=0.0
  for k in range(1,path.size()):distance+=path[k-1].distance_to(path[k]);lengths.append(distance)
  var travel=distance/(52.0+float(id%3)*3);var pause=5.0+float(n%3)*2
  legs.append({"path":path,"lengths":lengths,"distance":distance,"travel":travel,"pause":pause,"seconds":travel+pause,"at":at,"task":target.task,"label":target.label});seconds+=travel+pause
 var result={"at":navigation.get_point_position(usable(stops[0].at)),"legs":legs,"seconds":seconds}
 circuits[id]=result;circuit_builds+=1;return result
func errand_stop(id:int)->Dictionary:
 var circuit=errand_circuit(id)
 if circuit.is_empty():return {"at":Vector2(760,850),"task":"rest","inside":false,"label":"Town square"}
 return {"at":circuit.at,"task":"shop","inside":false,"label":"Town errands","circuit":id}
func path_position(path:PackedVector2Array,lengths:Array,distance:float)->Vector2:
 var from=0.0
 for n in lengths.size():
  var finish=float(lengths[n])
  if distance<=finish:return path[n].lerp(path[n+1],clampf((distance-from)/maxf(.01,finish-from),0,1))
  from=finish
 return path[-1]
func errand_state(id:int,elapsed:float,available:float,npc:Dictionary)->Dictionary:
 var circuit=errand_circuit(id);var base=float(circuit.seconds)
 # Fit whole circuits into the schedule window: the next departure starts where
 # this route finishes, including midnight. No arrival/departure teleport.
 var cycles=maxi(1,floori(available/base));var period=available/cycles
 var phase=fposmod(maxf(0,elapsed),period)*base/period
 for leg in circuit.legs:
  if phase>=float(leg.seconds):phase-=float(leg.seconds);continue
  var moving=phase<float(leg.travel);var at:Vector2=leg.at
  if moving:at=path_position(leg.path,leg.lengths,phase/float(leg.travel)*float(leg.distance))
  return {"pos":at,"working":not moving,"visible":true,"opacity":1.0,"task":str(leg.task),"destination":str(leg.label),"kind":npc.kind,"colour":npc.colour,"name":npc.name,"errand":true}
 return {"pos":circuit.at,"working":true,"visible":true,"task":"rest","destination":"Town errands","kind":npc.kind,"colour":npc.colour,"name":npc.name,"errand":true}
func daily_plan(index:int,day:int,npc:Dictionary)->Dictionary:
 if plans[index].has(day):return plans[index][day]
 var home=N.HOMES[index%N.HOMES.size()]
 var doorstep:Vector2=home.door
 if index%5==1 and int(index/5)%2==1:doorstep+=Vector2(90,0)
 var bed={"at":doorstep,"task":"sleep","inside":true,"label":home.name}
 var job=JOBS[index%JOBS.size()].duplicate()
 var leisure={"at":Vector2(180+index%4*37,550),"task":"fish","inside":false,"label":"Pond garden"} if index%2==0 else {"at":Vector2(2780+index%3*24,1320),"task":"explore","inside":false,"label":"Forest walk"}
 if day==6:job=leisure
 if DAY_ERRANDS.has(index):job=errand_stop(int(DAY_ERRANDS[index]))
 if NIGHT_ERRANDS.has(index):
  # These two residents take daytime rest, then cover the quieter overnight hours.
  job=bed.duplicate();bed=errand_stop(int(NIGHT_ERRANDS[index]))
 var social={"at":Vector2(-1135,1045)+Vector2(index%3*24,0),"task":"rest","inside":false,"label":"Fountain courtyard"} if index%3==0 else {"at":N.HOMES[(index+1)%5].door+Vector2(35,25),"task":"chat","inside":false,"label":"Neighbour"}
 var lunch={"at":Vector2(1080+index%4*24,1205+int(index/4)%2*24),"task":"lunch","inside":false,"label":"Moss’s Food Stand"}
 var events=[{"hour":0.0,"stop":bed},{"hour":6.0+(float(index/4)*.07 if DAY_ERRANDS.has(index) else index%4*.12),"stop":job},{"hour":12.0+index%3*.08,"stop":lunch},{"hour":13.0+index%3*.08,"stop":job},{"hour":17.0+index%4*.12,"stop":social},{"hour":20.0+index%4*.12,"stop":bed}]
 if day==2:
  var square={"at":Vector2((740 if index<10 else 1010)+(index%2)*42,635+int((index%10)/2)*36),"task":"music","inside":false,"label":"Wednesday music"}
  events=[{"hour":0.0,"stop":bed},{"hour":6.0+(float(index/4)*.07 if DAY_ERRANDS.has(index) else index%4*.12),"stop":job},{"hour":12.0+index%3*.08,"stop":lunch},{"hour":13.0+index%3*.08,"stop":job},{"hour":17.0,"stop":social},{"hour":18.0,"stop":square},{"hour":22.0,"stop":bed}]
 # Small weekly activities reuse the collision-aware resident routes.
 var extra={}
 if day in [1,3] and index<4:extra={"start":12.0,"end":14.0,"at":Vector2(350+index%2*55,660+int(index/2)*55),"task":"picnic","label":"Family picnic"}
 elif day in [0,3] and index in [4,5]:extra={"start":10.0,"end":15.0,"at":Vector2(1665+(index-4)*70,1165),"task":"market","label":"Faraway Flavours"}
 elif day==5 and index>=6 and index<12:extra={"start":11.0,"end":16.0,"at":preload("res://scripts/town_events.gd").EVENTS.fair.at+Vector2(-100+(index-6)*40,65),"task":"market","label":"Makers' Fair"}
 elif day==4 and index>=12 and index<17:extra={"start":20.0,"end":22.0,"at":Vector2(1640+(index-12)*30,1180),"task":"lanterns","label":"Lantern Walk"}
 elif day==5 and index in [2,7,10]:extra={"start":22.0,"end":23.9,"at":Vector2(2760+index%3*35,1350),"task":"stars","label":"Stories Under Stars"}
 if day in [1,3] and index in [4,5,13]:extra={"start":10.0,"end":12.0,"at":Vector2(1500+(index%3)*35,2380),"task":"harbour_trade","label":"Marina deliveries"}
 elif day==6 and index in [0,2,8,14]:extra={"start":15.0,"end":18.0,"at":Vector2(1710+[0,2,8,14].find(index)*110,2304),"task":"fish","label":"Marina fishing afternoon"}
 if index in [1,6,11] and day in [0,2,4]:extra={"start":12.0,"end":13.0,"at":preload("res://scripts/town_refresh46.gd").REST+Vector2(-48+(index/5)*32,0),"task":"tea","label":"Wayfarer’s Rest lunch"}
 elif index in [3,9,15] and day in [1,3]:extra={"start":18.0,"end":20.0,"at":preload("res://scripts/town_refresh46.gd").REST+Vector2(-48+(index/6)*32,0),"task":"games","label":"Wayfarer’s Rest games"}
 elif index in [1,6,11,16] and day==6:extra={"start":16.0,"end":19.0,"at":preload("res://scripts/town_refresh46.gd").REST+Vector2(-64+(index/5)*32,0),"task":"stories","label":"Wayfarer’s Rest stories"}
 if not extra.is_empty():
  events=events.filter(func(e):return float(e.hour)<float(extra.start) or float(e.hour)>float(extra.end))
  events.append({"hour":extra.start,"stop":{"at":extra.at,"task":extra.task,"inside":false,"label":extra.label}})
  events.append({"hour":extra.end,"stop":job if float(extra.end)<17 else bed})
  events.sort_custom(func(a,b):return float(a.hour)<float(b.hour))
 # The named camp traveller has a dawn fishing, day exploring, dusk fire routine.
 if index==20:
  bed={"at":Vector2(2950,1515),"task":"sleep","inside":true,"label":"Traveller's tent"}
  var fish={"at":Vector2(2475,480),"task":"fish","inside":false,"label":"Riverbank"}
  var walk={"at":Vector2(2785,1300),"task":"explore","inside":false,"label":"Forest trail"}
  var fire={"at":Vector2(2807,1477),"task":"camp","inside":false,"label":"Campfire"}
  events=[{"hour":0.0,"stop":bed},{"hour":4.0,"stop":fish},{"hour":6.0,"stop":walk},{"hour":18.0,"stop":fire},{"hour":23.0,"stop":bed}]
 var segments=[]
 for n in events.size():
  var event:Dictionary=events[n]
  var finish=24.0 if n==events.size()-1 else float(events[n+1].hour)
  var duration=(finish-float(event.hour))*3600.0
  var stop:Dictionary=event.stop.duplicate()
  # Snap outdoor destinations to clear navigation cells, not to a wall or water.
  stop.at=navigation.get_point_position(usable(stop.at))
  var previous:Dictionary=events[(n-1+events.size())%events.size()].stop
  var start:Vector2=navigation.get_point_position(usable(previous.at))
  var path=route_to(start,stop.at)
  var lengths=[];var distance=0.0
  for point in range(1,path.size()):distance+=path[point-1].distance_to(path[point]);lengths.append(distance)
  if path.is_empty():unreachable.append(str(npc.name)+" day "+str(day)+": "+str(stop.label))
  var speed=maxf(62.0+float(index%5)*4,distance/maxf(1,duration-1))
  segments.append({"start":float(event.hour)*3600.0,"duration":duration,"stop":stop,"path":path,"lengths":lengths,"distance":distance,"speed":speed})
 var result={"timeline":segments}
 plans[index][day]=result
 return result
func state(index:int,hour:float,npc:Dictionary,day:int=0)->Dictionary:
 if not ready:return {"pos":N.HOMES[index%5].door,"working":true,"visible":false,"task":"sleep","kind":npc.kind,"colour":npc.colour,"name":npc.name}
 var plan=daily_plan(index,day,npc)
 var phase=hour*3600.0
 for segment in plan.timeline:
  if phase>=float(segment.start)+float(segment.duration):continue
  var local=phase-float(segment.start)
  var distance=minf(float(segment.distance),local*float(segment.speed))
  var moving=distance<float(segment.distance)-.1
  var pos:Vector2=segment.stop.at
  if not moving and segment.stop.has("circuit"):
   var travel=float(segment.distance)/float(segment.speed)
   return errand_state(int(segment.stop.circuit),local-travel,maxf(.01,float(segment.duration)-travel),npc)
  if moving:
   var from=0.0
   for n in segment.lengths.size():
    var finish=float(segment.lengths[n])
    if distance<=finish:
     pos=segment.path[n].lerp(segment.path[n+1],clampf((distance-from)/maxf(.01,finish-from),0,1));break
    from=finish
  return {"pos":pos,"working":not moving,"visible":moving or not bool(segment.stop.inside),"opacity":1.0,"task":str(segment.stop.task),"destination":str(segment.stop.label),"kind":npc.kind,"colour":npc.colour,"name":npc.name}
 return {"pos":N.HOMES[index%5].door,"working":true,"visible":false,"task":"sleep","kind":npc.kind,"colour":npc.colour,"name":npc.name}

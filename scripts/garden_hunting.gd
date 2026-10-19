extends RefCounted
## Small daily seed caches, placed beside scenery, never on a spawn or exit.
static func build(g:Node,garden:RefCounted)->void:
 var region=str(g.region_id);var key=str(int((garden.now()+preload("res://scripts/town_clock_math.gd").edmonton_offset(garden.now()))/86400))+":"+region
 if garden.world_region==key:return
 garden.caches.clear()
 if g.practice or g.tutorial.active or g.mode not in ["town","run"] or not garden.allowed():return
 garden.world_region=key
 var rng=RandomNumberGenerator.new();rng.seed=hash(key+":garden184")
 var points=[]
 if g.mode=="town":points=[Vector2(360,585),Vector2(1015,1650),Vector2(1840,1250)]
 else:
  for obstacle in g.obstacles:
   var point:Vector2=obstacle.pos+Vector2(58,38)
   if point.distance_to(g.position_in_world)>350 and g.can_stand_at(point):points.append(point)
  # Scenic props differ by realm; scan clear ground if there are no tree obstacles.
  if points.is_empty():
   for n in 60:
    var point=Vector2(rng.randf_range(180,maxf(181,g.region_size().x-180)),rng.randf_range(180,maxf(181,g.region_size().y-180)))
    if point.distance_to(g.position_in_world)>450 and g.can_stand_at(point):points.append(point)
 if points.is_empty():return
 for i in (3 if g.mode=="town" else mini(2,points.size())):
  var pick=i if g.mode=="town" else rng.randi_range(0,points.size()-1)
  var p:Vector2=points[pick]
  if g.mode!="town":points.remove_at(pick)
  var claim=key+":"+str(i)
  if not garden.state().claims.has(claim):garden.caches.append({"at":p,"claim":claim})
static func draw_on(g:Node2D,camera:Vector2)->void:
 if g.legacy==null:return
 var garden=g.legacy.gardening;build(g,garden)
 for cache in garden.caches:
  if garden.state().claims.has(cache.claim):continue
  var at:Vector2=cache.at-camera
  if not Rect2(Vector2.ZERO,g.VIEW).grow(25).has_point(at):continue
  g.draw_style_box(preload("res://scripts/studio_ui.gd").box("#b09561","#f0dba4",4,2),Rect2(at-Vector2(10,17),Vector2(20,24)))
  g.draw_line(at+Vector2(0,1),at-Vector2(0,11),Color("#477c54"),2);g.draw_circle(at+Vector2(-4,-7),4,Color("#91bf7b"));g.draw_circle(at+Vector2(4,-10),4,Color("#b1d68b"))
  if g.position_in_world.distance_to(cache.at)<65:g.draw_string(g.font,at+Vector2(-45,-27),"E • Seed cache",HORIZONTAL_ALIGNMENT_LEFT,-1,13,Color("#f4df9f"))
static func interact(g:Node)->bool:
 if g.legacy==null:return false
 var garden=g.legacy.gardening;build(g,garden)
 for cache in garden.caches:
  if garden.state().claims.has(cache.claim) or g.position_in_world.distance_to(cache.at)>=65:continue
  g.hint="E • Search seed cache"
  if Input.is_action_just_pressed("interact"):
   garden.state().claims[cache.claim]=true
   while garden.state().claims.size()>200:garden.state().claims.erase(garden.state().claims.keys()[0])
   var source="town" if g.mode=="town" else "realm";var found=garden.find_seed(source,str(g.region_id),true)
   if found.is_empty():found=garden.find_seed("town","",true)
   if found.is_empty():garden.message("A packet of compost notes. Search other seed sources as you level up.")
   garden.save()
  return true
 return false

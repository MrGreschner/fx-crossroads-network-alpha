extends SceneTree
var failures:=0
func check(ok:bool,message:String)->void:
 if not ok:failures+=1;print("FAIL: ",message)
func _initialize()->void:call_deferred("run")
func run()->void:
 root.set_meta("fx_intro_seen",true)
 var g=load("res://scenes/main.tscn").instantiate();root.add_child(g);await process_frame;g.set_process(false);g.legacy.set_process(false);g.presentation.asked=true;g.presentation.close();g.session_menu.resume();g.enter_region("town");g.menu=""
 var original:Array=g.obstacles.duplicate()
 g.obstacles.clear()
 for n in 500:g.obstacles.append({"pos":Vector2(-100+n%25*130,-180+n/25*130),"radius":20+float(n%8)*13})
 g.build_scenery()
 for n in 800:
  var point:=Vector2(-130+posmod(n*113,3550),-230+posmod(n*197,3000));var padding:=float(n%3)*5
  var expected:bool=g.adventure.can_stand(point)
  for obstacle in g.obstacles:
   if point.distance_to(obstacle.pos)<float(obstacle.radius)+padding:expected=false;break
  check(g.clear_of_obstacles(point,padding)==expected,"indexed collision matches full scan "+str(n))
 g.obstacles.assign(original);g.build_scenery()
 var scenery=g.town_scenery
 for n in 500:
  var point:=Vector2(posmod(n*157,3200),-560+posmod(n*173,2810))
  var expected:bool=((point-scenery.POND)/scenery.POND_RADII).length()<1 or point.distance_to(scenery.TOWER)<40 or point.distance_to(scenery.CAMP)<28
  for tree in scenery.trees:
   if point.distance_to(tree)<25:expected=true;break
  check(scenery.blocked(point)==expected,"indexed town trunks match collision "+str(n))
 g.sync_terrain();await process_frame
 check(g.terrain_cache.chunks.size()>0,"retained terrain created")
 var count:int=g.terrain_cache.chunks.size()
 g.sync_terrain();check(g.terrain_cache.chunks.size()==count,"stationary frame reuses chunks")
 for n in 60:
  g.camera=Vector2(n%10*512,n/10*512);g.sync_terrain();await process_frame
 check(g.terrain_cache.chunks.size()<=48,"bounded cache while exploring")
 g.session_menu.page="main";g.sync_terrain();check(not g.terrain_cache.visible,"terrain hidden behind main menu")
 g.session_menu.page="";g.enter_region("practice");check(g.terrain_cache.chunks.is_empty(),"realm change invalidates terrain")
 g.camera=Vector2.ZERO;g.sync_terrain();await process_frame
 var base:String=str(g.region.get("terrain","forest"))
 var chunk=g.terrain_cache.chunks[Vector2i.ZERO]
 for tile in chunk.tiles:
  if (tile[1] as Rect2).size==Vector2(64,64):
   var cell:Vector2=(tile[1] as Rect2).position/64
   check(tile[0]==g.art[g.ground_tile_at(int(cell.x),int(cell.y),base)],"cached tile texture preserves terrain")
 g.queue_free();await process_frame;await process_frame
 var a=load("res://scenes/arcade.tscn").instantiate();root.add_child(a);await process_frame;a.set_process(false);a.party_tools.set_process(false);a.legacy.set_process(false);a._set_mode("arena");a.bot_count=1;a._solo()
 for n in 200:
  var tx:=n%20;var ty:=n/20;var point:=Vector2(tx*64+32,ty*64+32);var expected:String=a.world_terrain
  for patch in a.world_patches:
   if Geometry2D.is_point_in_polygon(point,patch.polygon):expected=str(patch.tile)
  check(a.cached_world_tile(tx,ty,64)==expected,"arena tile cache preserves path selection")
 a.arena_world.setup(a,"sand");check(a.world_tile_cache.is_empty(),"arena map switch invalidates tiles")
 a.queue_free();await process_frame;await process_frame
 print("v100 performance failures: ",failures);quit(failures)

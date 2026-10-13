extends SceneTree
var failures:=0
func check(ok:bool,label:String)->void:
 if not ok:failures+=1;print("FAIL: ",label)
func _initialize()->void:call_deferred("run")
func run()->void:
 root.set_meta("fx_intro_seen",true)
 var g=load("res://scenes/main.tscn").instantiate();root.add_child(g);await process_frame;g.set_process(false);g.legacy.set_process(false);g.presentation.asked=true;g.presentation.close();g.session_menu.resume()
 var library=g.hero_hall.library
 for n in g.manifest.characters.size():check(library.number(g,g.manifest.characters[n])==n+1,"consecutive roster number "+str(n+1))
 check(library.number(g,"harbor")==20 and library.number(g,"magnet")==21,"Harbor Bell and Polarity requested positions")
 g.menu="characters";g.hero_hall.refresh()
 for row in g.hero_hall.rows.get_children():
  if row is VBoxContainer and row.get_child(0) is HBoxContainer:check(row.get_child(0).get_child(0).icon!=null,"favourite uses a texture icon")
 var cached:Dictionary={}
 for tx in range(4,25):
  for ty in range(1,20):
   var expected:="grass"
   for patch in g.ground_patches:
    if Geometry2D.is_point_in_polygon(Vector2(tx*64+32,ty*64+32),patch.polygon):expected=str(patch.tile)
   check(g.ground_tile_at(tx,ty,"grass")==expected,"cached tile matches authored ground");cached[Vector2i(tx,ty)]=expected
 var used:int=g.ground_tile_cache.size();g.ground_tile_at(5,5,"grass");check(g.ground_tile_cache.size()==used,"reuse does not grow cache")
 g.load_town_layout();check(g.ground_tile_cache.is_empty(),"world reload invalidates tile cache")
 var scenery=g.town_scenery
 for index in scenery.routes.size():
  var outward:Array=scenery.routes[index];var route:Array=outward.duplicate()
  for n in range(outward.size()-2,0,-1):route.append(outward[n])
  var cycle:float=0
  for n in route.size():cycle+=(route[n] as Vector2).distance_to(route[(n+1)%route.size()])/55+1.2
  for clock in [0,5,30,80,160]:
   scenery.clock=clock;var elapsed:=fposmod(clock+index*14,cycle);var expected:Vector2=route[0]
   for n in route.size():
    var start:Vector2=route[n];var finish:Vector2=route[(n+1)%route.size()];var duration:=start.distance_to(finish)/55
    if elapsed<duration:expected=start.lerp(finish,elapsed/duration);break
    elapsed-=duration
    if elapsed<1.2:expected=finish;break
    elapsed-=1.2
   check(scenery.guard_position(index).distance_to(expected)<.001,"cached patrol preserves motion")
 g.legacy.save();var modified:int=FileAccess.get_modified_time(g.legacy.PATH);var stored:String=g.legacy.last_saved_json;g.legacy.save();check(g.legacy.last_saved_json==stored and FileAccess.get_modified_time(g.legacy.PATH)==modified,"idle profile is not rewritten")
 g.session_menu.open("main");g.session_menu.show_options();check(g.session_menu.page=="options" and g.session_menu.gallery.visible,"options is a standalone page")
 var stability:Node=root.get_node("FXStability");stability.set_fps(60);stability.set_diagnostics(false)
 var settings:Dictionary=JSON.parse_string(FileAccess.get_file_as_string(stability.PATH));check(settings.fps_limit==60 and not settings.diagnostics_enabled,"options persist locally")
 stability.set_fps(999);check(stability.fps_limit==60,"invalid FPS rejected")
 stability.set_diagnostics(true);stability.set_fps(30 if stability.school_mode else 60)
 g.session_menu.resume();g.queue_free();await process_frame
 var a=load("res://scenes/arcade.tscn").instantiate();root.add_child(a);await process_frame;a.set_process(false);a.party_tools.set_process(false);a.legacy.set_process(false);a._set_mode("defense");a._solo();a.set_process(false);a.start_countdown=0
 var gate=a.north_gate
 a._simulate(.01);check(a.wave==1 and a.wave_timer==8,"opening wave immediate, next eight seconds")
 check(a.opponents.size()==19,"opening wave has 19 enemies solo")
 check(a.guards.size()==9,"two base guards plus outpost guard per lane retained")
 for foe in a.opponents:check(gate.distance_at(foe.lane,foe.pos)>gate.length_of(foe.lane)-110,"opening still at far road entrance")
 for party in [1,2,3]:
  gate.party_size=party;check(gate.wave_count(1)>6*party and gate.wave_count(30)<=90,"opening pressure scales with bounded population")
 gate.party_size=1;a.positions.solo=Vector2(5300,8800);a.health.solo=99999
 for tick in 1200:a._simulate(.1)
 print("Gate no-hero 120s: wave=",a.wave," enemies=",a.opponents.size()," guards=",a.guards.size()," outposts=",gate.outpost_hp)
 check(a.opponents.size()>0 and gate.outpost_hp.any(func(h):return h<gate.outpost_max),"guards alone cannot clear opening pressure without losses")
 for player in a.find_children("*","AudioStreamPlayer",true,false):player.stop()
 a.queue_free();await process_frame;await process_frame
 print("v95 maintenance failures: ",failures);quit(failures)

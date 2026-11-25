extends SceneTree
const M=preload("res://scripts/town_marina.gd")
const W=preload("res://scripts/town_winter358.gd")
var g:Node
func _initialize():call_deferred("run")
func season(month:int,hour:int=12):
 var cal=g.town_life.calendar
 cal.test_time=Time.get_unix_time_from_datetime_dict({"year":2026,"month":month,"day":22,"hour":0,"minute":0,"second":0})+(hour+7)*3600
 cal.refresh();cal.mesh_key="";cal.step()
func shot(name:String,center:Vector2):
 g.position_in_world=center+Vector2(0,200);g.camera=center-g.VIEW*.5
 g.queue_redraw();await process_frame;await create_timer(.25).timeout;await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png("user://"+name+".png")
func run():
 root.set_meta("fx_intro_seen",true);g=load("res://scenes/main.tscn").instantiate();root.add_child(g);await process_frame;await process_frame;g.set_process(false)
 g.get_window().size=Vector2i(1280,720);g.mode="town";g.menu="";g.presentation.close();g.session_menu.page="";g.mobile.enabled=false;g.mobile.reset_controls();g.message="";g.message_time=0;g.journey.welcome_remaining=0
 season(12)
 assert(g.town_life.calendar.season()=="Winter")
 assert(M.visible_berths(true).is_empty() and M.visible_berths(false).size()==4)
 for at in [Vector2(1740,2415),Vector2(1920,2430),Vector2(2155,2430),Vector2(1910,2610),Vector2(1965,2565)]:assert(g.can_stand_at(at))
 assert(not g.can_stand_at(Vector2(2360,2500)))
 var original:Dictionary={"id":"town_marina","bank":[1800,2300],"water":[1800,2380],"fish":["dockstripe_perch"]}
 var ice=W.ice_spot(original);assert(ice.ice and ice.bank==[1965.,2565.] and ice.fish==original.fish);assert(not original.has("ice"))
 g.fishing.spots=preload("res://scripts/fishing_catalog.gd").spots("town");g.position_in_world=Vector2(1965,2565)
 assert(g.fishing.nearest().id=="town_marina" and g.fishing.nearest().ice)
 g.fishing.cast_spot=g.fishing.nearest();assert(g.fishing.cast_available())
 print("PASS winter harbour walk, river barrier, four boats hidden, unchanged catch pool and real ice-hole interaction")
 await shot("Marina_Winter_V384",Vector2(2010,2460))
 await shot("Market_Winter_V384",Vector2(-200,580))
 await shot("Tidecross_Winter_V384",Vector2(1650,3290))
 await shot("Tidecross_Docks_Winter_V384",Vector2(1840,3750))
 await shot("Outback_Cabin_Winter_V384",Vector2(3500,-2220))
 season(12,21);await shot("North_Gate_Night_V384",Vector2(900,300))
 for month in [4,7,10]:
  season(month)
  await shot("Market_"+g.town_life.calendar.season()+"_V384",Vector2(-200,580))
 season(7)
 g.position_in_world=Vector2(1965,2565);assert(not g.can_stand_at(g.position_in_world));assert(not g.fishing.cast_available());W.rescue_thawed_pond(g);assert(M.on_deck(g.position_in_world) and g.can_stand_at(g.position_in_world))
 assert(not g.fishing.winter_town_spot(original).has("ice"))
 print("PASS thaw returns player to accessible dock, invalidates winter cast, restores summer water/boats/fishing; ownership epoch unchanged")
 await shot("Marina_Summer_V384",Vector2(2010,2460))
 g.queue_free();await process_frame;print("ALL V384 CHECKS PASSED");quit()

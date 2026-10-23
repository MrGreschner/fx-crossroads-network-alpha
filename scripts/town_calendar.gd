extends RefCounted
## The ambient town uses wall time, including while the game is closed.
## Real Edmonton civil time. No accelerated day, offline rewards, or profile writes.
const DAY_SECONDS=86400.0
const EPOCH=1767571200.0 # Monday, 5 January 2026 UTC.
const DAYS=["Monday","Tuesday","Wednesday","Thursday","Friday","Saturday","Sunday"]
const SQUARE=Vector2(960,800)
const CAMP=Vector2(2890,1450)
const TENT=Vector2(2950,1515)
const FISH=Vector2(2475,480)
const LAMPS=[Vector2(-940,1060),Vector2(-1250,555),Vector2(-810,555),Vector2(-720,475),Vector2(-440,475),Vector2(-780,760),Vector2(700,810),Vector2(1180,810),Vector2(720,610),Vector2(1080,610),Vector2(440,870),Vector2(1450,870),Vector2(1940,870),Vector2(780,1205),Vector2(1515,1205),Vector2(2100,1205),Vector2(2550,1185),Vector2(2810,1320),Vector2(-820,920),Vector2(-350,920),Vector2(580,1765),Vector2(920,1765),Vector2(1560,1765),Vector2(2020,2100)]
const EXISTING_LAMPS=[Vector2(-720,1415),Vector2(-340,1415),Vector2(-810,2120),Vector2(-1100,2120),Vector2(-495,1710),Vector2(165,2160)]
var now:float=0
var hour:float=0
var weekday:int=0
var day_number:int=0
var local_date:Dictionary={}
var preview_time:float=-1
var preview_weather=""
var almanac:CanvasLayer
var animation_time_for_test:float=-1
var test_time:float=-1
var lights:Array[Dictionary]=[]
var mesh=ArrayMesh.new()
var frame_shade=Color(0,0,0,0)
var mesh_key=""
var mesh_origin=Vector2.ZERO
var lighting_rebuilds=0
var grid_extent=Vector2.ZERO
var grid_vertices=PackedVector3Array()
var grid_indices=PackedInt32Array()
var lighting_distance_checks=0
var puddle_cells:Dictionary={}
var music:AudioStreamPlayer
var game:Node
func setup(g:Node)->void:
 game=g;refresh()
 almanac=preload("res://scripts/town_almanac.gd").new();g.add_child(almanac);almanac.setup(g,self)
 music=AudioStreamPlayer.new();music.name="TownWednesdayMusic";music.stream=load("res://assets/audio/town_wednesday.wav");music.stream.loop_mode=AudioStreamWAV.LOOP_FORWARD;music.stream.loop_end=352800;g.add_child(music)
static func edmonton_offset(utc:float)->int:
 # Alberta.ca: permanent UTC-6 from November 2026; historical MST/MDT before that.
 var date=Time.get_datetime_dict_from_unix_time(int(utc));var year=int(date.year)
 var first=Time.get_datetime_dict_from_unix_time(Time.get_unix_time_from_datetime_dict({"year":year,"month":3,"day":1,"hour":0,"minute":0,"second":0}))
 var march_day=8+posmod(7-int(first.weekday),7)
 var spring=Time.get_unix_time_from_datetime_dict({"year":year,"month":3,"day":march_day,"hour":9,"minute":0,"second":0})
 if year>2026 or (year==2026 and utc>=spring):return -21600
 first=Time.get_datetime_dict_from_unix_time(Time.get_unix_time_from_datetime_dict({"year":year,"month":11,"day":1,"hour":0,"minute":0,"second":0}))
 var november_day=1+posmod(7-int(first.weekday),7)
 var autumn=Time.get_unix_time_from_datetime_dict({"year":year,"month":11,"day":november_day,"hour":8,"minute":0,"second":0})
 return -21600 if utc>=spring and utc<autumn else -25200
func refresh()->void:
 now=Time.get_unix_time_from_system() if test_time<0 else test_time
 var dev=preload("res://scripts/profile_store.gd").dev_session()
 if preview_time>=0 and dev!=null and dev.active:now=preview_time
 elif preview_time>=0:preview_time=-1
 var civil=now+edmonton_offset(now)
 local_date=Time.get_datetime_dict_from_unix_time(int(civil))
 day_number=floori(civil/DAY_SECONDS)
 weekday=posmod(int(local_date.weekday)+6,7)
 hour=float(local_date.hour)+float(local_date.minute)/60.0+(float(local_date.second)+fposmod(civil,1))/3600.0
func dawn_fishing_open()->bool:return hour>=4.0 and hour<6.0
func step()->void:
 refresh()
 if music==null:return
 var nearby=game.mode=="town" and music_active() and game.position_in_world.distance_to(SQUARE)<650
 if nearby:
  music.volume_db=-12.0-28.0*clampf(game.position_in_world.distance_to(SQUARE)/650.0,0,1)
  if not music.playing:music.play(fposmod(now-EPOCH,music.stream.get_length()))
 elif music.playing:music.stop()
func music_active()->bool:return weekday==2 and hour>=19 and hour<22
func phase()->String:
 if hour<6.0 or hour>=21:return "Night"
 if hour<8.0:return "Dawn"
 if hour<18.0:return "Day"
 return "Dusk"
func night_amount()->float:
 if hour<6.0 or hour>=21:return 1.0
 if hour<8.0:return 1.0-smoothstep(6.0,8.0,hour)
 if hour<18.0:return 0.0
 return smoothstep(18.0,21.0,hour)
func fire_strength()->float:
 if hour>=18:return smoothstep(18,19,hour)
 if hour<1:return 1.0
 if hour<6:return 1.0-smoothstep(1,6,hour)*.94
 return 0.0
func camper_task()->String:
 if hour<4 or hour>=23:return "sleep"
 if hour<6:return "fish"
 if hour<18:return "explore"
 return "camp"
func moon_amount()->float:
 if hour>=23:return smoothstep(23,24,hour)
 if hour<4:return 1.0
 if hour<5:return 1.0-smoothstep(4,5,hour)
 return 0.0
func label()->String:
 var minutes=floori(hour*60)
 return "%s  %02d:%02d  ·  %s" % [DAYS[weekday],minutes/60,minutes%60,weather()]
func weather()->String:
 var dev=preload("res://scripts/profile_store.gd").dev_session()
 if dev!=null and dev.active and preview_weather in preload("res://scripts/town_weather.gd").TYPES:return preview_weather
 preview_weather=""
 return preload("res://scripts/town_weather.gd").at(day_number,hour)

func draw_props(c:Node2D,camera:Vector2)->void:
 draw_puddles(c,camera)
 var view=Rect2(camera,c.VIEW).grow(130)
 var lit=night_amount()
 for spot in LAMPS+EXISTING_LAMPS:
  if not view.has_point(spot):continue
  var p:Vector2=spot-camera
  draw_lantern(c,p,lit)
 if view.has_point(TENT):
  var p:Vector2=TENT-camera
  c.draw_circle(p+Vector2(0,8),38,Color(0,0,0,.18))
  c.draw_colored_polygon(PackedVector2Array([p+Vector2(-38,12),p+Vector2(0,-49),p+Vector2(38,12)]),Color("#8c789c"))
  c.draw_colored_polygon(PackedVector2Array([p+Vector2(-16,12),p+Vector2(0,-27),p+Vector2(16,12)]),Color("#35434e"))
  for side in [-1,1]:c.draw_line(p+Vector2(side*25,-8),p+Vector2(side*47,17),Color("#cdbb97"),1.5)
  if camper_task()=="sleep":
   var font=ThemeDB.fallback_font
   c.draw_string(font,p+Vector2(8,-60-fposmod(c.town_life.clock*6,18)),"z z",HORIZONTAL_ALIGNMENT_LEFT,-1,15,Color(.8,.87,1,.7))
 if music_active() and view.has_point(SQUARE):
  var p:Vector2=SQUARE-camera
  # Small portable drum and a lute: no permanent building or collision on the square.
  c.draw_circle(p+Vector2(32,-12),13,Color("#b58c67"));c.draw_arc(p+Vector2(32,-12),13,0,TAU,20,Color("#ebd4a0"),2,true)
  c.draw_line(p+Vector2(23,-14),p+Vector2(16,-26-sin(c.town_life.clock*6)*4),Color("#d9c79e"),3)
  c.draw_circle(p+Vector2(-29,-15),10,Color("#ce9e62"));c.draw_line(p+Vector2(-29,-15),p+Vector2(-18,-39),Color("#ce9e62"),5)
  for n in 3:
   var t=fposmod(c.town_life.clock*.4+n*.33,1)
   var note=p+Vector2(-30+n*26+sin(t*4)*10,-46-t*42)
   c.draw_circle(note,3,Color(1,.86,.5,1-t));c.draw_line(note,note-Vector2(0,10),Color(1,.86,.5,1-t),2)
func collect_lights(c:Node2D,camera:Vector2)->void:
 lights.clear()
 var view=Rect2(camera,c.VIEW).grow(450)
 for spot in LAMPS:
  if view.has_point(spot):lights.append({"pos":spot-camera-Vector2(0,55),"radius":150.0,"strength":1.0})
 for spot in EXISTING_LAMPS:
  if view.has_point(spot):lights.append({"pos":spot-camera-Vector2(0,55),"radius":135.0,"strength":1.0})
 for lamp in preload("res://scripts/town_v173.gd").LIGHTS:
  if view.has_point(lamp):lights.append({"pos":lamp-camera,"radius":95.0,"strength":.85})
 for torch in c.arena_town.TORCHES:
  if view.has_point(torch):lights.append({"pos":torch-camera,"radius":180.0,"strength":1.1})
 for home in c.town_life.neighborhood.HOMES:
  var spot:Vector2=home.door+Vector2(38,-50)
  if view.has_point(spot):lights.append({"pos":spot-camera,"radius":120.0,"strength":1.0})
 if view.has_point(CAMP) and fire_strength()>.01:lights.append({"pos":CAMP-camera,"radius":190.0,"strength":fire_strength()})
 for source in preload("res://scripts/marina_life.gd").light_sources(c):
  if view.has_point(source.at):lights.append({"pos":source.at-camera,"radius":source.radius,"strength":source.strength})
 for source in preload("res://scripts/town_afterglow.gd").light_sources(c):
  if view.has_point(source.at):lights.append({"pos":source.at-camera,"radius":source.radius,"strength":source.strength})
 lights.append({"pos":Vector2(900,670)-camera,"radius":140.0,"strength":.7,"portal":true})
func shade_at(p:Vector2,night:float,twilight:float)->Color:
 var light=0.0
 for lamp in lights:
  var falloff=1.0-smoothstep(0.0,float(lamp.radius),p.distance_to(lamp.pos))
  light=maxf(light,falloff*float(lamp.strength))
 var ambient=frame_shade
 var shade=ambient
 shade.a=ambient.a*(1.0-light*.95)
 return shade
func draw_lighting(c:Node2D,camera:Vector2)->void:
 draw_weather(c,camera)
 var night=night_amount()
 var twilight=sin(PI*night)*.6
 # Daylight also changes subtly across morning, noon and afternoon.
 collect_lights(c,camera)
 frame_shade=ambient_shade()
 # Keep the spatial light field separate from the ambient tint. Time/weather modulate
 # its draw colour without rebuilding thousands of vertices twice per second.
 # The expanded source margin covers every light influencing the retained grid.
 # HUD is drawn afterwards.
 var origin=Vector2(floorf(camera.x/128)*128-64,floorf(camera.y/128)*128-64)
 var key=str(origin)+str(c.VIEW)+str(roundi(fire_strength()*64))
 if mesh_key!=key:
  mesh_key=key;mesh_origin=origin;lighting_rebuilds+=1
  var extent=c.VIEW+Vector2(256,256)
  var columns=ceili(extent.x/32.0);var rows=ceili(extent.y/32.0)
  if grid_extent!=extent or grid_vertices.is_empty():
   grid_extent=extent;grid_vertices=PackedVector3Array();grid_indices=PackedInt32Array()
   for y in range(rows+1):
    for x in range(columns+1):grid_vertices.append(Vector3(minf(x*32,extent.x),minf(y*32,extent.y),0))
   for y in rows:
    for x in columns:
     var a=y*(columns+1)+x;var b=a+1;var d=a+columns+1;var e=d+1
     grid_indices.append_array(PackedInt32Array([a,b,e,a,e,d]))
  var strengths=PackedFloat32Array();strengths.resize(grid_vertices.size());lighting_distance_checks=0
  # A lamp contributes only inside its radius. Visit that local grid square instead
  # of testing every vertex against every lamp; keep the authored 32px gradient.
  for lamp in lights:
   var center:Vector2=lamp.pos+camera-origin;var radius=float(lamp.radius)
   var left=clampi(floori((center.x-radius)/32),0,columns);var right=clampi(ceili((center.x+radius)/32),0,columns)
   var top=clampi(floori((center.y-radius)/32),0,rows);var bottom=clampi(ceili((center.y+radius)/32),0,rows)
   for y in range(top,bottom+1):
    for x in range(left,right+1):
     var index=y*(columns+1)+x;var vertex=grid_vertices[index];var distance=Vector2(vertex.x,vertex.y).distance_squared_to(center);lighting_distance_checks+=1
     if distance>=radius*radius:continue
     var strength=(1.0-smoothstep(0.0,radius,sqrt(distance)))*float(lamp.strength)
     strengths[index]=maxf(strengths[index],strength)
  var colours=PackedColorArray();colours.resize(grid_vertices.size())
  for i in grid_vertices.size():
   colours[i]=Color(1,1,1,1.0-strengths[i]*.95)
  var arrays=[];arrays.resize(Mesh.ARRAY_MAX);arrays[Mesh.ARRAY_VERTEX]=grid_vertices;arrays[Mesh.ARRAY_COLOR]=colours;arrays[Mesh.ARRAY_INDEX]=grid_indices
  mesh.clear_surfaces();mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
 c.draw_mesh(mesh,null,Transform2D(0,mesh_origin-camera),frame_shade)
 for lamp in lights:
  if float(lamp.strength)<.1:continue
  var p:Vector2=lamp.pos
  if not Rect2(Vector2.ZERO,c.VIEW).grow(100).has_point(p):continue
  if lamp.get("portal",false):
   for radius in [95,70,45]:c.draw_circle(p,radius,Color(.24,.55,1,night*.025))
   continue
  for radius in [17,10,4]:c.draw_circle(p,radius,Color(1,.79,.4,night*float(lamp.strength)*(.03 if radius>4 else .6)))
 # A silver reflection tracks the moonlit hours over the river, not over the HUD.
 if moon_amount()>.01:
  for n in 10:
   var world=Vector2(2360+sin(c.town_life.clock*.2+n)*22,240+n*190)
   if Rect2(camera,c.VIEW).grow(30).has_point(world):
    var point:Vector2=world-camera
    c.draw_line(point-Vector2(14,0),point+Vector2(14,0),Color(.72,.84,1,moon_amount()*.17),1.5,true)
 # Fireflies follow the river after dark.
 for n in 9:
  var world=Vector2(2660+sin(c.town_life.clock*.21+n*2)*80,1330+n*22+cos(c.town_life.clock*.3+n)*14)
  if not Rect2(camera,c.VIEW).grow(20).has_point(world):continue
  var p:Vector2=world-camera
  c.draw_circle(p,9,Color(.78,1,.58,night*.06));c.draw_circle(p,2,Color(.86,1,.66,night*(.55+.25*sin(c.town_life.clock+n))))
func interact(g:Node)->bool:
 if g.position_in_world.distance_to(TENT)<65:
  g.hint="E · Traveller's tent"
  if Input.is_action_just_pressed("interact"):
   g.message="The traveller is asleep. The fire will fade before dawn." if camper_task()=="sleep" else "A fishing rod, a bedroll, and a well-worn trail map. The traveller fishes at the northern river bend from 4–6 am and returns at dusk."
   g.message_time=5
  return true
 if weekday==4 and hour>=23.0 and g.position_in_world.distance_to(Vector2(2660,1440))<75:
  g.hint="E · Friday midnight fireflies"
  if Input.is_action_just_pressed("interact"):g.message="The fireflies trace a hidden message above the reeds: 'Every road leads home.'";g.message_time=5
  return true
 if weekday==0 and hour>=6.0 and hour<7.0 and g.position_in_world.distance_to(Vector2(-1030,1010))<80:
  g.hint="E · Monday dawn inscription"
  if Input.is_action_just_pressed("interact"):g.message="In the first light, old letters shine on the fountain: 'A town is the people who return to it.'";g.message_time=5
  return true
 return false

func ambient_shade()->Color:
 # Interpolated art direction, rather than abrupt hourly filter changes.
 var keys=[[0.0,Color(.045,.10,.21,.68)],[4.0,Color(.07,.16,.28,.61)],[6.0,Color(.43,.28,.36,.43)],[8.0,Color(.96,.68,.35,.065)],[10.0,Color(.91,.88,.66,.025)],[12.0,Color(.96,.93,.73,.015)],[15.0,Color(.96,.70,.33,.06)],[18.0,Color(.77,.37,.22,.20)],[20.0,Color(.26,.17,.34,.52)],[22.0,Color(.045,.10,.21,.70)],[24.0,Color(.045,.10,.21,.68)]]
 for n in range(1,keys.size()):
  if hour<=float(keys[n][0]):
   var shade:Color=keys[n-1][1].lerp(keys[n][1],smoothstep(float(keys[n-1][0]),float(keys[n][0]),hour))
   return weather_shade(shade.lerp(Color(.10,.20,.34,.61),moon_amount()*.65))
 return weather_shade(keys[0][1])

func weather_shade(base:Color)->Color:
 var sky=weather()
 var strength=.19 if sky=="Cloudy" else .29 if sky=="Rain" else .12 if sky=="Mist" else 0.0
 if strength==0:return base
 # Cloud cover lowers daylight; nighttime lanterns remain readable.
 var result=base.lerp(Color("#334b61"),strength*.55)
 result.a=1-(1-base.a)*(1-strength*(1-night_amount()*.72))
 return result

func puddles_in(bounds:Rect2)->Array[Dictionary]:
 var result:Array[Dictionary]=[]
 if puddle_cells.size()>512:puddle_cells.clear()
 # Seed per world cell, never per frame/camera: positions stay stable while walking.
 for y in range(floori(bounds.position.y/170)-1,ceili(bounds.end.y/170)+1):
  for x in range(floori(bounds.position.x/210)-1,ceili(bounds.end.x/210)+1):
   var cell=Vector2i(x,y)
   if not puddle_cells.has(cell):
    var rng=RandomNumberGenerator.new();rng.seed=hash("wet:%d:%d" % [x,y])
    if rng.randf()<.36:puddle_cells[cell]={}
    else:
     var world=Vector2(x*210+rng.randf_range(10,200),y*170+rng.randf_range(8,162))
     puddle_cells[cell]={"world":world,"width":rng.randf_range(12,34),"depth":rng.randf_range(5,12),"turn":rng.randf_range(-.7,.7),"salt":rng.randi_range(0,100)}
   var puddle:Dictionary=puddle_cells[cell]
   if not puddle.is_empty() and bounds.grow(40).has_point(puddle.world):result.append(puddle)
 return result
func draw_puddles(c:Node2D,camera:Vector2)->void:
 if weather()!="Rain":return
 var drawn=0
 for puddle in puddles_in(Rect2(camera,c.VIEW)):
  if drawn>=28:break
  var world:Vector2=puddle.world
  if not c.can_stand_at(world):continue
  var p=world-camera;var polygon=PackedVector2Array()
  for n in 14:
   var angle=n*TAU/14
   polygon.append(p+(Vector2(cos(angle)*puddle.width,sin(angle)*puddle.depth)*(1+sin(n*2+puddle.salt)*.21)).rotated(puddle.turn))
  c.draw_colored_polygon(polygon,Color(.23,.43,.53,.65))
  c.draw_line(p+Vector2(-puddle.width*.5,-1),p+Vector2(puddle.width*.3,-1),Color(.74,.86,.88,.48),1.5,true)
  if int(puddle.salt)%3==0:c.draw_arc(p,3+fposmod(animation_seconds()*5+puddle.salt,8),0,TAU,14,Color(.75,.88,.91,.24),1,true)
  drawn+=1

func animation_seconds()->float:
 # Visual motion is independent of civil time and a frozen Dev clock preview.
 return animation_time_for_test if animation_time_for_test>=0 else Time.get_ticks_msec()/1000.0

func draw_weather(c:Node2D,camera:Vector2)->void:
 var sky=weather()
 var seconds=animation_seconds()
 var motion=preload("res://scripts/town_weather_motion.gd")
 if sky in ["Cloudy","Rain"]:
  var strength=.14*(1-night_amount()*.70)
  for cloud in motion.particles(camera,c.VIEW,seconds,true):
   var p:Vector2=cloud.world-camera
   c.draw_set_transform(p,-.12,Vector2(1,.48))
   for k in range(3,0,-1):c.draw_circle(Vector2.ZERO,185+k*28,Color(.06,.12,.20,strength*.12))
   c.draw_circle(Vector2(150,10),165,Color(.06,.12,.20,strength*.30));c.draw_circle(Vector2(-130,15),155,Color(.06,.12,.20,strength*.23))
   c.draw_set_transform(Vector2.ZERO)
 if sky=="Rain":
  for drop in motion.particles(camera,c.VIEW,seconds,false):
   var p:Vector2=drop.world-camera
   c.draw_line(p,p+Vector2(-3,15),Color(.74,.86,.91,.56),1,true)
 elif sky=="Mist":
  # Mist banks drift over the landscape too, rather than following the player.
  for cloud in motion.particles(camera,c.VIEW,seconds*.3,true):
   var p:Vector2=cloud.world-camera
   c.draw_set_transform(p,0,Vector2(1,.18))
   for k in range(3,0,-1):c.draw_circle(Vector2.ZERO,220+k*36,Color(.65,.8,.83,.035))
   c.draw_set_transform(Vector2.ZERO)

static func draw_lantern(c:Node2D,p:Vector2,lit:float)->void:
 preload("res://scripts/town_sprite_cache.gd").draw(c,"lantern_lit" if lit>.1 else "lantern",Rect2(p-Vector2(16,80),Vector2(32,96)))
static func draw_lantern_source(c:Node2D,p:Vector2,lit:float)->void:
 c.draw_circle(p,8,Color(0,0,0,.18))
 c.draw_rect(Rect2(p-Vector2(6,5),Vector2(12,6)),Color("#344c50"))
 c.draw_line(p,p-Vector2(0,48),Color("#52665e"),4)
 c.draw_rect(Rect2(p-Vector2(7,64),Vector2(14,19)),Color("#344c50"))
 c.draw_rect(Rect2(p-Vector2(4,61),Vector2(8,13)),Color("#ffe2a0") if lit>.1 else Color("#8d9985"))
 c.draw_colored_polygon(PackedVector2Array([p+Vector2(-10,-64),p+Vector2(0,-71),p+Vector2(10,-64)]),Color("#52665e"))

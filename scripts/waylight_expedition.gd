extends RefCounted
const SIZE=768.0
static func deposit_value(ring:int)->int:return 0 if ring<=0 else 4+mini(6,ring)
const ORIGIN=Vector2(16512,16512)
const THEMES=[{"name":"Grove Remnant","tile":"forest","prop":"tree","color":"#84bd94","foes":["bramble","archer"]},{"name":"Quarry Remnant","tile":"ash","prop":"crystal","color":"#e4b58e","foes":["imp","warlock"]},{"name":"Silverfall Remnant","tile":"river_grass","prop":"river_willow","color":"#82c9d4","foes":["waylight_reed","waylight_crab"]},{"name":"Frostbound Remnant","tile":"ice","prop":"ice_pillar","color":"#aedff1","foes":["frostling","ice_archer"]},{"name":"Lantern Marsh Remnant","tile":"marsh_floor","prop":"lantern_tree","color":"#b8d88d","foes":["wick_wisp","bog_bellringer"]},{"name":"Astral Remnant","tile":"astral_floor","prop":"star_obelisk","color":"#c5a8f2","foes":["star_mine","comet_urchin"]}]
var manager:Node
var chunks={}
var dead={}
var collected={}
var explored={}
var sleeping={}
var carried=0
var farthest=0
var guardian=false
const SEAL_CELLS=[Vector2i(3,0),Vector2i(3,3),Vector2i(0,4),Vector2i(-4,2),Vector2i(-3,-4),Vector2i(2,-5)]
const WARDENS=["Verdant Warden","Cinder Warden","Tide Warden","Rime Warden","Lantern Warden","Astral Warden"]
var trial_seconds=0.0
var seal_drops={}
func trial()->bool:return manager.kind=="attunement" and int(manager.ticket().get("trial_version",0))==2
func seals()->int:
 var count=0
 for cell in SEAL_CELLS:
  if collected.has("seal:"+key(cell)):count+=1
 return count
func trial_report()->Dictionary:return {"seals":seals(),"seconds":trial_seconds}
var current=Vector2i(999,999)
var pulse=0.0
var reveal=0.0
var fog_image:Image
var fog_texture:ImageTexture
var fog_camera=Vector2.ZERO
var fog_view=Vector2.ZERO
func max_ring()->int:return int(manager.ticket().get("depth",12))
func key(cell:Vector2i)->String:return "%d,%d" % [cell.x,cell.y]
func cell_at(p:Vector2)->Vector2i:return Vector2i(floori((p.x-ORIGIN.x+SIZE*.5)/SIZE),floori((p.y-ORIGIN.y+SIZE*.5)/SIZE))
func rng_for(cell:Vector2i)->RandomNumberGenerator:
 var rng=RandomNumberGenerator.new();rng.seed=abs(int(manager.ticket().seed)+cell.x*92837111+cell.y*689287499);return rng
func parent_cell(cell:Vector2i)->Vector2i:
 if cell==Vector2i.ZERO:return cell
 if cell.x==0:return cell-Vector2i(0,signi(cell.y))
 if cell.y==0:return cell-Vector2i(signi(cell.x),0)
 return cell-Vector2i(signi(cell.x),0) if rng_for(cell).randi()%2==0 else cell-Vector2i(0,signi(cell.y))
func linked(cell:Vector2i,dir:Vector2i)->bool:
 var next=cell+dir
 if maxi(absi(next.x),absi(next.y))>max_ring():return false
 if parent_cell(cell)==next or parent_cell(next)==cell:return true
 var low=cell if key(cell)<key(next) else next
 var rng=rng_for(low+Vector2i(317 if dir.x!=0 else 913,121))
 return rng.randf()<.22
func layout(cell:Vector2i)->Dictionary:
 var rng=rng_for(cell);var ring=maxi(absi(cell.x),absi(cell.y));var center=ORIGIN+Vector2(cell)*SIZE
 var cluster=Vector2i(floori(cell.x/2.0),floori(cell.y/2.0));var theme=posmod(cluster.x*13+cluster.y*7+int(manager.ticket().seed),THEMES.size() if int(manager.ticket().get("layout_version",1))>=2 else 3)
 if trial() and cell in SEAL_CELLS:theme=SEAL_CELLS.find(cell)
 if int(manager.ticket().get("layout_version",1))>=3 and not (trial() and cell in SEAL_CELLS):
  var allowed=preload("res://scripts/between_access.gd").themes(max_ring());theme=allowed[theme%allowed.size()]
 var form=rng.randi_range(0,3);var props=[]
 for n in 8:
  var p=center+Vector2([-1,1][n%2]*rng.randf_range(145,290),[-1,1][int(n/2)%2]*rng.randf_range(145,290))
  props.append([p.x,p.y])
 var water=water_for(cell,theme)
 if not water.is_empty():
  var wet=Vector2(water.water[0],water.water[1])
  props=props.filter(func(v):return Vector2(v[0],v[1]).distance_to(wet)>110)
 var creatures=[]
 if ring>0:
  for n in range(2+mini(3,int(ring/2))):
   var p=center+Vector2(rng.randf_range(-210,210),rng.randf_range(-210,210));creatures.append({"pos":[p.x,p.y],"type":preload("res://scripts/between_actors.gd").type_for(THEMES[theme].foes[n%2]),"id":key(cell)+":"+str(n),"boss":false})
  if ring>=3 and posmod(cell.x+cell.y,3)==0 and not (trial() and cell in SEAL_CELLS):
   creatures.append({"pos":[center.x,center.y],"type":"boss","id":key(cell)+":guardian","boss":true})
 # Fixed ring destinations within a newly seeded maze: six distinct, reachable Wardens.
 if trial() and cell in SEAL_CELLS:creatures.append({"pos":[center.x,center.y],"type":"boss","id":key(cell)+":seal","boss":true})
 var exits={}
 for dir in [Vector2i.LEFT,Vector2i.RIGHT,Vector2i.UP,Vector2i.DOWN]:exits[key(dir)]=linked(cell,dir)
 return {"exits":exits,"cell":[cell.x,cell.y],"center":center,"ring":ring,"theme":theme,"form":form,"props":props,"foes":creatures,"crystal":center+Vector2(0,125),"fishing":water}
func water_for(cell:Vector2i,theme:int)->Dictionary:
 var ring=maxi(absi(cell.x),absi(cell.y))
 if ring<4 or int(manager.ticket().get("layout_version",1))<2:return {}
 var rng=RandomNumberGenerator.new();rng.seed=abs(int(manager.ticket().seed)+cell.x*71237+cell.y*91283+54019)
 if rng.randf()>=.24:return {}
 var pool=["between_root","between_ember","between_root","between_frost","between_mist","between_star"][theme]
 var spot=preload("res://scripts/fishing_catalog.gd").pools()[pool].duplicate(true)
 # The bank sits on the guaranteed east/west corridor, with water just north.
 var at=ORIGIN+Vector2(cell)*SIZE+Vector2(185,0);spot.id=pool;spot.bank=[at.x,at.y];spot.water=[at.x,at.y-98];spot.cell=key(cell);return spot
func fishing_spots()->Array:
 var result=[]
 for chunk in chunks.values():
  if not chunk.get("fishing",{}).is_empty():result.append(chunk.fishing)
 return result
func open(p:Vector2)->bool:
 var cell=cell_at(p)
 if maxi(absi(cell.x),absi(cell.y))>max_ring():return false
 var data=chunks.get(key(cell),{})
 if data.is_empty():data=layout(cell)
 # A seeded spanning tree plus extra shared links makes every section reachable.
 for dir in [Vector2i.LEFT,Vector2i.RIGHT,Vector2i.UP,Vector2i.DOWN]:
  if bool(data.exits[key(dir)]):continue
  var offset=p-data.center
  if (dir.x<0 and offset.x< -SIZE*.5+42) or (dir.x>0 and offset.x>SIZE*.5-42) or (dir.y<0 and offset.y< -SIZE*.5+42) or (dir.y>0 and offset.y>SIZE*.5-42):return false
 var water:Dictionary=data.get("fishing",{})
 if not water.is_empty() and p.distance_to(Vector2(water.water[0],water.water[1]))<64:return false
 # Wide crossing corridors connect the module's open exits.
 var local=p-data.center
 if absf(local.x)<98 or absf(local.y)<98:return true
 if data.theme==2 and data.form==3 and absf(local.x)>130 and absf(local.y-155)<55:return false
 for v in data.props:
  if p.distance_to(Vector2(v[0],v[1]))<45:return false
 return true
func start()->void:
 chunks.clear();dead.clear();collected.clear();explored.clear();sleeping.clear();carried=0;farthest=0;guardian=false;current=Vector2i(999,999);pulse=0;reveal=0
 trial_seconds=0;seal_drops.clear()
 if trial():manager.game.level=10;manager.game.highest_level=10
 manager.game.position_in_world=ORIGIN;manager.game.update_camera();stream();reveal_map()
func stream()->void:
 var g=manager.game;var here=cell_at(g.position_in_world)
 if here==current:return
 current=here;farthest=maxi(farthest,maxi(absi(here.x),absi(here.y)))
 var wanted={}
 for y in range(here.y-2,here.y+3):
  for x in range(here.x-2,here.x+3):
   var cell=Vector2i(x,y)
   if maxi(absi(x),absi(y))<=max_ring():wanted[key(cell)]=cell
 for k in chunks.keys():
  if not wanted.has(k):chunks.erase(k)
 for i in range(g.enemies.size()-1,-1,-1):
  var foe=g.enemies[i]
  if not foe.has("between_id"):
   if foe.pos.distance_to(g.position_in_world)>1300:g.enemies.remove_at(i)
   continue
  var actor_cell=cell_at(foe.pos)
  if maxi(absi(actor_cell.x-here.x),absi(actor_cell.y-here.y))>1:sleeping[str(foe.between_id)]=manager.pack(foe);g.enemies.remove_at(i)
 for k in wanted:
  if not chunks.has(k):chunks[k]=layout(wanted[k])
 # Active actors are restricted to a 3x3 neighbourhood and capped at 48.
 for k in wanted:
  var data=chunks[k];var c=Vector2i(data.cell[0],data.cell[1])
  if maxi(absi(c.x-here.x),absi(c.y-here.y))>1:continue
  for entry in data.foes:
   var id=str(entry.id)
   if dead.has(id) or g.enemies.size()>=48:continue
   var exists=false
   for foe in g.enemies:
    if str(foe.get("between_id",""))==id:exists=true;break
   if exists:continue
   var p=Vector2(entry.pos[0],entry.pos[1])
   if not open(p):p=data.center
   var foe=manager.spawn(str(entry.type),p,1+data.ring*.18,bool(entry.boss))
   foe["between_id"]=id;foe["ring"]=data.ring
   if id.ends_with(":seal"):
    foe["attunement_warden"]=true;foe["warden_name"]=WARDENS[SEAL_CELLS.find(c)]
    foe.hp*=1.6;foe.max_hp=foe.hp
   if bool(entry.boss):
    foe["sprite"]=["bramble_boss","kiln_knight","crowned_torrent","cryowarden","bellroot","eclipse_engine"][int(data.theme)];g.load_sprite_pair(str(foe.sprite))
   if sleeping.has(id):foe=manager.unpack(sleeping[id]);sleeping.erase(id)
   g.enemies.append(preload("res://scripts/between_actors.gd").normalize(foe))
func reveal_map()->void:
 var g=manager.game;var cell=Vector2i(g.position_in_world/96)
 for y in range(cell.y-4,cell.y+5):
  for x in range(cell.x-4,cell.x+5):
   var p=Vector2(x*96+48,y*96+48)
   if p.distance_to(g.position_in_world)<365:explored[key(Vector2i(x,y))]=true
func step(delta:float)->void:
 stream();pulse+=delta;reveal+=delta
 if trial():trial_seconds+=delta
 if reveal>.18:reveal=0;reveal_map()
 var g=manager.game
 if trial():
  for id in seal_drops.keys():
   if g.position_in_world.distance_to(seal_drops[id])>=64:continue
   collected["seal:"+str(id)]=true;seal_drops.erase(id);guardian=seals()==6
   g.message="CROSSING SEAL %d / 6%s" % [seals()," • all six collected! Return to the entrance." if guardian else " • find the remaining Wardens"]
   g.message_time=6;manager.checkpoint()
 for k in chunks:
  var d=chunks[k]
  if d.ring==0 or collected.has(k):continue
  if g.position_in_world.distance_to(d.crystal)<68:
   var guarded=false
   for foe in g.enemies:
    if foe.pos.distance_to(d.crystal)<230:guarded=true;break
   if guarded:g.hint="Clear nearby guardians to gather Waylight";continue
   var amount=deposit_value(int(d.ring));collected[k]=true;carried+=amount
   g.message="Gathered %d Waylight • %d carried. Return to the entrance to bank it." % [amount,carried];g.message_time=4;manager.checkpoint()
 if g.position_in_world.distance_to(ORIGIN)<100:
  g.hint="E • Extract & bank %d Waylight" % carried
  if Input.is_action_just_pressed("interact"):g.finish_run(true)
 elif trial():g.hint="Crossing Seals %d / 6 • Wardens in rings 3–5 • return with all six" % seals()
 if farthest>=max_ring():g.hint="The outer fracture ends here. Return and bank your haul."
func defeated(foe:Dictionary)->void:
 if bool(foe.get("summoned",false)) or bool(foe.get("converted",false)) or not foe.has("between_id") or dead.has(str(foe.between_id)):return
 dead[str(foe.get("between_id","spawn"))]=true;sleeping.erase(str(foe.get("between_id","spawn")))
 carried+=8 if bool(foe.boss) else 1
 if str(foe.get("between_id","")).ends_with(":seal"):
  var cell_id=str(foe.between_id).trim_suffix(":seal");seal_drops[cell_id]=foe.pos
  manager.game.message="%s defeated • collect the glowing Crossing Seal" % str(foe.get("warden_name","Warden"));manager.game.message_time=6
 manager.game.kills+=1;manager.game.grant_enemy_xp(50 if foe.boss else 10)
func snapshot()->Dictionary:return {"dead":dead,"collected":collected,"explored":explored,"sleeping":sleeping,"carried":carried,"farthest":farthest,"guardian":guardian,"trial_seconds":trial_seconds,"seal_drops":seal_drops}
func restore(v:Dictionary)->void:
 trial_seconds=float(v.get("trial_seconds",0));seal_drops=v.get("seal_drops",{});dead=v.get("dead",{});collected=v.get("collected",{});explored=v.get("explored",{});sleeping=v.get("sleeping",{});carried=clampi(int(v.get("carried",0)),0,100000);farthest=clampi(int(v.get("farthest",0)),0,14);guardian=bool(v.get("guardian",false));current=Vector2i(999,999);stream();reveal_map()
func draw_ground(g:Node2D,camera:Vector2)->void:
 var view=Rect2(camera,g.VIEW).grow(100)
 for k in chunks:
  var d=chunks[k];var box=Rect2(d.center-Vector2.ONE*SIZE*.5,Vector2.ONE*SIZE)
  if not view.intersects(box):continue
  var theme=THEMES[d.theme];var pos=d.center-camera
  g.draw_texture_rect(g.art[theme.tile],Rect2(box.position-camera,box.size),true,Color(.72,.80,.84))
  var path=Color("#666963") if d.theme==0 else Color("#907b70") if d.theme==1 else Color("#718e91")
  g.draw_rect(Rect2(pos-Vector2(72,SIZE*.5),Vector2(144,SIZE)),path)
  g.draw_rect(Rect2(pos-Vector2(SIZE*.5,72),Vector2(SIZE,144)),path)
  if d.form==1:
   g.draw_arc(pos,165,0,TAU,32,Color(theme.color,.25),8,true)
   for n in 6:g.draw_circle(pos+Vector2.from_angle(n*TAU/6)*170,9,Color(theme.color,.65))
  elif d.form==2:
   for side in [-1,1]:g.draw_rect(Rect2(pos+Vector2(side*205-18,-70),Vector2(36,140)),Color("#789099"));g.draw_rect(Rect2(pos+Vector2(side*205-25,-78),Vector2(50,12)),Color(theme.color))
  elif d.form==3 and d.theme==2:
   g.draw_texture_rect(g.art.river_water,Rect2(pos+Vector2(-SIZE*.5,100),Vector2(SIZE,110)),true)
   g.draw_rect(Rect2(pos+Vector2(-125,90),Vector2(250,130)),Color("#ae9270"))
   for n in 10:g.draw_line(pos+Vector2(-120+n*25,90),pos+Vector2(-120+n*25,220),Color("#6c665a"),2)
  var cell=Vector2i(d.cell[0],d.cell[1])
  for dir in [Vector2i.LEFT,Vector2i.RIGHT,Vector2i.UP,Vector2i.DOWN]:
   if bool(d.exits[key(dir)]):continue
   var edge=d.center+Vector2(dir)*SIZE*.5-camera
   g.draw_rect(Rect2(edge-(Vector2(42,SIZE*.5) if dir.x!=0 else Vector2(SIZE*.5,42)),Vector2(84,SIZE) if dir.x!=0 else Vector2(SIZE,84)),Color("#30434b"))
   for n in 12:
    var p=edge+(Vector2(0,-352+n*64) if dir.x!=0 else Vector2(-352+n*64,0))
    if Rect2(Vector2.ZERO,g.VIEW).grow(100).has_point(p):g.draw_sprite(theme.prop,p+camera-Vector2(32,48),Vector2(64,84))
  for v in d.props:
   var p=Vector2(v[0],v[1])
   g.draw_sprite(theme.prop,p-Vector2(32,60),Vector2(64,84))
  var water:Dictionary=d.get("fishing",{})
  if not water.is_empty():
   var wet=Vector2(water.water[0],water.water[1])-camera
   g.draw_circle(wet,72,Color("#233f4d"));g.draw_circle(wet,61,Color(theme.color).darkened(.50));g.draw_arc(wet,66,0,TAU,28,Color(theme.color).darkened(.1),4,true)
   g.draw_line(wet+Vector2(-35,15),wet+Vector2(29,15),Color(.65,.88,.9,.35),2,true)
  if d.ring>0 and not collected.has(k):
   var p=d.crystal-camera
   for n in range(3,0,-1):g.draw_circle(p,17+n*7,Color(.4,.95,.9,.035))
   g.draw_colored_polygon(PackedVector2Array([p+Vector2(0,-26),p+Vector2(15,-6),p+Vector2(8,15),p+Vector2(-10,15),p+Vector2(-15,-6)]),Color(theme.color))
   g.draw_line(p+Vector2(0,-23),p+Vector2(3,12),Color("#efffec"),2,true)
 var p=ORIGIN-camera
 g.draw_arc(p,100,0,TAU,48,Color("#94ddcf"),3,true)
 g.draw_string(g.font,p+Vector2(-100,100),"STABLE CROSSING • EXTRACT",HORIZONTAL_ALIGNMENT_LEFT,-1,14,Color("#d8ead2"))
 if trial():
  for id in seal_drops:
   var pickup:Vector2=seal_drops[id]-camera
   if not view.has_point(pickup+camera):continue
   g.draw_circle(pickup,27,Color(.8,.6,1,.14));g.draw_arc(pickup,18,pulse,pulse+TAU*.85,6,Color("#ffe7a4"),3,true)
   g.draw_circle(pickup,9,Color("#b9edf3"));g.draw_string(g.font,pickup+Vector2(-52,45),"Crossing Seal",HORIZONTAL_ALIGNMENT_LEFT,-1,14,Color("#ffe7a4"))
 # Each Warden arena has a restrained seal ring and its own title.
 if trial():
  for n in SEAL_CELLS.size():
   var cell=SEAL_CELLS[n];var target=ORIGIN+Vector2(cell)*SIZE-camera
   if not view.has_point(target+camera) or dead.has(key(cell)+":seal"):continue
   g.draw_arc(target,100,pulse*.3,pulse*.3+TAU*.9,40,Color("#e5b779"),3,true)
   g.draw_string(g.font,target+Vector2(-90,-110),WARDENS[n],HORIZONTAL_ALIGNMENT_LEFT,-1,16,Color("#ffe8aa"))
func draw_fog(g:Node2D,camera:Vector2)->void:
 # One small alpha texture rather than thousands of world-sized fog objects.
 if fog_image==null:fog_image=Image.create(96,54,false,Image.FORMAT_RGBA8);fog_texture=ImageTexture.create_from_image(fog_image)
 if fog_camera.distance_to(camera)>20 or fog_view!=g.VIEW or reveal<.025:
  fog_camera=camera;fog_view=g.VIEW
  var seen_cache={}
  for y in 54:
   for x in 96:
    var p=camera+Vector2((x+.5)/96*g.VIEW.x,(y+.5)/54*g.VIEW.y)
    var cell=Vector2i(floori(p.x/96),floori(p.y/96))
    if not seen_cache.has(cell):seen_cache[cell]=explored.has(key(cell))
    var seen=bool(seen_cache[cell])
    var darkness=lerpf(0,.72 if seen else 1,smoothstep(215,365,p.distance_to(g.position_in_world)))
    fog_image.set_pixel(x,y,Color(.025,.04,.065,darkness))
  fog_texture.update(fog_image)
 g.draw_texture_rect(fog_texture,Rect2(Vector2.ZERO,g.VIEW),false)
 for n in 8:g.draw_rect(Rect2(Vector2.ONE*n*7,g.VIEW-Vector2.ONE*n*14),Color(.015,.025,.045,.045),false,8)
func draw_map(g:Node2D)->void:
 var corner=Vector2(g.VIEW.x-185,200);g.draw_rect(Rect2(corner,Vector2(165,165)),Color(.03,.08,.11,.93));g.draw_rect(Rect2(corner,Vector2(165,165)),Color("#82adac"),false,1)
 var center=corner+Vector2(82,82)
 for y in range(-6,7):
  for x in range(-6,7):
   var cell=Vector2i(current.x+x,current.y+y);var p=center+Vector2(x,y)*11
   var world=ORIGIN+Vector2(cell)*SIZE
   if explored.has(key(Vector2i(floori(world.x/96),floori(world.y/96)))):g.draw_rect(Rect2(p-Vector2.ONE*4,Vector2.ONE*8),Color("#507779"))
 var home=(Vector2.ZERO-Vector2(current))*11
 if absf(home.x)<75 and absf(home.y)<75:g.draw_circle(center+home,4,Color("#eddf9c"))
 if trial():
  for cell in SEAL_CELLS:
   if collected.has("seal:"+key(cell)):continue
   var offset=(Vector2(cell)-Vector2(current))*11
   if absf(offset.x)<75 and absf(offset.y)<75:g.draw_circle(center+offset,3,Color("#e9b5f7"))
 g.draw_circle(center,3,Color("#f5f9ee"));g.draw_string(g.font,corner+Vector2(8,158),"Explored crossings",HORIZONTAL_ALIGNMENT_LEFT,-1,12,Color("#b8d3d1"))

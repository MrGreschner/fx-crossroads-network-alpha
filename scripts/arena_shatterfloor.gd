extends RefCounted
## Authority owns tiles, layers, actions and simultaneous-fall scoring.
const TILE=80
const COLS=14
const ROWS=10
const STRIDE=1040
const BOARD=Vector2(1120,800)
const ORIGIN=Vector2(80,120)
const SPEED=260.0
const ROUND_LIMIT=85.0
var world_ref:WeakRef
var world:RefCounted:
 get:return world_ref.get_ref() if world_ref!=null else null
 set(value):world_ref=weakref(value) if value!=null else null
var cells:Array=[]
var layers:Dictionary={}
var grace:Dictionary={}
var hops:Dictionary={}
var hop_ready:Dictionary={}
var shove_ready:Dictionary={}
var protected:Dictionary={}
var eliminated:Dictionary={}
var points:Dictionary={}
var round_points:Dictionary={}
var shoves:Dictionary={}
var falls:Dictionary={}
var clock=0.0
var round_time=0.0
var round_number=1
var intermission=0.0
var banner=""
var button:Button
func active()->bool:return world!=null and world.game.mode=="arena" and world.map_id=="shatterfloor"
func playable(id:String)->bool:return active() and world.game.started and world.game.start_countdown<=0 and intermission<=0 and layers.has(id) and not eliminated.has(id) and world.game.positions.has(id)
func setup(w:RefCounted)->void:
 world=w;clock=0;round_number=1;intermission=0;points.clear();shoves.clear();falls.clear()
 if not active():return
 var g=world.game;g.FIELD=Rect2(Vector2.ZERO,Vector2(1280,3120));g.field_obstacles.clear();g.world_buildings.clear();g.world_patches.clear();g.world_decorations.clear();g.world_fountains.clear();g.world_spawns.clear();g.world_terrain="storm_floor";g.art[g.world_terrain]=load("res://assets/storm_floor.png")
 for member in g.fighters():points[str(member.id)]=0;shoves[str(member.id)]=0;falls[str(member.id)]=0
 reset_round()
 if DisplayServer.get_name()!="headless" and not is_instance_valid(button):
  var layer=CanvasLayer.new();layer.layer=32;g.add_child(layer);button=preload("res://scripts/shatter_controls.gd").new();button.game=g;layer.add_child(button);button.text="HOP • RIGHT CLICK / SHIFT";button.add_theme_font_size_override("font_size",13)
  for state in ["normal","hover","pressed","disabled"]:button.add_theme_stylebox_override(state,preload("res://scripts/studio_ui.gd").box("#254652","#94e4d9",8,8))
  button.pressed.connect(func():request("secondary"))
func spawn(slot:int)->Vector2:return ORIGIN+BOARD*.5+Vector2.from_angle(TAU*(slot%8)/8)*Vector2(340,230)
func move_actor(id:String,p:Vector2)->void:
 var g=world.game
 if g.get("dedicated")==true:g.network_relocate(id,p)
 else:
  g.positions[id]=p
  if id==g.my_id:g.local_pos=p;g.dodge_time=0
func reset_round()->void:
 cells.clear();layers.clear();grace.clear();hops.clear();hop_ready.clear();shove_ready.clear();protected.clear();eliminated.clear();round_points.clear();round_time=0
 for floor_index in 3:
  var board=[];board.resize(COLS*ROWS);board.fill(-1.0);cells.append(board)
 var g=world.game;var n=0
 for id in points:
  if not g.positions.has(id):continue
  layers[id]=0;grace[id]=clock+.8;g.health[id]=g._max_hp(id);g.respawn_at[id]=0;g.levels[id]=10;g.inventory[id]=[];g.food_slots[id]=""
  if g.get("net_dash")!=null:g.net_dash.erase(id)
  move_actor(id,spawn((n+round_number-1)%8));n+=1
 banner="ROUND %d / 3 • KEEP MOVING" % round_number
func local_point(id:String,p:Vector2)->Vector2:return p-ORIGIN-Vector2(0,int(layers.get(id,0))*STRIDE)
func tile_index(id:String,p:Vector2)->int:
 var q=local_point(id,p)
 if q.x<0 or q.y<0 or q.x>=BOARD.x or q.y>=BOARD.y:return -1
 return floori(q.y/TILE)*COLS+floori(q.x/TILE)
func remaining(layer:int,index:int)->float:
 if layer<0 or layer>=cells.size() or index<0 or index>=COLS*ROWS:return 0.0
 var deadline=float(cells[layer][index]);return INF if deadline<0 else maxf(0,deadline-clock)
func airborne(id:String)->bool:return float(hops.get(id,{}).get("until",0))>clock
func action(id:String,kind:String,direction:Vector2)->bool:
 var g=world.game
 if g.role!="host" or not playable(id) or not direction.is_finite() or direction.length_squared()<.01:return false
 direction=direction.normalized()
 if kind=="secondary" or kind=="dodge":
  if clock<float(hop_ready.get(id,0)):return false
  hops[id]={"until":clock+.34,"direction":[direction.x,direction.y]};hop_ready[id]=clock+2.5;g.dodge_at[id]=Time.get_ticks_msec()+2500;return true
 if kind!="primary" or clock<float(shove_ready.get(id,0)) or airborne(id):return false
 shove_ready[id]=clock+.75;g.cooldown_at[id]["primary"]=Time.get_ticks_msec()+750;g.attack_pose_until[id]=Time.get_ticks_msec()+180
 var origin:Vector2=g.positions[id]
 g._emit_effect({"pos":origin+direction*55,"radius":38.0,"time":.18,"color":"#9cf5e2"})
 for other in layers:
  if other==id or int(layers[other])!=int(layers[id]) or not playable(other) or g.pvp_rule=="teams" and int(g.teams.get(other,0))==int(g.teams.get(id,0)) or clock<float(protected.get(other,0)) or airborne(other):continue
  var delta:Vector2=g.positions[other]-origin
  if delta.length()>112 or delta.normalized().dot(direction)<.45:continue
  var next:Vector2=g.positions[other]+direction*64
  move_actor(other,next);protected[other]=clock+1.1;shoves[id]=int(shoves.get(id,0))+1
 return true
func request(kind:String)->void:
 if not active():return
 var g=world.game;var aim:Vector2=g.mobile.aim if g.mobile.enabled else (g.media_mouse_world()-g.local_pos).normalized()
 if kind=="secondary":
  var movement:Vector2=g.mobile.movement if g.mobile.enabled else Input.get_vector("move_left","move_right","move_up","move_down")
  if movement.length_squared()>.01:aim=movement.normalized()
 if aim.length_squared()<.01:aim=g.last_aim
 if g.role=="host":action(g.my_id,kind,aim)
 elif kind in ["primary","secondary"] and Time.get_ticks_msec()>=int(g.request_ready.get(kind,0)):
  g.request_ready[kind]=Time.get_ticks_msec()+250
  g._send_channel(g.host_id,{"type":"attack","style":kind,"angle":aim.angle(),"target":[g.local_pos.x+aim.x*100,g.local_pos.y+aim.y*100]})
func fall(id:String)->void:
 if eliminated.has(id):return
 var g=world.game;falls[id]=int(falls.get(id,0))+1;hops.erase(id)
 if int(layers[id])>=2:
  eliminated[id]=round_time;g.health[id]=0;g.respawn_at[id]=0;banner="%s fell through the final floor" % player_name(id)
 else:
  var q=local_point(id,g.positions[id]).clamp(Vector2(20,20),BOARD-Vector2(20,20));layers[id]=int(layers[id])+1;grace[id]=clock+.45
  move_actor(id,ORIGIN+q+Vector2(0,int(layers[id])*STRIDE));banner="FLOOR %d • FIND A SAFE ROUTE" % (int(layers[id])+1)
func group(id:String)->String:return "team:"+str(world.game.teams.get(id,0)) if world.game.pvp_rule=="teams" else id
func player_name(id:String)->String:
 if id.begins_with("team:"):return "Blue team" if id=="team:0" else "Red team"
 for member in world.game.roster:
  if str(member.id)==id:return str(member.name)
 return id
func totals()->Dictionary:
 var result={}
 for id in points:
  var key=group(id);result[key]=int(result.get(key,0))+int(points[id])
 return result
func winners()->Array:
 var total=totals();var best=-1;var result=[]
 for key in total:
  if int(total[key])>best:best=int(total[key]);result=[key]
  elif int(total[key])==best:result.append(key)
 return result
func outcome(id:String)->String:return "loss" if group(id) not in winners() else "win" if winners().size()==1 else "draw"
func finish_round()->void:
 var entrants=layers.keys()
 for id in entrants:
  var survived=float(eliminated.get(id,round_time+.01));var award=1
  for other in entrants:
   if float(eliminated.get(other,round_time+.01))<survived-.0001:award+=1
  points[id]=int(points.get(id,0))+award;round_points[id]=award
 intermission=4.0;banner="ROUND %d COMPLETE • +%d POINTS" % [round_number,int(round_points.get(world.game.my_id,0))]
 if round_number==3:
  var leaders=winners();world.game.end_match("Shatterfloor • "+(player_name(str(leaders[0]))+" wins" if leaders.size()==1 else "Draw")+" • three rounds")
func step(dt:float)->void:
 if not active() or world.game.role!="host" or not world.game.started or world.game.start_countdown>0:return
 clock+=dt
 if intermission>0:
  intermission=maxf(0,intermission-dt)
  if intermission<=0:round_number+=1;reset_round()
  return
 round_time+=dt;var g=world.game
 # Late-round erosion cracks a predictable outside-in ring with a full warning.
 var ring=int((round_time-22)/7)
 if round_time>=22:
  for floor_index in 3:
   for index in COLS*ROWS:
    var edge=mini(mini(index%COLS,COLS-1-index%COLS),mini(index/COLS,ROWS-1-index/COLS))
    if edge<=ring and float(cells[floor_index][index])<0:cells[floor_index][index]=clock+1.5+floor_index*.2
 for id in layers:
  if not g.positions.has(id):eliminated[id]=round_time;continue
  if eliminated.has(id):continue
  if airborne(id):
   var h:Dictionary=hops[id];var direction=Vector2(float(h.direction[0]),float(h.direction[1]));g.positions[id]+=direction*390*dt
   if id==g.my_id:g.local_pos=g.positions[id]
   continue
  var index=tile_index(id,g.positions[id]);var layer=int(layers[id])
  if clock<float(grace.get(id,0)):continue
  if remaining(layer,index)<=0:fall(id)
  elif float(cells[layer][index])<0:cells[layer][index]=clock+.85
 var alive_groups=[]
 for id in layers:
  if not eliminated.has(id) and group(id) not in alive_groups:alive_groups.append(group(id))
 var initial_groups=[]
 for id in layers:
  if group(id) not in initial_groups:initial_groups.append(group(id))
 if alive_groups.is_empty() or initial_groups.size()>1 and alive_groups.size()<=1 or round_time>=ROUND_LIMIT:finish_round()
func bot_step(id:String,dt:float,state:Dictionary)->void:
 if not playable(id) or airborne(id):return
 var g=world.game;var p:Vector2=g.positions[id];var layer=int(layers[id]);var best=Vector2.ZERO;var weight=-INF
 var previous:Vector2=state.get("shatter_wish",Vector2.RIGHT.rotated(hash(id)%6))
 for n in 16:
  var direction=Vector2.from_angle(TAU*n/16);var q=p+direction*82;var index=tile_index(id,q);var time=remaining(layer,index)
  if time<.4:continue
  var score=minf(time,4)+direction.dot(previous)*.7
  for k in 4:
   var near=tile_index(id,q+Vector2.from_angle(k*PI/2)*75)
   if remaining(layer,near)>.5:score+=.35
  if score>weight:weight=score;best=direction
 state.shatter_wish=best
 if best.is_zero_approx():
  for n in 16:
   var direction=Vector2.from_angle(TAU*n/16)
   if remaining(layer,tile_index(id,p+direction*150))>.5:action(id,"secondary",direction);break
 else:g.positions[id]=p+best*SPEED*dt
 for other in layers:
  if other!=id and playable(other) and int(layers[other])==layer and g._rival(id,other) and p.distance_to(g.positions[other])<110:action(id,"primary",(g.positions[other]-p).normalized());break
func snapshot()->Dictionary:return {"clock":clock,"round_time":round_time,"round":round_number,"intermission":intermission,"cells":cells,"layers":layers,"grace":grace,"hops":hops,"hop_ready":hop_ready,"shove_ready":shove_ready,"eliminated":eliminated,"points":points,"round_points":round_points,"shoves":shoves,"falls":falls,"banner":banner}
func receive(data:Dictionary)->void:
 clock=float(data.get("clock",clock));round_time=float(data.get("round_time",round_time));round_number=int(data.get("round",round_number));intermission=float(data.get("intermission",0));cells=data.get("cells",cells);layers=data.get("layers",layers);grace=data.get("grace",grace);hops=data.get("hops",hops);hop_ready=data.get("hop_ready",hop_ready);shove_ready=data.get("shove_ready",shove_ready);eliminated=data.get("eliminated",eliminated);points=data.get("points",points);round_points=data.get("round_points",round_points);shoves=data.get("shoves",shoves);falls=data.get("falls",falls);banner=str(data.get("banner",banner))
func header()->String:return "SHATTERFLOOR • ROUND %d / 3 • %ds • %s" % [round_number,maxi(0,ceili(ROUND_LIMIT-round_time)),"NEXT ROUND IN %d" % ceili(intermission) if intermission>0 else "FLOOR %d / 3" % (int(layers.get(world.game.my_id,0))+1)]
func draw_ground()->void:
 if not active():return
 var g=world.game;var bounds=Rect2(g.camera,g.VIEW);g.draw_rect(Rect2(-g.camera,g.FIELD.size),Color("#0b172b"))
 var colors=[Color("#65c9bd"),Color("#8196dc"),Color("#d8a264")]
 for layer in 3:
  var origin=ORIGIN+Vector2(0,layer*STRIDE)
  if not bounds.intersects(Rect2(origin,BOARD).grow(80)):continue
  g.draw_rect(Rect2(origin-g.camera-Vector2(12,12),BOARD+Vector2(24,24)),Color("#233953"),false,4)
  for index in COLS*ROWS:
   var p=origin+Vector2(index%COLS,index/COLS)*TILE-g.camera;var rect=Rect2(p+Vector2(3,3),Vector2(TILE-6,TILE-6));var time=remaining(layer,index)
   if time<=0:
    g.draw_rect(rect,Color("#101b30"));g.draw_line(p+Vector2(24,26),p+Vector2(42,38),Color("#33415c"),2);continue
   var tint=colors[layer].darkened(.35) if is_inf(time) else Color("#edb36b").lerp(Color("#ee6b69"),1-clampf(time/.85,0,1))
   g.draw_rect(Rect2(rect.position+Vector2(0,6),rect.size),tint.darkened(.65));g.draw_rect(rect,tint);g.draw_rect(rect,tint.lightened(.25),false,1)
   if not is_inf(time):
    g.draw_polyline(PackedVector2Array([p+Vector2(15,3),p+Vector2(34,28),p+Vector2(24,42),p+Vector2(48,60),p+Vector2(42,77)]),Color("#402d39"),3,true);g.draw_line(p+Vector2(34,28),p+Vector2(70,18),Color("#402d39"),2)
  g.draw_string(ThemeDB.fallback_font,origin-g.camera+Vector2(5,-24),["01 • JADE DECK","02 • TWILIGHT DECK","03 • LAST CHANCE"][layer],HORIZONTAL_ALIGNMENT_LEFT,500,22,colors[layer])
func draw_hud()->void:
 if not active():return
 var g=world.game;var font=ThemeDB.fallback_font;var width=minf(650,g.VIEW.x-40);var y=100.0
 g.draw_style_box(preload("res://scripts/studio_ui.gd").box("#11283b","#81cfc6",8,8),Rect2(20,y,width,82))
 var eliminated_local=eliminated.has(g.my_id)
 var text="OUT THIS ROUND • Watch the survivors below" if eliminated_local else "STEP • CRACK • FALL • Shove rivals • Hop across gaps"
 if intermission>0:text="ROUND COMPLETE • Next round in %ds" % ceili(intermission)
 g.draw_string(font,Vector2(31,y+23),text,HORIZONTAL_ALIGNMENT_LEFT,width-20,14,Color("#e5ecdf"))
 var x=31.0
 for layer in 3:
  var count=0
  for id in layers:
   if int(layers[id])==layer and not eliminated.has(id):count+=1
  var tint=Color("#95e2d5") if int(layers.get(g.my_id,0))==layer else Color("#8da7c1")
  g.draw_string(font,Vector2(x,y+47),"FLOOR %d: %d" % [layer+1,count],HORIZONTAL_ALIGNMENT_LEFT,140,13,tint);x+=minf(145,width/3)
 g.draw_string(font,Vector2(31,y+70),"YOUR SCORE: %d   •   3 ROUNDS   •   NO HEALTH DAMAGE" % int(points.get(g.my_id,0)),HORIZONTAL_ALIGNMENT_LEFT,width-20,13,Color("#f0cd8b"))
func draw_minimap()->void:
 if not active():return
 var g=world.game;var p=Vector2(g.VIEW.x-200,195);var font=ThemeDB.fallback_font
 g.draw_style_box(preload("res://scripts/studio_ui.gd").box("#11283b","#6f929e",7,7),Rect2(p,Vector2(180,151)))
 var n=0
 for id in points:
  var state="OUT" if eliminated.has(id) else "F%d" % (int(layers.get(id,0))+1)
  g.draw_string(font,p+Vector2(9,19+n*16),player_name(id).left(12)+"  "+state+"  "+str(points[id]),HORIZONTAL_ALIGNMENT_LEFT,165,12,Color("#f3d795") if id==g.my_id else Color("#bbd2de"));n+=1
func report()->Dictionary:return {"round":round_number,"round_time":round_time,"points":points,"layers":layers,"shoves":shoves,"falls":falls,"eliminated":eliminated.size()}
func camera_point(fallback:Vector2)->Vector2:
 if not active() or not eliminated.has(world.game.my_id):return fallback
 for id in layers:
  if not eliminated.has(id) and world.game.positions.has(id):return world.game._player_draw_position(id,world.game.positions[id])
 return fallback
func draw_overlay()->void:
 var g=world.game;var font=ThemeDB.fallback_font
 g.draw_style_box(preload("res://scripts/studio_ui.gd").box("#102637","#70b8ba",8,7),Rect2(16,14,g.VIEW.x-32,70))
 g.draw_string(font,Vector2(30,40),"SHATTERFLOOR • ROUND %d / 3" % round_number,HORIZONTAL_ALIGNMENT_LEFT,g.VIEW.x-50,21,Color("#e4eee5"))
 g.draw_string(font,Vector2(30,66),"%ds left • %s • Equal movement for every hero" % [maxi(0,ceili(ROUND_LIMIT-round_time)),"ROUND BREAK" if intermission>0 else "FLOOR %d / 3" % (int(layers.get(g.my_id,0))+1)],HORIZONTAL_ALIGNMENT_LEFT,g.VIEW.x-50,14,Color("#9fd6cf"))
 draw_hud();draw_minimap()
 if not g.mobile.enabled:
  var width=minf(590,g.VIEW.x-40);var p=Vector2(20,g.VIEW.y-74)
  g.draw_style_box(preload("res://scripts/studio_ui.gd").box("#122c3b","#749da7",8,7),Rect2(p,Vector2(width,57)))
  g.draw_string(font,p+Vector2(12,22),"MOVE: WASD / ARROWS     SHOVE: LEFT CLICK     HOP: RIGHT CLICK / SHIFT",HORIZONTAL_ALIGNMENT_LEFT,width-20,13,Color("#e3e6d6"))
  var ready=maxf(0,float(hop_ready.get(g.my_id,0))-clock)
  g.draw_string(font,p+Vector2(12,44),"HOP READY" if ready<=0 else "HOP RECHARGING • %.1fs" % ready,HORIZONTAL_ALIGNMENT_LEFT,width-20,13,Color("#99e5d3"))

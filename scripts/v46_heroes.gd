extends Node
## Shared original-hero overhaul and Iris's authored chalk geometry.
var combat:Node
var books:Dictionary={}
var page_turn:Dictionary={}
var held:Dictionary={}
var bounces:Array=[]
var spins:Array=[]
var strikes:Array=[]
var strokes:Array=[]
var grids:Array=[]
const STYLES=["identity_strike","body_bounce","page_channel","cat_sweep","chalkstroke","erase_release","chalk_grid"]
func reset()->void:
 books.clear();page_turn.clear();held.clear();bounces.clear();spins.clear();strikes.clear();strokes.clear();grids.clear()
func holding(owner:String,pressed:bool)->void:
 held[owner]=.45 if pressed else 0.0
 if not pressed:books.erase(owner)
func channeling(owner:String)->bool:return books.has(owner)
func moving(owner:String)->bool:
 for entry in bounces:
  if str(entry.owner)==owner:return true
 return false
func locked(owner:String)->bool:return (channeling(owner) and (combat.adventure.game.get("legacy")==null or combat.adventure.game.legacy.channel_speed(owner)<=0)) or moving(owner)
func hero_id(owner:String)->String:
 if owner=="training_ally":return ""
 return str(combat.adventure.game.hero_ids.get(owner,"ram")) if combat.adventure.arcade else str(combat.adventure.game.selected_character)
func page_hero(owner:String)->bool:
 var game:Node=combat.adventure.game
 var hero:Dictionary=game.characters.get(hero_id(owner),{}) if combat.adventure.arcade else game.hero
 return str(hero.get("secondary",{}).get("style",""))=="page_channel"
func nearest(owner:String,origin:Vector2,reach:float,exclude:Array,aim:Vector2=Vector2.ZERO)->String:
 var found:="";var best:=INF
 for key in combat.hostile(owner):
  if exclude.has(key):continue
  var target:Dictionary=combat.actor(key)
  if target.is_empty() or not bool(target.get("alive",false)) or origin.distance_to(target.pos)>reach or not combat.path_clear(origin,target.pos):continue
  var distance:float=origin.distance_to(target.pos)
  if not aim.is_zero_approx():distance*=1.0+.7*(1.0-aim.dot((target.pos-origin).normalized()))
  if distance<best:found=key;best=distance
 return found
func heal(owner:String,amount:int)->void:
 if combat.adventure.arcade:combat.adventure.game._heal(owner,owner,amount)
 else:
  var game:Node=combat.adventure.game
  var before:float=game.health;game.health=minf(game.max_health(),game.health+amount*combat.v98.heal_factor(owner))
  if game.health>before:combat.feedback.hit(game.position_in_world,game.health-before,owner,true);game.add_float_text(game.position_in_world-Vector2(20,50),"+"+str(int(game.health-before)),Color("#95dfbe"))
func cast(owner:String,stats:Dictionary,aim:Vector2,amount:float)->bool:
 var style:=str(stats.get("style",""))
 if style not in STYLES:return false
 if not combat.adventure.authoritative() or not combat.adventure.alive(owner):return true
 var origin:Vector2=combat.owner_pos(owner);aim=aim.normalized()
 if aim.is_zero_approx():aim=Vector2.RIGHT
 match style:
  "identity_strike":
   if strikes.size()<32:strikes.append({"owner":owner,"pos":combat.point_array(origin),"aim":combat.point_array(aim),"action_seq":int(combat.adventure.game.get_meta("fx_action_seq",-1)),"visual":str(stats.get("visual","horns")),"range":float(stats.get("range",86)),"time":.26})
   for key in combat.hostile(owner):
    var target:Dictionary=combat.actor(key)
    if target.is_empty():continue
    var offset:Vector2=target.pos-origin;var radius:=float(target.get("npc",{}).get("hit_radius",0))
    if offset.length()<=float(stats.get("range",86))+radius and aim.dot(offset.normalized())>=cos(deg_to_rad(float(stats.get("arc_degrees",105))*.5)) and combat.path_clear(origin,target.pos):
     combat.apply_hit_status(key,stats,owner);combat.damage(key,amount,owner)
  "page_channel":
   if not books.has(owner) and float(held.get(owner,0))>0:books[owner]={"owner":owner,"tick":0.0,"damage":amount,"stats":stats.duplicate(true)}
  "body_bounce":
   if moving(owner) or bounces.size()>=8:return true
   var target:=nearest(owner,origin,float(stats.get("range",350)),[],aim)
   if not target.is_empty():bounces.append({"owner":owner,"target":target,"leg_start":combat.point_array(origin),"reach":float(stats.get("range",350)),"end":combat.point_array(combat.actor(target).pos),"hits":[],"attempted":[target],"time":0.0,"damage":amount,"jump_range":float(stats.get("jump_range",260)),"speed":650.0})
  "cat_sweep":
   if spins.size()<16:spins.append({"owner":owner,"angle":aim.angle(),"elapsed":0.0,"duration":.6,"radius":float(stats.get("range",128)),"damage":amount,"hits":[]})
  "chalkstroke":
   var end:Vector2=combat.chain.clip(origin,aim,clampf(float(stats.get("range",250)),60,350))
   var owned:Array=[]
   for entry in strokes:
    if str(entry.owner)==owner:owned.append(entry)
   if owned.size()>=3:strokes.erase(owned[0])
   if strokes.size()<24:strokes.append({"owner":owner,"start":combat.point_array(origin),"end":combat.point_array(end),"time":float(stats.get("duration",4)),"elapsed":0.0,"damage":amount,"hits":[]})
  "erase_release":
   var count:=0
   for entry in strokes.duplicate():
    if str(entry.owner)!=owner:continue
    count+=1
    var point:Vector2=combat.vec(entry.start).lerp(combat.vec(entry.end),.5)
    for n in 2:
     combat.launch_projectile(owner,point,aim.rotated((n-.5)*.5),{"range":450,"speed":340,"color":"#eff1ca","chalk_shard":true},amount,"homing")
    strokes.erase(entry)
   if count==0:combat.launch_projectile(owner,origin+aim*24,aim,{"range":450,"speed":340,"color":"#eff1ca","chalk_shard":true},amount,"homing")
   if count>0 and combat.passive(owner,"second_draft"):heal(owner,count*3)
  "chalk_grid":
   if grids.size()>=8:return true
   var point:Vector2=combat.chain.clip(origin,aim,float(stats.get("range",180)))
   grids.append({"owner":owner,"pos":combat.point_array(point),"time":float(stats.get("duration",4)),"tick":0.0,"damage":amount,"width":300.0,"height":220.0})
 return true
func step(delta:float)->void:
 if not combat.adventure.authoritative():return
 for owner in held:held[owner]=maxf(0,float(held[owner])-delta)
 for owner in books.keys():
  var entry:Dictionary=books[owner]
  if float(held.get(owner,0))<=0 or not combat.adventure.alive(str(owner)) or not page_hero(str(owner)) or combat.stunned(combat.player_key(str(owner))):books.erase(owner);continue
  entry.tick+=minf(delta,.25)
  var interval:float=float(entry.stats.get("page_interval",.22))
  if float(entry.tick)>=interval:
   entry.tick-=interval
   var origin:Vector2=combat.owner_pos(str(owner));var targets:Array=[]
   for key in combat.hostile(str(owner)):
    var target:Dictionary=combat.actor(key)
    if not target.is_empty() and bool(target.get("alive",false)) and origin.distance_to(target.pos)<=float(entry.stats.get("range",460)) and combat.path_clear(origin,target.pos):targets.append(str(key))
   targets.sort_custom(func(a,b):return origin.distance_squared_to(combat.actor(a).pos)<origin.distance_squared_to(combat.actor(b).pos))
   if not targets.is_empty():
    var turn:int=int(page_turn.get(owner,0));page_turn[owner]=turn+1
    # Alternate nearest-target pages with a round-robin through every other visible target.
    var index:int=0 if targets.size()==1 or turn%2==0 else 1+(turn/2)% (targets.size()-1)
    var key:String=targets[index]
    combat.launch_projectile(str(owner),origin,(combat.actor(key).pos-origin).normalized(),{"name":"Flying Pages","range":float(entry.stats.get("range",460)),"speed":340,"color":"#f2e7c8","flying_page":true,"homing_target":key},float(entry.damage),"homing")
 for i in range(strikes.size()-1,-1,-1):
  strikes[i].time-=delta
  if float(strikes[i].time)<=0:strikes.remove_at(i)
 for i in range(strokes.size()-1,-1,-1):
  var stroke:Dictionary=strokes[i];stroke.time-=delta;stroke.elapsed+=delta
  if float(stroke.time)<=0 or not combat.adventure.alive(str(stroke.owner)):strokes.remove_at(i);continue
  var start:Vector2=combat.vec(stroke.start);var end:Vector2=start.lerp(combat.vec(stroke.end),minf(1,float(stroke.elapsed)/.45))
  for key in combat.hostile(str(stroke.owner)):
   if (stroke.hits as Array).has(key):continue
   var target:Dictionary=combat.actor(key)
   if not target.is_empty() and Geometry2D.get_closest_point_to_segment(target.pos,start,end).distance_to(target.pos)<25 and combat.path_clear(start,target.pos):stroke.hits.append(key);combat.damage(key,float(stroke.damage),str(stroke.owner))
 for i in range(grids.size()-1,-1,-1):
  var grid:Dictionary=grids[i];grid.time-=delta;grid.tick+=minf(delta,.5)
  if not combat.adventure.alive(str(grid.owner)):grids.remove_at(i);continue
  var point:Vector2=combat.vec(grid.pos);var area:=Rect2(point-Vector2(150,110),Vector2(300,220))
  var hit:=float(grid.tick)>=.5
  if hit:grid.tick-=.5
  for key in combat.hostile(str(grid.owner)):
   var target:Dictionary=combat.actor(key)
   if target.is_empty() or not area.has_point(target.pos) or not combat.path_clear(point,target.pos):continue
   combat.apply_status(key,"slow",.2,str(grid.owner),.65)
   if hit:combat.damage(key,float(grid.damage),str(grid.owner))
  if float(grid.time)<=0:grids.remove_at(i)
 var pieces:=maxi(1,ceili(minf(delta,1)/.025))
 for n in pieces:advance(minf(delta,1)/pieces)
func advance(delta:float)->void:
 for i in range(bounces.size()-1,-1,-1):
  var entry:Dictionary=bounces[i];var owner:=str(entry.owner);entry.time+=delta
  if not combat.adventure.alive(owner) or combat.stunned(combat.player_key(owner)) or float(entry.time)>2.4:bounces.remove_at(i);continue
  var origin:Vector2=combat.owner_pos(owner)
  var live:Dictionary=combat.actor(str(entry.target))
  if not live.is_empty():
   if combat.vec(entry.leg_start).distance_to(live.pos)>float(entry.reach)+80 or not combat.path_clear(origin,live.pos):bounces.remove_at(i);continue
   entry.end=combat.point_array(live.pos)
  var end:Vector2=combat.vec(entry.end)
  var proposed:=origin.move_toward(end,float(entry.speed)*delta)
  var next:Vector2=combat.chain.clip(origin,(proposed-origin).normalized(),origin.distance_to(proposed))
  combat.chain.move_owner(owner,next)
  if next.distance_to(end)>2 and not (next==origin and proposed!=origin):continue
  var target:Dictionary=combat.actor(str(entry.target))
  if not target.is_empty() and next.distance_to(target.pos)<65 and combat.path_clear(next,target.pos):entry.hits.append(str(entry.target));combat.damage(str(entry.target),float(entry.damage),owner)
  if (entry.attempted as Array).size()>=3 or next.distance_to(end)>2:bounces.remove_at(i);continue
  var key:=nearest(owner,next,float(entry.jump_range),entry.attempted)
  if key.is_empty():bounces.remove_at(i);continue
  entry.target=key;entry.attempted.append(key);entry.leg_start=combat.point_array(next);entry.reach=entry.jump_range;entry.end=combat.point_array(combat.actor(key).pos)
 for i in range(spins.size()-1,-1,-1):
  var entry:Dictionary=spins[i];var owner:=str(entry.owner)
  if not combat.adventure.alive(owner):spins.remove_at(i);continue
  var old:=float(entry.elapsed);entry.elapsed=minf(float(entry.duration),old+delta)
  var origin:Vector2=combat.owner_pos(owner);var angle:=float(entry.angle)+TAU*float(entry.elapsed)/float(entry.duration)
  for key in combat.hostile(owner):
   if (entry.hits as Array).has(key):continue
   var target:Dictionary=combat.actor(key)
   if target.is_empty():continue
   var offset:Vector2=target.pos-origin
   if offset.length()<=float(entry.radius) and absf(wrapf(offset.angle()-angle,-PI,PI))<.45 and combat.path_clear(origin,target.pos):entry.hits.append(key);combat.damage(key,float(entry.damage),owner)
  if float(entry.elapsed)>=float(entry.duration):spins.remove_at(i)
func spinning(owner:String)->bool:
 for entry in spins:
  if str(entry.owner)==owner:return true
 return false
func snapshot()->Dictionary:return {"books":books,"bounces":bounces,"spins":spins,"strikes":strikes,"strokes":strokes,"grids":grids}
func receive(data:Dictionary)->void:
 books=data.get("books",{});bounces=data.get("bounces",[]);spins=data.get("spins",[]);strikes=data.get("strikes",[]);strokes=data.get("strokes",[]);grids=data.get("grids",[])
func strike_origin(entry:Dictionary)->Vector2:
 var owner=str(entry.owner)
 var game=combat.adventure.game
 if combat.adventure.arcade and game.has_method("melee_visual_position"):
  return game.melee_visual_position(owner,combat.vec(entry.pos))
 return combat.owner_pos(owner)
func draw_on(canvas:Node2D,camera:Vector2)->void:
 var drawing=strikes.duplicate()
 var game=combat.adventure.game
 if combat.adventure.arcade and game.has_method("predicted_identity_strikes"):
  drawing=drawing.filter(func(x):return not game.suppress_confirmed_strike(x))
  drawing.append_array(game.predicted_identity_strikes())
 for entry in drawing:
  if not combat.visible_owner(str(entry.owner)):continue
  var origin:Vector2=strike_origin(entry)-camera;var aim:Vector2=combat.vec(entry.aim);var end:=origin+aim*float(entry.range);var normal:=aim.rotated(PI*.5);var tint:=Color(1,1,1,(1.0 if float(entry.time)>.18 else minf(.32,float(entry.time)*1.7)))
  match str(entry.visual):
   "paper_cut":
    var paper:=PackedVector2Array([origin+aim*20-normal*10,end-normal*5,end+normal*7,origin+aim*20+normal*12])
    canvas.draw_colored_polygon(paper,Color(.94,.92,.8,tint.a));canvas.draw_line(origin+aim*25-normal*7,end-normal*5,Color(.62,.77,.8,tint.a),2,true)
    for n in 3:canvas.draw_line(origin+aim*(35+n*12)-normal*5,origin+aim*(42+n*12)+normal*4,Color(.42,.54,.61,tint.a),1,true)
   "scratch":
    for n in 3:
     var center:=origin+normal*(n-1)*9
     canvas.draw_arc(center,float(entry.range),aim.angle()-.24,aim.angle()+.24,12,Color(.72,.96,.84,tint.a),3,true)
   "bounce":
    var contact:Vector2=origin+aim*(float(entry.range)-8)
    canvas.draw_arc(contact,10,aim.angle()-PI*.6,aim.angle()+PI*.6,12,Color(.97,.72,.35,tint.a),3,true)
   _:
    for sign in [-1,1]:
     var point:Vector2=origin+aim*float(entry.range)*.75+normal*sign*15
     canvas.draw_arc(point,13,aim.angle()-PI*.7,aim.angle()+PI*.7,14,Color(.91,.78,.53,tint.a),5,true)
    canvas.draw_line(origin+aim*20,end,Color(.76,.88,.9,tint.a*.45),9,true)
 for entry in spins:
  if not combat.visible_owner(str(entry.owner)):continue
  var origin:Vector2=combat.owner_pos(str(entry.owner))-camera;var angle:=float(entry.angle)+TAU*float(entry.elapsed)/float(entry.duration)
  for n in 3:canvas.draw_arc(origin,float(entry.radius)-n*8,angle-.65,angle+.12,18,Color(.65,.93,.81,.75-n*.2),4,true)
 for entry in bounces:
  var point:Vector2=combat.owner_pos(str(entry.owner))-camera
  canvas.draw_arc(point+Vector2(0,12),24,PI*.15,PI*.85,12,Color("#ffbf75"),3,true)
 for owner in books:
  var point:Vector2=combat.owner_pos(str(owner))-camera
  canvas.draw_arc(point+Vector2(0,14),31,PI*.1,PI*.9,20,Color("#e6b28e"),2,true)
 for entry in strokes:
  var start:Vector2=combat.vec(entry.start);var end:Vector2=start.lerp(combat.vec(entry.end),minf(1,float(entry.elapsed)/.45))
  canvas.draw_line(start-camera,end-camera,Color(.88,.94,.77,.7),6,true)
  canvas.draw_line(start-camera,end-camera,Color("#96c4b6"),2,true)
  canvas.draw_circle(end-camera,5,Color("#f5eed3"))
 for entry in grids:
  var point:Vector2=combat.vec(entry.pos)-camera;var area:=Rect2(point-Vector2(150,110),Vector2(300,220))
  canvas.draw_rect(area,Color(.28,.52,.43,.13));canvas.draw_rect(area,Color("#e0e8bc"),false,3)
  for n in 5:canvas.draw_line(point+Vector2(-150+n*75,-110),point+Vector2(-150+n*75,110),Color(.8,.9,.7,.3),1,true)
  for n in 5:canvas.draw_line(point+Vector2(-150,-110+n*55),point+Vector2(150,-110+n*55),Color(.8,.9,.7,.3),1,true)

func body_offset(id:String)->Vector2:
 for entry in strikes:
  if not combat.visible_owner(str(entry.owner)):continue
  if str(entry.owner)==id and str(entry.visual)=="bounce":return combat.vec(entry.aim)*maxf(0,float(entry.range)-28)*pow(clampf(float(entry.time)/.26,0,1),2)
 return Vector2.ZERO

extends "res://scripts/workshop_arena.gd"
## Bounded standalone realm test: same custom ability interpreter, no profile rewards.
const W=preload("res://scripts/studio_world_project.gd")
var world:Dictionary={}
var camera=Vector2.ZERO
var collision={}
var actors:Array=[]
var result=""
var terrain_art={}
var navigation=AStarGrid2D.new()
var renderer=preload("res://scripts/studio_world_renderer.gd").new()
var slow=0.0
var stun=0.0
func setup(value:Dictionary,p:Dictionary)->void:
 for actor in actors:
  if is_instance_valid(actor.runtime):actor.runtime.queue_free()
 world=value.duplicate(true);collision=W.collision_index(world);begin(p,[],"Realm builder");external=true;bounds=Rect2(Vector2.ZERO,Vector2(world.width,world.height)*40);player=Vector2(world.spawn[0]*40+20,world.spawn[1]*40+20);foes.clear();actors.clear();result=""
 for placed in world.placements:
  if placed.kind!="enemy":continue
  var enemy:Dictionary=world.enemies[placed.id]
  var body={"pos":Vector2(placed.cell[0]*40+20,placed.cell[1]*40+20),"hp":float(enemy.health),"max_hp":float(enemy.health),"slow":0.0,"stun":0.0,"dot":0.0,"dot_damage":0.0,"tick":0.0,"phase":0.0,"hits":0}
  foes.append(body);var agent=preload("res://scripts/studio_enemy_agent.gd").new();agent.setup(enemy,body)
  var runtime=preload("res://scripts/workshop_arena.gd").new();add_child(runtime);runtime.hide();runtime.set_process(false)
  var build=Project.fresh();build.hero.max_health=enemy.health;build.hero.speed=enemy.speed;build.hero.primary=enemy.primary;build.hero.secondary=enemy.secondary;build.hero.special=enemy.get("special",Project.attack("block"));runtime.begin(build,[],"Enemy actor");runtime.external=true;runtime.bounds=bounds
  runtime.foes=[{"pos":player,"hp":health,"slow":0.0,"stun":0.0,"dot":0.0,"dot_damage":0.0,"tick":0.0,"phase":0.0,"hits":0}]
  runtime.hit_callback=func(target_index:int,amount:float,a:Dictionary):
   if target_index!=0:return
   if not clear_line(body.pos,player):return
   take_hit(amount)
   if a.status=="stun":stun=maxf(stun,float(a.status_duration));cancel_holds()
   if a.status=="slow":slow=maxf(slow,float(a.status_duration))
  actors.append({"agent":agent,"runtime":runtime,"enemy":enemy})
 navigation.region=Rect2i(0,0,int(world.width),int(world.height));navigation.cell_size=Vector2(40,40);navigation.offset=Vector2(20,20);navigation.diagonal_mode=AStarGrid2D.DIAGONAL_MODE_NEVER;navigation.update()
 for y in int(world.height):
  for x in int(world.width):navigation.set_point_solid(Vector2i(x,y),blocked(Vector2(x*40+20,y*40+20)))
 renderer.prepare(world);update_camera();preview_has_focus=true
func update_camera()->void:
 camera=(player-size*.5).clamp(Vector2.ZERO,(bounds.size-size).max(Vector2.ZERO))
func scale_factor()->Vector2:return Vector2.ONE
func draw_offset()->Vector2:return -camera
func press(kind:String)->void:
 if stun<=0:super.press(kind)
func clear_line(a:Vector2,b:Vector2,projectile:bool=true)->bool:
 for n in range(1,maxi(2,int(a.distance_to(b)/8)+1)):
  if blocked(a.lerp(b,float(n)/maxi(1,int(a.distance_to(b)/8))),projectile):return false
 return true
func hurt(index:int,a:Dictionary,multiplier:float=1)->void:
 if valid_target(index) and clear_line(player,foes[index].pos):
  var previous:Vector2=foes[index].pos;super.hurt(index,a,multiplier)
  if blocked(foes[index].pos):foes[index].pos=previous
func execute_attack(a:Dictionary,target:Vector2)->void:
 if a.style in ["blink","dash"]:
  var at=player;var direction=(target-player).normalized()
  for n in range(1,int(player.distance_to(target)/8)+1):
   var next=player+direction*n*8
   if blocked(next):break
   at=next
  target=at
 super.execute_attack(a,target)
func clip_shots(runtime:Node,old:Array)->void:
 for n in range(runtime.shots.size()-1,-1,-1):
  var shot=runtime.shots[n];var previous:Vector2=shot.get("world_previous",shot.get("origin",shot.pos))
  if not clear_line(previous,shot.pos):runtime.shots.remove_at(n)
func minion_target(m:Dictionary)->Dictionary:
 for key in ["slow","stun","dot","dot_damage","tick","phase","hits"]:
  if not m.has(key):m[key]=0.0
 return m
func tick(dt:float)->void:
 if world.is_empty() or not result.is_empty():return
 dt=minf(dt,.05);slow=maxf(0,slow-dt);stun=maxf(0,stun-dt)
 var direction=touch_direction+Vector2(float(Input.is_physical_key_pressed(KEY_D))-float(Input.is_physical_key_pressed(KEY_A)),float(Input.is_physical_key_pressed(KEY_S))-float(Input.is_physical_key_pressed(KEY_W)))
 var focus=get_viewport().gui_get_focus_owner()
 if focus is LineEdit or focus is TextEdit:direction=Vector2.ZERO
 moving=direction.length()>0 and stun<=0
 if moving:
  var cell=Vector2i(floorf(player.x/40),floorf(player.y/40));var tile:Dictionary=world.tiles[int(world.grid[cell.y*int(world.width)+cell.x])]
  var change=direction.normalized()*float(hero.speed)*dt*(.55 if slow>0 else 1.0)*float(tile.get("speed",1.0))
  for offset in [Vector2(change.x,0),Vector2(0,change.y)]:
   var next=player+offset
   if not blocked(next) and not blocked(next+offset.normalized()*12):player=next
 var player_cell=Vector2i(floorf(player.x/40),floorf(player.y/40))
 if player_cell.x>=0 and player_cell.y>=0 and player_cell.x<int(world.width) and player_cell.y<int(world.height):
  var floor_tile:Dictionary=world.tiles[int(world.grid[player_cell.y*int(world.width)+player_cell.x])]
  var hazard=float(floor_tile.get("damage",0))
  if hazard>0:take_hit(hazard*dt)
 for f in foes:
  if f.has("life") and f.life<=0:f.hp=0
  if f.hp>0 and f.dot>0:
   var amount=minf(float(f.hp),float(f.dot_damage)*minf(dt,float(f.dot)));f.hp-=amount;damage+=amount;f.dot=maxf(0,float(f.dot)-dt)
 for shot in shots:shot.world_previous=shot.pos
 var before=[];super.tick(dt);clip_shots(self,before)
 for m in minions:
  if blocked(m.pos):m.pos=player
 for actor in actors:
  var agent=actor.agent;var body:Dictionary=agent.body;var runtime=actor.runtime
  if body.hp<=0:
   runtime.shots.clear();runtime.fields.clear()
   for m in runtime.minions:m.hp=0
   runtime.minions.clear();continue
  if body.pos.distance_squared_to(player)>1400*1400:continue
  var cell=Vector2i(floorf(body.pos.x/40),floorf(body.pos.y/40));var tile:Dictionary=world.tiles[int(world.grid[cell.y*int(world.width)+cell.x])]
  body.hp=maxf(0,body.hp-float(tile.get("damage",0))*dt)
  var actions=agent.update(dt,player)
  actor.nav_left=maxf(0,float(actor.get("nav_left",0))-dt)
  if agent.heading.dot((player-body.pos).normalized())>.5 and not clear_line(body.pos,player,false):
   if actor.nav_left<=0:
    actor.nav_left=.6;actor.path=navigation.get_point_path(cell,Vector2i(floorf(player.x/40),floorf(player.y/40)))
   var path:PackedVector2Array=actor.get("path",PackedVector2Array())
   while not path.is_empty() and body.pos.distance_to(path[0])<12:path.remove_at(0)
   actor.path=path
   if not path.is_empty():agent.heading=(path[0]-body.pos).normalized()
  else:actor.path=PackedVector2Array()
  var change=agent.heading*float(actor.enemy.speed)*dt*(.55 if body.slow>0 else 1.0)*float(tile.get("speed",1))
  var next:Vector2=body.pos+change
  if not blocked(next):body.pos=next
  else:
   for offset in [Vector2(change.x,0),Vector2(0,change.y)]:
    if not blocked(body.pos+offset):body.pos+=offset
  runtime.player=body.pos;runtime.health=body.hp;runtime.aim=(player-body.pos).normalized();runtime.aim_point=player;runtime.foes[0].pos=player;runtime.foes[0].hp=health
  runtime.foes.resize(1)
  for m in minions:
   if m.hp>0:runtime.foes.append(minion_target(m))
  for action in actions:
   if float(action.ability.charge)>0:runtime.press(action.slot)
   else:runtime.cast(action.slot)
  for slot in runtime.holds.keys():
   if runtime.holds[slot].age>=float(runtime.hero[slot].charge):runtime.release(slot)
  for shot in runtime.shots:shot.world_previous=shot.pos
  runtime.tick(dt);clip_shots(runtime,before)
  for m in runtime.minions:
   if blocked(m.pos):m.pos=body.pos
   if not m.get("world_registered",false):
    m.world_registered=true;foes.append(minion_target(m))
 if health<=0:result="Defeated • return to the builder and try a different route.";cancel_holds()
 var end=Vector2(world.exit[0]*40+20,world.exit[1]*40+20)
 if health>0 and player.distance_to(end)<28 and (not world.get("clear_required",false) or not foes.any(func(f):return f.hp>0)):result="Realm complete • your route is playable!";cancel_holds()
 update_camera();queue_redraw()
func texture(encoded:String)->Texture2D:
 if not terrain_art.has(encoded):
  var image=Image.new()
  if image.load_png_from_buffer(Marshalls.base64_to_raw(encoded))==OK:terrain_art[encoded]=ImageTexture.create_from_image(image)
 return terrain_art.get(encoded)
func actor_effects(runtime:Node)->void:
 for f in runtime.fields:draw_circle(f.pos,float(f.ability.radius),Color(Color(f.ability.color),.2))
 for shot in runtime.shots:Graphics.shot(self,shot.pos,shot.direction,shot.ability)
 for m in runtime.minions:runtime.draw_minion(self,m,Vector2.ZERO)
 for v in runtime.visuals:
  if v.get("shape")=="melee":Graphics.strike(self,v,Vector2.ZERO)
  elif v.has("end"):draw_line(v.pos,v.end,Color(v.color),float(v.radius),true)
  else:draw_arc(v.pos,float(v.radius),0,TAU,24,Color(v.color),2)
func _draw()->void:
 if world.is_empty():return
 draw_set_transform(-camera)
 var view=Rect2(camera,size)
 renderer.ground(self,world,view,time)
 renderer.props(self,world,view,player.y)
 var end=Vector2(world.exit[0]*40+20,world.exit[1]*40+20)
 var portal:Texture2D=load("res://assets/portal.png")
 draw_texture_rect(portal,Rect2(end-Vector2(35,64+sin(time*2)*3),Vector2(70,80)),false)
 draw_circle(end,22,Color("#edd38b"),false,3);draw_arc(end,27,time,time+PI,24,Color("#f5e8bd"),2)
 actor_effects(self);draw_aim(self,Vector2.ZERO)
 var pose="attack" if attack_pose>0 else "walk1" if moving and int(time*8)%2==0 else "walk2" if moving else "idle"
 var tex:Texture2D=form_textures.get(active_form,textures.get(pose,textures.get("idle")))
 if tex!=null:draw_texture_rect(tex,Rect2(player-Vector2(28,42),Vector2(56,64)),false)
 else:draw_circle(player,18,Color("#f0dca6"))
 for slot in holds:Graphics.charge(self,player,aim,ability(slot),clampf(float(holds[slot].age)/maxf(.1,float(ability(slot).charge)),0,1),time)
 for actor in actors:
  var body=actor.agent.body
  if body.hp<=0:continue
  var enemy=actor.enemy;pose="attack" if actor.runtime.attack_pose>0 else "walk1" if int(time*7)%2==0 else "walk2"
  var encoded=str(enemy.art.get(pose,enemy.art.get("idle","")))
  if not encoded.is_empty():draw_texture_rect(texture(encoded),Rect2(body.pos-Vector2(22,34),Vector2(44,48)),false)
  else:draw_circle(body.pos,16,Color("#d48e7d"))
  draw_rect(Rect2(body.pos+Vector2(-20,-38),Vector2(40*maxf(0,body.hp)/float(enemy.health),4)),Color("#e4b27e"));actor_effects(actor.runtime)
 renderer.props(self,world,view,player.y,true)
 draw_set_transform(Vector2.ZERO)
 renderer.atmosphere(self,world,size,time)
 draw_rect(Rect2(12,12,220,32),Color("#102c38"));draw_string(ThemeDB.fallback_font,Vector2(22,34),"HP %d / %d • foes %d" % [health,hero.max_health,foes.filter(func(f):return f.hp>0).size()],HORIZONTAL_ALIGNMENT_LEFT,-1,17,Color.WHITE)
 if not result.is_empty():draw_rect(Rect2(20,size.y-60,size.x-40,44),Color("#102c38"));draw_string(ThemeDB.fallback_font,Vector2(30,size.y-30),result,HORIZONTAL_ALIGNMENT_LEFT,-1,19,Color("#f5d699"))

func blocked(at:Vector2,projectile:bool=false)->bool:return W.blocked(world,at,projectile,collision)

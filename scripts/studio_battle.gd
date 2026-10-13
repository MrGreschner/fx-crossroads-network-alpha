extends "res://scripts/workshop_arena.gd"
## Interactive sandbox: actual attacks collide with independent EnemyAgent objects.
var agents:Array=[]
var runtimes:Array=[]
var enemy_art:Dictionary={}
var definition:Dictionary
var player_slow=0.0
var player_stun=0.0
var player_dot=0.0
var dot_damage=0.0
var result=""
var obstacles=[Vector2(340,190),Vector2(650,365)]
func setup(enemy:Dictionary,p:Dictionary,count:int=1)->void:
 definition=enemy.duplicate(true);begin(p,[],"Battle Lab");agents.clear();runtimes.clear();foes.clear();enemy_art.clear();result="";player_slow=0;player_stun=0;player_dot=0
 for pose in definition.art:
  var image=Image.new();image.load_png_from_buffer(Marshalls.base64_to_raw(definition.art[pose]));enemy_art[pose]=ImageTexture.create_from_image(image)
 for index in count:
  var body={"pos":Vector2(600,140+index*110),"hp":float(enemy.health),"max_hp":float(enemy.health),"slow":0.0,"stun":0.0,"dot":0.0,"dot_damage":0.0,"tick":0.0,"phase":float(index),"hits":0}
  foes.append(body);var agent=preload("res://scripts/studio_enemy_agent.gd").new();agent.setup(enemy,body);agents.append(agent)
  var runtime=preload("res://scripts/workshop_arena.gd").new();add_child(runtime);runtime.hide();runtime.set_process(false)
  var build=Project.fresh();build.hero.max_health=enemy.health;build.hero.speed=enemy.speed;build.hero.primary=enemy.primary;build.hero.secondary=enemy.secondary;build.hero.special=enemy.get("special",Project.attack("block"));build.hero.passive="none";runtime.begin(build,[],"Enemy actor");runtime.external=true;runtime.locked_player=true
  runtime.foes=[{"pos":player,"hp":health,"max_hp":float(hero.max_health),"slow":0.0,"stun":0.0,"dot":0.0,"dot_damage":0.0,"tick":0.0,"phase":0.0,"hits":0}]
  runtime.hit_callback=func(_index:int,amount:float,a:Dictionary):enemy_hit(amount,a)
  runtime.heal_callback=func(amount:float):body.hp=minf(float(enemy.health),body.hp+amount)
  runtimes.append(runtime)
func press(kind:String)->void:
 if player_stun<=0:super.press(kind)
func blocked(p:Vector2)->bool:
 for obstacle in obstacles:
  if p.distance_to(obstacle)<42:return true
 return false
func tick(delta:float)->void:
 if not result.is_empty():queue_redraw();return
 player_slow=maxf(0,player_slow-delta);player_stun=maxf(0,player_stun-delta)
 var old=player;var speed=float(hero.speed);hero.speed=speed*(0 if player_stun>0 else .55 if player_slow>0 else 1.0)
 super.tick(delta);hero.speed=speed
 if blocked(player):player=old
 if player_dot>0:health=maxf(0,health-dot_damage*minf(delta,player_dot));player_dot=maxf(0,player_dot-delta)
 for index in agents.size():
  var agent=agents[index];var body:Dictionary=agent.body;var runtime=runtimes[index]
  if body.hp<=0:
   for minion in runtime.minions:minion.hp=0
   runtime.shots.clear();runtime.fields.clear();runtime.minions.clear();continue
  var attacks=agent.update(delta,player);var candidate:Vector2=body.pos+agent.heading*float(definition.speed)*delta*(.55 if body.slow>0 else 1.0)
  candidate=candidate.clamp(Vector2(40,40),Vector2(860,500))
  if not blocked(candidate):body.pos=candidate
  else:
   var tangent=agent.heading.rotated(PI*.5)*float(definition.speed)*delta
   if not blocked(body.pos+tangent):body.pos+=tangent
  runtime.player=body.pos;runtime.health=body.hp;runtime.aim=(player-body.pos).normalized();runtime.aim_point=player;runtime.foes[0].pos=player;runtime.foes[0].hp=health
  for action in attacks:
   var slot=str(action.slot)
   if float(action.ability.charge)>0:runtime.press(slot)
   else:runtime.cast(slot)
  for slot in runtime.holds.keys():
   if float(runtime.holds[slot].age)>=float(runtime.hero[slot].charge):runtime.release(slot)
  runtime.tick(delta)
  for minion in runtime.minions:
   if not minion.has("linked"):
    minion.linked=true;minion.slow=0.0;minion.stun=0.0;minion.dot=0.0;minion.dot_damage=0.0;minion.tick=0.0;minion.phase=0.0;minion.hits=0
    if foes.size()<80:foes.append(minion)
 if health<=0:running=false;cancel_holds();result="Defeated • adjust the enemy or your strategy and retry."
 elif agents.all(func(agent):return agent.body.hp<=0):result="Victory • your design survived a real battle test.";cancel_holds()
 queue_redraw()
func enemy_hit(amount:float,a:Dictionary)->void:
 take_hit(amount)
 if a.status=="slow":player_slow=maxf(player_slow,float(a.status_duration))
 elif a.status=="stun":player_stun=maxf(player_stun,float(a.status_duration));cancel_holds()
 elif a.status in ["burn","poison","bleed"]:player_dot=maxf(player_dot,float(a.status_duration));dot_damage=float(a.status_damage)
func hurt(index:int,a:Dictionary,multiplier:float=1.0)->void:
 var protection=0.0
 for n in agents.size():
  if index==n:protection=maxf(float(runtimes[n].hero.get("defence",0)),maxf(.15 if agents[n].guarded else 0,runtimes[n].passive.reduction()));if runtimes[n].protection>0:protection=maxf(protection,.6)
 super.hurt(index,a,multiplier*(1-protection))
func _draw()->void:
 super._draw()
 for obstacle in obstacles:
  draw_circle(obstacle+Vector2(4,10),36,Color(0,0,0,.25));draw_circle(obstacle,34,Color("#426275"));draw_arc(obstacle,34,0,TAU,24,Color("#8faeab"),2)
 for n in agents.size():
  var agent=agents[n];var body:Dictionary=agent.body
  if body.hp<=0:continue
  var pose="attack" if runtimes[n].attack_pose>0 else "walk1" if int(time*7)%2==0 and agent.heading.length()>0 else "walk2" if agent.heading.length()>0 else "idle"
  var texture:Texture2D=enemy_art.get(pose,enemy_art.get("idle"))
  if texture!=null:draw_texture_rect(texture,Rect2(body.pos-Vector2(28,42),Vector2(56,64)),false)
  draw_string(ThemeDB.fallback_font,body.pos+Vector2(-70,-52),definition.name,HORIZONTAL_ALIGNMENT_CENTER,140,14,Color("#f0c99b"))
  if agent.guarded:draw_arc(body.pos,30,0,TAU,24,Color("#c4cbd3"),2)
  draw_actor_effects(runtimes[n])
 if not result.is_empty():draw_rect(Rect2(150,225,600,60),Color("#102c38"));draw_string(ThemeDB.fallback_font,Vector2(165,263),result,HORIZONTAL_ALIGNMENT_CENTER,570,20,Color("#f1d399"))
func draw_actor_effects(actor:Node)->void:
 for f in actor.fields:draw_circle(f.pos,float(f.ability.radius),Color(Color(f.ability.color),.18));draw_arc(f.pos,float(f.ability.radius),0,TAU,28,Color(f.ability.color),2)
 for shot in actor.shots:
  var point:Vector2=shot.pos
  if shot.ability.style=="target_aoe":point.y-=sin(clampf(shot.distance/maxf(1,shot.origin.distance_to(shot.target)),0,1)*PI)*60
  Graphics.shot(self,point,shot.direction,shot.ability)
 for m in actor.minions:actor.draw_minion(self,m,Vector2.ZERO)
 for v in actor.visuals:
  if v.get("shape")=="melee":Graphics.strike(self,v,Vector2.ZERO)
  elif v.has("end"):draw_line(v.pos,v.end,Color(v.color),float(v.radius),true)
  else:draw_arc(v.pos,float(v.radius),0,TAU,24,Color(v.color),2)

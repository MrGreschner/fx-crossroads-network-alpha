extends "res://scripts/workshop_arena.gd"
## The same bounded attack runtime, bridged to solo game actors by stable enemy UID.
var game:Node
var last_hero=""
func setup(owner:Node)->void:
 game=owner;hide();set_process(false);external=true;locked_player=true;hit_callback=contact;heal_callback=recover
func active()->bool:return game.mode=="run" and game.character_id.begins_with("custom_")
func initialise()->void:
 var p:Dictionary=game.hero.studio_project
 var variants:Array=[];var build=game.legacy.payload(game.character_id)
 if build.technique:variants.append(0)
 if build.final_technique:variants.append(1)
 begin(p,variants,"Realm");external=true;locked_player=true;set_process(false);last_hero=game.character_id;foes.clear();bounds=Rect2(Vector2.ZERO,game.region_size())
func contact(index:int,amount:float,a:Dictionary)->void:
 if index<0 or index>=foes.size():return
 var uid=int(foes[index].uid)
 for i in game.enemies.size():
  var f:Dictionary=game.enemies[i]
  if int(f.get("uid",-1))!=uid:continue
  # Collision and status are resolved by the actual realm, not a synthetic target.
  if not game.shot_path_clear(player,f.pos,true):return
  var key=game.adventure.combat.npc_key(f)
  if a.status!="none":game.adventure.combat.apply_status(key,a.status,float(a.status_duration),"solo",float(a.status_damage))
  if hero.passive in ["burn_touch","poison_touch","slow_touch"]:game.adventure.combat.apply_status(key,{"burn_touch":"burn","poison_touch":"poison","slow_touch":"slow"}[hero.passive],2,"solo",1)
  if a.name==hero.primary.name:amount+=game.bonus_damage
  if float(a.get("knockback",0))>0:
   var pushed:Vector2=f.pos+(f.pos-player).normalized()*float(a.knockback)
   if game.can_stand_at(pushed):f.pos=pushed
  game.damage_enemy(i,amount);return
func recover(amount:float)->void:
 game.health=minf(game.max_health(),game.health+amount)
func step(delta:float)->void:
 if not active():last_hero="";return
 if last_hero!=game.character_id:initialise()
 player=game.position_in_world;health=game.health;hero.max_health=game.max_health();aim=game.aim_direction();aim_point=game.aimed_point(600);bounds=Rect2(Vector2.ZERO,game.region_size());running=game.health>0;moving=game.position_in_world.distance_to(passive.last_position)>.1
 # Keep target slots stable while projectiles are in flight. IDs, not shrinking game-array indices, determine contact history.
 var target_slots:Dictionary={}
 for index in foes.size():target_slots[int(foes[index].uid)]=index;foes[index].hp=0
 for enemy in game.enemies:
  if bool(enemy.get("converted",false)):continue
  var uid=int(enemy.get("uid",0))
  if target_slots.has(uid):foes[target_slots[uid]].pos=enemy.pos;foes[target_slots[uid]].hp=float(enemy.hp)
  else:foes.append({"uid":uid,"pos":enemy.pos,"hp":float(enemy.hp),"max_hp":float(enemy.hp),"slow":0.0,"stun":0.0,"dot":0.0,"dot_damage":0.0,"tick":0.0,"phase":0.0,"hits":0})
 if shots.is_empty() and fields.is_empty() and minions.is_empty() and foes.size()>100:foes=foes.filter(func(f):return f.hp>0)
 for kind in Project.KINDS:
  var allowed=game.practice or game.level>=({"primary":1,"secondary":3,"special":6}[kind])
  var down=game.mobile.attacking if kind=="primary" and game.mobile.enabled else Input.is_action_pressed(kind)
  if allowed and game.stun_time<=0 and not game.adventure.combat.stunned("p:solo"):
   if down:press(kind)
   elif holds.has(kind):release(kind)
  elif holds.has(kind):cancel_holds()
 var minion_positions:Array=[]
 for m in minions:minion_positions.append(m.pos)
 var old=player;tick(minf(delta,.05))
 for n in minions.size():
  if not game.can_stand_at(minions[n].pos):minions[n].pos=minion_positions[n] if n<minion_positions.size() else player
 for f in fields:
  if f.kind=="vortex":
   for enemy in game.enemies:
    if enemy.pos.distance_to(f.pos)<float(f.ability.radius):
     var next:Vector2=enemy.pos+(f.pos-enemy.pos).normalized()*70*minf(delta,.05)
     if game.can_stand_at(next):enemy.pos=next
 if player!=old and game.can_stand_at(player):game.position_in_world=player
 game.attack_pose_time=maxf(game.attack_pose_time,attack_pose)
 game.cooldowns=cooldowns.duplicate()
 # Realm projectiles stop at terrain and can destroy student minions.
 for n in range(shots.size()-1,-1,-1):
  var shot:Dictionary=shots[n]
  if not game.can_stand_at(shot.pos):shots.remove_at(n)
 for n in range(game.enemy_shots.size()-1,-1,-1):
  var shot:Dictionary=game.enemy_shots[n]
  for minion in minions:
   if minion.pos.distance_to(shot.pos)<20:minion.hp-=float(shot.get("damage",8))*(.9 if hero.passive=="shelter" and hero.get("passive_aura",false) and minion.pos.distance_to(player)<float(hero.get("passive_radius",100)) else 1.0);game.enemy_shots.remove_at(n);break
 for minion in minions:
  for enemy in game.enemies:
   if minion.pos.distance_to(enemy.pos)<40:minion.hp-=delta*float(game.enemy_types.get(str(enemy.get("type","")),{}).get("damage",8))
 if hero.passive=="mending" and hero.get("passive_aura",false):
  if game.practice and player.distance_to(game.training_yard.ALLY)<float(hero.get("passive_radius",100)):game.training_yard.heal(game,delta)
  for minion in minions:
   if player.distance_to(minion.pos)<float(hero.get("passive_radius",100)):minion.hp=minf(float(minion.get("max_hp",40)),minion.hp+delta)
 if hero.passive=="frost":
  for f in foes:
   if f.pos.distance_to(player)<float(hero.get("passive_radius",100)):game.adventure.combat.apply_status("e:"+str(f.uid),"slow",.3,"solo")
func execute_attack(a:Dictionary,target:Vector2)->void:
 if a.style in ["dash","blink"]:
  var direction=(target-player).normalized();var distance=player.distance_to(target);var end=player
  for step_number in range(1,int(distance/12)+1):
   var point=player+direction*step_number*12
   if not game.can_stand_at(point):break
   end=point
  target=end
 super.execute_attack(a,target)
func reduction()->float:
 if not active():return 0
 return maxf(float(hero.get("defence",0)),maxf(maxf(.6 if protection>0 else .1 if hero.get("passive","") in ["defence","shelter"] else 0.0,passive.reduction()),buff_reduction(player)))
func draw_on(canvas:Node2D,camera:Vector2)->void:
 if not active() or last_hero.is_empty():return
 for f in fields:
  var p:Vector2=f.pos-camera;var color=Color(f.ability.color);canvas.draw_circle(p,float(f.ability.radius),Color(color,.18));canvas.draw_arc(p,float(f.ability.radius),0,TAU,28,color,2)
 for shot in shots:
  var p:Vector2=shot.pos-camera
  if shot.ability.style=="target_aoe":
   var progress=clampf(float(shot.distance)/maxf(1,(shot.target-shot.origin).length()),0,1);p.y-=sin(progress*PI)*60;canvas.draw_circle(shot.pos-camera,6,Color(0,0,0,.25));canvas.draw_arc(shot.target-camera,float(shot.ability.radius),0,TAU,28,Color(.7,.8,.7,.2),1)
  var frames:Array=animation_cache.get(JSON.stringify(shot.ability.get("animation",[])).sha256_text(),[]) if not shot.ability.has("projectile_graphic") or shot.ability.projectile_graphic=="custom" else []
  if not frames.is_empty():canvas.draw_texture_rect(frames[int((5-float(shot.life))*8)%frames.size()],Rect2(p-Vector2.ONE*18,Vector2.ONE*36),false)
  else:Graphics.shot(canvas,p,shot.direction,shot.ability,1+float(shot.ability.get("charge_size",float(shot.ability.get("charged",0))*.5)))
 for minion in minions:draw_minion(canvas,minion,camera)
 for v in visuals:
  var color=Color(v.color,float(v.life)/float(v.total));var p:Vector2=v.pos-camera
  if v.has("animation"):
   var frames:Array=animation_cache.get(v.animation,[])
   if not frames.is_empty():canvas.draw_texture_rect(frames[mini(frames.size()-1,int((v.total-v.life)/.125))],Rect2(p-Vector2.ONE*32,Vector2.ONE*64),false)
  elif v.get("shape")=="melee":Graphics.strike(canvas,v,camera)
  elif v.has("end"):canvas.draw_line(p,v.end-camera,color,float(v.radius),true)
  else:canvas.draw_arc(p,float(v.radius),0,TAU,32,color,3,true)
 for kind in holds:
  var a=ability(kind);Graphics.charge(canvas,player-camera,aim,a,clampf(float(holds[kind].age)/maxf(.1,float(a.charge)),0,1),time)
  var frames:Array=animation_cache.get(JSON.stringify(a.get("charge_animation",[])).sha256_text(),[]) if a.get("charge_visual")=="custom" else []
  if not frames.is_empty():canvas.draw_texture_rect(frames[int(time*8)%frames.size()],Rect2(player-camera-Vector2.ONE*35,Vector2.ONE*70),false)
 draw_aim(canvas,camera)
 if hero.get("passive_aura",false):canvas.draw_arc(player-camera,float(hero.get("passive_radius",100)),0,TAU,32,Color(.5,.8,.9,.25),2)
 if protection>0:canvas.draw_arc(player-camera,32,0,TAU,32,Color(.85,.88,.92,.5),2)

func heal_at(origin:Vector2,a:Dictionary)->void:
 if origin.distance_to(player)<=float(a.radius):restore(float(a.heal))
 if game.practice and origin.distance_to(game.training_yard.ALLY)<=float(a.radius):game.training_yard.heal(game,float(a.heal))
 for minion in minions:
  if origin.distance_to(minion.pos)<=float(a.radius):minion.hp=minf(float(minion.get("max_hp",40)),minion.hp+float(a.heal))
func received(amount:float)->void:
 if not active():return
 passive.received()
 if hero.get("passive","")!="thorns":return
 var index=closest(player,55)
 if index>=0:
  var a=Project.attack();a.damage=minf(10,amount*.15);hurt(index,a)

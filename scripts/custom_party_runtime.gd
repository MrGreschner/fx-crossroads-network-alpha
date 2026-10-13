extends "res://scripts/studio_live.gd"
## Same Studio runtime with host-authoritative contacts against actual actors.
var actor_id=""
var serial=0
var keys:Array[String]=[]
func setup_party(g:Node,id:String,p:Dictionary)->void:
 game=g;actor_id=id;hide();set_process(false);external=true;locked_player=true;hit_callback=contact;heal_callback=recover
 begin(p,[],"Multiplayer");foes.clear();keys.clear();last_hero=id;running=true
func active()->bool:return game.started and game.characters.get(str(game.hero_ids.get(actor_id,"")),{}).has("studio_project")
func initialise()->void:pass
func contact(index:int,amount:float,a:Dictionary)->void:
 if index<0 or index>=keys.size():return
 var key=keys[index];var combat=game.adventure.combat;var f:Dictionary=combat.actor(key)
 if f.is_empty() or not combat.path_clear(player,f.pos):return
 combat.damage(key,amount,actor_id,str(a.name))
 if a.status!="none":combat.apply_status(key,a.status,float(a.status_duration),actor_id,float(a.status_damage))
 if int(game.levels.get(actor_id,1))>=5 and hero.passive in ["burn_touch","poison_touch","slow_touch"]:combat.apply_status(key,{"burn_touch":"burn","poison_touch":"poison","slow_touch":"slow"}[hero.passive],2,actor_id,1)
 if float(a.get("knockback",0))>0:combat.knock(key,(f.pos-player).normalized(),float(a.knockback))
func recover(amount:float)->void:
 var before=float(game.health.get(actor_id,0));game.health[actor_id]=minf(game._max_hp(actor_id),before+amount);game._stat(actor_id,"healing",float(game.health[actor_id])-before)
func heal_at(origin:Vector2,a:Dictionary)->void:
 for id in game.positions:
  if not game.adventure.alive(str(id)) or game.mode in ["arena","battlegrounds"] and game._rival(actor_id,str(id)):continue
  if origin.distance_to(game.positions[id])>float(a.radius) or not game._clear_path(origin,game.positions[id]):continue
  var before=float(game.health.get(id,0));game.health[id]=minf(game._max_hp(str(id)),before+float(a.heal));game._stat(actor_id,"healing",float(game.health[id])-before)
func execute_attack(a:Dictionary,target:Vector2)->void:
 if a.style in ["dash","blink"]:
  var end=player
  for n in range(1,int(player.distance_to(target)/12)+1):
   var next=player+(target-player).normalized()*n*12
   if not game._clear_path(end,next):break
   end=next
  target=end
 # Skip solo terrain adapter.
 var original_game=game
 if a.style in ["dash","blink"]:
  var copy=a.duplicate(true);copy.style="spin";pulse(player,copy);player=target;flash(player,float(a.radius),Color(a.color))
 else:super.execute_attack(a,target)
 game=original_game
func step(delta:float)->void:
 if not active() or game.role!="host":return
 if int(game.health.get(actor_id,0))<=0:cancel_holds();shots.clear();fields.clear();minions.clear();return
 hero.passive=game.characters[str(game.hero_ids[actor_id])].studio_project.hero.passive if int(game.levels.get(actor_id,1))>=5 else "none"
 player=game.positions[actor_id];health=float(game.health[actor_id]);hero.max_health=game._max_hp(actor_id);bounds=game.FIELD;running=true
 var combat=game.adventure.combat
 for f in foes:f.hp=0
 for key in combat.hostile(actor_id):
  var a:Dictionary=combat.actor(key)
  if a.is_empty() or not bool(a.alive):continue
  var index=keys.find(key)
  if index<0:keys.append(key);foes.append({"uid":key,"pos":a.pos,"hp":100.0,"max_hp":100.0,"slow":0.0,"stun":0.0,"dot":0.0,"dot_damage":0.0,"tick":0.0,"phase":0.0,"hits":0});index=foes.size()-1
  foes[index].pos=a.pos;foes[index].hp=100.0
 var old=player;tick(delta)
 if player!=old and game._clear_path(old,player):game.positions[actor_id]=player;game._send_channel(actor_id,{"type":"teleport","point":[player.x,player.y]})
 var cd:Dictionary={}
 for kind in cooldowns:cd[kind]=Time.get_ticks_msec()+int(float(cooldowns[kind])*1000)
 game.cooldown_at[actor_id]=cd
 if attack_pose>0:game.attack_pose_until[actor_id]=Time.get_ticks_msec()+int(attack_pose*1000)
 for m in minions:
  if not m.has("party_uid"):serial+=1;m.party_uid=str(serial)
  for key in combat.hostile(actor_id):
   var a:Dictionary=combat.actor(key)
   if not a.is_empty() and bool(a.alive) and m.pos.distance_to(a.pos)<35:m.hp-=delta*10
 for n in range(shots.size()-1,-1,-1):
  if not game._clear_path(shots[n].pos-shots[n].direction*8,shots[n].pos):shots.remove_at(n)
 if shots.is_empty() and fields.is_empty() and minions.is_empty() and foes.size()>120:foes.clear();keys.clear()

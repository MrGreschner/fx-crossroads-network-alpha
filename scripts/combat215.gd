extends Node
## Authority-owned channel steering, controller combo and one-pass cleanse/dispel.
var combat:Node
var aims:Dictionary={}
var combos:Dictionary={}
const NEGATIVE=["slow","stun","poison","burn","bleed","fear","silence","veil_weaken","veil_dry","weakness","exposed","healing_block","lifesteal_block","poison_touch"]
const POSITIVE=["guard","rune_ward","silk_guard","rune_stride","scout_stride","fern_stride","tailwind","haste","invincible","stealth","regen","damage_boost","rune_might"]
func reset()->void:aims.clear();combos.clear()
func aim(owner:String,direction:Vector2)->void:
 if combat.adventure.authoritative() and direction.is_finite() and not direction.is_zero_approx():aims[owner]=direction.normalized()
func steer(owner:String,current:Vector2,rate:float,delta:float)->Vector2:
 var target:Vector2=aims.get(owner,current)
 return Vector2.from_angle(rotate_toward(current.angle(),target.angle(),maxf(0,delta)*rate))
func combo(owner:String,amount:float,direction:Vector2)->void:
 if not combat.passive(owner,"combo_buffer"):return
 combos[owner]=(int(combos.get(owner,0))+1)%4
 if int(combos[owner])!=0:return
 combat.launch_projectile(owner,combat.owner_pos(owner)+direction*24,direction,{"range":340,"speed":440,"color":"#a6efe5","visual215":"confirm"},amount,"homing")
 combat.apply_status(combat.player_key(owner),"scout_stride",2,owner,1.15)
func purge(owner:String,key:String,ally:bool)->int:
 if not combat.adventure.authoritative():return 0
 var removed:=0;var active:Dictionary=combat.statuses.get(key,{})
 for kind in active.keys():
  var source:String=str(active[kind].get("owner",""))
  var known_bad:bool=kind in NEGATIVE;var known_good:bool=kind in POSITIVE
  var source_friendly:bool=source==owner or combat.v75.friendly(owner,source)
  var bad:bool=known_bad or not known_good and not source_friendly
  if bad==ally:active.erase(kind);removed+=1
 if active.is_empty():combat.statuses.erase(key)
 else:combat.statuses[key]=active
 var g:Node=combat.adventure.game
 if key.begins_with("p:") and not key.begins_with("p:risen:") and not key.begins_with("p:summon:"):
  var id:String=key.substr(2)
  if combat.adventure.arcade:
   if not ally:
    for name in ["shield_until","haste_until","invincible_until","stealth_until"]:
     var bank:Variant=g.get(name)
     if bank is Dictionary and bank.has(id):bank[id]=0
  elif id=="solo":
   if ally:g.stun_time=0
   else:g.block_time=0;g.invulnerable_time=0;g.stealth_time=0
  # Dispel active chill protection; passives, equipment and world fields remain intrinsic.
  if not ally:
   for aura in combat.auras.duplicate():
    if str(aura.owner)==id:combat.auras.erase(aura)
 return removed
func pulse(ring:Dictionary)->void:
 var owner:String=str(ring.owner);var centre:Vector2=combat.vec(ring.pos);var radius:float=float(ring.radius)
 if not ring.has("purged"):ring.purged=[]
 for id in combat.party_heroes.friendly_near(owner,centre,radius):
  var key:String=str(id) if str(id).begins_with("bg") else combat.player_key(str(id))
  if key in ring.purged:continue
  purge(owner,key,true);ring.purged.append(key)
 for key in combat.hostile(owner):
  if key in ring.purged:continue
  var target:Dictionary=combat.actor(key)
  if target.is_empty() or not bool(target.alive) or centre.distance_to(target.pos)>radius or not combat.path_clear(centre,target.pos):continue
  purge(owner,key,false);ring.purged.append(key)

 # Summons share the pulse's team, distance and obstruction rules.
 var allies:Dictionary={}
 for id in combat.morrow.units:
  var body:Dictionary=combat.morrow.units[id]
  if float(body.get("hp",0))>0 and combat.v75.friendly(owner,str(body.owner)):allies[combat.player_key(str(id))]=combat.vec(body.pos)
 for id in combat.summon_points():
  var body:Dictionary=combat.summon_body(str(id))
  if combat.v75.friendly(owner,str(body.owner)):allies[combat.player_key(str(id))]=body.pos
 for key in allies:
  if key not in ring.purged and centre.distance_to(allies[key])<=radius and combat.path_clear(centre,allies[key]):
   purge(owner,str(key),true);ring.purged.append(key)

extends RefCounted
## Realm identities survive streaming, checkpoint restoration and co-op snapshots.
const TYPES=["between_grove_boss","kiln_knight","crowned_torrent","between_ice_boss","bellroot","eclipse_engine"]
const NAMES=["Grove Rootwarden","Kiln Knight","Crowned Torrent","Cryowarden","Bellroot","Eclipse Engine"]
const SPRITES=["bramble_boss","kiln_knight","crowned_torrent","cryowarden","bellroot","eclipse_engine"]
const REALMS=["grove","oath","silverfall","ice","lantern_marsh","astral_rift"]
static func install(g:Node,multi:bool)->void:
 var defs:Dictionary=g.enemy_defs if multi else g.enemy_types
 for n in TYPES.size():
  var kind=TYPES[n]
  if not defs.has(kind):
   var path="res://content/enemies/"+kind+".json"
   defs[kind]=JSON.parse_string(FileAccess.get_file_as_string(path)) if FileAccess.file_exists(path) else {"id":kind,"name":"Grove Rootwarden" if n==0 else "Cryowarden","sprite":SPRITES[n],"health":540 if n==0 else 780,"speed":108,"damage":25,"behaviour":"chase"}
  if not multi:g.load_sprite_pair(SPRITES[n])
  for pose in ["idle","walk1","walk2","attack","0","1"]:g.art[kind+"_"+pose]=g.art.get(SPRITES[n]+"_"+pose,g.art.get(SPRITES[n]+"_idle"))
static func configure(foe:Dictionary,theme:int)->void:
 var n=clampi(theme,0,5)
 foe.type=TYPES[n];foe.name=NAMES[n];foe.sprite=SPRITES[n];foe.source_realm=REALMS[n];foe.between_guardian=true
 foe.expansion_boss=n in [1,2,4,5];foe.immersive=n in [2,4]
 foe.skill_timer=float(foe.get("skill_timer",2.0));foe.skill_step=int(foe.get("skill_step",0));foe.imm_turn=int(foe.get("imm_turn",0))
static func basic(g:Node,foe:Dictionary,dt:float,multi:bool=false)->bool:
 if not bool(foe.get("between_guardian",false)) or str(foe.type) not in [TYPES[0],TYPES[3]]:return false
 var a=g.adventure;var target=Vector2.ZERO;var nearest=INF;var target_id=""
 for id in a.points():
  if not a.alive(str(id)):continue
  if multi and Time.get_ticks_msec()<int(g.stealth_until.get(id,0)):continue
  if not multi and g.stealth_time>0:continue
  var d=foe.pos.distance_to(a.points()[id])
  if d<nearest:nearest=d;target=a.points()[id];target_id=str(id)
 if target_id.is_empty() or nearest>850:return true
 foe.attack_timer=maxf(0,float(foe.get("attack_timer",0))-dt)
 var credit=preload("res://scripts/defeat_credit.gd").resolve(g,a.combat.npc_key(foe),"Root Stomp" if str(foe.source_realm)=="grove" else "Frostburst")
 if str(foe.source_realm)=="grove":
  var swing=preload("res://scripts/starter_boss.gd").advance(foe,target,dt,true)
  if swing>0:
   if swing==2:
    for id in a.points():
     if a.alive(str(id)) and preload("res://scripts/starter_boss.gd").hits(foe,a.points()[id]):a.hit_player(str(id),25,a.combat.npc_key(foe),credit)
   return true
 elif nearest<54 and float(foe.attack_timer)<=0:
  a.hit_player(target_id,25,a.combat.npc_key(foe),credit);foe.attack_timer=1.3
 foe.secondary_timer=maxf(0,float(foe.get("secondary_timer",3.5))-dt)
 if float(foe.get("windup",0))>0:
  foe.windup=maxf(0,float(foe.windup)-dt)
  if float(foe.windup)==0:
   foe.strike_flash=.35
   if str(foe.source_realm)=="ice":
    for ray in 10:a.combat.launch_projectile("enemy",foe.pos,Vector2.RIGHT.rotated(TAU*ray/10.0+g.adventure.clock*.35),{"credit":credit.duplicate(true),"range":850,"speed":280,"ice_visual":"orb","color":"#a4e9ff"},15)
   else:
    for id in a.points():
     if a.alive(str(id)) and foe.pos.distance_to(a.points()[id])<175:
      a.hit_player(str(id),12,a.combat.npc_key(foe),credit);a.combat.apply_status(a.combat.player_key(str(id)),"stun",1,"enemy")
 elif float(foe.secondary_timer)<=0 and nearest<550:
  foe.windup=.8;foe.secondary_timer=4.0
 if str(foe.source_realm)=="ice":preload("res://scripts/ice_projectiles.gd").step_boss(g,foe,dt)
 if nearest>46:
  var move=(target-foe.pos).normalized()*108*a.combat.speed_factor(a.combat.npc_key(foe))*dt
  for turn in [0.0,.65,-.65,1.2,-1.2]:
   var end:Vector2=foe.pos+move.rotated(turn)
   if a.can_stand(end) and a.combat.path_clear(foe.pos,end):foe.pos=end;break
 return true

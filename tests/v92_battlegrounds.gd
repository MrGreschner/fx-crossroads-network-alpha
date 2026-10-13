extends SceneTree
var failures:=0
func check(value:bool,label:String)->void:
 if not value:failures+=1;print("FAIL: ",label)
func _initialize()->void:call_deferred("run")
func run()->void:
 root.set_meta("fx_intro_seen",true)
 var g=load("res://scenes/arcade.tscn").instantiate();root.add_child(g);await process_frame;g.set_process(false);g.party_tools.set_process(false);g.legacy.set_process(false);g.presentation.set_process(false)
 g.presentation.close();g.role="host";g.my_id="p0";g.host_id="p0";g._set_mode("battlegrounds");g.bg_team_size=3;g.bg_map="woodland"
 for n in 6:
  var id:="p"+str(n);g.roster.append({"id":id,"name":"Player "+str(n)});g._add_player(id,n);g.teams[id]=n/3;g.lobby_heroes[id]="ram"
 check(g.player_limit()==6 and g._teams_ready(),"3v3 accepts two full sides")
 g._start_match();g.start_countdown=0
 var b=g.battlegrounds
 check(b.bases.size()==6 and g.opponents.is_empty(),"six personal barracks; no descent enemies")
 check(g.pvp_rule=="teams" and g.teams.p3==1,"team assignments preserved")
 for n in 12:b.step(.1)
 check(b.units.size()==12,"two starting soldiers per owner")
 var key:String=b.units.keys()[0];var u:Dictionary=b.units[key];var original:Vector2=u.pos
 for n in 5:b.step(.1)
 check(u.pos.distance_to(original)>20,"troops march down lanes")
 var hp:float=u.hp;b.damage(key,30,"p0");check(u.hp==hp,"allied army ignores friendly fire");b.damage(key,15,"p3");check(u.hp==hp-15,"enemy hero damages troops")
 g.positions.p0=b.spawn("p0");g.gold.p0=50000
 check(b.buy("p0","unit:healer"),"owner recruits healer at own barracks")
 check(b.buy("p0","melee"),"owner upgrades melee")
 g.positions.p0=b.bases["1:0"].pos;check(not b.buy("p0","unit:archer"),"enemy barracks cannot be upgraded")
 g.positions.p0=b.bases["0:0"].pos
 var before:float=b.heart_hp[1];b.damage("bgheart:1",200,"p0");check(b.heart_hp[1]==before,"heart shield prevents skipping barracks")
 var payload:Dictionary=b.snapshot();var remote=load("res://scripts/battlegrounds.gd").new();remote.game=g;remote.receive(JSON.parse_string(JSON.stringify(payload)))
 check(remote.units.size()==b.units.size() and remote.bases["0:0"].pos is Vector2,"network snapshot reconstructs vectors and upgrades")
 # Host validates central market proximity, living state and army ownership.
 var item:String=g.item_list[0];g.inventory.p0=[];g.gold.p0=100000;g._purchase("p0",item);check(g.inventory.p0.is_empty(),"items unavailable at home base")
 g.positions.p0=b.SIZE*.5;g._purchase("p0",item);check(g.inventory.p0.size()==1,"central market sells items")
 g.health.p0=0;g.respawn_at.p0=0;b.step(.1);check(g.health.p0>0 and (g.positions.p0 as Vector2).distance_to(b.spawn("p0"))<1,"hero respawns at own barracks")
 # Every existing hero can cast all three attacks into the new combat target system.
 for hero in g.characters:
  if bool(g.characters[hero].get("npc_only",false)):continue
  g.adventure.combat.setup("");g.hero_ids.p0=hero;g.levels.p0=10;g.health.p0=g._max_hp("p0");g.invincible_until.p0=0;g.positions.p0=Vector2(3300,2200);g.positions.p3=Vector2(3410,2200);g.health.p3=10000;g.cooldown_at.p0={"primary":0,"secondary":0,"special":0}
  for kind in ["primary","secondary","special"]:
   g._attack("p0",kind,Vector2.RIGHT,Vector2(3410,2200));g.adventure.combat.step(.05)
  g.charges.clear();g.guards.clear();g.missiles.clear()
 # Resource bounds: no owner can produce more than 24; eight owners <= 192.
 b.units.clear()
 for base in b.bases.values():
  base.counts=[6,3,3,3,3,3,3,3]
  for repeat in 10:
   for kind in 8:b.spawn_unit(base,kind,repeat)
 check(b.units.size()==144,"six owners capped at 144 troops")
 g.bg_map="warzone";b.map_id="warzone";b.air_timer=0;b.step(.1);check(b.bombs.size()==3,"warzone generates staggered, warned airstrike")
 var bomb:Dictionary=b.bombs[0];g.positions.p0=bomb.pos;g.positions.p3=bomb.pos;g.health.p0=1000;g.health.p3=1000;g.invincible_until.p0=0;g.invincible_until.p3=0;bomb.time=0;b.tick_bombs(.1);check(g.health.p0<1000 and g.health.p3<1000,"airstrike damages both teams")
 b.units.clear()
 for base_key in b.bases:
  if int(b.bases[base_key].team)==1:b.damage("bgbase:"+str(base_key),2000,"p0")
 check(not b.shielded(1),"clearing all opposing barracks removes shield")
 b.damage("bgheart:1",3000,"p0");check(b.winner==0 and not g.started,"heart defeat ends the match")
 # Eight-player layout is four actual lanes, not a stretched three-lane layout.
 g.adventure.combat.setup("");g.roster.clear();g.positions.clear();g.health.clear();g.teams.clear();g.bg_team_size=4;g.bg_map="woodland"
 for n in 8:
  var id:="p"+str(n);g.roster.append({"id":id,"name":id});g._add_player(id,n);g.teams[id]=n/4;g.lobby_heroes[id]="ram"
 g._start_match();g.start_countdown=0
 check(b.bases.size()==8 and b.lanes==4 and g.player_limit()==8,"4v4 has eight barracks and four paths")
 for base in b.bases.values():
  base.counts=[6,3,3,3,3,3,3,3]
  for repeat in 10:
   for kind in 8:b.spawn_unit(base,kind,repeat)
 check(b.units.size()==192,"eight players capped at 192 troops")
 for soldier in b.units.values():soldier.pos=Vector2(3250 if int(soldier.team)==0 else 3500,b.lane_y(int(soldier.lane)))
 var starting_army_hp:=0.0
 for soldier in b.units.values():starting_army_hp+=float(soldier.hp)
 var begin:=Time.get_ticks_usec()
 for n in 40:b.step(.1);g.adventure.combat.step(.1)
 print("192-troop bounded simulation, 40 ticks ms: ",(Time.get_ticks_usec()-begin)/1000.0,"; snapshot bytes: ",JSON.stringify(b.snapshot()).length())
 var remaining_army_hp:=0.0
 for soldier in b.units.values():remaining_army_hp+=float(soldier.hp)
 check(remaining_army_hp<starting_army_hp,"armies fight and damage each other without a hero initiating combat")
 check(b.units.size()<=192,"simulation never exceeds total cap")
 # A converted soldier becomes friendly temporarily; no permanently stolen army.
 var enemy_key:=""
 for key2 in b.units:
  if int(b.units[key2].team)==1:enemy_key=str(key2);break
 if not enemy_key.is_empty():
  g.positions.p0=b.units[enemy_key].pos;g.hero_ids.p0="thistlebond";var money:int=g.gold.p0;b.convert("p0",enemy_key)
  check(int(b.units[enemy_key].team)==0 and g.gold.p0>money,"Change of Heart supports opposing soldiers and grants kill credit")
  b.units[enemy_key].expires=0;b.tick_units(.1);check(not b.units.has(enemy_key),"converted ally expires after eight seconds")
 g.adventure.combat.setup("");remote.game=null;remote=null
 for audio in g.journey.get_children():
  if audio is AudioStreamPlayer:audio.stop()
 g.queue_free();await process_frame;await process_frame;print("v92 Battlegrounds failures: ",failures);quit(failures)

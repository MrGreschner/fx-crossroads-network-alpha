extends SceneTree
var failures:=0
func check(ok:bool,label:String)->void:
 if not ok:failures+=1;print("FAIL: ",label)
func _initialize()->void:call_deferred("run")
func run()->void:
 root.set_meta("fx_intro_seen",true)
 var a=load("res://scenes/arcade.tscn").instantiate();root.add_child(a);await process_frame;a.set_process(false);a.party_tools.set_process(false);a.role="host";a.mode="arena";a.started=true;a.start_countdown=0;a.pvp_rule="teams"
 a._add_player("owner",0);a._add_player("rival",1);a._add_player("friend",2)
 a.teams={"owner":0,"rival":1,"friend":0};a.positions={"owner":Vector2(700,500),"rival":Vector2(770,530),"friend":Vector2(770,560)};a.hero_ids.owner="basketball";a.levels.owner=10
 a.adventure.setup("");a.field_obstacles.clear();a._rebuild_grid();a.guards.clear();a.opponents.clear()
 a._attack("owner","special",Vector2.RIGHT,Vector2(900,500))
 var c=a.adventure.combat
 check(a.guards.size()==1,"real Dribble special spawns a minion")
 var body:Dictionary=a.guards[0];var id:String="summon:"+str(body.net_uid);var key:String="p:"+id
 check(c.hostile("rival").has(key) and not c.hostile("friend").has(key) and not c.hostile("owner").has(key),"summons obey enemy/team targeting")
 check(c.v59.target_points().has(id) and c.v59.rival_id(id)=="owner","legacy melee/chain/fork targeting includes summon")
 var hp:float=body.hp;c.damage(key,10,"friend");check(body.hp==hp,"friendly fire cannot damage the minion")
 a.characters["test_melee"]={"max_health":100,"primary":{"style":"melee","damage":10,"cooldown":.1,"range":100,"arc_degrees":100}}
 a.hero_ids.rival="test_melee";a.positions.rival=body.pos-Vector2(45,0);a._attack("rival","primary",Vector2.RIGHT,body.pos)
 check(float(body.hp)<hp,"actual legacy melee attack damages minion")
 hp=float(body.hp);check(c.v59.catch_copy(body.pos-Vector2(40,0),body.pos+Vector2(40,0),"rival",9) and body.hp==hp-9,"legacy projectile collision damages minion")
 hp=float(body.hp);c.v75.area("rival",body.pos,50,8,{});check(body.hp==hp-8,"shared AoE damages minion")
 c.apply_status(key,"poison",1,"rival",2);hp=float(body.hp);c.tick_statuses(1);check(float(body.hp)<hp,"status damage applies to summon health")
 var packet:Dictionary=a._snapshot();var sent:Dictionary=packet.guards[0]
 check(sent.net_uid==body.net_uid and sent.hp==body.hp and sent.owner=="owner" and sent.max_hp==70,"snapshot carries stable identity/team/HP for clients")
 a.role="guest";hp=float(body.hp);c.damage(key,20,"rival");check(body.hp==hp,"guest cannot authoritatively damage summon");a.role="host"
 var hero_kills:int=a.arena_records.rival.kills;c.damage(key,999,"rival")
 check(a.guards.is_empty() and c.actor(key).is_empty() and not c.hostile("rival").has(key) and not c.statuses.has(key),"lethal damage removes summon and status immediately")
 check(a.arena_records.rival.kills==hero_kills,"minion defeat is not a hero kill")
 # Modern summon families already use the same registry; verify the legacy paths too.
 for family in ["mosaic","apiary"]:
  var raised:String=c.party_heroes.add_unit("owner",Vector2(900,500),family)
  var unit:Dictionary=c.morrow.units[raised];check(c.hostile("rival").has("p:"+raised),"modern "+family+" is targetable")
  c.damage("p:"+raised,999,"rival");check(not c.morrow.units.has(raised),"modern "+family+" dies")
 for player in a.find_children("*","AudioStreamPlayer",true,false):player.stop();player.stream=null
 await create_timer(.1).timeout
 a.queue_free();await process_frame;await process_frame;print("v107 minion failures: ",failures);quit(1 if failures else 0)

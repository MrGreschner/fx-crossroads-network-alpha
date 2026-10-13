extends SceneTree
var failures:=0
func check(ok:bool,label:String)->void:
 if not ok:failures+=1;print("FAIL: "+label)
func _initialize()->void:call_deferred("run")
func choose(game:Node,id:String)->void:
 game.selected_character=id;game.start_run(false,"elementary");game.enemies.clear();game.position_in_world=Vector2(3800,5400);game.level=6;game.adventure.school.initialized=true
func run()->void:
 var game=load("res://scenes/main.tscn").instantiate();root.add_child(game);await process_frame;game.set_process(false)
 var combat=game.adventure.combat;var extra=combat.classics
 check(game.manifest.characters.size()>=29 and game.characters.iris.name=="Iris Chalkbinder","Iris is hero 29")
 for id in ["basketball","goalie","medic"]:check(game.characters[id].primary.damage==29,id+" primary damage 29")
 for id in ["ram","basketball","book","cat"]:
  choose(game,id);game.adventure.spawn("pencil_scrapper",Vector2(3860,5400),300,false)
  combat.cast("solo",game.hero.primary,Vector2.RIGHT,float(game.hero.primary.damage))
  check(extra.strikes.size()==1 and game.enemies[0].hp==300-float(game.hero.primary.damage),id+" unique visual preserves close attack damage")
 choose(game,"basketball")
 for point in [Vector2(3980,5400),Vector2(4130,5480),Vector2(4300,5400),Vector2(4500,5400)]:game.adventure.spawn("pencil_scrapper",point,300,false)
 combat.cast("solo",game.hero.secondary,Vector2.RIGHT,28);extra.step(.1)
 check(game.position_in_world.x>3800 and game.position_in_world.x<3980 and combat.projectiles.is_empty(),"Dribble body moves smoothly, not a projectile")
 for n in 20:extra.step(.1)
 var damaged:=0
 for enemy in game.enemies:
  if enemy.hp==272:damaged+=1
 check(damaged==3 and extra.bounces.is_empty() and game.position_in_world.distance_to(Vector2(4300,5400))<3,"bounce hits three distinct foes and stops at third")
 choose(game,"basketball");game.adventure.spawn("pencil_scrapper",Vector2(3980,5400),300,false)
 combat.cast("solo",game.hero.secondary,Vector2.RIGHT,28);extra.step(.1);game.enemies[0].pos+=Vector2(90,0);extra.step(.5)
 check(game.enemies[0].hp==272,"body bounce tracks a target that moves during travel")
 choose(game,"basketball");game.adventure.spawn("pencil_scrapper",Vector2(6900,5400),300,false);game.position_in_world=Vector2(6700,5400)
 combat.cast("solo",game.hero.secondary,Vector2.RIGHT,28);check(extra.bounces.is_empty(),"bounce cannot select enemies beyond wall")
 choose(game,"book");game.adventure.spawn("pencil_scrapper",Vector2(4050,5400),300,false)
 extra.holding("solo",true);combat.cast("solo",game.hero.secondary,Vector2.RIGHT,11)
 check(extra.channeling("solo") and combat.speed_factor("p:solo")==0 and combat.busy("solo"),"book opens, immobilizes and prevents other casts")
 for n in 6:extra.holding("solo",true);extra.step(.1)
 check(combat.projectiles.size()==2 and combat.projectiles[0].style=="homing" and combat.projectiles[0].stats.flying_page,"hold emits homing paper pages")
 for n in 15:combat.step_projectiles(.05)
 check(game.enemies[0].hp<300,"flying pages actually seek and damage target")
 game.health=100;game.invulnerable_time=0;game.take_player_damage(10);check(is_equal_approx(game.health,87),"open Book takes 30 percent additional damage")
 extra.holding("solo",false);check(not extra.channeling("solo") and combat.speed_factor("p:solo")==1,"release immediately closes book and restores movement")
 extra.holding("solo",true);combat.cast("solo",game.hero.secondary,Vector2.RIGHT,11);extra.step(.5);check(not extra.channeling("solo"),"missing remote heartbeat closes book")
 extra.holding("solo",true);combat.cast("solo",game.hero.secondary,Vector2.RIGHT,11);combat.apply_status("p:solo","stun",1,"enemy");extra.step(.1);check(not extra.channeling("solo"),"stun cancels channel")
 choose(game,"book");extra.holding("solo",true);combat.cast("solo",game.hero.secondary,Vector2.RIGHT,11);game.health=0;extra.step(.1);check(not extra.channeling("solo"),"death cancels channel")
 choose(game,"cat");game.adventure.spawn("pencil_scrapper",Vector2(3800,5300),300,false)
 combat.cast("solo",game.hero.secondary,Vector2.RIGHT,43);extra.step(.05);check(game.enemies[0].hp==300,"cat spin does not instantaneously hit whole circle")
 extra.step(.6);check(game.enemies[0].hp==257 and extra.spins.is_empty(),"moving spin reaches foe once")
 choose(game,"iris");game.adventure.spawn("pencil_scrapper",Vector2(3950,5400),300,false)
 combat.cast("solo",game.hero.primary,Vector2.RIGHT,16);extra.step(.1);check(game.enemies[0].hp==300,"chalk drawing advances before hitting distant foe")
 extra.step(.5);extra.step(.5);check(game.enemies[0].hp==284,"persistent chalkstroke damages target only once")
 for n in 4:combat.cast("solo",game.hero.primary,Vector2.RIGHT,16)
 check(extra.strokes.size()==3,"Iris chalk line cap three")
 game.health=70;combat.projectiles.clear();combat.cast("solo",game.hero.secondary,Vector2.RIGHT,12)
 check(extra.strokes.is_empty() and combat.projectiles.size()==6 and game.health==79,"erase consumes three lines, emits six shards and passive heals nine")
 combat.cast("solo",game.hero.special,Vector2.RIGHT,7);extra.step(.51)
 check(game.enemies[0].hp==277 and combat.speed_factor(combat.npc_key(game.enemies[0]))==.65,"blackboard grid damages and slows")
 check(game.elder_lines().size()==14 and str(game.elder_lines()).contains("Ram Descent") and str(game.elder_lines()).contains("Wayfarer") and str(game.elder_lines()).contains("Join Random"),"Elder explains all game styles")
 var host=load("res://scenes/arcade.tscn").instantiate();root.add_child(host);await process_frame;host.set_process(false);host._set_mode("defense");host._solo();host._add_player("friend",1);host.opponents.clear();host.hero_ids.friend="book";host.levels.friend=6
 var hc=host.adventure.combat;var h=hc.classics;var origin:Vector2=host.positions.friend
 host._packet("friend",{"type":"pos","x":origin.x,"y":origin.y,"hero":"book","secondary_held":true});host._attack("friend","secondary",Vector2.RIGHT)
 check(h.channeling("friend"),"remote held input starts host book channel")
 host._packet("friend",{"type":"pos","x":origin.x+60,"y":origin.y,"hero":"book","secondary_held":true});check(host.positions.friend==origin,"host rejects movement while remote Book open")
 host.health.friend=100;host.invincible_until.clear();host._hurt("friend",10,"enemy");check(host.health.friend==87,"co-op Book vulnerability matches solo")
 var packet:Dictionary=JSON.parse_string(JSON.stringify(host._snapshot()));check(packet.adventure.combat.classics.books.has("friend"),"channel visual replicated")
 host._packet("friend",{"type":"pos","x":origin.x+60,"y":origin.y,"hero":"book","secondary_held":false});check(not h.channeling("friend"),"remote release removes movement lock")
 host.hero_ids.friend="basketball";host.adventure.spawn("pencil_scrapper",host.positions.friend+Vector2(160,0),300,false);hc.cast("friend",host.characters.basketball.secondary,Vector2.RIGHT,28)
 check(host._snapshot().players.friend.charging,"body bounce uses host movement replication")
 var before:Vector2=host.positions.friend;h.step(.1);check(host.positions.friend!=before,"remote bounce moves actual player")
 hc.setup(host.realm_id);check(h.bounces.is_empty() and h.books.is_empty() and h.strokes.is_empty(),"new run clears all overhaul state")
 for node in [game,host]:
  for voice in node.journey.voices:voice.stop()
  node.queue_free()
 await create_timer(.3).timeout;print("V46 FAILURES: "+str(failures));quit(failures)

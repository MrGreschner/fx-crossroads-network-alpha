extends SceneTree
var failures:=0
var g:Node
var combat:Node
var held:Node
func check(ok:bool,title:String)->void:
 if not ok:failures+=1;print("FAIL: ",title)
func _initialize()->void:call_deferred("run")
func setup(id:String)->void:
 g.start_run(false,"grove");g.presentation.close();g.menu="";g.selected_character=id;g.hero=g.characters[id].duplicate(true);g.level=10;g.health=g.max_health();g.position_in_world=Vector2(450,450);g.enemies.clear();g.obstacles.clear();g.build_scenery();g.inventory.clear();g.bonus_damage=0;g.upgrade="";g.mastery="";combat.setup("grove");g.cooldowns={"primary":0.0,"secondary":0.0,"special":0.0}
func enemy(uid:int,offset:Vector2)->String:
 var p:Vector2=g.position_in_world+offset
 g.enemies.append({"uid":uid,"pos":p,"type":"bramble","hp":1000.0,"max_hp":1000.0,"boss":false,"hit_radius":18,"speed":0.0,"timer":9.0,"attack_timer":9.0,"name":"Test Bramble"})
 return "e:"+str(uid)
func cast(id:String,kind:String,seconds:float,offset:Vector2=Vector2(220,0))->void:
 setup(id);held.begin("solo",kind,offset.normalized(),g.position_in_world+offset)
 check(held.charges.has("solo"),id+" starts hold")
 held.step(seconds);held.release("solo")
func tidy(node:Node)->void:
 for p in node.find_children("*","AudioStreamPlayer",true,false):p.stop();p.stream=null
 node.queue_free();await process_frame;await process_frame;await create_timer(.2).timeout
func run()->void:
 root.set_meta("fx_intro_seen",true);root.set_meta("fx_tutorial_offered",true)
 g=load("res://scenes/main.tscn").instantiate();root.add_child(g);current_scene=g;await process_frame;g.set_process(false)
 combat=g.adventure.combat;held=combat.held_cast
 setup("mosaic");var marked:=enemy(701,Vector2(180,0));var nearer:=enemy(702,Vector2(65,40));combat.v79.prepare("solo",g.hero.primary,Vector2.RIGHT,g.position_in_world+Vector2(180,0));combat.cast("solo",g.hero.primary,Vector2.RIGHT,7)
 check(combat.party_heroes.marks.get("solo","")==marked and combat.morrow.units.size()==1,"primary summons and marks clicked enemy")
 var u:Dictionary=combat.morrow.units.values()[0];u.pos=combat.point_array(g.position_in_world+Vector2(140,0));u.attack=0
 combat.morrow.step(.05);check(g.enemies[0].hp==993 and g.enemies[1].hp==1000,"minion prioritizes marked enemy")
 combat.cast("solo",g.hero.secondary,Vector2.RIGHT,0);u=combat.morrow.units.values()[0]
 check(float(u.haste)==4 and int(u.weight)==1,"Scatter buffs lone unmerged tile")
 for n in 4:combat.party_heroes.add_unit("solo",g.position_in_world,"mosaic")
 combat.party_heroes.merge("solo",true);u=combat.morrow.units.values()[0]
 check(int(u.weight)==5 and float(u.time)==26,"larger guardian lasts longer")
 for n in 3:combat.cast("solo",g.hero.primary,Vector2.RIGHT,7)
 check(combat.party_heroes.slots("solo","mosaic")==7 and combat.morrow.units.size()==3,"guardian allows exactly two extra companions")
 combat.party_heroes.merge("solo",true);check(combat.morrow.units.size()==3,"merge remains bounded")
 combat.cast("solo",g.hero.secondary,Vector2.RIGHT,0);check(combat.morrow.units.size()==7,"Scatter splits all pieces")
 check(combat.morrow.units.values().all(func(a):return int(a.weight)==1 and float(a.haste)==4),"every split companion gets haste")
 setup("mosaic");held.begin("solo","special",Vector2.RIGHT,Vector2(700,450));held.step(1.2);held.release("solo")
 check(combat.party_heroes.shots.size()==5,"bubble special works with zero minions")
 var victim:=enemy(703,Vector2(80,0));combat.party_heroes.step(.25)
 check(g.enemies[0].hp<1000 and combat.party_heroes.fields.size()>0,"bubble contact damages and leaves pool")
 combat.party_heroes.step(.1);check(combat.statuses.get(victim,{}).has("slow"),"splatter slows targets")
 for n in 70:combat.party_heroes.step(.1)
 check(combat.party_heroes.shots.is_empty() and combat.party_heroes.fields.is_empty(),"bubbles and pools expire")
 setup("ferryman");victim=enemy(704,Vector2(70,0));held.begin("solo","primary",Vector2.RIGHT,Vector2(650,450));held.step(1.1);held.release("solo")
 check(g.enemies[0].hp==1000,"oar damage waits for sweeping blade")
 combat.v112.step(.18);check(g.enemies[0].hp==960 and combat.statuses.get(victim,{}).has("slow"),"charged oar damage and slow")
 combat.v112.step(.1);check(g.enemies[0].hp==960,"oar hits each target only once")
 cast("stormscribe","primary",.85);check(bool(combat.projectiles[0].stats.get("ball_lightning",false)),"full charge enables ball lightning")
 victim=enemy(705,Vector2(180,65));combat.step_projectiles(.25);check(g.enemies[0].hp==996,"ball lightning shocks nearby enemy")
 cast("stormscribe","primary",0);check(not bool(combat.projectiles[0].stats.get("ball_lightning",false)),"tap is ordinary spark")
 setup("patch");combat.cast("solo",g.hero.special,Vector2.RIGHT,10)
 check(combat.morrow.units.size()==2,"Patch uses targetable minions")
 var ids:Array=combat.morrow.units.keys();var first:String=ids[0];var second:String=ids[1]
 check(combat.vec(combat.morrow.units[first].pos).distance_to(combat.vec(combat.morrow.units[second].pos))>40,"Patch companions spawn separated")
 combat.morrow.units[second].pos=combat.morrow.units[first].pos.duplicate();combat.morrow.step(.1)
 check(combat.vec(combat.morrow.units[first].pos).distance_to(combat.vec(combat.morrow.units[second].pos))>10,"stacked companions separate")
 combat.damage("p:"+first,100,"enemy");check(not combat.morrow.units.has(first),"Patch minion can be attacked and killed")
 for pose in ["idle","walk1","walk2","attack"]:check(ResourceLoader.exists("res://assets/goalie_"+pose+".png"),"goalie pose available")
 await tidy(g)
 var a=load("res://scenes/arcade.tscn").instantiate();root.add_child(a);current_scene=a;await process_frame;a.set_process(false);a.party_tools.set_process(false);a.mode="arena";a.role="host";a.started=true;a.start_countdown=0;a.my_id="host";a.host_id="host";a.roster.assign([{"id":"host","name":"Host"},{"id":"guest","name":"Friend"}]);a._add_player("host",0);a._add_player("guest",1);a.positions.host=Vector2(450,450);a.positions.guest=Vector2(650,450);a.hero_ids.guest="patch";a.levels.guest=10;a.adventure.combat.setup("grove");combat=a.adventure.combat
 combat.cast("guest",a.characters.patch.special,Vector2.LEFT,10)
 var buddy:String=combat.morrow.units.keys()[0];check(combat.hostile("host").has("p:"+buddy),"enemy player can target Patch buddy in arena")
 combat.damage("p:"+buddy,100,"host");check(not combat.morrow.units.has(buddy),"arena player can destroy Patch buddy")
 a.hero_ids.guest="mosaic";combat.v79.prepare("guest",a.characters.mosaic.primary,Vector2.LEFT,a.positions.host);combat.cast("guest",a.characters.mosaic.primary,Vector2.LEFT,7)
 check(combat.party_heroes.marks.get("guest","")=="p:host","arena mark selects opposing hero")
 check(a._snapshot().adventure.combat.party_heroes.marks.has("guest"),"mark travels with existing snapshot")
 await tidy(a);print("v121 failures: ",failures);quit(1 if failures else 0)

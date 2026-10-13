extends SceneTree
var failures:=0
func check(ok:bool,label:String)->void:
 if not ok:failures+=1;print("FAIL: ",label)
func _initialize()->void:call_deferred("run")
func run()->void:
 root.set_meta("fx_intro_seen",true)
 var a=load("res://scenes/arcade.tscn").instantiate();root.add_child(a);await process_frame;a.set_process(false);a.party_tools.set_process(false)
 a.role="host";a.mode="arena";a.started=true;a.start_countdown=0;a._add_player("hero",0);a._add_player("foe",1);a._add_player("ally",2);a.pvp_rule="teams";a.teams={"hero":0,"foe":1,"ally":0}
 a.positions={"hero":Vector2(700,500),"foe":Vector2(760,500),"ally":Vector2(760,500)};a.hero_ids.hero="hollow_rider";a.levels.hero=10;a.adventure.setup("");a.field_obstacles.clear();a._rebuild_grid();a.opponents.clear()
 var c=a.adventure.combat;var h=c.halloween;var v=c.v110
 check(a.characters.values().filter(func(hero):return not bool(hero.get("npc_only",false))).size()>=79,"all 79 heroes load")
 var before:int=a.health.foe;var friendly:int=a.health.ally
 h.cast("hero",a.characters.hollow_rider.primary,Vector2.RIGHT,25);check(a.health.foe==before,"scythe has a windup");h.step(.13)
 check(a.health.foe<before and a.health.ally==friendly,"melee sweep hits enemies only")
 a.positions.foe=Vector2(800,500);h.cast("hero",a.characters.hollow_rider.secondary,Vector2.RIGHT,26);h.step(.31)
 check(a.positions.foe.x>800 and c.effect_time("p:foe","stun")>0 and c.reduction("hero")>=.12,"lantern slam pushes, stuns and grants passive guard")
 h.cast("hero",a.characters.hollow_rider.special,Vector2.RIGHT,5);check(h.riding("hero") and c.speed_factor("p:hero")>1,"spectral horse increases movement")
 h.reset();h.cast("hero",a.characters.hollow_rider.mastery.final_technique.attack,Vector2.RIGHT,14)
 var horse:String=str(c.morrow.units.keys()[-1]);check(c.hostile("foe").has("p:"+horse) and c.morrow.units[horse].hp==70,"guardian is a targetable summon");c.damage("p:"+horse,999,"foe");check(not c.morrow.units.has(horse),"guardian can die")
 c.statuses.clear();h.reset();a.health.foe=300;a.positions.foe=Vector2(770,500);a.hero_ids.hero="hazel_hex"
 c.v79.prepare("hero",a.characters.hazel_hex.primary,Vector2.RIGHT,Vector2(1000,500));h.cast("hero",a.characters.hazel_hex.primary,Vector2.RIGHT,18);h.step(.2)
 check(a.health.foe<300 and c.effect_time("p:foe","slow")>0 and not h.effects.any(func(e):return e.kind=="pool"),"witch direct shot slows and leaves no missed-shot pool")
 a.positions.foe=Vector2(700,900);h.reset();h.cast("hero",a.characters.hazel_hex.primary,Vector2.RIGHT,18);h.step(1.8)
 check(h.effects.any(func(e):return e.kind=="pool"),"missed shot leaves ground poison")
 h.step(4.1);check(h.effects.is_empty(),"poison pools expire")
 for n in 16:h.pool("hero",Vector2(700+n*70,700))
 check(h.effects.size()==10,"poison pool cap")
 h.reset();a.positions.hero=Vector2(700,500);a.positions.foe=Vector2(755,500);a.health.foe=300
 c.v79.prepare("hero",a.characters.hazel_hex.secondary,Vector2.RIGHT,Vector2(1700,500));h.cast("hero",a.characters.hazel_hex.secondary,Vector2.RIGHT,10)
 check(h.moving("hero") and c.speed_factor("p:hero")==0 and c.busy("hero"),"flight owns movement and blocks other casts")
 for n in 22:h.step(.1)
 check(not h.moving("hero") and a.positions.hero.distance_to(Vector2(1700,500))<2,"flight lands at selected point")
 check(a.health.foe<300 and c.effect_time("p:foe","burn")>0 and c.effect_time("p:foe","stun")>0,"flight bomb damages, stuns and burns")
 h.reset();a.positions.hero=Vector2(700,500);a.positions.ally=Vector2(730,500);a.positions.foe=Vector2(750,500);a.health.hero=50;a.health.ally=50
 c.v79.prepare("hero",a.characters.hazel_hex.special,Vector2.RIGHT,Vector2(720,500));h.cast("hero",a.characters.hazel_hex.special,Vector2.RIGHT,8)
 check(h.bonus("hero")==1.05 and h.bonus("ally")==1.05 and h.bonus("foe")==1,"cauldron aura is friendly only")
 h.on_hit("ally",100);check(a.health.ally==56,"life-on-hit capped at six health per second");h.on_hit("ally",100);check(a.health.ally==56,"healing cap applies to repeated hits")
 c.dot_damage=true;h.on_hit("hero",100);check(a.health.hero==50,"DoT never generates life-on-hit");c.dot_damage=false
 h.step(.5);check(h.effects.any(func(e):return e.kind=="splatter"),"offensive cauldron targets enemies")
 h.reset();h.cast("hero",a.characters.hazel_hex.mastery.final_technique.attack,Vector2.RIGHT,0);h.step(.5)
 check(a.health.hero>50 and not h.effects.any(func(e):return e.kind=="splatter"),"alternative cauldron trades attacks for heals")
 h.reset();a.hero_ids.hero="little_menace";a.positions.foe=Vector2(750,500);a.health.foe=300;c.statuses.clear()
 v.cast("hero",a.characters.little_menace.primary,Vector2.RIGHT,8)
 for n in 3:v.step(.11)
 check(a.health.foe==276 and c.effect_time("p:foe","slow")>0,"three landed jabs apply slow")
 v.cast("hero",a.characters.little_menace.secondary,Vector2.RIGHT,0)
 check(v.small("hero") and c.speed_factor("p:hero")>=1.5 and v.target_radius("p:hero",20)==8,"shrinking changes speed and projectile target radius")
 check(v.resize("hero",Rect2(0,0,56,64)).size==Vector2(28,32),"shrinking changes rendered size")
 a.health.hero=120;c.projectiles.clear()
 c.launch_projectile("foe",Vector2(600,520),Vector2.RIGHT,{"range":250,"speed":300},10)
 c.step_projectiles(.5);check(a.health.hero==120,"near-miss projectile misses smaller hero hitbox")
 c.projectiles.clear();var stored:Dictionary=v.mini.duplicate(true);v.mini.clear()
 c.launch_projectile("foe",Vector2(600,520),Vector2.RIGHT,{"range":250,"speed":300},10)
 c.step_projectiles(.5);check(a.health.hero<120,"same projectile hits normal-size hero");c.projectiles.clear();v.mini=stored
 before=a.health.foe;v.cast("hero",a.characters.little_menace.primary,Vector2.RIGHT,8);v.step(.11);check(a.health.foe<before,"can attack while mini")
 v.step(4.1);check(not v.small("hero"),"mini form expires")
 a.health.hero=120;a.health.foe=300;a.health.ally=100;c.statuses.clear();v.cast("hero",a.characters.little_menace.special,Vector2.RIGHT,0);v.step(1.01)
 check(a.health.hero==60 and a.health.foe==240 and a.health.ally==100,"sacrifice pays half max health and damages foes only")
 a.health.hero=10;v.cast("hero",a.characters.little_menace.special,Vector2.RIGHT,0);v.step(1.01);check(a.health.hero==0 and a.respawn_at.has("hero"),"insufficient health defeats caster with arena respawn")
 a.health.hero=120;a.health.foe=300;v.reset();a.hero_ids.hero="echo_dancer";a.positions.hero=Vector2(700,500);a.positions.foe=Vector2(750,500)
 v.cast("hero",a.characters.echo_dancer.primary,Vector2.RIGHT,22);before=a.health.foe;v.step(.46)
 check(a.health.foe<before,"echo cut repeats after delay")
 a.positions.hero=Vector2(800,500);v.cast("hero",a.characters.echo_dancer.secondary,Vector2.LEFT,12);check(a.positions.hero.distance_to(Vector2(700,500))<2,"feint returns to last strike origin")
 v.cast("hero",a.characters.echo_dancer.special,Vector2.RIGHT,20);check(v.effects.size()>0,"encore replays authored strike memory")
 var snap:Dictionary=c.snapshot().duplicate(true);h.reset();v.reset();c.receive(snap);check(not v.memories.is_empty(),"new combat state survives network snapshot")
 a.role="guest";h.reset();v.reset()
 h.receive({"effects":[{"owner":str(a.my_id),"kind":"flight","start":[700,500],"end":[1000,500],"pos":[700,500],"age":0.0,"duration":1.0,"time":1.0}],"clock":0})
 h.client_step(.1);check(a.local_pos.x>700 and a.local_pos.x<1000,"guest flight animates between snapshots without applying damage");h.reset()
 h.cast("hero",a.characters.hazel_hex.primary,Vector2.RIGHT,18);v.cast("hero",a.characters.little_menace.secondary,Vector2.RIGHT,0)
 check(h.effects.is_empty() and v.mini.is_empty(),"guests cannot author new abilities");a.role="host"
 a.started=false;v.step(.1);h.step(.1);check(h.effects.is_empty() and v.effects.is_empty() and v.mini.is_empty(),"new effects clear outside matches")
 for player in a.find_children("*","AudioStreamPlayer",true,false):player.stop();player.stream=null
 await create_timer(.1).timeout;a.queue_free();await process_frame;await process_frame
 var g=load("res://scenes/main.tscn").instantiate();root.add_child(g);await process_frame;g.set_process(false);g.presentation.asked=true;g.presentation.close();g.session_menu.resume()
 check(g.characters.size()>=79,"solo roster has 79 playable heroes")
 g.journey.last_sound=Time.get_ticks_msec()+1000000
 g.selected_character="hazel_hex";g.start_training();g.set_process(false);g.fire("primary");check(not g.adventure.combat.halloween.effects.is_empty(),"witch primary works through normal solo input")
 g.enter_region("town");check(g.adventure.combat.halloween.effects.is_empty(),"return to town clears Halloween effects")
 g.session_menu._process(.01);g.presentation._process(.01)
 check(g.session_menu.menu_button.position.y==g.presentation.adventure_button.position.y,"Menu shares top button row")
 check(g.session_menu.menu_button.position.x>g.presentation.adventure_button.position.x+g.presentation.adventure_button.size.x,"Menu sits beside Adventures without overlap")
 for player in g.find_children("*","AudioStreamPlayer",true,false):player.stop();player.stream=null
 await create_timer(.1).timeout;g.queue_free();await process_frame;await process_frame;print("v110 failures: ",failures);quit(1 if failures else 0)

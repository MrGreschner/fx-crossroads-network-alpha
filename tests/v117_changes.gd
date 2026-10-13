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
 cast("baseball","primary",0)
 check(combat.projectiles.size()==1 and is_equal_approx(float(combat.projectiles[0].damage),22),"tap baseball base damage")
 cast("baseball","primary",1.1)
 check(combat.projectiles.size()==1 and is_equal_approx(float(combat.projectiles[0].speed),1105) and is_equal_approx(float(combat.projectiles[0].damage),40.7),"charged baseball speed and damage")
 check(g.cooldowns.primary>0 and held.charges.is_empty(),"cooldown begins only on release")
 cast("stormscribe","primary",1.2)
 check(is_equal_approx(float(combat.projectiles[0].damage),34.2) and float(combat.projectiles[0].radius)>10,"storm spark grows collision and damage")
 cast("navigator","secondary",1.4)
 check(combat.projectiles.size()==2 and combat.projectiles[0].style=="homing" and float(combat.projectiles[0].stats.splash_damage)>8,"charged navigator preserves Twin Stars and splash")
 cast("golfer","secondary",0)
 var short:float=combat.vec(g.adventure.lob_shots[0].end).distance_to(g.position_in_world)
 check(is_equal_approx(short,85) and is_equal_approx(float(g.adventure.lob_shots[0].damage),28),"tap chip short landing")
 cast("golfer","secondary",1.4)
 check(is_equal_approx(combat.vec(g.adventure.lob_shots[0].end).distance_to(g.position_in_world),330) and is_equal_approx(float(g.adventure.lob_shots[0].damage),42) and int(g.adventure.lob_shots[0].fragments)==6,"charged chip landing damage and fragments")
 cast("vesper","secondary",1.5)
 var comet:Dictionary=g.adventure.lob_shots[0]
 check(combat.vec(comet.start).y<combat.vec(comet.end).y-300 and comet.cast_visual=="meteor" and is_equal_approx(float(comet.damage),56) and is_equal_approx(float(comet.radius),119),"Vesper summons larger comet from sky")
 cast("stormscribe","special",.5,Vector2(110,60))
 check(g.adventure.lob_shots.size()==1 and combat.vec(g.adventure.lob_shots[0].end).distance_to(g.position_in_world+Vector2(110,60))<1,"Thunderfall release target follows selected location")
 setup("beaver");var key:String=enemy(201,Vector2(75,0));held.begin("solo","secondary",Vector2.RIGHT,g.position_in_world+Vector2(200,0));held.step(1.3);held.release("solo")
 check(combat.effect_time(key,"stun")>1.9 and combat.actor(key).pos.x>g.position_in_world.x+150,"Alderjaw charge increases stun and knockback")
 setup("dawnblade");key=enemy(202,Vector2(60,0));held.begin("solo","primary",Vector2.RIGHT,g.position_in_world+Vector2(200,0));held.step(1);held.release("solo")
 check(combat.effect_time(key,"bleed")>0 and combat.actor(key).pos.x>=g.position_in_world.x+120,"Mara charged cut retains bleed and adds knockback")
 cast("caelum","secondary",1.2)
 check(combat.projectiles.size()==3 and is_equal_approx(float(combat.projectiles[0].damage),19.2) and combat.projectiles[0].style=="corkscrew_key","Caelum charged mirror fan")
 setup("caelum");combat.v59.copies["solo"]={"pos":[450,520],"transferred":false};held.begin("solo","secondary",Vector2.RIGHT,Vector2(650,450));held.step(.3);held.release("solo");check(combat.projectiles.size()==6,"Twin Self echoes new secondary")
 setup("baseball");held.begin("solo","primary",Vector2.RIGHT,Vector2(650,450));g.fire("primary");check(combat.projectiles.is_empty() and float(g.cooldowns.primary)==0,"holding cannot emit early shots or spend cooldown")
 combat.apply_status("p:solo","stun",1,"enemy");held.step(.1);check(held.charges.is_empty(),"stun cancels charge without firing")
 setup("golfer");held.begin("solo","secondary",Vector2.RIGHT,Vector2(650,450));held.local_input(.1,false);check(held.charges.is_empty() and g.adventure.lob_shots.is_empty(),"opening menus cancels without casting")
 setup("book");var targets:Array=[]
 for n in 4:targets.append(enemy(300+n,Vector2(90+n*55,50)))
 combat.classics.holding("solo",true);g.fire("secondary")
 for n in 8:combat.classics.holding("solo",true);combat.classics.step(.22)
 var counts:Dictionary={}
 for shot in combat.projectiles:
  var target:String=str(shot.stats.get("homing_target",""));counts[target]=int(counts.get(target,0))+1
 check(counts.size()==4 and int(counts.get(targets[0],0))==4,"book prioritises nearest and visits all other targets at original rate")
 check(combat.projectiles.size()==8,"book distributes shots instead of multiplying damage output")
 setup("twisterspell");combat.twister.cast("solo",g.hero.secondary,Vector2.RIGHT,10)
 check(is_equal_approx(combat.twister.speed("solo"),1.2) and combat.twister.sway("solo",Vector2.ZERO)==Vector2.ZERO,"tornado speed reduced and rest stable")
 g.enemy_shots.assign([{"pos":g.position_in_world,"owner":"enemy","damage":10}]);combat.twister.step(.01);check(g.enemy_shots.is_empty(),"tornado catches hostile projectiles")
 setup("baseball");g.mobile.enabled=true;g.mobile.aim=Vector2.RIGHT;g.mobile.attacking=true;held.local_input(.01,true);held.step(.55)
 check(held.charges.has("solo") and combat.projectiles.is_empty(),"touch primary holds charge without premature firing")
 g.mobile.attacking=false;held.local_input(.01,true)
 check(combat.projectiles.size()==1 and is_equal_approx(float(combat.projectiles[0].damage),31.35),"touch release sends measured charge")
 setup("stormscribe");Input.action_press("special");held.local_input(.01,true);held.step(.2)
 check(held.charges.has("solo") and g.adventure.lob_shots.is_empty(),"Space holds special targeting")
 Input.action_release("special");held.local_input(.01,true);check(g.adventure.lob_shots.size()==1,"Space release casts once")
 setup("golfer");g.cooldowns.secondary=2;held.begin("solo","secondary",Vector2.RIGHT,Vector2(650,450));check(held.charges.is_empty(),"cooldown blocks new charge")
 setup("baseball");held.begin("solo","primary",Vector2.RIGHT,Vector2(650,450));held._notification(NOTIFICATION_APPLICATION_FOCUS_OUT);check(held.charges.is_empty() and combat.projectiles.is_empty(),"focus loss cancels without firing")
 await tidy(g)
 var a=load("res://scenes/arcade.tscn").instantiate();root.add_child(a);current_scene=a;await process_frame;a.set_process(false);a.party_tools.set_process(false);a.mode="arena";a.role="host";a.started=true;a.start_countdown=0;a.my_id="host";a.host_id="host";a.roster.assign([{"id":"host","name":"Host"},{"id":"guest","name":"Friend"}]);a._add_player("host",0);a._add_player("guest",1);a.hero_ids.guest="baseball";a.levels.guest=10;a.positions.guest=Vector2(450,450);a.adventure.combat.setup("grove");a.inventory.guest=[];a.cooldown_at.guest={}
 held=a.adventure.combat.held_cast;combat=a.adventure.combat
 a._packet("guest",{"type":"held_cast","phase":"begin","kind":"primary","angle":0,"target":[650,450]})
 check(held.charges.has("guest"),"guest begin packet accepted")
 held.step(.55)
 a._packet("guest",{"type":"held_cast","phase":"release","kind":"primary","angle":0,"target":[650,450],"power":999})
 check(combat.projectiles.size()==1 and is_equal_approx(float(combat.projectiles[0].damage),31.35),"host measures charge and ignores client power")
 a._packet("guest",{"type":"held_cast","phase":"release","kind":"primary","angle":0,"target":[650,450]});check(combat.projectiles.size()==1,"duplicate release cannot fire again")
 check(a._snapshot().adventure.combat.has("held_cast"),"charge visuals travel in snapshots")
 await tidy(a);print("v117 failures: ",failures);quit(1 if failures else 0)

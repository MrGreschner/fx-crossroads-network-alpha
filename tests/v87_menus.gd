extends SceneTree
var failures:=0
func check(ok:bool,name:String)->void:
 if not ok:failures+=1;print("FAIL: ",name)
func key()->InputEventKey:
 var event:=InputEventKey.new();event.keycode=KEY_ESCAPE;event.pressed=true;return event
func _initialize()->void:call_deferred("run")
func run()->void:
 root.set_meta("fx_intro_seen",true)
 var g=load("res://scenes/main.tscn").instantiate();g.set_script(load("res://tests/v82_input_game.gd"));root.add_child(g);await process_frame;g.set_process(false);g.legacy.set_process(false);g.presentation.asked=true;g.presentation.close();g.profile.tutorial_seen=true;g.session_menu.set_process(false);g.level_cards.set_process(false)
 var hall=g.hero_hall;hall.set_process(false);hall.query=str(hall.library.number(g,"caelum"));hall.refresh();check(hall.shown==["caelum"],"number search uses current roster position")
 var session=g.session_menu
 session.open("main");check(session.page=="main" and g.menu=="session","main blocks game input")
 session.resume();check(g.menu.is_empty(),"resume restores town")
 session._input(key());check(session.page.is_empty(),"single Escape does not quit or open")
 session._input(key());check(session.page=="pause","double Escape opens pause")
 session.resume();g.enter_region("practice");g.menu="";g.hero=g.characters.ram;g.level=2;g.menu="levelup";g.level_cards._process(.01)
 var cards=g.level_cards;check(cards.panel.visible and cards.choices.size()==3,"three large stat choices")
 var old:float=g.bonus_damage;cards.choose(KEY_2);check(g.bonus_damage==old+4 and g.menu.is_empty(),"damage card applies existing +4 once")
 g.menu="levelup";g.level=8;cards._process(.01);cards.choose(KEY_2);check(g.upgrade=="secondary","secondary cooldown card")
 g.menu="levelup";g.level=10;cards._process(.01);cards.choose(KEY_1);check(g.mastery=="special","special cooldown card")
 g.menu="levelup";g.level=3;cards._process(.01);check(cards.choices.size()==1,"ability unlock has one clear Continue");cards.choose(KEY_ENTER);check(g.menu.is_empty(),"unlock continues")
 session.open("main");var before:Dictionary=g.legacy.bundle().duplicate(true);session.profile_action(true);check(session.page=="main" and session.message.text.contains("town"),"upload blocked during run")
 session.request_clear();check(session.page=="main" and g.legacy.bundle().progress==before.progress,"new player blocked during run")
 g.legacy.export_profile();check(g.legacy.notice.text.contains("town"),"all export paths blocked during run")
 session.town();check(g.mode=="town" and g.menu.is_empty(),"pause exit to town recovers movement")
 session.open("clear");check(session.page=="clear","clear requires separate confirmation");session.open("main");session.resume()
 # Owl Eyes: front/back hits, rotation and a capped eight ticks.
 g.enter_region("practice");g.obstacles.clear();g.enemies.clear();g.position_in_world=Vector2(1000,1000);g.character_id="recess";g.selected_character="recess";g.hero=g.characters.recess;g.level=10;g.adventure.combat.setup("practice")
 var c=g.adventure.combat;var r=c.release_heroes
 for point in [Vector2(1120,1000),Vector2(880,1000),Vector2(1000,1120)]:g.adventure.spawn("bramble",point,500,false)
 var a:Dictionary=g.hero.mastery.technique.attack;c.v79.prepare("solo",a,Vector2.RIGHT,Vector2(1250,1000));r.cast("solo",a,Vector2.RIGHT,5);r.holding("solo",false,Vector2.RIGHT)
 for n in 4:r.step(.125)
 check(g.enemies[0].hp==490 and g.enemies[1].hp==490 and g.enemies[2].hp==500,"two opposite beams damage and spare off-axis foe")
 r.holding("solo",false,Vector2.DOWN)
 for n in 12:r.step(.125)
 check(g.enemies[2].hp==470 and r.owl_gazes.is_empty(),"aim rotates beams and expires after2seconds")
 r.cast("solo",a,Vector2.RIGHT,5);var clone=load("res://scripts/release_heroes.gd").new();clone.receive(r.snapshot());check(clone.owl_gazes.has("solo"),"owl gaze replicated");clone.free()
 check(g.characters.tidewright.name=="Tide Keeper" and g.characters.cantor.name=="Spark Keeper","pair renamed without changing IDs")
 g.queue_free();await process_frame
 # Live menu cannot stop the host simulation or steal a profile.
 var m=load("res://scenes/arcade.tscn").instantiate();root.add_child(m);await process_frame;m.set_process(false);m.party_tools.set_process(false);m.legacy.set_process(false);m.presentation.set_process(false);m.level_cards.set_process(false);m.session_menu.set_process(false)
 m._set_mode("coop");m.role="host";m.my_id="host";m.host_id="host";m.roster.assign([{"id":"host","name":"Host"}]);m._add_player("host",0);m._start_match();m.start_countdown=0;m.session_menu.open("pause");var time:float=m.run_time;m._process(.1);check(m.run_time>time and m.started,"live simulation runs behind pause menu")
 m.session_menu.open("main");m.session_menu.profile_action(false);check(m.session_menu.message.text.contains("town"),"live download blocked")
 m.session_menu.resume();check(m.shop_open.is_empty(),"resume clears live menu input lock")
 m.levels.host=8;m.attack_branch.host="";m.level_cards._process(.01);check(m.level_cards.panel.visible,"multiplayer has clickable upgrade choices");m.level_cards.choose(KEY_1);check(m.attack_branch.host=="primary","host choice routes to authority")
 m.queue_free();await process_frame;print("v87 menus and owl failures: ",failures);quit(failures)

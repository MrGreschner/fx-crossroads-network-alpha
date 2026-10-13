extends SceneTree
const P=preload("res://scripts/workshop_project.gd")
const B=preload("res://scripts/studio_balance.gd")
class FakeChannel extends RefCounted:
 var packets:Array=[]
 func get_ready_state()->int:return WebRTCDataChannel.STATE_OPEN
 func put_packet(bytes:PackedByteArray)->int:packets.append(JSON.parse_string(bytes.get_string_from_utf8()));return OK
var failures=0
func check(ok:bool,name:String)->void:
 print("PASS • " if ok else "FAIL • ",name)
 if not ok:failures+=1
func _initialize()->void:call_deferred("run")
func run()->void:
 root.set_meta("fx_intro_seen",true);root.set_meta("fx_tutorial_offered",true)
 var g=load("res://scenes/main.tscn").instantiate();root.add_child(g);current_scene=g
 for n in 3:await process_frame
 g.set_process(false);g.presentation.close();g.session_menu.resume()
 var p=P.fresh();check(not B.hero_checked(p),"default build is experimental")
 p.forced_balance=true;p.hero.max_health=200;p.hero.primary.damage=60;p.hero.primary.range=600;p.hero.primary.cooldown=.3
 B.enforce_hero(p)
 check(P.validate(p).is_empty(),"balanced metadata is portable")
 check(B.hero_checked(p),"health and attack tradeoffs meet budget")
 check(p.hero.speed<230 and p.hero.primary.cooldown>.3,"more health slows movement and more power slows attack")
 var cheated=p.duplicate(true);cheated.hero.primary.damage=60;cheated.hero.primary.cooldown=.3
 check(not B.hero_checked(cheated),"checked flag cannot bypass scalar budgets")
 var code=P.attack("custom");code.program="let damage = 60\nlet cooldown = 0.3\nrepeat 5\n emit projectile\nend";code.damage=0;code.cooldown=20
 check(B.attack_cost(code)>34,"code variable edits are included in budget")
 B.enforce_attack(code);check(B.attack_cost(code)<=34.01 and P.validate_attack(code).is_empty(),"custom code and fields normalize together")
 g.hero_workshop.project=p;g.hero_workshop.open();g.hero_workshop.hub.hide();g.hero_workshop.panel.show();g.hero_workshop.render();g.hero_workshop.close()
 var mine=g.legacy.mine;mine.time_for_test=1000;g.legacy.data.mine=mine.fresh(1000);mine.commission();mine.advance();mine.time_for_test=1120;mine.advance()
 var geo=preload("res://scripts/mine_geology.gd");check(float(geo.state(mine).stored.coal)>0,"coal produces during actual idle time")
 check(float(geo.state(mine).stored.diamond)==0,"deep deposits stay locked")
 mine.collect();check(float(geo.state(mine).wallet.coal)>0,"depot collection includes minerals")
 check(mine.valid(mine.state()),"new mining schema validates")
 check(geo.sell(mine,"coal"),"mineral assay starts a timed order")
 var before=float(mine.state().wallet.gold);mine.time_for_test+=61;mine.advance();check(float(mine.state().wallet.gold)>before,"assay finishes for separate Mine Gold")
 g.legacy.data.education={"studio_seconds":125.0};check(g.legacy.validate(g.legacy.bundle()),"profile preserves minerals and Studio activity")
 mine.open();mine.view.tabs.current_tab=4;mine.view.render();mine.view.close()
 preload("res://scripts/education_access.gd").unlock("teacher")
 g.legacy.answer("teacher");check(g.legacy.teacher_review_password,"teacher code asks for password")
 g.legacy.answer("fx97");check(g.menu=="learning" and not g.legacy.data.teacher,"teacher review opens without Dev powers")
 for child in g.legacy.get_children():
  if child.get_script()==load("res://scripts/learning_page.gd"):child.finish()
 g.presentation.close();var comparison=load("res://scripts/hero_compare.gd").new();comparison.open(g);check(comparison.box.get_child_count()==2,"comparison shows two hero panels");g.presentation.close()
 var a=load("res://scenes/arcade.tscn").instantiate();root.add_child(a);current_scene=a;g.set_process(false)
 for n in 3:await process_frame
 a.set_process(false);a.custom_party.set_process(false);a.allow_custom=true;a.public_room.set_pressed_no_signal(false);a.role="host";a.my_id="solo";a.host_id="solo";a.roster.assign([{"id":"solo","name":"Creator"}]);a.mode="arena";a.start_countdown=0;a.started=true
 a.custom_party.install("solo",p);a.positions={"solo":Vector2(400,400),"rival":Vector2(455,400)};a.hero_ids.rival="ram";a.health={"solo":120,"rival":120};a.levels={"solo":10,"rival":10};a.teams={"solo":0,"rival":1}
 var runtime=load("res://scripts/custom_party_runtime.gd").new();a.custom_party.add_child(runtime);runtime.setup_party(a,"solo",p);a.custom_party.runtimes.solo=runtime;runtime.step(.02);runtime.aim=Vector2.RIGHT;runtime.aim_point=Vector2(455,400);runtime.press("primary");runtime.step(.2)
 check(float(a.health.rival)<120,"custom primary damages actual PvP rival")
 var snap=a.custom_party.snapshot();check(not JSON.stringify(snap).contains('data:image') and snap.size()==1,"custom snapshots exclude asset payloads")
 a.public_room.set_pressed_no_signal(true);check(a.custom_party.allowed(p) and not a.custom_party.allowed(P.fresh()),"public policy validates build, private policy allows experiment")
 a.allow_custom=false;check(not a.custom_party.allowed(p),"custom permission defaults off")
 a.allow_custom=true;a.started=false
 var guest=load("res://scenes/arcade.tscn").instantiate();root.add_child(guest)
 for n in 2:await process_frame
 guest.set_process(false);guest.custom_party.set_process(false);guest.role="guest";guest.my_id="guest";guest.host_id="solo";guest.allow_custom=true
 a.roster.append({"id":"guest","name":"Reader"});guest.roster.assign(a.roster)
 var outbound=FakeChannel.new();var inbound=FakeChannel.new();a.links.guest={"channel":outbound};guest.links.solo={"channel":inbound}
 a.custom_party.enqueue("guest","solo",p)
 for n in 180:
  a.custom_party._process(.051)
  while not outbound.packets.is_empty():guest.custom_party.packet("solo",outbound.packets.pop_front())
  while not inbound.packets.is_empty():a.custom_party.packet("guest",inbound.packets.pop_front())
  if a.custom_party.acknowledgements.has("guest:solo"):break
 check(guest.custom_party.projects.has("solo") and a.custom_party.acknowledgements.get("guest:solo")==P.fingerprint(p),"paced artwork and abilities transfer completes with acknowledgement")
 var bad=p.duplicate(true);bad.hero.primary.damage=60;bad.hero.primary.cooldown=.3
 check(not a.custom_party.allowed(bad),"public host rejects tampered checked build")
 a.links.clear();guest.links.clear();a.started=true
 runtime.minions.append({"party_uid":"test","pos":Vector2(430,400),"hp":30.0})
 a.custom_party.runtimes.solo=runtime
 a.adventure.combat.damage("c|solo|test",10,"rival")
 check(float(runtime.minions.back().hp)<30,"custom summoned minions can take opposing damage")
 # Flush one-shot audio before destroying the test scenes; otherwise the audio
 # mixer can retain hurt.wav until after this headless test quits.
 for scene in [g,a,guest]:
  for voice in scene.journey.voices:voice.stop()
 await create_timer(.08).timeout
 g.queue_free();a.queue_free();guest.queue_free();await process_frame
 print("V139 FAILURES: ",failures);quit(1 if failures else 0)

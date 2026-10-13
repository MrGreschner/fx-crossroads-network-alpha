extends SceneTree
var failures=0
func check(ok:bool,label:String)->void:
 if not ok:failures+=1;push_error(label)
func _initialize()->void:call_deferred("run")
func run()->void:
 root.set_meta("fx_dedicated_server",true);root.set_meta("fx_dev_match",true)
 var g=preload("res://network/arena.gd").new();root.add_child(g);await process_frame
 g.set_physics_process(false);g.set_process(false);g.gateway=null
 g.positions={"a":Vector2(800,900),"b":Vector2(850,900)};g.health={"a":120,"b":120};g.hero_ids={"a":"ram","b":"ram"};g.levels={"a":10,"b":10};g.teams={"a":0,"b":1};g.inventory={"a":[],"b":[]};g.cooldown_at={"a":{},"b":{}};g.started=true;g.start_countdown=0;g.FIELD=Rect2(0,0,2400,1800);g.field_obstacles.clear();g._rebuild_grid()
 g._attack("a","primary",Vector2.RIGHT,Vector2(850,900));check(g.health.b<120,"Original melee damage runs on server")
 var classic=g.adventure.combat.classics
 check(not classic.strikes.is_empty(),"Real Ram headbutt creates identity strike")
 var strike=classic.strikes[0]
 var start=g.positions.a
 for offset in [Vector2(60,0),Vector2(-60,0),Vector2(0,45)]:
  g.positions.a=start+offset
  check(classic.strike_origin(strike)==g.positions.a,"Ram strike follows moving owner on authority")
 g.dedicated=false;g.my_id="a";g.local_pos=Vector2(700,850)
 check(classic.strike_origin(strike)==g.local_pos,"Ram follows predicted local hero")
 g.my_id="b";g.remote_draw_pos.a=Vector2(710,855)
 check(classic.strike_origin(strike)==g.remote_draw_pos.a,"Ram follows interpolated remote hero")
 check(g.adventure.combat.vec(strike.pos)==start,"Visual following does not move authoritative hit origin")
 g.dedicated=true;g.my_id="server";g.positions.a=start
 var after=g.health.b;g._attack("a","primary",Vector2.RIGHT,Vector2(850,900));check(g.health.b==after,"Server rejects cooldown spam")
 g.hero_ids.a="baseball";g.selected_hero="baseball";g.cooldown_at.a={};g.health.b=120;g.positions.b=Vector2(920,900)
 var held=g.adventure.combat.held_cast
 held.packet("a",{"phase":"begin","kind":"primary","angle":0.0,"target":[920,900]})
 check(held.charges.has("a"),"Existing charged ability starts on authority")
 for n in 30:g.adventure.step(1.0/60.0)
 held.packet("a",{"phase":"release","kind":"primary","angle":0.0,"target":[920,900]})
 check(not held.charges.has("a"),"Charged ability releases")
 for n in 30:g.adventure.step(1.0/60.0);g._simulate(1.0/60.0)
 check(g.health.b<120,"Charged projectile deals authoritative damage")
 var rules=preload("res://network/server.gd").new()
 check(rules.valid_frame({"seq":1,"d":[1,0],"a":0,"ph":false,"sh":false}),"Valid movement frame")
 check(not rules.valid_frame({"seq":1,"d":[99,0],"a":0,"ph":false,"sh":false}),"Oversized movement rejected")
 check(not rules.valid_action({"type":"attack","style":"primary","angle":INF,"target":[0,0],"input_seq":0}),"Non-finite attack rejected")
 var view=preload("res://network/projectile_view.gd").new()
 view.receive([{"net_id":1,"pos":[0,0],"velocity":[100,0],"owner":"a"}],0)
 check(absf(view.samples(.05)[0].pos.x-5)<.01,"Projectiles travel between snapshots")
 check(absf(view.samples(10)[0].pos.x-12)<.01,"Late projectile rendering is bounded")
 rules.free();g.started=false;g.queue_free();for n in 4:await process_frame
 print("COMBAT_AND_PROTOCOL "+str(failures)+" failures");quit(failures)

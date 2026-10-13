extends SceneTree
var failures=0
func check(ok:bool,note:String)->void:
 if not ok:failures+=1;push_error(note)
func _initialize()->void:call_deferred("run")
func run()->void:
 root.set_meta("fx_dedicated_server",true);root.set_meta("fx_dev_match",true)
 var g=preload("res://network/arena.gd").new();root.add_child(g);await process_frame
 g.set_process(false);g.set_physics_process(false);g.dedicated=false;g.my_id="a";g.selected_hero="ram";g.hero_ids={"a":"ram","b":"ram"};g.positions={"a":Vector2(800,900),"b":Vector2(850,900)};g.local_pos=g.positions.a;g.health={"a":120,"b":120};g.levels={"a":10,"b":10};g.teams={"a":0,"b":1};g.inventory={"a":[],"b":[]};g.cooldown_at={"a":{},"b":{}};g.started=true;g.start_countdown=0
 g._preview_attack("primary",{"angle":0.0},11)
 check(g.local_strikes.size()==1,"Ram has immediate horn animation before server reply")
 check(g.health.b==120 and g.missiles.is_empty(),"Preview cannot deal damage or simulate real projectiles")
 check(g.suppress_confirmed_strike({"owner":"a","action_seq":11}),"Confirmed Ram animation cannot double-flash")
 check(not g.suppress_confirmed_strike({"owner":"b","action_seq":11}),"Other player's attack remains visible")
 g.selected_hero="sunflower";g.hero_ids.a="sunflower";g._preview_attack("primary",{"angle":0.0},12)
 check(g.shots_view.predicted.size()==1 and g.pending_bursts.size()==3,"First seed appears instantly, remaining seeds paced")
 g.receive_net({"type":"action_ack","seq":12,"accepted":false})
 check(g.shots_view.predicted.is_empty() and g.pending_bursts.is_empty(),"Rejected burst cancels all cosmetic seeds")
 var v=preload("res://network/projectile_view.gd").new();v.local_owner="a";v.latency=.134
 v.preview("a",21,Vector2.ZERO,Vector2(100,0),"#ffffff",0)
 v.receive([{"net_id":1,"owner":"a","action_seq":21,"pos":[2,0],"velocity":[100,0]}],.1)
 check(v.predicted.is_empty(),"Confirmed shot replaces preview")
 check(absf(v.samples(.1)[0].pos.x-10)<.01,"Handoff starts at predicted position without backward jump")
 v.preview("a",22,Vector2.ZERO,Vector2.RIGHT,"#ffffff",0,0)
 v.preview("a",22,Vector2.ZERO,Vector2.RIGHT,"#ffffff",0,1)
 v.receive([{"net_id":2,"owner":"a","action_seq":22,"shot_index":0,"pos":[0,0],"velocity":[1,0],"custom":true}],.1)
 check(v.predicted.size()==1 and v.predicted[0].index==1,"A seed confirmation removes only its matching burst member")
 g.positions.b=Vector2(2000,1500)
 g.dedicated=true;g.set_meta("fx_action_seq",30);g.adventure.combat.cast("a",g.characters.sunflower.primary,Vector2.RIGHT,5);g.remove_meta("fx_action_seq")
 g.adventure.combat.step(.0167)
 var shots=g.adventure.combat.projectiles
 check(not shots.is_empty() and shots[0].action_seq==30 and shots[0].net_id>0,"Server burst carries action and stable projectile identities")
 g.started=false;g.queue_free();await process_frame
 print("LOCAL PREDICTION ",failures," failures");quit(failures)

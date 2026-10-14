extends SceneTree
var failures=0
var checks=0
func check(ok:bool,label:String)->void:
 checks+=1
 print("PASS " if ok else "FAIL ",label)
 if not ok:failures+=1
func _initialize()->void:call_deferred("run")
func run()->void:
 root.set_meta("fx_dedicated_server",true);root.set_meta("fx_dev_match",true)
 var g=preload("res://network/arena.gd").new();root.add_child(g);await process_frame
 g.set_physics_process(false);g.set_process(false);g.gateway=null
 g.positions={"a":Vector2(800,900),"b":Vector2(950,900)};g.health={"a":120,"b":120};g.hero_ids={"a":"ram","b":"ram"};g.levels={"a":10,"b":10};g.teams={"a":0,"b":1};g.inventory={"a":[],"b":[]};g.cooldown_at={"a":{},"b":{}};g.started=true;g.start_countdown=0;g.FIELD=Rect2(0,0,2400,1800);g.field_obstacles.clear();g._rebuild_grid()
 g.authority_tick=100;g.position_samples=[{"tick":94,"points":{"a":Vector2(800,900),"b":Vector2(850,900)},"hp":{"a":120,"b":120}}]
 var saved=g.rewind_melee_targets("a",{"type":"attack","style":"primary","view_tick":94})
 check(g.positions.b==Vector2(850,900),"Ram checks the opponent position visible in buffered world")
 g._attack("a","primary",Vector2.RIGHT,Vector2(850,900));g.restore_targets(saved)
 check(g.health.b<120,"bounded historical melee registers damage")
 check(g.positions.b==Vector2(950,900),"rewind restores present position")
 g.positions.b=Vector2(1000,900)
 check(g.rewind_melee_targets("a",{"type":"attack","style":"primary","view_tick":94}).is_empty(),"teleports and large discontinuities are not rewound")
 g.hero_ids.a="sunflower"
 check(g.rewind_melee_targets("a",{"type":"attack","style":"primary","view_tick":94}).is_empty(),"projectile attacks are never rewound")
 g.positions.b=Vector2(900,940);g.set_meta("fx_network_previous_positions",{"b":Vector2(900,860)})
 check(g.network_projectile_near(Vector2(890,900),Vector2(910,900),"p:b",g.positions.b,12),"relative sweep catches a player crossing a projectile within a tick")
 g.positions.b=Vector2(1000,940)
 check(not g.network_projectile_near(Vector2(890,900),Vector2(910,900),"p:b",g.positions.b,12),"relative sweep does not enlarge hits to distant players")
 g.positions={"a":Vector2(900,940),"b":Vector2(900,940)};g.set_meta("fx_network_previous_positions",{"a":Vector2(900,940),"b":Vector2(900,860)})
 check(g._projectile_near_player(Vector2(890,900),Vector2(910,900),"b",12),"stacked players keep separate swept collision identities")
 var v=preload("res://network/projectile_view.gd").new()
 v.preview("a",1,Vector2.ZERO,Vector2(100,0),"#fff",0)
 v.receive([{"net_id":1,"owner":"a","action_seq":1,"pos":[2,0],"velocity":[100,0]}],.1)
 check(v.samples(.1)[0].pos.x==2,"confirmed projectile follows server collision trajectory")
 check(v.samples(20)[0].pos.x<=14.01,"a stalled confirmed projectile cannot keep travelling through players")
 var rules=preload("res://network/server.gd").new()
 var compact=rules.prune_idle({"idle":{"clock":123,"shots":[]},"active":{"clock":123,"shots":[{"hp":0}]},"alive":false,"hp":0})
 check(not compact.has("idle") and compact.active.shots.size()==1 and compact.hp==0 and not compact.alive,"snapshot compaction preserves active mechanics and zero/false values")
 var room={"game":g,"host":"a","seats":2,"members":{"a":{},"b":{}}}
 rules.rooms={"TEST":room};rules.identities={"a":{"connection":-1,"left":0},"b":{"connection":-1,"left":100000}}
 rules.expire_members("TEST",room,61000)
 check(room.host=="b" and not g.positions.has("a") and room.members.size()==1,"expired host releases actor and hands room ownership to remaining member")
 rules.free();g.started=false;g.queue_free();for n in 4:await process_frame
 print("T4_COLLISION ",checks," checks, ",failures," failures");quit(failures)

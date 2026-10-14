extends SceneTree
var checked=0
func _initialize()->void:call_deferred("run")
func run()->void:
 root.set_meta("fx_dedicated_server",true);root.set_meta("fx_dev_match",true)
 var g=preload("res://network/arena.gd").new();root.add_child(g);await process_frame
 g.set_physics_process(false);g.set_process(false);g.gateway=null
 var rules=preload("res://network/server.gd").new()
 for hero in g.characters:
  if not rules.valid_hero(g,hero):continue
  g.adventure.setup("");g.mode="arena";g.started=true;g.start_countdown=0;g.positions={"a":Vector2(800,900),"b":Vector2(890,900)};g.hero_ids={"a":hero,"b":"ram"};g.health={"a":5000,"b":5000};g.levels={"a":10,"b":10};g.teams={"a":0,"b":1};g.inventory={"a":[],"b":[]};g.cooldown_at={"a":{},"b":{}};g.FIELD=Rect2(0,0,2400,1800);g.field_obstacles.clear();g._rebuild_grid();g.charges.clear();g.missiles.clear();g.selected_hero=hero
  for kind in ["primary","secondary","special"]:
   g._attack("a",kind,Vector2.RIGHT,Vector2(890,900))
   for n in 4:g.adventure.step(1.0/60.0);g._simulate(1.0/60.0)
   checked+=1
  var original=g.adventure.snapshot();var compact=rules.prune_idle(original)
  var encoded=JSON.parse_string(JSON.stringify(compact))
  g.adventure.receive(encoded)
  if not encoded is Dictionary:push_error("Hero snapshot invalid: "+str(hero));quit(1);return
 g.started=false;rules.free();g.queue_free();for n in 4:await process_frame
 print("T4 HERO SMOKE ",checked," ability calls and compact snapshot round trips");quit()

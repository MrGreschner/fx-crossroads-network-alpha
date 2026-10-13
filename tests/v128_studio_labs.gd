extends SceneTree
const Behavior=preload("res://scripts/studio_behavior.gd")
const Enemy=preload("res://scripts/studio_enemy_project.gd")
const Project=preload("res://scripts/workshop_project.gd")
var failures=0
func check(ok:bool,message:String)->void:
 print("PASS: " if ok else "FAIL: ",message)
 if not ok:failures+=1
func _initialize()->void:call_deferred("run")
func run()->void:
 var brain=Behavior.compile(Behavior.template("enemy"),"enemy")
 check(brain.error.is_empty(),"enemy example compiles")
 for pair in [[60,"retreat"],[150,"orbit"],[500,"chase"]]:
  var actions=Behavior.evaluate(brain,{"distance":pair[0],"health":100,"time":0})
  check(actions.any(func(a):return a.command=="move" and a.value==pair[1]),"distance decisions: "+pair[1])
 check(not Behavior.compile("while true\nmove chase\nend","enemy").error.is_empty(),"unbounded code rejected")
 check(not Behavior.compile("use delete_files","enemy").error.is_empty(),"unknown actions rejected")
 var a=Project.attack("projectile");preload("res://scripts/studio_options.gd").complete(a)
 for effect in preload("res://scripts/studio_charge.gd").EFFECTS:
  a.charge_effect=effect;a.max_charge_status="stun";var full=a.duplicate(true);preload("res://scripts/studio_charge.gd").apply(full,1)
  check(full.status=="stun","full charge effect: "+effect)
  var partial=a.duplicate(true);preload("res://scripts/studio_charge.gd").apply(partial,.3)
  check(partial.status!="stun","partial charge no stun: "+effect)
 var logic=preload("res://scripts/studio_script.gd").compile("let count = 3\nfor index in count\n emit projectile\nend\nif charged\n emit pulse\nelif targets\n emit heal\nelse\n emit protect\nend")
 check(logic.error.is_empty(),"ability for / elif / else compile")
 var actions=preload("res://scripts/studio_script.gd").actions(logic.instructions,false,true)
 check(actions.size()==4 and actions.back().command=="heal","ability branch uses target condition")
 var loops=Behavior.compile("for step in 3\n move hold\nend","enemy")
 check(loops.error.is_empty() and Behavior.evaluate(loops,{}).size()==3,"bounded behaviour loop executes")
 check("func spawn_shot" in preload("res://scripts/studio_code_levels.gd").ability(2,"") and "delta" in preload("res://scripts/studio_code_levels.gd").ability(2,""),"Level 2 includes actual projectile physics")
 check("var agents:Array" in preload("res://scripts/studio_code_levels.gd").behavior(3,""),"Level 3 includes class object references")
 var enemy=Enemy.fresh();check(Enemy.validate(enemy).is_empty(),"portable enemy valid")
 var lib=preload("res://scripts/studio_library.gd");check(lib.add_enemy(enemy).is_empty(),"enemy saved")
 check(lib.add_behavior(Behavior.fresh()).is_empty(),"behaviour saved")
 var zip="user://labs.zip";check(preload("res://scripts/studio_bundle.gd").make({"format":"fx-crossroads-profile","version":1},zip)==OK,"portable bundle built")
 var read=preload("res://scripts/studio_bundle.gd").read(zip);check(read.error.is_empty() and read.payload.studio.enemies.size()==1 and read.payload.studio.behaviors.size()==1,"enemy and behaviour round trip")
 var battle=preload("res://scripts/studio_battle.gd").new();root.add_child(battle);battle.setup(enemy,Project.fresh(),1);battle.set_process(false);battle.player=Vector2(400,140)
 for n in 180:battle.tick(.016)
 check(battle.incoming>0,"enemy real projectile damages player")
 battle.player=battle.agents[0].body.pos+Vector2(40,0);var before=battle.agents[0].body.pos;battle.tick(.1);check(battle.agents[0].body.pos.distance_to(battle.player)>before.distance_to(battle.player),"enemy retreats at close range")
 var lethal=Project.attack();lethal.damage=500;battle.hurt(0,lethal);battle.tick(.1);check("Victory" in battle.result,"enemy can be defeated")
 battle.queue_free();await process_frame
 root.set_meta("fx_intro_seen",true);root.set_meta("fx_tutorial_offered",true)
 var g=load("res://scenes/main.tscn").instantiate();root.add_child(g);await process_frame;g.set_process(false);g.presentation.close();g.session_menu.resume()
 var w=g.hero_workshop;w.set_meta("studio_intro",true);w.open();w.open_enemy();await process_frame;await process_frame
 check(w.get_children().any(func(c):return c.get_script()==preload("res://scripts/studio_enemy_lab.gd")),"Enemy Lab UI opens")
 w.open_behavior();await process_frame;await process_frame;w.open_lab();await process_frame;await process_frame
 check(is_instance_valid(w.lab.advanced_source),"advanced code viewer opens")
 g.queue_free();await process_frame;await process_frame;print("V128 failures: ",failures);quit(1 if failures else 0)

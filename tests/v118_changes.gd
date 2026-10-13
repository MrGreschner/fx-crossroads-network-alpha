extends SceneTree
var failures:=0
var g:Node
func check(ok:bool,title:String)->void:
 if not ok:failures+=1;print("FAIL: ",title)
func _initialize()->void:call_deferred("run")
func begin_tutorial()->void:
 g.presentation.close();g.tutorial.start("ram");g.presentation.close();g.menu="";g.health=1;g.invulnerable_time=0;g.inventory.clear();g.obstacles.clear();g.position_in_world=Vector2(850,600)
func foe(uid:int,boss:bool=false)->Dictionary:
 return {"uid":uid,"pos":g.position_in_world+Vector2(12,0),"hp":200.0,"max_hp":200.0,"attack_timer":0.0,"secondary_timer":4.0,"windup":0.0,"boss":boss,"type":"boss" if boss else "bramble","tutorial":true}
func assert_town(title:String)->void:
 check(g.mode=="town" and not g.tutorial.active and g.enemies.is_empty() and g.health>0,title)
 for n in 3:g._process(.017)
 check(g.enemies.is_empty(),title+" does not repopulate town enemies")
func run()->void:
 root.set_meta("fx_intro_seen",true);root.set_meta("fx_tutorial_offered",true)
 g=load("res://scenes/main.tscn").instantiate();root.add_child(g);current_scene=g;await process_frame;g.set_process(false)
 begin_tutorial();g.enemies.append(foe(900011));g.enemies.append(foe(900012));g.handle_run(.017);assert_town("tutorial melee defeat transitions safely during active loop")
 begin_tutorial();g.enemy_shots.append({"pos":g.position_in_world,"direction":Vector2.RIGHT,"damage":1000.0,"speed":1.0,"distance":0.0});g.enemy_shots.append({"pos":g.position_in_world,"direction":Vector2.RIGHT,"damage":1000.0,"speed":1.0,"distance":0.0});g.handle_run(.017);assert_town("tutorial projectile defeat does not remove from cleared shot list")
 begin_tutorial();var boss:=foe(900041,true);boss.windup=.001;g.enemies.append(boss);g.region.boss_secondary="stomp";g.handle_run(.017);assert_town("tutorial mini-boss stomp defeat stops frame")
 begin_tutorial();g.tutorial.finish(false,true);assert_town("tutorial skip remains safe")
 g.presentation.close();g.start_run(false,"grove");g.presentation.close();g.menu="";g.inventory.clear();g.health=1;g.invulnerable_time=0;g.obstacles.clear();g.enemies.clear();g.enemies.append(foe(901001));g.enemies.append(foe(901002));g.handle_run(.017)
 check(g.menu=="presentation" and g.presentation.page=="results" and g.health<=0,"normal realm defeat opens new results screen")
 var prior:float=g.damage_taken;g.handle_run(.017);g.update_enemies(.017);g.update_enemy_shots(.017)
 check(is_equal_approx(prior,g.damage_taken),"results modal cannot continue combat or take extra hits")
 g.presentation.close();g.enter_region("town");g.start_run(false,"grove");g.presentation.close();g.menu=""
 check(g.mode=="run" and g.health>0,"fresh run starts after defeat")
 for p in g.find_children("*","AudioStreamPlayer",true,false):p.stop();p.stream=null
 g.queue_free();await process_frame;await process_frame;await create_timer(.2).timeout
 print("v118 failures: ",failures);quit(failures)

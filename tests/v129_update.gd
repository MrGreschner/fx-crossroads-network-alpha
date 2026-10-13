extends SceneTree
const Behavior=preload("res://scripts/studio_behavior.gd")
const Enemy=preload("res://scripts/studio_enemy_project.gd")
var failures=0
func check(ok:bool,message:String)->void:
 print("PASS: " if ok else "FAIL: ",message)
 if not ok:failures+=1
func _initialize()->void:call_deferred("run")
func run()->void:
 var enemy=Enemy.fresh();enemy.attack_count=3
 check(Enemy.validate(enemy).is_empty(),"enemy supports three portable attack slots")
 for title in Behavior.presets():check(Behavior.compile(Behavior.presets()[title],"enemy").error.is_empty(),"behaviour preset compiles: "+title)
 enemy.behavior.program="move hold\nuse primary\nuse secondary\nuse special"
 var agent=preload("res://scripts/studio_enemy_agent.gd").new();agent.setup(enemy,{"hp":enemy.health,"pos":Vector2.ZERO,"stun":0});check(agent.update(.1,Vector2(10,0)).size()==3,"enemy executes three distinct attack slots")
 enemy.attack_count=1;agent.setup(enemy,{"hp":enemy.health,"pos":Vector2.ZERO,"stun":0});agent.cooldowns={"primary":0.0,"secondary":0.0,"special":0.0};check(agent.update(.1,Vector2(10,0)).size()==1,"one attack enemy cannot use hidden slots")
 root.set_meta("fx_intro_seen",true);root.set_meta("fx_tutorial_offered",true)
 var g=load("res://scenes/main.tscn").instantiate();root.add_child(g);current_scene=g;await process_frame;g.set_process(false);g.presentation.close();g.session_menu.resume()
 for pair in [["book","Melee / Ranged"],["soccer","Ranged / Support"],["basketball","Melee / Summoner"]]:check(g.presentation.starter_role(pair[0])==pair[1],"starter dual role "+pair[0])
 g.tutorial.start("ram");g.level=3;g.presentation.skill_unlock("secondary")
 check(g.menu=="presentation" and g.presentation.page=="unlock_celebration","unlock celebration pauses tutorial before lesson")
 g.presentation._process(.9);check(g.presentation.page=="unlock_celebration","celebration lasts long enough to notice")
 g.presentation._process(.2);check(g.presentation.page=="skill_unlock" and g.presentation.unlock_buttons.all(func(b):return b.disabled),"lesson opens with accidental click protection")
 g.presentation._process(.7);check(g.presentation.unlock_buttons.all(func(b):return not b.disabled),"lesson buttons enable after reading delay")
 g.presentation.close();g.tutorial.wave=0;g.enemies.clear();g.tutorial.spawn_wave()
 g.position_in_world=g.enemies[0].pos+Vector2(30,0);g.enemies[0].attack_timer=0;g.invulnerable_time=0;var hp_before=g.health;g.update_enemies(.01)
 check(g.health<hp_before and float(g.enemies[0].strike_flash)>0,"Bramble hit activates visible attack pose and swipe")
 g.health=1;g.enemies[0].attack_timer=0;g.update_enemies(.01)
 check(not g.last_defeat.is_empty() and "Bramble" in str(g.last_defeat.get("name","")),"actual tutorial fatal hit retains enemy identity")
 check(g.presentation.page=="tutorial_end","tutorial defeat has separate results")
 var labels=g.presentation.content.find_children("*","Button",true,false)
 check(labels.any(func(b):return b.text.begins_with("Retry tutorial")),"tutorial defeat offers highlighted same-hero retry")
 g.presentation.close();g.legacy.data.teacher=true
 var guide=g.town_services.field_guide;guide.game=g;check(guide.known_entries().size()>50,"Game Dev opens full enemy catalogue")
 g.mistglass_rift.open();var r=g.mistglass_rift;check(r.entries.size()>50,"Rift lists encountered and Game Dev enemies")
 r.choose(r.entries[0],4);r.choose(r.entries[1],3);r.choose(r.entries[2],3);r.choose(r.entries[3],1)
 check(r.selected.size()==3,"Rift enforces three enemy kinds")
 r.choose(r.entries[0],5);check(r.selected[r.entry_key(r.entries[0])].count==4,"Rift enforces ten enemies total")
 g.legacy.data.teacher=false;var damage_before=float(g.legacy.record("ram").damage);var discovered=JSON.stringify(g.legacy.data.encounters)
 r.begin();check(r.active and g.enemies.size()==10 and g.level==10,"Rift launches ten chosen enemies with current level-10 hero")
 check(g.menu=="rift_countdown","Rift provides ready countdown")
 r._process(3.1);check(g.menu.is_empty(),"Rift countdown releases controls")
 var before=g.dealt_damage;r.damage(0,20);check(g.dealt_damage>before,"Rift hit records practice damage")
 var hp=g.health;g.position_in_world=g.enemies[0].pos+Vector2(15,0);g.enemies[0].attack_timer=0;r.step(.1);check(g.health<hp or not g.enemy_shots.is_empty(),"Rift enemies fight back")
 g.catalog_ui.record_encounters();check(JSON.stringify(g.legacy.data.encounters)==discovered,"Rift does not save fake discoveries")
 r.finish(true);check(float(g.legacy.record("ram").damage)==damage_before,"Rift damage does not award mastery")
 check(not r.active and g.mode=="town" and g.presentation.page=="rift_result","Rift finishes into practice result and town")
 g.presentation.close();g.load_town_layout();g.position_in_world=g.studio_town.ENTRY;check(g.can_stand_at(g.position_in_world),"relocated Studio doorway is walkable")
 var w=g.hero_workshop;w.set_meta("studio_intro",true);w.open();w.open_enemy();await process_frame;await process_frame
 var lab:Node
 for c in w.get_children():
  if c.get_script()==preload("res://scripts/studio_enemy_lab.gd"):lab=c
 check(lab!=null,"Enemy Lab opens")
 lab.enemy.attack_count=3;lab.render();await process_frame;await process_frame
 check(lab.previews.size()==3,"Enemy Lab has three visual attack previews")
 var arts=lab.body.find_children("*","Label",true,false);var titles=[]
 for label in arts:titles.append(label.text)
 check(titles.find("FOUR POSES")<titles.find("DECISIONS"),"art poses are before decision options")
 g.queue_free();await process_frame;await process_frame
 for mode in ["arena","descent","battlegrounds"]:
  root.set_meta("fx_mode",mode);var a=load("res://scenes/arcade.tscn").instantiate();root.add_child(a);current_scene=a;await process_frame;a.set_process(false);a.presentation.close();a.session_menu.resume()
  a._set_mode(mode);a.role="host";a.my_id="host";a.host_id="host";a.spectator_host=true;a.roster.assign([{"id":"host","name":"Host"},{"id":"p1","name":"One"},{"id":"p2","name":"Two"}]);a._add_player("host",0);a._add_player("p1",0);a._add_player("p2",1)
  check(a.spectating() and not a.positions.has("host") and a.fighters().size()==2,"separate spectator seat in "+mode)
  a.teams["p1"]=0;a.teams["p2"]=1;a._start_match();a.start_countdown=0;if mode=="descent":
   var before_floor=int(a.legacy.card.state().descent_best);a.descent.cleared(30);check(int(a.legacy.card.state().descent_best)==before_floor,"spectator cannot earn Descent badge")
  check(a.match_party_size==2 and not a.health.has("host"),"spectator excluded from combat scaling in "+mode)
  a.spectator_director.view_mode=1;a.spectator_director.record_damage(Vector2(400,300),100);a.spectator_director._process(1);check(a.spectator_director.focus.distance_to(Vector2(400,300))<200,"action camera follows damage in "+mode)
  a.spectator_director.view_mode=2;a.spectator_director._process(6.1);check(a.spectator_director.picker.item_count==3,"overview plus two director choices in "+mode)
  a.queue_free();await process_frame;await process_frame
 print("V129 failures: ",failures);quit(1 if failures else 0)

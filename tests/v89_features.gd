extends SceneTree
var failures:=0
func check(ok:bool,name:String)->void:
 if not ok:failures+=1;print("FAIL: ",name)
func _initialize()->void:call_deferred("run")
func run()->void:
 root.set_meta("fx_intro_seen",true)
 var g=load("res://scenes/main.tscn").instantiate();root.add_child(g);await process_frame;g.set_process(false);g.legacy.set_process(false);g.presentation.asked=true;g.presentation.close();g.session_menu.resume();g.hero_hall.set_process(false);g.town_services.set_process(false)
 check(g.characters.size()>=67,"67 available heroes")
 for id in g.manifest.characters:
  var h:Dictionary=g.characters[id];var tech:Dictionary=h.mastery.technique
  if tech.has("attack"):
   var equipped:Dictionary=g.legacy.authored_stats(id,str(tech.ability),h[str(tech.ability)],{"technique":true,"tuning":[0,0,0]})
   check(equipped.style==tech.attack.style,"equipped first mastery attack "+id)
 var monk_heavy:Dictionary=g.legacy.authored_stats("tempo","primary",g.characters.tempo.primary,{"technique":true,"tuning":[2,0,0]})
 g.character_id="tempo";g.selected_character="tempo";var adjusted:Dictionary=g.adventure.combat.stance_heroes.effective("solo","primary",monk_heavy)
 check(is_equal_approx(float(adjusted.damage),32.4) and is_equal_approx(float(adjusted.cooldown),1.188),"monk form keeps mastery tuning")
 g.character_id="ram";g.selected_character="ram";g.adventure.combat.stance_heroes.reset()

 check(g.manifest.characters.find("harbor")>=9 and g.manifest.characters.find("harbor")<40 and g.manifest.characters.find("apiary")>=9 and g.manifest.characters.find("apiary")<60,"reordered supports not in first nine")
 g.hero_hall.query="62";g.hero_hall.refresh();check(g.hero_hall.shown==["harbor"],"stable published number after reordering")
 g.hero_hall.query="";g.selected_character="tempo";g.hero_hall.render_details();var cards:GridContainer
 for child in g.hero_hall.details.get_children():
  if child is GridContainer:cards=child
 check(cards!=null and cards.get_child_count()==4,"four normal ability cards")
 var pr=g.provisions;check(pr.garden.size()==16,"16 crops");check(pr.defs.keys().filter(func(id):return bool(pr.defs[id].get("shop",true))).size()==12,"8 extra foods for sale")
 pr.packed="";pr.crop="empty";pr.harvests={};g.gold=100
 check(not pr.plant("orchard1") and pr.crop=="empty","locked crop cannot plant")
 check(pr.plant("orchard0") and g.gold==94,"seed purchase cost")
 check(not pr.harvest(),"cannot harvest before clear");pr.complete_adventure();check(pr.harvest() and pr.packed=="sunapple" and pr.unlocked("orchard1"),"harvest rewards and next unlock")
 check(not pr.plant("orchard2"),"third tier remains locked")
 check(pr.ship() and pr.parcels==1 and pr.packed.is_empty(),"parcel consumes packed food")
 var reload=load("res://scripts/provisions.gd").new();reload.setup(g);check(reload.harvests.orchard==1 and reload.parcels==1,"garden and shipping persist")
 g.menu="postoffice";g.town_services._process(.1);check(g.town_services.panel.visible,"native post office opens");g.town_services.close()
 g.enter_region("practice");g.obstacles.clear();g.enemies.clear();g.character_id="tempo";g.selected_character="tempo";g.hero=g.characters.tempo;g.level=10;g.position_in_world=Vector2(1000,1000);g.menu="";g.adventure.combat.setup("practice")
 var c=g.adventure.combat;var monk=c.stance_heroes;var a:Dictionary=c.effective_stats("solo","primary",g.hero.primary);check(a.style=="monk_punch","starts melee")
 monk.step(12);a=c.effective_stats("solo","primary",g.hero.primary);check(a.style=="monk_dagger" and a.damage==16,"switches at12s")
 monk.step(12);check(monk.state("solo").form=="melee","alternates back")
 monk.cast("solo",g.hero.special,Vector2.RIGHT,0);check(c.effective_stats("solo","primary",g.hero.primary).style=="monk_jab","poison primary");check(c.effective_stats("solo","secondary",g.hero.secondary).style=="monk_darts","poison secondary")
 var heavy:Dictionary=monk.effective("solo","primary",g.hero.mastery.technique.attack);check(heavy.damage==25 and is_equal_approx(float(heavy.cooldown),.81),"balanced heavy technique in poison stance")
 monk.step(12);check(monk.state("solo").form=="melee","override expires to normal")
 monk.cast("solo",g.hero.mastery.final_technique.attack,Vector2.RIGHT,0);check(c.effective_stats("solo","primary",g.hero.primary).style=="monk_dash","shadow primary")
 monk.cast("solo",c.effective_stats("solo","secondary",g.hero.secondary),Vector2.RIGHT,0);g.health=50;g.invulnerable_time=0;g.take_player_damage(10);check(g.health==50 and c.display_reduction("solo")==1,"shadow veil immunity displayed")
 for n in 15:monk.step(.1)
 check(g.health==56 and not monk.immune("solo"),"veil heals6 across1.5s and expires")
 c.statuses.clear();monk.reset();g.character_id="quill";g.hero=g.characters.quill
 for n in 5:monk.cast("solo",g.hero.mastery.technique.attack,Vector2.RIGHT,0)
 check(monk.pack("solo").size()==3,"quill summon cap3")
 c.v79.prepare("solo",g.hero.mastery.final_technique.attack,Vector2.RIGHT,Vector2(1200,1000));monk.cast("solo",g.hero.mastery.final_technique.attack,Vector2.RIGHT,0);check(monk.pack("solo").size()==3,"pack rally does not duplicate")
 for id in monk.pack("solo"):check(c.morrow.units[id].rally_time==4,"pack rally target")
 c.apply_status("p:solo","guard",1,"solo",.2);g.inventory.clear();g.block_time=0;check(is_equal_approx(c.display_reduction("solo"),.2),"temporary DR value")
 c.statuses.clear();g.character_id="lumen";g.hero=g.characters.lumen;c.party_heroes.reset();c.party_heroes.kindred("solo",Vector2(1000,1000),Vector2.RIGHT,16,7,35);c.party_heroes.step(.1)
 check(c.party_heroes.shots.size()==1 and c.party_heroes.shots[0].ground,"missed dart becomes ground pickup")
 c.party_heroes.step(1.6);check(c.party_heroes.shots.is_empty(),"ground dart expires")
 # Moved-in enemies can consume a landed dart once.
 c.party_heroes.kindred("solo",Vector2(1000,1000),Vector2.RIGHT,16,7,35);c.party_heroes.step(.1);g.adventure.spawn("bramble",Vector2(1055,1000),100,false);c.party_heroes.step(.1)
 check(c.party_heroes.shots.is_empty() and g.enemies[0].hp==84,"ground dart still damages once")
 g.queue_free();await process_frame
 var m=load("res://scenes/arcade.tscn").instantiate();root.add_child(m);await process_frame;m.set_process(false);m.party_tools.set_process(false);m.presentation.set_process(false);m.legacy.set_process(false);m._set_mode("arena");m.bot_count=3;m.arena_seats=4;m._solo()
 check(m.started and m.bot_count==3 and m.positions.size()==4,"solo arena with3bots")
 check(m.start_countdown==5,"visible five-second start")
 m.start_countdown=0;m.field_obstacles.clear();m.obstacle_grid.clear();m.hero_ids[m.my_id]="tempo";m.levels[m.my_id]=10;m.cooldown_at[m.my_id]={};m._attack(m.my_id,"special",Vector2.RIGHT,Vector2.ZERO)
 check(m.adventure.combat.stance_heroes.state(m.my_id).form=="poison","multiplayer dispatcher casts monk form")
 var packet:Dictionary=m.adventure.combat.snapshot();var clone=load("res://scripts/stance_heroes.gd").new();clone.receive(packet.stance_heroes);check(clone.states[m.my_id].form=="poison","stance snapshot");clone.free()
 m.queue_free();await process_frame;print("v89 feature failures: ",failures);quit(failures)

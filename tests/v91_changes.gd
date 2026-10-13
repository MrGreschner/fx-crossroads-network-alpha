extends SceneTree
var failures:=0
func check(ok:bool,label:String)->void:
 if not ok:failures+=1;print("FAIL: ",label)
func _initialize()->void:call_deferred("run")
func run()->void:
 root.set_meta("fx_intro_seen",true)
 var g=load("res://scenes/main.tscn").instantiate();root.add_child(g);await process_frame;g.set_process(false);g.legacy.set_process(false);g.presentation.asked=true;g.presentation.close();g.session_menu.resume();g.enter_region("practice");g.menu="";g.level=10;g.obstacles.clear();g.scenery_tiles.clear();g.enemies.clear();g.position_in_world=Vector2(1000,1000)
 var c=g.adventure.combat;var kit=c.v90
 g.character_id="merrymask";g.hero=g.characters.merrymask;g.adventure.spawn("bramble",Vector2(1085,1000),500,false);g.adventure.spawn("bramble",Vector2(1010,1000),500,false)
 kit.cast("solo",g.hero.primary,Vector2.RIGHT,24);kit.step(.1);check(g.enemies[0].hp==500,"scissors windup visible before hit");kit.step(.09);check(g.enemies[0].hp==476 and g.enemies[1].hp==500,"scissors crossing hits aimed spot rather than broad close cone")
 c.setup("practice");g.character_id="dustmarshal";g.hero=g.characters.dustmarshal;g.enemies.clear();g.adventure.spawn("bramble",Vector2(1130,1000),500,false);g.adventure.spawn("bramble",Vector2(1240,1000),500,false)
 kit.cast("solo",g.hero.primary,Vector2.RIGHT,22);check(c.projectiles.size()==1 and g.enemies[0].hp==500,"pistol has travel before damage")
 for n in 20:c.step_projectiles(.02)
 check(g.enemies[0].hp==478 and g.enemies[1].hp==500 and c.projectiles.is_empty(),"pistol stops at first enemy")
 c.setup("practice");g.character_id="cindervane";g.hero=g.characters.cindervane;g.practice=false;g.mode="run";g.health=10;g.inventory.clear();g.invulnerable_time=0;g.take_player_damage(100)
 check(kit.pending_rebirth("solo") and g.health==0 and g.menu!="results","solo lethal hit reserves delayed rebirth")
 var before:Vector2=g.position_in_world;g._process(1);check(g.health==0 and g.position_in_world==before,"ash form cannot move or revive early");g._process(2.05)
 check(not kit.pending_rebirth("solo") and is_equal_approx(g.health,g.max_health()*.5),"solo revives after three seconds at half maximum")
 var cooldown:float=kit.rebirth_ready.solo;kit.reset();check(kit.rebirth_ready.solo==cooldown,"floor/region combat reset preserves rebirth cooldown")
 g.invulnerable_time=0;g.health=1;g.take_player_damage(100);check(g.presentation.page=="results" and not kit.pending_rebirth("solo"),"second defeat on cooldown follows ordinary defeat")
 g.presentation.close();g.enter_region("practice");g.practice=false;g.mode="run";g.character_id="cindervane";g.hero=g.characters.cindervane;g.level=10;g.menu="";g.inventory.clear();g.health=1;g.invulnerable_time=0;c.v90.rebirth_ready.solo=c.v90.clock+120;c.v90.clock+=120;g.take_player_damage(100);check(c.v90.pending_rebirth("solo"),"rebirth available again at two-minute cooldown")
 g.enter_region("town");g.selected_character="dustmarshal";g.hero_hall.render_details()
 var cards:GridContainer
 for child in g.hero_hall.details.get_children():
  if child is GridContainer:cards=child
 check(cards!=null and cards.columns==1 and cards.get_child_count()==4,"four vertically stacked hall cards")
 var titles:Array=[]
 for card in cards.get_children():titles.append(card.get_child(0).get_child(0).text)
 check(titles[0].begins_with("PRIMARY") and titles[1].begins_with("SECONDARY") and titles[2].begins_with("PASSIVE") and titles[3].begins_with("SPECIAL"),"hall ability order and controls")
 check(g.characters.dunecook.name=="Crumb Cook","dessert chef name")
 g.queue_free();await process_frame
 var a=load("res://scenes/arcade.tscn").instantiate();root.add_child(a);await process_frame;a.set_process(false);a.party_tools.set_process(false);a.legacy.set_process(false);a.presentation.set_process(false)
 for mode in ["arena","defense","descent","coop"]:
  a._set_mode(mode);a._solo();a.start_countdown=0;a.opponents.clear();a.hero_ids[a.my_id]="cindervane";a.selected_hero="cindervane";a.levels[a.my_id]=10;a.health[a.my_id]=10;a.inventory[a.my_id]=[];a.invincible_until[a.my_id]=0;a.adventure.combat.v90.reset();a.adventure.combat.v90.rebirth_ready.clear();a._hurt(a.my_id,1000,"enemy")
  check(a.started and a.adventure.combat.v90.pending_rebirth(a.my_id) and a.health[a.my_id]==0 and not a.downed.has(a.my_id),"host delays ordinary defeat/respawn in "+mode)
  var snap:Dictionary=JSON.parse_string(JSON.stringify(a.adventure.combat.snapshot()));check(snap.v90.rebirth.has(a.my_id),"pending rebirth in guest snapshot "+mode)
  a.adventure.combat.v90.step(3.05);check(a.health[a.my_id]==roundi(a._max_hp(a.my_id)*.5) and not a.adventure.combat.v90.pending_rebirth(a.my_id),"host half-health revive "+mode)
 a.queue_free();await process_frame;print("v91 changes failures: ",failures);quit(failures)

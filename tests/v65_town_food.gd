extends SceneTree
var failures:=0
func check(ok:bool,label:String)->void:
 if not ok:failures+=1;print("FAIL: ",label)
func key(game:Node,code:int)->void:
 var event:=InputEventKey.new();event.pressed=true;event.keycode=code;game._unhandled_input(event)
func _initialize()->void:call_deferred("run")
func run()->void:
 root.set_meta("fx_intro_seen",true)
 var game=load("res://scenes/main.tscn").instantiate();root.add_child(game);await process_frame;game.set_process(false);game.presentation.asked=true;game.presentation.close();game.session_menu.resume();game.profile.tutorial_seen=true
 var food=game.provisions;food.packed="";food.crop="empty";food.save();game.loadout.assign(["potion","shield","hammer"])
 check(food.buy("berry_bun") and game.loadout.size()==3 and game.gold==85,"food purchases use a separate fourth slot")
 check(not food.buy("hearty_stew") and game.gold==85 and food.packed=="berry_bun","full food slot rejects replacement without spending gold")
 food.refund();check(game.gold==100 and food.packed.is_empty(),"unused food can be refunded")
 game.menu="food";game.list_preview.food=2;game.confirm_list_entry();check(food.packed=="antidote_pear" and game.loadout.size()==3,"real food shop confirmation buys selected piece")
 food.refund();game.menu="";game.selected_character="ram";game.start_run(false,"grove");game.enemies.clear();game.inventory.clear();game.level=1;game.position_in_world=Vector2(1000,800);game.obstacles.clear();game.scenery_tiles.clear()
 for id in game.manifest.characters:
  game.hero=game.characters[id];game.menu="";game.adventure.combat.setup("grove");game.health=game.max_health();game.invulnerable_time=0
  food.packed="berry_bun";var maximum:float=game.max_health();var amount:float=maximum*.41
  game.take_player_damage(amount)
  check(is_equal_approx(game.health,minf(maximum,maximum-amount+30)) and food.packed.is_empty(),"automatic heal for "+str(id))
 game.hero=game.characters.ram;game.health=120;food.packed="berry_bun";game.invulnerable_time=0;game.take_player_damage(5)
 check(game.health==115 and food.packed=="berry_bun","small hit above threshold preserves food")
 game.health=40;game.adventure.combat.apply_status("p:solo","slow",3,"enemy",.5)
 check(food.packed=="berry_bun" and game.health==40,"status application alone does not eat healing food")
 game.health=120;food.packed="antidote_pear";game.adventure.combat.apply_status("p:solo","poison",5,"enemy",2)
 check(food.packed.is_empty() and game.adventure.combat.effect_time("p:solo","poison")==0,"poison application immediately eats and cleanses pear")
 game.health=120;food.packed="antidote_pear";game.adventure.combat.apply_status("p:solo","burn",3,"enemy",3)
 check(food.packed=="antidote_pear" and game.adventure.combat.effect_time("p:solo","burn")>0,"pear ignores unrelated burn")
 food.packed="cleansing_tea";game.adventure.combat.apply_status("p:solo","bleed",3,"enemy",2)
 check(food.packed.is_empty() and game.adventure.combat.effect_time("p:solo","burn")==0 and game.adventure.combat.effect_time("p:solo","bleed")==0,"tea cleanses all matching harmful effects")
 game.menu="";game.health=20;food.packed="hearty_stew";game.invulnerable_time=0;game.take_player_damage(30)
 check(game.presentation.page=="results" and food.packed=="hearty_stew","food cannot rescue lethal damage")
 game.selected_character="cat";game.presentation.return_to_town()
 check(game.mode=="town" and game.position_in_world==game.town_upgrade.CLINIC_SPAWN and game.selected_character=="cat" and game.health==game.characters.cat.max_health,"defeat returns chosen hero to healer at full health")
 var clinic:Vector2=game.position_in_world
 check(game.can_stand_at(clinic) and game.can_stand_at(game.town_upgrade.POINTS.healer),"healer respawn and NPC approach are walkable")
 game.start_run(false,"practice");game.health=40;food.packed="berry_bun";game.invulnerable_time=0;game.take_player_damage(5)
 check(food.packed=="berry_bun","training does not spend automatic food")
 game.enter_region("town");game.gold=100;food.packed="";food.crop="empty";food.garden_action()
 check(food.crop=="growing" and game.gold==92,"seedhouse plants one crop for eight gold")
 food.garden_action();check(game.gold==92,"growing crop cannot be purchased again")
 food.complete_adventure();food.garden_action();check(food.packed=="antidote_pear" and food.crop=="empty","cleared adventure ripens one harvest")
 var reloaded=load("res://scripts/provisions.gd").new();reloaded.setup(game)
 check(reloaded.packed=="antidote_pear" and reloaded.crop=="empty","food and crop persist across reloads")
 game.town_upgrade.route_filter=1;var entries:Array=game.town_upgrade.route_entries(game)
 check(entries.has("grove") and entries.has("quarry") and not entries.has("astral_rift"),"wayfinder easy route filters realms")
 game.town_upgrade.route_filter=3;entries=game.town_upgrade.route_entries(game);check(entries.has("astral_rift") and entries.has("shattered_oath") and not entries.has("grove"),"wayfinder hard route filters realms")
 game.menu="wayfinder";key(game,KEY_RIGHT);check(game.town_upgrade.route_filter==0,"wayfinder keyboard filter cycles")
 # Check connected walkable routes to every service, not just each endpoint.
 var seen:Dictionary={};var queue:Array[Vector2i]=[];var start:=Vector2i(45,32);queue.append(start);seen[start]=true;var cursor:=0
 while cursor<queue.size():
  var cell:Vector2i=queue[cursor];cursor+=1
  for offset in [Vector2i.UP,Vector2i.DOWN,Vector2i.LEFT,Vector2i.RIGHT]:
   var next:Vector2i=cell+offset
   if next.x<1 or next.y<1 or next.x>=int(game.region_size().x/20)-1 or next.y>=int(game.region_size().y/20)-1 or seen.has(next):continue
   if game.can_stand_at(Vector2(next)*20):seen[next]=true;queue.append(next)
 for place in game.town_places:
  check(game.can_stand_at(place.pos),"town interaction accessible: "+str(place.menu))
  check(seen.has(Vector2i(roundi(place.pos.x/20),roundi(place.pos.y/20))),"connected town path: "+str(place.menu))
 check(not game.can_stand_at(Vector2(510,480)) and not game.can_stand_at(Vector2(1960,600)),"new building bodies block movement")
 var party=load("res://scenes/arcade.tscn").instantiate();root.add_child(party);await process_frame;party.set_process(false);party.provisions.packed="berry_bun";party._set_mode("defense");party._solo()
 var id:String=party.my_id;check(party.food_slots[id]=="berry_bun","packed food transfers to solo defence")
 party.inventory[id]=["potion","shield","hammer"];party.health[id]=party._max_hp(id);party.invincible_until[id]=0;party._hurt(id,60,"enemy")
 check(party.food_slots[id]=="" and party.inventory[id].size()==3 and party.contributions.get(id,{}).get("healing",0)==0,"multiplayer food eats once without ability-healing contribution")
 party.food_slots[id]="antidote_pear";party.adventure.combat.apply_status("p:"+id,"poison",5,"enemy",2)
 check(party.food_slots[id]=="" and party.adventure.combat.effect_time("p:"+id,"poison")==0,"host poison cleanse")
 party._add_player("friend",1);party.run_time=8;party.party_tools.late_pending["friend"]=true;party._packet("friend",{"type":"hero","hero":"cat","food":"hearty_stew"})
 check(party.food_loadouts.friend=="hearty_stew" and party.food_slots.friend=="hearty_stew","late initial guest food registration accepted once")
 party._packet("friend",{"type":"hero","hero":"cat","food":"berry_bun"});check(party.food_loadouts.friend=="hearty_stew","repeated hero packet cannot refill food")
 party._add_player("pending",2)
 var pending_packet:Dictionary=party._snapshot();check(not pending_packet.players.pending.food_ready,"unregistered guest food not confirmed in snapshot")
 var packet:Dictionary=JSON.parse_string(JSON.stringify(party._snapshot()))
 check(packet.players.friend.food=="hearty_stew","food slots serialize to multiplayer state")
 var guest=load("res://scenes/arcade.tscn").instantiate();root.add_child(guest);await process_frame;guest.set_process(false);guest.role="guest";guest.my_id="friend";guest.host_id=id;guest._packet(id,packet)
 check(guest.food_slots.friend=="hearty_stew" and guest.provisions.packed=="hearty_stew","guest receives and persists packed food")
 guest.health.friend=1;check(not guest.provisions.check_auto("friend") and guest.food_slots.friend=="hearty_stew","guest cannot consume food authoritatively")
 party.health.friend=100;party.invincible_until.friend=0;party._hurt("friend",80,"enemy")
 check(party.food_slots.friend=="" and party.health.friend>20,"host auto-heals remote player")
 packet=JSON.parse_string(JSON.stringify(party._snapshot()));guest._packet(id,packet)
 check(guest.food_slots.friend=="" and guest.provisions.packed=="","consumption sync prevents food duplication after return to town")
 for style in ["arena","descent","coop","defense"]:
  party._set_mode(style);party.food_loadouts[id]="berry_bun";party._start_match();party.health[id]=party._max_hp(id);party.invincible_until[id]=0
  party._hurt(id,60,"enemy")
  check(party.food_slots[id]=="" and party.health[id]>party._max_hp(id)-60,"automatic food in "+style)
 for node in [game,party,guest]:
  for voice in node.journey.voices:voice.stop()
  node.queue_free()
 await create_timer(.4).timeout
 print("v65: ",failures," failures");quit(1 if failures else 0)

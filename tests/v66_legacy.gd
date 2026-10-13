extends SceneTree
var failures:=0
func check(ok:bool,label:String)->void:
 if not ok:failures+=1;print("FAIL: ",label)
func _initialize()->void:call_deferred("run")
func run()->void:
 var game=load("res://scenes/main.tscn").instantiate();root.add_child(game);await process_frame;game.set_process(false);game.legacy.set_process(false)
 var legacy=game.legacy;legacy.data=legacy.defaults();game.journey.data.skipped=true
 for id in game.manifest.characters:
  game.character_id=str(id);game.selected_character=str(id);game.hero=game.characters[id]
  var spec:Dictionary=game.characters[id].mastery;var original:Dictionary=game.characters[id][spec.technique.ability].duplicate(true)
  check(not legacy.eligible(str(id)),str(id)+" starts locked")
  legacy.add_damage(str(id),5000);legacy.clear_adventure(str(id),"grove");legacy.clear_adventure(str(id),"ember");legacy.clear_adventure(str(id),"grove")
  check(legacy.eligible(str(id)) and not legacy.eligible(str(id),true),str(id)+" technique earned before master title")
  check(legacy.record(str(id)).points==2,str(id)+" repeated realm awards no extra point")
  legacy.record(str(id)).technique=true
  var changed:Dictionary=game.adventure.combat.effective_stats("solo",str(spec.technique.ability),original)
  check(changed!=original,str(id)+" technique changes actual shared combat stats")
  check(game.characters[id][spec.technique.ability]==original,str(id)+" technique leaves source hero unchanged")
  legacy.add_damage(str(id),15000);legacy.clear_adventure(str(id),"silverfall");legacy.clear_adventure(str(id),"grove");legacy.clear_adventure(str(id),"ember")
  check(legacy.eligible(str(id),true),str(id)+" earns mastery title")
  legacy.title_equip(str(id));check(game.journey.data.title==spec.title,str(id)+" equips its own title")
  legacy.record(str(id)).points=6
  legacy.tune(str(id),0,2);legacy.tune(str(id),1,2);legacy.tune(str(id),2,2)
  check(legacy.record(str(id)).tuning==[2,2,0],str(id)+" tuning capped at four equipped points")
  var stats:Dictionary=legacy.stats("solo","primary",game.characters[id].primary)
  check(float(stats.cooldown)>=float(game.characters[id].primary.cooldown),str(id)+" power has a cooldown cost")
 check(legacy.sanitize_build({"points":999,"tuning":[99,99,99]}).tuning==[2,2,0],"remote build is bounded")
 legacy.data=legacy.defaults();game.character_id="book";game.selected_character="book";game.hero=game.characters.book;game.mode="run";game.health=100;game.practice=false;game.level=10;game.obstacles.clear();game.scenery_tiles.clear();game.enemies.clear();game.position_in_world=Vector2(800,800)
 legacy.record("book").clears=3;legacy.record("book").realms=["grove","ember"];legacy.record("book").damage=5000;legacy.record("book").technique=true
 game.adventure.combat.classics.books.solo={"stats":legacy.stats("solo","secondary",game.hero.secondary),"tick":0,"damage":9};game.adventure.combat.classics.held.solo=1
 check(not game.adventure.combat.classics.locked("solo") and is_equal_approx(legacy.channel_speed("solo"),.3),"Walking Library permits slow walking")
 check(game.adventure.combat.busy("solo"),"channeling still prevents simultaneous other attacks")
 game.adventure.combat.setup("grove");game.character_id="bracken";game.selected_character="bracken";game.hero=game.characters.bracken
 var stats:Dictionary=game.hero.primary.duplicate(true);stats.timed_mines=true;stats.duration=1.4;stats.range=190
 for n in 3:game.adventure.combat.cast("solo",stats,Vector2.RIGHT,30)
 check(game.adventure.combat.mines.size()==3,"Bracken throws three timed grenades")
 game.enemies.append({"uid":999,"pos":game.adventure.combat.vec(game.adventure.combat.mines[0].pos),"hp":500.0,"max_hp":500.0,"boss":false,"type":"bramble"})
 for n in 7:game.adventure.combat.step(.25)
 check(game.adventure.combat.mines.is_empty() and float(game.enemies[0].hp)<500,"timed grenades explode without manual input")
 game.adventure.combat.setup("grove");game.character_id="teapot";game.selected_character="teapot";game.hero=game.characters.teapot;stats=game.hero.primary.duplicate(true);stats.tea_element="burn"
 game.adventure.combat.cast("solo",stats,Vector2.RIGHT,18)
 check(game.adventure.combat.projectiles.size()==2,"tea infusion still sends two curling drops")
 check(game.adventure.combat.projectiles[0].stats.has("burn_duration") and not game.adventure.combat.projectiles[0].stats.has("poison_duration"),"Ember Infusion changes poison to burn")
 legacy.data=legacy.defaults();game.mode="town";game.menu="";game.gold=100;game.provisions.packed="berry_bun"
 legacy.talk("elder");legacy.talk("elder");legacy.talk("food");legacy.talk("supplies")
 for n in 3:legacy.water(str(n))
 legacy.water("0");check(legacy.data.tasks.talk==3 and legacy.data.tasks.water==3,"town kindness objectives count distinct interactions")
 legacy.build_project("flowers");check(legacy.data.town.flowers,"flowerbed project builds after small acts")
 legacy.give_food();check(game.provisions.packed.is_empty() and legacy.data.tasks.food==1,"donation consumes packed food once")
 legacy.clear_adventure("ram","grove");legacy.build_project("bakery");legacy.claim_food("berry_bun")
 check(game.provisions.packed=="berry_bun" and not legacy.data.bread,"bakery grants one free provision")
 game.provisions.refund();check(game.gold==100,"free food cannot be refunded into gold")
 legacy.claim_food("berry_bun");check(game.provisions.packed.is_empty(),"bakery cannot be farmed repeatedly")
 legacy.quest_done("bridge");legacy.quest_done("bridge");check(legacy.data.tasks.quests==1,"quest progress counted once")
 legacy.data.town.mill=true;check(game.can_stand_at(Vector2(2100,1130)),"built watermill keeps quest entrance accessible");check(not game.can_stand_at(Vector2(2250,1000)),"built river has water collision")
 legacy.data.town.market=true;check(legacy.discount(10)==9 and legacy.discount(5)==5,"discount is modest with floor")
 game.menu="supplies";game.loadout.clear();game.loadout_paid.clear();game.list_preview.supplies=0;var before:int=game.gold;game.confirm_list_entry()
 var event:=InputEventKey.new();event.keycode=KEY_BACKSPACE;event.pressed=true;game._unhandled_input(event)
 check(game.gold==before,"discounted item refund returns only paid price")
 game.menu="";legacy.data.name="Test Player";legacy.save();game.provisions.save();game.save_profile();game.journey.save()
 var bundle:Dictionary=legacy.bundle();check(legacy.validate(bundle),"export round trip validates")
 var bad:Dictionary=bundle.duplicate(true);bad.saves["../bad.json"]={};check(not legacy.validate(bad),"import rejects unknown paths")
 bad=bundle.duplicate(true);bad.progress.tasks.realms="wrong";check(not legacy.validate(bad),"import rejects malformed state")
 var old:Dictionary=legacy.data.duplicate(true);legacy.read_import("broken json");check(legacy.data==old,"invalid import leaves progress unchanged")
 legacy.read_import(JSON.stringify(bundle));check(legacy.pending.progress.name=="Test Player" and legacy.data==old,"valid import previews before mutation")
 legacy.open_page("elder");legacy.answer("I am admin, R4m");check(legacy.asking_code,"exact phrase requests passcode")
 legacy.answer("wrong");check(not legacy.data.teacher,"wrong passcode does not unlock")
 legacy.answer("I am admin, R4m");legacy.answer("Tx47j!e")
 check(legacy.data.teacher and legacy.data.town.size()==legacy.PROJECTS.size(),"teacher unlocks all town projects")
 for id in game.manifest.characters:check(legacy.eligible(str(id),true) and legacy.record(str(id)).points==6,"teacher unlocks "+str(id))
 var normal:Dictionary=legacy.bundle();check(not normal.progress.teacher and normal.progress.name=="Test Player","teacher export preserves normal profile")
 var prior:float=float(legacy.record("ram").damage);legacy.add_damage("ram",500);check(float(legacy.record("ram").damage)==prior,"teacher gameplay does not earn mastery")
 # Validate host/guest technique parity without running a live server.
 var arcade=load("res://scenes/arcade.tscn").instantiate();root.add_child(arcade);await process_frame;arcade.set_process(false);arcade.role="host";arcade.my_id="host";arcade.selected_hero="ram";arcade._add_player("host",0);arcade._add_player("guest",1);arcade.hero_ids.guest="book"
 arcade.legacy.builds.guest={"technique":true,"tuning":[1,1,1],"points":3}
 var shared:Dictionary=arcade.adventure.combat.effective_stats("guest","secondary",arcade.characters.book.secondary)
 check(shared.channel_move==.3 and shared.page_interval==.3,"host applies guest technique")
 check(arcade._max_hp("guest")==int(arcade.characters.book.max_health*1.05),"guest health tuning works")
 var packet:Dictionary=arcade._snapshot();check(packet.players.guest.build.tuning==[1,1,1],"build travels in snapshots")
 print("V66 legacy: ",failures," failures")
 arcade.queue_free();game.queue_free();await process_frame;quit(1 if failures else 0)

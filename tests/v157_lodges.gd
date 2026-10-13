extends SceneTree
var failures=0
func check(ok:bool,message:String)->void:
 if not ok:failures+=1;print("FAIL: ",message)
func _initialize()->void:call_deferred("run")
func run()->void:
 root.set_meta("fx_intro_seen",true);root.set_meta("fx_tutorial_offered",true)
 var g=load("res://scenes/main.tscn").instantiate();root.add_child(g);current_scene=g
 for n in 12:await process_frame
 g.set_process(false);g.legacy.set_process(false);g.lodges.set_process(false);g.presentation.close();g.session_menu.resume()
 var e=g.legacy.lodge_economy;e.clock_override=1000;g.legacy.data.erase("lodges");var s=e.state()
 e.dispatch("meadow");s.jobs[0].seed="forage_sun";e.claim(0);check(s.jobs.size()==1,"early crew claim blocked")
 e.clock_override=1301;e.claim(0);check(s.jobs.is_empty() and "forage_sun" in s.seeds,"crew claim and rare seed unlock")
 var found=s.gathered;e.claim(0);check(s.gathered==found,"duplicate claim cannot award")
 e.brew("lodge_tonic");check(not s.brew.is_empty(),"starter recipe brews")
 e.claim_brew();check(s.potions.is_empty(),"early brew claim blocked")
 e.clock_override=1362;e.claim_brew();e.claim_brew();check(s.potions.get("lodge_tonic",0)==1,"brew collected once")
 g.loadout.clear();e.pack(g,"lodge_tonic");check(g.loadout==["lodge_tonic"] and s.potions.lodge_tonic==0,"packing spends a bottle")
 check(preload("res://scripts/lodge_catalog.gd").valid(s),"portable state valid")
 check(g.legacy.validate(g.legacy.bundle()),"complete profile export preserves lodges")
 for id in g.lodges.visual_textures:check(g.lodges.visual_textures[id]!=null,"loaded art "+str(id))
 for page in ["gather","apothecary","challenge"]:g.lodges.open(page);await process_frame;check(g.presentation.content.get_child_count()>3,"menu "+page)
 for type in 5:
  g.lodges.start(type,0);g.menu="";g.mistglass_rift.countdown=0
  check(g.lodges.active and g.level==10 and g.inventory.is_empty(),"trial launches at level 10 without items")
  check(g.lodges.map_texture!=null,"trial map art")
  for n in 30:g.mistglass_rift.step(.016);g.lodges.tick(.016)
  g.lodges.finish(true);await process_frame
  check(g.mode=="town" and not g.lodges.active,"trial returns to town")
 check(e.medal_total()>=5,"trial medals awarded")
 check(g.legacy.cosmetics.eligible("lodge_bronze"),"bronze cosmetic earned")
 for task in preload("res://scripts/lodge_catalog.gd").weekly():e.medal("stand:0",3,task.key)
 check(g.legacy.cosmetics.eligible("lodge_week"),"weekly cosmetic earned")
 g.lodges.start(0,0);g.menu="";g.mistglass_rift.countdown=0;g.health=1;g.invulnerable_time=0;g.take_player_damage(100)
 check(not g.lodges.active and g.mode=="town","death returns safely")
 g.presentation.close();g.legacy.cosmetics.close_picker();g.queue_free();
 for n in 4:await process_frame
 print("v157 lodges: ",failures," failures");quit(failures)

extends SceneTree
var failures:=0
func check(ok:bool,label:String)->void:
 if not ok:failures+=1;print("FAIL: ",label)
func _initialize()->void:call_deferred("run")
func run()->void:
 root.set_meta("fx_intro_seen",true)
 var g=load("res://scenes/main.tscn").instantiate();root.add_child(g);await process_frame;g.set_process(false);g.legacy.set_process(false);g.presentation.asked=true;g.presentation.close();g.session_menu.resume()
 check(g.characters.size()==72,"72 complete heroes")
 for id in g.manifest.characters:
  var h:Dictionary=g.characters[id]
  for pose in ["idle","walk1","walk2","attack"]:check(g.art.has(str(h.sprite)+"_"+pose),"matching pose "+str(id)+" "+pose)
  check(int(h.mastery.final_requirements.damage)==85000,"final damage gate "+str(id))
  check(int(h.mastery.technique_requirements.damage)==10000,"first damage gate "+str(id))
 check(g.town_scenery.routes.size()==5,"two new guard patrol routes")
 check(not g.can_stand_at(Vector2(2350,1000)) and g.can_stand_at(Vector2(2350,1150)),"river blocks and bridge crosses")
 check(g.town_upgrade.POINTS.food==Vector2(900,950),"food at old descent plaza")
 check(g.town_places.any(func(x):return x.menu=="descent_entrance" and x.pos==Vector2(230,805)),"descent at western mountain")
 g.menu="portal";g.catalog_ui._process(.1);check(g.catalog_ui.panel.visible and g.catalog_ui.enter.text.begins_with("ENTER REALM"),"realm native UI and confirm")
 var roster:Array=g.catalog_ui.roster("grove");check(not roster.is_empty(),"realm has unseen enemy squares")
 g.menu="supplies";g.catalog_ui._process(.1);check(g.catalog_ui.enter.text.begins_with("BUY ITEM"),"item explicit confirm")
 g.menu="food";g.catalog_ui._process(.1);check(g.catalog_ui.enter.text.begins_with("BUY FOOD"),"food explicit confirm")
 g.catalog_ui.close();g.enter_region("practice");g.menu="training_guide";g.town_services._process(.1);check(g.town_services.panel.visible,"practice guide opens");g.town_services.close()
 # Actual mastery selection changes the intended independent slot for every new hero.
 for id in ["cindervane","tova","merrymask","dunecook","dustmarshal"]:
  var h:Dictionary=g.characters[id]
  check(h.mastery.technique.ability!=h.mastery.final_technique.ability,"separate mastery slots "+id)
  for key in ["technique","final_technique"]:
   var t:Dictionary=h.mastery[key];var a:Dictionary=g.legacy.authored_stats(id,str(t.ability),h[t.ability],{key:true,"tuning":[0,0,0]})
   check(a.style==t.attack.style,"equipped technique "+id+key)
 g.enter_region("grove");g.enemies.clear();g.obstacles.clear();g.scenery_tiles.clear();g.adventure.spawn("bramble",g.position_in_world+Vector2(80,0),500,false);g.legacy.data.encounters={};g.catalog_ui.record_encounters()
 check("bramble" in g.legacy.data.encounters.get("grove",[]),"encounter reveals only visited realm")
 check(not "bramble" in g.legacy.data.encounters.get("quarry",[]),"discovery is per realm")
 var portable:Dictionary=JSON.parse_string(JSON.stringify(g.legacy.bundle()))
 check(g.legacy.validate(portable) and "bramble" in portable.progress.encounters.grove,"encounters survive portable profile serialization")
 g.queue_free();await process_frame;print("v90 features failures: ",failures);quit(failures)

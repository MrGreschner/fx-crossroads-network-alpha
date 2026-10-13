extends SceneTree
var failures:=0
func check(ok:bool,description:String)->void:
 if not ok:failures+=1;print("FAIL: ",description)
func _initialize()->void:call_deferred("run")
func run()->void:
 root.set_meta("fx_intro_seen",true)
 var g=load("res://scenes/main.tscn").instantiate();root.add_child(g);await process_frame;g.set_process(false);g.legacy.set_process(false);g.presentation.asked=true;g.presentation.close();g.session_menu.resume()
 var gallery=g.session_menu.gallery
 check(gallery.heroes.size()==24 and gallery.creatures.size()==24,"four full six-card sets per side")
 var ids:Array=[]
 for entry in gallery.heroes:ids.append(entry.id);check(entry.first!=null and entry.second!=null,"hero gallery art")
 check(ids.size()==24 and ids.all(func(id):return ids.count(id)==1),"hero sets are distinct")
 ids.clear()
 for entry in gallery.creatures:ids.append(entry.id);check(entry.first!=null,"enemy gallery art")
 check(ids.all(func(id):return ids.count(id)==1),"enemy sets are distinct")
 var before:float=gallery.clock;gallery._process(.3);check(gallery.clock==before,"hidden gallery does no animation work")
 var hall=g.hero_hall;g.menu="characters";hall._process(0)
 for id in g.manifest.characters:
  g.selected_character=id;hall.render_details();await process_frame;await process_frame
  var info:Dictionary=hall.library.entry(id,g.characters[id]);check(not str(info.get("lore","")).is_empty(),"short lore for "+id)
  check(not str(info.get("passive_brief","")).is_empty(),"passive quick summary for "+id)
  check(hall.ability_cards.size()==4,"four cards for "+id)
  var bottom:float=hall.right_scroller.get_global_rect().end.y
  check(hall.ability_cards.special.button.get_global_rect().end.y<=bottom+1,"all four abilities visible without scrolling: "+id)
  for kind in ["primary","secondary","special"]:check(not hall.library.ability_brief(g.characters[id][kind],kind).is_empty(),"quick ability summary "+id+kind)
 g.selected_character="dustmarshal";hall.render_details();await process_frame
 var primary:Dictionary=hall.ability_cards.primary;primary.button.pressed.emit();check(primary.detail.visible and primary.detail.text.contains("22"),"click expands exact pistol details")
 check(not hall.ability_cards.secondary.detail.visible,"expanding one card leaves the others compact")
 primary.button.pressed.emit();check(not primary.detail.visible,"second click collapses details")
 hall.show_story("patch");var story:AcceptDialog
 for child in hall.get_children():
  if child is AcceptDialog:story=child
 check(story!=null and story.dialog_text.contains("controller"),"Patch story describes what he is")
 if story!=null:story.queue_free()
 hall.close();g.menu="portal";g.catalog_ui._process(.1)
 var catalog=g.catalog_ui;var id:String="grove";catalog.selected=catalog.entries.find(id);g.legacy.data.encounters[id]=catalog.roster(id).duplicate();catalog.render_detail();await process_frame
 var captions:Array=[]
 for grid in catalog.detail.get_children():
  if grid is GridContainer:
   for box in grid.get_children():captions.append(box.get_child(0).get_child(1).text)
 for kind in catalog.roster(id):check(catalog.enemy_name(id,kind) in captions,"discovered enemy has visible name "+kind)
 g.legacy.data.encounters[id]=[];catalog.render_detail();await process_frame
 for grid in catalog.detail.get_children():
  if grid is GridContainer:
   for box in grid.get_children():check(box.get_child(0).get_child(1).text=="Unknown","unknown names stay hidden")
 check(g.town_chapter.forest_trees.size()>=15,"woodland is a dense cached grove")
 for tree in g.town_chapter.forest_trees:check(not g.town_chapter.CAMP_CLEARING.grow(50).has_point(tree),"camp clearing free of trunks")
 for point in [Vector2(2510,1150),Vector2(2680,1150),Vector2(2780,1180),Vector2(2940,1160),Vector2(2810,1300),Vector2(2850,1390)]:check(g.can_stand_at(point),"open forest trail "+str(point))
 g.queue_free();await process_frame;await process_frame;print("v96 polish failures: ",failures);quit(failures)

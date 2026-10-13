extends SceneTree
var failures=0
func check(ok:bool,message:String)->void:
 if not ok:failures+=1;print("FAIL: ",message)
func _initialize()->void:call_deferred("run")
func run()->void:
 var game=load("res://scenes/main.tscn").instantiate();root.add_child(game);current_scene=game
 for i in 12:await process_frame
 game.set_process(false);game.legacy.set_process(false);game.presentation.close();game.session_menu.resume()
 var hall=game.hero_hall
 hall.open_grid();await process_frame
 var selector=hall.portrait_grid
 check(selector.shown.size()==game.manifest.characters.size(),"all official heroes in grid")
 for id in selector.shown:check(selector.tiles[id].get_child(0).get_child(0).texture!=null,"portrait "+str(id))
 var original=game.selected_character;selector.choose("book")
 check(game.selected_character==original,"preview does not select")
 check(selector.info.text.contains("Living Book"),"name preview")
 selector.close();await process_frame
 check(game.selected_character==original,"close cancels")
 hall.open_grid();await process_frame;selector=hall.portrait_grid;selector.choose("book");selector.confirm();await process_frame
 check(game.selected_character=="book","hall Select applies")
 var p=preload("res://scripts/studio_examples.gd").all("hero")[0]
 preload("res://scripts/studio_library.gd").add_hero(p);preload("res://scripts/studio_library.gd").install(game)
 hall.open_grid();await process_frame;selector=hall.portrait_grid;selector.custom=true;selector.refresh()
 check(not selector.shown.is_empty(),"custom saved hero available")
 selector.close();await process_frame
 var arcade=load("res://scenes/arcade.tscn").instantiate();root.add_child(arcade)
 for i in 8:await process_frame
 arcade.set_process(false);arcade.party_tools.auto_solo=false
 arcade._open_hero_grid();await process_frame;selector=arcade.hero_grid
 check(selector.shown.size()==game.manifest.characters.size(),"lobby roster")
 selector.choose("cat");selector.confirm();await process_frame
 check(arcade.selected_hero=="cat","lobby selection route")
 var id=""
 for key in arcade.characters:if str(key).begins_with("custom_"):id=str(key);break
 if not id.is_empty():
  check(not arcade._grid_permission(id).is_empty(),"custom disabled restriction")
  arcade.allow_custom=true;arcade.public_room.button_pressed=false
  check(arcade._grid_permission(id).is_empty(),"private custom enabled")
 arcade.queue_free();game.queue_free();await process_frame
 print("v155 grid: ",failures," failures");quit(failures)

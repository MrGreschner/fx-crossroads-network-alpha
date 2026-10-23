extends RefCounted
static func day()->int:
 return floori((Time.get_unix_time_from_system()+preload("res://scripts/town_clock_math.gd").edmonton_offset(Time.get_unix_time_from_system()))/86400.0)
static func id(g:Node)->String:
 var choices=[]
 for key in g.manifest.characters:
  if g.characters.has(key) and not str(key).begins_with("custom_") and not g.characters[key].has("studio_project"):choices.append(str(key))
 if choices.is_empty():return "ram"
 var rng=RandomNumberGenerator.new();rng.seed=day()*7919+194
 return str(choices[rng.randi_range(0,choices.size()-1)])
static func active(l:Node)->bool:
 if l.arcade:return l.game.started and str(l.game.hero_ids.get(l.game.my_id,""))==id(l.game)
 return l.game.mode=="run" and str(l.game.character_id)==id(l.game) and not l.game.practice
static func open(hall:Node)->void:
 var hero_id=id(hall.game);var hero=hall.game.characters[hero_id]
 var dialog=AcceptDialog.new();preload("res://scripts/studio_ui.gd").apply(dialog);dialog.title="Hero of the day";dialog.ok_button_text="Pick hero of the day";dialog.dialog_text=""
 var col=VBoxContainer.new();col.add_theme_constant_override("separation",12);dialog.add_child(col)
 var label=Label.new();label.text=str(hero.name)+"\nEarn 10% more Glimmers during gameplay with today's hero.\nTown trades keep their normal prices.";label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;label.custom_minimum_size.x=460;col.add_child(label)
 var art=TextureRect.new();art.texture=portrait(hall.game,hero_id);art.custom_minimum_size=Vector2(130,130);art.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;art.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;col.add_child(art)
 dialog.confirmed.connect(func():hall.collection=0;hall.custom_only=false;hall.collection_picker.select(0);hall.select(hero_id);dialog.queue_free());dialog.canceled.connect(dialog.queue_free);hall.add_child(dialog);dialog.popup_centered(Vector2i(520,300))

static func portrait(g:Node,hero_id:String)->Texture2D:
 var sprite=str(g.characters.get(hero_id,{}).get("sprite",hero_id))
 var texture:Texture2D=g.art.get(sprite+"_idle",g.art.get(sprite+"_0"))
 if texture==null and ResourceLoader.exists("res://assets/"+sprite+"_idle.png"):texture=load("res://assets/"+sprite+"_idle.png")
 return texture

extends CanvasLayer
const UI=preload("res://scripts/studio_ui.gd")
const W=preload("res://scripts/studio_world_project.gd")
const Library=preload("res://scripts/studio_library.gd")
var workshop:Node
var kind="object"
var value:Dictionary={}
var panel:PanelContainer
var col:VBoxContainer
var tools:VBoxContainer
var canvas:Control
var preview:TextureRect
var status:Label
var transfer:Node
var upload="object"
var test_layer:CanvasLayer
var finalized=false
var test_arena:Control
var test_hero:Dictionary={}
var play_project:Dictionary={}
var autosave=-1.0
func setup(owner:Node,is_realm:bool)->void:
 workshop=owner;kind="realm" if is_realm else "object";layer=72
 value=W.example(randi()%5) if is_realm else W.object(W.OBJECTS[randi()%W.OBJECTS.size()])
 var draft="user://fx_"+kind+"_lab.json"
 var restored=preload("res://scripts/profile_store.gd").read(draft,func(v:Dictionary)->bool:return W.validate(kind,v).is_empty())
 if not restored.is_empty():value=restored
 var shade=ColorRect.new();shade.color=Color("#071c27");shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);add_child(shade)
 panel=PanelContainer.new();panel.size=Vector2(1170,730);add_child(panel);UI.apply(panel);UI.enter(panel)
 col=VBoxContainer.new();panel.add_child(col)
 transfer=preload("res://scripts/studio_transfer.gd").new();add_child(transfer);transfer.received.connect(import_file);transfer.failed.connect(func(t:String):status.text=t)
 render()
func changed()->void:finalized=false;autosave=.6
func save_draft()->void:
 var issue=W.validate(kind,value)
 if not issue.is_empty():status.text=issue;return
 var error=preload("res://scripts/profile_store.gd").write("user://fx_"+kind+"_lab.json",value)
 if error!=OK:status.text="Could not save draft; download this project."
func render()->void:
 workshop.clear(col)
 var header=HBoxContainer.new();col.add_child(header);workshop.label(header,"REALM BUILDER" if kind=="realm" else "OBJECT LAB",25).size_flags_horizontal=Control.SIZE_EXPAND_FILL
 UI.accent(workshop.button(header,"Finalize & Play" if kind=="realm" else "Finalize object",finalize));workshop.button(header,"Back to Studio",func():save_draft();workshop.show_hub();queue_free())
 workshop.button(header,"Journey",func():save_draft();load("res://scripts/studio_showcase.gd").open(workshop))
 var row=HBoxContainer.new();col.add_child(row);workshop.button(row,"Clear / Start fresh",fresh);workshop.button(row,"Download project",download);workshop.button(row,"Import project",func():transfer.choose())
 if load("res://scripts/education_access.gd").student():
  var submit=workshop.button(row,"Submit finalized work",func():
   if not finalized:status.text="Finalize this revision first.";return
   status.text=preload("res://scripts/studio_finalize.gd").submit(kind,value,value.name)
  );submit.disabled=not finalized
 var samples=OptionButton.new();samples.fit_to_longest_item=false;samples.custom_minimum_size.x=180;samples.add_item("Load an example…");row.add_child(samples)
 for n in 5:samples.add_item((W.example(n).name if kind=="realm" else ["Oak tree","Bench","Tower","Flower bed","Fountain"][n]))
 samples.item_selected.connect(func(n:int):if n>0:value=W.example(n-1) if kind=="realm" else W.object(samples.get_item_text(n));changed();render())
 var split=HBoxContainer.new();split.size_flags_vertical=Control.SIZE_EXPAND_FILL;col.add_child(split)
 var scroll=ScrollContainer.new();scroll.custom_minimum_size.x=360;scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;split.add_child(scroll);tools=VBoxContainer.new();tools.size_flags_horizontal=Control.SIZE_EXPAND_FILL;scroll.add_child(tools);preload("res://scripts/touch_list_scroll.gd").attach(scroll).form_controls=true
 edit_text(tools,"Project name",value,"name",60)
 var saved=OptionButton.new();saved.fit_to_longest_item=false;saved.add_item("Open saved project…");tools.add_child(saved);var collection=Library.load_data()["realms" if kind=="realm" else "objects"];var keys=collection.keys()
 for id in keys:saved.add_item(collection[id].name)
 saved.item_selected.connect(func(n:int):if n>0:value=collection[keys[n-1]].duplicate(true);changed();render())
 if kind=="realm":
  realm_tools()
  canvas=preload("res://scripts/studio_world_canvas.gd").new();canvas.size_flags_horizontal=Control.SIZE_EXPAND_FILL;canvas.size_flags_vertical=Control.SIZE_EXPAND_FILL;split.add_child(canvas);canvas.setup(value);canvas.edited.connect(changed)
  var controls=HBoxContainer.new();col.add_child(controls)
  for entry in [["Fit map",canvas.fit],["Go to spawn",canvas.focus_spawn],["Undo",canvas.undo],["Redo",canvas.redo]]:workshop.button(controls,entry[0],entry[1])
  var grid=CheckButton.new();grid.text="Grid";grid.button_pressed=true;controls.add_child(grid);grid.toggled.connect(func(on:bool):canvas.show_grid=on;canvas.renderer.invalidate();canvas.refresh_minimap();canvas.queue_redraw())
  var brush=OptionButton.new();controls.add_child(brush)
  for n in [1,3,5,9]:brush.add_item(str(n)+" × "+str(n)+" brush")
  brush.item_selected.connect(func(n:int):canvas.brush=[1,3,5,9][n])
  workshop.button(controls,"Touch pan",func():canvas.mode="pan")
 else:
  object_tools()
  var right=VBoxContainer.new();right.size_flags_horizontal=Control.SIZE_EXPAND_FILL;split.add_child(right);preview=TextureRect.new();preview.custom_minimum_size=Vector2(340,350);preview.size_flags_vertical=Control.SIZE_EXPAND_FILL;preview.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;preview.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;preview.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST;right.add_child(preview)
  var image=Image.new();image.load_png_from_buffer(Marshalls.base64_to_raw(value.image));preview.texture=ImageTexture.create_from_image(image)
  workshop.label(right,"GAME PREVIEW • artwork is placed at its feet. Dimensions affect display and footprint; collision is a small base, so players can pass behind tall props.",15)
 status=workshop.label(col,"LOCAL DRAFT • Edit → Finalize → Play. Download one file to share. Profile ZIP includes saved objects and realms.",15)
func edit_text(parent:Node,title:String,data:Dictionary,key:String,limit:int)->void:
 workshop.label(parent,title,16);var edit=LineEdit.new();edit.text=str(data.get(key,""));edit.max_length=limit;parent.add_child(edit);edit.text_changed.connect(func(t:String):data[key]=t;changed())
func check(parent:Node,title:String,data:Dictionary,key:String)->void:
 var c=CheckButton.new();c.text=title;c.button_pressed=data[key];parent.add_child(c);c.toggled.connect(func(on:bool):data[key]=on;changed();if kind=="realm" and is_instance_valid(canvas):canvas.renderer.invalidate();canvas.refresh_minimap();canvas.queue_redraw())
func number(parent:Node,title:String,data:Dictionary,key:String,lo:int,hi:int)->void:
 workshop.label(parent,title,16);var s=SpinBox.new();s.min_value=lo;s.max_value=hi;s.value=data[key];parent.add_child(s);s.value_changed.connect(func(n:float):data[key]=int(n);changed())
func object_tools()->void:
 var premade=OptionButton.new();premade.fit_to_longest_item=false;premade.add_item("Start from a premade object…");tools.add_child(premade)
 for name in W.OBJECTS:premade.add_item(name)
 premade.item_selected.connect(func(n:int):if n>0:value=W.object(premade.get_item_text(n));changed();render())
 edit_text(tools,"Category",value,"category",100);edit_text(tools,"Creator / sources / permission",value,"source",200)
 number(tools,"Display width",value,"width",16,160);number(tools,"Display height",value,"height",16,160)
 check(tools,"Block movement at base",value,"block_move");check(tools,"Block projectiles at base",value,"block_shots")
 UI.accent(workshop.button(tools,"Draw • layers & pixel tools",func():
  var editor=preload("res://scripts/studio_raster_editor.gd").new();add_child(editor);editor.setup(workshop,value);editor.saved.connect(func(v:Dictionary):value=v;changed();render())
 ))
 workshop.button(tools,"Download flattened PNG",func():W.download_png(self,value.image,value.name.validate_filename()+".png"))
 workshop.button(tools,"Upload PNG artwork",func():upload="object";transfer.choose("png"))
 workshop.label(tools,"Editable layers: "+str(value.layers.size())+" • recorded operations: "+str(value.operations.size()),15)
func realm_tools()->void:
 if preload("res://scripts/education_access.gd").student():
  workshop.label(tools,"Vision before building",19)
  var vision=TextEdit.new();vision.text=value.vision;vision.custom_minimum_size.y=80;vision.wrap_mode=TextEdit.LINE_WRAPPING_BOUNDARY;tools.add_child(vision);vision.text_changed.connect(func():value.vision=vision.text.left(1500);changed())
  if load("res://scripts/education_access.gd").student():workshop.button(tools,"Record initial vision in module",func():
   var s=load("res://scripts/learning_store.gd");var data=s.load_data();var available=s.stages(data.active).filter(func(t):return t.id in ["vision","brief","plan"])
   if available.is_empty():status.text="Select the realm design module in your portfolio first.";return
   var issue=s.note(data,data.active,available[0].id,value.vision);status.text="Initial vision recorded before your next artifact." if issue.is_empty() else issue
  )
 workshop.label(tools,"1 • Map size & atmosphere",19)
 workshop.button(tools,"Map size: %d × %d tiles" % [value.width,value.height],resize_map)
 workshop.label(tools,"Atmosphere & play rules",19)
 environment_tools()
 workshop.label(tools,"2 • Terrain / routes",19)
 var tiles=OptionButton.new();tiles.fit_to_longest_item=false;tools.add_child(tiles)
 for t in value.tiles:tiles.add_item(t.name)
 tiles.item_selected.connect(func(n:int):canvas.mode="tile";canvas.tile=n;canvas.picked="")
 workshop.button(tools,"Edit selected terrain",func():edit_tile(tiles.selected))
 workshop.button(tools,"Add custom terrain",func():
  if value.tiles.size()>=16:status.text="Sixteen terrain types maximum.";return
  value.tiles.append({"name":"Custom tile","color":"#769888","block_move":false,"block_shots":false,"image":""});changed();render()
 )
 workshop.label(tools,"3 • Place objects",19)
 var props=OptionButton.new();props.fit_to_longest_item=false;props.add_item("Select an object…");tools.add_child(props)
 var objects=Library.load_data().objects.duplicate(true)
 for name in W.OBJECTS:
  var p=W.object(name);p.id="builtin-"+name.to_snake_case();objects[p.id]=p
 var ids=objects.keys();var object_ids=ids.duplicate()
 for id in ids:props.add_item(objects[id].name)
 props.item_selected.connect(func(n:int):if n>0:
   var id=object_ids[n-1]
   if value.objects.size()>=32 and not value.objects.has(id):status.text="32 object types maximum. Clean unused types to make room.";return
   value.objects[id]=objects[id].duplicate(true);canvas.mode="object";canvas.picked=id;status.text="Click tiles to place "+objects[id].name+". Erase removes a placement.";changed())
 workshop.label(tools,"4 • Enemies (up to 64)",19)
 var enemies=Library.load_data().enemies.duplicate(true)
 var pick=OptionButton.new();pick.fit_to_longest_item=false;pick.add_item("Select an enemy…");tools.add_child(pick)
 var enemy_ids=enemies.keys()
 for id in enemy_ids:pick.add_item("Custom • "+enemies[id].name)
 var official_ids=workshop.game.enemy_types.keys();official_ids.sort()
 for id in official_ids:pick.add_item(str(workshop.game.enemy_types[id].get("name",id)))
 pick.item_selected.connect(func(n:int):
  if n==0:return
  var e:Dictionary=enemies[enemy_ids[n-1]] if n<=enemy_ids.size() else basic_enemy(official_ids[n-1-enemy_ids.size()])
  if value.enemies.size()>=12 and not value.enemies.has(e.id):status.text="Twelve enemy types per realm; reuse one or remove unused types.";return
  value.enemies[e.id]=e.duplicate(true);canvas.mode="enemy";canvas.picked=e.id;status.text="Place "+e.name+" • bounded Studio combat preset; customise it in Enemy Lab.";changed()
 )
 var heroes=Library.load_data().heroes;var hero_pick=OptionButton.new();hero_pick.fit_to_longest_item=false;tools.add_child(hero_pick);hero_pick.add_item("Test with current Workshop hero");var hero_ids=heroes.keys()
 for id in hero_ids:hero_pick.add_item(heroes[id].hero.name)
 hero_pick.item_selected.connect(func(n:int):play_project=heroes[hero_ids[n-1]].duplicate(true) if n>0 else {})
 var modes=HBoxContainer.new();tools.add_child(modes)
 for mode in ["spawn","exit","erase"]:workshop.button(modes,mode.capitalize(),func():canvas.mode=mode;status.text="Click a tile to "+mode+".")
 workshop.button(tools,"Clean unused object / enemy types",func():
  for collection_name in ["objects","enemies"]:
   var placement_kind="object" if collection_name=="objects" else "enemy"
   for id in value[collection_name].keys():
    if not value.placements.any(func(p):return p.kind==placement_kind and p.id==id):value[collection_name].erase(id)
  changed();render();status.text="Unused palette data removed; placed artwork preserved."
 )
 workshop.button(tools,"Check routes & collision",func():var issues=W.checks(value);status.text="Ready • walkable spawn, exit and route." if issues.is_empty() else "\n".join(issues))
 workshop.label(tools,"Wheel: zoom at cursor • right/middle-drag: pan • click minimap: travel. On touch, choose Pan to drag the map. Diagonals show blocked terrain.",14)
func basic_enemy(id:String)->Dictionary:
 var e=preload("res://scripts/studio_enemy_project.gd").fresh();e.id="grove-"+id;e.name=id.capitalize();e.attack_count=1;e.health=160 if id=="warden" else 70;e.speed=85;e.primary.style="projectile" if id=="archer" else "melee";e.primary.range=260 if id=="archer" else 65;e.primary.damage=8;e.primary.heal=0
 var definition:Dictionary=workshop.game.enemy_types.get(id,{})
 e.name=str(definition.get("name",e.name));e.primary.damage=clampf(float(definition.get("damage",8)),1,45);e.primary.cooldown=clampf(float(definition.get("shot_cooldown",1.5)),.5,10);e.health=clampf(float(definition.get("health",e.health)),20,500);e.speed=clampf(float(definition.get("speed",e.speed)),40,230)
 if "ranged" in str(definition.get("behaviour","")) or definition.has("shot_speed"):e.primary.style="projectile";e.primary.range=300
 e.art=preload("res://scripts/studio_art249.gd").encoded("wave_sentry" if id=="archer" else "mending_sentinel" if id=="warden" else "bramble_practice")
 return e
func edit_tile(n:int)->void:
 var dialog=AcceptDialog.new();dialog.title="Terrain • separate collision settings";add_child(dialog);UI.apply(dialog);var body=VBoxContainer.new();dialog.add_child(body);var t:Dictionary=value.tiles[n]
 edit_text(body,"Name",t,"name",60);var colour=ColorPickerButton.new();colour.color=Color(t.color);body.add_child(colour);colour.color_changed.connect(func(c:Color):t.color="#"+c.to_html(false);changed();canvas.renderer.invalidate();canvas.refresh_minimap();canvas.queue_redraw())
 check(body,"Block movement",t,"block_move");check(body,"Block projectiles",t,"block_shots")
 workshop.button(body,"Draw custom tile",func():var editor=preload("res://scripts/studio_pixel_editor.gd").new();add_child(editor);editor.setup(t.get("image",""),"Terrain tile",{},32);editor.saved.connect(func(img:String):t.image=img;changed();canvas.renderer.invalidate();canvas.refresh_minimap();canvas.queue_redraw()))
 workshop.button(body,"Upload tile PNG",func():upload="tile:"+str(n);transfer.choose("png"))
 var speed=SpinBox.new();speed.min_value=.2;speed.max_value=1.5;speed.step=.05;speed.value=float(t.get("speed",1));workshop.label(body,"Movement multiplier (sand / slippery routes)",15);body.add_child(speed);speed.value_changed.connect(func(n:float):t.speed=n;changed())
 var damage=SpinBox.new();damage.min_value=0;damage.max_value=20;damage.step=1;damage.value=float(t.get("damage",0));workshop.label(body,"Hazard damage per second (0 = safe)",15);body.add_child(damage);damage.value_changed.connect(func(n:float):t.damage=n;changed())
 dialog.confirmed.connect(func():dialog.queue_free();render());dialog.popup_centered(Vector2i(470,370))
func resize_map()->void:
 var d=AcceptDialog.new();d.title="Map dimensions • tiles are 40 world pixels";add_child(d);UI.apply(d);var b=VBoxContainer.new();d.add_child(b);var dimensions={"width":int(value.width),"height":int(value.height)};number(b,"Width",dimensions,"width",8,W.MAX_SIDE);number(b,"Length",dimensions,"height",8,W.MAX_SIDE)
 workshop.label(b,"Existing tiles are kept where they fit. Placements outside the new edges are removed.",15)
 d.confirmed.connect(func():
  var grid=[]
  for y in range(int(dimensions.height)):
   for x in range(int(dimensions.width)):grid.append(value.grid[y*int(value.width)+x] if x<int(value.width) and y<int(value.height) else 0)
  value.width=dimensions.width;value.height=dimensions.height;value.grid=grid;value.placements=value.placements.filter(func(p):return p.cell[0]<value.width and p.cell[1]<value.height)
  for field in ["spawn","exit"]:value[field]=[mini(value[field][0],value.width-1),mini(value[field][1],value.height-1)]
  changed();d.queue_free();render()
 );d.popup_centered(Vector2i(450,320))
func fresh()->void:
 preload("res://scripts/studio_examples.gd").confirm(self,func():value=W.realm() if kind=="realm" else W.object();changed();render();if kind=="realm":resize_map())
func finalize()->void:
 var issues=W.checks(value) if kind=="realm" else []
 if not issues.is_empty():status.text="\n".join(issues);return
 var issue=Library.add_world(kind,value)
 if not issue.is_empty():status.text=issue;return
 save_draft();finalized=true;render();status.text="Finalized • available in your saved projects and profile ZIP."
 preload("res://scripts/learning_store.gd").activity("Finalized "+kind,value.name)
 if kind=="realm":test()
func download()->void:
 var issue=W.validate(kind,value)
 if not issue.is_empty():status.text=issue;return
 workshop.write_download(JSON.stringify(value,"  "),value.name.validate_filename()+"."+kind+".json")
func import_file(text:String)->void:
 if transfer.mode=="png":
  if not W.png(text):status.text="Choose a PNG up to 256 × 256 / 128 KB.";return
  if upload=="object":value.image=text;value.layers=[]
  else:value.tiles[int(upload.split(":")[1])].image=text
  changed();render();return
 var parsed=JSON.parse_string(text);var issue=W.validate(kind,parsed)
 if not issue.is_empty():status.text=issue;return
 value=parsed;changed();render()
func environment_tools()->void:
 if not value.has("environment"):value.environment={"weather":"Clear","lighting":"Day","intensity":.5}
 for entry in [["Weather","weather",["Clear","Rain","Snow","Fireflies","Ash"]],["Lighting","lighting",["Day","Dusk","Night","Moonlight"]]]:
  workshop.label(tools,entry[0],15);var pick=OptionButton.new();pick.fit_to_longest_item=false;tools.add_child(pick)
  for name in entry[2]:pick.add_item(name)
  pick.select(maxi(0,entry[2].find(value.environment[entry[1]])))
  var key:String=entry[1];pick.item_selected.connect(func(n:int):value.environment[key]=pick.get_item_text(n);changed())
 var strength=HSlider.new();strength.min_value=0;strength.max_value=1;strength.step=.1;strength.value=float(value.environment.intensity);workshop.label(tools,"Weather intensity",15);tools.add_child(strength);strength.value_changed.connect(func(n:float):value.environment.intensity=n;changed())
 var goal=CheckButton.new();goal.text="Clear enemies before reaching exit";goal.button_pressed=value.get("clear_required",false);tools.add_child(goal);goal.toggled.connect(func(on:bool):value.clear_required=on;changed())
func end_test()->void:
 if not is_instance_valid(test_arena):return
 if value.tests.size()>=10:value.tests.pop_front()
 value.tests.append({"time":Time.get_datetime_string_from_system(true),"seconds":snappedf(test_arena.time,.1),"damage":snappedf(test_arena.damage,.1),"result":test_arena.result if not test_arena.result.is_empty() else "Ended by designer"});Library.add_world("realm",value);save_draft()
 if test_arena.time>=2:preload("res://scripts/studio_cycle.gd").test("realm",value,{"seconds":test_arena.time,"damage":test_arena.damage,"result":test_arena.result})
 test_layer.queue_free();test_arena=null
func test()->void:
 test_layer=CanvasLayer.new();test_layer.layer=80;add_child(test_layer)
 var shade=ColorRect.new();shade.color=Color("#071c27");shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);test_layer.add_child(shade)
 var frame=VBoxContainer.new();frame.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);frame.add_theme_constant_override("separation",0);test_layer.add_child(frame);UI.apply(frame)
 var top=PanelContainer.new();top.add_theme_stylebox_override("panel",UI.box("#102c38","#8b9473",0,8));frame.add_child(top)
 var row=HBoxContainer.new();top.add_child(row);workshop.label(row,value.name+" • PLAYTEST",20).size_flags_horizontal=Control.SIZE_EXPAND_FILL
 workshop.button(row,"Restart",func():test_arena.setup(value,test_hero))
 workshop.button(row,"End test",end_test)
 test_arena=preload("res://scripts/studio_realm_test.gd").new();test_arena.size_flags_vertical=Control.SIZE_EXPAND_FILL;test_arena.size_flags_horizontal=Control.SIZE_EXPAND_FILL;frame.add_child(test_arena)
 test_hero=(play_project if not play_project.is_empty() else workshop.project).duplicate(true);test_arena.setup(value,test_hero);test_arena.custom_minimum_size=Vector2.ZERO
 var bottom=PanelContainer.new();bottom.add_theme_stylebox_override("panel",UI.box("#102c38","#345763",0,8));frame.add_child(bottom);var actions=HBoxContainer.new();bottom.add_child(actions)
 workshop.label(actions,"WASD move • hold / release attacks • gold portal = exit",14).size_flags_horizontal=Control.SIZE_EXPAND_FILL
 for entry in [["←",Vector2.LEFT],["↑",Vector2.UP],["↓",Vector2.DOWN],["→",Vector2.RIGHT]]:
  var button=workshop.button(actions,entry[0],func():pass);button.button_down.connect(func():test_arena.touch_direction=entry[1]);button.button_up.connect(func():test_arena.touch_direction=Vector2.ZERO)
 for slot in ["primary","secondary","special"]:
  var button=workshop.button(actions,slot.capitalize(),func():pass);button.button_down.connect(func():test_arena.press(slot));button.button_up.connect(func():test_arena.release(slot))
func _unhandled_key_input(event:InputEvent)->void:
 if event is InputEventKey and event.pressed and not event.echo and event.keycode==KEY_ESCAPE and is_instance_valid(test_arena):end_test();get_viewport().set_input_as_handled()
func _process(dt:float)->void:
 var view=get_viewport().get_visible_rect().size;panel.size=Vector2(1170,730);var fit=minf(1,minf((view.x-20)/panel.size.x,(view.y-20)/panel.size.y));panel.scale=Vector2.ONE*fit;panel.position=(view-panel.size*fit)*.5
 if is_instance_valid(test_layer):
  for node in test_layer.get_children():
   if node.has_meta("realm_test_panel"):node.size=Vector2(1100,690);node.scale=Vector2.ONE*minf(1,minf((view.x-24)/1100,(view.y-24)/690));node.position=(view-node.size*node.scale)*.5
 if autosave>=0:autosave-=dt;if autosave<0:save_draft()

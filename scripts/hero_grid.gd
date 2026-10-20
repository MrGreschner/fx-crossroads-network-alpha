extends CanvasLayer
## Shared portrait selector. Browsing never commits a hero until Select is pressed.
var game:Node
var source:Node
var commit:Callable
var permission:Callable
var candidate=""
var custom=false
var community=false
var library=preload("res://scripts/hero_library.gd").new()
var panel:PanelContainer
var grid:GridContainer
var scroll:ScrollContainer
var info:Label
var select_button:Button
var search:LineEdit
var tiles:Dictionary={}
var shown:Array=[]
var tile_scale=1.0
var collection_picker:OptionButton
var title_label:Label
var close_control:Button
func open(owner:Node,current:String,callback:Callable,allow:Callable=Callable(),provider:Node=null)->void:
 game=owner;source=owner if provider==null else provider;commit=callback;permission=allow;candidate=current;custom=current.begins_with("custom_");community=current.begins_with("community_");layer=90;owner.add_child(self)
 var shade=ColorRect.new();shade.color=Color(0,0,0,.82);shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);add_child(shade)
 panel=PanelContainer.new();add_child(panel);preload("res://scripts/studio_ui.gd").apply(panel)
 var col=VBoxContainer.new();panel.add_child(col)
 var top=HBoxContainer.new();col.add_child(top)
 var title=Label.new();title_label=title;title.text="CHOOSE YOUR HERO";title.add_theme_font_size_override("font_size",22);title.size_flags_horizontal=Control.SIZE_EXPAND_FILL;top.add_child(title)
 var close_button=Button.new();close_control=close_button;close_button.text="Close";close_button.custom_minimum_size=Vector2(72,42);top.add_child(close_button);close_button.pressed.connect(close)
 var filters=HBoxContainer.new();col.add_child(filters)
 var collection=OptionButton.new();collection_picker=collection;collection.add_item("Official heroes");collection.add_item("Custom heroes");collection.add_item("Community heroes");collection.select(2 if community else 1 if custom else 0);collection.custom_minimum_size=Vector2(170,42);filters.add_child(collection);collection.item_selected.connect(func(index:int):custom=index==1;community=index==2;refresh())
 search=LineEdit.new();search.max_length=80;search.placeholder_text="Name or number";search.size_flags_horizontal=Control.SIZE_EXPAND_FILL;filters.add_child(search);search.text_changed.connect(func(_text:String):refresh())
 var typing=preload("res://scripts/mobile_text_entry.gd").new();search.add_child(typing);typing.setup(search,"search")
 scroll=ScrollContainer.new();scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;scroll.size_flags_vertical=Control.SIZE_EXPAND_FILL;col.add_child(scroll)
 grid=GridContainer.new();grid.size_flags_horizontal=Control.SIZE_EXPAND_FILL;grid.add_theme_constant_override("h_separation",8);grid.add_theme_constant_override("v_separation",8);scroll.add_child(grid);preload("res://scripts/touch_list_scroll.gd").attach(scroll)
 var bottom=HBoxContainer.new();col.add_child(bottom)
 info=Label.new();info.size_flags_horizontal=Control.SIZE_EXPAND_FILL;info.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;bottom.add_child(info)
 select_button=Button.new();select_button.text="Select";select_button.custom_minimum_size=Vector2(100,48);preload("res://scripts/studio_ui.gd").accent(select_button);bottom.add_child(select_button);select_button.pressed.connect(confirm)
 resize();refresh();preload("res://scripts/studio_ui.gd").enter(panel)
func resize()->void:
 var viewport=get_viewport().get_visible_rect().size
 panel.size=Vector2(minf(1100,viewport.x-24),minf(660,viewport.y-24));panel.position=(viewport-panel.size)*.5
 var next_scale=clampf(viewport.x/maxf(1,get_window().size.x),1,2)
 var changed=not is_equal_approx(next_scale,tile_scale)
 tile_scale=next_scale
 grid.columns=maxi(2,int((panel.size.x-40)/(90*tile_scale)))
 title_label.add_theme_font_size_override("font_size",int(22*tile_scale))
 for control in [close_control,collection_picker,search,select_button,info]:control.add_theme_font_size_override("font_size",int(17*tile_scale))
 close_control.custom_minimum_size=Vector2(72,42)*tile_scale
 collection_picker.custom_minimum_size=Vector2(170,42)*tile_scale
 select_button.custom_minimum_size=Vector2(100,48)*tile_scale
 if changed and is_instance_valid(search):refresh()
func refresh()->void:
 for child in grid.get_children():grid.remove_child(child);child.queue_free()
 tiles.clear();shown.clear();scroll.scroll_vertical=0
 var service=get_tree().root.get_node("FXCommunityHeroes");service.install(source)
 var ids:Array=source.characters.keys() if custom or community else JSON.parse_string(FileAccess.get_file_as_string("res://content/manifest.json")).get("characters",[])
 for raw in ids:
  var id=str(raw)
  if not source.characters.has(id):continue
  if community and not id.begins_with("community_"):continue
  if custom and not id.begins_with("custom_"):continue
  if not custom and not community and (id.begins_with("custom_") or id.begins_with("community_")):continue
  var hero:Dictionary=source.characters[id];var number=int(library.numbers.get(id,shown.size()+1));var query=search.text.strip_edges().to_lower()
  if not query.is_empty() and not str(hero.name).to_lower().contains(query) and query!=str(number):continue
  shown.append(id)
  var tile=Button.new();tile.custom_minimum_size=Vector2(80,96)*tile_scale;tile.size_flags_horizontal=Control.SIZE_EXPAND_FILL;tile.text="";tile.tooltip_text=str(hero.name);grid.add_child(tile)
  var contents=VBoxContainer.new();contents.mouse_filter=Control.MOUSE_FILTER_IGNORE;contents.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);contents.offset_left=6;contents.offset_right=-6;contents.offset_top=6;contents.offset_bottom=-6;tile.add_child(contents)
  var picture=TextureRect.new();picture.mouse_filter=Control.MOUSE_FILTER_IGNORE;picture.texture=source.art.get(str(hero.get("sprite",id))+"_idle");picture.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;picture.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;picture.custom_minimum_size=Vector2(56,56)*tile_scale;picture.size_flags_vertical=Control.SIZE_EXPAND_FILL;contents.add_child(picture)
  var caption=Label.new();caption.mouse_filter=Control.MOUSE_FILTER_IGNORE;caption.text="Community" if community else "Custom" if custom else str(number);caption.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;caption.add_theme_font_size_override("font_size",int(14*tile_scale));contents.add_child(caption)
  tile.pressed.connect(choose.bind(id));tiles[id]=tile
 if shown.is_empty():
  var empty=Label.new();empty.text="No approved community heroes yet. Use Refresh in Character Hall." if community else "No custom heroes saved yet. Create one in Crossroads Studio." if custom else "No matching heroes.";empty.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;grid.add_child(empty)
 update_info()
func choose(id:String)->void:candidate=id;update_info()
func update_info()->void:
 for id in tiles:tiles[id].add_theme_stylebox_override("normal",preload("res://scripts/studio_ui.gd").box("#365e64" if id==candidate else "#244854","#f3d18a" if id==candidate else "#345763"))
 var valid=source.characters.has(candidate) and candidate in shown
 var issue="Choose a portrait above."
 if valid:
  var hero:Dictionary=source.characters[candidate];var tags:Array=library.entry(candidate,hero).get("tags",[]).slice(0,2)
  if custom:tags=[str(hero.get("role",tags[0] if not tags.is_empty() else "Custom"))]
  issue=str(hero.name)+"\n"+" / ".join(tags)
  var blocked=reason(candidate)
  if not blocked.is_empty():issue+="\n"+blocked
 select_button.disabled=not valid or not reason(candidate).is_empty();info.text=issue
func reason(id:String)->String:return str(permission.call(id)) if permission.is_valid() else ""
func confirm()->void:
 if select_button.disabled:return
 var result=commit.call(candidate)
 if result is bool and not result:update_info();return
 close()
func close()->void:
 set_process_input(false);hide();queue_free()
func _process(_delta:float)->void:
 resize()
 if game.get("started")==true:close()
func _input(event:InputEvent)->void:
 if event is InputEventKey and event.pressed:
  if event.keycode==KEY_ESCAPE:
   close();get_viewport().set_input_as_handled()
  elif event.keycode in [KEY_ENTER,KEY_KP_ENTER] and not search.has_focus():
   confirm();get_viewport().set_input_as_handled()

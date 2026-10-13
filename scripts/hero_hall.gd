extends CanvasLayer
## Native, touch-scrollable roster with independent selection and portable favourites.
var grid_view_button:Button
var portrait_grid:Node
var game:Node
var library=preload("res://scripts/hero_library.gd").new()
var ability_cards:Dictionary={}
var right_scroller:ScrollContainer
var panel:PanelContainer
var rows:VBoxContainer
var details:VBoxContainer
var scroller:ScrollContainer
var count_label:Label
var role:="All"
var difficulty:="Any difficulty"
var query:=""
var favourites_only:=false
var was_open:=false
var custom_toggle:CheckButton
var custom_only:=false
var shown:Array=[]
var role_buttons:Dictionary={}
var favourite_on:Texture2D=preload("res://scripts/source_art.gd").texture("res://assets/ui/favourite_on.svg")
var favourite_off:Texture2D=preload("res://scripts/source_art.gd").texture("res://assets/ui/favourite_off.svg")
func setup(owner:Node)->void:
 game=owner;layer=28
 panel=PanelContainer.new();panel.size=Vector2(1120,660);add_child(panel);panel.visible=false
 var skin:=StyleBoxFlat.new();skin.bg_color=Color("#102c32");skin.border_color=Color("#d5b577");skin.set_border_width_all(2);skin.set_corner_radius_all(10)
 for edge in [SIDE_LEFT,SIDE_RIGHT,SIDE_TOP,SIDE_BOTTOM]:skin.set_content_margin(edge,18)
 panel.add_theme_stylebox_override("panel",skin)
 var col:=VBoxContainer.new();col.add_theme_constant_override("separation",8);panel.add_child(col)
 var top:=HBoxContainer.new();col.add_child(top);label(top,"CHARACTER HALL",27).size_flags_horizontal=Control.SIZE_EXPAND_FILL
 grid_view_button=button(panel,"Grid view",open_grid)
 for state in ["normal","hover","pressed","focus"]:
  var outline=preload("res://scripts/studio_ui.gd").box("#31525d" if state=="normal" else "#446974","#efd395",8,9);outline.set_border_width_all(2);grid_view_button.add_theme_stylebox_override(state,outline)
 grid_view_button.add_theme_color_override("font_color",Color("#fff0c6"))
 grid_view_button.tooltip_text="Choose a hero from portrait tiles"
 button(top,"Crossroads Studio",func():close(false);game.hero_workshop.open())
 button(top,"Continue",close);button(top,"Close",close)
 var filters:=HBoxContainer.new();col.add_child(filters)
 for tag in ["All","Melee","Ranged","Support","Control","Summoner"]:
  var b:=button(filters,tag,filter_role.bind(tag));b.toggle_mode=true;role_buttons[tag]=b
 var stars:=CheckButton.new();stars.text="Favourites";stars.toggled.connect(func(value:bool):favourites_only=value;refresh());filters.add_child(stars)
 var toggle=CheckButton.new();custom_toggle=toggle;toggle.text="Custom heroes";filters.add_child(toggle);toggle.toggled.connect(func(value:bool):custom_only=value;refresh())
 var search_row:=HBoxContainer.new();col.add_child(search_row)
 var search:=LineEdit.new();search.placeholder_text="Find a hero…";search.custom_minimum_size=Vector2(400,42);search.size_flags_horizontal=Control.SIZE_EXPAND_FILL;search.text_changed.connect(func(value:String):query=value;refresh());search_row.add_child(search)
 var skill:=OptionButton.new();skill.custom_minimum_size=Vector2(220,42);search_row.add_child(skill)
 for text in ["Any difficulty","Easy to learn","Some practice","Technical"]:skill.add_item(text)
 skill.item_selected.connect(func(index:int):difficulty=skill.get_item_text(index);refresh())
 count_label=label(search_row,"",16)
 var split:=HBoxContainer.new();split.add_theme_constant_override("separation",20);split.size_flags_vertical=Control.SIZE_EXPAND_FILL;col.add_child(split)
 scroller=ScrollContainer.new();scroller.custom_minimum_size=Vector2(395,350);scroller.size_flags_vertical=Control.SIZE_EXPAND_FILL;scroller.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;split.add_child(scroller)
 rows=VBoxContainer.new();rows.size_flags_horizontal=Control.SIZE_EXPAND_FILL;rows.add_theme_constant_override("separation",6);scroller.add_child(rows)
 var right:=ScrollContainer.new();right_scroller=right;right.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;right.size_flags_horizontal=Control.SIZE_EXPAND_FILL;right.size_flags_vertical=Control.SIZE_EXPAND_FILL;split.add_child(right)
 details=VBoxContainer.new();details.custom_minimum_size.x=600;details.size_flags_horizontal=Control.SIZE_EXPAND_FILL;details.add_theme_constant_override("separation",8);right.add_child(details)
 preload("res://scripts/touch_list_scroll.gd").attach(scroller);preload("res://scripts/touch_list_scroll.gd").attach(right_scroller)
 label(col,"Swipe lists to browse. Tap an ability for details; Story opens lore.",16)
func label(parent:Node,text:String,size:int=18)->Label:
 var l:=Label.new();l.text=text;l.add_theme_font_size_override("font_size",size);l.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;l.size_flags_horizontal=Control.SIZE_EXPAND_FILL;parent.add_child(l);return l
func button(parent:Node,text:String,call:Callable)->Button:
 var b:=Button.new();b.text=text;b.custom_minimum_size.y=40;b.add_theme_font_size_override("font_size",17);b.pressed.connect(call);parent.add_child(b);return b
func clear(node:Node)->void:
 for child in node.get_children():node.remove_child(child);child.queue_free()
func open_grid()->void:
 if is_instance_valid(portrait_grid):return
 portrait_grid=preload("res://scripts/hero_grid.gd").new()
 portrait_grid.open(game,game.selected_character,func(id:String):custom_only=id.begins_with("custom_");custom_toggle.set_pressed_no_signal(custom_only);select(id))
func test_hero()->void:
 close(false);game.start_training()
func close(apply_selection:bool=true)->void:
 game.menu="";game.mobile.reset_controls();Input.action_release("secondary");game.queue_redraw();panel.hide();was_open=false
 if apply_selection and game.practice and game.character_id!=game.selected_character:game.start_training(game.position_in_world)
func filter_role(value:String)->void:role=value;refresh()
func favourite(id:String)->void:
 var values:Array=game.legacy.data.get("favourites",[]).duplicate()
 if id in values:values.erase(id)
 else:values.append(id)
 game.legacy.data.favourites=values;game.legacy.save();refresh()
func select(id:String)->void:
 game.hero_preview=id;game.selected_character=id;game.mark_welcome("hero");game.save_profile();game.queue_redraw();refresh(false)
func refresh(reset_scroll:bool=true)->void:
 preload("res://scripts/studio_library.gd").install(game)
 var old:int=scroller.scroll_vertical
 clear(rows)
 shown=library.entries(game,role,difficulty,query,favourites_only)
 if custom_only:
  shown=[]
  for id in preload("res://scripts/studio_library.gd").load_data().heroes:
   var h:Dictionary=game.characters.get(id,{})
   if h.is_empty():continue
   if role!="All" and h.role!=role:continue
   if not query.is_empty() and not str(h.name).to_lower().contains(query.to_lower()):continue
   shown.append(id)
 count_label.text=str(shown.size())+" / "+str(game.characters.size())
 for tag in role_buttons:role_buttons[tag].set_pressed_no_signal(tag==role)
 if shown.is_empty():label(rows,"No matches. Try another filter or mark a favourite.",18)
 for id in shown:
  var h:Dictionary=game.characters[id];var info:Dictionary=library.entry(id,h);var card:=VBoxContainer.new();rows.add_child(card);var line:=HBoxContainer.new();card.add_child(line)
  var marked:bool=id in game.legacy.data.get("favourites",[])
  var star:=button(line,"",favourite.bind(id));star.custom_minimum_size.x=42;star.icon=favourite_on if marked else favourite_off;star.tooltip_text="Remove favourite" if marked else "Add favourite";star.toggle_mode=true;star.set_pressed_no_signal(marked)
  var b:=button(line,("Custom" if str(id).begins_with("custom_") else str(library.number(game,str(id))))+". "+str(h.name)+"\n"+str(info.role)+" • "+str(info.difficulty),select.bind(id));b.custom_minimum_size.y=62;b.size_flags_horizontal=Control.SIZE_EXPAND_FILL;b.alignment=HORIZONTAL_ALIGNMENT_LEFT;b.add_theme_font_size_override("font_size",16)
  if id==game.selected_character:b.modulate=Color("#ffe0a1");b.tooltip_text="Selected hero"
  var icon:Texture2D=game.art.get(str(h.get("sprite",id))+"_idle")
  if icon!=null:b.icon=icon;b.expand_icon=true;b.add_theme_constant_override("icon_max_width",36)
  var progress:Dictionary={"ratio":1.0,"label":"Local custom creation"} if str(id).begins_with("custom_") else library.progress(game,id);var small:=ProgressBar.new();small.custom_minimum_size.y=5;small.show_percentage=false;small.value=float(progress.ratio)*100;small.tooltip_text=str(progress.label);card.add_child(small)
 scroller.scroll_vertical=0 if reset_scroll else old
 render_details()
func render_details()->void:
 if custom_only:
  render_custom();return
 clear(details);ability_cards.clear();right_scroller.scroll_vertical=0
 var id:String=game.selected_character if not game.selected_character.begins_with("custom_") else "ram";var h:Dictionary=game.characters[id];var info:Dictionary=library.entry(id,h)
 var heading:=HBoxContainer.new();details.add_child(heading)
 var texture:Texture2D=game.art.get(str(h.get("sprite",id))+"_idle")
 if texture!=null:
  var pic:=TextureRect.new();pic.texture=texture;pic.custom_minimum_size=Vector2(48,56);pic.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;pic.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;heading.add_child(pic)
 var names:=VBoxContainer.new();names.size_flags_horizontal=Control.SIZE_EXPAND_FILL;heading.add_child(names);label(names,str(library.number(game,str(id)))+". "+str(h.name),22);label(names," • ".join(info.tags)+"  |  "+str(info.difficulty),14)
 var actions:=HBoxContainer.new();actions.add_theme_constant_override("separation",8);details.add_child(actions)
 var test:=button(actions,"Test hero",test_hero);test.custom_minimum_size=Vector2(140,38);test.tooltip_text="Try this hero at level 10 in the training yard"
 button(actions,"Compare heroes",func():var comparison=preload("res://scripts/hero_compare.gd").new();comparison.open(game))
 var story:=button(actions,"Story",func():show_story(id));story.custom_minimum_size=Vector2(90,38);story.tooltip_text="Who is "+str(h.name)+"?"
 label(details,"Health %s  •  Speed %s" % [h.max_health,h.speed],17)
 var home:String=str(info.get("home_realm",""))
 if not home.is_empty():story.tooltip_text+=" • "+str(game.realms.get(home,{}).get("name",home))
 label(details,str(info.get("summary","")),17)
 for kind in ["primary","secondary","passive","special"]:
  var tint:=Color({"primary":"#dda87c","secondary":"#8bbbd9","special":"#bba0df","passive":"#a8c99b"}[kind])
  var card:=VBoxContainer.new();card.add_theme_constant_override("separation",4);details.add_child(card)
  var title:String=kind.to_upper()+{"primary":" · LMB · Lv1","secondary":" · RMB · Lv3","passive":" · Lv5","special":" · Space · Lv6"}[kind]
  var ability_name:String=str(h.passive).split(":")[0] if kind=="passive" else str(h[kind].name)
  var brief:String=str(info.get("passive_brief","A passive bonus unlocked at level five.")) if kind=="passive" else library.ability_brief(h[kind],kind)
  var expanded:=Label.new();expanded.text=str(h.passive) if kind=="passive" else game.ability_info(h[kind],kind);expanded.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;expanded.add_theme_font_size_override("font_size",15);expanded.visible=false;expanded.mouse_filter=Control.MOUSE_FILTER_IGNORE
  var action:=button(card,title+"  |  "+ability_name+"\n"+brief,func():expanded.visible=not expanded.visible)
  action.custom_minimum_size.y=62;action.alignment=HORIZONTAL_ALIGNMENT_LEFT;action.add_theme_font_size_override("font_size",15);action.tooltip_text="Click / tap for full details";action.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS
  for state in ["normal","hover","pressed"]:
   var skin:=StyleBoxFlat.new();skin.bg_color=Color("#1b3943").lightened(.08 if state=="hover" else 0);skin.border_color=tint;skin.set_border_width_all(2);skin.set_corner_radius_all(7);skin.set_content_margin_all(8);action.add_theme_stylebox_override(state,skin)
  card.add_child(expanded);ability_cards[kind]={"button":action,"detail":expanded}
 label(details,"MASTERY • customise these abilities",20).modulate=Color("#f0d194")
 var progress:Dictionary=library.progress(game,id);label(details,str(progress.label),16)
 var bar:=ProgressBar.new();bar.value=float(progress.ratio)*100;bar.custom_minimum_size.y=12;bar.show_percentage=false;details.add_child(bar)
 if progress.has("detail"):label(details,str(progress.detail),15)
 for key in ["technique","final_technique"]:
  var choice:Dictionary=h.get("mastery",{}).get(key,{})
  label(details,str(choice.get("name",""))+" • "+str(choice.get("ability","")).capitalize(),17);label(details,str(choice.get("description","")),15)
 button(details,"View / equip mastery choices",func():close();game.legacy.open_hero(id))
func show_story(id:String)->void:
 var story:=AcceptDialog.new();story.title=str(game.characters[id].name)+" • Story";story.dialog_text=str(library.entry(id,game.characters[id]).get("lore","A traveler drawn to the Crossroads."));story.dialog_autowrap=true;add_child(story);story.confirmed.connect(story.queue_free);story.canceled.connect(story.queue_free);story.popup_centered(Vector2i(500,200))
func _process(_delta:float)->void:
 var open:bool=game.menu=="characters" and (game.mode=="town" or game.practice) and game.legacy.page.is_empty()
 panel.visible=open
 if open and not was_open:refresh()
 was_open=open
 if not open:return
 panel.size=Vector2(1120,660)
 var view:=get_viewport().get_visible_rect().size;var factor:=minf(1,minf((view.x-32)/1120,(view.y-24)/660))
 panel.scale=Vector2.ONE*maxf(.35,factor);panel.position=(view-panel.size*panel.scale)*.5
 grid_view_button.position=Vector2((panel.get_global_transform().affine_inverse()*role_buttons["Summoner"].get_global_transform().origin).x,18)
 grid_view_button.size=Vector2(role_buttons["Summoner"].size.x,40)
func handle_key(event:InputEvent)->bool:
 if is_instance_valid(portrait_grid):return true
 if not panel.visible or not event is InputEventKey or not event.pressed:return false
 if event.keycode in [KEY_ESCAPE,KEY_ENTER,KEY_KP_ENTER]:close();return true
 if event.keycode in [KEY_DOWN,KEY_UP]:scroller.scroll_vertical+=64 if event.keycode==KEY_DOWN else -64;return true
 return false

func render_custom()->void:
 clear(details)
 if shown.is_empty():
  label(details,"Your Custom Hall is ready for creations.",22)
  button(details,"Open Crossroads Studio",func():close(false);game.hero_workshop.open())
  label(details,"Import a friend's hero project in Studio → Hero Workshop → Open project, then Add to Custom Hall. Your profile ZIP carries the library.",17);return
 var id=game.selected_character if game.selected_character in shown else str(shown[0])
 var h:Dictionary=game.characters[id];var p:Dictionary=h.studio_project
 label(details,str(h.name)+" • Custom",24);label(details,str(p.hero.role)+" • "+str(p.hero.species)+"\n"+str(p.hero.lore),17)
 for kind in ["primary","secondary","passive","special"]:
  var text=preload("res://scripts/workshop_project.gd").PASSIVES.get(p.hero.passive,"") if kind=="passive" else str(p.hero[kind].name)+" • "+str(p.hero[kind].style)+" • "+str(p.hero[kind].damage)+" damage"
  label(details,kind.to_upper()+" • "+str(text),17)
 button(details,"Select hero",func():select(id))
 button(details,"Test in training yard",func():select(id);test_hero())
 button(details,"Compare heroes",func():var comparison=preload("res://scripts/hero_compare.gd").new();comparison.open(game))
 button(details,"Edit in Studio",func():close(false);game.hero_workshop.open();game.hero_workshop.project=p.duplicate(true);game.hero_workshop.hub.hide();game.hero_workshop.panel.show();game.hero_workshop.render())
 button(details,"Remove from this library",func():
  var data=preload("res://scripts/studio_library.gd").load_data();data.heroes.erase(id);preload("res://scripts/studio_library.gd").save_data(data)
  if game.selected_character==id:game.selected_character="ram";game.hero_preview="ram";game.save_profile()
  preload("res://scripts/studio_library.gd").install(game);refresh()
 )
 label(details,"Custom play is available in training and solo realms. Multiplayer hosts can allow customs: public builds need Forced Balance; private code rooms can allow experiments.",15)

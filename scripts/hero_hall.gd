extends CanvasLayer
## Native, touch-scrollable roster with independent selection and portable favourites.
const Roster=preload("res://scripts/hero_roster376.gd")
var info_panel:CanvasLayer
var grid_view_button:Button
var daily_hero_button:Button
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
var continue_button:Button
var role:="All"
var difficulty:="Any difficulty"
var query:=""
var favourites_only:=false
var was_open:=false
enum {OFFICIAL, EVENT, COMMUNITY, CUSTOM}
var collection := OFFICIAL
var collection_tabs: Dictionary = {}
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
 daily_hero_button=button(panel,"Hero of the day",func():preload("res://scripts/daily_hero.gd").open(self))
 var daily_id=preload("res://scripts/daily_hero.gd").id(game);daily_hero_button.icon=preload("res://scripts/daily_hero.gd").portrait(game,daily_id);daily_hero_button.expand_icon=true;daily_hero_button.add_theme_constant_override("icon_max_width",64);daily_hero_button.tooltip_text="Today: "+str(game.characters[daily_id].name)
 for state in ["normal","hover","pressed","focus"]:
  var outline=preload("res://scripts/studio_ui.gd").box("#31525d" if state=="normal" else "#446974","#efd395",8,9);outline.set_border_width_all(2);grid_view_button.add_theme_stylebox_override(state,outline)
 grid_view_button.add_theme_color_override("font_color",Color("#fff0c6"))
 grid_view_button.tooltip_text="Choose a hero from portrait tiles"
 var actions=VBoxContainer.new();actions.custom_minimum_size.x=300;top.add_child(actions)
 var utilities=HBoxContainer.new();actions.add_child(utilities)
 button(utilities,"Crossroads Studio",func():close(false);game.hero_workshop.open()).size_flags_horizontal=Control.SIZE_EXPAND_FILL
 button(utilities,"Close",close)
 var next=button(actions,"Continue with selected hero",continue_with_preview);continue_button=next;next.name="HallContinue";next.custom_minimum_size.y=50
 preload("res://scripts/studio_ui.gd").accent(next)
 var tabs:=HBoxContainer.new();tabs.add_theme_constant_override("separation",8);col.add_child(tabs)
 for i in 4:
  var tab:=button(tabs,["Official","Event","Community","Custom"][i],set_collection.bind(i))
  tab.toggle_mode=true;tab.size_flags_horizontal=Control.SIZE_EXPAND_FILL;tab.custom_minimum_size.y=34
  tab.add_theme_stylebox_override("pressed",preload("res://scripts/studio_ui.gd").box("#315c65","#efd395",6,6))
  collection_tabs[i]=tab
 var filters:=HBoxContainer.new();col.add_child(filters)
 for tag in ["All","Melee","Ranged","Support","Control","Summoner"]:
  var b:=button(filters,tag,filter_role.bind(tag));b.toggle_mode=true;role_buttons[tag]=b
 var stars:=CheckButton.new();stars.text="Favourites";stars.toggled.connect(func(value:bool):favourites_only=value;refresh());filters.add_child(stars)
 get_tree().root.get_node("FXCommunityHeroes").changed.connect(func():if is_instance_valid(panel) and panel.visible:refresh(false))
 var search_row:=HBoxContainer.new();col.add_child(search_row)
 var search:=LineEdit.new();search.placeholder_text="Find a hero…";search.custom_minimum_size=Vector2(400,42);search.size_flags_horizontal=Control.SIZE_EXPAND_FILL;search.text_changed.connect(func(value:String):query=value;refresh());search_row.add_child(search)
 var skill:=OptionButton.new();skill.custom_minimum_size=Vector2(220,42);search_row.add_child(skill)
 for text in ["Any difficulty","Easy to learn","Some practice","Technical"]:skill.add_item(text)
 skill.item_selected.connect(func(index:int):difficulty=skill.get_item_text(index);refresh())
 count_label=label(search_row,"",14)
 Roster.legend(col)
 var split:=HBoxContainer.new();split.add_theme_constant_override("separation",20);split.size_flags_vertical=Control.SIZE_EXPAND_FILL;col.add_child(split)
 scroller=ScrollContainer.new();scroller.custom_minimum_size=Vector2(395,260);scroller.size_flags_vertical=Control.SIZE_EXPAND_FILL;scroller.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;split.add_child(scroller)
 rows=VBoxContainer.new();rows.size_flags_horizontal=Control.SIZE_EXPAND_FILL;rows.add_theme_constant_override("separation",6);scroller.add_child(rows)
 var right:=ScrollContainer.new();right_scroller=right;right.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;right.size_flags_horizontal=Control.SIZE_EXPAND_FILL;right.size_flags_vertical=Control.SIZE_EXPAND_FILL;split.add_child(right)
 details=VBoxContainer.new();details.custom_minimum_size.x=600;details.size_flags_horizontal=Control.SIZE_EXPAND_FILL;details.add_theme_constant_override("separation",8);right.add_child(details)
 preload("res://scripts/touch_list_scroll.gd").attach(scroller);preload("res://scripts/touch_list_scroll.gd").attach(right_scroller)
 label(col,"Gold marks an available unlock mission. Unlock a hero to play or train with them.",14)
func label(parent:Node,text:String,size:int=18)->Label:
 var l:=Label.new();l.text=text;l.add_theme_font_size_override("font_size",size);l.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;l.size_flags_horizontal=Control.SIZE_EXPAND_FILL;parent.add_child(l);return l
func button(parent:Node,text:String,call:Callable)->Button:
 var b:=Button.new();b.text=text;b.custom_minimum_size.y=40;b.add_theme_font_size_override("font_size",17);b.pressed.connect(call);parent.add_child(b);return b
func clear(node:Node)->void:
 for child in node.get_children():node.remove_child(child);child.queue_free()
func open_grid()->void:
 if is_instance_valid(portrait_grid):return
 portrait_grid=preload("res://scripts/hero_grid.gd").new()
 portrait_grid.browse_locked=true
 portrait_grid.open(game,game.selected_character,func(id:String):collection=collection_for(id);select(id))
func collection_for(id:String)->int:
 if id in game.manifest.get("event_heroes",[]):return EVENT
 if id.begins_with("community_"):return COMMUNITY
 if id.begins_with("custom_"):return CUSTOM
 return OFFICIAL
func set_collection(value:int)->void:
 collection=value
 refresh()
func preview_id()->String:
 if game.hero_preview in shown:return str(game.hero_preview)
 if game.selected_character in shown:return game.selected_character
 for id in shown:
  if bool(game.characters[id].get("event_active",true)):return str(id)
 return str(shown[0]) if not shown.is_empty() else ""
func continue_with_preview()->void:
 var id:=preview_id()
 if id.is_empty() or not bool(game.characters[id].get("event_active",true)):return
 if not preload("res://scripts/hero_unlocks371.gd").owned(game.legacy,id):return
 if id!=game.selected_character:select(id)
 close()
func test_hero()->void:
 var id:=preview_id()
 if id.is_empty() or not Roster.can_test(game,id):return
 game.selected_character=id;game.hero=game.characters[id].duplicate(true)
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
 if not game.characters.has(id):return
 game.hero_preview=id
 if not bool(game.characters[id].get("event_active",true)):refresh(false);return
 if not preload("res://scripts/hero_unlocks371.gd").owned(game.legacy,id):refresh(false);return
 game.selected_character=id;game.hero=game.characters[id].duplicate(true)
 if not game.practice:game.character_id=id
 if game.studio_live!=null:game.studio_live.last_hero="";game.studio_live.hide()
 game.mark_welcome("hero");game.save_profile();game.queue_redraw();refresh(false)
func refresh(reset_scroll:bool=true)->void:
 preload("res://scripts/studio_library.gd").install(game)
 var old:int=scroller.scroll_vertical
 clear(rows)
 var ids: Array = game.manifest.get("characters",[]) if collection==OFFICIAL else game.manifest.get("event_heroes",[]) if collection==EVENT else game.characters.keys().filter(func(id):return collection_for(str(id))==collection)
 if collection==EVENT:label(rows,"Winter Holiday • Active   /   Halloween • Returns for Halloween",15)
 shown=[]
 for id in ids:
  if not game.characters.has(id):continue
  var h:Dictionary=game.characters[id]
  var info:Dictionary=library.entry(id,h)
  if role!="All" and role not in info.tags and role!=str(info.role) and role!=str(h.get("role","")):continue
  if difficulty!="Any difficulty" and difficulty!=info.difficulty:continue
  if not query.strip_edges().is_empty() and not str(h.name).to_lower().contains(query.strip_edges().to_lower()) and (collection!=OFFICIAL or query.strip_edges()!=str(library.number(game,str(id)))):continue
  if favourites_only and id not in game.legacy.data.get("favourites",[]):continue
  shown.append(id)
 var favs:Array=game.legacy.data.get("favourites",[])
 shown=shown.filter(func(id):return id in favs)+shown.filter(func(id):return id not in favs)
 count_label.text="%d / %d heroes • %d unlocked" % [shown.size(),ids.size(),shown.filter(func(id):return preload("res://scripts/hero_unlocks371.gd").owned(game.legacy,str(id))).size()]
 for tab in collection_tabs:collection_tabs[tab].set_pressed_no_signal(tab==collection)
 var preview:=preview_id()
 continue_button.disabled=preview.is_empty() or not bool(game.characters[preview].get("event_active",true)) or not preload("res://scripts/hero_unlocks371.gd").owned(game.legacy,preview)
 for tag in role_buttons:role_buttons[tag].set_pressed_no_signal(tag==role)
 if shown.is_empty():label(rows,"No matches. Try another filter or mark a favourite.",18)
 for id in shown:
  var h:Dictionary=game.characters[id];var info:Dictionary=library.entry(id,h);var card:=VBoxContainer.new();rows.add_child(card);var line:=HBoxContainer.new();card.add_child(line)
  var marked:bool=id in game.legacy.data.get("favourites",[])
  var star:=button(line,"",favourite.bind(id));star.custom_minimum_size.x=42;star.icon=favourite_on if marked else favourite_off;star.tooltip_text="Remove favourite" if marked else "Add favourite";star.toggle_mode=true;star.set_pressed_no_signal(marked)
  var b:=button(line,("Community" if str(id).begins_with("community_") else "Custom" if str(id).begins_with("custom_") else str(library.number(game,str(id))))+". "+str(h.name)+"\n"+str(info.role)+" • "+str(info.difficulty),select.bind(id));b.custom_minimum_size.y=96;b.clip_text=true;b.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS;b.size_flags_horizontal=Control.SIZE_EXPAND_FILL;b.alignment=HORIZONTAL_ALIGNMENT_LEFT;b.add_theme_font_size_override("font_size",16)
  if collection==EVENT:
   b.text=str(h.name)+"\n"+str(h.event)+(" • Active" if h.event_active else " • Inactive");b.disabled=not h.event_active
  var access=Roster.state(game,str(id));Roster.style(b,access,id==preview);b.name="HeroRow_"+str(id);b.set_meta("hero_id",id);b.tooltip_text=str(h.name)+" • "+Roster.description(game,str(id))
  var icon:Texture2D=Roster.portrait(game,str(id))
  if icon!=null:b.icon=icon;b.expand_icon=true;b.add_theme_constant_override("icon_max_width",64)
  var progress:Dictionary={"ratio":1.0,"label":"Local custom creation"} if collection==CUSTOM else {"ratio":1.0,"label":"Published community hero"} if collection==COMMUNITY else library.progress(game,id);var small:=ProgressBar.new();small.custom_minimum_size.y=5;small.show_percentage=false;small.value=float(progress.ratio)*100;small.tooltip_text=str(progress.label);small.visible=access==Roster.OWNED;card.add_child(small)
 scroller.scroll_vertical=0 if reset_scroll else old
 render_details()
func render_details()->void:
 right_scroller.scroll_vertical=0
 ability_cards.clear()
 if collection in [COMMUNITY,CUSTOM]:
  render_custom();return
 clear(details);ability_cards.clear();right_scroller.scroll_vertical=0
 if shown.is_empty():clear(details);return
 var id:=preview_id()
 var h:Dictionary=game.characters[id];var info:Dictionary=library.entry(id,h)
 var overview=VBoxContainer.new();overview.name="HeroOverview";overview.add_theme_constant_override("separation",7);details.add_child(overview)
 var intro=VBoxContainer.new();intro.name="HeroIdentity";intro.size_flags_horizontal=Control.SIZE_EXPAND_FILL;overview.add_child(intro)
 var heading:=HBoxContainer.new();intro.add_child(heading)
 var texture:Texture2D=Roster.portrait(game,str(id))
 if texture!=null:
  var pic:=TextureRect.new();pic.texture=texture;pic.custom_minimum_size=Vector2(72,72);pic.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;pic.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;heading.add_child(pic)
 var names:=VBoxContainer.new();names.size_flags_horizontal=Control.SIZE_EXPAND_FILL;heading.add_child(names);label(names,(str(library.number(game,str(id)))+". " if collection==OFFICIAL else "")+str(h.name),22);label(names,str(info.difficulty)+" • "+str(h.get("event",info.role)),13)
 var actions:=HFlowContainer.new();actions.add_theme_constant_override("separation",5);names.add_child(actions)
 var test:=button(actions,"Test hero",test_hero);test.custom_minimum_size=Vector2(82,30);test.add_theme_font_size_override("font_size",13);test.name="HallTestHero";test.disabled=not Roster.can_test(game,id);test.tooltip_text="Train at level 10 with this unlocked hero" if not test.disabled else "This event is inactive" if not bool(h.get("event_active",true)) else "Unlock this hero before training"
 var compare=button(actions,"Compare heroes",func():var comparison=preload("res://scripts/hero_compare.gd").new();comparison.open(game));compare.custom_minimum_size=Vector2(108,30);compare.add_theme_font_size_override("font_size",13)
 var story:=button(actions,"Story",func():show_story(id));story.custom_minimum_size=Vector2(52,30);story.add_theme_font_size_override("font_size",13);story.tooltip_text="Who is "+str(h.name)+"?"
 if not preload("res://scripts/hero_unlocks371.gd").owned(game.legacy,id):
  label(overview,Roster.description(game,id),14).modulate=Roster.colour(Roster.state(game,id))
  if id in preload("res://scripts/hero_unlocks371.gd").ACTIVITY_IDS:button(actions,"View goal",func():preload("res://scripts/hero_goals372.gd").open(game,id))
  elif preload("res://scripts/hero_journeys373.gd").catalog().has(id):button(actions,"View journey",func():preload("res://scripts/hero_journeys373.gd").open(game,id))
  else:button(actions,"View challenge",func():preload("res://scripts/hero_unlocks371.gd").open_hall(game))
  if Roster.state(game,id)==Roster.READY:
   var mission=actions.get_child(actions.get_child_count()-1);mission.name="HallUnlockMission";mission.custom_minimum_size.y=30;mission.add_theme_font_size_override("font_size",13);Roster.style(mission,Roster.READY)
 else:
  label(overview,Roster.description(game,id),13).modulate=Roster.colour(Roster.state(game,id))
 preload("res://scripts/hero_stat_bars.gd").add_to(overview,h)
 var home:String=str(info.get("home_realm",""))
 if not home.is_empty():story.tooltip_text+=" • "+str(game.realms.get(home,{}).get("name",home))
 for kind in ["primary","secondary","passive","special"]:
  var tint:=Color({"primary":"#dda87c","secondary":"#8bbbd9","special":"#bba0df","passive":"#a8c99b"}[kind])
  var card:=VBoxContainer.new();card.add_theme_constant_override("separation",4);details.add_child(card)
  var title:String=kind.to_upper()+{"primary":" · LMB · Lv1","secondary":" · RMB · Lv3","passive":" · Lv5","special":" · Space · Lv6"}[kind]
  var ability_name:String=str(h.passive).split(":")[0] if kind=="passive" else str(h[kind].name)
  var brief:String=str(info.get("passive_brief","A passive bonus unlocked at level five.")) if kind=="passive" else library.ability_brief(h[kind],kind)
  var expanded:=Label.new();expanded.text=str(h.passive) if kind=="passive" else game.ability_info(h[kind],kind);expanded.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;expanded.add_theme_font_size_override("font_size",15);expanded.visible=false;expanded.mouse_filter=Control.MOUSE_FILTER_IGNORE
  var action:=button(card,"",func():show_ability(id,kind,ability_name,expanded.text))
  var line=HBoxContainer.new();line.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);line.offset_left=9;line.offset_right=-9;line.offset_top=5;line.offset_bottom=-5;line.mouse_filter=Control.MOUSE_FILTER_IGNORE;action.add_child(line)
  var copy=Label.new();copy.text=title+"  |  "+ability_name+"\n"+brief;copy.add_theme_font_size_override("font_size",15);copy.size_flags_horizontal=Control.SIZE_EXPAND_FILL;copy.clip_text=true;copy.mouse_filter=Control.MOUSE_FILTER_IGNORE;line.add_child(copy)
  var more=Label.new();more.text="Tap for details  ›" if game.mobile.enabled else "Click for details  ›";more.add_theme_font_size_override("font_size",12);more.modulate=Color("#efd6a0");more.mouse_filter=Control.MOUSE_FILTER_IGNORE;line.add_child(more)
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
 if is_instance_valid(info_panel):return
 var h:Dictionary=game.characters[id];var info:Dictionary=library.entry(id,h)
 info_panel=preload("res://scripts/hero_info_panel320.gd").new()
 info_panel.open(self,str(h.name),str(info.get("role",""))+" • "+str(info.get("difficulty","")),str(info.get("lore",h.get("studio_project",{}).get("hero",{}).get("lore",h.get("lore","A traveler drawn to the Crossroads.")))),preload("res://scripts/hero_portrait.gd").texture(game,id))
 info_panel.dismissed.connect(func():info_panel=null)
func _process(_delta:float)->void:
 var open:bool=game.menu=="characters" and (game.mode=="town" or game.practice) and game.legacy.page.is_empty()
 panel.visible=open
 if open and not was_open:collection=collection_for(game.selected_character);refresh()
 was_open=open
 if not open:return
 panel.size=Vector2(1120,660)
 var view:=get_viewport().get_visible_rect().size;var factor:=minf(1,minf((view.x-32)/1120,(view.y-24)/660))
 panel.scale=Vector2.ONE*maxf(.35,factor);panel.position=(view-panel.size*panel.scale)*.5
 grid_view_button.position=Vector2(315,18)
 grid_view_button.size=Vector2(145,64)
 daily_hero_button.position=grid_view_button.position+Vector2(grid_view_button.size.x+10,0);daily_hero_button.size=Vector2(260,64)
func handle_key(event:InputEvent)->bool:
 if is_instance_valid(info_panel):
  if event is InputEventKey and event.pressed and event.keycode==KEY_ESCAPE:info_panel.close()
  return true
 if is_instance_valid(portrait_grid):return true
 if not panel.visible or not event is InputEventKey or not event.pressed:return false
 if event.keycode==KEY_ESCAPE:close();return true
 if event.keycode in [KEY_ENTER,KEY_KP_ENTER]:continue_with_preview();return true
 if event.keycode in [KEY_DOWN,KEY_UP]:scroller.scroll_vertical+=64 if event.keycode==KEY_DOWN else -64;return true
 return false

func render_custom()->void:
 clear(details)
 if shown.is_empty():
  label(details,"Approved creations appear here after admin review." if collection==COMMUNITY else "Your Custom Hall is ready for creations.",22)
  if collection==COMMUNITY:
   var service=get_tree().root.get_node("FXCommunityHeroes")
   label(details,service.status,16);button(details,"Refresh community",service.refresh);return
  button(details,"Open Crossroads Studio",func():close(false);game.hero_workshop.open())
  label(details,"Import a friend's hero project in Studio → Hero Workshop → Open project, then Add to Custom Hall. Your profile ZIP carries the library.",17);return
 var id:=preview_id()
 var h:Dictionary=game.characters[id];var p:Dictionary=h.studio_project
 var identity:=HBoxContainer.new();details.add_child(identity)
 var pic:=TextureRect.new();pic.texture=preload("res://scripts/hero_portrait.gd").texture(game,id);pic.custom_minimum_size=Vector2(72,72);pic.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;pic.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;identity.add_child(pic)
 var names:=VBoxContainer.new();names.size_flags_horizontal=Control.SIZE_EXPAND_FILL;identity.add_child(names)
 label(names,str(h.name),22)
 label(names,str(p.hero.role)+(" • Community • by "+str(h.get("community_author","Creator")) if collection==COMMUNITY else " • Custom"),15)
 button(names,"Story",func():show_story(id))
 preload("res://scripts/hero_stat_bars.gd").add_to(details,h)
 for kind in ["primary","secondary","passive","special"]:
  var text=preload("res://scripts/workshop_project.gd").PASSIVES.get(p.hero.passive,"") if kind=="passive" else str(p.hero[kind].name)+" • "+str(p.hero[kind].style)+" • "+str(p.hero[kind].damage)+" damage"
  label(details,kind.to_upper()+" • "+str(text),17)
 button(details,"Select hero",func():select(id))
 button(details,"Test in training yard",func():select(id);test_hero())
 button(details,"Compare heroes",func():var comparison=preload("res://scripts/hero_compare.gd").new();comparison.open(game))
 if collection==COMMUNITY:
  var service=get_tree().root.get_node("FXCommunityHeroes")
  button(details,"Refresh community",service.refresh)
  label(details,"Published by the community and approved for official play.",16);return
 button(details,"Edit in Studio",func():close(false);game.hero_workshop.open();game.hero_workshop.project=p.duplicate(true);game.hero_workshop.hub.hide();game.hero_workshop.panel.show();game.hero_workshop.render())
 button(details,"Remove from this library",func():
  var data=preload("res://scripts/studio_library.gd").load_data();data.heroes.erase(id);preload("res://scripts/studio_library.gd").save_data(data)
  if game.selected_character==id:game.selected_character="ram";game.hero_preview="ram";game.save_profile()
  preload("res://scripts/studio_library.gd").install(game);refresh()
 )
 label(details,"Custom play is available in training and solo realms. Multiplayer hosts can allow customs: public builds need Forced Balance; private code rooms can allow experiments.",15)

func show_ability(id:String,kind:String,ability_name:String,body:String)->void:
 if is_instance_valid(info_panel):return
 info_panel=preload("res://scripts/hero_info_panel320.gd").new()
 info_panel.open(self,ability_name,str(game.characters[id].name)+" • "+kind.capitalize(),body,preload("res://scripts/hero_portrait.gd").texture(game,id),"HERO ABILITIES")
 info_panel.dismissed.connect(func():info_panel=null)

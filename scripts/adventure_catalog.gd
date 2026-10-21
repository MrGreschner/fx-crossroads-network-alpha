extends CanvasLayer
## Native scrollbars/buttons and per-realm encounter portraits in portable profiles.
const MENUS=["portal","wayfinder","supplies","merchant","food"]
var game:Node
var panel:PanelContainer
var rows:VBoxContainer
var detail:VBoxContainer
var scroll:ScrollContainer
var status:Label
var enter:Button
var context:=""
var refund_button:Button
var category:OptionButton
var route_picker:OptionButton
var selected:=0
var entries:Array=[]
var tick:=0.0
var portraits:Dictionary={}
var bosses:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://content/encounter_bosses.json"))
var rosters:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://content/encounter_rosters.json"))
func setup(owner:Node)->void:
 game=owner;layer=34
 panel=PanelContainer.new();panel.size=Vector2(1120,610);panel.visible=false;add_child(panel)
 var skin:=StyleBoxFlat.new();skin.bg_color=Color("#142e35");skin.border_color=Color("#cab68b");skin.set_border_width_all(2);skin.set_corner_radius_all(12);skin.set_content_margin_all(18);panel.add_theme_stylebox_override("panel",skin)
 var col:=VBoxContainer.new();col.add_theme_constant_override("separation",12);panel.add_child(col)
 var head:=HBoxContainer.new();col.add_child(head);status=label(head,"",25);status.size_flags_horizontal=Control.SIZE_EXPAND_FILL;route_picker=OptionButton.new();head.add_child(route_picker)
 for name in game.town_upgrade.FILTERS:route_picker.add_item(name)
 route_picker.item_selected.connect(func(index:int):game.town_upgrade.route_filter=index;selected=0;game.list_preview[context]=0;render())
 category=OptionButton.new();category.add_item("Equipment • 3 slots");category.add_item("Consumables • 1 slot");head.add_child(category)
 category.item_selected.connect(func(index:int):game.supply_category="consumables" if index==1 else "equipment";game.list_preview[context]=0;render())
 button(head,"Close",close)
 var split:=HBoxContainer.new();split.add_theme_constant_override("separation",24);split.size_flags_vertical=Control.SIZE_EXPAND_FILL;col.add_child(split)
 scroll=ScrollContainer.new();scroll.custom_minimum_size=Vector2(390,0);scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;split.add_child(scroll)
 rows=VBoxContainer.new();rows.size_flags_horizontal=Control.SIZE_EXPAND_FILL;rows.add_theme_constant_override("separation",6);scroll.add_child(rows)
 var right:=ScrollContainer.new();right.size_flags_horizontal=Control.SIZE_EXPAND_FILL;right.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;split.add_child(right)
 detail=VBoxContainer.new();detail.size_flags_horizontal=Control.SIZE_EXPAND_FILL;detail.add_theme_constant_override("separation",10);right.add_child(detail)
 preload("res://scripts/touch_list_scroll.gd").attach(scroll);preload("res://scripts/touch_list_scroll.gd").attach(right)
 var foot:=HBoxContainer.new();col.add_child(foot)
 refund_button=button(foot,"Refund food / items",refund)
 enter=button(foot,"ENTER",confirm);enter.size_flags_horizontal=Control.SIZE_EXPAND_FILL
 button(foot,"Co-op realms",func():game.menu="";game.get_tree().root.set_meta("fx_mode","coop");game.get_tree().root.set_meta("fx_hero",game.selected_character);game.get_tree().change_scene_to_file("res://network/client.tscn")).name="Coop"
func label(parent:Node,t:String,size:int=18)->Label:
 var l:=Label.new();l.text=t;l.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;l.add_theme_font_size_override("font_size",size);parent.add_child(l);return l
func button(parent:Node,t:String,action:Callable)->Button:
 var b:=Button.new();b.text=t;b.custom_minimum_size.y=44;b.add_theme_font_size_override("font_size",17);b.pressed.connect(action);parent.add_child(b);return b
func clear(parent:Node)->void:
 for child in parent.get_children():parent.remove_child(child);child.queue_free()
func close()->void:game.menu="";game.mobile.reset_controls();context="";panel.hide()
func data(id:String)->Dictionary:return game.realms.get(id,{}) if context in ["portal","wayfinder"] else game.provisions.defs.get(id,{}) if context=="food" else game.items.get(id,{})
func render()->void:
 category.visible=context in ["supplies","merchant"];category.select(1 if game.supply_category=="consumables" else 0)
 route_picker.visible=context=="wayfinder"
 refund_button.visible=context in ["food","supplies"]
 entries=game.list_entries();selected=clampi(int(game.list_preview.get(context,0)),0,maxi(0,entries.size()-1));clear(rows)
 status.text={"portal":"CHOOSE A REALM","wayfinder":"WAYFINDER ROUTES","supplies":"SUPPLY VENDOR","merchant":"REALM MERCHANT","food":"FOOD STAND"}[context]+"  •  "+str(game.gold)+" CC"
 panel.find_child("Coop",true,false).visible=context in ["portal","wayfinder"]
 for n in entries.size():
  var id:=str(entries[n]);var spec:=data(id);var b:=button(rows,("LOCKED • " if context in ["portal","wayfinder"] and not preload("res://scripts/realm_access.gd").unlocked(game.legacy,id) else "")+str(spec.get("name",id)),select.bind(n));b.toggle_mode=true;b.set_pressed_no_signal(n==selected);b.alignment=HORIZONTAL_ALIGNMENT_LEFT;b.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS;b.tooltip_text=str(spec.get("name",id))
  if context in ["supplies","merchant","food"]:b.icon=preload("res://scripts/item_icons.gd").texture(id);b.add_theme_constant_override("icon_max_width",42)
  if context in ["portal","wayfinder"] and game.legacy.realm_mastered(id):b.icon=preload("res://scripts/ui_reward_icons.gd").texture();b.add_theme_constant_override("icon_max_width",22)
 render_detail()
func select(index:int)->void:
 selected=index;game.list_preview[context]=index
 for n in rows.get_child_count():rows.get_child(n).set_pressed_no_signal(n==selected)
 render_detail()
func render_detail()->void:
 clear(detail)
 if entries.is_empty():enter.disabled=true;return
 var id:=str(entries[selected]);var spec:=data(id);label(detail,str(spec.get("name",id)),27).modulate=Color("#edd19b")
 if context in ["supplies","merchant","food"]:
  var icon=TextureRect.new();icon.texture=preload("res://scripts/item_icons.gd").texture(id);icon.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;icon.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;icon.custom_minimum_size=Vector2(110,110);detail.add_child(icon)
 label(detail,str(spec.get("description","Explore, fight and watch for attack warnings.")),19)
 if context in ["portal","wayfinder"]:
  var difficulty:=label(detail,str(spec.get("difficulty_label",""))+" • "+str(game.legacy.realm_clears(id))+" clears",20)
  difficulty.modulate=difficulty_color(str(spec.get("difficulty_label","")))
  label(detail,"Encounter journal • meet an enemy here to reveal its portrait",16).modulate=Color("#b4cbd1")
  var grid:=GridContainer.new();grid.columns=5;grid.add_theme_constant_override("h_separation",8);grid.add_theme_constant_override("v_separation",8);detail.add_child(grid)
  var boss_grid:GridContainer
  for kind in roster(id):
   var target_grid:=grid
   if is_boss(id,str(kind)):
    if boss_grid==null:
     label(detail,"BOSSES",16).modulate=Color("#efd09c")
     boss_grid=GridContainer.new();boss_grid.columns=5;boss_grid.add_theme_constant_override("h_separation",8);boss_grid.add_theme_constant_override("v_separation",8);detail.add_child(boss_grid)
    target_grid=boss_grid
   var known:bool=str(kind) in game.legacy.data.get("encounters",{}).get(id,[])
   var box:=PanelContainer.new();box.custom_minimum_size=Vector2(102,102);target_grid.add_child(box)
   var skin:=StyleBoxFlat.new();skin.bg_color=Color("#493f37") if is_boss(id,str(kind)) else Color("#24434a");skin.set_corner_radius_all(6);
   if is_boss(id,str(kind)):skin.border_color=Color("#c5a169");skin.set_border_width_all(1)
   box.add_theme_stylebox_override("panel",skin)
   box.tooltip_text=enemy_name(id,str(kind)) if known else "Not encountered in this realm yet"
   var column:=VBoxContainer.new();column.custom_minimum_size.x=102;box.add_child(column)
   var texture:Texture2D=portrait(id,str(kind)) if known else null
   if texture!=null:
    var image:=TextureRect.new();image.texture=texture;image.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;image.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;image.custom_minimum_size=Vector2(96,64);column.add_child(image)
   else:
    var l:=label(column,"?" if not known else "Seen",24);l.custom_minimum_size.y=64;l.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;l.vertical_alignment=VERTICAL_ALIGNMENT_CENTER
   var caption:=label(column,enemy_name(id,str(kind)) if known else "Unknown",13);caption.custom_minimum_size.x=102;caption.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
  enter.disabled=not preload("res://scripts/realm_access.gd").unlocked(game.legacy,id)
  enter.text="REALM LOCKED" if enter.disabled else "ENTER REALM • Enter key"
  if enter.disabled:label(detail,preload("res://scripts/realm_access.gd").hint(game.legacy,id),21).modulate=Color("#f4ca82")
 else:
  var price:int=preload("res://scripts/supply_slots.gd").price(spec,game.legacy)
  label(detail,"Cost: "+str(price)+" CC",22).modulate=Color("#edd19b")
  label(detail,"Packed food: "+game.provisions.name_of(game.provisions.packed) if context=="food" else "Your pack: "+str(game.inventory if context=="merchant" else game.loadout)+" • 3 equipment + 1 consumable",18)
  enter.text=("BUY FOOD" if context=="food" else "BUY ITEM")+" • Enter key"
  var packed:Array=game.inventory if context=="merchant" else game.loadout
  enter.disabled=game.gold<price or (not game.provisions.packed.is_empty() if context=="food" else not preload("res://scripts/supply_slots.gd").can_add(packed,id,game.items))
 label(detail,"Select a row, then confirm using the button or Enter. Swipe anywhere on a list to scroll, or use the mouse wheel.",15).modulate=Color("#abc5cc")
 if game.message_time>0:label(detail,game.message,16).modulate=Color("#e8daaa")
func confirm()->void:
 if enter.disabled:return
 game.list_preview[context]=selected
 var before:int=game.gold;var name:=str(data(str(entries[selected])).get("name",entries[selected]))
 game.confirm_list_entry()
 if game.menu in MENUS:
  if game.gold<before:game.message="Packed "+name+" • paid "+str(before-game.gold)+" CC.";game.message_time=4
  render()
func refund()->void:
 if context=="food":game.provisions.refund()
 elif context=="supplies":
  preload("res://scripts/supply_slots.gd").refund(game)
 render()
func key(event:InputEvent)->void:
 if game.menu in MENUS and context!=game.menu:context=game.menu;render()
 if not event is InputEventKey or not event.pressed or event.echo:return
 match event.keycode:
  KEY_ENTER,KEY_KP_ENTER:confirm()
  KEY_ESCAPE:close()
  KEY_UP,KEY_DOWN:
   if entries.is_empty():return
   select(clampi(selected+(-1 if event.keycode==KEY_UP else 1),0,maxi(0,entries.size()-1)));scroll.ensure_control_visible(rows.get_child(selected))
  KEY_BACKSPACE:refund()
  KEY_LEFT,KEY_RIGHT:
   if context=="wayfinder":game.town_upgrade.route_filter=posmod(game.town_upgrade.route_filter+(-1 if event.keycode==KEY_LEFT else 1),4);game.list_preview[context]=0;route_picker.select(game.town_upgrade.route_filter);render()
 get_viewport().set_input_as_handled()
func collect(value:Variant,result:Array)->void:
 if value is Dictionary:
  for key in value:
   if str(key) in ["type","boss_type","enemy","enemy_type"] and str(value[key]) in game.enemy_types and str(value[key]) not in result:result.append(str(value[key]))
   else:collect(value[key],result)
 elif value is Array:
  for child in value:collect(child,result)
func roster(id:String)->Array:
 var result:Array=rosters.get(id,[]).duplicate();collect(game.realms.get(id,{}),result)
 for kind in bosses.get(id,[]):
  if kind not in result:result.append(kind)
 for path in ["res://content/campaigns/"+id+"_paths.json","res://content/campaigns/"+id+".json","res://content/quests/"+id+".json"]:
  if FileAccess.file_exists(path):collect(JSON.parse_string(FileAccess.get_file_as_string(path)),result)
 var boss:=str(game.realms.get(id,{}).get("boss_sprite",""))
 if not boss.is_empty() and boss not in result and "boss:"+boss not in result:result.append("boss:"+boss)
 for kind in game.legacy.data.get("encounters",{}).get(id,[]):
  if kind not in result:result.append(kind)
 return result.filter(func(kind):return not is_boss(id,str(kind)))+result.filter(func(kind):return is_boss(id,str(kind)))
func enemy_name(id:String,kind:String)->String:
 if kind.begins_with("boss:"):
  var prefix:=kind.substr(5)
  return str(game.realms[id].get("boss_name",game.enemy_types.get(prefix,{}).get("name",prefix.replace("_"," ").capitalize())))
 return str(game.enemy_types.get(kind,{}).get("name",kind.replace("_"," ").capitalize()))
func portrait(id:String,kind:String)->Texture2D:
 var prefix:String=kind.substr(5) if kind.begins_with("boss:") else str(game.enemy_types.get(kind,{}).get("sprite",kind))
 if portraits.has(prefix):return portraits[prefix]
 for suffix in ["_idle","_0",""]:
  for ext in [".png",".svg"]:
   var path:String="res://assets/"+prefix+suffix+ext
   if ResourceLoader.exists(path):portraits[prefix]=load(path);return portraits[prefix]
 return null
func record_encounters()->void:
 if game.mode!="run" or game.practice or game.tutorial.active or (game.mistglass_rift!=null and game.mistglass_rift.active):return
 var id:=str(game.region.get("id",""));var book:Dictionary=game.legacy.data.get("encounters",{});var found:Array=book.get(id,[]);var changed:=false
 for foe in game.enemies:
  if float(foe.get("hp",0))<=0 or game.position_in_world.distance_to(foe.pos)>600 or not game.shot_path_clear(game.position_in_world,foe.pos):continue
  var kind:=str(foe.get("type",""))
  if kind in ["boss","fragment"]:
   var boss:=str(game.region.get("boss_sprite","bramble_boss"));kind=boss if game.enemy_types.has(boss) else "boss:"+boss
  if kind.is_empty() or kind in found:continue
  found.append(kind);changed=true
 if changed:book[id]=found;game.legacy.data.encounters=book;game.legacy.save()
func _process(delta:float)->void:
 tick+=delta
 if tick>.4:tick=0;record_encounters()
 var wanted:String=game.menu if game.menu in MENUS else "";panel.visible=not wanted.is_empty()
 if wanted.is_empty():context="";return
 if wanted!=context:context=wanted;game.message_time=0;render()
 panel.size=Vector2(1120,610);var view:=get_viewport().get_visible_rect().size;var f:=minf(1,minf((view.x-24)/1120,(view.y-24)/610));panel.scale=Vector2.ONE*f;panel.position=(view-panel.size*panel.scale)*.5

func is_boss(id:String,kind:String)->bool:
 if kind.begins_with("boss:") or kind in bosses.get(id,[]):return true
 var realm:Dictionary=game.realms.get(id,{})
 if kind==str(realm.get("boss_sprite","")) or kind==str(realm.get("boss_type","")):return true
 var enemy:Dictionary=game.enemy_types.get(kind,{})
 return bool(enemy.get("boss",false)) or str(enemy.get("ai",""))=="boss" or kind.ends_with("_boss")
func difficulty_color(value:String)->Color:
 var text:=value.to_lower()
 if "expert" in text or "ultimate" in text or "extreme" in text:return Color("#f3a2ed")
 if "hard" in text or "challeng" in text:return Color("#ffab83")
 if "medium" in text:return Color("#f1d477")
 return Color("#9ee6b1")

extends CanvasLayer
## A collapsible town guide. It never opens over combat or changes unlock rules.
const A=preload("res://scripts/realm_access.gd")
const UI=preload("res://scripts/studio_ui.gd")
const ORDER=["grove","quarry","honeyglass","elementary","sunfield","ice","folded_coast","moonburrow","moonveil","petalbrook","middle_school","space","zombie","lantern_marsh","silverfall","confluence","brasslock","clockwork_orchard","high_school","neon_crucible","cinderheart","astral_rift","chimevault","ebonwake","shattered_oath"]
var panel:PanelContainer
var rows:VBoxContainer
var minimize:Button
var launcher:Button
var weather:Button
var weather_help:AcceptDialog
var collapsed=true
var identity=""
var shown_signature=""
var timer=0.0
var game:Node
var prefs=ConfigFile.new()
func _ready()->void:
 layer=31;prefs.load("user://fx_interface.cfg")
 panel=PanelContainer.new();panel.name="JourneyGuide";panel.mouse_filter=Control.MOUSE_FILTER_STOP;add_child(panel);UI.apply(panel)
 rows=VBoxContainer.new();panel.add_child(rows);panel.hide()
 launcher=Button.new();launcher.name="JourneyGuideButton";launcher.text="◇";launcher.tooltip_text="Journey guide • your next realm";launcher.custom_minimum_size=Vector2(36,30);launcher.add_theme_font_size_override("font_size",22);launcher.pressed.connect(toggle);add_child(launcher);UI.apply(launcher)
 for style in ["normal","hover","pressed","focus"]:launcher.add_theme_stylebox_override(style,UI.box("#244854","#799da3",5,3))
 weather=Button.new();weather.name="WeatherHelpButton";weather.tooltip_text="Weather & fishing • click for tips";weather.custom_minimum_size=Vector2(36,30);weather.pressed.connect(show_weather_help);add_child(weather)
 for style in ["normal","hover","pressed","focus"]:weather.add_theme_stylebox_override(style,StyleBoxEmpty.new())
 weather_help=AcceptDialog.new();weather_help.name="WeatherFishingHelp";weather_help.title="Weather & fishing";weather_help.dialog_text="Weather around town and some other areas changes which fish you can catch.\n\nSome species prefer rain, mist or clear skies. Time of day and the day of the week can matter too. Different waters have different species.\n\nCheck your fishing journal for the conditions of fish you have discovered. A fish symbol appears beside a realm only after you catch a fish there.\n\nPlaced baskets keep their own catch timer. Click the basket notice to check their locations.";weather_help.dialog_autowrap=true;add_child(weather_help)
func _process(dt:float)->void:
 timer-=dt
 if timer<=0:
  timer=.5;var scene=get_tree().current_scene
  game=scene if scene!=null and scene.get("legacy")!=null and not scene.legacy.arcade else null
  var a=get_tree().root.get_node_or_null("FXAccount");var who=str(a.user.get("id","guest")) if a!=null and a.loaded else "guest"
  if identity!=who:identity=who;collapsed=true;render()
  if game!=null and not collapsed:
   var signature=str(A.count(game.legacy,ORDER))+next_realm(game.legacy)
   if signature!=shown_signature:render()
 var available=game!=null and game.mode=="town" and game.menu in ["","town"] and game.session_menu.page.is_empty() and not game.has_node("FXIntro")
 launcher.visible=available;weather.visible=available;panel.visible=available and not collapsed
 var view=get_viewport().get_visible_rect().size;var y=132.0 if view.x<1100 else 118.0
 weather.position=Vector2(24,y);weather.size=Vector2(36,30)
 launcher.position=Vector2(24,y+36);launcher.size=Vector2(36,30)
 if panel.visible:
  panel.size=Vector2(minf(320,view.x-32),0);panel.position=Vector2(minf(68,maxf(16,view.x-panel.size.x-16)),y+36)
func show_weather_help()->void:
 weather_help.popup_centered(Vector2i(mini(480,int(get_viewport().get_visible_rect().size.x)-32),300))
func next_realm(legacy:Node)->String:
 # Follow the next unlock milestone first; optional uncleared branches can wait.
 var milestones=[[["grove"],1],[["quarry","honeyglass"],1],[["elementary"],1],[["sunfield","ice"],1],[["folded_coast","moonburrow","moonveil","petalbrook"],3],[["middle_school"],1],[["space","zombie"],1],[A.HARD,4],[A.EXPERT,2],[A.EXTREME,1]]
 for milestone in milestones:
  if A.count(legacy,milestone[0])>=int(milestone[1]):continue
  for id in milestone[0]:
   if not A.cleared(legacy,id) and A.unlocked(legacy,id):return id
 for id in ORDER:
  if not A.cleared(legacy,id) and A.unlocked(legacy,id):return id
 return ""
func toggle()->void:
 collapsed=not collapsed;prefs.set_value(identity,"journey_minimized",collapsed);prefs.save("user://fx_interface.cfg");render()
func render()->void:
 for child in rows.get_children():rows.remove_child(child);child.queue_free()
 var top=HBoxContainer.new();rows.add_child(top)
 minimize=Button.new();minimize.text="JOURNEY GUIDE  •  Close";minimize.custom_minimum_size=Vector2(280,34);minimize.pressed.connect(toggle);top.add_child(minimize)
 if collapsed or game==null:return
 var id=next_realm(game.legacy);var cleared=A.count(game.legacy,ORDER);shown_signature=str(cleared)+id
 var bar=ProgressBar.new();bar.show_percentage=false;bar.max_value=ORDER.size();bar.value=cleared;bar.custom_minimum_size.y=10;rows.add_child(bar)
 label("%d / %d realms cleared" % [cleared,ORDER.size()],13)
 if id.is_empty():label("All realms cleared • master your favourites or explore your collections.",15);return
 var landscape=preload("res://scripts/realm_landscape.gd").new();landscape.realm=id;landscape.custom_minimum_size=Vector2(280,70);rows.add_child(landscape)
 label(str(game.realms.get(id,{}).get("name",id)),18)
 var tip="Clear this realm to continue your journey."
 if id=="grove":tip="Start here: reach the gate, defeat the guardian, then explore two new beginner realms."
 elif id in ["quarry","honeyglass"]:tip="A first clear here opens the elementary school adventure. Choose either route."
 elif id=="elementary":tip="A first clear opens Sunfield and the ice arena realm."
 elif id in ["sunfield","ice"]:tip="Clear either realm to open the medium realm routes."
 elif id in ["folded_coast","moonburrow","moonveil","petalbrook"]:tip="Clear three different medium realms to unlock Crossbell Middle School."
 label(tip,14)
 var b=Button.new();b.text="View realm routes";b.custom_minimum_size.y=34;b.pressed.connect(func():game.menu="portal";game.list_preview["portal"]=game.manifest.regions.find(id);game.list_scroll["portal"]=maxi(0,game.manifest.regions.find(id)-3));rows.add_child(b)
 label("Optional guide • minimise any time • hidden in combat",11)
func label(text:String,size:int)->void:
 var l=Label.new();l.text=text;l.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;l.custom_minimum_size.x=280;l.add_theme_font_size_override("font_size",size);rows.add_child(l)

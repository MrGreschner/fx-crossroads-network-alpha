extends CanvasLayer
const C=preload("res://scripts/waylight_catalog.gd")
var game:Node
var row:HBoxContainer
var slots:Array[Button]=[]
var tick=0.0
func setup(g:Node)->void:
 game=g;layer=34;row=HBoxContainer.new();row.add_theme_constant_override("separation",7);add_child(row)
 for i in 6:
  var b=Button.new();b.size_flags_horizontal=Control.SIZE_EXPAND_FILL;b.custom_minimum_size.y=28;b.add_theme_font_size_override("font_size",12);b.clip_text=true;b.pressed.connect(pressed.bind(i));row.add_child(b);slots.append(b)
 update()
func _process(delta:float)->void:
 tick+=delta
 if tick>=.15:tick=0;update()
func update()->void:
 if game==null or not is_instance_valid(game.presentation):return
 row.visible=game.menu.is_empty() and game.presentation.page.is_empty() and game.session_menu.page.is_empty() and game.mode in ["town","run"] and not game.media.clean_view and not game.has_node("FXIntro")
 row.position=Vector2(20,48 if game.mode=="town" else 145)
 row.size=Vector2(game.VIEW.x-40,28)
 var pack=game.loadout if game.mode=="town" else game.inventory
 slots[0].text="Food: "+game.provisions.name_of(game.provisions.packed)
 slots[0].tooltip_text=game.provisions.summary(game.provisions.packed)+". Click to visit the Food Stand in town."
 for i in 3:
  var spec=game.items.get(pack[i],{}) if i<pack.size() else {}
  slots[i+1].text="Item %d%s: %s" % [i+1," • "+str(i+1) if game.mode=="run" else "",str(spec.get("name","empty"))]
  slots[i+1].tooltip_text=str(spec.get("description","Buy equipment at the Supply Vendor with CC."))
 var state=game.waylight.progress.state()
 for i in 2:
  var relic=game.waylight.progress.item(str(state.equipped[i]));var spec=C.RELICS.get(str(relic.get("type","")),{})
  slots[i+4].text="Relic %d%s: %s" % [i+1," • off" if state.fair else "",str(spec.get("name","empty"))]
  slots[i+4].tooltip_text=str(spec.get("effect","Complete Portal Attunement to unlock relics. View your Inventory in town."))
  slots[i+4].modulate=Color(spec.get("color","#c6d8e1")) if state.attuned else Color("#82949f")
func pressed(index:int)->void:
 if not game.menu.is_empty():return
 if game.mode=="town":
  game.mobile.reset_controls()
  if index==0:game.menu="food";game.list_preview[game.menu]=0
  elif index<=3:game.menu="supplies";game.list_preview[game.menu]=0
  else:game.legacy.open_page("inventory")
 elif index>=1 and index<=3:game.use_item_slot(index-1)
 else:game.message="Return to town to change food or relics.";game.message_time=4

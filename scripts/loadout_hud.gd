extends CanvasLayer
const C=preload("res://scripts/waylight_catalog.gd")
var game:Node
var row:GridContainer
var slots:Array[Button]=[]
var tick=0.0
var arcade=false
func setup(g:Node)->void:
 game=g;arcade=g.has_method("_attack_request");layer=34;row=GridContainer.new();row.columns=7;row.add_theme_constant_override("h_separation",4);row.add_theme_constant_override("v_separation",5);add_child(row)
 for i in 7:
  var b=Button.new();b.size_flags_horizontal=Control.SIZE_EXPAND_FILL;b.custom_minimum_size.y=28;b.add_theme_font_size_override("font_size",12);b.clip_text=true;b.focus_mode=Control.FOCUS_NONE;b.pressed.connect(pressed.bind(i));row.add_child(b);slots.append(b)
 update()
func _process(delta:float)->void:
 tick+=delta
 if tick>=.15:tick=0;update()
func update()->void:
 if game==null or not is_instance_valid(game.presentation):return
 var active=game.started and game.shop_open.is_empty() and not game.spectating() if arcade else game.menu.is_empty() and game.mode in ["town","run"]
 row.visible=active and not (arcade and game.arena_world.shatter.active()) and game.presentation.page.is_empty() and game.session_menu.page.is_empty() and not game.media.clean_view and not game.media.capturing and not game.has_node("FXIntro")
 var combat=arcade or game.mode=="run"
 var rect=preload("res://scripts/combat_hud.gd").dock(game) if combat else Rect2(20,48,game.VIEW.x-40,28)
 row.columns=4 if combat and game.mobile.enabled else 7
 for b in slots:b.custom_minimum_size.y=38 if combat and game.mobile.enabled else 28
 for b in slots:b.custom_minimum_size.x=maxf(40,(rect.size.x-4*(row.columns-1))/row.columns)
 row.position=rect.position;row.size=rect.size
 var pack=game.inventory.get(game.my_id,[]) if arcade else game.inventory if combat else game.loadout
 var food=str(game.food_slots.get(game.my_id,"")) if arcade else game.provisions.packed
 slots[0].text="Food: "+game.provisions.name_of(food)
 slots[0].tooltip_text=game.provisions.summary(food)+". Click to visit the Food Stand in town."
 var bottle_index=preload("res://scripts/supply_slots.gd").index(pack,3,game.items)
 var bottle=game.items.get(str(pack[bottle_index]),{}) if bottle_index>=0 else {}
 slots[1].text="Consumable: "+str(bottle.get("name","empty"))
 slots[1].tooltip_text="Key 4 / Click • "+str(bottle.get("description","One potion or other single-use supply; separate from your three equipment slots."))
 slots[1].modulate=Color("#b6dbbf")
 for i in 3:
  var packed_index=preload("res://scripts/supply_slots.gd").index(pack,i,game.items)
  var spec=game.items.get(str(pack[packed_index]),{}) if packed_index>=0 else {}
  slots[i+2].text="Item %d: %s" % [i+1,str(spec.get("name","empty"))]
  slots[i+2].tooltip_text=str(spec.get("description","Buy equipment at the Supply Vendor with CC."))
 var progress=preload("res://network/expedition_profile.gd").progress(game) if arcade else game.waylight.progress
 var state=progress.state()
 var relics_off=bool(state.fair) or (arcade and (game.get("expedition")==null or not game.get("expedition").special()))
 for i in 2:
  var relic=progress.item(str(state.equipped[i]));var spec=C.RELICS.get(str(relic.get("type","")),{})
  slots[i+5].text="Relic %d%s: %s" % [i+1," • off" if relics_off else "",str(spec.get("name","empty"))]
  slots[i+5].tooltip_text=str(spec.get("effect","Complete Portal Attunement to unlock relics. View your Inventory in town."))
  slots[i+5].modulate=Color(spec.get("color","#c6d8e1")) if state.attuned and not relics_off else Color("#82949f")
func pressed(index:int)->void:
 var logical=3 if index==1 else index-2
 if arcade:
  if index>=1 and index<=4:game.mobile.key(KEY_1+logical)
  return
 if not game.menu.is_empty():return
 if game.mode=="town":
  game.mobile.reset_controls()
  if index==0:game.menu="food";game.list_preview[game.menu]=0
  elif index<=4:game.supply_category="consumables" if index==1 else "equipment";game.menu="supplies";game.list_preview[game.menu]=0
  else:game.legacy.open_page("inventory")
 elif index>=1 and index<=4:game.use_item_slot(logical)
 else:game.message="Return to town to change food or relics.";game.message_time=4

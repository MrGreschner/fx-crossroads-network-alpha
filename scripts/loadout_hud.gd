extends CanvasLayer
const C=preload("res://scripts/waylight_catalog.gd")
var game:Node
var row:GridContainer
var slots:Array[Button]=[]
var tick=0.0
var arcade=false
func setup(g:Node)->void:
 game=g;arcade=g.has_method("_attack_request");layer=34;row=GridContainer.new();row.columns=6;row.add_theme_constant_override("h_separation",7);row.add_theme_constant_override("v_separation",5);add_child(row)
 for i in 6:
  var b=Button.new();b.size_flags_horizontal=Control.SIZE_EXPAND_FILL;b.custom_minimum_size.y=28;b.add_theme_font_size_override("font_size",12);b.clip_text=true;b.focus_mode=Control.FOCUS_NONE;b.pressed.connect(pressed.bind(i));row.add_child(b);slots.append(b)
 update()
func _process(delta:float)->void:
 tick+=delta
 if tick>=.15:tick=0;update()
func update()->void:
 if game==null or not is_instance_valid(game.presentation):return
 var active=game.started and game.shop_open.is_empty() and not game.spectating() if arcade else game.menu.is_empty() and game.mode in ["town","run"]
 row.visible=active and game.presentation.page.is_empty() and game.session_menu.page.is_empty() and not game.media.clean_view and not game.media.capturing and not game.has_node("FXIntro")
 var combat=arcade or game.mode=="run"
 var rect=preload("res://scripts/combat_hud.gd").dock(game) if combat else Rect2(20,48,game.VIEW.x-40,28)
 var order=[0,4,5,1,2,3] if combat and game.mobile.enabled else [0,1,2,3,4,5]
 for n in order.size():
  if slots[order[n]].get_index()!=n:row.move_child(slots[order[n]],n)
 row.columns=3 if combat and game.mobile.enabled else 6
 for b in slots:b.custom_minimum_size.y=42 if combat and game.mobile.enabled else 28
 row.position=rect.position;row.size=rect.size
 var pack=game.inventory.get(game.my_id,[]) if arcade else game.inventory if combat else game.loadout
 var food=str(game.food_slots.get(game.my_id,"")) if arcade else game.provisions.packed
 slots[0].text="Food: "+game.provisions.name_of(food)
 slots[0].tooltip_text=game.provisions.summary(food)+". Click to visit the Food Stand in town."
 for i in 3:
  var spec=game.items.get(pack[i],{}) if i<pack.size() else {}
  slots[i+1].text="Item %d%s: %s" % [i+1,"",str(spec.get("name","empty"))]
  slots[i+1].tooltip_text=str(spec.get("description","Buy equipment at the Supply Vendor with CC."))
 var progress=preload("res://network/expedition_profile.gd").progress(game) if arcade else game.waylight.progress
 var state=progress.state()
 var relics_off=bool(state.fair) or (arcade and (game.get("expedition")==null or not game.get("expedition").special()))
 for i in 2:
  var relic=progress.item(str(state.equipped[i]));var spec=C.RELICS.get(str(relic.get("type","")),{})
  slots[i+4].text="Relic %d%s: %s" % [i+1," • off" if relics_off else "",str(spec.get("name","empty"))]
  slots[i+4].tooltip_text=str(spec.get("effect","Complete Portal Attunement to unlock relics. View your Inventory in town."))
  slots[i+4].modulate=Color(spec.get("color","#c6d8e1")) if state.attuned and not relics_off else Color("#82949f")
func pressed(index:int)->void:
 if arcade:
  if index>=1 and index<=3:game.mobile.key(KEY_1+index-1)
  return
 if not game.menu.is_empty():return
 if game.mode=="town":
  game.mobile.reset_controls()
  if index==0:game.menu="food";game.list_preview[game.menu]=0
  elif index<=3:game.menu="supplies";game.list_preview[game.menu]=0
  else:game.legacy.open_page("inventory")
 elif index>=1 and index<=3:game.use_item_slot(index-1)
 else:game.message="Return to town to change food or relics.";game.message_time=4

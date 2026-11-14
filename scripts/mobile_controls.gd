extends CanvasLayer
## Shared touch overlay. Gameplay uses vectors directly; menu choices reuse existing handlers.
var game: Node
var enabled := false
var movement := Vector2.ZERO
var aim := Vector2.RIGHT
var attacking := false
var fingers: Dictionary = {}
var held_buttons: Dictionary = {}
var stick_points: Dictionary = {}
var panel: Control
var buttons: Array[Button] = []
var menu_state := ""
var swipe_y := 0.0
var swipe_index := -1
var arcade := false
var layout_size := Vector2.ZERO
var move_center := Vector2(160,585)
var aim_center := Vector2(1110,615)
var menu_offset := Vector2.ZERO
const PREFS = "user://fx_mobile_controls.cfg"
const UI = preload("res://assets/fonts/CrossroadsUI.ttf")
const ACTIONS = ["primary", "secondary", "special", "dodge"]
var action_positions: Dictionary = {}
var action_radius: Dictionary = {}
var action_fingers: Dictionary = {}
var aimed_origins: Dictionary = {}
var move_origin := Vector2.ZERO
var primary_origin := Vector2.ZERO
var primary_sampled := false
var tap_pending := false
var release_pending := false
var dodge_pending := false
var cancel_selected := false
var charge_kind := ""
var left_handed := false
var button_scale := 1.0
var button_opacity := .82
var unit := 1.0
var cancel_center := Vector2.ZERO
var redraw_clock := 0.0

func _ready() -> void:
 game = get_parent()
 arcade = game.has_method("_attack_request")
 layer = 20
 enabled = DisplayServer.is_touchscreen_available() or OS.has_feature("web_android") or OS.has_feature("web_ios")
 var prefs := ConfigFile.new()
 prefs.load(PREFS)
 left_handed = bool(prefs.get_value("controls","left_handed",false))
 button_scale = clampf(float(prefs.get_value("controls","size",1.0)),.85,1.15)
 button_opacity = clampf(float(prefs.get_value("controls","opacity",.82)),.4,1.0)
 panel = Control.new()
 panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
 add_child(panel)
 panel.draw.connect(_draw_sticks)

func aquarium_controls()->bool:
 if arcade or game.get("fishing")==null:return false
 var room=game.fishing.room
 return is_instance_valid(room) and game.menu=="fishing_shop" and not is_instance_valid(room.dialogue) and not is_instance_valid(game.fishing.journal) and not is_instance_valid(game.fishing.inspector) and not is_instance_valid(game.fishing.workshop)

func active_menu() -> String:
 if aquarium_controls():return ""
 if game.adventure.quests.active and game.adventure.quests.journal:return "quest_journal"
 if arcade: return "lobby" if not game.started else str(game.shop_open)
 return str(game.menu)

func key(code: int) -> void:
 var event := InputEventKey.new()
 event.keycode = code
 event.physical_keycode = code
 event.pressed = true
 game._unhandled_input(event)

func action_button(label: String, point: Vector2, action: String) -> void:
 var button := make_button(label, point, Vector2(112,64))
 button.button_down.connect(func() -> void: Input.action_press(action))
 button.button_up.connect(func() -> void: Input.action_release(action))

func make_button(label: String, point: Vector2, dimensions := Vector2(100,56)) -> Button:
 var button := Button.new()
 button.text = label
 button.position = point
 button.size = dimensions
 button.add_theme_font_size_override("font_size",22)
 button.focus_mode = Control.FOCUS_NONE
 panel.add_child(button)
 buttons.append(button)
 return button

func key_button(label: String, point: Vector2, code: int) -> void:
 make_button(label,point).pressed.connect(key.bind(code))

func reset_controls() -> void:
 menu_state = "__refresh__"
 movement = Vector2.ZERO
 for action in action_fingers.values():
  if action in ["primary","secondary","special"]:cancel_cast(action)
 attacking = false
 tap_pending = false
 release_pending = false
 dodge_pending = false
 primary_sampled = false
 cancel_selected = false
 charge_kind = ""
 action_fingers.clear()
 aimed_origins.clear()
 fingers.clear()
 stick_points.clear()
 held_buttons.clear()
 for button in buttons:
  if is_instance_valid(button):button.scale=Vector2.ONE;button.modulate=Color.WHITE
 for action in ["secondary","special","dodge","interact"]: Input.action_release(action)

func blocked()->bool:
 if game.has_node("FXIntro"):return true
 if arcade and (game.get("dedicated")==true or game.spectating()):return true
 if game.get("session_menu")!=null and not game.session_menu.page.is_empty():return true
 if not arcade and game.menu=="fishing_shop" and not aquarium_controls():return true
 if not arcade and game.menu in ["fishing_journal","fishing_workshop","town_almanac","waylight","legacy","workshop"]:return true
 if not arcade and game.get("level_cards")!=null and game.menu=="levelup":return true
 if not arcade and game.get("hero_hall")!=null and game.menu=="characters":return true
 if not arcade and game.menu in ["seedhouse","postoffice","training_guide","portal","wayfinder","supplies","merchant","food","arcane_tower","barracks"]:return true
 return (game.get("presentation")!=null and not game.presentation.page.is_empty()) or (arcade and game.get("recovery")!=null and game.recovery.frozen)

func _process(delta: float) -> void:
 # The parent combat loop samples input before this child. Keep a sub-frame tap
 # down through that sample, then let the release be observed on the next frame.
 release_pending = tap_pending
 if tap_pending:
  attacking = false
  tap_pending = false
 elif attacking:
  primary_sampled = true
 if not visible:
  if menu_state != "hidden":reset_controls();menu_state = "hidden"
  panel.hide()
  return
 layer=70 if aquarium_controls() else 20
 if blocked():
  if menu_state!="blocked":reset_controls();menu_state="blocked"
  panel.visible=false;return
 panel.visible = enabled
 if not enabled: return
 var state := active_menu()
 var view := get_viewport().get_visible_rect().size
 if state != menu_state or view != layout_size:
  layout_size = view
  menu_offset = (view-Vector2(1280,720))*0.5
  layout_combat(view)
  reset_controls()
  menu_state = state
  for button in buttons:
   panel.remove_child(button);button.queue_free()
  buttons.clear()
  if state == "":
   if arcade:
    action_button("Interact",Vector2(730,610),"interact")
    buttons[-1].button_down.connect(key.bind(KEY_E))
   else: action_button("Interact",Vector2(730,610),"interact")
   if arcade: pass # Native session Menu replaces the overlapping duplicate.
   if game.adventure.quests.active:key_button("Journal",Vector2(20,275),KEY_Q)
   if arcade:
    key_button("Choice A",Vector2(850,120),KEY_J)
    key_button("Choice B",Vector2(960,120),KEY_K)
  elif state != "lobby":
   key_button("Close",Vector2(1120,610),KEY_ESCAPE)
   key_button("Enter Realm" if state in ["portal","wayfinder"] else "Buy Food" if state=="food" else "Buy Item" if state in ["supplies","merchant"] else "Continue",Vector2(970,610),KEY_ENTER)
   if state in ["characters","supplies","merchant","portal","quest_journal","food","wayfinder"]:
    key_button("Up",Vector2(110,510),KEY_UP)
    key_button("Down",Vector2(225,510),KEY_DOWN)
    if state in ["supplies","food"]: key_button("Refund",Vector2(340,510),KEY_BACKSPACE)
    if state == "portal": key_button("Co-op",Vector2(340,510),KEY_0)
    if state=="wayfinder":
     key_button("Previous",Vector2(340,510),KEY_LEFT);key_button("Next",Vector2(470,510),KEY_RIGHT)
   elif state=="seedhouse":key_button("Plant / Harvest",Vector2(210,510),KEY_1)
   elif state == "quest_entrance":
    key_button("Solo",Vector2(210,510),KEY_1)
    key_button("Co-op",Vector2(340,510),KEY_2)
    key_button("Restart",Vector2(470,510),KEY_3)
   elif state in ["levelup","journey_cosmetics","Barracks","Forge","Archery","Sanctum"]:
    for n in 9: key_button(str(n+1),Vector2(120+n*97,630),KEY_1+n)
  for button in buttons:
   if state == "":
    if button.text == "Interact": button.position = Vector2(view.x*.5-button.size.x*.5,view.y-72*unit)
    elif button.position.x >= 730: button.position.x += view.x-1280
    elif button.text.begins_with("Item"): button.position.x += (view.x-1280)*0.5
    if button.text != "Interact" and button.position.y > 400: button.position.y += view.y-720
   else: button.position += menu_offset
 redraw_clock += delta
 if redraw_clock >= 1.0/30.0:
  redraw_clock = 0
  panel.queue_redraw()

func _input(event: InputEvent) -> void:
 if not visible or blocked() or menu_state != active_menu():return
 if event is InputEventScreenTouch:
  enabled = true
  if not event.pressed:
   if action_fingers.has(event.index):
    finish_action(event.index,event.position,event.canceled)
    get_viewport().set_input_as_handled()
    return
   if held_buttons.has(event.index):
    var button: Button = held_buttons[event.index]
    held_buttons.erase(event.index)
    if is_instance_valid(button):
     button.button_up.emit()
     if hit_button(button,event.position): button.pressed.emit()
    get_viewport().set_input_as_handled()
   if fingers.has(event.index):
    movement = Vector2.ZERO
    get_viewport().set_input_as_handled()
    fingers.erase(event.index)
    stick_points.erase(event.index)
   if swipe_index == event.index: swipe_index = -1
   return
  if active_menu() == "" and layout_size != Vector2.ZERO:
   var action := action_at(event.position)
   if not action.is_empty():
    if not action_fingers.values().has(action):begin_action(event.index,action,event.position)
    get_viewport().set_input_as_handled()
    return
  for button in buttons:
   if hit_button(button,event.position) and not held_buttons.values().has(button):
    held_buttons[event.index] = button
    button.button_down.emit()
    get_viewport().set_input_as_handled()
    return
  if active_menu() in ["characters","supplies","merchant","portal","food","wayfinder"] and Rect2(Vector2(100,182)+menu_offset,Vector2(420,301)).has_point(event.position):
   swipe_index = event.index
   swipe_y = event.position.y
   var row := int((event.position.y-menu_offset.y-182)/43.0)
   if active_menu() == "characters": game.select_hero_entry(game.hero_scroll+row)
   else: game.select_list_entry(int(game.list_scroll.get(active_menu(),0))+row)
   get_viewport().set_input_as_handled()
  elif active_menu() == "":
   if in_move_zone(event.position) and fingers.is_empty():
    fingers[event.index] = "move"
    move_origin = event.position
    update_stick(event.index,event.position)
    get_viewport().set_input_as_handled()
 elif event is InputEventScreenDrag:
  if action_fingers.has(event.index):
   if action_fingers[event.index] == "primary":update_primary(event.position)
   elif aimed_origins.has(event.index):update_aimed_action(event.index,event.position)
   get_viewport().set_input_as_handled()
  elif fingers.has(event.index):
   update_stick(event.index,event.position)
   get_viewport().set_input_as_handled()
  elif event.index == swipe_index and active_menu() in ["characters","supplies","merchant","portal","food","wayfinder"]:
   var steps := int((swipe_y-event.position.y)/43.0)
   if steps != 0:
    if active_menu() == "characters": game.hero_scroll = clampi(game.hero_scroll+steps,0,maxi(0,game.manifest.get("characters",[]).size()-7))
    else: game.scroll_list(steps)
    swipe_y = event.position.y
   get_viewport().set_input_as_handled()

func hit_button(button:Button,point:Vector2)->bool:
 if not is_instance_valid(button) or not button.visible or button.disabled:return false
 return button.get_global_rect().has_point(point)

func layout_combat(view: Vector2) -> void:
 unit = minf(view.x / 820.0, view.y / 510.0)
 var edge := 91.0 * unit
 var direction := 1.0 if left_handed else -1.0
 var side := edge if left_handed else view.x - edge
 aim_center = Vector2(side,view.y - 111.0 * unit)
 move_center = Vector2(view.x - side,view.y - 96.0 * unit)
 action_positions = {
  "primary":aim_center,
  "secondary":aim_center + Vector2(62 * direction,-104) * unit,
  "special":aim_center + Vector2(-15 * direction,-136) * unit,
  "dodge":aim_center + Vector2(123 * direction,27) * unit
 }
 action_radius = {"primary":53*unit*button_scale,"secondary":35*unit*button_scale,
  "special":35*unit*button_scale,"dodge":37*unit*button_scale}
 cancel_center = aim_center + Vector2(153 * direction,-71) * unit

func shatter_active() -> bool:
 return arcade and game.arena_world.shatter.active()

func action_at(point: Vector2) -> String:
 for action in ACTIONS:
  if shatter_active() and action != "secondary":continue
  if point.distance_to(action_positions[action]) <= float(action_radius[action]):return action
 return ""

func in_move_zone(point: Vector2) -> bool:
 var side_x := layout_size.x - point.x if left_handed else point.x
 return side_x < minf(layout_size.x*.38,285*unit) and point.y > layout_size.y - 223*unit

func cast_controller() -> Node:
 return game.adventure.combat.held_cast

func owner_id() -> String:
 return str(game.my_id) if arcade else "solo"

func chargeable(kind: String) -> bool:
 return game.adventure.combat.playing() and not shatter_active() and cast_controller().supports(owner_id(),kind)

func begin_action(index: int, action: String, point: Vector2) -> void:
 if action == "primary" and (tap_pending or release_pending):return
 action_fingers[index] = action
 if action == "dodge":
  dodge_pending = true
  return
 if action != "primary":
  if game.adventure.combat.playing() and str(cast_controller().hero(owner_id()).get(action,{}).get("style","")) in ["care_parcel","dawn_garden"]:
   aimed_origins[index] = point
  Input.action_press(action)
  return
 primary_origin = point
 primary_sampled = false
 cancel_selected = false
 charge_kind = "primary" if chargeable("primary") else ""
 if movement.length_squared() > .04:aim = movement.normalized()
 assist_tap()
 attacking = true

func finish_action(index: int, point: Vector2, canceled: bool) -> void:
 var action: String = action_fingers[index]
 action_fingers.erase(index)
 if action == "dodge":
  if canceled:dodge_pending = false
  return
 if action != "primary":
  if aimed_origins.has(index):
   update_aimed_action(index,point)
   aimed_origins.erase(index)
   release_pending=true
  if canceled and action in ["secondary","special"]:cancel_cast(action)
  Input.action_release(action)
  return
 update_primary(point)
 if canceled or cancel_selected:
  if not charge_kind.is_empty():cancel_cast(charge_kind)
  attacking = false
  tap_pending = false
 elif primary_sampled:
  attacking = false
  release_pending = true
 else:
  tap_pending = true
 charge_kind = ""
 cancel_selected = false

func cancel_cast(kind: String) -> void:
 var cast := cast_controller()
 cast.cancel_local(owner_id(),kind)

func update_stick(index: int, point: Vector2) -> void:
 var offset := (point-move_origin)/(65*unit)
 stick_points[index] = offset.limit_length() * (55*unit)
 movement = offset.limit_length() if offset.length() > .12 else Vector2.ZERO
 if not attacking and aimed_origins.is_empty() and not release_pending and not tap_pending and not movement.is_zero_approx():aim = movement.normalized()

func update_aimed_action(index:int,point:Vector2)->void:
 var offset:Vector2=point-aimed_origins[index]
 if offset.length()>=15*unit:aim=offset.normalized()

func update_primary(point: Vector2) -> void:
 cancel_selected = not charge_kind.is_empty() and point.distance_to(cancel_center) <= 38*unit
 var offset := point-primary_origin
 if cancel_selected or offset.length() < 15*unit:return
 aim = offset.normalized()

func assist_tap() -> void:
 var combat: Node = game.adventure.combat
 if not combat.playing():return
 var id := owner_id()
 var stats: Dictionary = combat.held_cast.hero(id).get("primary",{})
 if not str(stats.get("style","")) in ["projectile","homing","mirror_fan","courtbow","melee"]:return
 var origin: Vector2 = combat.owner_pos(id)
 var reach := minf(480,float(stats.get("range",300)))
 var best := INF
 var snapped := aim
 for key in combat.hostile(id,origin,reach):
  var actor: Dictionary = combat.actor(key)
  if not bool(actor.get("alive",false)):continue
  if arcade and actor.has("player") and not combat.visible_owner(str(actor.player)):continue
  var offset: Vector2 = actor.pos-origin
  var distance := offset.length()
  if distance < 1 or distance > reach:continue
  var direction := offset/distance
  var alignment := aim.dot(direction)
  if alignment < .9:continue
  var score := distance + (1-alignment)*reach*2
  if score >= best or not combat.path_clear(origin,actor.pos):continue
  best = score
  snapped = direction
 aim = snapped

func take_dodge() -> bool:
 var pressed := dodge_pending and visible and not blocked() and active_menu().is_empty()
 dodge_pending = false
 return pressed

func cooldown(action: String) -> float:
 if not arcade:
  return game.dodge_cooldown if action == "dodge" else float(game.cooldowns.get(action,0))
 if action == "dodge":return maxf(0,(int(game.dodge_at.get(game.my_id,0))-Time.get_ticks_msec())*.001)
 if game.role == "guest":return float(game.cooldown_remaining.get(game.my_id,{}).get(action,0))
 return maxf(0,(int(game.cooldown_at.get(game.my_id,{}).get(action,0))-Time.get_ticks_msec())*.001)

func draw_label(at: Vector2, label: String, size: float, tint: Color) -> void:
 var px := maxi(10,roundi(size*unit))
 var width := UI.get_string_size(label,HORIZONTAL_ALIGNMENT_LEFT,-1,px).x
 panel.draw_string(UI,at-Vector2(width*.5,0),label,HORIZONTAL_ALIGNMENT_LEFT,-1,px,tint)

func draw_icon(action: String, center: Vector2, tint: Color) -> void:
 var points: PackedVector2Array
 match action:
  "primary":points = PackedVector2Array([Vector2(-10,8),Vector2(9,-9),Vector2(9,0),Vector2(9,-9),Vector2(0,-9)])
  "secondary":points = PackedVector2Array([Vector2(0,-10),Vector2(8,-2),Vector2(0,7),Vector2(-8,-2),Vector2(0,-10)])
  "special":points = PackedVector2Array([Vector2(0,-12),Vector2(3,-4),Vector2(11,-1),Vector2(3,2),Vector2(0,10),Vector2(-3,2),Vector2(-11,-1),Vector2(-3,-4),Vector2(0,-12)])
  "dodge":points = PackedVector2Array([Vector2(-10,-8),Vector2(-2,-1),Vector2(-10,6),Vector2(-2,-1),Vector2(2,-1),Vector2(-2,-8),Vector2(6,-1),Vector2(-2,6)])
 for i in points.size():points[i] = center + points[i]*unit
 panel.draw_polyline(points,tint,2*unit,true)

func _draw_sticks() -> void:
 if layout_size == Vector2.ZERO or active_menu() != "":return
 var edge := Color("#a8dae4")
 var origin := move_origin if not fingers.is_empty() else move_center
 var offset: Vector2 = Vector2.ZERO if fingers.is_empty() else stick_points.get(fingers.keys()[0],Vector2.ZERO)
 panel.draw_circle(origin,57*unit,Color("#102734",button_opacity*.75))
 panel.draw_arc(origin,57*unit,0,TAU,32,Color(edge,button_opacity),2*unit,true)
 panel.draw_circle(origin+offset,22*unit,Color(edge,button_opacity))
 var labels := {"primary":"Attack","secondary":"Secondary","special":"Special","dodge":"Dodge"}
 for action in ACTIONS:
  if shatter_active() and action != "secondary":continue
  var center: Vector2 = action_positions[action]
  var radius: float = action_radius[action]
  var held := action_fingers.values().has(action)
  var remaining := cooldown(action)
  var tint := Color("#ffda92") if action == "special" else edge
  panel.draw_circle(center,radius,Color("#315969" if held else "#142c37",button_opacity))
  panel.draw_arc(center,radius,0,TAU,32,Color(tint,button_opacity),2*unit,true)
  draw_icon(action,center-Vector2(0,8*unit),Color(tint,button_opacity))
  var label: String = "Hop" if shatter_active() else str(labels[action])
  draw_label(center+Vector2(0,18*unit),str(ceili(remaining))+" s" if remaining > .12 else label,13,Color("#f5edd9",button_opacity))
 if not charge_kind.is_empty() and attacking:
  var cast := cast_controller()
  var id := owner_id()
  var q: Dictionary = cast.charges.get(id,{})
  var s: Dictionary = cast.hero(id).get(charge_kind,{})
  var power: float = cast.power(q,s) if not q.is_empty() else 0.0
  var gold := Color("#ffda92")
  if str(s.get("style","")) == "courtbow":
   var count: int = game.adventure.combat.events.arrow_count(power)
   for i in 4:
    panel.draw_circle(aim_center+Vector2((i-1.5)*17,-34)*unit,4.5*unit,Color(gold,1.0 if i<count else .25))
  elif power > 0:
   panel.draw_arc(aim_center,action_radius.primary-5*unit,-PI/2,-PI/2+TAU*power,28,gold,3*unit,true)
  panel.draw_circle(cancel_center,38*unit,Color("#703b47" if cancel_selected else "#352a37",button_opacity))
  panel.draw_arc(cancel_center,38*unit,0,TAU,32,Color("#efadb3",button_opacity),2*unit,true)
  draw_label(cancel_center+Vector2(0,5*unit),"Cancel",14,Color("#ffe1e0"))
 if layout_size.y > layout_size.x:
  draw_label(Vector2(layout_size.x*.5,layout_size.y*.22),"Rotate sideways for more room",20,Color.WHITE)

func save_preferences() -> void:
 var cfg := ConfigFile.new()
 cfg.set_value("controls","left_handed",left_handed)
 cfg.set_value("controls","size",button_scale)
 cfg.set_value("controls","opacity",button_opacity)
 cfg.save(PREFS)
 reset_controls()

func _notification(what: int) -> void:
 if what == NOTIFICATION_APPLICATION_FOCUS_OUT: reset_controls()

func _exit_tree() -> void:
 reset_controls()

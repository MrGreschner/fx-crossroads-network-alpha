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
var round_actions: Dictionary = {}

func _ready() -> void:
 game = get_parent()
 arcade = game.has_method("_attack_request")
 layer = 20
 enabled = DisplayServer.is_touchscreen_available() or OS.has_feature("web_android") or OS.has_feature("web_ios")
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
 var round:bool=action in ["secondary","special","dodge"]
 var button := make_button(label, point, Vector2(120,120) if round else Vector2(112,64))
 if round:
  round_actions[button]=action
  button.add_theme_font_size_override("font_size",19)
  for state in ["normal","hover","pressed"]:
   var skin:=StyleBoxFlat.new()
   skin.bg_color=Color(.08,.17,.23,.88) if action!="special" else Color(.25,.17,.08,.9)
   if state=="pressed":skin.bg_color=Color(.22,.48,.58,.96)
   skin.border_color=Color("#ffdb86") if action=="special" else Color("#a7d8ed")
   skin.set_border_width_all(4 if state=="pressed" else 2);skin.set_corner_radius_all(60)
   button.add_theme_stylebox_override(state,skin)
  button.button_down.connect(func():button.scale=Vector2.ONE*.96;button.modulate=Color(1.3,1.3,1.3))
  button.button_up.connect(func():button.scale=Vector2.ONE;button.modulate=Color.WHITE)
  button.pivot_offset=Vector2(60,60)
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
 attacking = false
 fingers.clear()
 stick_points.clear()
 held_buttons.clear()
 for button in buttons:
  if is_instance_valid(button):button.scale=Vector2.ONE;button.modulate=Color.WHITE
 for action in ["secondary","special","dodge","interact"]: Input.action_release(action)

func blocked()->bool:
 if game.get("session_menu")!=null and not game.session_menu.page.is_empty():return true
 if not arcade and game.menu=="fishing_shop" and not aquarium_controls():return true
 if not arcade and game.menu in ["fishing_journal","fishing_workshop","town_almanac","waylight","legacy","workshop"]:return true
 if not arcade and game.get("level_cards")!=null and game.menu=="levelup":return true
 if not arcade and game.get("hero_hall")!=null and game.menu=="characters":return true
 if not arcade and game.menu in ["seedhouse","postoffice","training_guide","portal","wayfinder","supplies","merchant","food","arcane_tower","barracks"]:return true
 return (game.get("presentation")!=null and not game.presentation.page.is_empty()) or (arcade and game.get("recovery")!=null and game.recovery.frozen)

func _process(_delta: float) -> void:
 layer=70 if aquarium_controls() else 20
 if blocked():
  if menu_state!="blocked":reset_controls();menu_state="blocked"
  panel.visible=false;return
 panel.visible = enabled
 if not enabled: return
 var state := active_menu()
 var view := get_viewport().get_visible_rect().size
 if state != menu_state or buttons.is_empty() or view != layout_size:
  layout_size = view
  menu_offset = (view-Vector2(1280,720))*0.5
  move_center = Vector2(160,view.y-135)
  aim_center = Vector2(view.x-170,view.y-125)
  reset_controls()
  menu_state = state
  for button in buttons:
   panel.remove_child(button);button.queue_free()
  buttons.clear()
  round_actions.clear()
  if state == "":
   action_button("Secondary",Vector2(905,405),"secondary")
   action_button("Special",Vector2(1050,355),"special")
   action_button("Dodge",Vector2(870,570),"dodge")
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
    if button.position.x >= 730: button.position.x += view.x-1280
    elif button.text.begins_with("Item"): button.position.x += (view.x-1280)*0.5
    if button.position.y > 400: button.position.y += view.y-720
   else: button.position += menu_offset
 panel.queue_redraw()

func _input(event: InputEvent) -> void:
 if blocked():return
 if event is InputEventScreenTouch:
  enabled = true
  if not event.pressed:
   if held_buttons.has(event.index):
    var button: Button = held_buttons[event.index]
    held_buttons.erase(event.index)
    if is_instance_valid(button):
     button.button_up.emit()
     if hit_button(button,event.position): button.pressed.emit()
    get_viewport().set_input_as_handled()
   if fingers.has(event.index):
    if fingers[event.index] == "move": movement = Vector2.ZERO
    else: attacking = false
    fingers.erase(event.index)
    stick_points.erase(event.index)
   if swipe_index == event.index: swipe_index = -1
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
   var role := "move" if event.position.distance_to(move_center) < 115 else "aim" if event.position.distance_to(aim_center) < 105 else ""
   if role != "" and not fingers.values().has(role):
    fingers[event.index] = role
    update_stick(event.index,event.position)
    get_viewport().set_input_as_handled()
 elif event is InputEventScreenDrag:
  if fingers.has(event.index):
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
 if round_actions.has(button):return point.distance_to(button.get_global_rect().get_center())<=button.size.x*.5
 return button.get_global_rect().has_point(point)

func update_stick(index: int, point: Vector2) -> void:
 var moving: bool = fingers[index] == "move"
 var offset := (point-(move_center if moving else aim_center))/75.0
 stick_points[index] = offset.limit_length()*65
 if moving: movement = offset.limit_length() if offset.length() > 0.12 else Vector2.ZERO
 else:
  attacking = offset.length() > 0.18
  if attacking: aim = offset.normalized()

func _draw_sticks() -> void:
 if layout_size.y > layout_size.x:
  panel.draw_rect(Rect2(Vector2(30,120),Vector2(layout_size.x-60,90)),Color(.02,.07,.1,.92))
  panel.draw_string(ThemeDB.fallback_font,Vector2(65,178),"Rotate your phone sideways for the best view",HORIZONTAL_ALIGNMENT_LEFT,-1,36,Color.WHITE)
 if active_menu() != "": return
 for role in ["move","aim"]:
  var center := move_center if role == "move" else aim_center
  panel.draw_circle(center,85,Color(0.04,0.09,0.14,0.55))
  panel.draw_arc(center,85,0,TAU,48,Color(0.85,0.9,1,0.6),3,true)
  var offset := Vector2.ZERO
  for index in fingers:
   if fingers[index] == role: offset = stick_points.get(index,Vector2.ZERO)
  panel.draw_circle(center+offset,32,Color(0.75,0.85,1,0.65))
  panel.draw_string(ThemeDB.fallback_font,center+Vector2(-36,110),"MOVE" if role == "move" else "AIM / FIRE",HORIZONTAL_ALIGNMENT_LEFT,-1,18)

func _notification(what: int) -> void:
 if what == NOTIFICATION_APPLICATION_FOCUS_OUT: reset_controls()

func _exit_tree() -> void:
 reset_controls()

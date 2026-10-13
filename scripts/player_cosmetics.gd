extends RefCounted
## Local weekly rewards; cosmetic only. Calendar dates use the player's device timezone.
const W=preload("res://scripts/weekly_activities.gd")
const IDS=["weekly_1","weekly_2","weekly_3"]
const LODGE_IDS=["lodge_bronze","lodge_silver","lodge_gold","lodge_week"]
const NAMES=["Wisp Skull","Silver Revenant","Astral Sovereign"]
const GOALS=[10000,20000,30000]
var legacy:Node
var date_for_test=""
var next_check=0.0
var picker:CanvasLayer
var previous_menu=""
var game_ref:Node
func day()->String:return date_for_test if not date_for_test.is_empty() else Time.get_date_string_from_system(false)
static func week_key(date:String)->String:
 var n=int(Time.get_unix_time_from_datetime_string(date+"T00:00:00"))/86400
 return Time.get_date_string_from_unix_time((n-posmod(n+4,7))*86400)
func setup(owner:Node)->void:legacy=owner;refresh()
func state()->Dictionary:
 if not legacy.data.get("cosmetics",{}) is Dictionary or not legacy.data.has("cosmetics"):legacy.data.cosmetics={"week":week_key(day()),"damage":0.0,"selected":"auto"}
 return legacy.data.cosmetics
func refresh()->void:
 var s=state();var key=week_key(day())
 if str(s.get("week",""))!=key:
  s.week=key;s.damage=0.0
  if str(s.get("selected","auto")) in IDS+W.REWARDS.keys():s.selected="auto"
  if not preload("res://scripts/profile_store.gd").progression_blocked():legacy.save()
  notify()
func step(delta:float)->void:
 next_check-=delta
 if next_check<=0:next_check=1;refresh()
func add_damage(value:float)->void:
 if value<=0 or not is_finite(value) or preload("res://scripts/profile_store.gd").progression_blocked() or bool(legacy.data.get("teacher",false)):return
 refresh();state().damage=minf(1e12,float(state().get("damage",0))+value)
func tier()->int:
 refresh();var count=0
 for goal in GOALS:
  if float(state().get("damage",0))>=goal:count+=1
 return count
func easter_unlocked()->bool:
 for realm in preload("res://scripts/profile_card.gd").BADGES:
  if realm not in legacy.card.badges():return false
 return true
func eligible(id:String)->bool:
 if id in ["auto","none"]:return true
 if bool(legacy.data.get("teacher",false)):return true
 if id in W.REWARDS:return legacy.weekly.earned(id)
 if id=="daily":return legacy.daily.earned()
 if id=="easter":return easter_unlocked()
 if id=="lodge_week":return legacy.lodge_economy.weekly_earned()
 if id in LODGE_IDS:return legacy.lodge_economy.medal_total()>=[5,15,30][LODGE_IDS.find(id)]
 return id in IDS and IDS.find(id)<tier()
func select(id:String)->void:
 if not eligible(id):return
 state().selected=id;legacy.save();notify()
func daily_visible()->bool:return str(state().get("selected","auto")) in ["auto","daily"]
func effect()->String:
 refresh();var id=str(state().get("selected","auto"));return id if id in IDS+LODGE_IDS+W.REWARDS.keys()+["easter"] and eligible(id) else ""
func notify()->void:
 if legacy.arcade:legacy.game.session_hero_sent=false
func ui(parent:Node)->void:
 refresh()
 var heading=Label.new();heading.text="WEEKLY DAMAGE • "+str(state().week)+" to next Sunday";heading.add_theme_font_size_override("font_size",18);parent.add_child(heading)
 var board=Button.new();board.text="WEEKLY ACTIVITIES • fishing, market & battles";board.custom_minimum_size.y=44;parent.add_child(board);board.pressed.connect(legacy.weekly.open_board)
 var amount=Label.new();amount.text="%s / 30,000 damage • 3 cosmetic unlocks • normal play only" % str(int(state().damage));parent.add_child(amount)
 var b=Button.new();b.text="COSMETICS • choose your effect";b.custom_minimum_size.y=48;preload("res://scripts/top_button_style.gd").apply(b);parent.add_child(b);b.pressed.connect(open_picker)
func open_picker()->void:
 if is_instance_valid(picker):picker.queue_free()
 else:
  game_ref=legacy.game;previous_menu=str(game_ref.menu);game_ref.menu="cosmetics";game_ref.mobile.reset_controls()
 picker=CanvasLayer.new();picker.layer=81;legacy.game.add_child(picker)
 var shade=ColorRect.new();shade.color=Color(.02,.05,.08,.94);shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);picker.add_child(shade)
 var center=CenterContainer.new();picker.add_child(center)
 var panel=PanelContainer.new();panel.custom_minimum_size=Vector2(580,600);center.add_child(panel);preload("res://scripts/studio_ui.gd").apply(panel)
 var shell=VBoxContainer.new();panel.add_child(shell)
 var fixed=Label.new();fixed.text="YOUR COSMETICS";fixed.add_theme_font_size_override("font_size",26);shell.add_child(fixed)
 var board=Button.new();board.text="Weekly activities • see progress";board.custom_minimum_size.y=44;shell.add_child(board);board.pressed.connect(func():close_picker();legacy.weekly.open_board())
 var scroll=ScrollContainer.new();scroll.custom_minimum_size.y=430;scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;scroll.size_flags_vertical=Control.SIZE_EXPAND_FILL;shell.add_child(scroll);preload("res://scripts/touch_list_scroll.gd").attach(scroll)
 var col=VBoxContainer.new();col.size_flags_horizontal=Control.SIZE_EXPAND_FILL;scroll.add_child(col)
 var info=Label.new();info.text="One optional effect • no combat bonuses\nWeekly rewards reset at Sunday 00:00 on this device.";col.add_child(info)
 var choices=[["auto","Automatic Daily Mission reward"],["none","No cosmetic effect"],["daily","Daily Mission reward • "+legacy.daily.reward_name()]]
 for id in W.REWARDS:choices.append([id,str(W.REWARDS[id].name)+" • this week"])
 for n in 3:choices.append([IDS[n],NAMES[n]+" • "+str(GOALS[n])+" damage this week"])
 for n in 3:choices.append([LODGE_IDS[n],["Bronze Laurel","Silver Laurel","Golden Laurel"][n]+" • "+str([5,15,30][n])+" lodge medal points"])
 choices.append(["lodge_week","Weekly Lantern • clear all three featured trials"])
 choices.append(["easter","Easter Egg • earn all four expert realm badges"])
 for pair in choices:
  var button=Button.new();var id=str(pair[0]);button.text=("✓ " if str(state().selected)==id else "")+str(pair[1])+(" • LOCKED" if not eligible(id) else "");button.disabled=not eligible(id);button.clip_text=true;button.tooltip_text=legacy.weekly.goal_text(id) if id in W.REWARDS else str(pair[1]);button.custom_minimum_size.y=44;col.add_child(button);button.pressed.connect(func():select(id);open_picker())
 var close=Button.new();close.text="Done";close.custom_minimum_size.y=44;shell.add_child(close);close.pressed.connect(close_picker)
 var size=legacy.game.get_viewport_rect().size
 var fit=minf(1,minf((size.x-24)/610,(size.y-24)/650));center.scale=Vector2.ONE*fit;center.size=size/fit
func close_picker()->void:
 if is_instance_valid(picker):picker.queue_free()
 picker=null
 if is_instance_valid(game_ref):game_ref.menu=previous_menu;game_ref.mobile.reset_controls()
static func draw_on(c:CanvasItem,p:Vector2,t:float,id:String,week:String="")->void:
 if id in W.REWARDS:
  if week==week_key(Time.get_date_string_from_system(false)):W.draw_on(c,p,t,id)
  return
 if id in LODGE_IDS:
  var q=p+Vector2(0,-83+sin(t*2)*2)
  if id=="lodge_week":
   if week!=week_key(Time.get_date_string_from_system(false)):return
   c.draw_circle(q,12,Color(1,.8,.3,.09));c.draw_rect(Rect2(q-Vector2(5,6),Vector2(10,13)),Color("#e7c36e"),false,1.5);c.draw_circle(q,3+sin(t*3)*.5,Color("#ffe6a5"));c.draw_arc(q+Vector2(0,-6),4,PI,TAU,12,Color("#b79760"),1.5,true)
  else:
   var ink=[Color("#c99568"),Color("#c2d5df"),Color("#efcf81")][LODGE_IDS.find(id)]
   for side in [-1,1]:
    for n in 4:
     var leaf=q+Vector2(side*(6+n*2),6-n*4);c.draw_line(leaf,leaf+Vector2(side*3,-3),ink,2,true)
   c.draw_circle(q+Vector2(0,-6),2,Color(ink,.8))
  return
 if id=="easter":
  var q=p+Vector2(sin(t*.7)*16,-90+cos(t)*3)
  c.draw_arc(q,5,0,TAU,14,Color("#d8b9ef"),1.5,true);c.draw_circle(q+Vector2(-1,-1),1.3,Color("#f4dfa5"));c.draw_line(q+Vector2(3,6),q+Vector2(4,9),Color(.9,.8,1,.35),1,true);return
 if id not in IDS or week!=week_key(Time.get_date_string_from_system(false)):return
 var tier=IDS.find(id);var ink=[Color("#c2dabd"),Color("#c6e2f4"),Color("#dbc1fa")][tier]
 var q=p+Vector2(0,-90+sin(t*2)*3)
 c.draw_circle(q,9,Color(ink,.08));c.draw_circle(q,6,Color(ink,.65));c.draw_rect(Rect2(q+Vector2(-4,3),Vector2(8,5)),Color(ink,.65))
 for x in [-2.5,2.5]:c.draw_circle(q+Vector2(x,-1),1.6,Color("#1b2c38"))
 for x in [-2,0,2]:c.draw_line(q+Vector2(x,5),q+Vector2(x,8),Color("#384552"),1)
 if tier>=1:
  c.draw_arc(q,12,0,TAU,24,Color(ink,.35),1,true)
  for x in [-1,1]:c.draw_line(q+Vector2(x*6,-4),q+Vector2(x*10,-8),Color(ink,.65),2,true)
 if tier==2:
  for n in 3:
   var a=t+n*TAU/3;var point=q+Vector2(cos(a)*16,sin(a)*8);c.draw_circle(point,1.3,Color(ink,.65))
  for x in [-4,0,4]:c.draw_line(q+Vector2(x,-8),q+Vector2(x,-12-abs(x)*.5),Color("#eed59e"),1.5,true)
func valid(value:Variant)->bool:
 if not value is Dictionary:return false
 return value.get("week") is String and str(value.week).length()==10 and value.get("selected") is String and str(value.selected) in ["auto","none","daily","easter"]+IDS+LODGE_IDS+W.REWARDS.keys() and (value.get("damage") is float or value.get("damage") is int) and is_finite(float(value.damage)) and float(value.damage)>=0 and float(value.damage)<=1e12

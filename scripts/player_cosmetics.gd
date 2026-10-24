extends RefCounted
## Profile cosmetics and the dedicated Gleam Atelier gallery. Appearance only.
const W=preload("res://scripts/weekly_activities.gd")
const IDS=["weekly_1","weekly_2","weekly_3"]
const LODGE_IDS=["lodge_bronze","lodge_silver","lodge_gold","lodge_week"]
const NAMES=["Silver Revenant","Wisp Skull","Astral Sovereign"]
const GOALS=[10000,20000,30000]
var competitive=preload("res://scripts/competitive_progress.gd").new()
var rankings=preload("res://scripts/cosmetic_rankings.gd").new()
var atelier:CanvasLayer
var legacy:Node
var date_for_test=""
var next_check=0.0
var picker:CanvasLayer
var previous_menu=""
var game_ref:Node
func day()->String:return date_for_test if not date_for_test.is_empty() else Time.get_date_string_from_system(false)
static func week_key(date:String)->String:
 var n=int(Time.get_unix_time_from_datetime_string(date+"T00:00:00"))/86400
 return Time.get_date_string_from_unix_time((n-posmod(n+3,7))*86400)
func setup(owner:Node)->void:legacy=owner;competitive.legacy=owner;refresh();rankings.setup(owner);competitive.state()
func state()->Dictionary:
 if not legacy.data.get("cosmetics",{}) is Dictionary or not legacy.data.has("cosmetics"):legacy.data.cosmetics={"week":week_key(day()),"damage":0.0,"selected":"auto"}
 return legacy.data.cosmetics
func refresh()->void:
 var s=state();var key=week_key(day())
 if str(s.get("week",""))!=key:
  s.week=key;s.damage=0.0
  if str(s.get("selected","auto")) in W.REWARDS.keys():s.selected="auto"
  if not preload("res://scripts/profile_store.gd").progression_blocked():legacy.save()
  notify()
func step(delta:float)->void:
 competitive.step();rankings.step(delta)
 next_check-=delta
 if next_check<=0:next_check=1;refresh()
func add_damage(value:float)->void:
 if not preload("res://scripts/record_eligibility.gd").damage_allowed(legacy):return
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
 if id in preload("res://scripts/cosmetic_rankings.gd").IDS:return id in rankings.badges()
 if id in W.REWARDS:return legacy.weekly.earned(id)
 if id=="daily":return legacy.daily.earned()
 if id=="easter":return easter_unlocked()
 if id=="lodge_week":return legacy.lodge_economy.weekly_earned()
 if id in LODGE_IDS:return legacy.lodge_economy.medal_total()>=[15,30,50][LODGE_IDS.find(id)]
 if id=="weekly_1":return not bool(competitive.state().defeated)
 if id=="weekly_2":return int(legacy.card.state().descent_best)>=50
 if id=="weekly_3":return "astral_rift" in legacy.card.badges() and bool(legacy.data.get("waylight",{}).get("attuned",false))
 return false
func select(id:String)->void:
 if not eligible(id):return
 state().selected=id;legacy.save();notify()
func daily_visible()->bool:return str(state().get("selected","auto")) in ["auto","daily"]
func effect()->String:
 refresh();var id=str(state().get("selected","auto"))
 if id=="auto" and eligible("weekly_1"):return "weekly_1"
 return id if id not in preload("res://scripts/cosmetic_rankings.gd").IDS and id in IDS+LODGE_IDS+W.REWARDS.keys()+["easter"] and eligible(id) else ""
func effect_week(id:String)->String:return rankings.week() if id=="weekly_1" else str(state().week)
func notify()->void:
 if legacy.arcade:legacy.game.session_hero_sent=false
func ui(parent:Node)->void:
 var text=Label.new();text.text="GLEAM ATELIER • preview your hero and discover every cosmetic";text.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;parent.add_child(text)
 var b=Button.new();b.text="Visit Gleam Atelier";b.custom_minimum_size.y=46;preload("res://scripts/top_button_style.gd").apply(b);parent.add_child(b);b.pressed.connect(open_picker)
func open_picker()->void:
 if is_instance_valid(atelier):return
 atelier=load("res://scripts/gleam_atelier.gd").new();legacy.game.add_child(atelier);atelier.setup(self)
func close_picker()->void:
 if is_instance_valid(atelier):atelier.close()
static func draw_on(c:CanvasItem,p:Vector2,t:float,id:String,week:String="")->void:
 if id in preload("res://scripts/cosmetic_rankings.gd").IDS:return
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
  var q=p+Vector2(sin(t*.9)*29,-40+cos(t*.9)*6)
  c.draw_arc(q,5,0,TAU,14,Color("#d8b9ef"),1.5,true);c.draw_circle(q+Vector2(-1,-1),1.3,Color("#f4dfa5"));c.draw_line(q+Vector2(3,6),q+Vector2(4,9),Color(.9,.8,1,.35),1,true);return
 if id not in IDS:return
 var q=p+Vector2(0,-90+sin(t*2)*1.5)
 if id=="weekly_2":
  q=p+Vector2(sin(t*.75)*11,-99+cos(t*.75)*1.2)
  var ink=Color("#b9eadf")
  c.draw_arc(p+Vector2(0,-99),15,PI*.1,PI*.9,24,Color(.5,.85,.8,.22),1,true)
  var skull=PackedVector2Array([q+Vector2(-4,-4),q+Vector2(-2,-6),q+Vector2(2,-6),q+Vector2(5,-3),q+Vector2(4,1),q+Vector2(2,2),q+Vector2(2,5),q+Vector2(-2,5),q+Vector2(-2,2),q+Vector2(-4,1)])
  c.draw_colored_polygon(skull,ink);c.draw_polyline(skull,Color("#e7fff0"),.7,true)
  for x in [-1.8,1.8]:c.draw_circle(q+Vector2(x,-1.5),1.1,Color("#284b54"))
  c.draw_line(q+Vector2(0,0),q+Vector2(-.6,1.4),Color("#517d7c"),.8,true)
  for x in [-1,1]:c.draw_line(q+Vector2(x,3),q+Vector2(x,5),Color("#779f9e"),.7,true)
  for side in [-1,1]:c.draw_arc(q+Vector2(side*5,-2),4,-PI*.7,PI*.3,12,Color(ink,.5),.8,true)
 elif id=="weekly_1":
  if week!=preload("res://scripts/cosmetic_rankings.gd").week_at(Time.get_unix_time_from_system()):return
  q=p+Vector2(-48,-73+sin(t*2)*1.5);var ink=Color("#bbdef5")
  for side in [-1,1]:
   var a=q+Vector2(side*5,0);c.draw_polyline(PackedVector2Array([a+Vector2(0,4),a+Vector2(-side*2,-2),a+Vector2(0,-6),a+Vector2(side*3,-1),a+Vector2(0,4)]),ink,1,true)
  c.draw_circle(q,2,Color("#e2f3ff"));c.draw_arc(q,10,t*.6,t*.6+PI,18,Color(ink,.3),1,true)
 else:
  var ink=Color("#d6b6ff");var points=PackedVector2Array()
  for n in 5:
   var a=t*.2+n*TAU/5;var star=q+Vector2(cos(a)*22,sin(a)*12);points.append(star);c.draw_circle(star,2.5,ink)
  points.append(points[0]);c.draw_polyline(points,Color(ink,.5),1.2,true)
  c.draw_circle(q,6,Color("#ffe2a1"));c.draw_arc(q,11,0,TAU,24,Color(ink,.7),1.5,true)
func valid(value:Variant)->bool:
 if not value is Dictionary:return false
 if value.has("hide_town_crown") and not value.hide_town_crown is bool:return false
 return value.get("week") is String and str(value.week).length()==10 and value.get("selected") is String and str(value.selected) in ["auto","none","daily","easter"]+IDS+LODGE_IDS+W.REWARDS.keys() and (value.get("damage") is float or value.get("damage") is int) and is_finite(float(value.damage)) and float(value.damage)>=0 and float(value.damage)<=1e12

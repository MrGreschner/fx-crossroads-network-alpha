extends RefCounted
## Calendar-week appearance rewards. Records live in the portable player profile.
const F=preload("res://scripts/fishing_catalog.gd")
const UI=preload("res://scripts/studio_ui.gd")
const REWARDS={
 "week_fish":{"name":"Moonlit Minnow","key":"fish","goal":1,"color":"#89dce2"},
 "week_market":{"name":"Merchant's Fortune","key":"market","goal":1,"color":"#e8c87a"},
 "week_arena_1":{"name":"Duelist's Pennant","key":"arena_matches","goal":1,"color":"#d6a08b"},
 "week_arena_2":{"name":"Silver Crossblades","key":"arena_kills","goal":3,"color":"#c1dbe8"},
 "week_arena_3":{"name":"Champion's Diadem","key":"arena_wins","goal":2,"color":"#ebd082"},
 "week_descent":{"name":"Deepwell Crystal","key":"descent","goal":10,"color":"#b5a5ec"},
 "week_challenge":{"name":"Trialfire Laurel","key":"challenge","goal":2,"color":"#ebb78b"},
 "week_gate":{"name":"Bastion Lantern","key":"gate","goal":10,"color":"#9cd8b8"}}
const TARGETS=[["reed_roach","town_pond"],["swift_dace","town_river"],["copper_bream","town_pond"],["ribbon_loach","quest_reed"],["pebble_perch","town_pond"],["rustfin_chub","quest_brook"],["brook_barbel","town_river"],["mint_grayling","quest_reed"]]
const KEYS=["fish","market","arena_matches","arena_kills","arena_wins","descent","challenge","gate"]
var legacy:Node
func week()->String:
 var n=int(Time.get_unix_time_from_datetime_string(legacy.cosmetics.day()+"T00:00:00"))/86400
 return Time.get_date_string_from_unix_time((n-posmod(n+4,7))*86400)
func state()->Dictionary:
 var key=week()
 if not legacy.data.has("weekly_activities") or str(legacy.data.weekly_activities.get("week",""))!=key:
  legacy.data.weekly_activities={"week":key,"counts":{}}
 return legacy.data.weekly_activities
func allowed()->bool:
 if bool(legacy.data.get("teacher",false)) or preload("res://scripts/profile_store.gd").progression_blocked():return false
 if legacy.arcade:return not legacy.game.spectating() and not legacy.game.practice_match() and not legacy.game.dev_magic.quarantine
 return not legacy.game.practice
func advance(key:String,value:int,maximum:bool=false)->void:
 if key not in KEYS or value<=0 or not allowed():return
 var counts:Dictionary=state().counts;var before=int(counts.get(key,0));var after=mini(1000000,maxi(before,value) if maximum else before+value)
 if after==before:return
 counts[key]=after
 for id in REWARDS:
  if id in preload("res://scripts/cosmetic_rankings.gd").IDS:continue
  var reward=REWARDS[id]
  if str(reward.key)==key and before<int(reward.goal) and after>=int(reward.goal):legacy.cosmetics.notify();legacy.gardening.find_seed("mission")
 legacy.save()
func fishing_task()->Dictionary:
 var day=int(Time.get_unix_time_from_datetime_string(week()+"T00:00:00"))/86400
 var target:Array=TARGETS[posmod(int(day/7),TARGETS.size())];var spec:Dictionary=F.fish()[target[0]]
 return {"species":target[0],"pool":target[1],"kg":snappedf(float(spec.min_kg)+(float(spec.max_kg)-float(spec.min_kg))*.30,.01)}
func catch_fish(catch:Dictionary)->void:
 var task=fishing_task()
 if str(catch.species)==str(task.species) and float(catch.kg)>=float(task.kg):advance("fish",1,true)
func earned(id:String)->bool:
 if id in preload("res://scripts/cosmetic_rankings.gd").IDS:return id in legacy.cosmetics.rankings.badges()
 if not REWARDS.has(id):return false
 return int(state().counts.get(REWARDS[id].key,0))>=int(REWARDS[id].goal)
func goal_text(id:String)->String:
 var task=fishing_task()
 return {"week_fish":"Catch a %s weighing at least %.2f kg" % [F.fish()[task.species].name,task.kg],"week_market":"Hold a server top-10 place for all-time Glimmers earned; spending does not reduce your total","week_arena_1":"Weekly PvP wins: top 30 Bronze, top 15 Silver, top 5 Gold. Human-only Arena and Battleground matches count","week_arena_2":"Hold a server top-10 place for player KOs this week","week_arena_3":"Lead the weekly KO/death ratio with at least 10 KOs and 5 completed human-only PvP matches. KOs / max(1, deaths); ties: more KOs, then fewer deaths","week_descent":"Hold a server top-5 place for deepest Cave Descent floor reached, all time","week_challenge":"Complete 2 lodge trials","week_gate":"Hold a server top-5 place for cleared, visited Between sections this week. Collect a defended section’s Waylight deposit to record it"}.get(id,"")

func open_board()->void:
 legacy.game.presentation.window("WEEKLY ACTIVITIES • "+week(),"weekly_activities")
 var body=legacy.game.presentation.content
 legacy.game.presentation.label(body,"Earn appearance rewards, then equip one at the cosmetic pavilion. Server ranking styles update while connected and reset Mondays where weekly. The fishing and lodge activity goals use their own local weekly schedule. PvP awards exclude bot matches.",18)
 var counts:Dictionary=state().counts
 for id in REWARDS:
  var spec:Dictionary=REWARDS[id];var done=earned(id);var box=UI.card(body,("✓ " if done else "")+str(spec.name),goal_text(id));var row=HBoxContainer.new();box.add_child(row)
  var icon=WeeklyIcon.new();icon.effect=id;icon.custom_minimum_size=Vector2(75,80);row.add_child(icon)
  var col=VBoxContainer.new();col.size_flags_horizontal=Control.SIZE_EXPAND_FILL;row.add_child(col)
  if id in preload("res://scripts/cosmetic_rankings.gd").IDS:
   legacy.game.presentation.label(col,"Currently eligible" if done else "Climb the server rankings • inspect in Gleam Atelier",16);continue
  var bar=ProgressBar.new();bar.max_value=int(spec.goal);bar.value=mini(int(spec.goal),int(counts.get(spec.key,0)));bar.custom_minimum_size.y=18;col.add_child(bar)
  legacy.game.presentation.label(col,"Unlocked for this week" if done else "%d / %d" % [mini(int(spec.goal),int(counts.get(spec.key,0))),spec.goal],16)
  if id=="week_fish":
   var task=fishing_task();var pic=TextureRect.new();pic.texture=F.texture(str(task.species));pic.custom_minimum_size=Vector2(120,66);pic.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;pic.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;col.add_child(pic)
   legacy.game.presentation.label(col,"Suggested water: "+str(F.pools()[task.pool].name)+" • keep or release to claim",16)
 legacy.game.presentation.button(body,"Choose cosmetics",func():legacy.game.presentation.close();legacy.cosmetics.open_picker())
class WeeklyIcon extends Control:
 var effect=""
 var clock=0.0
 func _process(delta:float)->void:clock+=delta;queue_redraw()
 func _draw()->void:preload("res://scripts/weekly_activities.gd").draw_on(self,Vector2(38,132),clock,effect)
static func draw_on(c:CanvasItem,p:Vector2,t:float,id:String)->void:
 if not REWARDS.has(id):return
 var ink=Color(str(REWARDS[id].color));var q=p+Vector2(0,-90+sin(t*2)*2)
 c.draw_circle(q,14,Color(ink,.07))
 match id:
  "week_fish":
   var fish=q+Vector2(sin(t)*8,cos(t)*3);c.draw_colored_polygon(PackedVector2Array([fish+Vector2(-9,0),fish+Vector2(0,-5),fish+Vector2(9,0),fish+Vector2(0,5)]),Color(ink,.85));c.draw_colored_polygon(PackedVector2Array([fish+Vector2(-8,0),fish+Vector2(-14,-5),fish+Vector2(-14,5)]),ink);c.draw_circle(fish+Vector2(5,-1),1.3,Color("#234553"));c.draw_arc(q+Vector2(0,13),14,0,PI,18,Color(ink,.45),1,true)
  "week_market":
   for n in 3:
    var coin=q+Vector2((n-1)*10,sin(t*2+n)*4);c.draw_circle(coin,4,ink);c.draw_line(coin-Vector2(0,2),coin+Vector2(0,2),Color("#957957"),1,true)
  "week_arena_1":
   c.draw_line(q+Vector2(-8,-10),q+Vector2(-8,14),ink,2,true);c.draw_colored_polygon(PackedVector2Array([q+Vector2(-7,-10),q+Vector2(12,-8+sin(t*3)*2),q+Vector2(6,2),q+Vector2(-7,0)]),ink)
  "week_arena_2":
   for side in [-1,1]:
    c.draw_line(q+Vector2(side*9,-12),q+Vector2(-side*10,12),ink,3,true);c.draw_line(q+Vector2(-side*13,5),q+Vector2(-side*3,13),Color("#d3ae80"),2,true)
  "week_arena_3":
   c.draw_colored_polygon(PackedVector2Array([q+Vector2(-13,7),q+Vector2(-14,-6),q+Vector2(-6,0),q+Vector2(0,-12),q+Vector2(6,0),q+Vector2(14,-6),q+Vector2(13,7)]),ink);c.draw_circle(q,2,Color("#ab7892"))
  "week_descent":
   c.draw_colored_polygon(PackedVector2Array([q+Vector2(0,-14),q+Vector2(9,-3),q+Vector2(6,8),q+Vector2(0,14),q+Vector2(-6,8),q+Vector2(-9,-3)]),Color(ink,.85));c.draw_line(q-Vector2(0,13),q+Vector2(0,12),Color("#ecdefa"),1.5,true);c.draw_arc(q,19,t,t+PI*.7,15,Color(ink,.4),1,true)
  "week_challenge":
   for side in [-1,1]:
    for n in 4:
     var leaf=q+Vector2(side*(9+n),9-n*5);c.draw_line(leaf,leaf+Vector2(side*4,-4),ink,2,true)
   c.draw_colored_polygon(PackedVector2Array([q+Vector2(0,-12),q+Vector2(4,2),q+Vector2(0,8),q+Vector2(-4,2)]),Color("#f2d498"))
  "week_gate":
   c.draw_rect(Rect2(q+Vector2(-11,-7),Vector2(22,18)),ink,false,2)
   for x in [-11,0,9]:c.draw_rect(Rect2(q+Vector2(x,-12),Vector2(3,6)),ink)
   c.draw_circle(q+Vector2(0,2),3,Color("#efe4aa"));c.draw_line(q+Vector2(-3,10),q+Vector2(-3,4),ink,2,true);c.draw_line(q+Vector2(3,10),q+Vector2(3,4),ink,2,true)
 var spark=q+Vector2(cos(t*.9)*20,sin(t*.9)*9);c.draw_circle(spark,1.5,Color(ink,.65))
static func valid(v:Variant)->bool:
 if not v is Dictionary or not v.get("week",null) is String or str(v.week).length()!=10 or not v.get("counts",null) is Dictionary:return false
 if v.counts.size()>KEYS.size():return false
 for key in v.counts:
  var n:Variant=v.counts[key]
  if key not in KEYS or not (n is int or n is float) or not is_finite(float(n)) or float(n)<0 or float(n)>1000000:return false
 return true

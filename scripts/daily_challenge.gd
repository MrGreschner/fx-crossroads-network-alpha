extends RefCounted
## Offline daily rotation. Profile-owned cosmetics only; never alters combat stats.
var legacy:Node
var tasks:Array=[]
var today:=""
var check_in:=0.0
var current_task:Dictionary={}
var date_for_test:=""
const REWARDS=["Solar Compass","Moonpetal Halo","Ember Crown","Tidal Pearls","Runic Orbit","Firefly Lanterns","Crystal Bloom","Aurora Ribbons"]
func setup(owner:Node)->void:
 legacy=owner
 var content:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://content/daily_challenges.json"))
 tasks=content.get("tasks",[])
 refresh()
func date_key()->String:return date_for_test if not date_for_test.is_empty() else Time.get_date_string_from_system(false)
func task_for(day:String)->Dictionary:
 var day_number:int=int(Time.get_unix_time_from_datetime_string(day+"T00:00:00"))/86400
 var cycle:int=int(floor(float(day_number)/50.0))
 var order:Array=[]
 for n in tasks.size():order.append(n)
 var rng:=RandomNumberGenerator.new();rng.seed=1190047+cycle*7919
 for n in range(order.size()-1,0,-1):
  var j:int=rng.randi_range(0,n);var swap:int=order[n];order[n]=order[j];order[j]=swap
 # Keep the next cycle’s first task different from the previous cycle’s last.
 var previous:Array=[]
 for n in tasks.size():previous.append(n)
 rng.seed=1190047+(cycle-1)*7919
 for n in range(previous.size()-1,0,-1):
  var j:int=rng.randi_range(0,n);var swap:int=previous[n];previous[n]=previous[j];previous[j]=swap
 if order.size()==50 and order[0]==previous[49]:
  var swap:int=order[0];order[0]=order[1];order[1]=swap
 return tasks[int(order[posmod(day_number,50)])] if tasks.size()==50 else {}
func task()->Dictionary:return current_task
func refresh()->void:
 var new_day:=date_key()
 if today!=new_day or current_task.is_empty():current_task=task_for(new_day)
 today=new_day
 if blocked():return
 var old:Variant=legacy.data.get("daily",{})
 if not old is Dictionary or str(old.get("day",""))!=today or str(old.get("task",""))!=str(task().get("id","")):
  legacy.data.daily={"day":today,"task":str(task().get("id","")),"done":false,"best":0}
func blocked()->bool:
 return bool(legacy.data.get("teacher",false)) or preload("res://scripts/profile_store.gd").progression_blocked()
func step(delta:float)->void:
 check_in-=delta
 if check_in>0:return
 check_in=1
 var old:String=today;refresh()
 if old!=today:notify_network()
func earned()->bool:
 var info:Variant=legacy.data.get("daily",{})
 return not blocked() and info is Dictionary and str(info.get("day",""))==today and str(info.get("task",""))==str(task().get("id","")) and bool(info.get("done",false))
func cosmetic_date()->String:return today if earned() else ""
func matches_team(required:String,size:int)->bool:return required=="any" or (size==1 if required=="solo" else size>=2)
func realm_clear(hero:String,realm:String)->void:
 if realm in ["descent","defense","quests","wayfarer","town","practice","first_steps"]:return
 var g:Node=legacy.game
 if not legacy.arcade and (g.practice or g.tutorial.active):return
 var count:int=g.match_party_size if legacy.arcade else 1
 if legacy.arcade and (g.mode!="coop" or g.spectating()):return
 event("realm",1,count,realm,hero)
func survival(kind:String,count:int,party_size:int)->void:
 if not legacy.arcade or legacy.game.spectating() or legacy.game.mode!=kind:return
 event(kind,count,party_size)
func event(kind:String,count:int,party_size:int,realm:String="",hero:String="")->void:
 refresh()
 if blocked() or earned():return
 var goal:=task()
 if str(goal.get("kind",""))!=kind or not matches_team(str(goal.get("team","any")),party_size):return
 if kind=="realm" and ((str(goal.realm)!="*" and str(goal.realm)!=realm) or (not str(goal.hero).is_empty() and str(goal.hero)!=hero)):return
 var progress:Dictionary=legacy.data.daily
 if count<=int(progress.get("best",0)):return
 progress.best=maxi(int(progress.get("best",0)),mini(count,int(goal.target)))
 if count>=int(goal.target):
  progress.done=true;notify_network()
 legacy.save()
func notify_network()->void:
 # Existing reliable hero/cosmetic metadata carries the reward, not every movement packet.
 if legacy.arcade and legacy.game.role=="guest":legacy.game.session_hero_sent=false
func ui(parent:Node)->void:
 refresh()
 var goal:=task()
 var box:=PanelContainer.new();parent.add_child(box)
 var skin:=StyleBoxFlat.new();skin.bg_color=Color("#203e45");skin.border_color=Color("#d7bf78");skin.set_border_width_all(1);skin.set_corner_radius_all(10);skin.set_content_margin_all(16);box.add_theme_stylebox_override("panel",skin)
 var col:=VBoxContainer.new();col.add_theme_constant_override("separation",8);box.add_child(col)
 for row in [["DAILY MISSION • "+today,15],[str(goal.get("title","Today’s adventure")),24],[str(goal.get("description","")),19]]:
  if int(row[1])==24:
   var title=Button.new();title.text=str(row[0])+" →";title.custom_minimum_size.y=48;title.add_theme_font_size_override("font_size",20);preload("res://scripts/top_button_style.gd").apply(title);col.add_child(title);title.pressed.connect(quick_play)
  else:
   var l:=Label.new();l.text=row[0];l.add_theme_font_size_override("font_size",row[1]);l.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;l.size_flags_horizontal=Control.SIZE_EXPAND_FILL;col.add_child(l)
 var state:=Label.new();state.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;state.add_theme_font_size_override("font_size",18);col.add_child(state)
 state.text="GAME DEV • mission rewards are disabled during testing." if blocked() else "COMPLETED • "+reward_name()+" active until midnight!" if earned() else "Reward: "+reward_name()+" until local midnight • cosmetic only."
 if not blocked() and not earned() and str(goal.get("kind","")) in ["descent","defense"]:
  state.text="Best today: %d / %d cleared • %s" % [int(legacy.data.get("daily",{}).get("best",0)),int(goal.target),state.text]
 state.modulate=Color("#f8d785")
 var play=Button.new();play.text="PLAY TODAY’S MISSION →";play.custom_minimum_size.y=48;preload("res://scripts/top_button_style.gd").apply(play);col.add_child(play);play.pressed.connect(quick_play)
 var foot:=Label.new();foot.text="50 rotating missions • separate from Challenge Lodge trials • changes at local midnight • progress travels with your downloaded profile";foot.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;foot.add_theme_font_size_override("font_size",14);col.add_child(foot)
static func reward_index(day:String)->int:
 return posmod(int(Time.get_unix_time_from_datetime_string(day+"T00:00:00"))/86400,8)
func reward_name()->String:return REWARDS[reward_index(today)]
func quick_plan()->Dictionary:
 var goal=task();return {"hero":str(goal.get("hero","")),"realm":"grove" if str(goal.get("realm","grove"))=="*" else str(goal.get("realm","grove")),"mode":"coop" if goal.kind=="realm" and goal.team=="party" else str(goal.kind),"party":goal.team=="party"}
func quick_play()->void:
 var g:Node=legacy.game
 if legacy.arcade or g.mode!="town":
  g.presentation.window("TODAY’S MISSION","daily_return")
  g.presentation.label(g.presentation.content,"Starting a new mission ends this attempt and leaves your current room. Return to town first?",20)
  g.presentation.button(g.presentation.content,"Return to town & open mission",func():g.get_tree().root.set_meta("fx_daily_launch",true);g.session_menu.town())
  g.presentation.button(g.presentation.content,"Keep playing",g.presentation.close);return
 var plan=quick_plan()
 g.session_menu.resume(false);g.presentation.close();legacy.close()
 if not plan.hero.is_empty() and g.characters.has(plan.hero):g.selected_character=plan.hero;g.character_id=plan.hero
 if plan.mode=="realm":g.start_run(false,plan.realm)
 else:
  g.get_tree().root.set_meta("fx_daily_party",bool(plan.party));g.presentation.launch(plan.mode,plan.realm)
static func draw_on(c:CanvasItem,p:Vector2,t:float,day:String="")->void:
 if day.is_empty():day=Time.get_date_string_from_system(false)
 var style=reward_index(day);var center=p+Vector2(0,-25)
 var colors=[Color("#ffe199"),Color("#c4afff"),Color("#ffa477"),Color("#86e5e7"),Color("#a9ccff"),Color("#ddf19c"),Color("#e1b4e9"),Color("#96e6c7")]
 var ink:Color=colors[style]
 match style:
  0: # Solar compass: rotating directions etched beneath the hero.
   var foot=p+Vector2(0,6)
   for n in 8:
    var a=t*.25+n*TAU/8;var inner=foot+Vector2(cos(a)*17,sin(a)*6);var outer=foot+Vector2(cos(a)*30,sin(a)*11)
    c.draw_line(inner,outer,Color(ink,.65 if n%2==0 else .3),1.5,true)
   c.draw_arc(foot,14,0,TAU,20,Color(ink,.25),1,true)
   c.draw_line(p-Vector2(0,58),p-Vector2(0,48),Color(ink,.7),1.5,true)
  1: # Moonpetal: hovering crescent and drifting petals.
   c.draw_arc(p-Vector2(0,54),9,t*.2,t*.2+PI*1.55,16,Color(ink,.7),2,true)
   for n in 4:
    var q=p+Vector2(sin(t*.7+n)*24,-fposmod(t*10+n*16,56));c.draw_circle(q,2,Color(ink,.4))
  2: # Ember crown: tiny flames rise along a crown.
   for n in 5:
    var q=p+Vector2((n-2)*6,-48-abs(sin(t*3+n))*8);c.draw_line(q,q+Vector2(0,5),Color(ink,.7),2,true)
  3: # Tidal pearls: wavy foot-ring and rising water beads.
   var line=PackedVector2Array()
   for n in 25:
    var a=n*TAU/24;line.append(p+Vector2(cos(a)*27,sin(a)*7+sin(t*2+a*3)*2+7))
   c.draw_polyline(line,Color(ink,.45),1.5,true)
   for n in 3:c.draw_circle(p+Vector2(sin(t+n*2)*23,-fposmod(t*11+n*15,45)),2,Color(ink,.5))
  4: # Runic orbit: rotating diamonds.
   for n in 4:
    var a=t*.5+n*TAU/4;var q=center+Vector2(cos(a)*30,sin(a)*18)
    c.draw_polyline(PackedVector2Array([q-Vector2(0,4),q+Vector2(3,0),q+Vector2(0,4),q-Vector2(3,0),q-Vector2(0,4)]),Color(ink,.65),1,true)
  5: # Fireflies: warm pulsing lantern motes.
   for n in 5:
    var q=center+Vector2(sin(t*.8+n*1.7)*34,cos(t*.6+n)*24);c.draw_circle(q,5,Color(ink,.07));c.draw_circle(q,1.8,Color(ink,.45+.25*sin(t*2+n)))
  6: # Crystal bloom: six expanding petals underfoot.
   for n in 6:
    var a=t*.18+n*TAU/6;var q=p+Vector2(cos(a)*22,sin(a)*8+6)
    c.draw_line(q,q+Vector2(cos(a)*6,sin(a)*3),Color(ink,.6),3,true)
  7: # Aurora ribbons: two flowing strands behind the hero.
   for row in 2:
    var points=PackedVector2Array()
    for n in 13:points.append(center+Vector2(-31+n*5,sin(n*.4+t*1.6+row*PI)*9+row*12))
    c.draw_polyline(points,Color(ink,.25+row*.12),1.5,true)

func valid(value:Variant)->bool:
 if not value is Dictionary:return false
 if not value.get("day","") is String or str(value.get("day","")).length()!=10:return false
 if not value.get("task","") is String or str(value.get("task","")).length()>64:return false
 if not value.get("done",false) is bool:return false
 var count:Variant=value.get("best",0)
 return (count is int or count is float) and is_finite(float(count)) and float(count)>=0 and float(count)<=100

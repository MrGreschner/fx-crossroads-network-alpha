extends RefCounted
## Cosmetic-only trailing 168-hour activity, stored in one-minute buckets.
const WINDOW=604800
const GOALS=[1000,3000,7000,15000,25000,40000,65000,100000]
const NAMES=["Bronze Spark","Copper Crest","Silver Scout","Golden Vanguard","Amethyst Regent","Sapphire Monarch","Ruby Champion","Celestial Crown"]
const COLORS=["#ad8460","#dc965d","#cbdce5","#efd174","#c39ae8","#71c8f2","#f48691","#f2ecbd"]
var legacy:Node
var time_for_test=-1.0
var timer=0.0
var previous_tier=-1
var cached_sum=0.0
var dirty=false
var sent_payload=""
func now()->float:return time_for_test if time_for_test>=0 else Time.get_unix_time_from_system()
static func valid(v:Variant)->bool:
 if not v is Dictionary or v.get("version")!=1 or not v.get("buckets") is Array or v.buckets.size()>10082:return false
 var last=-1
 for b in v.buckets:
  if not b is Array or b.size()!=2 or not preload("res://scripts/workshop_project.gd").number(b[0],0,100000000000) or float(b[0])!=floorf(float(b[0])) or int(b[0])<=last or not preload("res://scripts/workshop_project.gd").number(b[1],0,1e12):return false
  last=int(b[0])
 return true
func setup(owner:Node)->void:
 legacy=owner
 if not legacy.data.has("rolling_damage") or not valid(legacy.data.rolling_damage):legacy.data.rolling_damage={"version":1,"buckets":[]}
 refresh()
func state()->Dictionary:
 if not legacy.data.has("rolling_damage"):legacy.data.rolling_damage={"version":1,"buckets":[]}
 return legacy.data.rolling_damage
func refresh()->void:
 var buckets:Array=state().buckets;var minute=int(now()/60)
 while not buckets.is_empty() and int(buckets[0][0])*60<=now()-WINDOW:buckets.pop_front();dirty=true
 cached_sum=0
 for b in buckets:if int(b[0])<=minute:cached_sum+=float(b[1])
 var rank=tier_from(cached_sum)
 if rank!=previous_tier:
  previous_tier=rank
  if legacy.arcade and not legacy.game.started:legacy.game.session_hero_sent=false
func add_damage(amount:float)->void:
 if amount<=0 or not is_finite(amount) or preload("res://scripts/profile_store.gd").progression_blocked() or bool(legacy.data.get("teacher",false)):return
 var minute=int(now()/60);var buckets:Array=state().buckets
 # A backward local clock must not reorder or fabricate earlier history.
 if not buckets.is_empty() and int(buckets.back()[0])>minute:return
 var added=minf(1e12,amount)
 if not buckets.is_empty() and int(buckets.back()[0])==minute:
  added=minf(added,1e12-float(buckets.back()[1]));buckets.back()[1]+=added
 else:buckets.append([minute,added])
 cached_sum+=added;dirty=true
 if buckets.size()>10082:buckets.pop_front()
func step(dt:float)->void:
 timer-=dt
 if timer<=0:
  timer=10;refresh()
  if legacy.arcade and legacy.game.role=="guest" and not legacy.game.started and legacy.game._link_open(legacy.game.host_id):
   var payload_text=JSON.stringify(legacy.game.local_cosmetic())
   if payload_text!=sent_payload:legacy.game._send_channel(legacy.game.host_id,{"type":"lobby_cosmetic","cosmetic":legacy.game.local_cosmetic()});sent_payload=payload_text
  if dirty and not preload("res://scripts/profile_store.gd").progression_blocked():legacy.save();dirty=false
func total()->float:return cached_sum
static func tier_from(amount:float)->int:
 var tier=0
 for threshold in GOALS:if amount>=threshold:tier+=1
 return tier
func payload()->Dictionary:return {"crown_damage":int(minf(1e12,cached_sum)),"crown_tier":tier_from(cached_sum)}
static func remote_tier(value:Dictionary)->int:
 var amount=value.get("crown_damage",0)
 return tier_from(float(amount)) if preload("res://scripts/workshop_project.gd").number(amount,0,1e12) else 0
func ui(parent:Node)->void:
 refresh();var rank=tier_from(cached_sum);var label=Label.new();label.text="LOBBY CROWN • "+(NAMES[rank-1] if rank>0 else "Earn your first crown")+"\n"+str(int(cached_sum))+" damage in the last 7 days • no Sunday reset";label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;parent.add_child(label)
 var bar=ProgressBar.new();bar.max_value=GOALS[mini(rank,7)];bar.value=cached_sum;bar.custom_minimum_size.y=22;parent.add_child(bar)
 var note=Label.new();note.text="Next: "+str(GOALS[rank])+" damage" if rank<8 else "Top crown • cosmetic only";parent.add_child(note)
static func draw_on(c:CanvasItem,p:Vector2,t:float,tier:int)->void:
 if tier<1 or tier>8:return
 var ink=Color(COLORS[tier-1]);var alpha=.35+.09*sin(t*1.8)
 c.draw_arc(p-Vector2(0,18),26,0,TAU,32,Color(ink,alpha),1.5,true)
 var top=p-Vector2(0,38+sin(t*2)*1.2);var width=6+min(tier,5)
 var points=PackedVector2Array([top+Vector2(-width,7),top+Vector2(-width,-4),top+Vector2(-width*.5,1),top+Vector2(0,-8),top+Vector2(width*.5,1),top+Vector2(width,-4),top+Vector2(width,7)])
 c.draw_colored_polygon(points,Color(ink,.85));c.draw_polyline(points,ink,1.2,true)
 c.draw_line(top+Vector2(-width,8),top+Vector2(width,8),ink,2,true)
 if tier>=3:c.draw_circle(top+Vector2(0,3),2,Color("#19343c"))
 if tier>=5:
  for side in [-1,1]:c.draw_circle(top+Vector2(side*width*.55,4),1.6,Color("#fcf4ce"))
 if tier>=7:
  for side in [-1,1]:c.draw_line(top+Vector2(side*(width+2),7),top+Vector2(side*(width+6),-1),Color(ink,.7),1.5,true)
 if tier==8:
  for n in 3:
   var angle=t*.6+n*TAU/3;c.draw_circle(top+Vector2(cos(angle)*23,sin(angle)*9),1.1,Color(ink,.65))

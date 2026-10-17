extends RefCounted
## Trailing 168-hour activity powers combat; only the current crown can be worn. Highest rank is a record only.
const WINDOW=604800
const GOALS=[1000,3000,7000,15000,25000,40000,65000,100000,120000,140000,160000,180000,200000,220000,240000,260000,280000,300000]
const NAMES=["Bronze Spark","Copper Crest","Silver Scout","Golden Vanguard","Amethyst Regent","Sapphire Monarch","Ruby Champion","Celestial I","Celestial II","Celestial III","Celestial IV","Celestial V","Omnipotent I","Omnipotent II","Omnipotent III","Omnipotent IV","Omnipotent V","Beyonder"]
const COLORS=["#ad8460","#dc965d","#cbdce5","#efd174","#c39ae8","#71c8f2","#f48691","#f2ecbd","#f2ecbd","#f2ecbd","#f2ecbd","#f2ecbd","#bfb2ff","#bfb2ff","#bfb2ff","#bfb2ff","#bfb2ff","#9cf4ed"]
var legacy:Node
var time_for_test=-1.0
var timer=0.0
var previous_tier=-1
var cached_sum=0.0
var dirty=false
var sent_payload=""
var expiry_cache:Array=[]
var expiry_cache_until=0.0
func now()->float:return time_for_test if time_for_test>=0 else Time.get_unix_time_from_system()
static func rank_name(rank:int)->String:return NAMES[rank-1] if rank>0 and rank<=GOALS.size() else "No crown yet"
static func valid(v:Variant)->bool:
 if not v is Dictionary or (v.get("version")!=1 and v.get("version")!=2) or not v.get("buckets") is Array or v.buckets.size()>10082:return false
 var last=-1
 for b in v.buckets:
  if not b is Array or b.size()!=2 or not preload("res://scripts/workshop_project.gd").number(b[0],0,100000000000) or float(b[0])!=floorf(float(b[0])) or int(b[0])<=last or not preload("res://scripts/workshop_project.gd").number(b[1],0,1e12):return false
  last=int(b[0])
 if v.get("version")==2:
  var best=v.get("best_tier",0)
  if not preload("res://scripts/workshop_project.gd").number(best,0,GOALS.size()) or float(best)!=floorf(float(best)):return false
 return true
func setup(owner:Node)->void:
 legacy=owner
 if not legacy.data.has("rolling_damage") or not valid(legacy.data.rolling_damage):legacy.data.rolling_damage={"version":2,"buckets":[],"best_tier":0}
 refresh()
func state()->Dictionary:
 if not legacy.data.has("rolling_damage"):legacy.data.rolling_damage={"version":2,"buckets":[],"best_tier":0}
 var s:Dictionary=legacy.data.rolling_damage
 if int(s.version)==1:s.version=2;s.best_tier=0;dirty=true
 return s
func remember()->void:
 var rank=tier_from(cached_sum);var s=state()
 if rank>int(s.best_tier):s.best_tier=rank;dirty=true
 if rank!=previous_tier:
  previous_tier=rank;expiry_cache_until=0.0
  if legacy.arcade and not legacy.game.started:legacy.game.session_hero_sent=false
func refresh()->void:
 var buckets:Array=state().buckets;var minute=int(now()/60)
 while not buckets.is_empty() and int(buckets[0][0])*60<=now()-WINDOW:buckets.pop_front();dirty=true
 cached_sum=0
 for b in buckets:if int(b[0])<=minute:cached_sum+=float(b[1])
 remember()
func add_damage(amount:float)->void:
 if amount<=0 or not is_finite(amount) or preload("res://scripts/profile_store.gd").progression_blocked() or bool(legacy.data.get("teacher",false)):return
 var minute=int(now()/60);var buckets:Array=state().buckets
 if not buckets.is_empty() and int(buckets.back()[0])>minute:return
 var added=minf(1e12,amount)
 if not buckets.is_empty() and int(buckets.back()[0])==minute:
  added=minf(added,1e12-float(buckets.back()[1]));buckets.back()[1]+=added
 else:buckets.append([minute,added])
 cached_sum+=added;dirty=true
 if buckets.size()>10082:buckets.pop_front()
 remember()
func step(dt:float)->void:
 timer-=dt
 if timer<=0:
  timer=10;refresh()
  if legacy.arcade and game_lobby_guest():
   var payload_text=JSON.stringify(legacy.game.local_cosmetic())
   if payload_text!=sent_payload:legacy.game._send_channel(legacy.game.host_id,{"type":"lobby_cosmetic","cosmetic":legacy.game.local_cosmetic()});sent_payload=payload_text
  if dirty and not preload("res://scripts/profile_store.gd").progression_blocked():legacy.save();dirty=false
func game_lobby_guest()->bool:return legacy.game.role=="guest" and not legacy.game.started and legacy.game._link_open(legacy.game.host_id)
func total()->float:return cached_sum
static func tier_from(amount:float)->int:
 if not is_finite(amount) or amount<0:return 0
 var tier=0
 for threshold in GOALS:if amount>=threshold:tier+=1
 return tier
static func bonus(rank:int,competition:bool=false)->Dictionary:
 if competition:return {"chance":0.0,"damage":0.0}
 rank=clampi(rank,0,GOALS.size())
 return {"chance":(.02 if rank>=8 else 0.0)+(.02 if rank>=13 else 0.0)+(.02 if rank>=18 else 0.0),"damage":clampi(rank-7,0,10)*.05}
func active_bonus()->Dictionary:return bonus(tier_from(cached_sum))
func display_tier()->int:return tier_from(cached_sum)
func expiry_schedule(force:bool=false)->Array:
 if not force and now()<expiry_cache_until:return expiry_cache
 var rank=tier_from(cached_sum);var remaining=cached_sum;var values:Array=[];values.resize(rank);values.fill(int(now())+WINDOW)
 for b in state().buckets:
  if int(b[0])>int(now()/60):continue
  remaining-=float(b[1])
  while rank>0 and remaining<GOALS[rank-1]:values[rank-1]=int(b[0])*60+WINDOW;rank-=1
  if rank==0:break
 expiry_cache=values;expiry_cache_until=now()+10;return values
static func clean_expiry(value:Variant,rank:int,timestamp:float)->Array:
 if not value is Array or value.size()!=rank:return []
 var result:Array=[];var previous=timestamp+WINDOW
 for expiry in value:
  if not preload("res://scripts/workshop_project.gd").number(expiry,0,timestamp+WINDOW) or float(expiry)!=floorf(float(expiry)) or float(expiry)>previous:return []
  previous=float(expiry);result.append(int(expiry))
 return result
static func timed_tier(value:Dictionary,timestamp:float)->int:
 var rank=remote_active_tier({"crown_damage":value.get("crown_damage",0)})
 var expiries=clean_expiry(value.get("crown_expiry",[]),rank,timestamp)
 if expiries.size()!=rank:return 0
 while rank>0 and float(expiries[rank-1])<=timestamp:rank-=1
 return rank
func payload()->Dictionary:return {"crown_damage":int(minf(1e12,cached_sum)),"crown_tier":tier_from(cached_sum),"crown_best":int(state().best_tier),"crown_expiry":expiry_schedule()}
static func remote_active_tier(value:Dictionary)->int:
 var amount=value.get("crown_damage",0)
 return tier_from(float(amount)) if preload("res://scripts/workshop_project.gd").number(amount,0,1e12) else 0
static func remote_tier(value:Dictionary)->int:return timed_tier(value,Time.get_unix_time_from_system()) if value.has("crown_expiry") else remote_active_tier(value)
func ui(parent:Node)->void:
 refresh()
 var ui=preload("res://scripts/studio_ui.gd");var rank=tier_from(cached_sum);var powers=bonus(rank)
 var box=ui.card(parent,"CROWN JOURNEY", "Damage dealt across your last seven days • all heroes share this progress")
 var row=HBoxContainer.new();row.add_theme_constant_override("separation",18);box.add_child(row)
 var preview=preload("res://scripts/crown_view.gd").new();preview.rank=rank;row.add_child(preview)
 var info=VBoxContainer.new();info.size_flags_horizontal=Control.SIZE_EXPAND_FILL;row.add_child(info)
 line(info,rank_name(rank),23)
 line(info,"%d / %d damage" % [int(cached_sum),GOALS[rank]] if rank<GOALS.size() else "%d damage • highest crown reached" % int(cached_sum),17)
 var bar=ProgressBar.new();bar.custom_minimum_size.y=20;bar.show_percentage=false;bar.max_value=GOALS[rank] if rank<GOALS.size() else GOALS.back();bar.min_value=GOALS[rank-1] if rank>0 and rank<GOALS.size() else 0;bar.value=cached_sum;info.add_child(bar)
 line(info,"Next • "+rank_name(rank+1) if rank<GOALS.size() else "Beyonder • beyond the known paths",15)
 line(box,"ACTIVE POWER  •  +%.0f%% crit chance  •  +%.0f%% crit damage" % [float(powers.chance)*100,float(powers.damage)*100],17)
 line(box,"Power follows your rolling seven-day crown. Competition matches disable crown bonuses for everyone.",14)
 var archive=ui.card(parent,"PERSONAL BEST",rank_name(int(state().best_tier))+" • highest recorded crown")
 line(archive,"Record only • keep playing to maintain your visible crown and its power. Expired crowns cannot be equipped.",15)
static func line(parent:Node,value:String,fs:int)->void:
 var label=Label.new();label.text=value;label.add_theme_font_size_override("font_size",fs);label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;parent.add_child(label)
static func draw_on(c:CanvasItem,p:Vector2,t:float,tier:int)->void:
 if tier<1 or tier>GOALS.size():return
 var ink=Color(COLORS[tier-1]);var alpha=.28+.06*sin(t*1.8)
 c.draw_arc(p-Vector2(0,18),26,0,TAU,32,Color(ink,alpha),1.5,true)
 var top=p-Vector2(0,38+sin(t*2)*1.2);var width=6+mini(tier,5)
 var points=PackedVector2Array([top+Vector2(-width,7),top+Vector2(-width,-4),top+Vector2(-width*.5,1),top+Vector2(0,-8),top+Vector2(width*.5,1),top+Vector2(width,-4),top+Vector2(width,7)])
 c.draw_colored_polygon(points,Color(ink,.85));c.draw_polyline(points,ink,1.2,true);c.draw_line(top+Vector2(-width,8),top+Vector2(width,8),ink,2,true)
 if tier>=3:c.draw_circle(top+Vector2(0,3),2,Color("#19343c"))
 if tier>=5:
  for side in [-1,1]:c.draw_circle(top+Vector2(side*width*.55,4),1.6,Color("#fcf4ce"))
 if tier>=7:
  for side in [-1,1]:c.draw_line(top+Vector2(side*(width+2),7),top+Vector2(side*(width+6),-1),Color(ink,.7),1.5,true)
 if tier>=8:
  var stage=clampi(tier-7 if tier<13 else tier-12,1,5)
  for n in 5:c.draw_circle(top+Vector2((n-2)*5,14),1.65,ink if n<stage else Color(ink,.17))
 if tier>=13:
  for side in [-1,1]:
   c.draw_polyline(PackedVector2Array([top+Vector2(side*13,4),top+Vector2(side*21,-4),top+Vector2(side*16,-14),top+Vector2(side*10,-8)]),ink,1.4,true)
  for n in 3:
   var a=t*.6+n*TAU/3;c.draw_circle(top+Vector2(cos(a)*25,sin(a)*10),1.2,Color(ink,.7))
 if tier==18:
  c.draw_arc(top,32,-PI*.85+t*.12,PI*.85+t*.12,40,Color(ink,.5),1.4,true)
  for n in 4:
   var v=top+Vector2.from_angle(t*.25+n*TAU/4)*30;c.draw_line(v-Vector2(0,3),v+Vector2(0,3),ink,1,true);c.draw_line(v-Vector2(3,0),v+Vector2(3,0),ink,1,true)

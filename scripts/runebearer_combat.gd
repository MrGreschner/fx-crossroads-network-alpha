extends Node
var combat:Node
var next_rune:Dictionary={}
var verdicts:Array=[]
var flashes:Array=[]
const STYLES=["rune_hammer","rune_cycle","triune_verdict"]
const RUNES=["Might","Stride","Ward"]
const EFFECTS=["rune_might","rune_stride","rune_ward"]
const COLOURS=["#efb976","#86dac4","#a3c9ed"]
func reset()->void:next_rune.clear();verdicts.clear();flashes.clear()
func cast(owner:String,stats:Dictionary,aim:Vector2,amount:float)->bool:
 var style:=str(stats.get("style",""))
 if style not in STYLES:return false
 if not combat.adventure.authoritative() or not combat.adventure.alive(owner):return true
 var origin:Vector2=combat.owner_pos(owner);aim=aim.normalized()
 if aim.is_zero_approx():aim=Vector2.RIGHT
 match style:
  "rune_hammer":
   var shot:Dictionary=stats.duplicate(true);shot.rune_hammer=true;shot.splash_radius=float(stats.get("splash_radius",65));shot.splash_damage=float(stats.get("splash_damage",8));shot.color="#e6c491"
   combat.launch_projectile(owner,origin+aim*24,aim,shot,amount)
  "rune_cycle":
   var index:=int(next_rune.get(owner,0))%3
   var effects:Dictionary=combat.statuses.get(combat.player_key(owner),{})
   for effect in EFFECTS:effects.erase(effect)
   combat.statuses[combat.player_key(owner)]=effects
   if index==2 and combat.passive(owner,"purifying_rune"):
    for effect in ["burn","bleed","poison"]:effects.erase(effect)
   combat.apply_status(combat.player_key(owner),EFFECTS[index],float(stats.get("duration",4.5)),owner,[.2,.3,.35][index])
   next_rune[owner]=(index+1)%3
   flashes.append({"owner":owner,"pos":combat.point_array(origin),"time":.65,"rune":index})
  "triune_verdict":
   if verdicts.size()>=8:return true
   var point:Vector2=combat.chain.clip(origin,aim,float(stats.get("range",240)))
   verdicts.append({"owner":owner,"pos":combat.point_array(point),"aim":combat.point_array(aim),"elapsed":0.0,"phase":0,"damage":amount,"base":float(stats.get("damage",28))})
 return true
func strike(entry:Dictionary,phase:int)->void:
 var owner:=str(entry.owner);var point:Vector2=combat.vec(entry.pos);var aim:Vector2=combat.vec(entry.aim)
 var radius:float=[75,125,155][phase]
 var damage:float=[24,28,38][phase]+float(entry.damage)-float(entry.base)
 for key in combat.hostile(owner):
  var target:Dictionary=combat.actor(key)
  if target.is_empty() or not bool(target.get("alive",false)):continue
  var offset:Vector2=target.pos-point
  var inside:=offset.length()<=radius
  if phase==1:inside=absf(offset.dot(aim))<=32 and absf(offset.dot(aim.rotated(PI*.5)))<=125
  if not inside or not combat.path_clear(point,target.pos):continue
  combat.damage(key,damage,owner)
  if phase==0:combat.knock(key,offset.normalized(),25)
  if phase==1:combat.apply_status(key,"slow",1.5,owner,.7)
  if phase==2:combat.apply_status(key,"stun",.65,owner)
 flashes.append({"owner":owner,"pos":entry.pos,"aim":entry.aim,"time":.35,"phase":phase})
func step(delta:float)->void:
 if not combat.adventure.authoritative():return
 for i in range(flashes.size()-1,-1,-1):
  flashes[i].time-=delta
  if float(flashes[i].time)<=0:flashes.remove_at(i)
 for i in range(verdicts.size()-1,-1,-1):
  var entry:Dictionary=verdicts[i];entry.elapsed+=delta
  if not combat.adventure.alive(str(entry.owner)):verdicts.remove_at(i);continue
  while int(entry.phase)<3 and float(entry.elapsed)>=[.45,.95,1.5][int(entry.phase)]:strike(entry,int(entry.phase));entry.phase+=1
  if int(entry.phase)>=3:verdicts.remove_at(i)
func snapshot()->Dictionary:return {"next_rune":next_rune,"verdicts":verdicts,"flashes":flashes}
func receive(data:Dictionary)->void:next_rune=data.get("next_rune",{});verdicts=data.get("verdicts",[]);flashes=data.get("flashes",[])
func draw_mark(canvas:Node2D,point:Vector2,phase:int,aim:Vector2,tint:Color)->void:
 if phase==0:
  canvas.draw_arc(point,75,0,TAU,32,tint,3,true)
  for n in 3:canvas.draw_line(point+Vector2.from_angle(TAU*n/3)*25,point+Vector2.from_angle(TAU*n/3)*70,tint,3,true)
 elif phase==1:
  var side:=aim.rotated(PI*.5)
  canvas.draw_line(point-side*125,point+side*125,tint,5,true)
  for sign in [-1,1]:canvas.draw_line(point+side*sign*100-aim*15,point+side*sign*125,tint,3,true)
 else:
  canvas.draw_arc(point,155,0,TAU,48,tint,4,true)
  for n in 6:
   var start:=point+Vector2.from_angle(TAU*n/6)*60;var end:=point+Vector2.from_angle(TAU*n/6+.3)*140
   canvas.draw_line(start,end,tint,3,true)
func draw_on(canvas:Node2D,camera:Vector2)->void:
 for entry in verdicts:
  var phase:=mini(2,int(entry.phase));var tint:=Color(COLOURS[phase]);tint.a=.45
  draw_mark(canvas,combat.vec(entry.pos)-camera,phase,combat.vec(entry.aim),tint)
 for entry in flashes:
  var tint:=Color(COLOURS[int(entry.get("rune",entry.get("phase",0)))]);tint.a=minf(1,float(entry.time)*3)
  var point:Vector2=combat.vec(entry.pos)-camera
  if entry.has("phase"):draw_mark(canvas,point,int(entry.phase),combat.vec(entry.aim),tint)
  else:canvas.draw_arc(point,35+(1-float(entry.time)/.65)*25,0,TAU,32,tint,3,true)
 for owner in combat.adventure.points():
  var id:=str(owner);var game:Node=combat.adventure.game
  var hero:Dictionary=game.characters.get(str(game.hero_ids.get(id,"ram")),{}) if combat.adventure.arcade else game.hero
  if not combat.adventure.alive(id) or str(hero.get("secondary",{}).get("style",""))!="rune_cycle":continue
  var point:Vector2=combat.owner_pos(id)-camera;var index:=int(next_rune.get(id,0))%3
  canvas.draw_string(ThemeDB.fallback_font,point+Vector2(-38,48),"Next: "+RUNES[index],HORIZONTAL_ALIGNMENT_LEFT,-1,12,Color(COLOURS[index]))
  for n in 3:
   var tint:=Color(COLOURS[n]);tint.a=1 if n==index else .3
   canvas.draw_circle(point+Vector2(-43,-20+n*12),4,tint)
   if combat.effect_time(combat.player_key(id),EFFECTS[n])>0:canvas.draw_arc(point,31,-PI*.8,-PI*.2,16,Color(COLOURS[n]),3,true)

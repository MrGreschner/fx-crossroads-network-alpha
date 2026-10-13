extends Node
## Cosmetic contact confirmation. Never predicts hits or alters combat authority.
var combat:Node
var contacts:Array=[]
var guides:=false
var healing_numbers:Array=[]
var observed_health:Dictionary={}
var observed_match:=""
func _ready()->void:
 var cfg:=ConfigFile.new();cfg.load("user://fx_combat_view.cfg");guides=bool(cfg.get_value("view","guides",false))
func set_guides(value:bool)->void:
 guides=value;var cfg:=ConfigFile.new();cfg.set_value("view","guides",value);cfg.save("user://fx_combat_view.cfg")
func hit(point:Vector2,amount:float,victim:String="",healing:bool=false)->void:
 if amount<=0 or not combat.playing():return
 if not victim.is_empty() and not combat.visible_owner(victim):return
 for entry in contacts:
  if entry.pos.distance_to(point)<12 and bool(entry.healing)==healing:entry.time=.18;return
 if contacts.size()>=24:contacts.pop_front()
 contacts.append({"pos":point,"victim":victim,"time":.18,"healing":healing})
func healed(victim:String,point:Vector2,amount:float)->void:
 if amount<=0 or not combat.playing() or not combat.visible_owner(victim):return
 if combat.adventure.arcade:observed_health[victim]=float(combat.adventure.game.health.get(victim,0))
 for entry in healing_numbers:
  if entry.victim==victim and float(entry.age)<.22:
   entry.amount=float(entry.amount)+amount;entry.time=.85;return
 if healing_numbers.size()>=24:healing_numbers.pop_front()
 healing_numbers.append({"victim":victim,"pos":point,"amount":amount,"time":.85,"age":0.0})
func _process(delta:float)->void:
 if not combat.playing():contacts.clear();healing_numbers.clear();observed_health.clear();return
 if combat.adventure.arcade:
  var g=combat.adventure.game
  var current_match=str(g.match_id)
  if current_match!=observed_match:observed_health.clear();observed_match=current_match
  for id in g.health:
   var hp:float=g.health[id];var old:float=observed_health.get(id,hp)
   if old>0 and hp>old:healed(str(id),g.positions.get(id,Vector2.ZERO),hp-old)
   observed_health[id]=hp
 for i in range(healing_numbers.size()-1,-1,-1):
  healing_numbers[i].time=float(healing_numbers[i].time)-delta;healing_numbers[i].age=float(healing_numbers[i].age)+delta
  if float(healing_numbers[i].time)<=0:healing_numbers.remove_at(i)
 for i in range(contacts.size()-1,-1,-1):
  contacts[i].time-=delta
  if float(contacts[i].time)<=0:contacts.remove_at(i)
func draw_on(canvas:Node2D,camera:Vector2)->void:
 for entry in contacts:
  if not str(entry.victim).is_empty() and not combat.visible_owner(str(entry.victim)):continue
  var p:Vector2=entry.pos-camera
  if not Rect2(Vector2(-30,-30),canvas.get_viewport_rect().size+Vector2(60,60)).has_point(p):continue
  var alpha:=clampf(float(entry.time)/.18,0,1);var r:=9+(1-alpha)*9
  var tint:=Color(.65,1,.73,alpha) if bool(entry.healing) else Color(1,.91,.68,alpha)
  if bool(entry.healing):canvas.draw_line(p-Vector2(7,0),p+Vector2(7,0),tint,2,true);canvas.draw_line(p-Vector2(0,7),p+Vector2(0,7),tint,2,true)
  else:
   for n in 4:
    var d:=Vector2.RIGHT.rotated(PI*.25+n*PI*.5);canvas.draw_line(p+d*r*.6,p+d*r,tint,2,true)
 for entry in healing_numbers:
  if not combat.visible_owner(str(entry.victim)):continue
  var world:Vector2=combat.owner_pos(str(entry.victim))
  var p:Vector2=world-camera+Vector2(-20,-70-float(entry.age)*25)
  if not Rect2(Vector2(-60,-60),canvas.get_viewport_rect().size+Vector2(120,120)).has_point(p):continue
  var alpha:float=minf(1,float(entry.time)*3)
  var value:String="+"+(str(int(round(float(entry.amount)))) if is_equal_approx(float(entry.amount),round(float(entry.amount))) else str(snappedf(float(entry.amount),.1)))
  var font:Font=preload("res://assets/fonts/CrossroadsUI.ttf")
  canvas.draw_string(font,p+Vector2(1,2),value,HORIZONTAL_ALIGNMENT_LEFT,-1,20,Color(0,.12,.06,alpha))
  canvas.draw_string(font,p,value,HORIZONTAL_ALIGNMENT_LEFT,-1,20,Color(.42,1,.55,alpha))
 if guides:draw_guide(canvas,camera)
func guide_stats()->Dictionary:
 var g:Node=combat.adventure.game;var owner:String=g.my_id if combat.adventure.arcade else "solo"
 if combat.adventure.arcade:
  if g.spectating() or not g.shop_open.is_empty() or not combat.adventure.alive(owner):return {}
 elif g.mode!="run" or not g.menu.is_empty() or g.health<=0:return {}
 var id:String=str(g.hero_ids.get(owner,"ram")) if combat.adventure.arcade else str(g.character_id)
 var h:Dictionary=g.characters.get(id,{})
 var stats:Dictionary=g.legacy.stats(owner,"primary",h.get("primary",{}))
 if str(stats.get("style","")) not in ["melee","punch","scratch","slash","kick","identity_strike"]:return {}
 return {"owner":owner,"range":float(stats.get("range",82)),"half_arc":deg_to_rad(float(stats.get("arc_degrees",105))*.5)}
func draw_guide(canvas:Node2D,camera:Vector2)->void:
 var spec:=guide_stats()
 if spec.is_empty():return
 var g:Node=combat.adventure.game;var aim:Vector2=(g.mobile.aim if g.mobile.enabled else ((g.media_mouse_world())-combat.owner_pos(str(spec.owner))).normalized()) if combat.adventure.arcade else g.aim_direction()
 if aim.is_zero_approx():return
 var p:Vector2=combat.owner_pos(str(spec.owner))-camera;var angle:=aim.angle();var half:float=spec.half_arc;var reach:float=spec.range;var tint:=Color(.55,.82,.95,.25)
 canvas.draw_arc(p,reach,angle-half,angle+half,20,tint,1.5,true)
 for sign in [-1,1]:canvas.draw_line(p+aim.rotated(half*sign)*25,p+aim.rotated(half*sign)*reach,tint,1,true)

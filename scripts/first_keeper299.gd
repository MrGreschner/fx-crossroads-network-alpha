extends RefCounted
## A gentle tutorial guardian: fixed facing, locked tells, three distinct dodge lessons.
static var frames:Array=[]
static func prepare()->void:
 if not frames.is_empty():return
 var atlas=preload("res://scripts/first_environment299.gd").texture("keeper")
 for n in 4:
  var t=AtlasTexture.new();t.atlas=atlas;t.region=Rect2(n*192,0,192,192);frames.append(t)
static func hit(g:Node,e:Dictionary,amount:float,label:String)->void:
 g.take_player_damage(amount,g.adventure.combat.npc_key(e),preload("res://scripts/defeat_credit.gd").resolve(g,g.adventure.combat.npc_key(e),label))
static func step(g:Node,e:Dictionary,dt:float)->void:
 if not e.has("keeper299"):e.keeper299={"turn":0,"style":"","aim":[0,0],"marks":[],"bolts":[],"cast":0}
 var s:Dictionary=e.keeper299
 for i in range(s.bolts.size()-1,-1,-1):
  var b:Dictionary=s.bolts[i];var p=Vector2(b.pos[0],b.pos[1]);var dir=Vector2(b.dir[0],b.dir[1]);var q=p+dir*225*dt;b.left=float(b.left)-dt
  if Geometry2D.get_closest_point_to_segment(g.position_in_world,p,q).distance_to(g.position_in_world)<24:hit(g,e,9,"Keeper's lantern spark");s.bolts.remove_at(i)
  elif b.left<=0 or not Rect2(35,35,1730,1130).has_point(q):s.bolts.remove_at(i)
  else:b.pos=[q.x,q.y]
 for i in range(s.marks.size()-1,-1,-1):
  var mark:Dictionary=s.marks[i];mark.left=float(mark.left)-dt
  if mark.left<=0:
   if g.position_in_world.distance_to(Vector2(mark.pos[0],mark.pos[1]))<60:hit(g,e,10,"Keeper's dawn mark")
   g.attack_effects.append({"center":Vector2(mark.pos[0],mark.pos[1]),"radius":60,"time":.4,"color":Color("#dbc88a")});s.marks.remove_at(i)
 if g.adventure.combat.stunned(g.adventure.combat.npc_key(e)):e.moving=0;return
 e.attack_timer=maxf(0,float(e.attack_timer)-dt)
 if float(e.windup)>0:
  e.windup=maxf(0,float(e.windup)-dt);e.moving=0
  if float(e.windup)<=0:
   var aim=Vector2(s.aim[0],s.aim[1]);var dir=(aim-(e.pos as Vector2)).normalized();e.strike_flash=.35;e.strike_direction=dir;e.attack_timer=2.0;s.cast=int(s.cast)+1
   match str(s.style):
    "stomp":
     if g.position_in_world.distance_to(e.pos)<125:hit(g,e,12,"Dawnstone training stomp")
     g.attack_effects.append({"center":e.pos,"radius":125,"time":.45,"color":Color("#e1cd97")})
    "sparks":
     for k in 3:
      var ray=dir.rotated((k-1)*.24);s.bolts.append({"pos":[e.pos.x,e.pos.y],"dir":[ray.x,ray.y],"left":5.5})
    "marks":
     for k in 3:s.marks.append({"pos":[clampf(aim.x+(k-1)*135,250,1550),clampf(aim.y,330,870)],"left":.85+k*.35})
  return
 var diff:Vector2=g.position_in_world-e.pos
 if e.attack_timer<=0:
  var style=["stomp","sparks","marks"][int(s.turn)%3];s.turn=int(s.turn)+1
  if style=="stomp" and diff.length()>140:style="sparks"
  s.style=style;s.aim=[g.position_in_world.x,g.position_in_world.y];e.windup=1.25;e.warning_direction=diff.normalized();return
 if diff.length()>180:e.moving=92;g.move_enemy_around_obstacles(e,diff.normalized()*92*dt,false)
 else:e.moving=0
static func draw_body(c:CanvasItem,e:Dictionary,p:Vector2,t:float)->void:
 prepare()
 var index=3 if float(e.get("windup",0))>0 else 1+int(t*5)%2 if float(e.get("moving",0))>0 else 0
 c.draw_texture_rect(frames[index],Rect2(p-Vector2(70,101),Vector2(140,148)),false)
static func draw_cues(c:CanvasItem,g:Node,e:Dictionary,cam:Vector2)->void:
 var s:Dictionary=e.get("keeper299",{});var p:Vector2=e.pos-cam
 if float(e.windup)>0:
  var aim=Vector2(s.aim[0],s.aim[1])-cam;var style=str(s.style)
  if style=="stomp":preload("res://scripts/combat_cues.gd").danger(c,p,125,float(e.windup),1.25)
  elif style=="sparks":
   var dir=(aim-p).normalized()
   for k in 3:c.draw_line(p,p+dir.rotated((k-1)*.24)*390,Color(.83,.68,.33,.55),2,true)
  else:c.draw_arc(aim,60,0,TAU,30,Color("#e5c780"),3,true)
 for b in s.get("bolts",[]):
  var q=Vector2(b.pos[0],b.pos[1])-cam;c.draw_circle(q,8,Color("#c7984a"));c.draw_circle(q,4,Color("#f7e5a3"))
 for mark in s.get("marks",[]):
  var q=Vector2(mark.pos[0],mark.pos[1])-cam;c.draw_circle(q,60,Color(.9,.75,.4,.12));c.draw_arc(q,60,0,TAU,32,Color("#d6ae63"),2,true)

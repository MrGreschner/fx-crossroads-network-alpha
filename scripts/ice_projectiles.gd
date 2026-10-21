extends RefCounted
static func matches(kind:String)->bool:return kind in ["ice_archer","snow_oracle"]
static func fire(g:Node,enemy:Dictionary,aim:Vector2,definition:Dictionary,boss=false)->void:
 var oracle=boss or str(enemy.get("type",""))=="snow_oracle"
 var stats={"name":"Seeking Ice" if oracle else "Ice Spear","range":850,"speed":220.0 if oracle else float(definition.get("shot_speed",315)),"ice_visual":"orb" if oracle else "spear","projectile_radius":9.0 if oracle else 6.0,"color":"#a4e9ff","credit":preload("res://scripts/defeat_credit.gd").resolve(g,g.adventure.combat.npc_key(enemy),"Seeking Ice" if oracle else "Ice Spear")}
 for offset in [-.22,.22] if boss else [0.0]:g.adventure.combat.launch_projectile("enemy",enemy.pos,aim.rotated(offset),stats.duplicate(true),12.0 if boss else float(definition.get("damage",11)),"homing" if oracle else "pellet")
static func step_boss(g:Node,enemy:Dictionary,dt:float)->void:
 var realm=str(g.realm_id) if g.get("realm_id")!=null else str(g.region_id)
 if realm!="ice" or not enemy.get("boss",false):return
 enemy.ice_seek_timer=float(enemy.get("ice_seek_timer",5.0))-dt
 if enemy.ice_seek_timer>0:return
 var target:Vector2=g.position_in_world if g.get("position_in_world")!=null else enemy.pos+Vector2.LEFT*200
 if g.get("positions") is Dictionary:
  var nearest=INF
  for key in g.positions:
   if enemy.pos.distance_to(g.positions[key])<nearest:nearest=enemy.pos.distance_to(g.positions[key]);target=g.positions[key]
 fire(g,enemy,(target-enemy.pos).normalized(),{},true);enemy.ice_seek_timer=8.0
static func draw(c:Node2D,point:Vector2,aim:Vector2,kind:String,clock:float)->void:
 var side=aim.orthogonal()
 if kind=="spear":
  c.draw_line(point-aim*23,point+aim*11,Color("#87cced"),3,true)
  c.draw_colored_polygon(PackedVector2Array([point+aim*18,point+side*6,point-aim*8,point-side*6]),Color("#bceeff"))
  c.draw_line(point-aim*10,point+aim*14,Color("#f4ffff"),1.5,true)
 else:
  c.draw_circle(point,13,Color(.4,.75,1,.20));c.draw_circle(point,8,Color("#8dcdf1"));c.draw_circle(point-Vector2(2,2),4,Color("#dcfaff"))
  for n in 3:
   var d=Vector2.from_angle(clock*2+n*TAU/3);c.draw_line(point+d*7,point+d*12,Color("#d5f4ff"),1.5,true)

extends RefCounted
static func warm()->void:
 if DisplayServer.get_name()=="headless":return
 for side in 2:
  for kind in 8:
   for pose in 6:preload("res://scripts/source_art.gd").texture("res://assets/battlegrounds/%d_%d_%d.svg" % [side,kind,pose])
static func draw_unit(c:Node2D,u:Dictionary,p:Vector2,clock:float)->void:
 var kind=clampi(int(u.kind),0,7);var side=clampi(int(u.team),0,1);var pose=4
 if bool(u.get("moving",false)):pose=posmod(int(float(u.get("walk",0))*4/TAU),4)
 if clock-float(u.get("attack_at",-10))>=0 and clock-float(u.get("attack_at",-10))<.3:pose=5
 var texture=preload("res://scripts/source_art.gd").texture("res://assets/battlegrounds/%d_%d_%d.svg" % [side,kind,pose])
 if texture!=null:c.draw_texture_rect(texture,Rect2(p-Vector2(35,46),Vector2(70,84)),false)
 var ratio=clampf(float(u.hp)/maxf(1,float(u.max_hp)),0,1)
 c.draw_rect(Rect2(p+Vector2(-16,34),Vector2(32,3)),Color("#283a42"));c.draw_rect(Rect2(p+Vector2(-16,34),Vector2(32*ratio,3)),Color("#79cdd7") if side==0 else Color("#e9a48a"))

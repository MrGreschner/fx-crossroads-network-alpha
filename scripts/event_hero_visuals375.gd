extends RefCounted
## Ability geometry layered around the approved front-facing sprites, without warping faces.
static func jaws(c:Node2D,p:Vector2,aim:Vector2,size:float,opening:float)->void:
 var side=aim.orthogonal();var back=p-aim*size*.6;var tip=p+aim*size*.55
 for sign_value in [-1.0,1.0]:
  var spread=side*sign_value*opening*size
  var outer=PackedVector2Array([back+spread*.32-side*sign_value*3,back+spread,tip+spread*.68,tip+spread*.22])
  c.draw_colored_polygon(outer,Color("#49786c"));outer.append(outer[0]);c.draw_polyline(outer,Color("#34554d"),2)
  for i in 3:
   var tooth=back.lerp(tip,.4+i*.2)+spread*.65
   c.draw_colored_polygon(PackedVector2Array([tooth-aim*3,tooth+aim*3,tooth-side*sign_value*5]),Color("#d7c6a0"))
static func bite(c:Node2D,p:Vector2,f:Dictionary,combat:Node)->void:
 var aim=combat.vec(f.aim);var reach=float(f.radius);var t=1.0-clampf(float(f.time)/.32,0,1)
 var contact=p+aim*reach*lerpf(.32,.83,smoothstep(0,.45,t))-Vector2(0,9)
 var opening=lerpf(.6,.08,smoothstep(.15,.7,t))
 jaws(c,contact,aim,minf(40,reach*.55),opening)
 # A restrained arc marks the actual bite range, then fades with the recovery.
 c.draw_arc(p,reach,aim.angle()-acos(.15),aim.angle()+acos(.15),22,Color(.83,.74,.52,.45*(1-t)),2)
 if t>.5:
  for i in 3:
   var d=aim.rotated((i-1)*.9);c.draw_line(contact+d*14,contact+d*21,Color(.9,.78,.55,(1-t)*1.3),2)
static func latch(c:Node2D,camera:Vector2,combat:Node,id:String,q:Dictionary,local:bool)->void:
 var target=combat.actor(str(q.target))
 if not target.get("alive",false):return
 var owner=combat.owner_pos(id)-camera-Vector2(0,17)
 var p:Vector2=target.pos-camera-Vector2(0,10);var aim=(p-owner).normalized()
 if aim.is_zero_approx():aim=Vector2.RIGHT
 var contact=p-aim*8
 c.draw_line(owner,contact,Color("#34554d"),5);c.draw_line(owner,contact,Color("#ba9c68"),2)
 for i in 3:c.draw_arc(owner.lerp(contact,(i+1)/4.0),3,0,TAU,8,Color("#c8b07d"),1)
 jaws(c,contact,aim,28,.12+.035*sin(float(q.get("tick",0))*TAU))
 # A small lock clasp makes the attached state readable even over larger targets.
 var lock=contact+Vector2(0,-25)
 c.draw_arc(lock-Vector2(0,4),4,PI,TAU,8,Color("#d3bb80"),2)
 c.draw_rect(Rect2(lock-Vector2(5,3),Vector2(10,9)),Color("#a98a59"));c.draw_line(lock+Vector2(0,-1),lock+Vector2(0,3),Color("#344e49"),2)
 if local:
  var seconds=combat.events.display_time(float(q.time))
  c.draw_style_box(plate(),Rect2(owner+Vector2(-111,-90),Vector2(246,22)))
  c.draw_string(ThemeDB.fallback_font,owner+Vector2(-108,-74),"LATCHED • %.1fs • Secondary: release" % seconds,HORIZONTAL_ALIGNMENT_CENTER,240,13,Color("#ecd09a"))

static var ability_plate:StyleBoxFlat
static func plate()->StyleBoxFlat:
 if ability_plate==null:
  ability_plate=StyleBoxFlat.new();ability_plate.bg_color=Color(.07,.16,.17,.90);ability_plate.set_corner_radius_all(4)
 return ability_plate

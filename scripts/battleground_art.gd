extends RefCounted
static func warm()->void:pass # Lazy per-visible-role loading avoids rasterizing a whole army at match start.
static func pose(u:Dictionary,clock:float)->int:
 var elapsed=clock-float(u.get("attack_at",-10))
 if elapsed>=0 and elapsed<.18:return 6
 if elapsed>=.18 and elapsed<.48:return 7
 if bool(u.get("winding",false)):return 5
 return posmod(int(float(u.get("walk",0))*4/TAU),4) if bool(u.get("moving",false)) else 4
static func draw_unit(c:Node2D,u:Dictionary,p:Vector2,clock:float)->void:
 var kind=clampi(int(u.kind),0,10);var side=clampi(int(u.team),0,1);var frame=pose(u,clock)
 var id="bg_%d_%d" % [side,kind]
 var phase=3 if frame in [5,6,7] else 1+posmod(frame,2) if frame<4 else 0
 var scale=1.15 if kind==6 else 1.1 if kind in [3,9] else 1.0
 preload("res://scripts/unit_art231.gd").draw(c,id,p+Vector2(0,32*scale),phase,preload("res://scripts/unit_art231.gd").world_height(id)*scale)
 var ratio=clampf(float(u.hp)/maxf(1,float(u.max_hp)),0,1)
 c.draw_rect(Rect2(p+Vector2(-16,38*scale),Vector2(32,3)),Color("#283a42"));c.draw_rect(Rect2(p+Vector2(-16,38*scale),Vector2(32*ratio,3)),Color("#79cdd7") if side==0 else Color("#e9a48a"))
static func capital(c:Node2D,p:Vector2,side:int,hp:float)->void:
 var texture=preload("res://scripts/source_art.gd").texture("res://assets/battlegrounds/capital_%d.svg" % side)
 if texture!=null:c.draw_texture_rect(texture,Rect2(p-Vector2(160,180),Vector2(320,240)),false)
 var tint=Color("#8ccbd8") if side==0 else Color("#e9ad82")
 var info=p+Vector2(175 if side==0 else -375,-55)
 c.draw_style_box(preload("res://scripts/studio_ui.gd").box("#193942","#76968c",6,7),Rect2(info,Vector2(204,80)))
 c.draw_string(ThemeDB.fallback_font,info+Vector2(9,22),"CAPITAL • %d HP" % int(hp),HORIZONTAL_ALIGNMENT_LEFT,190,17,tint)
 c.draw_rect(Rect2(info+Vector2(10,32),Vector2(184,6)),Color("#243c45"));c.draw_rect(Rect2(info+Vector2(10,32),Vector2(184*clampf(hp/2600.0,0,1),6)),tint)
 c.draw_string(ThemeDB.fallback_font,info+Vector2(9,61),"ALLIED HEROES +4 HP/s",HORIZONTAL_ALIGNMENT_LEFT,190,12,Color("#bfe1cf"))

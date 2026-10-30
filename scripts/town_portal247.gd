extends RefCounted
## One 72-frame immutable atlas for all 3 identities, shared between world and menu.
const WORLD=Rect2(837,569.5,126,161)
const APERTURE=Vector2(900,643)
const FOOT=Vector2(900,727)
static func prepare():preload("res://scripts/realm_portals258.gd").prepare()
static func phase(time:float)->int:return preload("res://scripts/realm_portals258.gd").phase(time)
static func texture(variant:int,time:float,muted:bool=false)->Texture2D:return preload("res://scripts/realm_portals258.gd").texture(variant,time,muted)
static func world(g:Node2D,camera:Vector2):
 if not Rect2(camera,g.VIEW).intersects(WORLD):return
 g.draw_texture_rect(texture(0,g.town_life.clock),Rect2(WORLD.position-camera,WORLD.size),false)

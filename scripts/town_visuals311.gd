extends RefCounted

const Layout=preload("res://scripts/town_layout311.gd")
const ROOT="res://assets/town311/"
static var art:Dictionary={}

static func texture(id:String)->Texture2D:
 if not art.has(id):
  var image:=Image.new()
  if image.load_webp_from_buffer(FileAccess.get_file_as_bytes(ROOT+id+".webp"))!=OK:return null
  art[id]=ImageTexture.create_from_image(image)
 return art[id]

static func ground(c:Node2D,camera:Vector2)->void:
 var view:=Rect2(camera,c.VIEW)
 if view.intersects(Layout.BATTLE_PAD):
  c.draw_texture_rect(texture("muster_court"),Rect2(Layout.BATTLE_PAD.position-camera,Layout.BATTLE_PAD.size),false)
 if view.intersects(Layout.DESCENT_COURT):
  c.draw_texture_rect(texture("descent_apron"),Rect2(Layout.DESCENT_COURT.position-camera,Layout.DESCENT_COURT.size),false)

static func muster_sign(c:Node2D,camera:Vector2)->void:
 if not Rect2(camera,c.VIEW).grow(60).has_point(Layout.BATTLE_ENTRY):return
 var p:=Layout.BATTLE_ENTRY-camera
 var near:bool=c.position_in_world.distance_to(Layout.BATTLE_ENTRY)<82
 if near:c.draw_arc(p,32,0,TAU,32,Color("#d2d5a1"),1.6,true)
 var caption:="BATTLEGROUNDS"
 var plaque:=Rect2(p+Vector2(-88,56),Vector2(176,26))
 preload("res://scripts/town_streets244.gd").plaque(c,plaque)
 c.draw_string(ThemeDB.fallback_font,plaque.position+Vector2(0,18),caption,HORIZONTAL_ALIGNMENT_CENTER,176,14,Color("#f6e2aa"))

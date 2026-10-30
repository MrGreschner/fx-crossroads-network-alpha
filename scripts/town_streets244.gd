extends RefCounted
## Static art only. Original owners retain geometry, collision, schedules and services.
static var sheet:Texture2D
static var specs:Dictionary={}
static var frames:Dictionary={}
static var plate:StyleBoxFlat
const SPRITES={"town_gate":"gate","town_banner":"banner","town_fence":"picket","creator_board":"adventure_board"}
const SIGN_FITS={"mill":Rect2(63,118,97,15),"tower":Rect2(105,100,94,13)}
static var draws=0
static func prepare()->void:
 if sheet!=null:return
 specs=JSON.parse_string(FileAccess.get_file_as_string("res://assets/town244/street.json"))
 var im=Image.new();im.load_png_from_buffer(FileAccess.get_file_as_bytes("res://assets/town244/street.png"));sheet=ImageTexture.create_from_image(im)
 for id in specs:
  var a:Array=specs[id].region;var t=AtlasTexture.new();t.atlas=sheet;t.region=Rect2(a[0],a[1],a[2],a[3]);frames[id]=t
 plate=StyleBoxFlat.new();plate.bg_color=Color("#29464a");plate.border_color=Color("#b19a72");plate.set_border_width_all(2);plate.set_corner_radius_all(1)
static func texture(id:String)->Texture2D:
 prepare();return frames[id]
static func draw(g:CanvasItem,id:String,r:Rect2,tint:Color=Color.WHITE)->void:
 if not Rect2(Vector2.ZERO,g.get_viewport_rect().size).grow(2).intersects(r):return
 g.draw_texture_rect(texture(id),r,false,tint);draws+=1
static func plaque(g:CanvasItem,r:Rect2)->void:
 prepare();g.draw_style_box(plate,r)
static func sprite(g:Node2D,id:String,r:Rect2,tint:Color)->bool:
 var key=SPRITES.get(id,"")
 if key.is_empty():return false
 # The earned stone replacement is drawn by legacy.draw_card_projects, using its old flag.
 if id=="town_fence" and bool(g.legacy.data.town.get("bastion",false)):return true
 draw(g,key,r,tint);return true
static func bench(g:CanvasItem,at:Vector2,width:float,top:float,height:float)->void:
 draw(g,"bench",Rect2(at+Vector2(-width*.5,top),Vector2(width,height)))
static func garden_rails(g:CanvasItem,camera:Vector2)->void:
 for x in [800,1080]:
  for n in 5:draw(g,"garden_rail",Rect2(Vector2(x-12,1790+n*64)-camera,Vector2(24,64)))
static func lookout(g:Node2D,camera:Vector2)->void:
 draw(g,"lookout",Rect2(Vector2(1672,280)-camera,Vector2(96,168)))
 g.draw_string(ThemeDB.fallback_font,Vector2(1672,464)-camera,"LOOKOUT",HORIZONTAL_ALIGNMENT_LEFT,-1,14,Color("#e9d9b3"))
 # Its existing light origin remains (1720,288), on the small lantern pane.

static func sign_rect(id:String,fallback:Rect2)->Rect2:
 return SIGN_FITS.get(id,fallback)

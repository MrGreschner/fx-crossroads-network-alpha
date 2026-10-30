extends Node2D
## Three existing water shapes. All geometry/textures prepared once; redraw at 8 Hz.
const T=preload("res://scripts/town_terrain247.gd")
var game:Node2D
var time=0.0
var frame=-1
var phase_for_test=-1
var updates=0
var last_view=Rect2()
static var ripples:Array=[]
var pond=PackedVector2Array()
var pond_uv=PackedVector2Array()
var marina=PackedVector2Array()
var marina_uv=PackedVector2Array()
var white=PackedColorArray([Color.WHITE])
func _ready():
 z_index=-2;texture_repeat=CanvasItem.TEXTURE_REPEAT_ENABLED
 for n in 48:
  var a=n*TAU/48;var point=Vector2(200,365)+Vector2(cos(a)*(202+sin(a*3)*7),sin(a)*(114+cos(a*5)*5));pond.append(point);pond_uv.append(point/128)
 marina=PackedVector2Array(preload("res://scripts/town_marina.gd").WATER)
 for point in marina:marina_uv.append(point/128)
 if ripples.is_empty():
  var im=Image.new();im.load_png_from_buffer(FileAccess.get_file_as_bytes("res://assets/town247/ripples.png"))
  for n in 8:ripples.append(ImageTexture.create_from_image(im.get_region(Rect2i(n*128,0,128,128))))
 sync()
func sync():
 visible=game.mode=="town" and not game.practice and game.session_menu.page not in ["main","options","clear"]
 var view=Rect2(game.camera,game.VIEW)
 if view!=last_view:last_view=view;queue_redraw()
 position=game.media.offset()-game.camera*game.media.factor();scale=Vector2.ONE*game.media.factor()
func _process(dt:float):
 sync()
 if not visible:return
 time+=dt;var next=posmod(phase_for_test if phase_for_test>=0 else int(time*8),8)
 if next!=frame:frame=next;updates+=1;queue_redraw()
func _draw():
 if not visible:return
 var view=Rect2(game.camera,game.VIEW);var base=T.png("water");var ripple=ripples[maxi(frame,0)]
 # River splits at the inlet to avoid double-painted ripples on its overlap.
 for r in [Rect2(2280,-560,160,2850),Rect2(2280,2660,160,240)]:
  if view.intersects(r):
   draw_texture_rect(base,r,true);draw_texture_rect(ripple,r,true)
 if view.intersects(Rect2(-20,225,445,280)):
  draw_polygon(pond,white,pond_uv,base);draw_polygon(pond,white,pond_uv,ripple)
 if view.intersects(Rect2(1630,2260,810,440)):
  draw_polygon(marina,white,marina_uv,base);draw_polygon(marina,white,marina_uv,ripple)

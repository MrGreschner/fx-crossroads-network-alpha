extends Node2D
## Visible-only 8 Hz ripples on the existing river/pond, below units and bridge rails.
var game:Node2D
var last_view=Rect2()
var frame=-1
var updates=0
static var ripples:Array=[]
func _ready():
 z_index=-1;texture_repeat=CanvasItem.TEXTURE_REPEAT_ENABLED
 if ripples.is_empty():
  var im=Image.new();im.load_png_from_buffer(FileAccess.get_file_as_bytes("res://assets/town247/ripples.png"))
  for n in 8:ripples.append(ImageTexture.create_from_image(im.get_region(Rect2i(n*128,0,128,128))))
func sync():
 visible=game.mode=="defense" and game.started and game.session_menu.page not in ["main","options","clear"]
 var view=Rect2(game.camera,game.VIEW)
 if view!=last_view:last_view=view;queue_redraw()
 position=game.media.offset()-game.camera*game.media.factor();scale=Vector2.ONE*game.media.factor()
func _process(_dt:float):
 sync()
 if not visible:return
 var next=posmod(int(float(game.visual_time)*8),8)
 if next!=frame:frame=next;updates+=1;queue_redraw()
func _draw():
 if not visible or ripples.is_empty():return
 var view=Rect2(game.camera,game.VIEW)
 for rect in [Rect2(910,4110,4280,310),Rect2(5800,4110,3790,310),Rect2(2210,5410,570,380)]:
  var r:Rect2=rect.intersection(view)
  if r.has_area():draw_texture_rect_region(ripples[maxi(0,frame)],r,Rect2(r.position, r.size),Color.WHITE,false,false)

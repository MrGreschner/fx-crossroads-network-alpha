extends Node2D
## Three existing water shapes. All geometry/textures prepared once; redraw at 8 Hz.
const T=preload("res://scripts/town_terrain247.gd")
const WINTER=preload("res://scripts/town_winter358.gd")
var game:Node2D
var time=0.0
var frame=-1
var phase_for_test=-1
var updates=0
var last_view=Rect2()
var frozen=false
static var ripples:Array=[]
var pond=PackedVector2Array()
var pond_uv=PackedVector2Array()
var marina=PackedVector2Array()
var marina_uv=PackedVector2Array()
const SOUTH_CHANNEL=[Vector2(2360,2659),Vector2(2360,2848),Vector2(2362,2900),Vector2(2375,2960),Vector2(2400,3034),Vector2(2413,3100),Vector2(2443,3200)]
var white=PackedColorArray([Color.WHITE])
static var gravel:Texture2D
var south_water=PackedVector2Array()
var south_bank=PackedVector2Array()
var south_uv=PackedVector2Array()
var south_bank_uv=PackedVector2Array()

func channel_polygon(margin:float)->PackedVector2Array:
 var poly=PackedVector2Array()
 for side in [-1,1]:
  for n in SOUTH_CHANNEL.size():
   var i=n if side==-1 else SOUTH_CHANNEL.size()-1-n
   var p:Vector2=SOUTH_CHANNEL[i]
   poly.append(p+Vector2(side*(80+margin),0))
 return poly

func prepare_south_channel()->void:
 south_water=channel_polygon(0)
 south_bank=channel_polygon(12)
 for p in south_water:south_uv.append(p/128.0)
 for p in south_bank:south_bank_uv.append(p/128.0)
 if gravel==null:
  var image=Image.new()
  image.load_png_from_buffer(FileAccess.get_file_as_bytes("res://assets/lake301/gravel.png"))
  image.adjust_bcs(1.0,1.0,.40)
  gravel=ImageTexture.create_from_image(image)
func _ready():
 z_index=-2;texture_repeat=CanvasItem.TEXTURE_REPEAT_ENABLED
 prepare_south_channel()
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
 var winter=WINTER.SEASON.active(game)
 if view!=last_view or frozen!=winter:
  last_view=view
  frozen=winter
  queue_redraw()
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
 for r in [Rect2(2280,-560,160,2850)]:
  if view.intersects(r):
   draw_texture_rect(base,r,true);draw_texture_rect(ripple,r,true)
   if frozen:draw_texture_rect(WINTER.texture("ice"),r,true,Color("#b1c6cc"))
 if view.intersects(Rect2(2265,2659,275,545)) and game.position_in_world.y<2800:
  var winter_bank=Color("#c7d6d7") if frozen else Color.WHITE
  draw_polygon(south_bank,PackedColorArray([winter_bank]),south_bank_uv,gravel)
  draw_polygon(south_water,white,south_uv,base)
  draw_polygon(south_water,white,south_uv,ripple)
  if frozen:draw_polygon(south_water,PackedColorArray([Color("#b1c6cc")]),south_uv,WINTER.texture("ice"))
 if view.intersects(Rect2(-20,225,445,280)):
  if frozen:WINTER.draw_pond(self,pond,pond_uv)
  else:
   draw_polygon(pond,white,pond_uv,base);draw_polygon(pond,white,pond_uv,ripple)
 if view.intersects(Rect2(1630,2260,810,440)):
  if frozen:draw_polygon(marina,PackedColorArray([Color("#b1c6cc")]),marina_uv,WINTER.texture("ice"))
  else:
   draw_polygon(marina,white,marina_uv,base);draw_polygon(marina,white,marina_uv,ripple)

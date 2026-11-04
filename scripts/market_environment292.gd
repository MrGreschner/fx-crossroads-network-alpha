extends RefCounted
## Cached matte materials. No changes to trading state, prices, click targets or worker routes.
static var textures:Dictionary={}
const MATERIALS=["oak","stone","teal_roof","clay_roof","plum_roof","plaster"]
static func texture(id:String)->Texture2D:
 if not textures.has(id):
  var im=Image.new();im.load_png_from_buffer(FileAccess.get_file_as_bytes("res://assets/market292/"+id+".png"));textures[id]=ImageTexture.create_from_image(im)
 return textures[id]
static func panel(c:CanvasItem,id:String,r:Rect2,tint:Color=Color.WHITE)->void:
 c.draw_texture_rect(texture(id),r,true,tint)
static func roof(c:CanvasItem,id:String,points:PackedVector2Array)->void:
 var uv=PackedVector2Array()
 for p in points:uv.append((p+Vector2(16,95))/192.0)
 c.draw_polygon(points,PackedColorArray([Color.WHITE]),uv,texture(id))
static func roof_id(id:String)->String:
 if id in ["kitchen","courier","blank1"]:return "clay_roof"
 if id in ["clothier","salon","dessert"]:return "plum_roof"
 return "teal_roof"
static func street(c:CanvasItem,id:String,r:Rect2)->void:
 c.draw_texture_rect(preload("res://scripts/town_streets244.gd").texture(id),r,false)
static func tree(c:CanvasItem,p:Vector2,type:int)->void:
 var tex=preload("res://scripts/town_nature243.gd").texture("apple" if type%2==0 else "amber_willow")
 c.draw_texture_rect(tex,Rect2(p-Vector2(47,111),Vector2(94,116)),false)
static func planter(c:CanvasItem,p:Vector2)->void:
 street(c,"basket",Rect2(p-Vector2(15,22),Vector2(30,25)))
 c.draw_texture_rect(preload("res://scripts/town_nature243.gd").texture("flowers_small"),Rect2(p-Vector2(17,40),Vector2(34,30)),false)
static func tag(c:CanvasItem,at:Vector2,text:String,width:float=116)->void:
 var font=preload("res://assets/fonts/CrossroadsUI.ttf")
 var lines:Array[String]=[""]
 for word in text.split(" "):
  var trial=lines[-1]+(" " if not lines[-1].is_empty() else "")+word
  if font.get_string_size(trial,HORIZONTAL_ALIGNMENT_LEFT,-1,13).x>width-10 and not lines[-1].is_empty():lines.append(word)
  else:lines[-1]=trial
 if lines.size()>2:lines=lines.slice(0,2);lines[1]=lines[1].left(14)+"…"
 var skin=StyleBoxFlat.new();skin.bg_color=Color("#263f43",.96);skin.set_corner_radius_all(3)
 c.draw_style_box(skin,Rect2(at,Vector2(width,18*lines.size()+4)))
 for i in lines.size():c.draw_string(font,at+Vector2(5,15+18*i),lines[i],HORIZONTAL_ALIGNMENT_LEFT,-1,13,Color("#fff0cd"))

extends RefCounted
## Four small cached prop regions. Existing doors, lantern origins and collisions remain authoritative.
static var sheet:Texture2D
static var metadata:Dictionary={}
static var frames:Dictionary={}
const EXCHANGE_RECT=Rect2(-952,609,274,216)
const EXCHANGE_POSTS=[Vector2(-918,807),Vector2(-712,807)]
const EXCHANGE_WINDOWS=[Rect2(-904,744,33,40),Rect2(-760,744,33,40)]
static func texture(id:String)->Texture2D:
 if sheet==null:
  metadata=JSON.parse_string(FileAccess.get_file_as_string("res://assets/town240/props.json"))
  var im=Image.new();im.load_png_from_buffer(FileAccess.get_file_as_bytes("res://assets/town240/props.png"));sheet=ImageTexture.create_from_image(im)
 if not frames.has(id):
  var a:Array=metadata[id].region;var tex=AtlasTexture.new();tex.atlas=sheet;tex.region=Rect2(a[0],a[1],a[2],a[3]);frames[id]=tex
 return frames[id]
static func draw(g:CanvasItem,id:String,rect:Rect2,tint:Color=Color.WHITE)->void:g.draw_texture_rect(texture(id),rect,false,tint)
static func lamp_glass(p:Vector2)->Vector2:return p-Vector2(0,55)
static func lamp(g:CanvasItem,p:Vector2,night:float)->void:
 draw(g,"lamp",Rect2(p-Vector2(9,70),Vector2(18,70)))
 if night>.01:g.draw_rect(Rect2(lamp_glass(p)-Vector2(3,4),Vector2(6,8)),Color(1,.8,.43,night*.75))
static func fountain(g:CanvasItem,p:Vector2,t:float,night:float=0)->void:
 draw(g,"fountain",Rect2(p+Vector2(-56,-62),Vector2(112,98)))
 for n in 3:
  var u=fposmod(t*.42+n*.33,1);var radius=9+u*30;var points=PackedVector2Array()
  for k in 25:points.append(p+Vector2(cos(k*TAU/24)*radius,2+sin(k*TAU/24)*radius*.45))
  g.draw_polyline(points,Color(.6,.88,.9,(1-u)*.4),1,true)
 for side in [-1,1]:
  var points=PackedVector2Array()
  for k in 10:
   var u=k/9.0;points.append(p+Vector2(side*(5+29*u),-48+u*u*49))
  g.draw_polyline(points,Color(.62,.85,.88,.65),2,true)
  for k in 3:
   var u=fposmod(t*.7+k*.33,1);g.draw_circle(p+Vector2(side*(5+29*u),-48+u*u*49),1.6,Color(.83,.96,.96,.8))
 if night>.05:g.draw_circle(p-Vector2(0,48),4,Color(.52,.88,.95,night*.45))
static func exchange(g:Node2D,camera:Vector2,night:float)->void:
 draw(g,"exchange",Rect2(EXCHANGE_RECT.position-camera,EXCHANGE_RECT.size))
 var font:Font=preload("res://assets/fonts/CrossroadsUI.ttf")
 g.draw_string(font,Vector2(-882,715)-camera,"DEEPWELL EXCHANGE",HORIZONTAL_ALIGNMENT_CENTER,134,11,Color("#edd5a0"))
 if night>.01:
  for window in EXCHANGE_WINDOWS:
   for row in 2:
    for col in 2:
     var at=window.position+Vector2(col*18,row*22)-camera;g.draw_rect(Rect2(at,Vector2(13,16)),Color(1,.75,.36,night*.65))
 for at in EXCHANGE_POSTS:lamp(g,at-camera,night)
static func light_sources()->Array:
 var result=[]
 for p in EXCHANGE_POSTS:result.append({"at":lamp_glass(p),"radius":130.0,"strength":.9})
 for window in EXCHANGE_WINDOWS:result.append({"at":window.get_center(),"radius":95.0,"strength":.75})
 for p in [Vector2(-1030,1010),Vector2(1460,1880)]:result.append({"at":p-Vector2(0,48),"radius":105.0,"strength":.55,"portal":true})
 return result

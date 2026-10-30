extends RefCounted
## Cached landmark art. World doors, collision, ownership and routes remain in their original systems.
const RECTS={"studio":Rect2(-802,957,544,403),"academy":Rect2(-1215,1663,430,379),"lodge":Rect2(-1280,215,500,310),"arena":Rect2(-105,945,470,330)}
const SIGNS={"studio":Rect2(210,165,124,26),"academy":Rect2(60,142,308,29),"lodge":Rect2(191,132,116,23),"arena":Rect2(91,295,289,29)}
const LIGHTS=[Vector2(-589,1254),Vector2(-472,1254),Vector2(-1150,1908),Vector2(-855,1908)]
static var sheet:Texture2D
static var metadata:Dictionary={}
static var frames:Dictionary={}
static var glass:Dictionary={}
static var font:Font=preload("res://assets/fonts/CrossroadsUI.ttf")
static func prepare()->void:
 if sheet!=null:return
 metadata=JSON.parse_string(FileAccess.get_file_as_string("res://assets/town241/landmarks.json"))
 var im=Image.new();im.load_png_from_buffer(FileAccess.get_file_as_bytes("res://assets/town241/landmarks.png"));sheet=ImageTexture.create_from_image(im)
 for id in RECTS:
  var a:Array=metadata[id].region;var tex=AtlasTexture.new();tex.atlas=sheet;tex.region=Rect2(a[0],a[1],a[2],a[3]);frames[id]=tex
  glass[id]=[]
  for pane in metadata[id].glass:glass[id].append(Rect2(pane[0],pane[1],pane[2],pane[3]))
static func texture(id:String)->Texture2D:
 prepare();return frames[id]
static func draw(g:Node2D,id:String,camera:Vector2,grand:bool=false)->void:
 var rect:Rect2=RECTS[id]
 if not Rect2(camera,g.VIEW).grow(8).intersects(rect):return
 g.draw_texture_rect(texture(id),Rect2(rect.position-camera,rect.size),false)
 var sign:Rect2=SIGNS[id];var p=rect.position+sign.position-camera
 if id=="studio":
  g.draw_string(font,p+Vector2(0,11),"CROSSROADS",HORIZONTAL_ALIGNMENT_CENTER,sign.size.x,11,Color("#efd9a3"))
  g.draw_string(font,p+Vector2(0,23),"STUDIO",HORIZONTAL_ALIGNMENT_CENTER,sign.size.x,10,Color("#d5e6db"))
 else:
  var text={"academy":"CROSSROADS ACADEMY","lodge":"CHALLENGE LODGE","arena":"GRAND GLADIATOR ARENA" if grand else "GLADIATOR ARENA"}[id]
  g.draw_string(font,p+Vector2(0,19 if id!="lodge" else 15),text,HORIZONTAL_ALIGNMENT_CENTER,sign.size.x,16 if id!="lodge" else 11,Color("#efd9a3"))
 # Existing Studio wall lanterns now follow the glass in the new artwork.
 if id=="studio":
  var night:float=g.town_life.calendar.night_amount()
  if night>.01:
   for at in LIGHTS.slice(0,2):g.draw_rect(Rect2(at-camera-Vector2(1.5,3),Vector2(3,6)),Color(1,.78,.4,night*.8))
static func panes()->Array:
 prepare();var result=[]
 for id in RECTS:
  for pane in glass[id]:result.append(Rect2(RECTS[id].position+pane.position,pane.size))
 return result
static func draw_emission(g:Node2D,camera:Vector2,night:float)->void:
 if night<=.01:return
 var view=Rect2(camera,g.VIEW)
 for id in RECTS:
  if not view.intersects(RECTS[id]):continue
  for pane in glass[id]:
   var rect=Rect2(RECTS[id].position+pane.position-camera,pane.size)
   if Rect2(Vector2.ZERO,g.VIEW).intersects(rect):g.draw_rect(rect,Color(1,.74,.36,night*.68))
 if view.intersects(RECTS.studio):
  for at in LIGHTS.slice(0,2):g.draw_rect(Rect2(at-camera-Vector2(1.5,3),Vector2(3,6)),Color(1,.79,.43,night*.85))
static func light_sources()->Array:
 var result=[]
 for at in LIGHTS:result.append({"at":at,"radius":130.0,"strength":.85})
 return result

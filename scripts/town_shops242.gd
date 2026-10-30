extends RefCounted
## Offline prepared, culled facade sprites. No gameplay anchors live in this renderer.
const SPRITES={"character_hall_v65":"hall","supply_vendor_v65":"supply","pond_food_stand":"food","healer_shack":"healer","wayfinder_lodge":"wayfinder","seedhouse":"seedhouse","arena_hall":"training"}
static var sheet:Texture2D
static var glow:Texture2D
static var frames:Dictionary={}
static var emissions:Dictionary={}
static var specs:Dictionary={}
static var font:Font=preload("res://assets/fonts/CrossroadsUI.ttf")
static func as_rect(a:Array)->Rect2:return Rect2(a[0],a[1],a[2],a[3])
static func prepare()->void:
 if sheet!=null:return
 specs=JSON.parse_string(FileAccess.get_file_as_string("res://assets/town242/shops.json"))
 var im=Image.new();im.load_png_from_buffer(FileAccess.get_file_as_bytes("res://assets/town242/shops.png"));sheet=ImageTexture.create_from_image(im)
 im=Image.new();im.load_png_from_buffer(FileAccess.get_file_as_bytes("res://assets/town242/glass.png"));glow=ImageTexture.create_from_image(im)
 for id in specs:
  var tex=AtlasTexture.new();tex.atlas=sheet;tex.region=as_rect(specs[id].region);frames[id]=tex
  if not specs[id].emission_region.is_empty():
   var mask=AtlasTexture.new();mask.atlas=glow;mask.region=as_rect(specs[id].emission_region);emissions[id]=mask
static func texture(id:String)->Texture2D:
 prepare();return frames[id]
static func rect(id:String)->Rect2:
 prepare();return as_rect(specs[id].rect)
static func enabled(g:Node,id:String)->bool:
 var condition:String=specs[id].condition
 return condition.is_empty() or bool(g.legacy.data.town.get(condition,false))
static func draw_rect(g:Node2D,id:String,screen:Rect2,tint:Color=Color.WHITE)->void:
 if not Rect2(Vector2.ZERO,g.VIEW).intersects(screen):return
 g.draw_texture_rect(texture(id),screen,false,tint)
 var v:Dictionary=specs[id]
 if v.sign.is_empty() or str(v.label).is_empty():return
 var size=Vector2(v.rect[2],v.rect[3]);var scale=screen.size/size
 var sign=preload("res://scripts/town_streets244.gd").sign_rect(id,as_rect(v.sign));sign=Rect2(screen.position+sign.position*scale,sign.size*scale)
 if id=="fishing":g.draw_rect(sign.grow(1),Color("#254851"));g.draw_rect(sign.grow(1),Color("#b9a276"),false,1)
 var label:String=v.label;var fontsize:int=clampi(floori(sign.size.y*.85),7,15)
 while fontsize>6 and font.get_string_size(label,HORIZONTAL_ALIGNMENT_LEFT,-1,fontsize).x>sign.size.x:fontsize-=1
 g.draw_string(font,sign.position+Vector2(0,sign.size.y*.79),label,HORIZONTAL_ALIGNMENT_CENTER,sign.size.x,fontsize,(Color("#345348") if id=="seedhouse" else Color("#f1dca9"))*tint)
static func draw(g:Node2D,id:String,camera:Vector2)->void:
 var r=rect(id);draw_rect(g,id,Rect2(r.position-camera,r.size))
static func sprite(g:Node2D,key:String,screen:Rect2,tint:Color)->bool:
 if not SPRITES.has(key):return false
 draw_rect(g,SPRITES[key],screen,tint);return true
static func draw_emission(g:Node2D,camera:Vector2,night:float)->void:
 if night<=.01:return
 prepare();var view=Rect2(camera,g.VIEW)
 for id in emissions:
  if not enabled(g,id):continue
  var r=rect(id)
  if not view.intersects(r):continue
  var b:Array=specs[id].emission_bounds
  g.draw_texture_rect(emissions[id],Rect2(r.position+Vector2(b[0],b[1])-camera,Vector2(b[2]-b[0],b[3]-b[1])),false,Color(1,1,1,night))
 # Existing awning lights remain live and now follow their new canopy hems.
 for id in ["food","supply"]:
  var r=rect(id)
  if not view.intersects(r):continue
  var at=r.position+Vector2(r.size.x*.5,r.size.y*(.29 if id=="food" else .30))
  var width=r.size.x*.78
  g.draw_line(at-Vector2(width*.5,0)-camera,at+Vector2(width*.5,0)-camera,Color("#89734f"),1)
  for n in 5:
   var q=at+Vector2(-width*.5+width*.25*n,3+sin(float(n)*PI/4)*2)-camera
   g.draw_line(q-Vector2(0,3),q,Color("#9e8559"),1);g.draw_circle(q,2,Color(1,.81,.44,.4+night*.6))
static func light_sources(g:Node)->Array:
 prepare();var result=[]
 for id in emissions:
  if not enabled(g,id):continue
  var v:Dictionary=specs[id];var r=rect(id)
  for point in v.lights:
   result.append({"at":r.position+Vector2(point[0],point[1]),"radius":130.0 if id!="seedhouse" else 100.0,"strength":.9 if id!="seedhouse" else .4})
 for id in ["food","supply"]:
  var r=rect(id);result.append({"at":r.position+Vector2(r.size.x*.5,r.size.y*.30),"radius":135.0,"strength":.8})
 return result

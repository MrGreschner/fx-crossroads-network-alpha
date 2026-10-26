extends RefCounted
static var textures:Dictionary={}
static var motion:Dictionary={}
static func frame(kind:String,index:int)->Texture2D:
 var key:=kind+"_"+str(index).pad_zeros(2)
 if not textures.has(key):
  var path:="res://assets/art215/"+key+".png"
  if not FileAccess.file_exists(path):return null
  var image:=Image.new()
  if image.load_png_from_buffer(FileAccess.get_file_as_bytes(path))!=OK:return null
  textures[key]=ImageTexture.create_from_image(image)
 return textures[key]
static func kind(body:Dictionary)->String:
 var sprite:String=str(body.get("sprite",""))
 if sprite in ["mini_basketball","bit_buddy"]:return sprite
 if str(body.get("family",""))=="puppet":return "puppet_b" if int(body.get("visual_variant",0))%2 else "puppet_a"
 return ""
static func unit_texture(body:Dictionary,id:String,p:Vector2)->Texture2D:
 var skin:=kind(body)
 if skin.is_empty():return null
 var actual:Vector2=p
 var raw:Variant=body.get("pos",p)
 if raw is Vector2:actual=raw
 elif raw is Array and raw.size()==2:actual=Vector2(float(raw[0]),float(raw[1]))
 var now:float=Time.get_ticks_msec()/1000.0;var state:Dictionary=motion.get(id,{"pos":actual,"moving":0.0,"attack":0.0})
 if actual.distance_squared_to(state.pos)>.04:state.moving=now+.14
 state.pos=actual
 if str(body.get("pose",""))=="attack" or float(body.get("attack_timer",0))>.64:state.attack=now+.12
 motion[id]=state
 if motion.size()>256:motion.clear()
 var index:=3 if now<float(state.attack) else 1+int(now*7)%2 if now<float(state.moving) else 0
 return frame(skin,index)
static func draw_legacy(c:Node2D,body:Dictionary,p:Vector2,id:String)->bool:
 var tex:=unit_texture(body,id,p)
 if tex==null:return false
 var size:=Vector2(30,30) if kind(body)=="mini_basketball" else Vector2(32,36)
 c.draw_texture_rect(tex,Rect2(p-size*Vector2(.5,.72),size),false)
 return true

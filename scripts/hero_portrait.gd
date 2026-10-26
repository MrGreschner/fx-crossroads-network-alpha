extends RefCounted
static var cache:Dictionary={}
static func texture(g:Node,hero_id:String)->Texture2D:
 var sprite=str(g.characters.get(hero_id,{}).get("sprite",hero_id))
 var base:Texture2D=g.art.get(sprite+"_idle",g.art.get(sprite+"_0"))
 if base==null or sprite not in ["basketball","book"]:return base
 var key=sprite+":"+str(base.get_instance_id())
 if not cache.has(key):
  var image=base.get_image()
  if image==null:return base
  image.convert(Image.FORMAT_RGBA8)
  var size=image.get_size();var scale=.67 if sprite=="basketball" else .82
  var reduced=Vector2i(Vector2(size)*scale)
  image.resize(maxi(1,reduced.x),maxi(1,reduced.y),Image.INTERPOLATE_NEAREST)
  var canvas=Image.create(size.x,size.y,false,Image.FORMAT_RGBA8);canvas.fill(Color.TRANSPARENT)
  canvas.blit_rect(image,Rect2i(Vector2i.ZERO,image.get_size()),(size-image.get_size())/2)
  cache[key]=ImageTexture.create_from_image(canvas)
 return cache[key]

extends RefCounted
static var cache:Dictionary={}
static func texture(g:Node,hero_id:String)->Texture2D:
 var sprite=str(g.characters.get(hero_id,{}).get("sprite",hero_id))
 var base:Texture2D=g.art.get(sprite+"_idle",g.art.get(sprite+"_0"))
 var core=preload("res://scripts/core_hero_art.gd")
 if base is AtlasTexture and base.atlas==core.atlas:
  var prepared=core.portrait_texture(sprite)
  if prepared!=null:return prepared
 var correction:float=preload("res://scripts/hero_visual_scale.gd").portrait_factor(sprite)
 if base==null or (sprite not in ["basketball","book"] and is_equal_approx(correction,1.0)):return base
 var key=sprite+":"+str(base.get_instance_id())
 if not cache.has(key):
  var image=base.get_image()
  if image==null:return base
  image=image.duplicate()
  image.convert(Image.FORMAT_RGBA8)
  var size=image.get_size();var scale:float=.67 if sprite=="basketball" else .82 if sprite=="book" else correction
  var reduced=Vector2i(Vector2(size)*scale)
  image.resize(maxi(1,reduced.x),maxi(1,reduced.y),Image.INTERPOLATE_NEAREST)
  var canvas=Image.create(size.x,size.y,false,Image.FORMAT_RGBA8);canvas.fill(Color.TRANSPARENT)
  var offset:Vector2i=(size-image.get_size())/2
  if sprite not in ["basketball","book"]:offset=Vector2i(roundi((size.x-image.get_width())*.5),roundi((size.y-image.get_height())*.925))
  canvas.blit_rect(image,Rect2i(Vector2i.ZERO,image.get_size()),offset)
  cache[key]=ImageTexture.create_from_image(canvas)
 return cache[key]

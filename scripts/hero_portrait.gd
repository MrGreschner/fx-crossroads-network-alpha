extends RefCounted
## A shared stage preserves the same body-height and width ratios as world rendering.
const Layout=preload("res://scripts/hero_layout250.gd")
static var cache:Dictionary={}
static var stages:Dictionary={}
static func idle(g:Node,sprite:String)->Texture2D:
 var core=preload("res://scripts/core_hero_art.gd")
 return core.texture(sprite,"idle") if sprite in core.HEROES else g.art.get(sprite+"_idle",g.art.get(sprite+"_0"))
static func texture(g:Node,hero_id:String)->Texture2D:
 var spec:Dictionary=g.characters.get(hero_id,{})
 var sprite=str(spec.get("sprite",hero_id));var base:Texture2D=idle(g,sprite)
 if base==null:return null
 var stage_key=str(g.get_instance_id())+":"+str(g.characters.size())
 if not stages.has(stage_key):
  var maximum=Vector2(1,1)
  for id in g.characters:
   var s=str(g.characters[id].get("sprite",id));var t:Texture2D=idle(g,s)
   if t!=null:maximum=maximum.max(Layout.body(t,Layout.reference_rect(s)).size)
  if stages.size()>=32:stages.clear()
  stages[stage_key]=minf(108/maximum.x,110/maximum.y)
 var scale:float=stages[stage_key];var key=sprite+":"+str(base.get_instance_id())+":"+str(scale)
 if not cache.has(key):
  var image=base.get_image()
  if image==null:return base
  image=image.duplicate();image.convert(Image.FORMAT_RGBA8)
  var used=image.get_used_rect();var body=Layout.body(base,Layout.reference_rect(sprite))
  var painted=image.get_region(used);var dimensions=Vector2i((body.size*scale).round()).max(Vector2i.ONE)
  painted.resize(dimensions.x,dimensions.y,Image.INTERPOLATE_NEAREST)
  var canvas=Image.create(128,128,false,Image.FORMAT_RGBA8);canvas.fill(Color.TRANSPARENT)
  canvas.blit_rect(painted,Rect2i(Vector2i.ZERO,dimensions),Vector2i((128-dimensions.x)/2,120-dimensions.y))
  if cache.size()>=256:cache.clear()
  cache[key]=ImageTexture.create_from_image(canvas)
 return cache[key]

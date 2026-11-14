extends RefCounted
## The Lodge uses the Rift's combat runtime with independent world geometry.
const DATA="res://content/challenge_grounds308.json"
const ART="res://assets/challenge308/"
const WAYFARER=preload("res://scripts/wayfarer_art305.gd")
const FROST=preload("res://scripts/frost_art264.gd")
const FIRST="res://assets/first299/"
const TRAINING=preload("res://scripts/training_environment303.gd")

static var catalog:Array=[]
static var previews:Dictionary={}
var layout:Dictionary
var size:Vector2
var bounds:Rect2
var trail:=Curve2D.new()
var pages:Array=[]
var props:Array=[]
var colliders:Array=[]
var landmark_textures:Dictionary={}

static func catalog_entry(index:int)->Dictionary:
 if catalog.is_empty():catalog=JSON.parse_string(FileAccess.get_file_as_string(DATA))
 return catalog[index]

static func image(name:String)->Texture2D:
 var raster:=Image.new()
 if raster.load_webp_from_buffer(FileAccess.get_file_as_bytes(ART+name))!=OK:return null
 return ImageTexture.create_from_image(raster)

static func preview(index:int)->Texture2D:
 if not previews.has(index):previews[index]=image("preview_%d.webp" % index)
 return previews[index]

static func vec(values:Array)->Vector2:
 return Vector2(values[0],values[1])

func setup(index:int)->void:
 layout=catalog_entry(index)
 size=vec(layout.size)
 var top=430 if index==2 else 205
 bounds=Rect2(85,top,size.x-170,size.y-top-92)
 for point in layout.route:trail.add_point(vec(point))
 trail.bake_interval=16
 for row in layout.pages:
  pages.append({"file":row[0],"rect":Rect2(row[1],row[2],row[3],row[4]),"texture":null})
 for row in layout.props:
  var base=Vector2(row[1],row[2])
  var dimensions=Vector2(row[3],row[4])
  props.append({"key":row[0],"base":base,"rect":Rect2(base-dimensions*Vector2(.5,.86),dimensions)})
  if row[5]>0:colliders.append({"pos":base,"radius":float(row[5]),"kind":"tree","town_hidden":true})

func point(index:int)->Vector2:
 var row:Array=layout.landmarks[index]
 return Vector2(row[1],row[2])

func site_name(index:int)->String:
 return str(layout.landmarks[index][0])

func texture(key:String)->Texture2D:
 match key:
  "fir","pillar","goal":return FROST.frame(key)
  "frost_arch":return FROST.frame("arch")
  "fern","fence_end":return TRAINING.frame(key)
  "grand_gateway","ram_arch","keeper_statue","sunrise_relief":
   if not landmark_textures.has(key):
    var raster:=Image.new()
    if raster.load_png_from_buffer(FileAccess.get_file_as_bytes(FIRST+key+"_large.png"))!=OK:return null
    landmark_textures[key]=ImageTexture.create_from_image(raster)
   return landmark_textures[key]
  "quarry_rock":return preload("res://scripts/quarry_art254.gd").texture("rock")
  _:return WAYFARER.texture(key)

func draw(c:Node2D,camera:Vector2)->void:
 var visible:=Rect2(camera,c.VIEW)
 c.draw_rect(Rect2(-camera,size),Color("#293937"))
 for page in pages:
  var rect:Rect2=page.rect
  if not visible.intersects(rect):continue
  if page.texture==null:page.texture=image(page.file)
  if page.texture!=null:c.draw_texture_rect(page.texture,Rect2(rect.position-camera,rect.size),false)
 for prop in props:
  var rect:Rect2=prop.rect
  if not visible.intersects(rect):continue
  var sprite:=texture(prop.key)
  if sprite==null:continue
  var player:Vector2=c.position_in_world
  var faded=player.y<float(prop.base.y) and rect.has_point(player)
  c.draw_texture_rect(sprite,Rect2(rect.position-camera,rect.size),false,Color(1,1,1,.35 if faded else 1.0))
 for row in layout.landmarks:
  var at:=Vector2(row[1],row[2]+row[4]-12)
  if not visible.has_point(at):continue
  var origin:=at-camera-Vector2(140,0)
  c.draw_string_outline(ThemeDB.fallback_font,origin,str(row[0]),HORIZONTAL_ALIGNMENT_CENTER,280,17,4,Color("#283537"))
  c.draw_string(ThemeDB.fallback_font,origin,str(row[0]),HORIZONTAL_ALIGNMENT_CENTER,280,17,Color("#f7e7bc"))

func marker(c:Node2D,point_in_world:Vector2,camera:Vector2)->void:
 var p:=point_in_world-camera
 var safe:=Rect2(46,230,maxf(1,c.VIEW.x-92),maxf(1,c.VIEW.y-288))
 var tint:=Color("#ffe4a3")
 if safe.has_point(p):
  c.draw_arc(p,28,0,TAU,32,tint,2,true)
  return
 var at:=p.clamp(safe.position,safe.end)
 var direction:=(p-at).normalized()
 var side:=direction.orthogonal()
 c.draw_circle(at,15,Color("#243838"))
 c.draw_colored_polygon(PackedVector2Array([at+direction*10,at-direction*7+side*7,at-direction*7-side*7]),tint)

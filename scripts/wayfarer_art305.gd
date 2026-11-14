extends RefCounted
## Wayfarer-only presentation. Coordinates and passability are owned by the quest.
const ROOT="res://assets/wayfarer305/"
const FOES=["wayfarer_thornveil","wayfarer_ambercap","wayfarer_hollowroot","wayfarer_heartwood","wayfarer_rimehare","wayfarer_hoarfletch","wayfarer_bellstone","wayfarer_brassback","wayfarer_valvewright","wayfarer_reedjaw"]
const PREVIOUS={"wayfarer_thornveil":"briar_bandit","wayfarer_ambercap":"glowcap_slinger","wayfarer_hollowroot":"rootbound_keeper","wayfarer_heartwood":"rootwarden","wayfarer_rimehare":"frostling","wayfarer_hoarfletch":"ice_archer","wayfarer_bellstone":"summit_golem","wayfarer_brassback":"sluice_beetle","wayfarer_valvewright":"tidebinder","wayfarer_reedjaw":"inkfin"}
const PROPS=["lanternwright","willowrest","lodge","mill","willow","beech","oak","rocks","arch","valve","bell","spring"]
const DETAILS=["tent","lantern","waystone","dungeon","garden","ferns","roots","standing_stone","seal","waterwheel","ridge_rocks","rail"]
const MATERIALS=["meadow","road","river","cave","snow","terrace","wood"]
static var textures:Dictionary={}
static var repeats:Dictionary={}
static var regions:Dictionary={}

static func raw(key:String)->Texture2D:
 if not textures.has(key):
  var im=Image.new()
  if im.load_png_from_buffer(FileAccess.get_file_as_bytes(ROOT+key+".png"))!=OK:return null
  textures[key]=ImageTexture.create_from_image(im)
 return textures[key]

static func texture(key:String)->Texture2D:
 if key in FOES:return walk_texture(key)
 if regions.has(key):return regions[key]
 var page="creatures"
 var idx=FOES.find(key)
 if key=="glowroot":idx=10
 if key=="spruce":idx=11
 if key in PROPS:
  page="scenery";idx=PROPS.find(key)
 if key in DETAILS:
  page="details";idx=DETAILS.find(key)
 if idx<0:return null
 var atlas=raw(page)
 if atlas==null:return null
 var frame=AtlasTexture.new()
 frame.atlas=atlas;frame.region=Rect2((idx%4)*256,int(idx/4)*256,256,256);frame.filter_clip=true
 regions[key]=frame
 return frame

static func repeat_texture(key:String)->Texture2D:
 if not repeats.has(key):
  var atlas=CanvasTexture.new()
  atlas.diffuse_texture=raw(key)
  atlas.texture_repeat=CanvasItem.TEXTURE_REPEAT_ENABLED
  atlas.texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR
  repeats[key]=atlas
 return repeats[key]

static func surface(c:CanvasItem,key:String,world:Rect2,camera:Vector2,view:Rect2,tint:Color=Color.WHITE)->void:
 var clipped=world.intersection(view)
 if not clipped.has_area():return
 var uv:=Rect2(clipped.position.posmodv(Vector2(384,384))*(256.0/384.0),clipped.size*(256.0/384.0))
 c.draw_texture_rect_region(repeat_texture(key),Rect2(clipped.position-camera,clipped.size),uv,tint,false,false)

static func pavement(c:CanvasItem,points:PackedVector2Array,camera:Vector2)->void:
 var positions=PackedVector2Array()
 var uv=PackedVector2Array()
 for p in points:
  positions.append(p-camera);uv.append(p/384.0)
 c.draw_polygon(positions,PackedColorArray([Color.WHITE]),uv,repeat_texture("road"))

static func road(c:CanvasItem,a:Vector2,b:Vector2,camera:Vector2,view:Rect2,width:float=64.0)->void:
 if not Rect2(a,Vector2.ZERO).expand(b).grow(width).intersects(view):return
 var side=(b-a).normalized().orthogonal()*width
 pavement(c,PackedVector2Array([a-side,b-side,b+side,a+side]),camera)

static func plaza(c:CanvasItem,at:Vector2,camera:Vector2,view:Rect2,radius:float)->void:
 if not view.grow(radius).has_point(at):return
 var points=PackedVector2Array()
 for n in 24:
  var angle=TAU*n/24
  points.append(at+Vector2.from_angle(angle)*radius*(.96+.04*cos(angle*5)))
 pavement(c,points,camera)

static func prop(c:CanvasItem,key:String,at:Vector2,size:Vector2,tint:Color=Color.WHITE)->void:
 var sprite=texture(key)
 if sprite!=null:c.draw_texture_rect(sprite,Rect2(at-size*Vector2(.5,.86),size),false,tint)

static var walk_frames:Dictionary={}
static func walk_texture(key:String,pose:String="idle")->Texture2D:
 var index:=FOES.find(key)
 if index<0:return null
 var column:=1 if pose in ["walk1","1"] else 2 if pose in ["walk2","2"] else 0
 var cache_key:=key+":"+str(column)
 if not walk_frames.has(cache_key):
  var frame:=AtlasTexture.new()
  frame.atlas=raw("walk336")
  if frame.atlas==null:return null
  frame.region=Rect2(column*80,index*80,80,80)
  frame.filter_clip=true
  walk_frames[cache_key]=frame
 return walk_frames[cache_key]

static func enemy(c:CanvasItem,key:String,pose:String,rect:Rect2,tint:Color,_foe:Dictionary)->void:
 var sprite:=walk_texture(key,pose)
 if sprite==null:return
 var at:=rect.position+Vector2(rect.size.x*.5,rect.size.y*.84)
 var size:=Vector2.ONE*rect.size.y
 if key in ["wayfarer_bellstone","wayfarer_heartwood"]:size*=1.38
 if key=="wayfarer_rimehare":size*=.84
 c.draw_texture_rect(sprite,Rect2(at-size*Vector2(.5,.925),size),false,tint)

extends RefCounted
## Moonveil environment only. Authored gameplay geometry stays in moon_castle.gd.
static var textures:Dictionary={}
static var frames:Dictionary={}
static var manifest:Dictionary={}
static var placements:Array=[]
static var clock_override:float=-1
static var last_visible:int=0
static func texture(id:String)->Texture2D:
 if textures.has(id):return textures[id]
 var im=Image.new();var error=im.load_png_from_buffer(FileAccess.get_file_as_bytes("res://assets/masque271/"+id+".png"))
 if error!=OK:push_error("Moonveil material unavailable: "+id);return null
 var raw=ImageTexture.create_from_image(im)
 if id.begins_with("ground"):
  var smooth=CanvasTexture.new();smooth.diffuse_texture=raw;smooth.texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR;textures[id]=smooth
 else:textures[id]=raw
 return textures[id]
static func prepare()->void:
 if not manifest.is_empty():return
 manifest=JSON.parse_string(FileAccess.get_file_as_string("res://assets/masque271/manifest.json"))
 placements=JSON.parse_string(FileAccess.get_file_as_string("res://assets/masque271/placements.json"))
static func frame(id:String)->Texture2D:
 prepare()
 if not frames.has(id):
  var a:Array=manifest[id].region;var t=AtlasTexture.new();t.atlas=texture("props");t.region=Rect2(a[0],a[1],a[2],a[3]);frames[id]=t
 return frames[id]
static func phase()->float:return clock_override if clock_override>=0 else Time.get_ticks_msec()*.001
static func bounds(at:Vector2,size:Vector2)->Rect2:return Rect2(at-size*Vector2(.5,.9375),size)
static func prop(c:Node2D,id:String,at:Vector2,size:Vector2,cam:Vector2,hero:Vector2=Vector2(-9999,-9999))->bool:
 var r=bounds(at,size);var view=Rect2(cam,c.get_viewport_rect().size+Vector2(200,200)).grow(80)
 if not view.intersects(r):return false
 var tint=Color.WHITE
 if id in ["willow","palace","arch","gate","drapes","pavilion","columns","chandelier"] and r.grow(-25).has_point(hero):tint.a=.38
 c.draw_texture_rect(frame(id),Rect2(r.position-cam,r.size),false,tint)
 return true
static func cart(c:Node2D,cam:Vector2)->void:
 var at=Vector2(3340,2658);prop(c,"cart",at,Vector2(190,175),cam)
 var q=at-cam+Vector2(-105,-177);c.draw_string_outline(ThemeDB.fallback_font,q,"MERCHANT",HORIZONTAL_ALIGNMENT_CENTER,210,15,3,Color("#29374b"));c.draw_string(ThemeDB.fallback_font,q,"MERCHANT",HORIZONTAL_ALIGNMENT_CENTER,210,15,Color("#f3e6ba"))
static func draw(c:Node2D,cam:Vector2)->void:
 prepare();var view=Rect2(cam,c.get_viewport_rect().size+Vector2(200,200)).grow(160);var t=phase();last_visible=0
 c.draw_rect(Rect2(-cam,Vector2(7600,5600)),Color("#24313e"))
 for n in 4:
  var r=Rect2(Vector2((n%2)*3800,int(n/2)*2800),Vector2(3800,2800))
  if view.intersects(r):c.draw_texture_rect(texture("ground"+str(n)),Rect2(r.position-cam,r.size),false)
 # Ripple highlights are independent from collision/water, bounded to the southern lake.
 for row in 9:
  for col in 9:
   var at=Vector2(5120+col*285+sin(row*2.1)*54,3340+row*250);var p=at-cam
   if view.has_point(at):c.draw_arc(p,18+fposmod(t*7+row*9+col*13,36),.2,PI*.85,14,Color(.58,.73,.86,.07+.04*sin(t+col)),1,true)
 var hero=Vector2(-9999,-9999)
 if c.get("position_in_world")is Vector2:hero=c.position_in_world
 for item in placements:
  var at=Vector2(item.pos[0],item.pos[1]);var size=Vector2(item.size[0],item.size[1]);var id=str(item.kind)
  if prop(c,id,at,size,cam,hero):
   last_visible+=1
   if id=="fountain":
    var center=at-Vector2(0,119)-cam
    for j in 5:
     var radius=22+fposmod(t*14+j*20,90);c.draw_arc(center,radius,0,TAU,32,Color(.65,.84,.91,.18*(1-radius/120)),1.5,true)
    for j in 7:
     var q=center+Vector2((j-3)*8,-64+fposmod(t*48+j*17,66));c.draw_line(q,q+Vector2(0,8),Color(.74,.91,.96,.42),1,true)
   elif id in ["lantern","candelabrum","chandelier"]:
    var p=at-cam-Vector2(0,size.y*.64);c.draw_circle(p,3.1+sin(t*3+at.x)*.6,Color(1,.86,.57,.43));c.draw_circle(p,7,Color(1,.8,.49,.06))
   elif id=="mirror":
    var p=at-cam-Vector2(0,size.y*.55);c.draw_line(p+Vector2(-14,-32+sin(t+at.x)*6),p+Vector2(16,-18+sin(t+at.x)*6),Color(.76,.86,1,.18),2,true)
 # A few petals drift only above planted courts; no particles/nodes/physics added.
 for garden in [Rect2(1800,460,1400,480),Rect2(1850,4350,1400,480),Rect2(5160,430,1500,450)]:
  if not view.intersects(garden):continue
  for j in 10:
   var p=garden.position+Vector2(fposmod(j*151+t*8,garden.size.x),fposmod(j*73+t*5,garden.size.y))-cam;c.draw_line(p,p+Vector2(3,1+sin(t+j)),Color(.77,.69,.86,.32),2,true)
 for label in [[Vector2(430,2390),"MOONVEIL • THE MASQUERADE"],[Vector2(1820,1830),"THE FIRST DANCE"],[Vector2(3480,2440),"GALLERY OF REFLECTIONS"],[Vector2(4900,1940),"THE GRAND BALLROOM"],[Vector2(3460,3940),"MOONWATER GARDEN"],[Vector2(1750,680),"WHISPER COURT"]]:
  if view.has_point(label[0]):c.draw_string_outline(ThemeDB.fallback_font,label[0]-cam,label[1],HORIZONTAL_ALIGNMENT_LEFT,-1,18,3,Color("#22283a"));c.draw_string(ThemeDB.fallback_font,label[0]-cam,label[1],HORIZONTAL_ALIGNMENT_LEFT,-1,18,Color("#e5d8bc"))

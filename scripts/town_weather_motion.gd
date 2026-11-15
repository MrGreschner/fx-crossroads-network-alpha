extends RefCounted
## Repeating world-space weather field. The camera only selects/culls particles;
## it never drives their motion. Seeds do not depend on camera position or size.
const RAIN_TILE=Vector2(1440,1080)
const CLOUD_TILE=Vector2(2100,1500)
const RAIN_VELOCITY=Vector2(-65,390)
const CLOUD_VELOCITY=Vector2(13,4)
static func particles(camera:Vector2,view:Vector2,seconds:float,clouds:bool,snowfall:bool=false)->Array[Dictionary]:
 var tile=CLOUD_TILE if clouds else RAIN_TILE
 var velocity=CLOUD_VELOCITY if clouds else Vector2(-25,58) if snowfall else RAIN_VELOCITY
 var bounds=Rect2(camera,view).grow(430 if clouds else 20)
 var result:Array[Dictionary]=[]
 for n in (5 if clouds else 52):
  # Stagger the field without lining drops up in rows.
  var seed=Vector2(fposmod(n*433.0+sin(n*19.3)*109,tile.x),fposmod(n*311.0+cos(n*7.1)*113,tile.y))
  var base=Vector2(fposmod(seed.x+seconds*velocity.x,tile.x),fposmod(seed.y+seconds*velocity.y,tile.y))
  for y in range(ceili((bounds.position.y-base.y)/tile.y),floori((bounds.end.y-base.y)/tile.y)+1):
   for x in range(ceili((bounds.position.x-base.x)/tile.x),floori((bounds.end.x-base.x)/tile.x)+1):
    result.append({"id":"%d:%d:%d" % [n,x,y],"world":base+Vector2(x,y)*tile})
 return result

static var fog_texture:ImageTexture

static func snow(c:Node2D,camera:Vector2,view:Vector2,seconds:float)->void:
 for flake in particles(camera,view,seconds,false,true):
  var p:Vector2=flake.world-camera
  p.x+=sin(seconds*1.5+p.y*.06)*6
  c.draw_rect(Rect2(p.floor(),Vector2(2,2)),Color(.88,.95,1,.67))

static func fog(c:Node2D,camera:Vector2,view:Vector2,seconds:float,strength:float,clear_center:Vector2=Vector2.INF)->void:
 if fog_texture==null:
  var image:=Image.create(96,32,false,Image.FORMAT_RGBA8)
  for y in 32:
   for x in 96:
    var p:=Vector2((x+.5)/48-1,(y+.5)/16-1)
    var alpha:=1-smoothstep(.18,1.0,p.length())
    image.set_pixel(x,y,Color(.74,.82,.86,alpha))
  fog_texture=ImageTexture.create_from_image(image)
 if clear_center!=Vector2.INF:c.draw_rect(Rect2(Vector2.ZERO,view),Color(.68,.77,.82,strength*.12))
 for bank in particles(camera,view,seconds*.66,true):
  var center:Vector2=bank.world-camera
  var alpha:=strength*.56
  if clear_center!=Vector2.INF:alpha*=lerpf(.34,1.0,smoothstep(160,480,center.distance_to(clear_center)))
  var extent:=Vector2(1060,230)
  c.draw_texture_rect(fog_texture,Rect2(center-extent*.5,extent),false,Color(1,1,1,alpha))

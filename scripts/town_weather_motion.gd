extends RefCounted
## Repeating world-space weather field. The camera only selects/culls particles;
## it never drives their motion. Seeds do not depend on camera position or size.
const RAIN_TILE=Vector2(1440,1080)
const CLOUD_TILE=Vector2(2100,1500)
const RAIN_VELOCITY=Vector2(-65,390)
const CLOUD_VELOCITY=Vector2(13,4)
static func particles(camera:Vector2,view:Vector2,seconds:float,clouds:bool)->Array[Dictionary]:
 var tile=CLOUD_TILE if clouds else RAIN_TILE
 var velocity=CLOUD_VELOCITY if clouds else RAIN_VELOCITY
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

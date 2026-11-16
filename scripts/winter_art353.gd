extends RefCounted
## Cached winter materials drawn over the existing world geometry.
static var ground_atlas:Texture2D
static var roof_caps:Dictionary={}
static var snowy_canopy:Texture2D

static func active(game:Node)->bool:
 return game.town_life.calendar.season()=="Winter"

static func ground()->Texture2D:
 if ground_atlas!=null:return ground_atlas
 var im:=Image.new()
 if im.load_png_from_buffer(FileAccess.get_file_as_bytes("res://assets/town247/ground.png"))!=OK:return null
 im.convert(Image.FORMAT_RGBA8)
 for y in im.get_height():
  for x in im.get_width():
   var c:=im.get_pixel(x,y)
   if c.a==0:continue
   var shade:=c.get_luminance()
   var fleck:=float(posmod((x/2)*31^(y/2)*79,11))*.002
   var snow:=Color(.58+shade*.44+fleck,.67+shade*.38+fleck,.74+shade*.33+fleck,c.a)
   if x>=256 and c.r>c.g*1.05 and c.g>c.b*1.13:
    snow=c.lerp(Color(.67,.69,.67,c.a),.40)
   im.set_pixel(x,y,snow)
 ground_atlas=ImageTexture.create_from_image(im)
 return ground_atlas

static func roof(id:String,source:Texture2D)->Texture2D:
 if roof_caps.has(id):return roof_caps[id]
 var im:=source.get_image()
 var width:=im.get_width();var height:=im.get_height()
 var snow:=Image.create(width,height,false,Image.FORMAT_RGBA8)
 for x in width:
  for y in int(height*.4):
   var c:=im.get_pixel(x,y)
   if c.a<.8:continue
   var depth:=5+posmod(x/6*17,5)
   for dy in depth:
    if y+dy>=height or im.get_pixel(x,y+dy).a<.8:break
    var shade:=im.get_pixel(x,y+dy).get_luminance()
    snow.set_pixel(x,y+dy,Color(.75+shade*.19,.83+shade*.14,.88+shade*.10,1.0 if dy<depth-2 else .86))
   break
 roof_caps[id]=ImageTexture.create_from_image(snow)
 return roof_caps[id]

static func canopy(source:Texture2D)->Texture2D:
 if snowy_canopy!=null:return snowy_canopy
 var im:=source.get_image();im.convert(Image.FORMAT_RGBA8)
 for y in im.get_height():
  for x in im.get_width():
   var c:=im.get_pixel(x,y)
   if c.a<.5 or (c.r>c.g*1.08 and c.r>c.b*1.1):continue
   var light:=c.get_luminance()
   if light<.27:continue
   var amount:=smoothstep(.26,.58,light)*.9
   im.set_pixel(x,y,c.lerp(Color(.89,.94,.97,c.a),amount))
 snowy_canopy=ImageTexture.create_from_image(im)
 return snowy_canopy

static func lake_bank(c:Node2D,cam:Vector2,view:Rect2)->void:
 var geo=preload("res://scripts/lake_geometry301.gd")
 var top:=maxi(0,floori(view.position.y/32)*32)
 var bottom:=mini(6800,ceili(view.end.y/32)*32)
 if bottom<=top or view.position.x>950:return
 var edge:=PackedVector2Array();var inner:=PackedVector2Array()
 for y in range(top,bottom+1,32):
  var x:=geo.coast_x(float(y))
  edge.append(Vector2(x-4,y)-cam)
  inner.append(Vector2(x-62-posmod(y*17,33),y)-cam)
 var bank:=edge.duplicate();inner.reverse();bank.append_array(inner)
 c.draw_colored_polygon(bank,Color("#c2d2d8"))
 c.draw_polyline(edge,Color("#86afba"),5,true)
 for n in range(1,inner.size()-1):
  var p:=inner[n]+Vector2(22,posmod(n*17,16)-8)
  c.draw_rect(Rect2(p,Vector2(9+posmod(n*17,18),3)),Color("#dde6e7"))

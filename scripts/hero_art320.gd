extends RefCounted
static var sheets:Dictionary={}
static var frames:Dictionary={}
static func pose(sprite:String,index:int)->Texture2D:
 if sprite not in ["caelum","kage"]:return null
 if index==120:index=1
 elif index==121:index=2
 if index<0 or index>5:return null
 if not sheets.has(sprite):
  var image:=Image.new()
  if image.load_png_from_buffer(FileAccess.get_file_as_bytes("res://assets/hero320/"+sprite+".png"))!=OK:return null
  sheets[sprite]=ImageTexture.create_from_image(image)
 var key:=sprite+"/"+str(index)
 if not frames.has(key):
  var t:=AtlasTexture.new();t.atlas=sheets[sprite];t.region=Rect2((index%3)*80,(index/3)*80,80,80);t.filter_clip=true
  if sprite=="kage" and index==2:
   # V322: original second walking frame was registered 8px too high.
   var source:=t.get_image()
   var aligned:=Image.create(80,80,false,Image.FORMAT_RGBA8)
   aligned.blit_rect(source,Rect2i(0,0,80,72),Vector2i(0,8))
   frames[key]=ImageTexture.create_from_image(aligned)
  else:
   frames[key]=t
 return frames[key]

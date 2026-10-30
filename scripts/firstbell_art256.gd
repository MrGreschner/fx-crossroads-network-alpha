extends RefCounted
## Presentation only: shared lazy atlases, retained floor commands, unchanged world geometry.
static var cache:Dictionary={}
static var frames:Dictionary={}
static var metadata:Dictionary={}
static func texture(id:String)->Texture2D:
 if cache.has(id):return cache[id]
 var im=Image.new()
 if im.load_png_from_buffer(FileAccess.get_file_as_bytes("res://assets/firstbell256/"+id+".png"))!=OK:return null
 var t=ImageTexture.create_from_image(im);cache[id]=t;return t
static func frame(id:String)->Texture2D:
 if frames.has(id):return frames[id]
 if metadata.is_empty():metadata=JSON.parse_string(FileAccess.get_file_as_string("res://assets/firstbell256/manifest.json"))
 var b:Array=metadata.frames[id];var t=AtlasTexture.new();t.atlas=texture("ground" if id in ["school_tile","school_street","school_yard","school_sand"]else "props");t.region=Rect2(b[0],b[1],b[2],b[3]);frames[id]=t;return t
static func ground(c:Node2D)->void:
 if c.background:c.draw_rect(c.world_bounds,Color("#34474b"));return
 for tile in c.tiles:c.draw_texture_rect(frame("school_"+str(tile.room.theme)),Rect2(Vector2(tile.cell)*64,Vector2(64,64)),false)
 for tile in c.tiles:
  var tone=Color("#c4c4ad",.2)
  match str(tile.room.theme):
   "sand":tone=Color("#cdbb94",.5)
   "yard":tone=Color("#84966e",.48)
   "street":tone=Color("#59676f",.1)
  c.draw_rect(Rect2(Vector2(tile.cell)*64,Vector2(64,64)),tone)
 for tile in c.tiles:
  var p=Vector2(tile.cell)*64+Vector2(32,32)
  if str(tile.room.theme)=="street" and absf(p.y-c.source.rect(tile.room.rect).get_center().y)<32 and tile.cell.x%4<2:c.draw_rect(Rect2(p-Vector2(24,6),Vector2(47,7)),Color("#d6c999"))
  for side in tile.edges:
   c.draw_line(p+side*32-side.orthogonal()*32,p+side*32+side.orthogonal()*32,Color("#596966"),12)
   c.draw_line(p+side*28-side.orthogonal()*32,p+side*28+side.orthogonal()*32,Color("#bab8a0"),5)
   c.draw_line(p+side*25-side.orthogonal()*32,p+side*25+side.orthogonal()*32,Color("#d0cbb3"),2)
static func entrance(c:Node2D,p:Vector2,title:String)->void:
 c.draw_texture_rect(frame("entry"),Rect2(p+Vector2(-310,-125),Vector2(620,180)),false)
 var font=ThemeDB.fallback_font;var width=font.get_string_size(title,HORIZONTAL_ALIGNMENT_LEFT,-1,23).x
 c.draw_string_outline(font,p+Vector2(-width*.5,-80),title,HORIZONTAL_ALIGNMENT_LEFT,-1,23,3,Color("#394e54"));c.draw_string(font,p+Vector2(-width*.5,-80),title,HORIZONTAL_ALIGNMENT_LEFT,-1,23,Color("#f2dfad"))
static func lamp(c:Node2D,p:Vector2)->void:
 c.draw_line(p+Vector2(0,14),p+Vector2(0,-54),Color("#4c6265"),11);c.draw_line(p+Vector2(-2,10),p+Vector2(-2,-54),Color("#82918a"),2)
 c.draw_rect(Rect2(p+Vector2(-15,-74),Vector2(30,28)),Color("#6a776d"));c.draw_rect(Rect2(p+Vector2(-15,-74),Vector2(30,28)),Color("#bdad7a"),false,3);c.draw_rect(Rect2(p+Vector2(-10,-68),Vector2(20,17)),Color("#e4d7a1"));c.draw_line(p+Vector2(0,-68),p+Vector2(0,-51),Color("#a18b59"),2)
static func door(c:Node2D,r:Rect2,ready:bool)->void:
 var tone=Color("#93ac96") if ready else Color("#b78e78")
 c.draw_rect(r,Color("#596b63"));c.draw_rect(r,Color("#c7b998"),false,3)
 for x in range(int(r.position.x)+10,int(r.end.x),48):
  var panel=Rect2(x,r.position.y+7,minf(34,r.end.x-x-6),maxf(1,r.size.y-14))
  if panel.size.x>0:c.draw_rect(panel,Color("#829585"));c.draw_rect(panel,tone,false,2)
 c.draw_line(r.get_center()-Vector2(0,r.size.y*.35),r.get_center()+Vector2(0,r.size.y*.35),Color("#e6cf98"),3)

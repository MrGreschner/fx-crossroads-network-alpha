extends RefCounted
## Battleground presentation only. The authority modules retain geometry and rules.
const ROOT="res://assets/battleground262/"
static var pages:Dictionary={}
static var frames:Dictionary={}
static var specs:Dictionary={}
static var actors:Dictionary={}
static var ground:Dictionary={}
static func png(id:String)->Texture2D:
 if not pages.has(id):
  var im=Image.new();im.load_png_from_buffer(FileAccess.get_file_as_bytes(ROOT+id+".png"));pages[id]=ImageTexture.create_from_image(im)
 return pages[id]
static func part(page:String,key:String,r:Rect2)->Texture2D:
 if not frames.has(key):
  var t=AtlasTexture.new();t.atlas=png(page);t.region=r;t.filter_clip=true;frames[key]=t
 return frames[key]
static func prop(id:String)->Texture2D:
 if specs.is_empty():specs=JSON.parse_string(FileAccess.get_file_as_string(ROOT+"props.json"))
 var a:Array=specs[id]
 return part("fort" if id in ["capital0","capital1","barracks0","barracks1","market","bench"] else "scenery",id,Rect2(a[0],a[1],a[2],a[3]))
static func actor(id:String,pose:int)->Texture2D:
 if actors.is_empty():actors=JSON.parse_string(FileAccess.get_file_as_string(ROOT+"actors.json"))
 if not actors.has(id):return null
 var a:Array=actors[id].regions[clampi(pose,0,3)]
 return part(str(actors[id].sheet),id+":"+str(pose),Rect2(a[0],a[1],a[2],a[3]))
static func unit(c:CanvasItem,id:String,p:Vector2,pose:int,height:float)->void:
 var t=actor(id,pose)
 if t==null:return
 var s=height/float(actors[id].visible_height);var size=Vector2.ONE*80*s
 c.draw_texture_rect(t,Rect2(p-size*Vector2(.5,.925),size),false)
static func terrain(x:int,y:int,b:RefCounted)->Texture2D:
 if ground.is_empty():ground=JSON.parse_string(FileAccess.get_file_as_string(ROOT+"ground.json"))
 var map=str(b.map_id);var lanes=str(b.lanes) if ground[map].has(str(b.lanes)) else "3"
 var index:int=ground[map][lanes][clampi(y,0,68)][clampi(x,0,106)]
 return part(map,map+":"+str(index),Rect2(index%16*64,index/16*64,64,64))
static func append(chunk:Node,x:int,y:int,at:Vector2,g:Node)->void:
 chunk.compact=false;chunk.tiles.append([terrain(x,y,g.battlegrounds),Rect2(at,Vector2(64,64))])
static func draw(c:CanvasItem,id:String,r:Rect2,tint:Color=Color.WHITE)->void:
 c.draw_texture_rect(prop(id),r,false,tint)
static func scenery(c:Node2D,b:RefCounted,cam:Vector2)->void:
 var visible=Rect2(cam,b.game.VIEW).grow(150)
 for lane in b.lanes:
  var y=b.lane_y(lane)
  for x in [1450,2850,3950,5350]:
   var at=Vector2(x,y+160)
   if not visible.has_point(at):continue
   if b.map_id=="woodland":draw(c,"logs",Rect2(at-cam-Vector2(55,23),Vector2(110,46)))
   else:
    draw(c,"crater",Rect2(at-cam-Vector2.ONE*65,Vector2.ONE*130));draw(c,"sandbags",Rect2(at-cam+Vector2(-55,48),Vector2(110,42)))
 for gap in range(b.lanes-1):
  var y=(b.lane_y(gap)+b.lane_y(gap+1))*.5
  for x in [1150,2200,4600,5650]:
   var at=Vector2(x,y)
   if not visible.has_point(at):continue
   draw(c,"pond"if b.map_id=="woodland"else"bunker",Rect2(at-cam-Vector2(80,80)if b.map_id=="woodland"else at-cam-Vector2(80,40),Vector2(160,160)if b.map_id=="woodland"else Vector2(160,100)))
static func aircraft(c:Node2D,p:Vector2)->void:
 # Same original flyover path/clock and decorative envelope. Nose travels right.
 c.world_transform(p,PI/2);draw(c,"plane",Rect2(-Vector2(46,80),Vector2(92,160)));c.world_transform()
static func obstacle(c:Node2D,b:RefCounted,o:Dictionary)->void:
 var p:Vector2=o.pos-b.game.camera;var radius=float(o.get("radius",36))
 c.draw_circle(p+Vector2(0,6),radius,Color(0.08,.14,.13,.14))
 if str(o.get("kind","tree"))=="tree":c.draw_texture_rect(preload("res://scripts/quarry_art254.gd").grove_tree(o.pos),Rect2(p-Vector2(44,65),Vector2(88,112)),false)
 else:c.draw_texture_rect(preload("res://scripts/quarry_art254.gd").texture("rock"),Rect2(p-Vector2.ONE*(radius+4),Vector2.ONE*(radius*2+8)),false)
static func ruins(c:Node2D,p:Vector2)->void:
 var t=preload("res://scripts/quarry_art254.gd").texture("rock")
 for n in 4:c.draw_texture_rect(t,Rect2(p+Vector2(n*40-90,-15),Vector2(60,48)),false,Color("#9b8778"))
static func overview(c:Node2D,b:RefCounted)->void:
 var lane=0 if b.lanes==3 else 1
 var t=part("overview_"+str(b.map_id),"overview:"+str(b.map_id)+str(lane),Rect2(0,lane*550,850,550))
 c.draw_texture_rect(t,Rect2(-b.game.camera,b.SIZE),false)

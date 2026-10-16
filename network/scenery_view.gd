extends Node2D
## Retain immutable arena props in visible chunks; no render textures.
const EDGE=512
var game:Node2D
var chunks:Dictionary={}
var signature=""
var builds=0
class Chunk extends Node2D:
 var sprites:Array=[]
 var springs:Array=[]
 var labels:Array=[]
 func _draw()->void:
  for entry in sprites:draw_texture_rect(entry.texture,entry.rect,false)
  for p in springs:draw_arc(p,135,0,TAU,32,Color(.5,.9,.8,.3),2,true)
  for entry in labels:draw_string(ThemeDB.fallback_font,entry.point,entry.text,HORIZONTAL_ALIGNMENT_LEFT,-1,entry.size,entry.color)
func _ready()->void:z_index=-1
func reset()->void:
 for chunk in chunks.values():chunk.hide();chunk.queue_free()
 chunks.clear();signature=""
func bucket(point:Vector2)->Node2D:
 var key=Vector2i(floori(point.x/EDGE),floori(point.y/EDGE))
 if not chunks.has(key):
  var chunk=Chunk.new();chunk.position=Vector2(key)*EDGE;chunks[key]=chunk;add_child(chunk)
 return chunks[key]
func sprite(point:Vector2,texture:Texture2D,rect:Rect2)->void:
 if texture==null:return
 var chunk=bucket(point);rect.position-=chunk.position
 chunk.sprites.append({"texture":texture,"rect":rect})
func rebuild()->void:
 for decoration in game.world_decorations:
  var size:Vector2=decoration.size
  sprite(decoration.pos,decoration.texture,Rect2(decoration.pos-size*.5,size))
 for obstacle in game.field_obstacles:
  var size=Vector2(88,112);var offset=Vector2(44,65)
  var key=str(obstacle.get("kind","tree"))
  if key=="rock":
   size=Vector2.ONE*(float(obstacle.get("radius",38))*2+8);offset=size*.5
  sprite(obstacle.pos,game.art.get(key),Rect2(obstacle.pos-offset,size))
 for building in game.world_buildings:
  var size=Vector2(260,210) if str(building.name)=="Gate" else Vector2(170,150)
  sprite(building.pos,game.art.get(str(building.sprite)),Rect2(building.pos-size*Vector2(.5,.7),size))
  var chunk=bucket(building.pos)
  chunk.labels.append({"point":building.pos-chunk.position+Vector2(-65,65),"text":str(building.name).to_upper(),"size":18,"color":Color("#f5e3bb")})
 for spring in game.world_fountains:
  var chunk=bucket(spring);chunk.springs.append(spring-chunk.position)
  chunk.labels.append({"point":spring-chunk.position+Vector2(-100,-110),"text":"PILGRIM’S SPRING","size":16,"color":Color("#b7efdb")})
 for chunk in chunks.values():chunk.queue_redraw()
 builds+=1
func sync()->void:
 visible=game.started and game.mode=="arena" and not game.spectating() and not (game.session_menu!=null and game.session_menu.page in ["main","clear","options"])
 if not visible:return
 var key=str(game.match_id)+":"+str(game.arena_map)+":"+str(game.world_decorations.size())+":"+str(game.field_obstacles.size())+":"+str(game.world_buildings.size())+":"+str(game.world_fountains.size())
 if key!=signature:
  reset();signature=key;rebuild()
 var factor=game.media.factor()
 position=game.media.offset()-game.camera*factor;scale=Vector2.ONE*factor
 var bounds=Rect2(game.camera,game.VIEW/factor).grow(200)
 for chunk in chunks.values():chunk.visible=bounds.intersects(Rect2(chunk.position,Vector2(EDGE,EDGE)))

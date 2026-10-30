extends Node2D
## Retain only visible 512px terrain chunks, with a hard 48-chunk cap.
var source:Node
var chunks:Dictionary={}
var used:=0
var key=""
static var baked:Dictionary={}
class Chunk extends Node2D:
 var draws:Array=[]
 var stamp:=0
 func _draw()->void:
  for d in draws:
   if d[0]==null:draw_colored_polygon(d[1],d[2][0])
   else:draw_polygon(d[1],d[2],d[3],d[0])
func _ready()->void:
 z_index=-2;texture_repeat=CanvasItem.TEXTURE_REPEAT_ENABLED;queue_redraw()
func _process(_dt:float)->void:
 var game=source.adventure.game
 visible=source.active and str(source.data.get("id",""))=="sunfield" and (game.started if source.adventure.arcade else game.mode=="run") and game.session_menu.page not in ["main","clear","options"]
 if visible:sync(game.camera,game.VIEW)
func _draw()->void:
 draw_texture_rect(preload("res://scripts/sunfield_art257.gd").texture("grass"),Rect2(-512,-512,11824,7824),true,Color("#657664"))
func sync(camera:Vector2,view:Vector2)->void:
 var game=source.adventure.game;var factor=float(game.broadcast_scale)if source.adventure.arcade and game.spectating()else game.media.factor();var offset=game.broadcast_offset if source.adventure.arcade and game.spectating()else game.media.offset()
 position=offset-camera*factor;scale=Vector2.ONE*factor;view=game.get_viewport_rect().size/factor
 var lo=Vector2i(floori(camera.x/512),floori(camera.y/512));var hi=Vector2i(floori((camera.x+view.x)/512),floori((camera.y+view.y)/512));var next=str(lo)+str(hi)
 if next==key:return
 key=next;used+=1
 if baked.is_empty():baked=JSON.parse_string(FileAccess.get_file_as_string("res://assets/sunfield257/terrain.json"))
 for chunk in chunks.values():chunk.visible=false
 for x in range(lo.x,hi.x+1):
  for y in range(lo.y,hi.y+1):
   var id=str(x)+","+str(y)
   if not baked.chunks.has(id):continue
   if not chunks.has(id):
    var chunk=Chunk.new();chunk.position=Vector2(x,y)*512;chunk.texture_repeat=CanvasItem.TEXTURE_REPEAT_ENABLED
    for raw in baked.chunks[id]:
     var points=PackedVector2Array();var uv=PackedVector2Array();var period=256.0 if str(raw.style) in ["grass","stone","water"]else 128.0
     for point in raw.points:
      var p=Vector2(point[0],point[1]);points.append(p);uv.append((p+chunk.position)/period)
     var color=Color(raw.tint[0],raw.tint[1],raw.tint[2],raw.tint[3]);var tex=null if str(raw.style)=="shadow"else preload("res://scripts/sunfield_art257.gd").texture(str(raw.style));chunk.draws.append([tex,points,PackedColorArray([color]),uv])
    chunks[id]=chunk;add_child(chunk);chunk.queue_redraw()
   chunks[id].visible=true;chunks[id].stamp=used
 while chunks.size()>48:
  var oldest="";var age=used
  for id in chunks:
   if not chunks[id].visible and chunks[id].stamp<age:age=chunks[id].stamp;oldest=id
  if oldest.is_empty():break
  chunks[oldest].queue_free();chunks.erase(oldest)

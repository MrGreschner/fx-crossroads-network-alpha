extends RefCounted
## Shared native realm art: editor and play use identical tiles and prop footprints.
const W=preload("res://scripts/studio_world_project.gd")
var textures:Dictionary={}
var sorted_props:Array=[]
func png(encoded:String)->Texture2D:
 if not textures.has(encoded):
  var img=Image.new()
  if img.load_png_from_buffer(Marshalls.base64_to_raw(encoded))==OK:textures[encoded]=ImageTexture.create_from_image(img)
 return textures.get(encoded)
func asset(name:String)->Texture2D:
 var path="res://assets/"+str(W.TERRAIN.get(name,""))
 if not textures.has(path):textures[path]=load(path) if W.TERRAIN.has(name) and ResourceLoader.exists(path) else null
 return textures[path]
func prepare(world:Dictionary)->void:
 invalidate();tile_images.clear()
 sorted_props=world.placements.filter(func(p):return p.kind=="object")
 sorted_props.sort_custom(func(a,b):return a.cell[1]<b.cell[1])
var chunks:Dictionary={}
var tile_images:Dictionary={}
var chunk_order:Array=[]
func invalidate()->void:chunks.clear();chunk_order.clear()
func tile_image(tile:Dictionary)->Image:
 var key=str(tile.get("image","")) if not str(tile.get("image","")).is_empty() else str(tile.name)
 if not tile_images.has(key):
  var tex:Texture2D=png(tile.image) if not str(tile.get("image","")).is_empty() else asset(tile.name)
  var img:Image=tex.get_image() if tex!=null else Image.create(40,40,false,Image.FORMAT_RGBA8)
  img=img.duplicate();img.convert(Image.FORMAT_RGBA8);img.resize(40,40,Image.INTERPOLATE_NEAREST)
  if tex==null:img.fill(Color(tile.color))
  if tile.name=="Lava":
   for y in 40:
    for x in 40:img.set_pixel(x,y,img.get_pixel(x,y)*Color("#ef815b"))
  tile_images[key]=img
 return tile_images[key]
func bake(world:Dictionary,cell:Vector2i)->Texture2D:
 if chunks.has(cell):return chunks[cell]
 var image=Image.create(640,640,false,Image.FORMAT_RGBA8);image.fill(Color.TRANSPARENT);var w=int(world.width);var h=int(world.height)
 for iy in 16:
  for ix in 16:
   var x=cell.x*16+ix;var y=cell.y*16+iy
   if x<0 or y<0 or x>=w or y>=h:continue
   var index=int(world.grid[y*w+x]);var tile:Dictionary=world.tiles[index];var colour=Color(tile.color);var at=Vector2i(ix,iy)*40
   image.blit_rect(tile_image(tile),Rect2i(0,0,40,40),at)
   if not tile.name in ["Path","Water","Sand","Lava"]:continue
   for step in [Vector2i.LEFT,Vector2i.RIGHT,Vector2i.UP,Vector2i.DOWN]:
    var next=Vector2i(x,y)+step
    if next.x<0 or next.y<0 or next.x>=w or next.y>=h or int(world.grid[next.y*w+next.x])==index:continue
    var edge=Rect2i(at+Vector2i(0 if step.x<0 else 38 if step.x>0 else 0,0 if step.y<0 else 38 if step.y>0 else 0),Vector2i(2,40) if step.x!=0 else Vector2i(40,2))
    image.fill_rect(edge,colour.darkened(.25));image.fill_rect(Rect2i(edge.position-step*2,edge.size),colour.lightened(.12))
 var texture=ImageTexture.create_from_image(image);chunks[cell]=texture;chunk_order.append(cell)
 if chunk_order.size()>16:chunks.erase(chunk_order.pop_front())
 return texture
func ground(node:CanvasItem,world:Dictionary,view:Rect2,time:float,grid:bool=false)->void:
 var w=int(world.width);var h=int(world.height)
 for y in range(maxi(0,int(floorf(view.position.y/640))),mini(int(ceilf(h/16.0)),int(ceilf(view.end.y/640)))):
  for x in range(maxi(0,int(floorf(view.position.x/640))),mini(int(ceilf(w/16.0)),int(ceilf(view.end.x/640)))):
   var cell=Vector2i(x,y);node.draw_texture_rect(bake(world,cell),Rect2(Vector2(cell)*640,Vector2(640,640)),false)
 var first=Vector2i(maxi(0,int(floorf(view.position.x/40))),maxi(0,int(floorf(view.position.y/40))))
 var last=Vector2i(mini(w,int(ceilf(view.end.x/40))+1),mini(h,int(ceilf(view.end.y/40))+1))
 for y in range(first.y,last.y):
  for x in range(first.x,last.x):
   var tile:Dictionary=world.tiles[int(world.grid[y*w+x])];var r=Rect2(x*40,y*40,40,40)
   if tile.name in ["Water","Lava"]:
    var shift=fmod(time*8+x*7+y*13,28.0)
    node.draw_line(r.position+Vector2(5,shift+5),r.position+Vector2(22,shift+5),Color("#b9e7f1" if tile.name=="Water" else "#ffd77b",.4),1)
   if grid:
    node.draw_rect(r,Color(0,0,0,.12),false,1)
    if tile.block_move:node.draw_line(r.position+Vector2(7,7),r.end-Vector2(7,7),Color(1,1,1,.28),1)
func prop(node:CanvasItem,world:Dictionary,placed:Dictionary)->void:
 var object:Dictionary=world.objects[placed.id];var at=(Vector2(placed.cell[0],placed.cell[1])+Vector2(.5,.5))*40;var dims=Vector2(object.width,object.height)
 node.draw_set_transform(at,0,Vector2(1,.32));node.draw_circle(Vector2.ZERO,dims.x*.35,Color(0,0,0,.17));node.draw_set_transform(Vector2.ZERO)
 var tex=png(object.image)
 if tex!=null:node.draw_texture_rect(tex,Rect2(at-Vector2(dims.x*.5,dims.y*.8),dims),false)
func props(node:CanvasItem,world:Dictionary,view:Rect2,cut:float=INF,front:bool=false)->void:
 for placed in sorted_props:
  var at=(Vector2(placed.cell[0],placed.cell[1])+Vector2(.5,.5))*40
  if (at.y>cut)!=front or not view.grow(170).has_point(at):continue
  # Caller owns its camera transform: no transform-changing helpers here.
  var object:Dictionary=world.objects[placed.id];var dims=Vector2(object.width,object.height);var tex=png(object.image)
  node.draw_rect(Rect2(at-Vector2(dims.x*.3,3),Vector2(dims.x*.6,8)),Color(0,0,0,.15))
  if tex!=null:node.draw_texture_rect(tex,Rect2(at-Vector2(dims.x*.5,dims.y*.8),dims),false)
func atmosphere(node:CanvasItem,world:Dictionary,screen:Vector2,time:float)->void:
 var env:Dictionary=world.get("environment",{});var light=str(env.get("lighting","Day"));var weather=str(env.get("weather","Clear"));var strength=float(env.get("intensity",.5))
 var tint={"Day":Color.TRANSPARENT,"Dusk":Color(.3,.1,.28,.16),"Night":Color(.03,.08,.23,.35),"Moonlight":Color(.12,.18,.4,.22)}[light]
 node.draw_rect(Rect2(Vector2.ZERO,screen),tint)
 if weather=="Clear":return
 for n in range(int(20+strength*50)):
  var at=Vector2(fposmod(n*173.7+sin(time*.7+n)*12,screen.x),fposmod(n*81.4+time*(95 if weather=="Rain" else 18),screen.y))
  if weather=="Rain":node.draw_line(at,at+Vector2(-3,12),Color(.65,.8,.94,.4),1)
  else:node.draw_circle(at,1.5 if weather=="Snow" else 1.0,Color("#b8ed94" if weather=="Fireflies" else "#ffe4c6" if weather=="Ash" else "#eef5fa",.3+.35*sin(time*2+n)))

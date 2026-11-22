extends RefCounted
## Shared offline artwork. Trunks, roads, doors, collision and all plant-state logic stay in their owners.
const Fall=preload("res://scripts/fall_art356.gd")
const Spring=preload("res://scripts/spring_art357.gd")
static var sheet:Texture2D
static var glass:Texture2D
static var frames:Dictionary={}
static var specs:Dictionary={}
static var masks:Dictionary={}
static var uvs:Dictionary={}
static var white=PackedColorArray([Color.WHITE])
static var tree_draws=0
static var plant_draws=0
static func rect_of(a:Array)->Rect2:return Rect2(a[0],a[1],a[2],a[3])
static func prepare()->void:
 if sheet!=null:return
 specs=JSON.parse_string(FileAccess.get_file_as_string("res://assets/town243/nature.json"))
 var im=Image.new();im.load_png_from_buffer(FileAccess.get_file_as_bytes("res://assets/town243/nature.png"));sheet=ImageTexture.create_from_image(im)
 im=Image.new();im.load_png_from_buffer(FileAccess.get_file_as_bytes("res://assets/town243/glass.png"));glass=ImageTexture.create_from_image(im)
 for id in specs:
  var v:Dictionary=specs[id];var tex=AtlasTexture.new();tex.atlas=sheet;tex.region=rect_of(v.region);frames[id]=tex
  var a:Array=v.region;var b:Array=v.inset
  var r=Rect2(a[0]+b[0],a[1]+b[1],b[2],b[3]);var tl=r.position/sheet.get_size();var br=r.end/sheet.get_size()
  uvs[id]=PackedVector2Array([tl,Vector2(br.x,tl.y),br,Vector2(tl.x,br.y)])
  if not v.emission_region.is_empty():
   var mask=AtlasTexture.new();mask.atlas=glass;mask.region=rect_of(v.emission_region);masks[id]=mask
static func texture(id:String)->Texture2D:
 prepare();return frames[id]
static var seasonal_frames:Dictionary={}
static func seasonal_texture(id:String,season:String)->Texture2D:
 var original=texture(id)
 var atlas=preload("res://scripts/town_homes382.gd").texture(id,season)
 if atlas==null:return original
 var key=season+":"+id
 if not seasonal_frames.has(key):
  var frame=AtlasTexture.new();frame.atlas=atlas;frame.region=original.region;seasonal_frames[key]=frame
 return seasonal_frames[key]
static func draw(g:Node2D,id:String,screen:Rect2,tint:Color=Color.WHITE)->void:
 if not Rect2(Vector2.ZERO,g.VIEW).intersects(screen):return
 var art:=texture(id)
 var winter_frame=preload("res://scripts/winter_buildings383.gd").texture("nature",id,g.town_life.calendar.season(),null)
 if winter_frame!=null:
  g.draw_texture_rect(winter_frame,screen,false,tint);plant_draws+=1;return
 var atlas=seasonal_atlas(id,g.town_life.calendar.season())
 if atlas!=null:g.draw_texture_rect_region(atlas,screen,art.region,tint)
 else:g.draw_texture_rect(art,screen,false,tint)
 plant_draws+=1
 var winter=preload("res://scripts/winter_art353.gd")
 if id in ["shrub","garden_bed"] and winter.active(g):
  g.draw_texture_rect(winter.roof("nature:"+id,art),screen,false,tint)
static func seasonal_atlas(id:String,season:String)->Texture2D:
 var homes=preload("res://scripts/town_homes382.gd").texture(id,season)
 if homes!=null:return homes
 if season=="Fall" and id in Fall.TOWN_PLANTS:return Fall.texture("town_canopies")
 if season=="Spring" and id in Spring.TOWN_PLANTS:return Spring.texture("town_canopies")
 return null

static func sway(at:Vector2,clock:float)->float:
 # At most one world pixel, dephased by position; the bottom/root vertices never move.
 return roundf(sin(clock*.68+at.x*.013+at.y*.009))
static func tree(g:Node2D,id:String,screen:Rect2,at:Vector2)->void:
 if not Rect2(Vector2.ZERO,g.VIEW).grow(2).intersects(screen):return
 prepare();var v:Dictionary=specs[id];var b:Array=v.inset;var scale=screen.size/Vector2(v["size"][0],v["size"][1])
 var r=Rect2(screen.position+Vector2(b[0],b[1])*scale,Vector2(b[2],b[3])*scale)
 var shift=Vector2(sway(at,g.town_life.clock),0)
 # One textured quad, cached UVs, fixed root edge: no extra nodes, shaders or render targets.
 var vertices=PackedVector2Array([r.position+shift,Vector2(r.end.x,r.position.y)+shift,r.end,Vector2(r.position.x,r.end.y)])
 var winter=preload("res://scripts/winter_art353.gd")
 var season:String=g.town_life.calendar.season()
 var canopy=seasonal_atlas(id,season)
 if season=="Winter":canopy=winter.canopy(sheet)
 if canopy==null:canopy=sheet
 g.draw_polygon(vertices,white,uvs[id],canopy);tree_draws+=1
 if season=="Spring" and id in Spring.BLOOM_TREES:Spring.petals(g,id,r,at)
static func home(g:Node2D,id:String,camera:Vector2)->void:
 prepare();var r=rect_of(specs[id].rect);draw(g,id,Rect2(r.position-camera,r.size))
static func chimney(id:String)->Vector2:
 prepare();var v:Dictionary=specs[id];return rect_of(v.rect).position+Vector2(v.chimney[0],v.chimney[1])
static func home_windows(id:String)->Array:
 prepare();var v:Dictionary=specs[id];var r=rect_of(v.rect);var result=[]
 for point in v.window_lights:result.append(r.position+Vector2(point[0],point[1]))
 return result
static func star_point(n:int,at:Vector2,clock:float)->Vector2:
 prepare();var v:Dictionary=specs.starlace;var a:Array=v.stars[n];var b:Array=v.inset
 var phase=sway(at,clock)*clampf(1-(float(a[1])-b[1])/b[3],0,1)
 return at-Vector2(112.5,235)+Vector2(a[0]+phase,a[1])
static func draw_emission(g:Node2D,camera:Vector2,night:float)->void:
 if night<=.01:return
 prepare();var view=Rect2(camera,g.VIEW)
 for id in masks:
  var v:Dictionary=specs[id];var r=rect_of(v.rect)
  if not view.intersects(r):continue
  var b:Array=v.emission_bounds
  g.draw_texture_rect(masks[id],Rect2(r.position+Vector2(b[0],b[1])-camera,Vector2(b[2]-b[0],b[3]-b[1])),false,Color(1,1,1,night))
 # Retained porch emitters remain at their original world coordinates.
 for home_spec in g.town_life.neighborhood.HOMES:
  var p:Vector2=home_spec.door+Vector2(38,-50)
  if view.has_point(p):g.draw_rect(Rect2(p-camera-Vector2(2,4),Vector2(4,8)),Color(1,.81,.46,night*.85))
static func garden(g:Node2D,camera:Vector2)->void:
 # Existing tiny western civic planting accents, with their original footprints.
 for n in 9:
  var at=Vector2(-290+n*85,1798)
  draw(g,"shrub",Rect2(at-camera-Vector2(5,7),Vector2(17,12)))
static func river_reeds(g:Node2D,camera:Vector2)->void:
 for y in range(310,2140,145):
  if y>1020 and y<1290:continue
  for x in [2250,2470]:
   var at=Vector2(x,y)
   if not Rect2(camera,g.VIEW).grow(40).has_point(at):continue
   g.draw_circle(at-camera+Vector2(0,5),8,Color("#929e86"))
   tree(g,"reeds",Rect2(at-camera-Vector2(14,36),Vector2(28,38)),at)
static func ground_cuts()->Array:
 var cuts=[Rect2(2448,935,694,790),Rect2(2544,784,302,81),Rect2(2759,653,83,131),Rect2(2544,865,91,231),Rect2(-1760,350,560,1085),Rect2(-1228,1040,44,157),Rect2(-988,1040,44,157),Rect2(-1175,1195,245,130),Rect2(848,-220,104,414)]
 for row in 3:
  for col in 2:cuts.append(Rect2(Vector2(805 if col==0 else 962,1840+row*85)-Vector2(2,2),Vector2(54 if col==0 else 94,46)))
 for n in 9:cuts.append(Rect2(Vector2(-290+n*85,1798)-Vector2(6,9),Vector2(20,18)))
 for y in range(310,2140,145):
  if y>1020 and y<1290:continue
  for x in [2250,2470]:cuts.append(Rect2(x-12,y-30,25,44))
 return cuts
static func clean_ground_tiles(tiles:Array,cuts:Array=[])->Array:
 # Split cached UV rectangles ONCE to omit old flat plant paint only.
 # Bank stones/fence crossings are redrawn identically under the new foliage.
 var result=[]
 if cuts.is_empty():cuts=ground_cuts()
 for tile in tiles:
  var original=rect_of(tile.world);var uv=rect_of(tile.region);var pieces=[original]
  for cut in cuts:
   var next=[]
   for piece in pieces:
    if not piece.intersects(cut):next.append(piece);continue
    var hit:Rect2=piece.intersection(cut)
    for part in [Rect2(piece.position,Vector2(piece.size.x,hit.position.y-piece.position.y)),Rect2(Vector2(piece.position.x,hit.end.y),Vector2(piece.size.x,piece.end.y-hit.end.y)),Rect2(Vector2(piece.position.x,hit.position.y),Vector2(hit.position.x-piece.position.x,hit.size.y)),Rect2(Vector2(hit.end.x,hit.position.y),Vector2(piece.end.x-hit.end.x,hit.size.y))]:
     if part.size.x>0 and part.size.y>0:next.append(part)
   pieces=next
  for piece in pieces:
   var updated:Dictionary=tile.duplicate();var offset=piece.position-original.position
   updated.world=[piece.position.x,piece.position.y,piece.size.x,piece.size.y];updated.region=[uv.position.x+offset.x,uv.position.y+offset.y,piece.size.x,piece.size.y];result.append(updated)
 return result

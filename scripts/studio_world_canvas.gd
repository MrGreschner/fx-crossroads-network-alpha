extends Control
const W=preload("res://scripts/studio_world_project.gd")
signal edited
var realm:Dictionary={}
var mode="tile"
var tile=0
var picked=""
var painting=false
var zoom=1.0
var pan=Vector2.ZERO
var textures={}
var last_cell=Vector2i(-1,-1)
var brush=1
var show_grid=true
var history:Array=[]
var future:Array=[]
var renderer=preload("res://scripts/studio_world_renderer.gd").new()
var clock=0.0
var map_texture:ImageTexture
func setup(value:Dictionary)->void:
 realm=value;custom_minimum_size=Vector2(660,470);mouse_filter=MOUSE_FILTER_STOP;clip_contents=true;texture_filter=TEXTURE_FILTER_NEAREST;textures.clear();renderer.prepare(realm);fit();refresh_minimap();queue_redraw()
func scale_factor()->float:return zoom
func origin()->Vector2:return pan
func fit()->void:
 zoom=clampf(minf(maxf(size.x,660)/(float(realm.width)*40),maxf(size.y,470)/(float(realm.height)*40)),.06,2);pan=Vector2.ZERO;queue_redraw()
func clamp_pan()->void:
 pan=pan.clamp((size-Vector2(realm.width,realm.height)*40*zoom).min(Vector2.ZERO),Vector2.ZERO)
func focus_spawn()->void:
 zoom=.9;pan=size*.5-(Vector2(realm.spawn[0],realm.spawn[1])+Vector2(.5,.5))*40*zoom;clamp_pan();queue_redraw()
func snapshot()->void:
 history.append({"grid":realm.grid.duplicate(),"placements":realm.placements.duplicate(true),"spawn":realm.spawn.duplicate(),"exit":realm.exit.duplicate()});if history.size()>12:history.pop_front()
 future.clear()
func restore(data:Dictionary)->void:
 for field in data:realm[field]=data[field].duplicate(true)
 renderer.prepare(realm);refresh_minimap();edited.emit();queue_redraw()
func undo()->void:
 if history.is_empty():return
 future.append({"grid":realm.grid.duplicate(),"placements":realm.placements.duplicate(true),"spawn":realm.spawn.duplicate(),"exit":realm.exit.duplicate()});restore(history.pop_back())
func redo()->void:
 if future.is_empty():return
 history.append({"grid":realm.grid.duplicate(),"placements":realm.placements.duplicate(true),"spawn":realm.spawn.duplicate(),"exit":realm.exit.duplicate()});restore(future.pop_back())
func paint(at:Vector2)->void:
 var point=(at-origin())/(40*scale_factor());var c=Vector2i(floorf(point.x),floorf(point.y))
 if c.x<0 or c.y<0 or c.x>=int(realm.width) or c.y>=int(realm.height) or c==last_cell:return
 last_cell=c;var cell=[c.x,c.y]
 match mode:
  "tile":
   for y in range(maxi(0,c.y-brush/2),mini(int(realm.height),c.y+(brush+1)/2)):
    for x in range(maxi(0,c.x-brush/2),mini(int(realm.width),c.x+(brush+1)/2)):realm.grid[y*int(realm.width)+x]=tile
  "spawn","exit":realm[mode]=cell
  "erase":realm.placements=realm.placements.filter(func(p):return p.cell!=cell)
  "object","enemy":
   if picked.is_empty() or realm.placements.size()>=W.MAX_PLACEMENTS:return
   if mode=="enemy" and realm.placements.filter(func(p):return p.kind=="enemy").size()>=W.MAX_ENEMIES:return
   if not realm.placements.any(func(p):return p.kind==mode and p.cell==cell):realm.placements.append({"kind":mode,"id":picked,"cell":cell})
 renderer.prepare(realm);edited.emit();queue_redraw()
func stroke(at:Vector2)->void:
 if last_cell.x<0 or mode not in ["tile","erase"]:paint(at);return
 var start=origin()+(Vector2(last_cell)+Vector2(.5,.5))*40*zoom
 var steps=maxi(1,int(start.distance_to(at)/maxf(2,20*zoom)))
 for n in range(1,mini(steps,512)+1):paint(start.lerp(at,float(n)/mini(steps,512)))
func minimap_rect()->Rect2:return Rect2(size-Vector2(160,130),Vector2(148,108))
func refresh_minimap()->void:
 var img=Image.create(int(realm.width),int(realm.height),false,Image.FORMAT_RGB8)
 for y in int(realm.height):
  for x in int(realm.width):img.set_pixel(x,y,Color(realm.tiles[int(realm.grid[y*int(realm.width)+x])].color))
 map_texture=ImageTexture.create_from_image(img)
func _gui_input(event:InputEvent)->void:
 if event is InputEventMouseButton:
  if event.button_index==MOUSE_BUTTON_LEFT:
   if event.pressed and minimap_rect().has_point(event.position):
    var at=(event.position-minimap_rect().position)/minimap_rect().size*Vector2(realm.width,realm.height)*40;pan=size*.5-at*zoom;clamp_pan();queue_redraw();accept_event();return
   painting=event.pressed;last_cell=Vector2i(-1,-1)
   if painting:snapshot();paint(event.position)
   else:refresh_minimap()
  elif event.pressed and event.button_index in [MOUSE_BUTTON_WHEEL_UP,MOUSE_BUTTON_WHEEL_DOWN]:
   var at=(event.position-pan)/zoom;zoom=clampf(zoom*(1.15 if event.button_index==MOUSE_BUTTON_WHEEL_UP else 1.0/1.15),.06,2);pan=event.position-at*zoom;clamp_pan();queue_redraw()
  accept_event()
 elif event is InputEventMouseMotion:
  if event.button_mask&(MOUSE_BUTTON_MASK_MIDDLE|MOUSE_BUTTON_MASK_RIGHT):pan+=event.relative;clamp_pan();queue_redraw()
  elif painting:stroke(event.position)
 elif event is InputEventScreenTouch:
  painting=event.pressed;last_cell=Vector2i(-1,-1)
  if painting:snapshot();paint(event.position)
  else:refresh_minimap()
 elif event is InputEventScreenDrag:
  if mode=="pan":pan+=event.relative;clamp_pan();queue_redraw()
  elif painting:stroke(event.position)
func _input(event:InputEvent)->void:
 if (event is InputEventMouseButton or event is InputEventScreenTouch) and not event.pressed:painting=false
func texture(encoded:String)->Texture2D:return renderer.png(encoded)
func _process(dt:float)->void:
 clock+=dt
 if int(clock*12)!=int((clock-dt)*12):queue_redraw()
func _draw()->void:
 if realm.is_empty():return
 draw_rect(Rect2(Vector2.ZERO,size),Color("#0c202b"));var start=origin();var scale_value=scale_factor();var view=Rect2(-start/scale_value,size/scale_value)
 draw_set_transform(start,0,Vector2.ONE*scale_value);
 if zoom<.3 and map_texture!=null:draw_texture_rect(map_texture,Rect2(Vector2.ZERO,Vector2(realm.width,realm.height)*40),false)
 else:renderer.ground(self,realm,view,clock,show_grid and zoom>.3)
 renderer.props(self,realm,view)
 for placed in realm.placements:
  if placed.kind!="enemy":continue
  var at=(Vector2(placed.cell[0],placed.cell[1])+Vector2(.5,.5))*40
  if not view.grow(100).has_point(at):continue
  var tex=texture(str(realm.enemies[placed.id].art.get("idle","")))
  if tex!=null:draw_texture_rect(tex,Rect2(at-Vector2(22,40),Vector2(44,52)),false)
  draw_circle(at,18,Color("#e5a078"),false,2)
 for field in ["spawn","exit"]:
  var at=(Vector2(realm[field][0],realm[field][1])+Vector2(.5,.5))*40
  draw_circle(at,18,Color("#8bebbc" if field=="spawn" else "#e9cb76"),false,3)
 draw_set_transform(Vector2.ZERO);renderer.atmosphere(self,realm,size,clock)
 var r=minimap_rect();draw_rect(r.grow(5),Color("#152c37"))
 if map_texture!=null:draw_texture_rect(map_texture,r,false)
 var world_size=Vector2(realm.width,realm.height)*40
 var visible_rect=Rect2(r.position+(view.position/world_size)*r.size,(view.size/world_size)*r.size).intersection(r)
 if visible_rect.has_area():draw_rect(visible_rect,Color("#fff0b7"),false,2)
 draw_string(ThemeDB.fallback_font,Vector2(12,24),"%s • %d × %d • %d%%" % [mode.capitalize(),realm.width,realm.height,int(zoom*100)],HORIZONTAL_ALIGNMENT_LEFT,-1,16,Color("#f3dfad"))

extends SceneTree
func _initialize():
 var source=Image.load_from_file("res://art_source/ram385/two_small_steps_source.png")
 var root="res://"
 var idle=Image.load_from_file(root+"assets/ram310/ram_0.png")
 print("idle ",idle.get_used_rect()," source ",source.get_size())
 for n in 2:
  var cell=source.get_region(Rect2i(n*source.get_width()/2,0,source.get_width()/2,source.get_height()))
  for y in cell.get_height():
   for x in cell.get_width():
    var c=cell.get_pixel(x,y)
    if c.a<.5:cell.set_pixel(x,y,Color(0,0,0,0))
  print("pose ",n," bounds ",cell.get_used_rect())
  var art=cell.get_region(cell.get_used_rect());art.resize(44,66,Image.INTERPOLATE_NEAREST)
  var frame=Image.create(80,80,false,Image.FORMAT_RGBA8);frame.blit_rect(art,Rect2i(0,0,44,66),Vector2i(17,8))
  # Retain the existing authored face/horns and tunic; use the new small planted steps below the hem.
  var original=Image.load_from_file(root+"assets/ram310/ram_"+str(n+1)+".png")
  frame.blit_rect(original,Rect2i(0,0,80,53),Vector2i.ZERO)
  for y in frame.get_height():
   for x in frame.get_width():
    if frame.get_pixel(x,y).a<.5:frame.set_pixel(x,y,Color(0,0,0,0))
  # Remove disconnected upper-body crop fragments (four dark pixels per old step).
  clean_fragments(frame)
  frame.save_png(root+"assets/ram385/ram_"+str(n+1)+".png")
 quit()

func clean_fragments(im:Image)->void:
 var seen={}
 for y in im.get_height():
  for x in im.get_width():
   var point=Vector2i(x,y)
   if seen.has(point) or im.get_pixelv(point).a<.5:continue
   var stack=[point];var group=[];seen[point]=true
   while not stack.is_empty():
    var p:Vector2i=stack.pop_back();group.append(p)
    for d in [Vector2i.LEFT,Vector2i.RIGHT,Vector2i.UP,Vector2i.DOWN]:
     var next=p+d
     if next.x<0 or next.y<0 or next.x>=im.get_width() or next.y>=im.get_height() or seen.has(next) or im.get_pixelv(next).a<.5:continue
     seen[next]=true;stack.append(next)
   if group.size()<8:
    for p in group:im.set_pixelv(p,Color(0,0,0,0))

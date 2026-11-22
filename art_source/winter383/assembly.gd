extends SceneTree
## Offline cropping/normalisation of image-generated winter artwork.
var ROOT=ProjectSettings.globalize_path("res://")
const SOURCE={"shops":"assets/town242/shops.png","landmarks":"assets/town241/landmarks.png","props":"assets/town240/props.png","street":"assets/town244/street.png","scenery":"assets/town246/scenery.png","mine":"assets/art232/mine.png","marina":"assets/marina250/bait_stall.png","nature":"assets/town243/nature.png"}
var originals={}
var sprites=[]
func rect(a:Array)->Rect2i:return Rect2i(int(a[0]),int(a[1]),int(a[2]),int(a[3]))
func _initialize():
 var references=JSON.parse_string(FileAccess.get_file_as_string(ROOT+"art_source/winter383/references.json"))
 var shops=JSON.parse_string(FileAccess.get_file_as_string(ROOT+"assets/town242/shops.json"))
 var landmarks=JSON.parse_string(FileAccess.get_file_as_string(ROOT+"assets/town241/landmarks.json"))
 var masks=Image.load_from_file(ROOT+"assets/town242/glass.png")
 for family in SOURCE:
  originals[family]=Image.load_from_file(ROOT+SOURCE[family]);originals[family].convert(Image.FORMAT_RGBA8)
 for group in references:
  var generated=Image.load_from_file(ROOT+"art_source/winter383/"+group+".png");generated.convert(Image.FORMAT_RGBA8)
  # Alpha matting only: remove transparent fringe/shadow pixels from generation.
  var threshold=.85 if group=="structures_b" else .5
  for y in generated.get_height():
   for x in generated.get_width():
    if generated.get_pixel(x,y).a<threshold:generated.set_pixel(x,y,Color(0,0,0,0))
  for item in references[group]:
   var grid=item.grid;var cols=int(grid[2]);var rows=int(grid[3])
   var x0=floori(float(grid[0])*generated.get_width()/cols);var x1=floori((float(grid[0])+1)*generated.get_width()/cols)
   var y0=floori(float(grid[1])*generated.get_height()/rows);var y1=floori((float(grid[1])+1)*generated.get_height()/rows)
   var cell=Rect2i(x0,y0,x1-x0,y1-y0);var art=generated.get_region(cell);var used=art.get_used_rect()
   assert(used.size.x>10 and used.size.y>10)
   art=art.get_region(used)
   var original:Image=originals[item.family].get_region(rect(item.original_region));var target=original.get_used_rect()
   art.resize(target.size.x,target.size.y,Image.INTERPOLATE_NEAREST)
   var painted=Image.create(original.get_width(),original.get_height(),false,Image.FORMAT_RGBA8);painted.fill(Color(0,0,0,0))
   painted.blit_rect(art,Rect2i(Vector2i.ZERO,art.get_size()),target.position)
   # Integrate authored snow into the unchanged source architecture. This keeps
   # every wall, door and window exactly registered, rather than stretching a
   # newly painted facade to fit an existing interaction or lighting mask.
   var result=original.duplicate()
   var plant_pixels={}
   if item.family=="shops" and item.id not in ["seedhouse","fishing"]:
    for sy in original.get_height():
     for sx in original.get_width():
      var c=original.get_pixel(sx,sy)
      if c.a>.5 and c.g>c.r*1.12 and c.g>c.b*1.12 and c.get_luminance()<.7:
       for dy in range(-3,4):
        for dx in range(-3,4):
         var p=Vector2i(sx+dx,sy+dy)
         if p.x>=0 and p.y>=0 and p.x<original.get_width() and p.y<original.get_height():plant_pixels[p]=true
   for sy in original.get_height():
    for sx in original.get_width():
     var c=painted.get_pixel(sx,sy)
     var snowy=c.a>.5 and c.get_luminance()>.57 and c.b>=c.r*.97 and c.b>=c.g*.97
     if snowy or plant_pixels.has(Vector2i(sx,sy)):result.set_pixel(sx,sy,c)
   if item.family=="nature":result=painted
   # Existing label panels and glass retain pixel-exact placement/colours so
   # lettering and the original nighttime emission masks keep lining up.
   if item.family=="shops":
    var spec=shops[item.id]
    if not spec.sign.is_empty():
     var sign=Rect2i(Vector2i(floori(spec.sign[0]),floori(spec.sign[1])),Vector2i(ceili(spec.sign[2]),ceili(spec.sign[3])))
     result.blit_rect(original,sign,sign.position)
    if not spec.emission_region.is_empty():
     var er=rect(spec.emission_region);var eb=spec.emission_bounds
     for sy in er.size.y:
      for sx in er.size.x:
       var p=Vector2i(sx+int(eb[0]),sy+int(eb[1]))
       if masks.get_pixel(er.position.x+sx,er.position.y+sy).a>.01:result.set_pixelv(p,original.get_pixelv(p))
   if item.family=="landmarks":
    for pane in landmarks[item.id].glass:
     var box=rect(pane);result.blit_rect(original,box,box.position)
   sprites.append({"family":item.family,"id":item.id,"image":result,"source":SOURCE[item.family],"original_region":item.original_region,"original_used":[target.position.x,target.position.y,target.size.x,target.size.y],"generated_group":group,"generated_cell":[cell.position.x,cell.position.y,cell.size.x,cell.size.y],"generated_used":[used.position.x,used.position.y,used.size.x,used.size.y]})
 sprites.sort_custom(func(a,b):return a.image.get_height()>b.image.get_height())
 var board=Image.create(2048,2048,false,Image.FORMAT_RGBA8);board.fill(Color(0,0,0,0))
 var x=2;var y=2;var row_height=0;var frames={}
 for sprite in sprites:
  var size:Vector2i=sprite.image.get_size()
  if x+size.x+2>2048:x=2;y+=row_height+4;row_height=0
  assert(y+size.y+2<=2048)
  board.blit_rect(sprite.image,Rect2i(Vector2i.ZERO,size),Vector2i(x,y))
  var info=sprite.duplicate();info.erase("image");info["region"]=[x,y,size.x,size.y]
  frames[sprite.family+":"+sprite.id]=info
  x+=size.x+4;row_height=maxi(row_height,size.y)
 var height=ceili(float(y+row_height+2)/64)*64
 board=board.get_region(Rect2i(0,0,2048,height))
 # The marina fittings are a precomposed world cache: replace its embedded
 # summer bait stall offline as well, preserving every other fitting and label.
 var fittings=Image.load_from_file(ROOT+"assets/marina250/fittings.png");fittings.convert(Image.FORMAT_RGBA8)
 var stall=board.get_region(rect(frames["marina:bait_stall"].region));stall.resize(150,125,Image.INTERPOLATE_NEAREST)
 fittings.fill_rect(Rect2i(208,76,150,125),Color(0,0,0,0));fittings.blend_rect(stall,Rect2i(0,0,150,125),Vector2i(208,76))
 fittings.save_png(ROOT+"assets/town_winter383/marina_fittings.png")
 var post_original=Image.load_from_file(ROOT+"assets/town_cache/post242.png");post_original.convert(Image.FORMAT_RGBA8)
 var post=post_original.duplicate();var old_region=rect(shops.post.region);var old_post:Image=originals.shops.get_region(old_region)
 var new_post=board.get_region(rect(frames["shops:post"].region))
 var offset=Vector2i(20,28)
 for py in old_post.get_height():
  for px in old_post.get_width():
   if old_post.get_pixel(px,py).a>.5:post.set_pixelv(offset+Vector2i(px,py),Color(0,0,0,0))
 post.blend_rect(new_post,Rect2i(Vector2i.ZERO,new_post.get_size()),offset)
 var ps=shops.post.sign;var sign_box=Rect2i(offset+Vector2i(floori(ps[0]),floori(ps[1])),Vector2i(ceili(ps[2]),ceili(ps[3])))
 post.blit_rect(post_original,sign_box,sign_box.position)
 post.save_png(ROOT+"assets/town_winter383/post242.png")

 board.save_png(ROOT+"assets/town_winter383/buildings.png")
 var f=FileAccess.open(ROOT+"assets/town_winter383/buildings.json",FileAccess.WRITE)
 f.store_string(JSON.stringify({"version":383,"season":"Winter","size":[2048,height],"frames":frames},"  "))
 print("PASS ",frames.size()," winter building/structure sprites normalised into one cached atlas ",board.get_size())
 quit()

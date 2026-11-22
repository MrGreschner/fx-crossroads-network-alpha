extends SceneTree
## Offline production assembly only: crop/scale the generated variant into the
## original atlas cells. All unrelated pixels are copied from the original atlas.
var ROOT=ProjectSettings.globalize_path("res://")
const CELLS={
 "cliff_cottage":Rect2i(0,0,378,356),
 "artists_duplex":Rect2i(378,0,380,356),
 "orchard_home":Rect2i(760,0,375,357),
 "guard_townhouse":Rect2i(0,358,379,359),
 "river_home":Rect2i(380,358,407,361),
 "tidekeeper":Rect2i(0,718,305,294)}
func _initialize():
 var summer=Image.load_from_file(ROOT+"assets/town243/nature.png")
 var generated=Image.load_from_file(ROOT+"art_source/winter382/generated_homes.png")
 summer.convert(Image.FORMAT_RGBA8);generated.convert(Image.FORMAT_RGBA8)
 # Remove near-transparent fringe RGB before nearest-neighbour sprite extraction.
 for y in generated.get_height():
  for x in generated.get_width():
   var c=generated.get_pixel(x,y)
   if c.a<.5:generated.set_pixel(x,y,Color(0,0,0,0))
 var result=summer.duplicate()
 var specs=JSON.parse_string(FileAccess.get_file_as_string(ROOT+"assets/town243/nature.json"))
 var entries={}
 for id in CELLS:
  var a=specs[id].region;var cell=Rect2i(a[0],a[1],a[2],a[3])
  var original=summer.get_region(cell);var target=original.get_used_rect()
  var source=generated.get_region(CELLS[id]);var used=source.get_used_rect()
  source=source.get_region(used)
  source.resize(target.size.x,target.size.y,Image.INTERPOLATE_NEAREST)
  result.fill_rect(cell,Color(0,0,0,0))
  result.blit_rect(source,Rect2i(Vector2i.ZERO,source.get_size()),cell.position+target.position)
  source.save_png(ROOT+"assets/town_winter382/"+id+".png")
  entries[id]={"atlas_region":a,"summer_used":[target.position.x,target.position.y,target.size.x,target.size.y],"generated_crop":[CELLS[id].position.x,CELLS[id].position.y,CELLS[id].size.x,CELLS[id].size.y],"generated_used":[used.position.x,used.position.y,used.size.x,used.size.y]}
 result.save_png(ROOT+"assets/town_winter382/homes.png")
 var f=FileAccess.open(ROOT+"assets/town_winter382/homes.json",FileAccess.WRITE)
 f.store_string(JSON.stringify({"version":382,"source":"assets/town243/nature.png","season":"Winter","homes":entries},"  "))
 print("PASS six generated winter homes assembled; original atlas size and all non-home pixels preserved")
 quit()

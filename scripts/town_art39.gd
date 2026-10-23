extends RefCounted
## Offline rasterized fixed architecture. The live world still owns all collisions,
## NPCs, water, day/night access checks and interactions. No render targets at runtime.
const ROOT="res://assets/town_cache/"
static var loaded=false
static var layers:Dictionary={}
static var pages:Dictionary={}
static var lookups=0
static var visible_tiles=0
static func prepare()->void:
 if loaded:return
 loaded=true
 if FileAccess.file_exists(ROOT+"town39.json"):
  var data=JSON.parse_string(FileAccess.get_file_as_string(ROOT+"town39.json"))
  if data is Dictionary:layers=data.get("layers",{})
static func page(name:String)->Texture2D:
 if pages.has(name):return pages[name]
 var texture=preload("res://scripts/town_sprite_cache.gd").texture(name)
 if texture!=null:pages[name]=texture
 return texture
static func draw(c:Node2D,kind:String,camera:Vector2)->void:
 prepare();lookups+=1
 if not layers.has(kind):source(c,kind,camera);return
 var view=Rect2(camera,c.VIEW).grow(2)
 for tile in layers[kind]:
  var p=tile.world;var rect=Rect2(p[0],p[1],p[2],p[3])
  if not view.intersects(rect):continue
  var texture=page(str(tile.page))
  if texture==null:source(c,kind,camera);return
  var uv=tile.region
  c.draw_texture_rect_region(texture,Rect2(rect.position-camera,rect.size),Rect2(uv[0],uv[1],uv[2],uv[3]))
  visible_tiles+=1
static func source(c:Node2D,kind:String,camera:Vector2)->void:
 match kind:
  "streets":c.town_plan.draw_ground_source(c,camera)
  "rails":preload("res://scripts/town_v173.gd").draw_tracks_source(c,camera)
  "chapter_ground":c.town_chapter.draw_ground_source(c,camera)
  "studio":c.studio_town.draw_structure_source(c,camera)
  "academy":c.academy_town.draw_structure_source(c,camera)
  "marina_deck":preload("res://scripts/town_marina.gd").draw_structure_source(c,camera)
  "marina_cottage","marina_cottage_night":c.marina_life.draw_cottage_source(c,camera)
  "marina_fittings":c.marina_life.draw_fittings_source(c,camera)
  "pond":c.town_scenery.draw_pond_source(c,camera)
  "lookout":c.town_scenery.draw_lookout_source(c,camera,ThemeDB.fallback_font)
  _:
   if kind.begins_with("boat_"):
    var index=int(kind.trim_prefix("boat_"));var dock=preload("res://scripts/town_marina.gd");var spec=dock.BERTHS[index]
    dock.boat_source(c,spec.at-camera,int(spec.crew),float(spec.angle),Color(spec.hull),Color(spec.trim),0)

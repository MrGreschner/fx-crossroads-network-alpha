extends RefCounted
## Spring uses the same scenery footprints as the summer map.
const ROOT="res://assets/spring357/"
const ATLAS=preload("res://scripts/season_art_atlas.gd")
const TOWN_PLANTS=["ancient","starlace","amber_willow","apple","knot_willow","flowers","flowers_small","reeds","shrub"]
const BLOOM_TREES=["apple","starlace"]

static func texture(id:String)->Texture2D:
 return ATLAS.texture(ROOT,id)

static func lake_plant(id:String)->Texture2D:
 return ATLAS.lake_plant(ROOT,id)

static func petals(g:Node2D,id:String,canopy:Rect2,at:Vector2)->void:
 var seconds:float=g.town_life.clock
 var color=Color("#efb8be") if id=="apple" else Color("#d8c4ec")
 for n in 4:
  var phase=fposmod(seconds*.24+at.x*.004+at.y*.003+float(n)*.27,1.0)
  var origin=canopy.position+canopy.size*Vector2(.25+float(n)*.18,.30)
  var p=origin+Vector2(phase*23+sin(phase*TAU+float(n))*7,canopy.size.y*.64*phase)
  color.a=.82*smoothstep(0.0,.12,phase)*(1.0-smoothstep(.72,1.0,phase))
  g.draw_rect(Rect2(p.floor(),Vector2(3,2)),color)

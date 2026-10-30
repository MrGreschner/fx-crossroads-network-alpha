extends RefCounted
## Portable data only; object and realm imports never contain script paths.
const P=preload("res://scripts/workshop_project.gd")
const MAX_SIDE=256
const MAX_PLACEMENTS=1000
const MAX_ENEMIES=64
const ASSETS={"Oak tree":"tree.png","Pine tree":"tree.png","Willow":"v50_moss_tree.png","Palm":"lantern_tree.png","Flower bed":"flower_bed.png","Sunflower":"v50_giant_flower.png","Mushroom":"moon_flower.png","Fern":"flower.png","Rose bush":"flower_bed.png","Crystal":"crystal.png","Boulder":"rock.png","Bench":"school_bench.png","Lamp post":"town_lamp.png","Fence":"town_fence.svg","Gate":"barricade.png","Bridge":"river_bridge.png","Well":"studio_well_v148.svg","Fountain":"garden_fountain.png","Statue":"star_obelisk.png","Sign":"studio_sign_v148.svg","Crate":"studio_crate_v148.svg","Barrel":"studio_barrel_v148.svg","Cart":"studio_cart_v148.svg","Tent":"studio_tent_v148.svg","Cottage":"house.png","Workshop":"supply_shop.png","Tower":"school_clocktower.png","Archway":"studio_archway_v148.svg","Ruins":"rock.png","Cauldron":"garden_fountain.png","Bookshelf":"studio_bookshelf_v148.svg","Training target":"training_dummy.svg"}
const TERRAIN={"Grass":"grass.png","Path":"path.png","Water":"river_water.png","Stone":"brass_path.png","Wall":"rock.png","Sand":"school_sand.png","Ice":"ice.png","Lava":"ash.png"}
static var art_cache:Dictionary={}
const OBJECTS=["Oak tree","Pine tree","Willow","Palm","Flower bed","Sunflower","Mushroom","Fern","Rose bush","Crystal","Boulder","Bench","Lamp post","Fence","Gate","Bridge","Well","Fountain","Statue","Sign","Crate","Barrel","Cart","Tent","Cottage","Workshop","Tower","Archway","Ruins","Cauldron","Bookshelf","Training target"]
static func object(name:String="New object")->Dictionary:
 var dimensions=Vector2(64,80)
 if name in ["Oak tree","Pine tree","Willow","Palm"]:dimensions=Vector2(100,132)
 if name in ["Cottage","Workshop","Tower"]:dimensions=Vector2(144,160)
 if name in ["Bench","Fence","Bridge"]:dimensions=Vector2(88,64)
 return {"format":"fx-crossroads-object","version":1,"id":"prop-"+str(Time.get_ticks_usec()),"name":name,"category":"Decoration","image":art(name),"width":int(dimensions.x),"height":int(dimensions.y),"block_move":name in ["Oak tree","Pine tree","Willow","Palm","Boulder","Cottage","Workshop","Tower"],"block_shots":name in ["Boulder","Cottage","Workshop","Tower"],"source":"Crossroads starter art • record your changes / credits","layers":[],"operations":[],"settings":{"mode":"RGBA8 / RGB","pixel_aspect":1,"output":"PNG for web / mobile"}}
static func art(name:String)->String:
 if name=="Training target":return Marshalls.raw_to_base64(preload("res://scripts/studio_art249.gd").prop("training_dummy").get_image().save_png_to_buffer())
 if art_cache.has(name):return art_cache[name]
 var path="res://assets/"+str(ASSETS.get(name,""))
 if ASSETS.has(name) and ResourceLoader.exists(path):
  var tex:Texture2D=load(path);var img=tex.get_image()
  if img.get_width()>256 or img.get_height()>256:img.resize(128,128,Image.INTERPOLATE_LANCZOS)
  var encoded=Marshalls.raw_to_base64(img.save_png_to_buffer());art_cache[name]=encoded;return encoded
 var image=Image.create(32,40,false,Image.FORMAT_RGBA8);image.fill(Color.TRANSPARENT)
 var wood=Color("#9f7750");var leaf=Color("#72a474");var stone=Color("#718897");var gold=Color("#edd399")
 var seed_value=absi(name.hash());var colour=Color.from_hsv(float(seed_value%360)/360,.35,.8)
 if "tree" in name or name in ["Pine tree","Willow","Palm"]:
  image.fill_rect(Rect2i(14,18,5,20),wood)
  for y in range(3,27):
   for x in range(2,30):
    if Vector2(x-16,y-15).length()<12:image.set_pixel(x,y,leaf.lightened(.12 if (x+y)%6==0 else 0))
 elif name in ["Flower bed","Sunflower","Mushroom","Fern","Rose bush"]:
  image.fill_rect(Rect2i(2,34,28,4),wood)
  for x in [6,16,26]:image.fill_rect(Rect2i(x,20,2,15),leaf);image.fill_rect(Rect2i(x-3,15,8,7),colour);image.set_pixel(x,18,gold)
 elif name in ["Oak tree","Pine tree"]:pass
 elif name in ["Cottage","Workshop","Tower","Archway","Ruins","Tent","Bookshelf"]:
  image.fill_rect(Rect2i(4,12,24,26),stone);image.fill_rect(Rect2i(2,8,28,5),colour);image.fill_rect(Rect2i(13,25,7,13),wood)
  for x in [7,21]:image.fill_rect(Rect2i(x,17,4,6),gold)
 elif name in ["Bench","Fence","Bridge","Gate","Sign"]:
  image.fill_rect(Rect2i(2,19,28,5),wood);image.fill_rect(Rect2i(5,24,3,14),wood);image.fill_rect(Rect2i(25,24,3,14),wood)
  if name=="Bench":image.fill_rect(Rect2i(2,12,28,4),gold)
 else:
  image.fill_rect(Rect2i(9,15,14,22),stone);image.fill_rect(Rect2i(6,12,20,5),colour);image.fill_rect(Rect2i(10,20,12,8),gold)
  if name in ["Crystal","Fountain","Cauldron"]:image.fill_rect(Rect2i(13,3,7,10),Color("#99dbea"))
 return Marshalls.raw_to_base64(image.save_png_to_buffer())
static func tiles()->Array:
 var result=[]
 for row in [["Grass","#70906a",false,false],["Path","#bfa778",false,false],["Water","#5d9cab",true,false],["Stone","#778b94",false,false],["Wall","#445b69",true,true],["Sand","#dac79a",false,false],["Ice","#b4dbe2",false,false],["Lava","#ba6046",true,false]]:
  result.append({"name":row[0],"color":row[1],"block_move":row[2],"block_shots":row[3],"image":"","speed":.65 if row[0]=="Sand" else 1.0,"damage":8.0 if row[0]=="Lava" else 0.0})
 return result
static func realm(w:int=80,h:int=60)->Dictionary:
 return {"format":"fx-crossroads-realm","version":1,"id":"realm-"+str(Time.get_ticks_usec()),"name":"My realm","vision":"","width":w,"height":h,"tiles":tiles(),"grid":Array(range(w*h)).map(func(_n):return 0),"objects":{},"enemies":{},"placements":[],"spawn":[1,1],"exit":[w-2,h-2],"tests":[],"environment":{"weather":"Clear","lighting":"Day","intensity":0.5}}
static func validate_object(v:Variant)->String:
 if not v is Dictionary or v.get("format")!="fx-crossroads-object" or v.get("version")!=1:return "Choose an Object Lab project."
 if not v.has_all(["id","name","category","source","image","width","height","block_move","block_shots","layers","operations","settings"]):return "Missing object fields."
 if JSON.stringify(v).to_utf8_buffer().size()>P.MAX_BYTES:return "Object exceeds 2 MB."
 for field in ["id","name","category","source"]:
  if not P.short_text(v.get(field),200):return "Invalid object "+field
 if v.name.strip_edges().is_empty():return "Name your object."
 for field in ["width","height"]:
  if not P.number(v.get(field),16,160):return "Object dimensions must be 16–160."
 for field in ["block_move","block_shots"]:
  if not v.get(field) is bool:return "Choose object collision settings."
 if not png(v.get("image")):return "Object artwork must be a valid PNG."
 if not v.get("layers",[]) is Array or v.get("layers",[]).size()>4:return "Four image layers maximum."
 for layer in v.get("layers",[]):
  if not layer is Dictionary or not P.short_text(layer.get("name"),60) or not png(layer.get("image")) or not layer.get("visible") is bool:return "Invalid image layer."
  if layer.has("mask") and not png(layer.mask):return "Invalid layer mask PNG."
 if v.has("brush") and not png(v.brush):return "Invalid custom brush PNG."
 if not v.get("operations",[]) is Array or v.get("operations",[]).size()>100:return "Invalid image process history."
 for op in v.get("operations",[]):
  if not P.short_text(op,100):return "Invalid image operation."
 if not v.get("settings",{}) is Dictionary or JSON.stringify(v.get("settings",{})).length()>1000:return "Invalid image settings."
 return ""
static func png(v:Variant)->bool:
 if not P.short_text(v,180000):return false
 var bytes=Marshalls.base64_to_raw(v)
 if not P.png_error(bytes).is_empty():return false
 var img=Image.new();return img.load_png_from_buffer(bytes)==OK
static func cell(v:Variant,w:int,h:int)->bool:
 return v is Array and v.size()==2 and P.number(v[0],0,w-1) and P.number(v[1],0,h-1) and float(v[0])==floorf(v[0]) and float(v[1])==floorf(v[1])
static func validate_realm(v:Variant)->String:
 if not v is Dictionary or v.get("format")!="fx-crossroads-realm" or v.get("version")!=1:return "Choose a Realm Builder project."
 if not v.has_all(["id","name","vision","width","height","tiles","grid","objects","enemies","placements","spawn","exit","tests"]):return "Missing realm fields."
 if JSON.stringify(v).to_utf8_buffer().size()>P.MAX_BYTES:return "Realm exceeds 2 MB; use smaller embedded artwork."
 for field in ["id","name","vision"]:
  if not P.short_text(v.get(field),1500):return "Invalid realm text."
 for field in ["width","height"]:
  if not P.number(v.get(field),8,MAX_SIDE) or float(v[field])!=floorf(v[field]):return "Choose 8–256 tiles per side."
 if v.has("clear_required") and not v.clear_required is bool:return "Invalid completion rule."
 var env=v.get("environment",{})
 if not env is Dictionary or not env.get("weather","Clear") in ["Clear","Rain","Snow","Fireflies","Ash"] or not env.get("lighting","Day") in ["Day","Dusk","Night","Moonlight"] or not P.number(env.get("intensity",.5),0,1):return "Invalid environment settings."
 var w=int(v.width);var h=int(v.height)
 if not v.get("tiles") is Array or v.tiles.is_empty() or v.tiles.size()>16:return "Use 1–16 terrain types."
 for t in v.tiles:
  if not t is Dictionary or not P.short_text(t.get("name"),60) or not P.short_text(t.get("color"),9) or not Color.html_is_valid(t.color) or not t.get("block_move") is bool or not t.get("block_shots") is bool:return "Invalid terrain."
  if not str(t.get("image","")).is_empty() and not png(t.image):return "Invalid tile artwork."
  if not P.number(t.get("speed",1.0),.2,1.5) or not P.number(t.get("damage",0),0,20):return "Terrain speed must be 0.2–1.5; damage 0–20 HP/s."
 if not v.get("grid") is Array or v.grid.size()!=w*h:return "Terrain grid does not match the map dimensions."
 for n in v.grid:
  if not P.number(n,0,v.tiles.size()-1) or float(n)!=floorf(n):return "Unknown terrain tile."
 for field in ["spawn","exit"]:
  if not cell(v.get(field),w,h):return "Place a valid "+field+" tile."
 if not v.get("objects") is Dictionary or v.objects.size()>32 or not v.get("enemies") is Dictionary or v.enemies.size()>12:return "Use up to 32 object types and 12 enemy types."
 for prop in v.objects.values():
  var error=validate_object(prop)
  if not error.is_empty():return error
 for enemy in v.enemies.values():
  var error=preload("res://scripts/studio_enemy_project.gd").validate(enemy)
  if not error.is_empty():return error
 if not v.get("placements") is Array or v.placements.size()>MAX_PLACEMENTS:return "Keep up to 1,000 placed objects/enemies."
 var enemies=0
 for at in v.placements:
  if not at is Dictionary or not cell(at.get("cell"),w,h) or not at.get("kind") in ["object","enemy"] or not (v.objects if at.kind=="object" else v.enemies).has(at.get("id")):return "Invalid placement."
  if at.kind=="enemy":enemies+=1
 if enemies>MAX_ENEMIES:return "Use at most 64 enemies per realm."
 if not v.get("tests",[]) is Array or v.get("tests",[]).size()>10:return "Keep up to ten realm test summaries."
 for test in v.get("tests",[]):
  if not test is Dictionary or JSON.stringify(test).length()>2000:return "Invalid realm test summary."
 return ""
static func validate(kind:String,v:Variant)->String:return validate_realm(v) if kind=="realm" else validate_object(v)
static func collision_index(v:Dictionary)->Dictionary:
 var index={}
 for placed in v.placements:
  if placed.kind!="object":continue
  var prop=v.objects[placed.id];var center=Vector2(placed.cell[0]*40+20,placed.cell[1]*40+20);var r=Rect2(center-Vector2(float(prop.width)*.4,12),Vector2(float(prop.width)*.8,24))
  for y in range(int(floorf(r.position.y/40)),int(floorf(r.end.y/40))+1):
   for x in range(int(floorf(r.position.x/40)),int(floorf(r.end.x/40))+1):
    var key=Vector2i(x,y)
    if not index.has(key):index[key]=[]
    index[key].append({"rect":r,"block_move":prop.block_move,"block_shots":prop.block_shots})
 index["built"]=true;return index
static func blocked(v:Dictionary,at:Vector2,shots:bool=false,index:Dictionary={})->bool:
 var c=Vector2i(floorf(at.x/40),floorf(at.y/40))
 if c.x<0 or c.y<0 or c.x>=int(v.width) or c.y>=int(v.height):return true
 var field="block_shots" if shots else "block_move"
 if v.tiles[int(v.grid[c.y*int(v.width)+c.x])][field]:return true
 if index.has("built"):
  for prop in index.get(c,[]):
   if prop[field] and prop.rect.has_point(at):return true
  return false
 for placed in v.placements:
  if placed.kind!="object":continue
  var prop=v.objects[placed.id];var center=Vector2(placed.cell[0]*40+20,placed.cell[1]*40+20)
  if prop[field] and Rect2(center-Vector2(float(prop.width)*.4,12),Vector2(float(prop.width)*.8,24)).has_point(at):return true
 return false
static func checks(v:Dictionary)->Array:
 var issue=validate_realm(v)
 if not issue.is_empty():return [issue]
 var problems=[];var index=collision_index(v)
 var start=Vector2(v.spawn[0]*40+20,v.spawn[1]*40+20);var end=Vector2(v.exit[0]*40+20,v.exit[1]*40+20)
 if blocked(v,start,false,index):problems.append("Spawn is blocked; move it or erase the obstruction.")
 if blocked(v,end,false,index):problems.append("Exit is blocked; move it or erase the obstruction.")
 var pending=[Vector2i(v.spawn[0],v.spawn[1])];var visited={pending[0]:true};var finish=Vector2i(v.exit[0],v.exit[1])
 while not pending.is_empty():
  var point:Vector2i=pending.pop_back()
  for step in [Vector2i.LEFT,Vector2i.RIGHT,Vector2i.UP,Vector2i.DOWN]:
   var next:Vector2i=point+step
   if not visited.has(next) and not blocked(v,Vector2(next)*40+Vector2(20,20),false,index):visited[next]=true;pending.append(next)
 if not visited.has(finish):problems.append("No walkable route from spawn to exit.")
 for at in v.placements:
  if at.kind=="enemy" and blocked(v,Vector2(at.cell[0]*40+20,at.cell[1]*40+20),false,index):problems.append("An enemy is placed on a blocked cell.");break
 return problems
static func example(index:int)->Dictionary:
 var v=realm(80,60);v.spawn=[4,30];v.exit=[75,30];v.name=["Forest crossing","Crystal courtyard","Lantern garden","Clockwork lane","Island bridges"][index%5]
 for y in range(int(v.height)):
  for x in range(int(v.width)):
   if x in [0,int(v.width)-1] or y in [0,int(v.height)-1]:v.grid[y*int(v.width)+x]=4
   elif index==4 and x>43 and x<50:v.grid[y*int(v.width)+x]=2
 for x in range(1,79):
  var route=30+int(round(sin((x-4)*.13)*4))
  for y in range(route-1,route+2):v.grid[y*int(v.width)+x]=1
 # Courtyard, loop and connected side trails give examples a purposeful layout.
 for y in range(10,50):
  for x in range(39,42):v.grid[y*int(v.width)+x]=1
 for y in range(24,35):
  for x in range(35,46):
   if Vector2(x-40,y-29).length()<6:v.grid[y*int(v.width)+x]=3 if index==1 else 1
 v.spawn=[4,30];v.exit=[75,30+int(round(sin(71*.13)*4))]
 v.environment={"weather":["Fireflies","Snow","Fireflies","Ash","Rain"][index%5],"lighting":["Day","Moonlight","Dusk","Day","Day"][index%5],"intensity":.4}
 for n in 60:
  var names=["Oak tree","Crystal","Willow","Tower","Palm"]
  var prop=object(names[index%5] if n%3 else "Flower bed");prop.id="example-prop-"+str(n%3);v.objects[prop.id]=prop
  var x=5+(n%15)*5;var route=30+int(round(sin((x-4)*.13)*4));var y=route+(5+(n/30)*7)*(1 if (n/15)%2 else -1)
  if abs(x-40)<4 or (index==4 and x>43 and x<50):continue
  v.placements.append({"kind":"object","id":prop.id,"cell":[x,y]})
 var e=preload("res://scripts/studio_enemy_project.gd").fresh();e.id="example-bramble";e.name="Bramble";e.health=85;e.speed=100;e.attack_count=1;e.primary.style="melee";e.primary.name="Bramble strike";e.primary.range=65;e.primary.damage=11;e.primary.heal=0
 e.art=preload("res://scripts/studio_art249.gd").encoded("bramble_practice")
 v.enemies[e.id]=e;v.placements.append({"kind":"enemy","id":e.id,"cell":[18,34]})
 return v
static func download_png(owner:Node,encoded:String,filename:String)->void:
 if not png(encoded):return
 if OS.has_feature("web"):
  JavaScriptBridge.eval("(()=>{const s=atob("+JSON.stringify(encoded)+");const b=new Uint8Array(s.length);for(let i=0;i<s.length;i++)b[i]=s.charCodeAt(i);const u=URL.createObjectURL(new Blob([b],{type:'image/png'}));const a=document.createElement('a');a.href=u;a.download="+JSON.stringify(filename)+";a.click();setTimeout(()=>URL.revokeObjectURL(u),1000);})()",true)
 else:
  var d=FileDialog.new();d.access=FileDialog.ACCESS_FILESYSTEM;d.file_mode=FileDialog.FILE_MODE_SAVE_FILE;d.add_filter("*.png","PNG image");d.current_file=filename;owner.add_child(d)
  d.file_selected.connect(func(path:String):var f=FileAccess.open(path,FileAccess.WRITE);if f!=null:f.store_buffer(Marshalls.base64_to_raw(encoded));d.queue_free())
  d.canceled.connect(d.queue_free);d.popup_centered(Vector2i(800,500))

extends RefCounted
const SIZE=Vector2(1280,960)
const WELL=Vector2(400,500)
const MERCHANT=Vector2(860,500)
const EXIT=Vector2(1050,220)
const TORCHES=[Vector2(160,190),Vector2(640,160),Vector2(1120,600),Vector2(160,770)]
var d_ref:WeakRef
var d:RefCounted:
 get:return d_ref.get_ref() if d_ref!=null else null
 set(value):d_ref=weakref(value) if value!=null else null
var active=false
var used=false
var exit_requested=false
var ready:Dictionary={}
var healing:Dictionary={}
var balance:Label
static var mask:Texture2D
func reset()->void:active=false;used=false;exit_requested=false;ready.clear();healing.clear()
func snapshot()->Dictionary:return {"active":active,"used":used,"exit_requested":exit_requested,"ready":ready.duplicate()}
func receive(v:Dictionary)->void:active=bool(v.get("active",false));used=bool(v.get("used",false));exit_requested=bool(v.get("exit_requested",false));ready=v.get("ready",{}).duplicate()
func setup_geometry()->void:
 var g=d.game;g.FIELD=Rect2(Vector2.ZERO,SIZE);g.field_obstacles.clear();g.world_buildings.clear();g.world_patches.clear();g.world_decorations.clear();g.world_fountains.clear();g.world_spawns.clear()
 g.field_obstacles.append({"pos":WELL,"radius":32.0,"kind":"rock"});g.field_obstacles.append({"pos":MERCHANT-Vector2(0,22),"radius":34.0,"kind":"rock"});g.world_buildings.append({"name":"Supplies","pos":MERCHANT,"sprite":"supply_shop"})
func enter()->void:
 active=true;used=true;exit_requested=false;ready.clear();healing.clear()
 d.game.status_label.text="DEPTH 50.5 • Abandoned mine refuge • Well +10 HP/s • Merchant • Ready at the lower shaft"
func near_merchant(id:String)->bool:
 var g=d.game
 return active and not d.falling() and int(g.health.get(id,0))>0 and g.positions.has(id) and (g.positions[id]as Vector2).distance_to(MERCHANT)<150
func interact(id:String)->bool:
 var g=d.game
 if not active or d.falling() or not g.positions.has(id) or int(g.health.get(id,0))<=0:return false
 if near_merchant(id):
  if id==g.my_id and g.get("dedicated")!=true:open_shop()
  return true
 if (g.positions[id]as Vector2).distance_to(EXIT)>100:return false
 if d.clock<float(d.interact_at.get(id,0)):return false
 d.interact_at[id]=d.clock+.5;ready[id]=not bool(ready.get(id,false));try_leave();return true
func try_leave()->void:
 if not active or d.falling():return
 var g=d.game;var living=0
 for id in g.positions:
  if int(g.health.get(id,0))<=0:continue
  living+=1
  if not bool(ready.get(id,false)) or (g.positions[id]as Vector2).distance_to(EXIT)>100:return
 if living>0:exit_requested=true;d.begin_fall()
func step(dt:float)->void:
 var g=d.game
 for id in g.positions:
  if int(g.health.get(id,0))<=0 or (g.positions[id]as Vector2).distance_to(EXIT)>100:ready.erase(id)
  if int(g.health.get(id,0))<=0 or (g.positions[id]as Vector2).distance_to(WELL)>140:healing.erase(id);continue
  healing[id]=float(healing.get(id,0))+dt*10
  var points=floori(float(healing[id])+0.000001)
  if points>0:g.health[id]=mini(g._max_hp(str(id)),int(g.health[id])+points);healing[id]=maxf(0,float(healing[id])-points)
 try_leave()
func open_shop(notice:String="")->void:
 var g=d.game
 if not near_merchant(g.my_id):return
 g.presentation.window("MINE-SHAFT MERCHANT • DEPTH 50.5","descent_rest_shop")
 balance=g.presentation.label(g.presentation.content,"CC: "+str(g.gold.get(g.my_id,0))+" • 3 equipment + 1 consumable",19)
 if not notice.is_empty():g.presentation.label(g.presentation.content,notice,16)
 var grid=GridContainer.new();grid.columns=2;g.presentation.content.add_child(grid)
 for id in g.items:
  var item:Dictionary=g.items[id]
  if not bool(item.get("shop",true)) or bool(item.get("bg_only",false)):continue
  var price=int(item.get("cost",0))
  if bool(g.shop_discounts.get(g.my_id,false))and price>=10:price-=1
  var b=g.presentation.button(grid,str(item.get("name",id))+" • "+str(price)+" CC",buy.bind(str(id)));b.custom_minimum_size=Vector2(320,48);b.icon=preload("res://scripts/item_icons.gd").texture(str(id));b.expand_icon=true;b.add_theme_constant_override("icon_max_width",38);b.tooltip_text=str(item.get("description",""));b.disabled=int(g.gold.get(g.my_id,0))<price or not preload("res://scripts/supply_slots.gd").can_add(g.inventory.get(g.my_id,[]),str(id),g.items)
 g.presentation.button(g.presentation.content,"Refresh stock / balance",open_shop);g.presentation.button(g.presentation.content,"Return to refuge",g.presentation.close)
func buy(item:String)->void:
 var g=d.game
 if not near_merchant(g.my_id):g.presentation.close();return
 if g.role=="host":g._purchase(g.my_id,item);open_shop(g.status_label.text)
 else:g._send_channel(g.host_id,{"type":"purchase","id":item});open_shop("Order sent • refresh balance after confirmation")
static func light()->Texture2D:
 if mask==null:
  var im=Image.new();im.load_png_from_buffer(FileAccess.get_file_as_bytes("res://assets/rest263/light.png"));mask=ImageTexture.create_from_image(im)
 return mask
func draw_ground(c:Node2D,cam:Vector2)->void:
 preload("res://scripts/descent_map251.gd").draw_floor(c,cam,d.game.VIEW,20)
 preload("res://scripts/descent_map251.gd").scenery(c,cam,Rect2(Vector2.ZERO,SIZE),d.game.VIEW,20)
 var wood=preload("res://scripts/marina_art250.gd").texture("dock_wood")
 for x in [100,1180]:c.draw_texture_rect(wood,Rect2(Vector2(x-16,105)-cam,Vector2(32,745)),false)
 for y in [120,835]:c.draw_texture_rect(wood,Rect2(Vector2(85,y)-cam,Vector2(1110,30)),false)
 c.draw_arc(WELL-cam,140,0,TAU,48,Color(.55,.81,.75,.30),1)
 preload("res://scripts/town_art246.gd").draw(c,"well",Rect2(WELL-Vector2(40,90)-cam,Vector2(80,120)))
 c.draw_texture_rect(preload("res://scripts/merchant_art259.gd").texture(),Rect2(MERCHANT-Vector2(64,80)-cam,Vector2(128,107)),false)
 c.draw_rect(Rect2(EXIT-Vector2(65,65)-cam,Vector2(130,135)),Color("#18242a"))
 for x in [-48,48]:c.draw_texture_rect(wood,Rect2(EXIT+Vector2(x-5,-60)-cam,Vector2(10,130)),false)
 for y in range(-48,70,18):c.draw_texture_rect(wood,Rect2(EXIT+Vector2(-46,y)-cam,Vector2(92,9)),false)
 for t in TORCHES:
  c.draw_circle(t-cam,38,Color(1,.61,.25,.08));preload("res://scripts/arena_art261.gd").draw(c,"torch",Rect2(t-Vector2(22,42)-cam,Vector2(44,60)))
func draw_light(c:Node2D,cam:Vector2)->void:
 c.draw_texture_rect(light(),Rect2(-cam,SIZE),false)
func draw_hud(c:Node2D,cam:Vector2)->void:
 var font=ThemeDB.fallback_font
 c.draw_set_transform(d.game.media.offset(),0,Vector2.ONE*d.game.media.factor())
 for pair in [[WELL+Vector2(-125,75),"HEALING WELL • +10 HP/s",250],[MERCHANT+Vector2(-130,62),"E • MINE-SHAFT MERCHANT",260],[EXIT+Vector2(-150,105),"E • READY FOR FLOOR 51",300]]:
  var p:Vector2=pair[0]-cam;c.draw_style_box(preload("res://scripts/studio_ui.gd").box("#19333b","#8f8d70",5,4),Rect2(p-Vector2(4,18),Vector2(pair[2]+8,27)));c.draw_string(font,p,str(pair[1]),HORIZONTAL_ALIGNMENT_CENTER,int(pair[2]),14,Color("#f1ddb0"))
 c.draw_set_transform(Vector2.ZERO)
 var count=0;var living=0
 for id in d.game.positions:
  if int(d.game.health.get(id,0))>0:living+=1;count+=int(bool(ready.get(id,false)))
 c.draw_string(font,Vector2(25,112),"SAFE REFUGE • No enemies • Rest, trade, then ready at the ladder (%d/%d)"%[count,living],HORIZONTAL_ALIGNMENT_LEFT,-1,16,Color("#ecd5a0"))
 if is_instance_valid(balance):balance.text="CC: "+str(d.game.gold.get(d.game.my_id,0))+" • 3 equipment + 1 consumable"

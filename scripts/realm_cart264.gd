extends RefCounted
## One existing service point per realm; no decorative second merchant.
static func supports(g:Node)->bool:return g.mode=="coop" and g.realm_id in preload("res://scripts/realm_art265.gd").IDS and not g.adventure.between_guardians()
static func anchor(realm:String)->Vector2:return preload("res://scripts/realm_art265.gd").ANCHORS.get(realm,Vector2.ZERO)
static func near(g:Node,id:String)->bool:return supports(g) and int(g.health.get(id,0))>0 and g.positions.has(id) and (g.positions[id]as Vector2).distance_to(anchor(g.realm_id))<220
static func open(g:Node,notice:String="")->void:
 if not near(g,g.my_id):return
 g.presentation.window("TRAVELLING MERCHANT","realm_cart264")
 g.presentation.label(g.presentation.content,"CC: "+str(g.gold.get(g.my_id,0))+" • 3 equipment + 1 consumable",19)
 if not notice.is_empty():g.presentation.label(g.presentation.content,notice,16)
 var grid=GridContainer.new();grid.columns=2;g.presentation.content.add_child(grid)
 for id in g.items:
  var item:Dictionary=g.items[id]
  if not bool(item.get("shop",true)) or bool(item.get("bg_only",false)):continue
  var price=int(item.get("cost",0))
  if bool(g.shop_discounts.get(g.my_id,false)) and price>=10:price-=1
  var b=g.presentation.button(grid,str(item.get("name",id))+" • "+str(price)+" CC",buy.bind(g,str(id)));b.custom_minimum_size=Vector2(320,48);b.icon=preload("res://scripts/item_icons.gd").texture(str(id));b.expand_icon=true;b.add_theme_constant_override("icon_max_width",38);b.disabled=int(g.gold.get(g.my_id,0))<price or not preload("res://scripts/supply_slots.gd").can_add(g.inventory.get(g.my_id,[]),str(id),g.items)
 g.presentation.button(g.presentation.content,"Refresh balance",open.bind(g,""));g.presentation.button(g.presentation.content,"Return to realm",g.presentation.close)
static func buy(g:Node,item:String)->void:
 if not near(g,g.my_id):g.presentation.close();return
 if g.role=="host":g._purchase(g.my_id,item);open(g,g.status_label.text)
 else:g._send_channel(g.host_id,{"type":"purchase","id":item});open(g,"Order sent • refresh after confirmation")

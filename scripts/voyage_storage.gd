extends RefCounted
const C=preload("res://scripts/fishing_catalog.gd")
const UI=preload("res://scripts/studio_ui.gd")
static func build(v:Node,col:Node)->void:
 var f=v.game.fishing;var r=v.records();var space=maxi(0,r.storage_capacity()-r.storage_count());var needed=maxi(0,v.cargo.size()-space)
 f.label(col,"YOUR BOAT CARGO IS SEPARATE • %d catches aboard" % v.cargo.size(),21)
 f.label(col,"Storage %d/%d • Bag %d/%d • Free %d more storage slots to unload all cargo." % [r.storage_count(),r.storage_capacity(),r.bag_count(),r.capacity(),needed],17)
 f.label(col,"Only older stored catches appear below. Selling, moving or releasing them never removes your new voyage catches. No rewards are banked until you finish landing.",16)
 f.label(col,v.game.fishing.status,15)
 f.button(col,"Back to landing • keep all voyage cargo",func():v.open_menu("landing"))
 var land=f.button(col,"Finish landing • keep all %d catches" % v.cargo.size(),v.bank);land.disabled=needed>0
 if int(r.state().storage_upgrades)<8:
  var cost=250*(int(r.state().storage_upgrades)+1)
  var upgrade=f.button(col,"Upgrade storage +10 • %d Glimmers (wallet %d)" % [cost,v.game.legacy.glimmers.balance()],func():
   v.game.fishing.status="Storage expanded." if r.upgrade_storage() else "Not enough Glimmers for this upgrade."
   v.open_menu("storage"))
  upgrade.disabled=v.game.legacy.glimmers.balance()<cost
 var list:Array=r.state().kept.filter(func(c):return r.stored(c.id))
 if list.is_empty():f.label(col,"No older fish are stored here.",17)
 for catch in list:
  var id=str(catch.id);var spec:Dictionary=C.fish()[catch.species]
  var card=UI.card(col,str(spec.name)+" • "+str(spec.rarity),"%.2f kg • %s • %d Glimmers" % [float(catch.kg),"TROPHY" if C.is_trophy(catch) else "Normal size",v.game.legacy.glimmers.fish_price(catch)])
  f.picture(card,str(catch.species),Vector2(100,64),catch)
  var tanks=[]
  for n in 5:
   if r.state().display[n]==id:tanks.append(str(n+1))
  if not tanks.is_empty():f.label(card,"ON DISPLAY • Tank "+", ".join(tanks),16)
  if r.state().favorite==id:f.label(card,"FAVOURITE • player card",16)
  f.button(card,"Sell this stored fish…",func():v.stored_action(id,true))
  var move=f.button(card,"Move to fish bag",func():
   v.game.fishing.status="Moved to your bag." if r.transfer(id,false) else "Your bag is full."
   v.open_menu("storage"))
  move.disabled=r.bag_count()>=r.capacity()
  f.button(card,"Release this stored fish…",func():v.stored_action(id,false))

extends RefCounted
const UI=preload("res://scripts/studio_ui.gd")
static func build(body:Node,f:Node,reply:Callable)->void:
 var wallet=f.game.legacy.glimmers
 f.label(body,"GLIMMER EXCHANGE • %d Glimmers" % wallet.balance(),22)
 f.label(body,"Permanent town money. Sell kept catches and gathered/grown ingredients here. CC remains your adventure currency. The Market also awards 10 Glimmers for a profitable trading day, once per real day.",16)
 if f.game.mode!="town":f.label(body,"Return to town to sell goods.",18);return
 f.label(body,"KEPT CATCHES • selling removes the specimen from tanks and favourites; your discovery, records and XP stay.",16)
 for catch in f.records().state().kept:
  var id=str(catch.id);var price=wallet.fish_price(catch)
  var box=UI.card(body,str(f.C.fish()[catch.species].name),"%.2f kg • %s • %d Glimmers" % [catch.kg,f.C.fish()[catch.species].rarity,price])
  f.picture(box,str(catch.species),Vector2(110,56))
  f.button(box,"Sell for %d Glimmers…" % price,func():
   var d=ConfirmationDialog.new();d.title="Sell this catch?";d.dialog_text="Remove this specimen from your collection and displays for %d Glimmers? Your journal and XP stay." % price;body.add_child(d)
   d.confirmed.connect(func():reply.call(wallet.sell_fish(id));d.queue_free());d.canceled.connect(d.queue_free);d.popup_centered(Vector2i(440,200)))
 f.label(body,"GATHERED & GROWN INGREDIENTS • save some for fish bait and apothecary recipes.",18)
 var stock=f.game.legacy.lodge_economy.state().ingredients
 for id in wallet.ING:
  var count=int(stock.get(id,0));var box=UI.card(body,str(wallet.ING[id].name),"Owned: %d • %d Glimmers each" % [count,wallet.ingredient_price(id)])
  var row=HBoxContainer.new();box.add_child(row)
  var b=f.button(row,"Sell 1",func():reply.call(wallet.sell_ingredient(id,1)));b.disabled=count<1
  b=f.button(row,"Sell 5",func():reply.call(wallet.sell_ingredient(id,5)));b.disabled=count<5

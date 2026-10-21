extends CanvasLayer
const UI=preload("res://scripts/studio_ui.gd")
const CARDS=preload("res://scripts/fish_collection_ui.gd")
var fishing:Node
var panel:PanelContainer
var scroll:ScrollContainer
var goods=false
var filters:HBoxContainer
var list:VBoxContainer
var notice:Label
func setup(f:Node)->void:
 fishing=f;layer=93;f.game.menu="fishing_sales";build()
func build()->void:
 var shade=ColorRect.new();shade.color=Color(.02,.05,.07,.94);shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);add_child(shade)
 panel=PanelContainer.new();UI.apply(panel);add_child(panel)
 var col=VBoxContainer.new();col.add_theme_constant_override("separation",8);panel.add_child(col)
 var top=HBoxContainer.new();col.add_child(top);CARDS.text(top,"RIPPLE & REEL • SALES",24);CARDS.action(top,"Back to shop",close,130)
 notice=CARDS.text(col,"Sell kept fish for Glimmers. Journal records stay. Compare size before choosing.",15)
 var tabs=HBoxContainer.new();col.add_child(tabs);CARDS.action(tabs,"Fish sales",func():goods=false;refresh(),150);CARDS.action(tabs,"Gathered goods",func():goods=true;refresh(),150)
 CARDS.kept_filters(fishing,col,refresh);filters=col.get_child(col.get_child_count()-1)
 scroll=ScrollContainer.new();scroll.size_flags_vertical=Control.SIZE_EXPAND_FILL;scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;col.add_child(scroll)
 list=VBoxContainer.new();list.size_flags_horizontal=Control.SIZE_EXPAND_FILL;list.add_theme_constant_override("separation",10);scroll.add_child(list);preload("res://scripts/touch_list_scroll.gd").attach(scroll)
 refresh()
func refresh()->void:
 if not is_instance_valid(list):return
 filters.visible=not goods
 if goods:
  for child in list.get_children():list.remove_child(child);child.queue_free()
  var wallet=fishing.game.legacy.glimmers;var stock=fishing.game.legacy.lodge_economy.state().ingredients
  for id in wallet.ING:
   var row=CARDS.framed(list,Color("#87bca5"));CARDS.text(row,str(wallet.ING[id].name)+" • "+str(int(stock.get(id,0)))+" owned • "+str(wallet.ingredient_price(id))+" Glimmers each",16)
   for amount in [1,5]:CARDS.action(row,"Sell "+str(amount),func():notice.text=wallet.sell_ingredient(id,amount);refresh(),85).disabled=int(stock.get(id,0))<amount
 else:
  CARDS.fill_kept(fishing,list,true)
  focus_selected.call_deferred()
 notice.text="%d Glimmers • %d kept fish • Trophy and Very rare+ catches ask before sale." % [fishing.game.legacy.glimmers.balance(),fishing.records().state().kept.size()]
func focus_selected()->void:
 await get_tree().process_frame
 if not is_instance_valid(list) or fishing.sales_focus_id.is_empty():return
 for child in list.get_children():
  if str(child.get_meta("catch_id",""))==fishing.sales_focus_id:scroll.ensure_control_visible(child);break
 fishing.sales_focus_id=""
func sell(id:String)->void:
 var catch=fishing.records().specimen(id)
 if catch.is_empty():refresh();return
 var rarity=str(fishing.C.fish()[catch.species].rarity)
 if fishing.C.is_trophy(catch) or rarity in ["Very rare","Legendary","Mystical"]:
  var dialog=ConfirmationDialog.new();dialog.title="Sell this special catch?";dialog.dialog_text="%s • %s • %.2f kg%s\nSell for %d Glimmers? This removes the specimen from your bag, tanks and favourite. Journal records remain." % [fishing.C.fish()[catch.species].name,rarity,float(catch.kg)," • TROPHY" if fishing.C.is_trophy(catch) else "",fishing.game.legacy.glimmers.fish_price(catch)];add_child(dialog)
  dialog.confirmed.connect(func():complete_sale(id);dialog.queue_free());dialog.canceled.connect(dialog.queue_free);dialog.popup_centered(Vector2i(540,230))
 else:complete_sale(id)
func complete_sale(id:String)->void:
 var message=fishing.game.legacy.glimmers.sell_fish(id);refresh();notice.text=message
func close()->void:
 if is_instance_valid(fishing.inspector):fishing.inspector.close()
 fishing.sales=null;fishing.game.menu="fishing_shop";queue_free()
func _process(_delta:float)->void:fishing.fit_panel(panel,Vector2(1000,650))
func _unhandled_input(event:InputEvent)->void:
 if event is InputEventKey and event.pressed and not event.echo and event.keycode==KEY_ESCAPE:close();get_viewport().set_input_as_handled()

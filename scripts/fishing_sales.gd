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
var selection:Dictionary={}
var batch_row:HBoxContainer
var summary:Label
var sell_button:Button
func setup(f:Node)->void:
 fishing=f;layer=93;f.game.menu="fishing_sales";build()
func build()->void:
 var shade=ColorRect.new();shade.color=Color(.02,.05,.07,.94);shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);add_child(shade)
 panel=PanelContainer.new();UI.apply(panel);add_child(panel);var col=VBoxContainer.new();col.add_theme_constant_override("separation",8);panel.add_child(col)
 var top=HBoxContainer.new();col.add_child(top);CARDS.text(top,"RIPPLE & REEL • SELL CATCHES",22);CARDS.action(top,"Back",close,75)
 notice=CARDS.text(col,"Tick fish, review the total, then sell together. Your journal and XP stay.",14)
 var tabs=HBoxContainer.new();col.add_child(tabs);CARDS.action(tabs,"Fish sales",func():goods=false;refresh(),140);CARDS.action(tabs,"Gathered goods",func():goods=true;refresh(),140)
 CARDS.kept_filters(fishing,col,refresh);filters=col.get_child(col.get_child_count()-1)
 batch_row=HBoxContainer.new();batch_row.add_theme_constant_override("separation",6);col.add_child(batch_row)
 CARDS.action(batch_row,"Select matches",func():choose(false),110);CARDS.action(batch_row,"Ordinary only",func():choose(true),110);CARDS.action(batch_row,"Clear",func():selection.clear();refresh(),65)
 sell_button=CARDS.action(batch_row,"Sell selected…",confirm_batch,140)
 summary=CARDS.text(col,"",14,Color("#f0d38c"))
 scroll=ScrollContainer.new();scroll.size_flags_vertical=Control.SIZE_EXPAND_FILL;scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;col.add_child(scroll)
 list=VBoxContainer.new();list.size_flags_horizontal=Control.SIZE_EXPAND_FILL;list.add_theme_constant_override("separation",5);scroll.add_child(list);preload("res://scripts/touch_list_scroll.gd").attach(scroll);refresh()
func protected_catch(c:Dictionary)->bool:
 var s=fishing.records().state();return fishing.C.is_trophy(c) or str(fishing.C.fish()[c.species].rarity) in ["Very rare","Legendary","Mystical","Fabled"] or str(c.id)==str(s.favorite) or c.id in s.display
func choose(ordinary:bool)->void:
 if ordinary:selection.clear()
 for c in CARDS.selected_catches(fishing):
  if not ordinary or not protected_catch(c):selection[str(c.id)]=true
 refresh()
func quote()->Dictionary:
 var ids=[];var base=0;var special=0
 for c in fishing.records().state().kept:
  if not selection.has(str(c.id)):continue
  ids.append(str(c.id));base+=fishing.game.legacy.glimmers.fish_price(c)
  if protected_catch(c):special+=1
 return {"ids":ids,"base":base,"special":special,"paid":int(fishing.game.legacy.glimmers.award_quote(base).total)}
func update_summary()->void:
 var q=quote();summary.text="%d selected • %d Glimmers%s • %d kept fish" % [q.ids.size(),q.paid," • %d protected" % q.special if q.special>0 else "",fishing.records().state().kept.size()];sell_button.disabled=q.ids.is_empty()
func refresh()->void:
 if not is_instance_valid(list):return
 for id in selection.keys():
  if fishing.records().specimen(str(id)).is_empty():selection.erase(id)
 filters.visible=not goods;batch_row.visible=not goods;summary.visible=not goods
 for child in list.get_children():list.remove_child(child);child.queue_free()
 if goods:
  var wallet=fishing.game.legacy.glimmers;var stock=fishing.game.legacy.lodge_economy.state().ingredients
  for id in wallet.ING:
   var row=CARDS.framed(list,Color("#87bca5"));CARDS.text(row,str(wallet.ING[id].name)+" • "+str(int(stock.get(id,0)))+" owned • "+str(wallet.ingredient_price(id))+" Glimmers each",15)
   for amount in [1,5]:CARDS.action(row,"Sell "+str(amount),func():var message=wallet.sell_ingredient(id,amount);refresh();notice.text=message,75).disabled=int(stock.get(id,0))<amount
 else:
  var catches=CARDS.selected_catches(fishing)
  if catches.is_empty():CARDS.text(list,"No kept fish match. Return with catches, or clear the search.",16)
  for c in catches:fish_row(c)
  update_summary();focus_selected.call_deferred()
 notice.text="%d Glimmers • Selections stay selected when sorting or filtering. Confirm before any batch sale." % fishing.game.legacy.glimmers.balance()
func fish_row(c:Dictionary)->void:
 var spec=fishing.C.fish()[c.species];var id=str(c.id);var special=protected_catch(c)
 var row=CARDS.framed(list,Color("#d7b875") if special else Color("#527f87"));row.get_parent().set_meta("catch_id",id)
 var tick=CheckBox.new();tick.button_pressed=selection.has(id);tick.custom_minimum_size.x=30;tick.tooltip_text="Select "+str(spec.name);row.add_child(tick);tick.toggled.connect(func(on):
  if on:selection[id]=true
  else:selection.erase(id)
  update_summary())
 fishing.picture(row,str(c.species),Vector2(76,47))
 var info=VBoxContainer.new();info.size_flags_horizontal=Control.SIZE_EXPAND_FILL;row.add_child(info);CARDS.text(info,str(spec.name),16);CARDS.text(info,"%s • %.2f kg • %s%s" % [spec.rarity,float(c.kg),str(c.date)," • Protected" if special else ""],13)
 var actions=VBoxContainer.new();row.add_child(actions);CARDS.text(actions,"%d Glimmers" % fishing.game.legacy.glimmers.fish_price(c),16,Color("#ffe0a0"));var buttons=HBoxContainer.new();actions.add_child(buttons)
 CARDS.action(buttons,"Details",fishing.show_catch_details.bind(id),70);CARDS.action(buttons,"Sell…" if special else "Sell",func():sell(id),65)
func focus_selected()->void:
 await get_tree().process_frame
 if not is_instance_valid(list) or fishing.sales_focus_id.is_empty():return
 for child in list.get_children():
  if str(child.get_meta("catch_id",""))==fishing.sales_focus_id:scroll.ensure_control_visible(child);break
 fishing.sales_focus_id=""
func confirm_batch()->void:
 var q=quote()
 if q.ids.is_empty():return
 var dialog=ConfirmationDialog.new();dialog.title="Review batch sale";dialog.dialog_text="Sell %d selected fish for %d Glimmers?%s\n\nSold fish leave your bag, displays and favourite. Species records and fishing XP remain. Hidden selections are included." % [q.ids.size(),q.paid,"\nWARNING: %d trophy, rare, displayed or favourite catches are selected." % q.special if q.special>0 else ""];add_child(dialog)
 dialog.confirmed.connect(func():var message=fishing.game.legacy.glimmers.sell_fish_batch(q.ids,int(q.base));refresh();notice.text=message;dialog.queue_free());dialog.canceled.connect(dialog.queue_free);dialog.popup_centered(Vector2i(540,250))
func sell(id:String)->void:
 var c=fishing.records().specimen(id)
 if c.is_empty():refresh();return
 if protected_catch(c):
  var dialog=ConfirmationDialog.new();dialog.title="Sell protected catch?";dialog.dialog_text="Sell %s for %d Glimmers? It will leave your bag, tank and favourite. Journal records remain." % [fishing.C.fish()[c.species].name,fishing.game.legacy.glimmers.fish_price(c)];add_child(dialog);dialog.confirmed.connect(func():complete_sale(id);dialog.queue_free());dialog.canceled.connect(dialog.queue_free);dialog.popup_centered(Vector2i(500,200))
 else:complete_sale(id)
func complete_sale(id:String)->void:
 var message=fishing.game.legacy.glimmers.sell_fish(id);refresh();notice.text=message
func close()->void:
 if is_instance_valid(fishing.inspector):fishing.inspector.close()
 fishing.sales=null;fishing.game.menu="fishing_shop";queue_free()
func _process(_delta:float)->void:
 var view=fishing.game.get_viewport_rect().size;panel.scale=Vector2.ONE;panel.size=Vector2(minf(1020,view.x-24),minf(660,view.y-24));panel.position=(view-panel.size)*.5
func _unhandled_input(event:InputEvent)->void:
 if event is InputEventKey and event.pressed and not event.echo and event.keycode==KEY_ESCAPE:close();get_viewport().set_input_as_handled()

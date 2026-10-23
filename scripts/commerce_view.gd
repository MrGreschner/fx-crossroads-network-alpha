extends CanvasLayer
const UI=preload("res://scripts/studio_ui.gd")
const F=preload("res://scripts/mine_foundry.gd")
const G=preload("res://scripts/mine_geology.gd")
var market:RefCounted
var panel:PanelContainer
var body:VBoxContainer
var page:VBoxContainer
var status:Label
var wallet:Label
var tabs:HBoxContainer
var sale_button:Button
var page_index=0
var filter_index=0
var selected={}
var active=false
var old_process=true
var old_visible=true
var dialog:ConfirmationDialog
func label(parent:Node,value:String,size:int=17)->Label:
 var l=Label.new();l.text=value;l.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;l.add_theme_font_size_override("font_size",size);parent.add_child(l);return l
func button(parent:Node,value:String,action:Callable)->Button:
 var b=Button.new();b.text=value;b.custom_minimum_size.y=44;parent.add_child(b);b.pressed.connect(action);return b
func setup(owner:RefCounted)->void:
 market=owner;layer=80
 var bg=ColorRect.new();bg.color=Color("#0b1921");bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);add_child(bg)
 panel=PanelContainer.new();add_child(panel);UI.apply(panel)
 body=VBoxContainer.new();panel.add_child(body);body.add_theme_constant_override("separation",10)
 var header=HBoxContainer.new();body.add_child(header)
 var title=label(header,"DEEPWELL EXCHANGE",26);title.size_flags_horizontal=Control.SIZE_EXPAND_FILL;title.add_theme_color_override("font_color",Color("#ebcc87"))
 button(header,"My mine",func():close();market.legacy.mine.open())
 button(header,"Back to town",close)
 var art=Counter.new();art.custom_minimum_size.y=132;body.add_child(art)
 wallet=label(body,"",20);status=label(body,"",16)
 tabs=HBoxContainer.new();body.add_child(tabs)
 for i in 2:
  var b=button(tabs,["SELL FINDS","MINE SUPPLIES"][i],func():page_index=i;render());b.size_flags_horizontal=Control.SIZE_EXPAND_FILL;b.toggle_mode=true;b.custom_minimum_size.y=52
 var scroll=ScrollContainer.new();scroll.size_flags_vertical=Control.SIZE_EXPAND_FILL;scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;body.add_child(scroll);preload("res://scripts/touch_list_scroll.gd").attach(scroll).form_controls=true
 page=VBoxContainer.new();page.size_flags_horizontal=Control.SIZE_EXPAND_FILL;page.add_theme_constant_override("separation",12);scroll.add_child(page)
 var footer=HBoxContainer.new();body.add_child(footer)
 button(footer,"Collect mine depot",func():if market.legacy.mine.collect():market.note="Collected your depot. Your carried finds are ready to trade.";render()).disabled=market.readonly()
 sale_button=button(footer,"Review sale",review);sale_button.size_flags_horizontal=Control.SIZE_EXPAND_FILL;UI.accent(sale_button)
 button(footer,"Start / manage a business →",func():close();market.legacy.game.open_business_district())
 label(body,"Instant trades • Mine Gold is for mining • Glimmers and adventure CC stay separate • only selected finds are sold",14)
 hide()
func open()->void:
 old_process=market.legacy.game.is_processing();old_visible=market.legacy.game.visible;market.legacy.game.set_process(false);market.legacy.game.hide();market.legacy.game.mobile.reset_controls();market.legacy.game.menu="commerce";active=true;selected.clear();show();render();UI.enter(panel)
func close()->void:
 if not active:return
 if is_instance_valid(dialog):dialog.queue_free()
 active=false;hide();market.save();market.legacy.game.menu="";market.legacy.game.visible=old_visible;market.legacy.game.set_process(old_process);market.legacy.game.mobile.reset_controls();market.legacy.game.queue_redraw()
func _process(_delta:float)->void:
 if not active:return
 var size=get_viewport().get_visible_rect().size;panel.size=Vector2(1160,800);var fit=minf(1,minf((size.x-20)/1160,(size.y-24)/800));panel.scale=Vector2.ONE*fit;panel.position=(size-panel.size*fit)*.5
func _input(event:InputEvent)->void:
 if active and event is InputEventKey and event.pressed and event.keycode==KEY_ESCAPE:
  if is_instance_valid(dialog):dialog.queue_free()
  else:close()
  get_viewport().set_input_as_handled()
func render()->void:
 for child in page.get_children():page.remove_child(child);child.queue_free()
 for i in 2:tabs.get_child(i).set_pressed_no_signal(page_index==i)
 wallet.text="MINE GOLD  %.2f" % market.legacy.mine.state().wallet.gold
 status.text=market.note if not market.readonly() else "PLAYTEST • your mining inventory and wallet are protected."
 if bool(market.legacy.data.get("teacher",false)):status.text="GAME DEV • temporary mining preview."
 sale_button.visible=page_index==0
 if page_index==0:sell_page()
 else:supplies_page()
 update_sale()
func sell_page()->void:
 var x=market.exchange()
 if not x.notice_seen:
  var box=UI.card(page,"YOUR OLD STALL HAS CLOSED","Returned as Mine Gold: cash %.2f + stocked-goods value %.2f + upgrades %.2f − old loan %.2f = %.2f. Your original records are preserved. Business management now lives at Crossroads Market." % [x.cash,x.stock,x.upgrades,x.debt,x.credit])
  button(box,"Got it",func():x.notice_seen=true;market.save();render())
 if x.pending>0:
  var credit=UI.card(page,"RETURNED FUNDS WAITING","Your Mine Gold wallet is full. %.2f is safely waiting; collect it after spending at the mine." % x.pending)
  button(credit,"Collect returned Mine Gold",func():market.claim_credit();render()).disabled=market.readonly()
 if int(market.state().get("supply_reward",{}).get("pending",0))>0:button(page,"Collect remaining old supply reward • "+str(market.state().supply_reward.pending)+" CC",func():market.claim_supply();render()).disabled=market.readonly()
 if x.credit>0 or market.state().day>0:button(page,"Download previous stall record",download_archive)
 var tools=HBoxContainer.new();page.add_child(tools)
 var pick=OptionButton.new();pick.custom_minimum_size=Vector2(230,44);tools.add_child(pick)
 for name in ["All carried finds","Ore & coal","Gems & specimens","Forged bars"]:pick.add_item(name)
 pick.select(filter_index);pick.item_selected.connect(func(i:int):filter_index=i;render())
 button(tools,"Select loose ore & fragments",func():
  selected.clear()
  for id in ["ore","gems"]:
   var n=mini(1000000000,int(floor(market.amount(id))))
   if n>0:selected[id]=n
  filter_index=0;render())
 button(tools,"Clear selection",func():selected.clear();render())
 label(page,"Choose quantities, then review one combined sale. Bars and coal help build the mine—keep what you need.",16)
 var grid=GridContainer.new();grid.columns=2;grid.add_theme_constant_override("h_separation",12);grid.add_theme_constant_override("v_separation",12);page.add_child(grid)
 var shown=0
 for d in market.goods():
  if market.amount(d.id)<1 or (filter_index>0 and d.kind!=["","ore","gem","bar"][filter_index]):continue
  shown+=1;goods_card(grid,d)
 if shown==0:label(page,"No whole finds in this category yet. Collect your depot, or visit the mine to start digging.",19)
func goods_card(parent:Node,d:Dictionary)->void:
 var box=UI.card(parent,"","");box.custom_minimum_size.x=530;box.size_flags_horizontal=Control.SIZE_EXPAND_FILL
 var row=HBoxContainer.new();box.add_child(row)
 var art=TextureRect.new();art.custom_minimum_size=Vector2(54,54);art.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;art.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;row.add_child(art)
 if d.id.begins_with("bar:") or d.id.begins_with("metal:"):art.texture=F.icon(market.key_for(d.id),d.kind=="bar")
 elif d.id.begins_with("deposit:"):art.texture=G.icon(market.key_for(d.id))
 else:art.texture=G.icon("diamond" if d.id=="gems" else "coal")
 var text=VBoxContainer.new();text.size_flags_horizontal=Control.SIZE_EXPAND_FILL;row.add_child(text)
 label(text,d.name,21);label(text,"%.2f carried • %.2f Mine Gold each" % [market.amount(d.id),d.price],16)
 label(box,d.hint,14)
 var choice=HBoxContainer.new();box.add_child(choice)
 var check=CheckBox.new();check.text="Sell";check.disabled=market.readonly();choice.add_child(check)
 var n=SpinBox.new();n.min_value=1;n.max_value=mini(1000000000,int(floor(market.amount(d.id))));n.step=1;n.value=mini(int(selected.get(d.id,1)),int(n.max_value));n.custom_minimum_size=Vector2(155,40);n.editable=not market.readonly();choice.add_child(n)
 check.set_pressed_no_signal(selected.has(d.id));check.toggled.connect(func(on:bool):if on:selected[d.id]=int(n.value);update_sale()
 else:selected.erase(d.id);update_sale())
 n.value_changed.connect(func(v:float):if check.button_pressed:selected[d.id]=int(v);update_sale())
 button(choice,"All",func():n.value=n.max_value;check.set_pressed_no_signal(true);selected[d.id]=int(n.value);update_sale()).disabled=market.readonly()
func update_sale()->void:
 var offer=market.quote(selected);sale_button.text="Review sale • %.2f Mine Gold" % offer.total if not offer.is_empty() else "Select finds to sell";sale_button.disabled=market.readonly() or offer.is_empty()
func review()->void:
 var offer=market.quote(selected)
 if offer.is_empty():return
 var lines=[]
 for row in offer.rows:lines.append("%d × %s  →  %.2f Mine Gold" % [row.count,row.name,row.value])
 confirm("Sell selected finds?","\n".join(lines)+"\n\nTotal: %.2f Mine Gold\nUnselected finds stay in your inventory." % offer.total,func():market.sell(selected.duplicate(),offer);selected.clear();render())
func confirm(title:String,message:String,action:Callable)->void:
 if is_instance_valid(dialog):return
 dialog=ConfirmationDialog.new();dialog.title=title;dialog.dialog_text=message;dialog.ok_button_text="Confirm";dialog.cancel_button_text="Keep / go back";add_child(dialog)
 dialog.confirmed.connect(func():dialog.queue_free();action.call());dialog.canceled.connect(func():dialog.queue_free());dialog.popup_centered(Vector2i(540,310))
func supplies_page()->void:
 var mine=market.legacy.mine
 if not mine.state().commissioned:
  var box=UI.card(page,"START YOUR MINE","Your first shaft and crew cost 80 Mine Gold. The mine keeps producing while you explore.")
  button(box,"Open first shaft • 80 Mine Gold",func():mine.commission();render()).disabled=market.readonly() or mine.state().wallet.gold<80
  return
 if not mine.state().job.is_empty():label(page,"Construction underway. Visit My mine to see progress or change the job.",18)
 label(page,"Useful upgrades at the same prices as My mine. Costs include any bars required for construction.",16)
 var grid=GridContainer.new();grid.columns=2;grid.add_theme_constant_override("h_separation",12);grid.add_theme_constant_override("v_separation",12);page.add_child(grid)
 for id in ["tools","depot","vent","lift"]:
  var spec=mine.CATALOG.data().services[id];var cost=mine.upgrade_cost(id);var material=mine.material_cost(id)
  var box=UI.card(grid,str(spec.name)+" • level "+str(int(mine.state().levels[id])),str(spec.description) if spec.has("description") else {"tools":"Help each miner dig faster.","depot":"Store more production before your next collection.","vent":"Give your crews more fresh air.","lift":"Carry more finds up to the depot."}[id]);box.custom_minimum_size.x=530;box.size_flags_horizontal=Control.SIZE_EXPAND_FILL
  var parts=[]
  for k in ["gold","ore","gems"]:
   if float(cost.get(k,0))>0:parts.append("%.0f %s" % [cost[k],{"gold":"Mine Gold","ore":"ore","gems":"gem fragments"}[k]])
  for metal in material:parts.append(str(material[metal])+" "+F.METALS[metal].name+" bars")
  var caption=" • ".join(parts)
  label(box,caption,16)
  var full=int(mine.state().levels[id])>=int(mine.CATALOG.data().max_upgrade)
  var ready=not market.readonly() and not full and mine.state().job.is_empty() and mine.depth()>=int(spec.depth) and mine.afford(cost) and F.affordable(mine,material)
  var b=button(box,"Upgrade" if not full else "Fully upgraded",func():confirm("Upgrade "+str(spec.name)+"?",caption,func():market.buy_supply(id,cost);render()));b.disabled=not ready
  if not ready and not full:label(box,"Finish construction or collect the required materials first." if mine.depth()>=int(spec.depth) else "Unlock at shaft "+str(spec.depth),14)
 button(page,"More mining upgrades & the foundry →",func():close();mine.open())
func download_archive()->void:
 var content=market.report()
 if OS.has_feature("web"):
  JavaScriptBridge.download_buffer(content.to_utf8_buffer(),"crossroads-previous-stall.json","application/json")
 else:
  var file=FileDialog.new();file.access=FileDialog.ACCESS_FILESYSTEM;file.file_mode=FileDialog.FILE_MODE_SAVE_FILE;file.current_file="crossroads-previous-stall.json";file.use_native_dialog=true;add_child(file)
  file.file_selected.connect(func(path:String):
   var output=FileAccess.open(path,FileAccess.WRITE)
   if output!=null:output.store_string(content);output.close()
   file.queue_free())
  file.canceled.connect(func():file.queue_free());file.popup_centered(Vector2i(800,600))
class Counter extends Control:
 var elapsed=0.0
 var clock=0.0
 func _ready():mouse_filter=Control.MOUSE_FILTER_IGNORE
 func _process(delta:float):
  if not is_visible_in_tree():return
  elapsed+=delta;clock+=delta
  if elapsed>=.1:elapsed=0;queue_redraw()
 func _draw():
  var w=size.x;draw_style_box(UI.box("#263c40","#997d54"),Rect2(Vector2.ZERO,size))
  for n in 8:draw_rect(Rect2(16+n*(w-32)/8,12,(w-32)/8-3,69),Color("#31484b"))
  draw_rect(Rect2(16,89,w-32,25),Color("#8d6a48"));draw_rect(Rect2(12,82,w-24,10),Color("#c49b69"))
  var merchant=preload("res://assets/ram_idle.png");draw_texture_rect(merchant,Rect2(w*.48,27+sin(clock*1.5)*1.3,48,60),false)
  for n in 5:draw_texture_rect(F.icon(["copper","iron","cobalt","mithril","starsteel"][n],true),Rect2(35+n*52,43,42,42),false)
  draw_texture_rect(G.icon("ruby"),Rect2(360,42,39,39),false);draw_texture_rect(G.icon("diamond"),Rect2(415,40,43,43),false)
  draw_string(UI.FONT,Vector2(w*.57,46),"YOUR FINDS. FAIR PRICES.",HORIZONTAL_ALIGNMENT_LEFT,-1,20,Color("#f1d89e"))
  draw_string(UI.FONT,Vector2(w*.57,70),"Sell • collect • head back underground",HORIZONTAL_ALIGNMENT_LEFT,-1,15,Color("#b3d4cc"))

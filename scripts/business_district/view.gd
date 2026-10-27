extends CanvasLayer
const C=preload("res://scripts/business_district/catalog.gd")
const A=preload("res://scripts/business_district/art.gd")
const Sim=preload("res://scripts/business_district/simulation.gd")
var supplier_choice=0
var browse_category="Recommended"
var browse_query=""
var browse_page=0
const PAGE_SIZE=10
var classroom=false
var academy:Node
var game:Node
var sim=Sim.new()
var root:Control
var world=Node2D.new()
var floor_layer=Node2D.new()
var buildings=Node2D.new()
var actors=Node2D.new()
var lighting=Node2D.new()
var top:VBoxContainer
var status:Label
var title:Label
var day_clock:Label
var toast:Label
var panel:PanelContainer
var panel_body:VBoxContainer
var panel_title:Label
var panel_kind=""
var zoom=1.0
var centre=Vector2(350,410)
var accumulator=0.0
var save_clock=0.0
var ui_clock=0.0
var drag=false
var dragged=false
var last_mouse=Vector2.ZERO
var hidden_layers:Array=[]
var previous_mode=Node.PROCESS_MODE_INHERIT
var previous_process=true
var previous_visible=true
var frame_us=0
var peak_frame_us=0
var ready_ui=false
var state:Dictionary
func setup(g:Node,options:Dictionary={})->void:
 game=g;classroom=bool(options.get("classroom",false));academy=options.get("academy")
 state=options.get("state",C.fresh()).duplicate(true) if classroom else game.legacy.data.get("district",C.fresh()).duplicate(true)
 state=C.upgrade(state)
 if not C.valid(state):state=C.upgrade(C.fresh())
 sim.ownership_limit=0 if classroom else 5
 sim.public_catalog=not classroom
 sim.pending_resets=options.get("pending_resets",[])
 sim.setup(state)
 sim.restricted=classroom and is_instance_valid(academy) and not academy.attempt.is_empty()
 sim.access=options.get("access",["kitchen"])
 previous_process=game.is_processing();previous_visible=game.visible
 previous_mode=game.process_mode;process_mode=Node.PROCESS_MODE_ALWAYS;game.process_mode=Node.PROCESS_MODE_DISABLED
 for child in get_tree().root.find_children("*","CanvasLayer",true,false):
  if child!=self:hidden_layers.append({"node":child,"visible":child.visible});child.hide()
 game.set_process(false);game.hide()
 layer=100
 root=Control.new();root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);add_child(root)
 var bg=ColorRect.new();bg.color=Color("#1c3338");bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);bg.mouse_filter=Control.MOUSE_FILTER_IGNORE;root.add_child(bg)
 root.add_child(world);world.add_child(floor_layer);world.add_child(buildings);world.add_child(actors);world.add_child(lighting)
 var light_material=CanvasItemMaterial.new();light_material.blend_mode=CanvasItemMaterial.BLEND_MODE_ADD;lighting.material=light_material
 lighting.draw.connect(func():
  if state.night:A.night_lights(lighting))
 floor_layer.draw.connect(func():A.ground(floor_layer,state.night))
 buildings.draw.connect(func():
  for v in C.visible_ventures(state):
   A.premises(buildings,v,state.businesses.get(v.id,{}),state.selected==v.id,state.night)
   if not sim.allowed(v.id):buildings.draw_rect(Rect2(C.plot(v.id)+Vector2(-16,-86),Vector2(610,580)),Color("#163139",.62));A.ink(buildings,C.plot(v.id)+Vector2(120,268),"NOT AVAILABLE HERE",20,Color("#e0d9c5"))
   if state.businesses.has(v.id):preload("res://scripts/business_district/venue_art.gd").floor_plan(buildings,C.plot(v.id),state.businesses[v.id],state.night))
 actors.draw.connect(draw_actors)
 var hud=PanelContainer.new();hud.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE);hud.offset_left=14;hud.offset_right=-14;hud.offset_top=12
 root.add_child(hud);style(hud)
 top=VBoxContainer.new();hud.add_child(top)
 var row=HBoxContainer.new();top.add_child(row)
 title=label(row,"CROSSROADS • MARKET QUARTER",22);title.size_flags_horizontal=Control.SIZE_EXPAND_FILL
 button(row,"Back to module" if classroom else "Town",leave)
 if classroom:button(row,"Capture for assignment",func():
  if is_instance_valid(academy):academy.capture_image())
 else:button(row,"Learning Academy",func():game.open_business_academy())
 button(row,"?",func():show_panel("help"))
 button(row,"Reserve • transfer",func():show_panel("reserve"))
 day_clock=label(top,"",21);day_clock.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;day_clock.size_flags_horizontal=Control.SIZE_EXPAND_FILL;day_clock.add_theme_color_override("font_color",Color("#ffe0a1"))
 status=label(top,"",16);status.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;status.size_flags_horizontal=Control.SIZE_EXPAND_FILL;title.clip_text=true
 var bottom=PanelContainer.new();bottom.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE);bottom.offset_left=14;bottom.offset_right=-14;bottom.offset_top=-94;bottom.offset_bottom=-12;root.add_child(bottom);style(bottom)
 var column=VBoxContainer.new();bottom.add_child(column)
 var sc=ScrollContainer.new();sc.custom_minimum_size.y=43;sc.vertical_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;column.add_child(sc)
 var actions=HBoxContainer.new();sc.add_child(actions)
 button(actions,"Open / Close",toggle_open)
 for entry in [["Products","products"],["Materials","supplies"],["People","people"],["Equipment","fitout"],["Name & restart","manage"],["Strategy","strategy"],["Ledger","ledger"],["Sales & trends","trends"],["District map","map"]]:
  var key:String=entry[1];button(actions,entry[0],func():show_panel(key))
 button(actions,"Prepare one • 2",func():act(func():return sim.stock_help(state.selected)))
 toast=label(column,"",15);toast.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
 panel=PanelContainer.new();root.add_child(panel);style(panel);panel.hide()
 var col=VBoxContainer.new();panel.add_child(col)
 var pr=HBoxContainer.new();col.add_child(pr);panel_title=label(pr,"",22);panel_title.size_flags_horizontal=Control.SIZE_EXPAND_FILL;button(pr,"×",func():panel.hide();panel_kind="";update_camera())
 var scroll=ScrollContainer.new();scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;scroll.size_flags_vertical=Control.SIZE_EXPAND_FILL;col.add_child(scroll)
 panel_body=VBoxContainer.new();panel_body.size_flags_horizontal=Control.SIZE_EXPAND_FILL;scroll.add_child(panel_body)
 root.resized.connect(resize_ui);top.minimum_size_changed.connect(func():call_deferred("resize_ui"));resize_ui();ready_ui=true;select(state.selected);refresh()
 if not state.get("welcome45",false):state.welcome45=true;save_state();show_panel("welcome")
 toast.text="Inspect a premises, choose products, match equipment and order the actual materials. Then open."
func style(p:PanelContainer)->void:
 var skin=StyleBoxFlat.new();skin.bg_color=Color("#203a40",.97);skin.border_color=Color("#a3b39a");skin.set_border_width_all(1);skin.set_corner_radius_all(9);skin.content_margin_left=14;skin.content_margin_right=14;skin.content_margin_top=10;skin.content_margin_bottom=10;p.add_theme_stylebox_override("panel",skin)
func label(parent:Node,text:String,size:int=17)->Label:
 var l=Label.new();l.text=text;l.add_theme_font_override("font",A.FONT);l.add_theme_font_size_override("font_size",size);l.add_theme_color_override("font_color",Color("#f1e8d3"));parent.add_child(l);return l
func paragraph(text:String)->void:
 var l=label(panel_body,text);l.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;l.custom_minimum_size.x=280
func button(parent:Node,text:String,callback:Callable)->Button:
 var b=Button.new();b.text=text;b.custom_minimum_size.y=36;b.add_theme_font_override("font",A.FONT);b.add_theme_font_size_override("font_size",16);b.pressed.connect(callback);parent.add_child(b);return b
func resize_ui()->void:
 if not is_instance_valid(root):return
 var size=root.size
 var top_edge=maxf(152,top.get_parent().position.y+top.get_parent().size.y+10)
 panel.position=Vector2(maxf(14,size.x-minf(620,size.x-28)-14),top_edge);panel.size=Vector2(minf(620,size.x-28),maxf(140,size.y-top_edge-107))
 update_camera()
func update_camera()->void:
 if not is_instance_valid(root):return
 world.modulate=Color("#a7b6d2") if state.night else Color.WHITE
 var available=root.size.x-panel.size.x-28 if is_instance_valid(panel) and panel.visible and root.size.x>1050 else root.size.x
 world.scale=Vector2.ONE*zoom;world.position=Vector2(available*.5,root.size.y*.5+12)-centre*zoom;actors.queue_redraw()
func select(id:String)->void:
 browse_page=0;browse_category="Recommended";browse_query=""
 state.selected=id;sim.rebuild_workers();centre=C.plot(id)+Vector2(286,188);zoom=clampf((root.size.y-235)/570.0,.5,1.2);update_camera();buildings.queue_redraw();refresh()
 if not state.businesses.has(id):show_panel("premises")
 elif panel.visible:show_panel(panel_kind)
func act(f:Callable,redraw:bool=true)->void:
 var success=f.call()
 toast.text=sim.last_notice if not sim.last_notice.is_empty() else "Saved your change." if success else "That action is unavailable. Check cash, stock, staffing and whether you are open."
 save_state()
 if redraw:buildings.queue_redraw()
 refresh()
 if panel.visible and panel_kind!="customer":show_panel(panel_kind)
func toggle_open()->void:
 if not state.businesses.has(state.selected):show_panel("premises");return
 var b=sim.business(state.selected)
 if b.open:act(func():return sim.close(state.selected))
 else:act(func():return sim.start(state.selected))
func refresh()->void:
 if not is_instance_valid(status):return
 var b=sim.business(state.selected);var v=C.spec(state.selected)
 var passed=float(b.get("elapsed",0));var current_day=int(b.get("day",0))+1
 day_clock.text="WORKDAY %d • %s • %d full days completed • district completed openings: %d" % [current_day,("%02d:%02d remaining" % [int(maxf(0,Sim.PERIOD-passed))/60,int(maxf(0,Sim.PERIOD-passed))%60]) if b.get("open",false) else "CLOSED • ready to open",int(b.get("summary",{}).get("full_days",0)),state.periods]
 title.text=("CLASSROOM • " if classroom else "")+str(b.get("name",v.name)).to_upper()+" • Reserve %.0f" % state.reserve
 if b.is_empty():status.text="Available premises • Acquisition %.0f • Reserve %.0f" % [sim.acquisition(state.selected),state.reserve]
 else:status.text="%s • Cash %.0f • Supplies %d • Ready %d • Sold %d • Reputation %.0f%% • %s" % ["OPEN %d:%02d" % [int(maxf(0,Sim.PERIOD-b.elapsed))/60,int(maxf(0,Sim.PERIOD-b.elapsed))%60] if b.open else "CLOSED",b.cash,b.inputs,b.stock,b.served,b.reputation,["Market day","Food festival","Craft fair","Rainy market"][int(b.day)%4]]+" • %d/%d profitable full days" % [b.summary.profitable_days,b.summary.full_days]
func show_panel(kind:String)->void:
 if kind!=panel_kind:browse_page=0
 if not ready_ui and kind!="premises":return
 panel_kind=kind
 for n in panel_body.get_children():panel_body.remove_child(n);n.queue_free()
 panel.show();update_camera();var id:String=state.selected;var b=sim.business(id);var v=C.spec(id)
 panel_title.text={"premises":"Your next venture","manage":"Business name & restart","products":"Your product line","supplies":"Materials & suppliers","people":"Your people","fitout":"Fit out your premises","strategy":"Plan the next period","ledger":"Business ledger","map":"Explore the district","welcome":"Welcome • your first workday","trends":"Sales & trends","reserve":"District reserve","help":"Welcome to Market Quarter","customer":"At your business"}.get(kind,kind)
 if kind=="products" and b.get("trade","") in ["salon","daycare","minigolf"]:panel_title.text="Your services"
 if kind=="reserve":
  paragraph("DISTRICT RESERVE • %.2f\nThis starts at 0. It is shared expansion money, separate from each business cash balance." % state.reserve)
  if b.is_empty():paragraph("Select an owned business on the map to transfer its cash.");return
  paragraph("Selected business cash: %.2f. Keep working cash for wages, stock, rent and loan coverage." % b.cash)
  var amount=SpinBox.new();amount.min_value=1;amount.max_value=100000;amount.value=100;panel_body.add_child(amount)
  button(panel_body,"Transfer to district reserve",func():act(func():return sim.transfer(id,amount.value,true)))
  button(panel_body,"Fund this business from reserve",func():act(func():return sim.transfer(id,amount.value,false)))
  return
 if kind=="welcome":
  if not classroom:paragraph("Six ventures are currently available in the public town market: Hearth & Ladle, Silverfin Exchange, Lantern & Ladder, Deepwell Foundry, Copperwick Works and Bramble & Bloom. Other premises are greyed out. Classroom venture access is chosen separately by your teacher.")
  paragraph("WELCOME • Choose a business on the map. Its name is its brand; the descriptions below tell you what it does. The empty premises has no equipment: build a mixed shop one product at a time.")
  paragraph("START: choose one premises → inspect its inherited guide → pick products → buy the required equipment → order each ingredient → keep cash for costs → open. Watch customers and the Ledger, then change what is not working. Your first business gets startup support. Extra businesses cost reserve savings; public play allows five.")
  paragraph("Your reserve starts at 0. Use Reserve • transfer at the top to save business cash for expansion. Recommended products are only a starting guide. Browse categories to change or mix your goods. Trend labels change every three trading days; they are estimates, not guaranteed sales.")
  button(panel_body,"Got it • explore the map",func():panel.hide();panel_kind="";update_camera())
  for place in C.ventures():paragraph(place.name+" • "+place.kind+"\n"+place.description)
  return
 if kind=="help":
  paragraph("Take over a working business, or build an empty premises from scratch. Choose a menu or product range, inspect recipes and equipment, and order each material from a supplier.")
  paragraph("An opening is three active minutes. Products need every ingredient and the correct equipment. Customers request particular products, compare prices and leave if the queue is too slow. Unused perishable stock expires; wages, rent and utilities continue while trading.")
  paragraph("The first premises includes starting capital: 1,200 for an existing business with inherited equipment and starter stock, or 2,200 for an empty shell with nothing installed. Subsequent premises must be bought from saved profits at their displayed acquisition price, then supplied with working capital.")
  paragraph("Close before changing menus, jobs, prices or equipment. Use the ledger to move cash into the expansion reserve. Three periods of arrears or cash below −200 closes a business through insolvency. You can transfer capital to recover, or start over after confirmation.")
  paragraph("Hire people after reading their resumes. Assign preparation, service or receiving duties yourself. Relevant experience affects work; training improves capacity. A new pool of 30 applicants arrives every three market days. Hired employees remain.")
  paragraph("Drag the ground to pan and scroll to zoom. Click a person to inspect their current order or work. All activity is local, active-time simulation; leaving suspends it. Classroom assignments, public game progress and submitted evidence remain separate.")
  button(panel_body,"Day / lantern evening",func():state.night=not state.night;update_camera();floor_layer.queue_redraw();buildings.queue_redraw();lighting.queue_redraw();save_state())
  if not classroom:button(panel_body,"Start district over…",confirm_restart)
  return
 if kind=="map":
  paragraph("Fourteen inherited businesses and one empty shell. Teacher permission and acquisition cash are both required for a new classroom venture.")
  for spec in C.visible_ventures(state):
   var sid:String=spec.id;button(panel_body,("🔒 " if not sim.allowed(sid) else "● " if state.businesses.has(sid) else "+ ")+spec.name+" • "+("Owned" if state.businesses.has(sid) else "%.0f" % sim.acquisition(sid)),func():panel.hide();panel_kind="";select(sid))
  button(panel_body,"View whole district",func():panel.hide();panel_kind="";centre=Vector2(1100,1670);zoom=minf(root.size.x/2350,(root.size.y-300)/3400);update_camera())
  return
 if b.is_empty():
  if v.get("archived",false):paragraph("This earlier empty premises has been retired from new acquisitions. Existing saved businesses remain available.");return
  paragraph(v.description+"\nCustomer need: "+v.need+"\nTrade-off: "+v.tradeoff)
  button(panel_body,"Record premises inspection",func():act(func():return sim.investigate(id)))
  if not sim.allowed(id):paragraph("Your teacher has not unlocked this premises." if classroom else "This premises is not available in the public town market. Its saved contents are preserved.");return
  if not classroom:paragraph("Public districts start with one supported venture. Save profits to buy more; the current limit is five owned ventures and five trading at once.")
  paragraph("First venture: inherited premises include 1,200 working cash, installed equipment and starter materials. Empty premises include 2,200 cash but no equipment or stock. Further acquisitions cost %.0f from your reserve and receive no free working capital. Reserve: %.0f." % [sim.acquisition(id),state.reserve])
  var model=OptionButton.new()
  if v.get("blank",false):
   paragraph("Build from scratch: Mixed goods lets you choose food, produce, clothing and crafted products item by item. Specialist services need their own operating model. Nothing is installed or stocked for you.")
   model.add_item("Mixed goods • build item by item");model.set_item_metadata(0,"kitchen")
   for base in C.ventures().filter(func(x):return x.id in ["salon","daycare","minigolf","rental","courier"]):model.add_item(base.kind);model.set_item_metadata(model.item_count-1,base.id)
   panel_body.add_child(model)
  else:
   paragraph("Inherited equipment")
   for eq in v.base_equipment:item_card(eq,"equipment",C.ops().equipment[eq].name,"Installed • purchase new for %.0f" % C.ops().equipment[eq].cost)
   paragraph("Current menu: "+", ".join(v.starter_products.map(func(key):return C.ops().products[key].name)))
  button(panel_body,"Take over first premises" if not state.started else "Buy premises • %.0f" % sim.acquisition(id),func():act(func():return sim.establish(id,str(model.get_item_metadata(model.selected)) if v.get("blank",false) else ""));browse_category="All" if v.get("blank",false) else "Recommended";show_panel("products"));return
 if not sim.allowed(id):
  paragraph("Restart approval is pending. This business is paused; return to your module for updates." if id in sim.pending_resets else "This venture is unavailable in this market. Its existing progress remains saved.")
  if not classroom and not b.is_empty():
   paragraph("Saved cash %.2f • recorded day %d. You may retire this venture to free an ownership slot." % [b.cash,b.day])
   button(panel_body,"Retire saved venture…",func():confirm_action("Retire saved venture?","Its normal net sale value returns to your reserve. The earlier summary is kept.",func():act(func():return sim.retire_unavailable(id))))
  return
 match kind:
  "manage":
   paragraph("SELECTED: "+b.name+" • "+v.kind)
   var name=LineEdit.new();name.text=b.name;name.placeholder_text="Your business name";panel_body.add_child(name)
   button(panel_body,"Save new name • 25",func():act(func():return sim.rebrand(id,name.text)))
   paragraph("Restart this business only. Its employees, stock, cash, equipment and operating days return to a fresh starting setup; its name and earlier audit summary remain. Other ventures and reserve savings stay as they are.")
   button(panel_body,"Request teacher approval to restart" if classroom else "Restart business • free",confirm_business_restart)
  "products":products_panel(id,b)
  "supplies":materials_panel(id,b)
  "people":people_panel(id,b)
  "fitout":equipment_panel(id,b)
  "strategy":
   paragraph(v.tip+"\nClose the shop to change the plan. Observe the effect during your next opening.")
   paragraph("Business name • rebranding and new signage cost 25. Product prices and preparation targets are set in Products.")
   var name_input=LineEdit.new();name_input.text=b.name;name_input.max_length=32;panel_body.add_child(name_input)
   button(panel_body,"Confirm rebrand • 25",func():act(func():return sim.rebrand(id,name_input.text)))
   paragraph("Promotion budget %.0f • charged once at opening" % b.ad)
   for money in [0.0,10.0,25.0]:
    var budget:float=money;button(panel_body,"Choose %.0f campaign" % budget,func():act(func():return sim.advertise(id,budget)))
   paragraph("Layout: "+["Compact","Open aisle • faster service","Display led"][int(b.layout)])
   button(panel_body,"Try next floor layout",func():act(func():return sim.rearrange(id)))
   paragraph("Distribution route: "+["Direct collection","Local retailer","Wholesaler network"][int(b.route)]+". Wider routes take longer to deliver; courier capacity increases with route investment.")
   button(panel_body,"Change distribution route",func():act(func():
    if not sim.can_manage(id,true):return false
    b.route=(int(b.route)+1)%3;sim.log_action(id,"Route",str(b.route));return true))
   paragraph("Decision journal • record what you expect and why")
   var note=TextEdit.new();note.custom_minimum_size=Vector2(280,95);note.text=b.note;note.placeholder_text="I will change… because… I expect…";panel_body.add_child(note)
   button(panel_body,"Save reasoning",func():act(func():
    if not sim.can_manage(id,true):return false
    b.note=note.text.left(1000);sim.log_action(id,"Reasoning",b.note);return true))
  "trends":
   paragraph("ACTUAL SALES • named products and completed-day results. Forecast demand is separate below. A full workday is 3 active minutes; early closures are marked partial in Ledger.")
   sales_charts(b)
  "ledger":
   if not b.services.is_empty():paragraph("Work in progress: %d appointments • material cost %.2f" % [b.services.size(),sim.work_in_progress(b)])
   paragraph("Cash %.2f • Inventory at cost %.2f • Loan due %.2f\nDistrict reserve %.0f (separate from each venture)." % [b.cash,b.input_book+b.stock_book,b.loan,state.reserve])
   paragraph("Expansion reserve: save profits here to buy another premises. Loan funds must remain covered before transferring cash out.")
   var transfer=SpinBox.new();transfer.min_value=1;transfer.max_value=100000;transfer.value=100;transfer.step=10;panel_body.add_child(transfer)
   button(panel_body,"Move cash to reserve",func():act(func():return sim.transfer(id,transfer.value,true)))
   button(panel_body,"Move reserve into business",func():act(func():return sim.transfer(id,transfer.value,false)))
   if b.failed:button(panel_body,"Resume after recapitalising",func():act(func():return sim.recapitalise(id)))
   button(panel_body,"Sell this venture…",func():confirm_action("Sell this venture?","Its cash, used assets and half the inventory value, less its loan, return %.2f to the reserve. Its summary is retained; this is not sales revenue." % sim.divestment_quote(id),func():act(func():return sim.divest(id))))
   if not classroom:button(panel_body,"Start district over…",confirm_restart)
   paragraph("Successful trading days: %d profitable / %d full days • current streak %d • best %d\nCumulative operating result %.2f • spoiled stock at cost %.2f\nIdle equipment-unit days: %d" % [b.summary.profitable_days,b.summary.full_days,b.summary.streak,b.summary.best_streak,b.summary.profit,b.summary.spoilage_cost,b.summary.idle_equipment_days])
   paragraph("A full day is a completed three-minute opening. Closing early still records cash, costs and results, but does not count as a successful full day. An idle unit-day means one installed item had no work during a full day.")
   paragraph("Operating results • most recent first")
   var chart=Control.new();chart.custom_minimum_size=Vector2(280,105);panel_body.add_child(chart)
   chart.draw.connect(func():
    var recent=b.history.slice(maxi(0,b.history.size()-8));var width=chart.size.x;chart.draw_line(Vector2(0,53),Vector2(width,53),Color("#90a69b"),1)
    var maximum=1.0
    for h in recent:maximum=maxf(maximum,absf(h.profit))
    for i in recent.size():
     var height=absf(recent[i].profit)/maximum*40;chart.draw_rect(Rect2(Vector2(8+i*width/8,53-height if recent[i].profit>=0 else 53),Vector2(width/8-6,height)),Color("#9bc89b") if recent[i].profit>=0 else Color("#e5a083")))
   if b.history.is_empty():paragraph("Your first completed period will appear here. Profit and cash are different: unsold stock and investments explain part of that difference.")
   for h in reverse_copy(b.history):
    paragraph("Period %d • %d sold • %d left\nSales %.2f − stock cost %.2f − operating costs %.2f\nOperating profit %.2f • cash %.2f\nAverage queue %.1fs • spoiled %d" % [h.day,h.sold,h.lost,h.revenue,h.cogs,h.expenses,h.profit,h.cash,h.wait,h.spoilage])
    if h.has("utilisation"):paragraph("Visitors %d • spoiled stock cost %.2f • idle equipment %d\nEquipment use: %s" % [h.visitors,h.spoilage_cost,h.idle_units,", ".join(h.utilisation.keys().map(func(eq):return C.ops().equipment[eq].name+" %.0f%%" % h.utilisation[eq]))])
   button(panel_body,"Repay 100 loan" if b.loan>0 else "Borrow 90 • repay 100",func():act(func():return sim.finance(id)))
   button(panel_body,"Download business report",download_report)
   paragraph("Transactions • most recent first")
   for entry in reverse_copy(b.ledger.slice(maxi(0,b.ledger.size()-15))):paragraph("%s • %+.2f • balance %.2f\n%s" % [entry.kind,entry.amount,entry.balance,entry.detail])
   if not classroom and preload("res://scripts/education_access.gd").student():
    paragraph("For the MAM1010 practical-evidence check, complete two trading periods in one venture and save your reasoning in Strategy. Your teacher still assesses the quality of the analysis.")
    button(panel_body,"Attach district evidence to MAM1010",attach_evidence)
func item_card(key:String,kind:String,name:String,detail:String)->VBoxContainer:
 var card=PanelContainer.new();style(card);panel_body.add_child(card);var row=HBoxContainer.new();row.add_theme_constant_override("separation",14);card.add_child(row)
 var art=TextureRect.new();art.tooltip_text=name;art.mouse_filter=Control.MOUSE_FILTER_PASS;art.texture=A.item_texture(key,kind);art.custom_minimum_size=Vector2(78,78);art.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;art.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;row.add_child(art)
 var col=VBoxContainer.new();col.size_flags_horizontal=Control.SIZE_EXPAND_FILL;row.add_child(col);var heading=label(col,name,19);heading.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;var text=label(col,detail,15);text.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;return col
func products_panel(id:String,b:Dictionary)->void:
 paragraph("Empty premises: no inherited menu or equipment. Choose individual goods from All or a category, then buy their required machines and ingredients. You may mix goods categories." if C.spec(id).get("blank",false) else "Starter guide: "+C.spec(b.trade).get("tip",C.spec(id).tip)+" Recommended shows the inherited menu; browse categories to change it.")
 if b.trade in ["salon","daycare","minigolf"]:paragraph("These are services, not goods to take away. Reception admits a customer only when capacity and time remain; payment is recorded when service finishes. Prepare a small buffer of supply kits to shorten waits. Early closure cancels unfinished work and writes off its materials.")
 if not b.trade in ["salon","daycare","minigolf"]:paragraph("Recipes show the ingredients and machines you need. Base cost excludes supplier fees, wages and waste. Keep a small ready-stock buffer to limit spoilage. Goods shops can mix categories.")
 for p in browser_items(C.menu(b.trade),b):
  var key:String=p.id;var enabled=b.menu.has(key) and b.menu[key].enabled;var ingredients=[];var machines=[]
  for m in p.materials:ingredients.append("%d × %s" % [p.materials[m],C.ops().materials[m].name])
  for eq in p.equipment:machines.append(("✓ " if b.assets.has(eq) else "Missing: ")+C.ops().equipment[eq].name)
  var col=item_card(key,"product",p.name,("ON YOUR MENU" if enabled else "Not offered")+" • ready %d • missed requests %d\n%s\nEquipment: %s\nBase recipe %.2f • %.0fs at 1× preparation • %s\n%s" % [sim.quantity(b.finished,key),int(b.get("missed",{}).get(key,0)),", ".join(ingredients),", ".join(machines),C.unit_cost(key),p.prep,("appointment • capacity limited" if p.get("service_duration",0)>0 else "durable stock") if p.life==0 else "%d market-day shelf life" % p.life,sim.ready_recipe(id,key)+"\n"+sim.trend_text(id,key)])
  var recipe=HFlowContainer.new();recipe.add_theme_constant_override("h_separation",5);col.add_child(recipe)
  for m in p.materials:
   var ingredient=VBoxContainer.new();recipe.add_child(ingredient);var icon=TextureRect.new();icon.texture=A.item_texture(m,"material");icon.tooltip_text=C.ops().materials[m].name;icon.mouse_filter=Control.MOUSE_FILTER_PASS;icon.custom_minimum_size=Vector2(38,38);icon.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;icon.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;ingredient.add_child(icon);label(ingredient,"×"+str(int(p.materials[m])),13)
  label(recipe,"→",24)
  for eq in p.equipment:
   var machine=TextureRect.new();machine.texture=A.item_texture(eq,"equipment");machine.custom_minimum_size=Vector2(40,48);machine.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;machine.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;machine.tooltip_text=C.ops().equipment[eq].name;machine.mouse_filter=Control.MOUSE_FILTER_PASS;recipe.add_child(machine)
  if p.get("service_duration",0)>0:
   var service_label=label(col,"In service %d • capacity %d • expected %.0fs" % [sim.occupied_slots(b),sim.service_capacity(b,key),sim.service_seconds(id,key)],15);service_label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
  button(col,"Remove from menu" if enabled else "Add to product line",func():act(func():return sim.select_product(id,key,not enabled)))
  if enabled:
   var price=SpinBox.new();price.prefix="Price  ";price.min_value=1;price.max_value=p.price*3;price.step=.5;price.value=b.menu[key].price;col.add_child(price)
   var target=SpinBox.new();target.prefix="Preparation buffer  " if b.trade in ["salon","daycare","minigolf"] else "Ready-stock limit  ";target.min_value=1;target.max_value=40;target.value=b.menu[key].target;col.add_child(target)
   button(col,"Confirm product plan",func():act(func():return sim.product_plan(id,key,price.value,int(target.value))))
func materials_panel(id:String,b:Dictionary)->void:
 paragraph("Order named materials, not generic supplies. Choose a supplier, compare its price, freight, quality and lead time. One order is one material. Freight is included in inventory cost.")
 var pick=OptionButton.new()
 for source in C.ops().suppliers:pick.add_item(source.name+" • %.0fs • minimum %d" % [source.lead,source.minimum])
 pick.selected=supplier_choice;panel_body.add_child(pick);pick.item_selected.connect(func(i:int):supplier_choice=i;show_panel("supplies"))
 var source=C.ops().suppliers[supplier_choice]
 paragraph("Unit-price factor %.2f • freight %.0f per material order • quality %.0f%% • storage %d / %d units." % [source.multiplier,source.freight,source.quality*100,b.inputs,240+b.cold*120])
 var needed={}
 for key in b.menu:
  if b.menu[key].enabled:
   for m in C.ops().products[key].materials:needed[m]=true
 for m in b.materials:
  if sim.quantity(b.materials,m)>0:needed[m]=true
 if needed.is_empty():paragraph("Choose products first. Their ingredients and packaging will appear here.")
 for m in needed:
  var key:String=m;var info=C.ops().materials[key];var on_order=0
  for o in b.orders:
   if o.material==key:on_order+=int(o.qty)
  var vendor_name=str(info.local_supplier) if supplier_choice==0 else str(source.name)
  var col=item_card(key,"material",info.name+" • "+vendor_name,"%s • %.2f each before supplier factor\nOn hand %d • on order %d • %s" % [info.unit,info.cost,sim.quantity(b.materials,key),on_order,"durable" if info.life==0 else "%d-day life; cold storage can protect suitable stock" % info.life])
  var qty=SpinBox.new();qty.prefix="Order quantity  ";qty.min_value=source.minimum;qty.max_value=100;qty.value=maxi(10,int(source.minimum));col.add_child(qty)
  var buy=button(col,"",func():act(func():return sim.order_material(id,key,int(qty.value),supplier_choice)))
  var update=func(_value:float=0):buy.text="Order %d %s • %.2f total" % [int(qty.value),info.name,qty.value*info.cost*source.multiplier+source.freight]
  qty.value_changed.connect(update);update.call()
 paragraph("Deliveries on the road")
 for o in b.orders:paragraph("%d × %s • %.1fs remaining" % [o.qty,C.ops().materials[o.material].name,o.due])
func people_panel(id:String,b:Dictionary)->void:
 paragraph("Read each resume, then choose the role. Applicants are not pre-assigned jobs. Relevant experience, service skills and reliability affect work. Exact simulation skill numbers are hidden; watch queues, output and results. Recruitment costs 25; each business can hire six people.")
 for i in b.employees.size():
  var index:int=i;var e=b.employees[i];staff_card(int(e.id),false);var row=HFlowContainer.new();panel_body.add_child(row)
  for r in [["craft","Preparation / making"],["serve","Customer service"],["stock","Receiving / stock"]]:
   var role_name:String=r[0];button(row,("✓ " if e.role==role_name else "")+r[1],func():act(func():return sim.role(id,index,role_name)))
  button(panel_body,"End employment…",func():confirm_action("End employment?","A half-period transition payment applies. Earlier hiring and results remain in the ledger.",func():act(func():return sim.dismiss(id,index))))
 paragraph("Current applicant pool • 30 people • refreshes every three completed market days. Hired people stay. Requested pay is per full trading period.")
 for i in C.staff().size():
  var p=C.staff()[i];var taken=false
  for owned in state.businesses.values():
   if owned.employees.any(func(e):return int(e.id)==int(p.id)):taken=true
  if not taken:
   var index:int=i;staff_card(int(p.id),true);button(panel_body,"Interview & hire "+p.name+" • 25",func():act(func():return sim.hire(id,index)))
func equipment_panel(id:String,b:Dictionary)->void:
 if b.equipment>0:paragraph("Earlier workstation improvements retained: level %d adds preparation efficiency." % b.equipment)
 paragraph("Inherited machines can be sold for 55% of their purchase value, adjusted for condition. New product lines may need different equipment. Close before installation, sale or maintenance.")
 var needed={}
 for product_key in b.menu:
  var product=C.ops().products[product_key]
  for eq in product.equipment:needed[eq]=true
 for eq in b.assets:needed[eq]=true
 for info in browser_items(C.ops().equipment.values(),b,"equipment",needed):
  var key:String=info.id;var owned=b.assets.has(key)
  var col=item_card(key,"equipment",info.name,"Installed %d • condition %.0f%% • resale per unit %.0f" % [int(b.assets[key].count),b.assets[key].condition*100,b.assets[key].paid/maxi(1,int(b.assets[key].count))*.55*b.assets[key].condition] if owned else "Not installed • purchase %.0f" % info.cost)
  if owned:button(col,"Buy another • %.0f" % info.cost,func():act(func():return sim.equipment(id,key,true)))
  button(col,"Sell one unit…" if owned else "Buy & install • %.0f" % info.cost,func():
   if owned:confirm_action("Sell equipment?","Products requiring "+info.name+" will stop until you replace it.",func():act(func():return sim.equipment(id,key,false)))
   else:act(func():return sim.equipment(id,key,true)))
 button(panel_body,"Service installed equipment • %.0f" % sim.maintenance_quote(id),func():act(func():return sim.maintain(id)))
 for entry in [["display","Display capacity & customer patience"],["cold","Storage capacity & shelf life"],["quality","Quality presentation"],["brand","Shopfront recognition"],["training","Staff development"]]:
  var key:String=entry[0];paragraph(entry[1]+" • level %d/3" % b[key]);button(panel_body,"Improve • %.0f" % (60+b[key]*45),func():act(func():return sim.improve(id,key)))
func staff_card(index:int,_applicant:bool)->void:
 var info=C.person(index);var row=HBoxContainer.new();panel_body.add_child(row);var portrait=TextureRect.new();portrait.texture=A.actor(index,0);portrait.custom_minimum_size=Vector2(128,128);portrait.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;portrait.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;row.add_child(portrait)
 var resume="%s\nRequested pay %.1f / period\n%s" % [info.name,info.wage,info.bio]
 for job in info.get("experience",[]):resume+="\n• %s — %d year(s), %s" % [job.job,job.years,"most recent role" if job.ago==0 else "ended %d year(s) ago" % job.ago]
 resume+="\n"+str(info.get("reference","Earlier employee profile retained."));var text=label(row,resume,16);text.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;text.size_flags_horizontal=Control.SIZE_EXPAND_FILL
func confirm_action(title_text:String,message:String,action:Callable)->void:
 var dialog=ConfirmationDialog.new();dialog.title=title_text;dialog.dialog_text=message;add_child(dialog);dialog.confirmed.connect(func():action.call();dialog.queue_free());dialog.canceled.connect(dialog.queue_free);dialog.popup_centered(Vector2i(560,220))
func confirm_restart()->void:
 confirm_action("Start this district over?","This resets your local/classroom district businesses, employees, money and stock. Public adventure progress and previously submitted assignments remain. A restart count is retained in future evidence.",func():sim.restart();A.actor_textures.clear();state=sim.state;save_state();panel.hide();panel_kind="";select(state.selected);buildings.queue_redraw();refresh())
func attach_evidence()->void:
 var S=preload("res://scripts/learning_store.gd");var result=S.attach(S.load_data(),"MAM1010","district",state.duplicate(true),"Market Quarter • "+C.spec(state.selected).name,"Market Quarter")
 toast.text=result if not result.is_empty() else "District snapshot attached to your learning portfolio."
func draw_actors()->void:
 var begin=Time.get_ticks_usec();var visible_world=Rect2((Vector2.ZERO-world.position)/zoom,root.size/zoom).grow(100);var all_people=sim.workers+sim.people;all_people.sort_custom(func(a,b):return a.pos.y<b.pos.y)
 for p in all_people:
  if not visible_world.has_point(p.pos):continue
  var moving=p.pos.distance_to(p.prev)>.1;var pose=1+int(sim.clock*8)%2 if moving else 8+int(sim.clock*3)%2 if (p.get("role","")=="craft" or p.get("owner",false) and not sim.business(p.shop).production_key.is_empty()) and sim.business(p.shop).open else 0
  var point=p.prev.lerp(p.pos,clampf(accumulator/.1,0,1));A.person(actors,point,int(p.person),pose,1.0,p.get("fade",1.0))
  if p.has("role") and p.role in ["stock","craft"] and moving:
   var materials=sim.business(p.shop).materials.keys()
   if not materials.is_empty():actors.draw_texture_rect(A.item_texture(materials[0],"material"),Rect2(point+Vector2(2,-35),Vector2(25,25)),false)
  if p.get("bought",false) and C.ops().products[p.product].get("service_duration",0)==0:actors.draw_texture_rect(A.item_texture(p.product,"product"),Rect2(point+Vector2(5,-30),Vector2(24,24)),false)
  if p.get("phase","") is String and p.phase=="queue":
   actors.draw_arc(point-Vector2(0,71),6,-PI/2,-PI/2+TAU*minf(1,p.wait/35),12,Color("#e4be7e"),2)
 for id in state.businesses:
  var b=sim.business(id);var o=C.plot(id)
  if not visible_world.intersects(Rect2(o-Vector2(20,100),Vector2(650,670))):continue
  if b.trade in ["salon","daycare","minigolf"]:preload("res://scripts/business_district/venue_art.gd").live(actors,o,b,sim.clock)
  A.ink(actors,o+Vector2(24,390),("%d material units • %d service kits" if b.trade in ["salon","daycare","minigolf"] else "%d material units • %d products ready") % [b.inputs,b.stock],16,Color("#314943"))
  var slot=0
  for key in b.assets:
   var pos=o+Vector2(40+(slot%4)*125,100+(slot/4)*95);actors.draw_texture_rect(A.item_texture(key,"equipment"),Rect2(pos,Vector2(74,74)),false);A.ink(actors,pos+Vector2(0,83),(C.ops().equipment[key].name+" × "+str(b.assets[key].count)).left(23),11,Color("#2c4444"));slot+=1
   if slot>=8:break
  slot=0
  for key in b.materials:
   if sim.quantity(b.materials,key)==0:continue
   var pos=o+Vector2(400+(slot%3)*36,42+(slot/3)*38);actors.draw_texture_rect(A.item_texture(key,"material"),Rect2(pos,Vector2(34,34)),false);slot+=1
   if slot>=9:break
  slot=0
  for key in b.finished:
   if sim.quantity(b.finished,key)==0 or C.ops().products[key].get("service_duration",0)>0:continue
   var pos=o+Vector2(280+(slot%4)*42,300);actors.draw_texture_rect(A.item_texture(key,"product"),Rect2(pos,Vector2(40,40)),false);slot+=1
   if slot>=4:break
  if b.open:
   var station=sim.station(id,"craft");var progress=clampf(b.produce/float(C.ops().products.get(b.production_key,{"prep":1}).prep),0,1);actors.draw_rect(Rect2(station-Vector2(29,69),Vector2(58,5)),Color("#293c3d"));actors.draw_rect(Rect2(station-Vector2(29,69),Vector2(58*progress,5)),Color("#c8b77b"))
   if id=="kitchen":
    for j in 3:A.ellipse(actors,station+Vector2(j*9-9,-48-fmod(sim.clock*12+j*9,30)),Vector2(6,4),Color(.95,.94,.85,.25))
   if id=="clothier":actors.draw_line(station-Vector2(10,31),station-Vector2(10+sin(sim.clock*16)*3,47),Color("#efe3b7"),2)
   if id=="fishery":
    for j in 3:actors.draw_circle(o+Vector2(305+j*25,120+sin(sim.clock*2+j)*3),1.5,Color("#eef5e3",.6))
   if id=="garden":
    for j in 4:actors.draw_line(station+Vector2(15+j*5,-44+fmod(sim.clock*15+j*5,22)),station+Vector2(14+j*5,-41+fmod(sim.clock*15+j*5,22)),Color("#a6cdd0"),1.5)
   if id in ["workshop","mine"]:
    for j in 4:
     var t=fmod(sim.clock*2+j*.2,1);actors.draw_line(station+Vector2(10,-35),station+Vector2(10+cos(j*2)*t*20,-35-sin(j)*t*12),Color("#efc278",1-t),1.5)
  if not b.orders.is_empty():
   var o2=b.orders[0];var cart=o+Vector2(620-minf(100,(20-o2.due)*4),72);A.box(actors,cart,Vector2(36,28),Color("#ae8455"),16);actors.draw_texture_rect(A.item_texture(o2.material,"material"),Rect2(cart-Vector2(0,30),Vector2(34,34)),false);actors.draw_circle(cart+Vector2(4,30),6,Color("#293c3d"));actors.draw_circle(cart+Vector2(30,30),6,Color("#293c3d"))
 for fx in sim.effects:
  if visible_world.has_point(fx.pos):A.ink(actors,fx.pos-Vector2(0,(1-fx.life)*15),fx.text,20,Color("#e2d58d",minf(1,fx.life)))
 frame_us=Time.get_ticks_usec()-begin;peak_frame_us=maxi(peak_frame_us,frame_us)
func _process(dt:float)->void:
 if not ready_ui:return
 accumulator+=minf(dt,.25)
 while accumulator>=.1:sim.step(.1);accumulator-=.1
 if sim.scene_changed:buildings.queue_redraw();sim.scene_changed=false
 actors.queue_redraw();save_clock+=dt;ui_clock+=dt
 if ui_clock>=.4:ui_clock=0;refresh()
 if save_clock>=8:save_clock=0;save_state()
 if not sim.last_notice.is_empty():toast.text=sim.last_notice;sim.last_notice=""
func _input(event:InputEvent)->void:
 if not ready_ui:return
 if event is InputEventKey and event.pressed and event.keycode==KEY_ESCAPE:
  if panel.visible:panel.hide();panel_kind=""
  else:leave()
  get_viewport().set_input_as_handled();return
 if event is InputEventMouseButton:
  var over_ui=event.position.y<145 or event.position.y>root.size.y-110 or panel.visible and panel.get_global_rect().has_point(event.position)
  if event.button_index in [MOUSE_BUTTON_WHEEL_UP,MOUSE_BUTTON_WHEEL_DOWN] and not over_ui:
   zoom=clampf(zoom*(1.12 if event.button_index==MOUSE_BUTTON_WHEEL_UP else 1/1.12),.28,2);update_camera();get_viewport().set_input_as_handled()
  if event.button_index==MOUSE_BUTTON_LEFT:
   if event.pressed and not over_ui:drag=true;dragged=false;last_mouse=event.position
   elif not event.pressed and drag:
    drag=false
    if not dragged:inspect((event.position-world.position)/zoom)
 if event is InputEventMouseMotion and drag:
  var delta=event.position-last_mouse
  if delta.length()>2:dragged=true
  centre-=delta/zoom;centre=centre.clamp(Vector2(0,0),Vector2(3000,3400));last_mouse=event.position;update_camera()
func inspect(point:Vector2)->void:
 for p in sim.people+sim.workers:
  if Rect2(p.pos-Vector2(22,64),Vector2(44,70)).has_point(point):
   show_panel("customer")
   if p.get("owner",false):
    paragraph("Your proprietor • prepares goods and serves customers. Dedicated employees increase capacity; each is paid separately.")
   elif p.has("budget"):
    var portrait=TextureRect.new();portrait.texture=A.actor(int(p.person),0);portrait.custom_minimum_size=Vector2(112,112);portrait.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;portrait.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;panel_body.add_child(portrait)
    paragraph(p.name+"\nShopping for "+C.ops().products.get(p.get("product",""),{"name":"goods"}).name.to_lower())
   else:staff_card(int(p.person),false)
   paragraph(p.get("thought","Working at "+C.spec(p.shop).name+" • "+p.get("role","proprietor")))
   if p.has("budget"):
    paragraph("Budget %.0f • waiting %.1f seconds" % [p.budget,p.wait])
    var patience=ProgressBar.new();patience.max_value=[25,36,44][p.segment]+int(sim.business(p.shop).display)*3;patience.value=maxf(0,patience.max_value-p.wait);patience.show_percentage=false;panel_body.add_child(patience)
    paragraph("Travellers tend to spend less and hurry. Collectors tend to allow more time and have larger budgets. Watch who actually purchases before changing your pricing.")
   return
 for v in C.ventures():
  if Rect2(C.plot(v.id),Vector2(572,403)).has_point(point):select(v.id);return
func save_state()->void:
 if classroom:
  if is_instance_valid(academy):academy.capture_simulation(state)
  return
 if C.valid(state):game.legacy.data.district=state.duplicate(true);game.legacy.save();sim.changed=false
 else:toast.text="Save check failed. Keep this window open and report this issue."
func leave()->void:
 save_state();game.process_mode=previous_mode;game.set_process(previous_process);game.visible=previous_visible
 for entry in hidden_layers:
  if is_instance_valid(entry.node):entry.node.visible=entry.visible
 if classroom and is_instance_valid(academy):academy.return_from_scene()
 if game.has_method("reset_controls"):game.reset_controls()
 queue_free()

func reverse_copy(values:Array)->Array:
 var copy=values.duplicate();copy.reverse();return copy

func report()->String:
 return JSON.stringify({"format":"crossroads-market-quarter","version":1,"simulation":"Fictional educational market; no real financial advice or automatic credit awards","district":state.duplicate(true)},"  ")
func download_report()->void:
 var content=report()
 if OS.has_feature("web"):
  JavaScriptBridge.download_buffer(content.to_utf8_buffer(),"crossroads-market-quarter-report.json","application/json");toast.text="Report download requested."
 else:
  var dialog=FileDialog.new();dialog.access=FileDialog.ACCESS_FILESYSTEM;dialog.file_mode=FileDialog.FILE_MODE_SAVE_FILE;dialog.current_file="crossroads-market-quarter-report.json";dialog.use_native_dialog=true;add_child(dialog)
  dialog.file_selected.connect(func(path:String):
   var f=FileAccess.open(path,FileAccess.WRITE)
   if f==null:toast.text="Could not save that report. Choose another location."
   else:f.store_string(content);f.close();toast.text="Business report saved."
   dialog.queue_free())
  dialog.canceled.connect(dialog.queue_free);dialog.popup_centered(Vector2i(800,600))

func pause_for_access(message:String)->void:
 sim.restricted=true;sim.access=[];sim.last_notice="";toast.text=message;set_process(false)

func browser_items(items:Array,b:Dictionary,kind:String="product",needed:Dictionary={})->Array:
 var controls=HFlowContainer.new();panel_body.add_child(controls)
 var categories=["Recommended","On my menu","All"] if kind=="product" else ["Recommended","Installed","All"]
 if kind=="product":
  for p in items:
   var cat=str(p.get("category",p.trade.capitalize()))
   if cat not in categories:categories.append(cat)
 var pick=OptionButton.new();controls.add_child(pick)
 for category in categories:pick.add_item(category)
 pick.select(maxi(0,categories.find(browse_category)))
 pick.item_selected.connect(func(i:int):browse_category=categories[i];browse_page=0;show_panel(panel_kind))
 var search=LineEdit.new();search.placeholder_text="Search name • press Enter";search.text=browse_query;search.custom_minimum_size.x=210;controls.add_child(search);search.text_submitted.connect(func(text:String):browse_query=text.strip_edges();browse_page=0;show_panel(panel_kind))
 var filtered=[]
 for item in items:
  var include=true
  if browse_category=="Recommended":include=item.id in C.spec(b.trade).get("starter_products",[]) if kind=="product" else needed.has(item.id)
  elif browse_category=="On my menu":include=b.menu.has(item.id)
  elif browse_category=="Installed":include=b.assets.has(item.id)
  elif browse_category!="All" and kind=="product":include=str(item.get("category",item.trade.capitalize()))==browse_category
  if include and (browse_query.is_empty() or browse_query.to_lower() in str(item.name).to_lower()):filtered.append(item)
 var pages=maxi(1,ceili(filtered.size()/float(PAGE_SIZE)));browse_page=clampi(browse_page,0,pages-1)
 paragraph("%d matches • page %d/%d • %d shown at a time" % [filtered.size(),browse_page+1,pages,PAGE_SIZE])
 var row=HBoxContainer.new();panel_body.add_child(row)
 button(row,"Previous",func():browse_page=maxi(0,browse_page-1);show_panel(panel_kind)).disabled=browse_page==0
 button(row,"Next",func():browse_page=mini(pages-1,browse_page+1);show_panel(panel_kind)).disabled=browse_page>=pages-1
 return filtered.slice(browse_page*PAGE_SIZE,mini(filtered.size(),(browse_page+1)*PAGE_SIZE))

func sales_charts(b:Dictionary)->void:
 var totals={}
 for report in b.history:
  for key in report.get("products_sold",{}):totals[key]=int(totals.get(key,0))+int(report.products_sold[key])
 if b.open:
  for key in b.observations:totals[key]=int(totals.get(key,0))+int(b.observations[key])
 var keys=totals.keys();keys.sort_custom(func(a,c):return totals[a]>totals[c])
 paragraph("Top products • units sold across the retained last 24 reports plus this opening")
 if keys.is_empty():paragraph("No sales yet. Open a business and serve customers; your actual sales chart will appear here.")
 var maximum=1
 for key in keys:maximum=maxi(maximum,int(totals[key]))
 for key in keys.slice(0,10):
  var latest=int(b.history[-1].get("products_sold",{}).get(key,0)) if not b.history.is_empty() else 0
  var previous=int(b.history[-2].get("products_sold",{}).get(key,0)) if b.history.size()>1 else 0
  paragraph(C.ops().products[key].name+" • "+str(totals[key])+" sold • last day %d vs %d before (%+d)" % [latest,previous,latest-previous])
  var bar=ProgressBar.new();bar.min_value=0;bar.max_value=maximum;bar.value=totals[key];bar.show_percentage=false;bar.custom_minimum_size.y=16;panel_body.add_child(bar)
 paragraph("Daily sales • last eight openings; bars are units, not revenue")
 var recent=b.history.slice(maxi(0,b.history.size()-8))
 for report in recent:
  paragraph("Day %d%s • %d sold • profit %.2f" % [report.day," (partial)" if not report.get("full_day",false) else "",report.sold,report.profit])
  var bar=ProgressBar.new();bar.max_value=maxi(1,recent.map(func(h):return h.sold).max());bar.value=report.sold;bar.show_percentage=false;bar.custom_minimum_size.y=14;panel_body.add_child(bar)
 paragraph("OUTLOOK • seeded simulated demand; not a promise or an assessment mark. Refreshes every three workdays. Missing stock, price and queues can still prevent sales.")
 for key in b.menu:
  if b.menu[key].enabled:paragraph(C.ops().products[key].name+" • "+sim.trend_text(state.selected,key))

func confirm_business_restart()->void:
 var id:String=state.selected;var b=sim.business(id)
 if b.open:toast.text="Close the business before restarting or requesting approval.";return
 if classroom:
  if not is_instance_valid(academy) or academy.attempt.is_empty():toast.text="An assigned module and teacher approval are required for a classroom restart.";return
  confirm_action("Ask your teacher to restart "+b.name+"?","Your latest statistics will be sent for review. This business will pause until your teacher approves or declines.",func():save_state();academy.request_business_restart(id);leave())
 else:confirm_action("Restart "+b.name+"?","This resets only the selected business, free of charge. Its earlier summary is retained. Other ventures and reserve savings are kept.",func():act(func():return sim.restart_business(id)))

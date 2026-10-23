extends CanvasLayer
const C=preload("res://scripts/business_district/catalog.gd")
const A=preload("res://scripts/business_district/art.gd")
const Sim=preload("res://scripts/business_district/simulation.gd")
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
 if not C.valid(state):state=C.fresh()
 sim.setup(state)
 previous_process=game.is_processing();previous_visible=game.visible
 previous_mode=game.process_mode;process_mode=Node.PROCESS_MODE_ALWAYS;game.process_mode=Node.PROCESS_MODE_DISABLED
 for child in game.find_children("*","CanvasLayer",true,false):
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
  for v in C.ventures():A.premises(buildings,v,state.businesses.get(v.id,{}),state.selected==v.id,state.night))
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
 var nav=ScrollContainer.new();nav.custom_minimum_size.y=43;nav.vertical_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;top.add_child(nav)
 var tabs=HBoxContainer.new();nav.add_child(tabs)
 for v in C.ventures():
  var id:String=v.id
  button(tabs,v.name,func():select(id))
 status=label(top,"",16)
 var bottom=PanelContainer.new();bottom.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE);bottom.offset_left=14;bottom.offset_right=-14;bottom.offset_top=-94;bottom.offset_bottom=-12;root.add_child(bottom);style(bottom)
 var column=VBoxContainer.new();bottom.add_child(column)
 var sc=ScrollContainer.new();sc.custom_minimum_size.y=43;sc.vertical_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;column.add_child(sc)
 var actions=HBoxContainer.new();sc.add_child(actions)
 button(actions,"Open / Close",toggle_open)
 for entry in [["Supplies","supplies"],["People","people"],["Fit out","fitout"],["Strategy","strategy"],["Ledger","ledger"],["District map","map"]]:
  var key:String=entry[1];button(actions,entry[0],func():show_panel(key))
 button(actions,"Help prepare",func():act(func():return sim.stock_help(state.selected)))
 toast=label(column,"",15)
 panel=PanelContainer.new();root.add_child(panel);style(panel);panel.hide()
 var col=VBoxContainer.new();panel.add_child(col)
 var pr=HBoxContainer.new();col.add_child(pr);panel_title=label(pr,"",22);panel_title.size_flags_horizontal=Control.SIZE_EXPAND_FILL;button(pr,"×",func():panel.hide();panel_kind="")
 var scroll=ScrollContainer.new();scroll.size_flags_vertical=Control.SIZE_EXPAND_FILL;col.add_child(scroll)
 panel_body=VBoxContainer.new();panel_body.size_flags_horizontal=Control.SIZE_EXPAND_FILL;scroll.add_child(panel_body)
 root.resized.connect(resize_ui);resize_ui();ready_ui=true;select(state.selected);refresh()
 toast.text="Welcome. Choose a premises, order supplies, then open for a three-minute trading period."
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
 panel.position=Vector2(maxf(14,size.x-minf(475,size.x-28)-14),148);panel.size=Vector2(minf(475,size.x-28),maxf(140,size.y-255))
 update_camera()
func update_camera()->void:
 if not is_instance_valid(root):return
 world.modulate=Color("#a7b6d2") if state.night else Color.WHITE
 world.scale=Vector2.ONE*zoom;world.position=root.size*.5-centre*zoom+Vector2(0,12);actors.queue_redraw()
func select(id:String)->void:
 state.selected=id;centre=C.plot(id)+Vector2(220,145);zoom=clampf((root.size.y-235)/440.0,.65,1.45);update_camera();buildings.queue_redraw();refresh()
 if not state.businesses.has(id):show_panel("premises")
 elif panel.visible:show_panel(panel_kind)
func act(f:Callable,redraw:bool=true)->void:
 var success=f.call()
 toast.text=sim.last_notice if success and not sim.last_notice.is_empty() else "Saved your change." if success else "That action is unavailable. Check cash, stock, staffing and whether you are open."
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
 title.text=("CLASSROOM • " if classroom else "")+v.name.to_upper()
 if b.is_empty():status.text="Available premises • 300 market cash allocation • District reserve %.0f" % state.reserve
 else:status.text="%s • Cash %.0f • Supplies %d • Ready %d • Sold %d • Reputation %.0f%% • %s" % ["OPEN %d:%02d" % [int(maxf(0,Sim.PERIOD-b.elapsed))/60,int(maxf(0,Sim.PERIOD-b.elapsed))%60] if b.open else "CLOSED",b.cash,b.inputs,b.stock,b.served,b.reputation,["Market day","Food festival","Craft fair","Rainy market"][int(b.day)%4]]
func show_panel(kind:String)->void:
 if not ready_ui and kind!="premises":return
 panel_kind=kind
 for n in panel_body.get_children():panel_body.remove_child(n);n.queue_free()
 panel.show();var id:String=state.selected;var b=sim.business(id);var v=C.spec(id)
 panel_title.text={"premises":"Your next venture","supplies":"Receiving & supplies","people":"Your people","fitout":"Fit out your premises","strategy":"Plan the next period","ledger":"Business ledger","map":"Explore the district","help":"Welcome to Market Quarter","customer":"At your business"}.get(kind,kind)
 if kind=="help":
  paragraph("Build a business you can actually watch. Customers browse, queue and leave with goods. Staff walk between receiving, preparation and service.")
  paragraph("1 • Choose a premises. Its 300 market cash comes from a separate district reserve; your adventure money is untouched.\n2 • Order supplies. A delivery cart brings them to your bay.\n3 • Set a price and open. Each period lasts three active minutes.\n4 • Watch people, inspect the ledger, then improve one decision.")
  paragraph("Drag empty ground to pan. Scroll to zoom. Click a person to hear their thoughts. The district map shows every venture. Town saves your progress and suspends district trading; time away never earns money or wages.")
  paragraph("Every venture can buy supplies here. Mining, fishing, gardening, combat, art and cooking courses are optional. Market cash and loans belong to this district only.")
  paragraph("Reports show operating profit: sales minus the cost of sold stock, promotion, wages, rent and spoilage. Unsold stock remains inventory. Fit-out purchases and loan principal appear separately in the cash ledger; the loan fee is a financing cost.")
  button(panel_body,"Day / lantern evening",func():state.night=not state.night;update_camera();floor_layer.queue_redraw();buildings.queue_redraw();lighting.queue_redraw();save_state())
  return
 if kind=="map":
  paragraph("Nine independently operated premises. Select a venture to visit its workshop and customers. The extra venture, Lantern & Ladder, explores equipment rental and service logistics.")
  for spec in C.ventures():
   var sid:String=spec.id;button(panel_body,("● " if state.businesses.has(sid) else "+ ")+spec.name+" • "+spec.product,func():panel.hide();panel_kind="";select(sid))
  button(panel_body,"View whole district",func():panel.hide();panel_kind="";centre=Vector2(930,800);zoom=minf(root.size.x/1900,(root.size.y-240)/1600);update_camera())
  return
 if b.is_empty():
  paragraph(v.description);paragraph("You will see "+v.product.to_lower()+" made from "+v.input.to_lower()+". "+v.tip)
  paragraph("Start with 300 market cash. District reserve: %.0f. No adventure resources or subject-specific skills are required." % state.reserve)
  button(panel_body,"Establish venture • allocate 300",func():act(func():return sim.establish(id));show_panel("supplies"));return
 match kind:
  "supplies":
   paragraph("Receiving bay • %s\n%d supplies on hand • %d finished goods ready" % [v.input,b.inputs,b.stock])
   paragraph("Supplies cost %.2f per unit at current quality, plus 4 delivery. Delivery cost becomes part of inventory value. Suppliers are available to every player." % (float(v.cost)*(1+.12*b.quality)))
   if not b.delivery.is_empty():paragraph("On the road: %d units • %.0f seconds until delivery" % [b.delivery.units,b.delivery_due])
   for units in [10,20,40]:
    var amount:int=units;button(panel_body,"Order %d • %.0f cash" % [units,float(v.cost)*units*(1+.12*b.quality)+4],func():act(func():return sim.order(id,amount)))
   if id=="rental":paragraph("Equipment fleet: %d sets • %d on hire. A hire returns after 28 active seconds. Maintenance kits prepare each booking. Equipment upgrades add two sets per level." % [2+int(b.equipment)*2,b.hires.size()])
   paragraph("Prepared stock capacity: %d. A stockkeeper improves replenishment speed. Perishable finished goods can spoil when a period ends; cold storage reduces this loss." % (30+int(b.display)*10))
  "people":
   paragraph("The proprietor prepares and serves to get you started. Hire up to three employees per venture. Each person can work for one venture only. Recruitment costs 15; wages are charged for actual opening time.")
   for i in b.employees.size():
    var idx:int=i;var e=b.employees[i];staff_card(int(e.id),false)
    var roles=HBoxContainer.new();panel_body.add_child(roles)
    for role_name in ["craft","serve","stock"]:
     var role:String=role_name;button(roles,("✓ " if e.role==role else "")+role.capitalize(),func():act(func():return sim.role(id,idx,role)))
   paragraph("Applicants • individual skills and personalities")
   for i in C.staff().size():
    var taken=false
    for owned in state.businesses.values():
     for e in owned.employees:
      if int(e.id)==i:taken=true
    if not taken:
     staff_card(i,true)
     var index:int=i;button(panel_body,"Hire "+C.staff()[i].name+" • 15",func():act(func():return sim.hire(id,index)))
  "fitout":
   paragraph("Close before changing equipment. Upgrades change the visible premises and the simulation. "+v.upgrade)
   for entry in [["equipment","Workstation","Faster preparation"],["display","Display shelving","More ready-stock space and patience"],["cold","Protected storage","Less spoilage of perishable goods"],["quality","Material quality","Higher acceptable prices; costlier supplies"],["brand","Shopfront identity","More walk-in interest"],["training","Staff development","Faster preparation and service"]]:
    var key:String=entry[0];paragraph(entry[1]+" • Level "+str(b[key])+"/3 • "+entry[2]);button(panel_body,"Improve • %.0f cash" % (60+float(b[key])*45),func():act(func():return sim.improve(id,key)))
  "strategy":
   paragraph(v.tip+"\nClose the shop to change the plan. Observe the effect during your next opening.")
   paragraph("Selling price • suggested baseline %.0f" % v.price)
   var price=SpinBox.new();price.min_value=1;price.max_value=float(v.price)*3;price.step=.5;price.value=b.price;panel_body.add_child(price)
   button(panel_body,"Set price",func():act(func():return sim.set_price(id,price.value)))
   paragraph("Promotion budget %.0f • charged once at opening" % b.ad)
   for money in [0.0,10.0,25.0]:
    var budget:float=money;button(panel_body,"Choose %.0f campaign" % budget,func():act(func():return sim.advertise(id,budget)))
   paragraph("Layout: "+["Compact","Open aisle • faster service","Display led"][int(b.layout)])
   button(panel_body,"Try next floor layout",func():act(func():return sim.rearrange(id)))
   paragraph("Distribution route: "+["Direct collection","Local retailer","Wholesaler network"][int(b.route)]+". Wider routes take longer to deliver; courier capacity increases with route investment.")
   button(panel_body,"Change distribution route",func():act(func():
    if b.open:return false
    b.route=(int(b.route)+1)%3;sim.log_action(id,"Route",str(b.route));return true))
   paragraph("Decision journal • record what you expect and why")
   var note=TextEdit.new();note.custom_minimum_size=Vector2(280,95);note.text=b.note;note.placeholder_text="I will change… because… I expect…";panel_body.add_child(note)
   button(panel_body,"Save reasoning",func():act(func():b.note=note.text.left(1000);sim.log_action(id,"Reasoning",b.note);return true))
  "ledger":
   paragraph("Cash %.2f • Inventory at cost %.2f • Loan due %.2f\nDistrict reserve %.0f (separate from each venture)." % [b.cash,b.input_book+b.stock_book,b.loan,state.reserve])
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
   button(panel_body,"Repay 100 loan" if b.loan>0 else "Borrow 90 • repay 100",func():act(func():return sim.finance(id)))
   button(panel_body,"Download business report",download_report)
   paragraph("Transactions • most recent first")
   for entry in reverse_copy(b.ledger.slice(maxi(0,b.ledger.size()-15))):paragraph("%s • %+.2f • balance %.2f\n%s" % [entry.kind,entry.amount,entry.balance,entry.detail])
   if not classroom and preload("res://scripts/education_access.gd").student():
    paragraph("For the MAM1010 practical-evidence check, complete two trading periods in one venture and save your reasoning in Strategy. Your teacher still assesses the quality of the analysis.")
    button(panel_body,"Attach district evidence to MAM1010",attach_evidence)
func staff_card(index:int,applicant:bool)->void:
 var info=C.staff()[index];var row=HBoxContainer.new();panel_body.add_child(row)
 var portrait=TextureRect.new();portrait.texture=A.actor(index,0);portrait.custom_minimum_size=Vector2(64,86);portrait.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;portrait.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;row.add_child(portrait)
 var text=label(row,"%s • %s\n%s\nCraft %.1f • Service %.1f • %.0f / period" % [info.name,info.role,info.bio,info.craft,info.service,info.wage],16);text.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;text.size_flags_horizontal=Control.SIZE_EXPAND_FILL
func attach_evidence()->void:
 var S=preload("res://scripts/learning_store.gd");var result=S.attach(S.load_data(),"MAM1010","district",state.duplicate(true),"Market Quarter • "+C.spec(state.selected).name,"Market Quarter")
 toast.text=result if not result.is_empty() else "District snapshot attached to your learning portfolio."
func draw_actors()->void:
 var begin=Time.get_ticks_usec();var visible_world=Rect2((Vector2.ZERO-world.position)/zoom,root.size/zoom).grow(100);var all_people=sim.workers+sim.people;all_people.sort_custom(func(a,b):return a.pos.y<b.pos.y)
 for p in all_people:
  if not visible_world.has_point(p.pos):continue
  var moving=p.pos.distance_to(p.prev)>.1;var pose=int(sim.clock*8)%4 if moving else 8+int(sim.clock*3)%2 if p.get("role","")=="craft" and sim.business(p.shop).open else 0
  var point=p.prev.lerp(p.pos,clampf(accumulator/.1,0,1));A.person(actors,point,int(p.person),pose,1.0,p.get("fade",1.0))
  if p.has("role") and p.role in ["stock","craft"] and moving:A.goods(actors,point+Vector2(13,-23),C.spec(p.shop).icon,1,.55)
  if p.get("bought",false):A.goods(actors,point+Vector2(12,-21),C.spec(p.shop).icon,1,.35)
  if p.get("phase","") is String and p.phase=="queue":
   actors.draw_arc(point-Vector2(0,71),6,-PI/2,-PI/2+TAU*minf(1,p.wait/35),12,Color("#e4be7e"),2)
 for id in state.businesses:
  var b=sim.business(id);var o=C.plot(id)
  if not visible_world.intersects(Rect2(o-Vector2(20,100),Vector2(500,520))):continue
  A.ink(actors,o+Vector2(22,290),"%d supplies  •  %d ready" % [b.inputs,b.stock],14,Color("#314943"))
  A.goods(actors,o+Vector2(310 if int(b.layout)!=2 else 85,232),C.spec(id).icon,mini(8,int(b.stock)),.8)
  if id=="rental":
   for j in b.hires.size():
    A.goods(actors,o+Vector2(290+j*18,382),"rental",1,.8);actors.draw_arc(o+Vector2(290+j*18,359),5,-PI/2,-PI/2+TAU*(1-float(b.hires[j])/28),12,Color("#e3c77e"),2)
  if b.inputs>0:
   for j in mini(3,int(ceil(b.inputs/10.0))):A.box(actors,o+Vector2(309+j*24,84),Vector2(20,16),Color("#ba9b6a"),14)
  if b.open:
   var station=sim.station(id,"craft");var progress=clampf(b.produce/float(C.spec(id).prep),0,1);actors.draw_rect(Rect2(station-Vector2(29,69),Vector2(58,5)),Color("#293c3d"));actors.draw_rect(Rect2(station-Vector2(29,69),Vector2(58*progress,5)),Color("#c8b77b"))
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
  if not b.delivery.is_empty():
   var t=clampf(1-b.delivery_due/(8+int(b.route)*3),0,1);var cart=o+Vector2(490-165*t,65)
   A.box(actors,cart,Vector2(34,26),Color("#ae8455"),16);actors.draw_circle(cart+Vector2(4,29),6,Color("#293c3d"));actors.draw_circle(cart+Vector2(30,29),6,Color("#293c3d"));A.person(actors,cart+Vector2(-20,30),4,4+int(sim.clock*7)%4,.75)
 for fx in sim.effects:
  if visible_world.has_point(fx.pos):A.ink(actors,fx.pos-Vector2(0,(1-fx.life)*15),fx.text,20,Color("#e2d58d",minf(1,fx.life)))
 frame_us=Time.get_ticks_usec()-begin;peak_frame_us=maxi(peak_frame_us,frame_us)
func _process(dt:float)->void:
 if not ready_ui:return
 accumulator+=minf(dt,.25)
 while accumulator>=.1:sim.step(.1);accumulator-=.1
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
  centre-=delta/zoom;centre=centre.clamp(Vector2(0,0),Vector2(1860,1600));last_mouse=event.position;update_camera()
func inspect(point:Vector2)->void:
 for p in sim.people+sim.workers:
  if Rect2(p.pos-Vector2(22,64),Vector2(44,70)).has_point(point):
   show_panel("customer")
   if p.get("owner",false):
    paragraph("Your proprietor • prepares goods and serves customers. Dedicated employees increase capacity; each is paid separately.")
   elif p.has("budget"):
    var portrait=TextureRect.new();portrait.texture=A.actor(int(p.person),0);portrait.custom_minimum_size=Vector2(72,96);portrait.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;portrait.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;panel_body.add_child(portrait)
    paragraph(p.name+"\nShopping for "+C.spec(p.shop).product.to_lower())
   else:staff_card(int(p.person),false)
   paragraph(p.get("thought","Working at "+C.spec(p.shop).name+" • "+p.get("role","proprietor")))
   if p.has("budget"):
    paragraph("Budget %.0f • waiting %.1f seconds" % [p.budget,p.wait])
    var patience=ProgressBar.new();patience.max_value=[25,36,44][p.segment]+int(sim.business(p.shop).display)*3;patience.value=maxf(0,patience.max_value-p.wait);patience.show_percentage=false;panel_body.add_child(patience)
    paragraph("Travellers tend to spend less and hurry. Collectors tend to allow more time and have larger budgets. Watch who actually purchases before changing your pricing.")
   return
 for v in C.ventures():
  if Rect2(C.plot(v.id),Vector2(440,310)).has_point(point):select(v.id);return
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

extends CanvasLayer
const UI=preload("res://scripts/studio_ui.gd")
var market:RefCounted
var panel:PanelContainer
var body:VBoxContainer
var page:VBoxContainer
var status:Label
var wallet:Label
var tabs:TabBar
var pacing_picker:SpinBox
var day_clock:Label
var opening:Button
var timer=0.0
var pending_save=0.0
var rendered_day=-1
var active=false
var old_process=true
var old_visible=true
func label(parent:Node,value:String,size:int=17)->Label:
 var l=Label.new();l.text=value;l.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;l.add_theme_font_size_override("font_size",size);parent.add_child(l);return l
func product_cost(d:Dictionary)->String:
 if d.has("bar"):return "1 forged "+str(market.legacy.mine.FOUNDRY.METALS[d.bar].name)+" bar + %.1f processing cash" % (d.cost*(1+.25*market.state().quality))
 return "%.0f ore + %.0f gems + %.1f processing cash" % [d.ore,d.gems,d.cost*(1+.25*market.state().quality)]
func button(parent:Node,value:String,action:Callable)->Button:
 var b=Button.new();b.text=value;b.custom_minimum_size.y=44;parent.add_child(b);b.pressed.connect(action);return b
func setup(owner:RefCounted)->void:
 market=owner;layer=80
 var bg=ColorRect.new();bg.color=Color("#0b1921");bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);add_child(bg)
 panel=PanelContainer.new();add_child(panel);UI.apply(panel)
 body=VBoxContainer.new();panel.add_child(body);body.add_theme_constant_override("separation",10)
 var header=HBoxContainer.new();body.add_child(header)
 var title=label(header,"CROSSROADS MARKET",26);title.size_flags_horizontal=Control.SIZE_EXPAND_FILL;title.add_theme_color_override("font_color",Color("#ebcc87"))
 button(header,"Idle Mining",func():close();market.legacy.mine.open())
 if not market.legacy.arcade:button(header,"Fishing bait",func():close();market.legacy.game.fishing.open_workshop())
 button(header,"Back to town",close)
 var pacing=HBoxContainer.new();body.add_child(pacing)
 var pacing_title=label(pacing,"One business day (minutes):",16);pacing_title.custom_minimum_size=Vector2(260,40);pacing_title.vertical_alignment=VERTICAL_ALIGNMENT_CENTER
 var duration=SpinBox.new();pacing_picker=duration;duration.min_value=5;duration.max_value=1440;duration.step=5;duration.value=market.state().day_seconds/60;duration.custom_minimum_size=Vector2(150,40);pacing.add_child(duration);duration.editable=not market.readonly() and not market.busy();duration.value_changed.connect(func(v:float):if not market.set_duration(v*60):duration.set_value_no_signal(market.state().day_seconds/60))
 day_clock=label(pacing,"",16);day_clock.custom_minimum_size=Vector2(320,40);day_clock.vertical_alignment=VERTICAL_ALIGNMENT_CENTER;day_clock.size_flags_horizontal=Control.SIZE_EXPAND_FILL
 wallet=label(body,"",19);status=label(body,"",16)
 tabs=TabBar.new();body.add_child(tabs)
 for name in ["Market floor","Plan & trade","Reports","Grow your business","Trading tips"]:tabs.add_tab(name)
 tabs.tab_changed.connect(func(_i:int):render())
 var scroll=ScrollContainer.new();scroll.size_flags_vertical=Control.SIZE_EXPAND_FILL;scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;body.add_child(scroll);preload("res://scripts/touch_list_scroll.gd").attach(scroll).form_controls=true
 page=VBoxContainer.new();page.size_flags_horizontal=Control.SIZE_EXPAND_FILL;page.add_theme_constant_override("separation",14);scroll.add_child(page)
 opening=button(body,"OPEN MARKET • begin timed trading",func():action(market.run_day));opening.disabled=market.readonly()
 label(body,"Separate account economy • saved in your player ZIP • real-time business days • continues while away • daily supply dividend • no direct stat bonuses",14)
 hide()
func open()->void:
 old_process=market.legacy.game.is_processing();old_visible=market.legacy.game.visible;market.legacy.game.set_process(false);market.legacy.game.hide();market.legacy.game.mobile.reset_controls();market.legacy.game.menu="commerce";active=true;show();render();UI.enter(panel)
func close()->void:
 if not active:return
 pending_save=0;active=false;hide();market.save();market.legacy.game.menu="";market.legacy.game.visible=old_visible;market.legacy.game.set_process(old_process);market.legacy.game.mobile.reset_controls();market.legacy.game.queue_redraw()
func _process(_delta:float)->void:
 if not active:return
 if pending_save>0:
  pending_save=maxf(0,pending_save-_delta)
  if pending_save==0:market.save()
 timer+=_delta
 if timer>=.5:
  timer=0;market.advance()
  if market.state().day!=rendered_day:render()
  var remaining=maxi(0,ceili(float(market.state().trading.get("end",0))-market.now()))
  day_clock.text="TRADING • %02d:%02d:%02d left" % [remaining/3600,(remaining%3600)/60,remaining%60] if market.busy() else "Choose duration → Basic setup → Open market"
  pacing_picker.editable=not market.readonly() and not market.busy()
  opening.disabled=market.readonly() or market.busy()
  opening.text="TRADING • return for results when the countdown ends" if market.busy() else "OPEN MARKET • begin timed trading"
 var size=get_viewport().get_visible_rect().size;panel.size=Vector2(1160,670);var fit=minf(1,minf((size.x-20)/1160,(size.y-24)/670));panel.scale=Vector2.ONE*fit;panel.position=(size-panel.size*fit)*.5
func _input(event:InputEvent)->void:
 if market.legacy.game.menu=="education_business":return
 if active and event is InputEventKey and event.pressed and event.keycode==KEY_ESCAPE:close();get_viewport().set_input_as_handled()
func action(fn:Callable)->void:
 market.note=""
 if not fn.call() and market.note.is_empty():market.note="Cannot do this yet. Check the material/cash amounts on this card; active trading locks changes."
 render()
func choose(parent:Node,title:String,options:Array,current:int,setter:Callable)->void:
 label(parent,title,16)
 var pick=OptionButton.new();pick.custom_minimum_size.y=44;parent.add_child(pick)
 for name in options:pick.add_item(str(name))
 pick.select(current);pick.disabled=market.readonly() or market.busy();pick.item_selected.connect(func(i:int):setter.call(i);market.save();render())
func number(parent:Node,title:String,current:float,min_value:float,max_value:float,setter:Callable,step:float=1)->void:
 var row=HBoxContainer.new();parent.add_child(row);var text=label(row,title,16);text.size_flags_horizontal=Control.SIZE_EXPAND_FILL
 var spin=SpinBox.new();spin.min_value=min_value;spin.max_value=max_value;spin.step=step;spin.value=current;spin.custom_minimum_size=Vector2(180,42);spin.editable=not market.readonly() and not market.busy();row.add_child(spin);spin.value_changed.connect(func(v:float):setter.call(v);market.save())
func textfield(parent:Node,title:String,key:String)->void:
 label(parent,title,16);var edit=LineEdit.new();edit.text=market.state()[key];edit.max_length=1000;edit.custom_minimum_size.y=42;edit.editable=not market.readonly() and not market.busy();parent.add_child(edit);edit.text_changed.connect(func(t:String):market.state()[key]=t;pending_save=.6)
func render()->void:
 for child in page.get_children():page.remove_child(child);child.queue_free()
 rendered_day=int(market.state().day)
 var a=market.state();wallet.text="Day %d • Market cash %.1f • Lifetime sales %.1f • Operating profit %.1f • Reputation %.0f / 100" % [a.day,a.cash,a.revenue,a.profit,a.reputation]
 status.text=market.note if not market.readonly() else "PLAYTEST • read only; your account business is protected."
 if bool(market.legacy.data.teacher):status.text="GAME DEV • temporary market preview. No account changes or assessment credit."
 if tabs.current_tab==0:floor_view()
 elif tabs.current_tab==1:plan()
 elif tabs.current_tab==2:reports()
 elif tabs.current_tab==3:grow()
 else:classroom()
func floor_view()->void:
 button(page,"Glimmer exchange • sell fish & gathered goods",func():close();market.legacy.game.fishing.open_workshop();var w=market.legacy.game.fishing.workshop;w.selected_tab=4;w.build())
 var a=market.state()
 var reward=market.supply_reward()
 var dividend=UI.card(page,"SUPPLY DIVIDEND • "+str(int(reward.pending))+" CC ready","A profitable trading day with at least one sale earns 20 CC, once per real day. Bank up to 60 CC. Collect in town to help buy supplies; combat stats and multiplayer starting money stay the same.")
 var collect=button(dividend,"Collect "+str(int(reward.pending))+" CC for supplies",func():action(market.claim_supply));UI.accent(collect);collect.disabled=int(reward.pending)<=0 or market.readonly() or bool(market.legacy.data.get("teacher",false))
 var welcome=UI.card(page,"START HERE • your first market day","You can start without mining first. Basic setup buys a small wholesale starter pack using market cash, then sets a simple selling strategy.")
 var ready=button(welcome,"1 • Basic setup • ready my stall",func():action(market.basic_setup));UI.accent(ready);ready.disabled=market.readonly() or market.busy()
 var selected_product=market.PRODUCTS[int(a.product)];var units=int(a.inventory[selected_product.id].units)
 label(welcome,("✓" if units>0 else "1")+" • Stock: "+str(units)+" "+str(selected_product.name)+" units",16)
 label(welcome,"2 • Optional: Plan & trade lets you change product, price and promotion. Beginners can keep the defaults.",16)
 label(welcome,"3 • Set one business day at the top (5 minutes–24 hours), then press OPEN MARKET below. You may leave while it trades; return to Reports for results.",16)
 var issue=market.start_problem();label(welcome,"Ready to open." if issue.is_empty() else issue,16).modulate=Color("#bde1be" if issue.is_empty() else "#efcc91")
 page.move_child(dividend.get_parent(),1) # Keep the beginner setup first; reward collection follows it.
 var stage=preload("res://scripts/trade_visual.gd").new();stage.market=market;page.add_child(stage)
 var actions=HBoxContainer.new();page.add_child(actions)
 button(actions,"Plan prices & campaigns",func():tabs.current_tab=1)
 button(actions,"Inspect daily results",func():tabs.current_tab=2)
 button(actions,"Collect mine materials",func():action(market.legacy.mine.collect)).disabled=market.readonly()
 label(page,"PRODUCT DISPLAY • select goods below, then plan your strategy. Deeper mining unlocks new stock.",16)
 var grid=GridContainer.new();grid.columns=3;grid.add_theme_constant_override("h_separation",12);grid.add_theme_constant_override("v_separation",12);page.add_child(grid)
 for i in market.PRODUCTS.size():
  var product=market.PRODUCTS[i];var box=UI.card(grid,product.name,"");box.size_flags_horizontal=Control.SIZE_EXPAND_FILL
  var art=Control.new();art.custom_minimum_size=Vector2(0,42);box.add_child(art);art.draw.connect(func():preload("res://scripts/trade_visual.gd").icon(art,Vector2(28,21),i))
  label(box,"%d in stock • %.1f cash each" % [a.inventory[product.id].units,a.inventory[product.id].price],15)
  var b=button(box,"Select & plan" if market.unlocked(i) else "Unlock at shaft "+str(product.depth),func():a.product=i;market.save();tabs.current_tab=1);b.disabled=market.readonly() or market.busy() or not market.unlocked(i)
func plan()->void:
 var a=market.state()
 var stage=preload("res://scripts/trade_visual.gd").new();stage.market=market;page.add_child(stage)
 var cols=HBoxContainer.new();cols.add_theme_constant_override("separation",20);page.add_child(cols)
 var stock=VBoxContainer.new();stock.size_flags_horizontal=Control.SIZE_EXPAND_FILL;cols.add_child(stock)
 var strategy=VBoxContainer.new();strategy.size_flags_horizontal=Control.SIZE_EXPAND_FILL;cols.add_child(strategy)
 label(stock,"1 • PREPARE PRODUCTS",22)
 label(stock,"MINE MATERIALS • %.1f ore / %.1f gems collected • bars in Idle Mining" % [market.legacy.mine.state().wallet.ore,market.legacy.mine.state().wallet.gems],16)
 button(stock,"Collect mine depot",func():action(market.legacy.mine.collect)).disabled=market.readonly()
 label(stock,"Collect mine materials first. Original products use ore / gems; metal bars must be forged before preparing them for sale. Deeper shafts unlock both.",16)
 for i in market.PRODUCTS.size():
  var d=market.PRODUCTS[i];var item=a.inventory[d.id];var box=UI.card(stock,d.name,"")
  var picture=Control.new();picture.custom_minimum_size.y=40;box.add_child(picture);picture.draw.connect(func():preload("res://scripts/trade_visual.gd").icon(picture,Vector2(25,20),i))
  label(box,"Shaft %d • %d in stock • reference price %.0f\nEach: %s" % [d.depth,item.units,d.base,product_cost(d)],15)
  var row=HBoxContainer.new();box.add_child(row)
  for count in [1,5,20]:
   var b=button(row,"Prepare "+str(count),func():action(func():return market.stock(i,count)));b.disabled=market.readonly() or market.busy() or not market.unlocked(i)
 label(strategy,"2 • PLAN YOUR STRATEGY",22)
 var names=[]
 for d in market.PRODUCTS:names.append(d.name+(" • locked" if not market.unlocked(names.size()) else ""))
 choose(strategy,"Product to sell today",names,a.product,func(i:int):a.product=i)
 var d=market.PRODUCTS[int(a.product)]
 number(strategy,"Price per unit",a.inventory[d.id].price,1,d.base*4,func(v:float):a.inventory[d.id].price=v,.5)
 choose(strategy,"Target customer",market.SEGMENTS,a.segment,func(i:int):a.segment=i)
 choose(strategy,"Promotion channel",market.CHANNELS,a.channel,func(i:int):a.channel=i)
 choose(strategy,"Positioning message",market.MESSAGES,a.message,func(i:int):a.message=i)
 number(strategy,"Advertising budget",a.budget,0,100,func(v:float):a.budget=v)
 textfield(strategy,"Shop name", "brand");textfield(strategy,"Stall tagline (optional)","copy")
 if preload("res://scripts/education_access.gd").student():textfield(strategy,"Forecast: what do you expect and why?","forecast")
 if preload("res://scripts/education_access.gd").student():textfield(strategy,"Reflection: what would you change next?","reflection")
 label(strategy,"3 • OPEN FOR ONE BUSINESS DAY",22)
 var run=button(strategy,"OPEN MARKET • begin timed trading",func():action(market.run_day));run.disabled=market.readonly() or market.busy()
 label(strategy,"Daily overhead: %.0f. Stock costs are paid when prepared. The selected message influences which customers respond." % (2+a.shop*2+a.service*2),15)
func reports()->void:
 var export_row=HBoxContainer.new();page.add_child(export_row)
 button(export_row,"Copy business report",func():DisplayServer.clipboard_set(market.report());market.note="Business report copied.";render())
 button(export_row,"Download report",download)
 label(page,"DECISIONS → RESULTS",24)
 var a=market.state();label(page,"%.0f units sold • %.1f advertising spent • %.1f operating profit\nProfit counts consumed stock cost + material opportunity cost + advertising + overhead. Capital upgrades and unsold stock affect cash separately." % [a.units,a.marketing,a.profit],17)
 if a.history.is_empty():label(page,"No sales yet. Choose Basic setup or prepare stock, then open your first business day.");return
 var chart=Control.new();chart.custom_minimum_size.y=150;page.add_child(chart)
 chart.draw.connect(func():
  var rows=a.history.slice(maxi(0,a.history.size()-12));var top=1.0
  for r in rows:top=maxf(top,absf(float(r.profit)))
  chart.draw_line(Vector2(0,75),Vector2(chart.size.x,75),Color("#809f9e"),1)
  for n in rows.size():
   var width=chart.size.x/maxi(1,rows.size());var height=float(rows[n].profit)/top*52
   chart.draw_rect(Rect2(Vector2(n*width+6,75 if height<0 else 75-height),Vector2(width-12,absf(height))),Color("#d4887a") if height<0 else Color("#8cccaa"))
   chart.draw_string(ThemeDB.fallback_font,Vector2(n*width+8,144),"Day "+str(rows[n].day),HORIZONTAL_ALIGNMENT_LEFT,-1,12,Color("#d0d9cf")))
 label(page,"OPERATING PROFIT • last 12 business days • green profit / red loss",14)
 for offset in a.history.size():
  var r=a.history[a.history.size()-1-offset];var card=UI.card(page,"Day %d • %s • %s" % [r.day,r.product,r.event],"")
  label(card,"Sold %d / %d available • unmet demand %d\nRevenue %.1f − stock cost %.1f − advertising %.1f − overhead %.1f = profit %.1f\nReach %d → visits %d → purchase chance %.0f%% • ROAS %s • satisfaction %.0f / 100" % [r.sold,r.stock,r.unmet,r.revenue,r.cogs,r.advertising,r.overhead,r.profit,r.reach,r.visits,r.conversion*100,"%.2f" % r.roas if r.advertising>0 else "no paid ads",r.satisfaction],16)
  label(card,"Target: %s • Price %.1f • %s / %s" % [r.target,r.price,r.channel,r.message],15)
  if preload("res://scripts/education_access.gd").student():label(card,"Forecast: %s\nReflection: %s" % [r.forecast,r.reflection],15)
func grow()->void:
 for kind in ["quality","service","shop"]:
  var descriptions={"quality":"Better finishing raises price tolerance, but also preparation cost.","service":"Higher conversion and satisfaction, but ongoing wages increase overhead.","shop":"More passing customers, but higher rent every business day."}
  var box=UI.card(page,kind.capitalize()+" • level "+str(market.state()[kind])+" / 5",descriptions[kind])
  var cost=70*pow(1.8,market.state()[kind]);var b=button(box,"Upgrade • %.0f market cash" % cost,func():action(func():return market.upgrade(kind)));b.disabled=market.readonly() or market.state()[kind]>=5
 button(page,"Customer research • 12 cash",func():action(market.research)).disabled=market.readonly()
 label(page,"WORKING CAPITAL",22)
 label(page,"Outstanding loan: %.0f. Borrow 80, repay 100. Only one unpaid loan; borrowing never counts as sales." % market.state().debt)
 var loans=HBoxContainer.new();page.add_child(loans)
 button(loans,"Borrow 80 cash",func():action(market.loan)).disabled=market.readonly() or market.state().debt>0
 button(loans,"Repay loan",func():action(market.repay)).disabled=market.readonly() or market.state().debt<=0
 label(page,"REINVEST IN THE MINE",22);label(page,"Optional: transfer market cash into Mine Gold at 1:1. Leave a working-capital reserve for stock and operations. It never becomes Crossroads Coins.")
 var row=HBoxContainer.new();page.add_child(row)
 for amount in [25,100,500]:button(row,"Reinvest "+str(amount),func():action(func():return market.transfer(amount))).disabled=market.readonly()
func classroom()->void:
 var A=preload("res://scripts/education_access.gd")
 if A.student() or A.review_allowed():
  var challenges=UI.card(page,"STUDENT BUSINESS CHALLENGES","Three separate sandboxes: opportunity selection, risk and finance, controlled merchandising. Practice does not spend mine goods or market cash.")
  button(challenges,"Open business challenges",func():preload("res://scripts/education_business_page.gd").open(market.legacy))
 for lesson in [
  ["The 4 Ps","PRODUCT: choose mine goods. PRICE: trade margin against demand. PLACE: improve the shop and choose the right channel. PROMOTION: match your message to customer needs."],
  ["Know your customers","Builders want value. Collectors reward finishing and stories. Guilds prefer dependable service. A mismatched audience can waste a strong campaign."],
  ["Revenue is not profit","Revenue = units × price. Profit subtracts stock cost, advertising and overhead. Materials are valued at 0.45 per ore, 8 per gem and 55% of each bar’s reference price so free mining is not mistaken for free manufacturing. This is a teaching convention."],
  ["Cash flow and inventory","Preparing goods spends cash immediately. Unsold goods stay in inventory. Selling receives cash. Capital upgrades consume cash but are not daily operating expenses. Keep enough cash to open tomorrow."],
  ["A/B experiments","Change one setting, run a day and compare results. Calendar events affect demand, so compare the same day in each five-day cycle for a fairer test. The simulation is deterministic; it is not a prediction of real markets."],
  ["Assessment evidence","Download the business report with your decisions, forecasts, reflections and the last 100 daily results. Player Profile separately shows mine progression, sales and operating profit. Strong mining does not automatically mean strong marketing."],
  ["If you run out of cash","Sell existing stock with zero advertising; only basic overhead is required. New accounts receive 160 market cash. Mine resources remain safe; a working-capital loan can help you restock, but you must repay it before borrowing again."]]:
  if lesson[0]=="Assessment evidence" and not preload("res://scripts/education_access.gd").student():continue
  UI.card(page,lesson[0],lesson[1])
func download()->void:
 var content=market.report()
 if OS.has_feature("web"):JavaScriptBridge.download_buffer(content.to_utf8_buffer(),"crossroads-business-report.json","application/json");market.note="Report download requested.";render()
 else:
  var dialog=FileDialog.new();dialog.access=FileDialog.ACCESS_FILESYSTEM;dialog.file_mode=FileDialog.FILE_MODE_SAVE_FILE;dialog.current_file="crossroads-business-report.json";dialog.use_native_dialog=true;add_child(dialog)
  dialog.file_selected.connect(func(path:String):var f=FileAccess.open(path,FileAccess.WRITE);if f!=null:f.store_string(content);f.close();market.note="Report saved.";render();dialog.queue_free())
  dialog.popup_centered(Vector2i(800,600))

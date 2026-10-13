extends CanvasLayer
const UI=preload("res://scripts/studio_ui.gd")
var mine:RefCounted
var panel:PanelContainer
var shade:ColorRect
var page:VBoxContainer
var wallet:Label
var report:Label
var construction:Label
var construction_bar:ProgressBar
var ticker:Label
var tabs:TabBar
var controls:Array=[]
var labels:Dictionary={}
var bars:Dictionary={}
var cutaway:Control
var active=false
var previous_process=true
var previous_visible=true
var timer=0.0
var signature=""
func setup(owner:RefCounted)->void:
 mine=owner;layer=80
 shade=ColorRect.new();shade.color=Color("#08151e");shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);add_child(shade)
 panel=PanelContainer.new();panel.size=Vector2(1160,670);add_child(panel);UI.apply(panel)
 var body=VBoxContainer.new();panel.add_child(body)
 var header=HBoxContainer.new();body.add_child(header)
 var title=label(header,"IDLE MINING • Deepwell",26);title.add_theme_color_override("font_color",Color("#f0cc87"));title.size_flags_horizontal=Control.SIZE_EXPAND_FILL
 button(header,"Crossroads Market",func():close();mine.legacy.commerce.open())
 button(header,"Back up profile",backup)
 button(header,"Back to town",close)
 var goods=Control.new();goods.custom_minimum_size.y=38;body.add_child(goods);goods.draw.connect(func():
  for n in 3:preload("res://scripts/trade_visual.gd").icon(goods,Vector2(22+n*65,20),[0,1,2][n],.8))
 wallet=label(body,"",19)
 ticker=label(body,"",15);ticker.add_theme_color_override("font_color",Color("#9ec9d0"))
 report=label(body,"",16);report.add_theme_color_override("font_color",Color("#d7c792"))
 construction=label(body,"",15);construction_bar=ProgressBar.new();construction_bar.custom_minimum_size.y=16;body.add_child(construction_bar)
 tabs=TabBar.new();body.add_child(tabs)
 for tab in ["Mine & crews","Buildings","Milestones & geology","How it works","Mineral gallery","Smelter & metals"]:tabs.add_tab(tab)
 tabs.tab_changed.connect(func(_index:int):render())
 var scroll=ScrollContainer.new();scroll.size_flags_vertical=Control.SIZE_EXPAND_FILL;scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;body.add_child(scroll)
 preload("res://scripts/touch_list_scroll.gd").attach(scroll).form_controls=true
 page=VBoxContainer.new();page.size_flags_horizontal=Control.SIZE_EXPAND_FILL;page.add_theme_constant_override("separation",12);scroll.add_child(page)
 label(body,"Mine Gold, ore and gems stay in this account's mine • no combat bonuses • offline catch-up up to 24 hours",14)
 hide()
func geology_page()->void:
 var geology=preload("res://scripts/mine_geology.gd");var state=geology.state(mine)
 label(page,"MINERAL GALLERY • Discover deposits as you dig",23)
 label(page,"Your airflow and lift power extraction. Collect specimens with Collect Depot, then assay up to 25 for Mine Gold. Assaying takes 60 seconds. The Smelter & metals tab turns deeper metal seams into bars for the Market and construction.",16)
 if not state.order.is_empty():
  labels["geo_order"]=label(page,"Assaying "+str(state.order.amount)+" "+str(geology.DEPOSITS[state.order.id].name)+" • "+time_text(float(state.order.end)-mine.now()),17)
  var progress=ProgressBar.new();progress.value=completion(float(state.order.end),mine.now(),60);page.add_child(progress);bars["geo_order"]=progress
 var grid=GridContainer.new();grid.columns=2;grid.add_theme_constant_override("h_separation",16);grid.add_theme_constant_override("v_separation",14);page.add_child(grid)
 for id in geology.DEPOSITS:
  var item:Dictionary=geology.DEPOSITS[id];var card=UI.card(grid,str(item.name),"Shaft "+str(item.depth)+" • "+str(item.depth*30)+"m");card.custom_minimum_size.x=460;card.size_flags_horizontal=Control.SIZE_EXPAND_FILL
  var row=HBoxContainer.new();card.add_child(row);var picture=TextureRect.new();picture.texture=geology.icon(id);picture.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST;picture.custom_minimum_size=Vector2(72,72);picture.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;picture.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;picture.size_flags_vertical=Control.SIZE_SHRINK_CENTER;row.add_child(picture)
  labels["geo:"+id]=label(row,"",17);labels["geo:"+id].size_flags_horizontal=Control.SIZE_EXPAND_FILL
  var bar=ProgressBar.new();bar.max_value=250;bar.value=float(state.stored[id]);bar.show_percentage=false;card.add_child(bar);bars["geo:"+id]=bar;labels["geo_store:"+id]=label(card,"",15)
  var action_button=button(card,"Assay batch • "+str(item.price)+" Mine Gold / specimen",func():action(geology.sell.bind(mine,str(id))));action_button.disabled=mine.readonly() or mine.depth()<int(item.depth) or not state.order.is_empty() or float(state.wallet[id])<1;controls.append({"button":action_button,"kind":"mineral","id":id})
func label(parent:Node,text:String,size:int=17)->Label:
 var l=Label.new();l.text=text;l.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;l.add_theme_font_size_override("font_size",size);parent.add_child(l);return l
func button(parent:Node,text:String,action:Callable)->Button:
 var b=Button.new();b.text=text;b.custom_minimum_size.y=44;b.pressed.connect(action);parent.add_child(b);return b
func amount(value:float)->String:
 if value>=1000000000:return "%.2fB" % (value/1000000000)
 if value>=1000000:return "%.2fM" % (value/1000000)
 if value>=10000:return "%.1fk" % (value/1000)
 return "%.1f" % value if value<10 else str(int(value))
func cost_text(cost:Dictionary)->String:
 var parts=PackedStringArray()
 for key in mine.RESOURCES:
  if float(cost.get(key,0))>0:parts.append(amount(float(cost[key]))+" "+("Mine Gold" if key=="gold" else key.capitalize()))
 return " + ".join(parts)
func bar_cost_text(cost:Dictionary)->String:
 var parts=PackedStringArray()
 for id in cost:parts.append(str(int(cost[id]))+" "+str(mine.FOUNDRY.METALS[id].name)+" bar"+("s" if int(cost[id])!=1 else ""))
 return " + ".join(parts)
func full_cost(cost:Dictionary,materials:Dictionary)->String:
 return cost_text(cost)+(" + "+bar_cost_text(materials) if not materials.is_empty() else "")
func time_text(seconds:float)->String:
 var n=maxi(0,ceili(seconds))
 if n>=3600:return str(int(n/3600))+"h "+str(int(n%3600/60))+"m"
 if n>=60:return str(int(n/60))+"m "+str(n%60)+"s"
 return str(n)+"s"
func open()->void:
 active=true;show();mine.legacy.game.menu="idle_mine";mine.legacy.game.mobile.reset_controls()
 previous_process=mine.legacy.game.is_processing();previous_visible=mine.legacy.game.visible;mine.legacy.game.set_process(false);mine.legacy.game.hide()
 var arrival=mine.arrival;var a:Dictionary=arrival.get("resources",mine.zeros())
 report.text="WELCOME BACK • "+time_text(float(arrival.get("seconds",0)))+" since your last visit • produced "+cost_text(a) if float(arrival.get("seconds",0))>60 else "Your crews keep working while you adventure. Collect the depot to use its resources."
 if cost_text(a).is_empty() and float(arrival.get("seconds",0))>60:report.text="Welcome back. Commission your mine or clear depot space to get production moving."
 if mine.readonly():report.text="PLAYTEST • view only. Mining actions and account progress are disabled."
 if bool(mine.legacy.data.teacher):report.text="GAME DEV • temporary mine preview. No saves or account rewards."
 render();refresh();UI.enter(panel)
func close()->void:
 if not active:return
 active=false;hide();mine.advance();mine.legacy.save();mine.legacy.game.menu="";mine.legacy.game.mobile.reset_controls();mine.legacy.game.visible=previous_visible;mine.legacy.game.set_process(previous_process);mine.legacy.game.queue_redraw()
func backup()->void:
 if mine.readonly() or bool(mine.legacy.data.teacher):report.text="Exit testing mode before downloading your normal profile.";return
 mine.advance();mine.legacy.export_profile();report.text="Profile download requested • the whole mine is included in profile.json."
func action(method:Callable)->void:
 var gathered=mine.state().stored.duplicate(true)
 var ok:Variant=method.call()
 if ok is bool and not ok:report.text="Not ready yet. Check your collected resources, building requirements or active construction."
 elif method.get_method()=="collect":report.text="COLLECTED • "+cost_text(gathered)+" • saved in your mine wallet"
 else:report.text="Order received • "+mine.recommendation()
 render();refresh()
func render()->void:
 for child in page.get_children():page.remove_child(child);child.queue_free()
 controls.clear();labels.clear();bars.clear();cutaway=null
 signature=JSON.stringify([mine.depth(),mine.state().levels,mine.state().job.get("kind",""),mine.state().refine.is_empty(),mine.state().milestones,mine.FOUNDRY.state(mine).job.is_empty(),preload("res://scripts/mine_geology.gd").state(mine).order.is_empty()])
 if not mine.state().commissioned:
  var intro=UI.card(page,"A mine of your own","An old ram tunnel is ready to become your operation. Its 120 Mine Gold starter grant belongs only to the mine.")
  label(intro,"Commission a camp for 80 Mine Gold: one ram digger, a lift, fresh-air fan, tool bench and depot. You can hire a second digger immediately.")
  var start=button(intro,"Commission starter camp • 80 Mine Gold",func():action(mine.commission));UI.accent(start);start.disabled=mine.readonly()
  label(intro,"Your hero is not involved. Grow this operation over many visits, then download your player profile to take it to another computer.")
  return
 match tabs.current_tab:
  0:mine_page()
  1:buildings_page()
  2:ledger_page()
  4:geology_page()
  5:foundry_page()
  3:help_page()
 refresh()
func dynamic(parent:Node,key:String,text:String="")->Label:
 var l=label(parent,text);labels[key]=l;return l
func tracked(parent:Node,text:String,method:Callable,kind:String,id:Variant="")->Button:
 var b=button(parent,text,func():action(method));controls.append({"button":b,"kind":kind,"id":id});return b
func mine_page()->void:
 var galleries=HBoxContainer.new();page.add_child(galleries)
 var picture_scroll=ScrollContainer.new();picture_scroll.custom_minimum_size=Vector2(640,390);picture_scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;galleries.add_child(picture_scroll)
 preload("res://scripts/touch_list_scroll.gd").attach(picture_scroll)
 cutaway=preload("res://scripts/idle_mine_cutaway.gd").new();cutaway.mine=mine;picture_scroll.add_child(cutaway)
 var sidebar=ScrollContainer.new();sidebar.custom_minimum_size=Vector2(340,390);sidebar.size_flags_horizontal=Control.SIZE_EXPAND_FILL;sidebar.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;galleries.add_child(sidebar)
 preload("res://scripts/touch_list_scroll.gd").attach(sidebar).form_controls=true
 var crew=VBoxContainer.new();crew.size_flags_horizontal=Control.SIZE_EXPAND_FILL;sidebar.add_child(crew)
 var flow=UI.card(crew,"YOUR OPERATION")
 UI.accent(tracked(flow,"COLLECT DEPOT",mine.collect,"collect"))
 var newest=mine.depth()-1
 for index in range(mine.depth()-1,-1,-1):
  if int(mine.state().shafts[index].crew)<12:newest=index;break
 tracked(flow,"",mine.hire.bind(newest),"hire_quick",newest);dynamic(flow,"pending")
 for pair in [["air","Fresh air"],["lift","Lift capacity"],["store","Depot space"]]:
  dynamic(flow,pair[0]);var bar=ProgressBar.new();bar.max_value=100;bar.show_percentage=false;bar.custom_minimum_size.y=10;var fill=StyleBoxFlat.new();fill.bg_color=Color("#7cc6d0") if pair[0]=="air" else Color("#d7bd79") if pair[0]=="lift" else Color("#8dbd98");fill.set_corner_radius_all(4);bar.add_theme_stylebox_override("fill",fill);flow.add_child(bar);bars[pair[0]]=bar
 dynamic(flow,"advice")
 for id in mine.BOOSTS:
  tracked(flow,"",mine.boost.bind(id),"boost",id);progress_bar(flow,"boost_"+id)
 label(flow,"Rally: double digging for 60s • Flush: double air for 120s • Survey: double gem recovery for 180s",14)
 var build=UI.card(crew,"EXPAND THE SHAFTS")
 dynamic(build,"job");progress_bar(build,"job_progress");tracked(build,"",mine.excavate,"excavate");tracked(build,"Cancel build • full refund",mine.cancel_build,"cancel");tracked(build,"",mine.FOUNDRY.reinforce.bind(mine),"reinforce")
 label(build,"One construction crew works at a time. From shaft 5, bars help build deeper works. Deliver one reinforcement batch to shorten a running build by 35%.",14)
 label(crew,"YOUR RAM CREWS",21)
 for index in mine.depth():
  var card=UI.card(crew,"Shaft "+str(index+1)+" • "+str((index+1)*30)+"m",str(mine.state().shafts[index].crew)+" / 12 diggers")
  tracked(card,"",mine.hire.bind(index),"hire",index)
func buildings_page()->void:
 dynamic(page,"job");progress_bar(page,"job_progress");tracked(page,"",mine.FOUNDRY.reinforce.bind(mine),"reinforce")
 for id in mine.SERVICES:
  var spec:Dictionary=mine.CATALOG.data().services[id];var lv=int(mine.state().levels[id])
  var card=UI.card(page,str(spec.name)+" • "+("Level "+str(lv) if lv>0 else "Not built"),str(spec.description))
  var row=HBoxContainer.new();card.add_child(row);tracked(row,"",mine.upgrade.bind(id),"upgrade",id)
  label(row,"Unlock: shaft "+str(int(spec.depth))+" • building time "+time_text(mini(600,int(spec.seconds)+lv*8)),15).size_flags_horizontal=Control.SIZE_EXPAND_FILL
  if id=="smelter":
   button(card,"Open Smelter & metals",func():tabs.current_tab=5)
   tracked(card,"",mine.refine,"refine");progress_bar(card,"refine_progress")
 label(page,"Air and pump requirements keep deep excavation balanced. All costs use collected mine resources.",15)
func ledger_page()->void:
 var record=UI.card(page,"YOUR MINING LEDGER","Account progress, independent of hero mastery.")
 label(record,"Mine level "+str(mine.level())+" • "+str(mine.depth()*30)+"m deep • "+str(mine.workers())+" ram diggers")
 dynamic(record,"lifetime")
 for item in mine.milestones():
  var card=UI.card(page,str(item.name),str(int(minf(float(item.need),float(item.target))))+" / "+str(int(item.target))+" • reward: "+cost_text(item.reward))
  var completion=progress_bar(card,"milestone_"+item.id);completion.value=clampf(float(item.need)/maxf(1,float(item.target))*100,0,100)
  tracked(card,"",mine.claim.bind(item.id),"milestone",item.id)
 var geology=UI.card(page,"GEOLOGY JOURNAL","New deposits change the colour and detail of your galleries.")
 for biome in mine.CATALOG.data().biomes:
  label(geology,("DISCOVERED • " if mine.depth()>=int(biome.depth) else "Shaft "+str(biome.depth)+" • ")+str(biome.name),19).add_theme_color_override("font_color",Color(biome.accent) if mine.depth()>=int(biome.depth) else Color("#83969f"))
  if mine.depth()>=int(biome.depth):label(geology,str(biome.lore),15)
func help_page()->void:
 for pair in [
  ["START SMALL","The camp costs 80 of your 120 starter Mine Gold. Hire another digger, collect the depot, and use those resources to deepen the mine."],
  ["FIX THE BOTTLENECK","Digging output is reduced when airflow is insufficient. The lift then limits how much reaches the surface. More diggers cannot overcome a full depot or slow lift. The Mine tab recommends your next improvement."],
  ["RETURN WITHOUT A PENALTY","A full depot pauses further production; stored resources stay safe. Upgrade storage for longer breaks. Offline production catches up at the current operation's rates, up to 24 hours per absence. Expired boosts and finished building timers are included."],
  ["GOLD, ORE AND GEMS","Mine Gold hires crews and pays construction costs. Ore builds machinery or can be refined. Gem fractions accumulate into gems, used for advanced upgrades. Collecting transfers depot supplies into your spendable mine wallet. Gold and ore use one storage unit each; gems use ten."],
  ["BUILDINGS AND COOLDOWNS","One construction order runs at a time. The smelter makes timed bar batches or refines ordinary ore for gold. Metal seams unlock at shafts 2, 4, 7, 11, 15 and 18. Collect them, then combine with coal. Bars can be sold at the Market, used for deeper buildings or delivered to shorten a current build. Rally, Flush and Survey are free timed boosts with reusable cooldowns; boosts help only if transport and storage can handle the output."],
  ["YOUR PROFILE IS THE SAVE","The whole operation lives in your downloaded player profile. Download before leaving a shared school computer, then upload your newest ZIP to resume elsewhere. New Game clears this device's mine too. There is no login or remote account server."],
  ["TESTING AND CLOCKS","Playtest views the mine without changing it. Game Dev opens a temporary fully built mine; refresh or exit to restore normal progress. Offline production uses the device clock, and moving it backward gives no extra income. This is a personal idle game, not a verified leaderboard."],
  ["THE LONG GAME","Twenty shafts, eight building types and twelve milestones give the mine room to grow. Ore production raises Mine level, opening access to deeper shafts. Upgrades improve your mine only; its wealth never buys combat equipment or changes hero statistics."]]:UI.card(page,pair[0],pair[1])
static func completion(end:float,stamp:float,duration:float)->float:return clampf(100*(1-(end-stamp)/maxf(1,duration)),0,100)
func progress_bar(parent:Node,key:String)->ProgressBar:
 var bar=ProgressBar.new();bar.max_value=100;bar.show_percentage=true;bar.custom_minimum_size.y=20;var fill=StyleBoxFlat.new();fill.bg_color=Color("#77bda6");fill.set_corner_radius_all(5);bar.add_theme_stylebox_override("fill",fill);parent.add_child(bar);bars[key]=bar;return bar
func refresh()->void:
 var s=mine.state();var r=mine.rates();var stamp=mine.now()
 var geology=preload("res://scripts/mine_geology.gd");var minerals=geology.state(mine)
 if bars.has("geo_order") and not minerals.order.is_empty():
  bars["geo_order"].value=completion(float(minerals.order.end),stamp,60)
  labels["geo_order"].text="Assaying "+str(minerals.order.amount)+" "+str(geology.DEPOSITS[minerals.order.id].name)+" • "+time_text(float(minerals.order.end)-stamp)
 for id in geology.DEPOSITS:
  if labels.has("geo:"+id):
   labels["geo:"+id].text="Collected "+amount(float(minerals.wallet[id]))+" • lifetime "+amount(float(minerals.lifetime[id]))
   labels["geo_store:"+id].text="Deposit case "+amount(float(minerals.stored[id]))+" / 250"
   bars["geo:"+id].value=float(minerals.stored[id])
 wallet.text="MINE WALLET   Mine Gold "+amount(float(s.wallet.gold))+"   •   Ore "+amount(float(s.wallet.ore))+"   •   Gems "+amount(float(s.wallet.gems))
 ticker.text="LEVEL "+str(mine.level())+"   •   DEPTH "+str(mine.depth()*30)+"m   •   "+str(mine.workers())+" DIGGERS   •   Surface output / minute: "+amount(float(r.gold)*60)+" gold, "+amount(float(r.ore)*60)+" ore, "+amount(float(r.gems)*60)+" gems"
 if labels.has("air"):
  labels.air.text="Air: "+amount(float(r.air_supply))+" supply / "+amount(float(r.air_demand))+" demand";bars.air.value=float(r.air)*100
  labels.lift.text="Lift: "+amount(float(r.lift))+" /s • digging "+amount(float(r.dig))+" /s";bars.lift.value=minf(100,float(r.lift)/maxf(float(r.dig)*float(r.air),.01)*100)
  labels.store.text="Depot: "+amount(mine.stored_units())+" / "+amount(mine.capacity());bars.store.value=mine.stored_units()/mine.capacity()*100
  labels.advice.text=mine.recommendation();labels.pending.text="Ready: "+cost_text(s.stored)
 if labels.has("job"):
  labels.job.text="Construction crew ready • "+mine.next_requirement() if s.job.is_empty() else ("Excavating shaft "+str(mine.depth()+1) if s.job.kind=="shaft" else "Building "+str(mine.CATALOG.data().services[s.job.service].name))+" • "+time_text(float(s.job.end)-stamp)+" remaining"
 construction.visible=not s.job.is_empty();construction_bar.visible=not s.job.is_empty()
 if not s.job.is_empty():
  var duration=minf(1800,60*pow(1.25,mine.depth()-1)) if s.job.kind=="shaft" else mini(600,int(mine.CATALOG.data().services[s.job.service].seconds)+int(s.levels[s.job.service])*8)
  construction.text=("Excavating next shaft" if s.job.kind=="shaft" else "Upgrading "+str(mine.CATALOG.data().services[s.job.service].name))+" • "+time_text(float(s.job.end)-stamp)+" remaining"
  construction_bar.value=completion(float(s.job.end),stamp,duration)
 if bars.has("job_progress"):
  var duration=1.0
  if not s.job.is_empty():duration=minf(1800,60*pow(1.25,mine.depth()-1)) if s.job.kind=="shaft" else mini(600,int(mine.CATALOG.data().services[s.job.service].seconds)+int(s.levels[s.job.service])*8)
  bars.job_progress.value=100 if s.job.is_empty() else completion(float(s.job.end),stamp,duration)
  bars.job_progress.tooltip_text="Construction ready" if s.job.is_empty() else "Elapsed construction time"
 if bars.has("refine_progress"):bars.refine_progress.value=100 if s.refine.is_empty() else completion(float(s.refine.end),stamp,30)
 refresh_foundry(stamp)
 for id in mine.BOOSTS:
  if bars.has("boost_"+id):
   var bar:ProgressBar=bars["boost_"+id];var active=float(s.active[id])>stamp
   bar.value=completion(float(s.active[id]) if active else float(s.ready[id]),stamp,float(mine.BOOSTS[id].duration) if active else float(mine.BOOSTS[id].cooldown))
   bar.tooltip_text="Boost duration elapsed" if active else "Cooldown recovery • full means ready"
 if labels.has("lifetime"):labels.lifetime.text="Lifetime production: "+cost_text(s.lifetime)+" • ore refined: "+amount(float(s.refined))
 for entry in controls:
  var b:Button=entry.button;var ready=true
  match entry.kind:
   "collect":ready=mine.stored_units()>0.001
   "hire","hire_quick":
    var index=int(entry.id);var full=int(s.shafts[index].crew)>=12;b.text="Crew full" if full else ("Hire shaft "+str(index+1)+" digger • " if entry.kind=="hire_quick" else "Hire digger • ")+cost_text(mine.hire_cost(index));ready=not full and mine.afford(mine.hire_cost(index))
   "upgrade":
    var id=str(entry.id);var spec:Dictionary=mine.CATALOG.data().services[id];var full=int(s.levels[id])>=25
    b.text="Maximum level" if full else ("Build" if int(s.levels[id])==0 else "Upgrade to Lv "+str(int(s.levels[id])+1))+" • "+full_cost(mine.upgrade_cost(id),mine.material_cost(id))
    ready=not full and mine.depth()>=int(spec.depth) and s.job.is_empty() and mine.afford(mine.upgrade_cost(id)) and mine.FOUNDRY.affordable(mine,mine.material_cost(id))
   "excavate":b.text="Open shaft "+str(mine.depth()+1)+" • "+full_cost(mine.next_shaft_cost(),mine.material_cost()) if mine.depth()<20 else "All shafts open";ready=mine.depth()<20 and s.job.is_empty() and mine.next_requirement().is_empty() and mine.afford(mine.next_shaft_cost()) and mine.FOUNDRY.affordable(mine,mine.material_cost())
   "cancel":ready=not s.job.is_empty()
   "boost":
    var id=str(entry.id);var spec:Dictionary=mine.BOOSTS[id];var locked=mine.depth()<int(spec.depth) or id=="survey" and int(s.levels.assay)==0
    b.text=str(spec.name)+( " • shaft "+str(spec.depth)+(" + Assay" if id=="survey" else "") if locked else " • active "+time_text(float(s.active[id])-stamp) if float(s.active[id])>stamp else " • ready in "+time_text(float(s.ready[id])-stamp) if float(s.ready[id])>stamp else " • READY")
    ready=not locked and float(s.ready[id])<=stamp
   "refine":
    var lv=int(s.levels.smelter);b.text="Refining • "+time_text(float(s.refine.end)-stamp) if not s.refine.is_empty() else "Refine "+str(lv*30)+" ore → "+amount(lv*30*(.6+.015*lv))+" Mine Gold • 30s";ready=lv>0 and s.refine.is_empty() and mine.FOUNDRY.state(mine).job.is_empty() and float(s.wallet.ore)>=lv*30
   "forge":
    var id=str(entry.id[0]);var count=int(entry.id[1]);ready=mine.FOUNDRY.can_forge(mine,id,count)
   "forge_cancel":ready=not mine.FOUNDRY.state(mine).job.is_empty()
   "reinforce":
    var f=mine.FOUNDRY.state(mine);var cost=mine.FOUNDRY.reinforce_cost(mine)
    b.text="Reinforcement delivered" if f.reinforced else "Deliver "+bar_cost_text(cost)+" • 35% less remaining build time"
    ready=not s.job.is_empty() and not f.reinforced and mine.FOUNDRY.affordable(mine,cost)
   "mineral":ready=mine.depth()>=int(geology.DEPOSITS[entry.id].depth) and minerals.order.is_empty() and float(minerals.wallet[entry.id])>=1
   "milestone":
    ready=false
    for item in mine.milestones():
     if item.id==entry.id:ready=float(item.need)>=float(item.target) and item.id not in s.milestones
    b.text="Claimed" if entry.id in s.milestones else "Claim reward" if ready else "Keep growing"
  b.disabled=not ready or mine.readonly()
func _input(event:InputEvent)->void:
 if active and event is InputEventKey and event.pressed and event.keycode==KEY_ESCAPE:close();get_viewport().set_input_as_handled()
func _process(delta:float)->void:
 if not active:return
 var size=get_viewport().get_visible_rect().size;panel.size=Vector2(1160,670);var fit=minf(1,minf((size.x-20)/panel.size.x,(size.y-20)/panel.size.y));panel.scale=Vector2.ONE*fit;panel.position=(size-panel.size*fit)*.5
 timer+=delta
 if timer>=1:
  timer=0;mine.advance()
  var changed=JSON.stringify([mine.depth(),mine.state().levels,mine.state().job.get("kind",""),mine.state().refine.is_empty(),mine.state().milestones,mine.FOUNDRY.state(mine).job.is_empty(),preload("res://scripts/mine_geology.gd").state(mine).order.is_empty()])
  if changed!=signature:render()
  refresh()

func foundry_page()->void:
 var f=mine.FOUNDRY.state(mine)
 var intro=UI.card(page,"RAMFORGE • from seam to bar","Six metals unlock deeper underground. Collect the depot, then use metal ore + coal at the furnace. Keep bars for machinery or prepare them as Market stock.")
 var row=HBoxContainer.new();intro.add_child(row);tracked(row,"Collect depot",mine.collect,"collect");button(row,"Sell bars at Market",func():close();mine.legacy.commerce.open())
 labels.furnace=label(intro,"",17);progress_bar(intro,"furnace");tracked(intro,"Cancel bar batch • refund materials",mine.FOUNDRY.cancel_forge.bind(mine),"forge_cancel")
 if mine.depth()<20 or not mine.state().job.is_empty():
  var next=UI.card(page,"YOUR NEXT BUILD")
  if mine.depth()<20:label(next,"Next shaft materials: "+full_cost(mine.next_shaft_cost(),mine.material_cost()),17)
  if not mine.state().job.is_empty():tracked(next,"",mine.FOUNDRY.reinforce.bind(mine),"reinforce")
 var grid=GridContainer.new();grid.columns=2;grid.add_theme_constant_override("h_separation",14);grid.add_theme_constant_override("v_separation",12);page.add_child(grid)
 for id in mine.FOUNDRY.METALS:
  var spec=mine.FOUNDRY.METALS[id];var box=UI.card(grid,str(spec.name)+" • shaft "+str(spec.depth),"");box.custom_minimum_size.x=500;box.size_flags_horizontal=Control.SIZE_EXPAND_FILL
  var pictures=HBoxContainer.new();box.add_child(pictures)
  for is_bar in [false,true]:
   var picture=TextureRect.new();picture.texture=mine.FOUNDRY.icon(id,is_bar);picture.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST;picture.custom_minimum_size=Vector2(54,54);picture.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;picture.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;pictures.add_child(picture)
  labels["metal:"+id]=label(pictures,"",16);labels["metal:"+id].size_flags_horizontal=Control.SIZE_EXPAND_FILL
  bars["metal:"+id]=progress_bar(box,"metal:"+id);bars["metal:"+id].max_value=1200;bars["metal:"+id].show_percentage=false
  var fill=StyleBoxFlat.new();fill.bg_color=Color(spec.color);fill.set_corner_radius_all(5);bars["metal:"+id].add_theme_stylebox_override("fill",fill)
  label(box,str(spec.ore)+" "+str(spec.name)+" ore + "+str(spec.coal)+" coal → 1 bar • Market reference "+str(spec.price)+" cash",15)
  var actions=HBoxContainer.new();box.add_child(actions)
  for count in [1,5,10]:
   var b=tracked(actions,"Forge "+str(count)+(" bar" if count==1 else " bars"),mine.FOUNDRY.forge.bind(mine,str(id),count),"forge",[id,count]);var recipe=mine.FOUNDRY.recipe(mine,id,count)
   b.tooltip_text=str(recipe.ore)+" "+str(spec.name)+" ore + "+str(recipe.coal)+" coal • "+time_text(recipe.seconds)+" • collect depot supplies first"
  if mine.depth()<int(spec.depth):label(box,"LOCKED • dig to shaft "+str(spec.depth)+" to discover this seam",15).modulate=Color("#b5a2c9")
func refresh_foundry(stamp:float)->void:
 var f=mine.FOUNDRY.state(mine)
 if labels.has("furnace"):
  var coal=float(preload("res://scripts/mine_geology.gd").state(mine).wallet.coal)
  labels.furnace.text="Furnace needs building at shaft 2 • Coal collected: "+amount(coal) if int(mine.state().levels.smelter)<1 else "Furnace ready • Coal collected: "+amount(coal) if f.job.is_empty() else "Forging "+str(f.job.count)+" "+str(mine.FOUNDRY.METALS[f.job.metal].name)+" bars • "+time_text(float(f.job.end)-stamp)+" remaining"
  if not mine.state().refine.is_empty():labels.furnace.text="Furnace refining ordinary ore for gold • "+time_text(float(mine.state().refine.end)-stamp)
  bars.furnace.value=100 if f.job.is_empty() else completion(float(f.job.end),stamp,float(f.job.seconds))
 for id in mine.FOUNDRY.METALS:
  if labels.has("metal:"+id):
   labels["metal:"+id].text="Collected ore "+amount(float(f.wallet[id]))+" • Bars "+str(int(f.bars[id]))+"\nIn depot "+amount(float(f.stored[id]))+" / 1200 • forged "+str(int(f.forged[id]))
   bars["metal:"+id].value=float(f.stored[id])

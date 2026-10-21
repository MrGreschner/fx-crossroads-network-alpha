extends RefCounted
const UI=preload("res://scripts/studio_ui.gd")
static func button(parent:Node,title:String,action:Callable)->Button:
 var b=Button.new();b.text=title;b.custom_minimum_size.y=40;b.clip_text=true;b.tooltip_text=title;b.size_flags_horizontal=Control.SIZE_EXPAND_FILL;parent.add_child(b);b.pressed.connect(action);return b
static func label(parent:Node,title:String,size:int=17)->Label:
 var l=Label.new();l.text=title;l.add_theme_font_size_override("font_size",size);l.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;l.size_flags_horizontal=Control.SIZE_EXPAND_FILL;parent.add_child(l);return l
static func icon(parent:Node,id:String,stage:int,dimensions:Vector2=Vector2(100,90))->void:
 var image=TextureRect.new();image.texture=preload("res://scripts/source_art.gd").texture("res://assets/seedhouse/"+id+"_"+str(stage)+".svg");image.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;image.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;image.custom_minimum_size=dimensions;parent.add_child(image)
static func refresh(g:RefCounted)->void:g.legacy.render()
static func go(g:RefCounted,page:String)->void:g.page=page;g.inventory_page=0;refresh(g);g.legacy.profile_scroll.set_deferred("scroll_vertical",0)
static func build(g:RefCounted,parent:Node)->void:
 g.labels.clear();var lv=g.level();var state=g.state();var stock=g.seed_summary()
 label(parent,"GARDENING • Lv %d / 100 • %d XP • %d beds • %d Glimmers" % [lv,int(state.xp),g.capacity(),g.legacy.glimmers.balance()],20)
 var summary=label(parent,"SEEDS OWNED: %d • READY TO PLANT: %d • %d types owned • %d / %d types discovered" % [stock.total,stock.ready,stock.types,state.seen.size(),g.crops().size()],17);summary.name="SeedStockSummary";summary.modulate=Color("#c0dcb2")
 if g.page=="beds":
  var bar=ProgressBar.new();bar.show_percentage=false;bar.custom_minimum_size.y=8;bar.value=100 if lv==100 else 100.0*(int(state.xp)-g.threshold(lv))/maxi(1,g.threshold(lv+1)-g.threshold(lv));parent.add_child(bar)
 var tabs=HFlowContainer.new();tabs.name="GardenTabs";parent.add_child(tabs)
 for entry in [["Garden beds","beds"],["Seeds & harvests","inventory"],["Seed shop","shop"],["Mastery tree","tree"],["Giant growers fair","fair"]]:
  var b=button(tabs,entry[0],func():
   if entry[1]=="tree":g.open_tree()
   else:go(g,entry[1]));b.toggle_mode=true;b.set_pressed_no_signal(g.page==entry[1]);b.custom_minimum_size.x=160
 if not g.note.is_empty():label(parent,g.note,16).modulate=Color("#ead19e")
 if g.page=="tree":tree(g,parent);return
 if g.page=="fair":g.fair.build(parent);return
 if g.page in ["inventory","shop"]:inventory(g,parent);return
 label(parent,"Plant one owned seed per bed. The picker lists seeds you can plant now; harvesting creates produce for food, ingredients or sale. Seeds and harvested produce are separate stocks.",16)
 if stock.locked>0:label(parent,"%d owned seeds need a higher Gardening level. Seeds & harvests shows the exact requirements; they remain safely in your stock." % stock.locked,16).modulate=Color("#e1bf8e")
 var grid=GridContainer.new();grid.columns=1 if g.legacy.get_viewport().get_visible_rect().size.x<1000 else 2;grid.size_flags_horizontal=Control.SIZE_EXPAND_FILL;parent.add_child(grid)
 var shown=maxi(g.capacity(),1)
 for i in state.beds.size():
  if not state.beds[i].is_empty():shown=maxi(shown,i+1)
 for i in shown:
  var b:Dictionary=state.beds[i];var card=UI.card(grid,"BED "+str(i+1),"");card.get_parent().custom_minimum_size.x=minf(425,maxf(250,g.legacy.get_viewport().get_visible_rect().size.x-110));card.get_parent().size_flags_horizontal=Control.SIZE_EXPAND_FILL
  if not b.is_empty():icon(card,str(b.seed),2 if g.now()>=float(b.end) else 1)
  var status=label(card,g.bed_text(i));g.labels.append({"label":status,"index":i})
  if b.is_empty():
   if i>=g.capacity():label(card,"Unlock more beds through Gardening levels and mastery.",16);continue
   var ids=g.plantable_seeds();var select=OptionButton.new();select.name="PlantSeedPicker";select.fit_to_longest_item=false;select.custom_minimum_size.y=40;select.size_flags_horizontal=Control.SIZE_EXPAND_FILL;card.add_child(select)
   for id in ids:select.add_item(str(g.crops()[id].name)+" • %d owned • Lv %d" % [g.seed_count(id),int(g.crops()[id].level)])
   if ids.is_empty():
    select.add_item("No seeds ready to plant");select.disabled=true
    label(card,"You own %d seeds, but none can be planted in a normal bed at your current level. Check Seeds & harvests for requirements, or buy a starter seed in Seed shop." % stock.total,16)
    button(card,"Open seed shop",go.bind(g,"shop"));continue
   var detail=HBoxContainer.new();card.add_child(detail)
   var picture=TextureRect.new();picture.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;picture.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;picture.custom_minimum_size=Vector2(88,88);detail.add_child(picture)
   var info=label(detail,"",16);info.name="PlantSeedDetails"
   var plant=button(card,"Plant 1 seed",func():
    if select.selected>=0 and select.selected<ids.size():g.plant(i,str(ids[select.selected]));refresh(g))
   var update=func(_selected:int):
    var id=str(ids[select.selected]);var spec=g.crops()[id]
    picture.texture=preload("res://scripts/source_art.gd").texture("res://assets/seedhouse/"+id+"_2.svg")
    var seconds=maxf(60,float(spec.seconds)*(1-minf(.30,g.bonus("time",str(spec.family)))))
    info.text="%d seeds owned • uses 1\nGardening Lv %d • grows in %s\nHarvest: %s • +%d base XP" % [g.seed_count(id),int(spec.level),g.duration(seconds),str(spec.produce),int(spec.xp)]
    plant.text="Plant 1 • "+str(spec.name);plant.disabled=not g.allowed()
   select.item_selected.connect(update);update.call(0)
  else:
   var ready=g.now()>=float(b.end);var harvest=button(card,"Harvest now" if ready else "Still growing",func():g.harvest(i);refresh(g));harvest.disabled=not ready or not g.allowed();g.labels.back()["button"]=harvest
 var links=HBoxContainer.new();parent.add_child(links);button(links,"View my seed quantities",go.bind(g,"inventory"));button(links,"Browse seed shop",go.bind(g,"shop"))
 label(parent,"Extra beds unlock at levels 5, 15, 30, 50, 75, 90 and 100. Realm scenery, fishing, lodge trips and Conclaves can reveal additional seeds.",15)
static func inventory(g:RefCounted,parent:Node)->void:
 var shop=g.page=="shop"
 label(parent,"ROWAN’S SEED SHOP" if shop else "MY SEEDS & HARVESTS",23)
 label(parent,"Buy seeds here with Glimmers. Each purchase adds 1 seed; quantities update immediately. Other seed types must be found at their listed source." if shop else "Seed quantities are what you can plant. Harvest quantities are produce you can sell, prepare or pack. Buy seeds in the separate Seed shop tab.",16)
 var filters=HFlowContainer.new();parent.add_child(filters)
 var collection=OptionButton.new();collection.custom_minimum_size=Vector2(230,34);collection.size_flags_horizontal=Control.SIZE_EXPAND_FILL;filters.add_child(collection);collection.visible=not shop
 var selections=[["Owned seeds & produce","owned"],["Ready to plant now","ready"],["Discovered seed types","seen"],["All seeds & sources","all"]]
 for i in selections.size():
  collection.add_item(selections[i][0])
  if g.inventory_filter==selections[i][1]:collection.selected=i
 collection.item_selected.connect(func(i):g.inventory_filter=selections[i][1];g.inventory_page=0;refresh(g))
 var families=OptionButton.new();families.custom_minimum_size=Vector2(180,34);families.size_flags_horizontal=Control.SIZE_EXPAND_FILL;filters.add_child(families);var names=["all","orchard","river","roots","flowers"]
 for i in names.size():
  families.add_item("All families" if i==0 else names[i].capitalize())
  if g.family==names[i]:families.selected=i
 families.item_selected.connect(func(i):g.family=names[i];g.inventory_page=0;refresh(g))
 if not shop:button(filters,"Fish bait recipes",g.legacy.game.fishing.open_workshop).custom_minimum_size.y=34
 var eligible=[]
 for id in g.crops():
  var spec=g.crops()[id]
  if g.family!="all" and spec.family!=g.family:continue
  if shop:
   if spec.source!="shop":continue
  else:
   if g.inventory_filter=="owned" and g.seed_count(id)+int(g.state().produce.get(id,0))==0:continue
   if g.inventory_filter=="ready" and id not in g.plantable_seeds():continue
   if g.inventory_filter=="seen" and id not in g.state().seen:continue
  eligible.append(id)
 eligible.sort_custom(func(a,b):return int(g.crops()[a].level)<int(g.crops()[b].level) if int(g.crops()[a].level)!=int(g.crops()[b].level) else str(g.crops()[a].name)<str(g.crops()[b].name))
 if eligible.is_empty():label(parent,"Nothing matches this filter. Try All seeds & sources, or visit Seed shop for starter seeds.",18)
 g.inventory_page=clampi(g.inventory_page,0,maxi(0,(eligible.size()-1)/12))
 var pages=HBoxContainer.new();parent.add_child(pages)
 var prev=button(pages,"Previous",func():g.inventory_page-=1;refresh(g));prev.disabled=g.inventory_page==0;prev.custom_minimum_size.y=30
 label(pages,"Page %d / %d • %d seed types" % [g.inventory_page+1,maxi(1,ceili(eligible.size()/12.0)),eligible.size()],16)
 var next=button(pages,"Next",func():g.inventory_page+=1;refresh(g));next.disabled=(g.inventory_page+1)*12>=eligible.size();next.custom_minimum_size.y=30
 var grid=GridContainer.new();grid.columns=1 if g.legacy.get_viewport().get_visible_rect().size.x<1000 else 2;grid.size_flags_horizontal=Control.SIZE_EXPAND_FILL;parent.add_child(grid)
 for id in eligible.slice(g.inventory_page*12,(g.inventory_page+1)*12):
  var spec=g.crops()[id];var seed_stock=g.seed_count(id);var produce_stock=int(g.state().produce.get(id,0))
  var card=UI.card(grid,str(spec.name),"%s • Gardening Lv %d • %s" % [str(spec.get("rarity","Common")),int(spec.level),g.duration(float(spec.seconds))]);card.get_parent().custom_minimum_size.x=minf(425,maxf(250,g.legacy.get_viewport().get_visible_rect().size.x-110));card.get_parent().size_flags_horizontal=Control.SIZE_EXPAND_FILL
  var quantities=label(card,"SEEDS OWNED: %d     HARVESTS OWNED: %d" % [seed_stock,produce_stock],20);quantities.name="SeedQuantity_"+str(id);quantities.modulate=Color("#c1ddb2")
  var badge=label(card,g.seed_status(id),16);badge.modulate=Color("#c1ddb2") if id in g.plantable_seeds() else Color("#e3be89")
  var art=HFlowContainer.new();card.add_child(art)
  for stage in [0,2,3]:
   var column=VBoxContainer.new();art.add_child(column);icon(column,str(id),stage,Vector2(110,80));label(column,("Seeds ×%d" % seed_stock) if stage==0 else ("Harvests ×%d" % produce_stock) if stage==3 else "Grown appearance",13)
  label(card,str(spec.description),15);label(card,"Source: "+g.seed_source(id),15)
  label(card,"+%d base harvest XP • %d Glimmers per produce • prepares %s ingredients" % [int(spec.xp),int(spec.price),str(spec.ingredient)],14)
  if shop:
   var buy=button(card,"Buy 1 seed • %d Glimmers" % int(spec.seed_price),func():g.buy_seed(str(id));refresh(g));buy.name="BuySeed_"+str(id);buy.disabled=g.level()<int(spec.level) or not g.allowed() or g.legacy.glimmers.balance()<int(spec.seed_price)
   if g.level()<int(spec.level):label(card,"Shop unlocks at Gardening Lv %d." % int(spec.level),15)
   continue
  if id in g.plantable_seeds():button(card,"Choose a garden bed",go.bind(g,"beds"))
  if produce_stock<=0:continue
  var row=HFlowContainer.new();card.add_child(row)
  button(row,"Sell 1 produce",func():g.use_produce(str(id),"sell");refresh(g)).disabled=not g.allowed()
  button(row,"Prepare 1 ingredient",func():g.use_produce(str(id),"ingredients");refresh(g)).disabled=not g.allowed()
  if not str(spec.food).is_empty():button(row,"Pack 1 as food",func():g.use_produce(str(id),"food");refresh(g)).disabled=not g.allowed() or not g.legacy.game.provisions.packed.is_empty()
static func tree(g:RefCounted,parent:Node)->void:
 label(parent,"Explore all 64 perks in one connected tree. Wheel to zoom; drag to pan.",18)
 button(parent,"Open full Gardening mastery tree",g.open_tree)

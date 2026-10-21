extends RefCounted
const UI=preload("res://scripts/studio_ui.gd")
static func button(parent:Node,title:String,action:Callable)->Button:
 var b=Button.new();b.text=title;b.custom_minimum_size.y=40;b.size_flags_horizontal=Control.SIZE_EXPAND_FILL;parent.add_child(b);b.pressed.connect(action);return b
static func label(parent:Node,title:String,size:int=17)->Label:
 var l=Label.new();l.text=title;l.add_theme_font_size_override("font_size",size);l.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;l.size_flags_horizontal=Control.SIZE_EXPAND_FILL;parent.add_child(l);return l
static func icon(parent:Node,id:String,stage:int,dimensions:Vector2=Vector2(100,90))->void:
 var image=TextureRect.new();image.texture=preload("res://scripts/source_art.gd").texture("res://assets/seedhouse/"+id+"_"+str(stage)+".svg");image.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;image.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;image.custom_minimum_size=dimensions;parent.add_child(image)
static func refresh(g:RefCounted)->void:g.legacy.render()
static func build(g:RefCounted,parent:Node)->void:
 g.labels.clear();var lv=g.level();var state=g.state()
 label(parent,"GARDENING • Lv %d / 100 • %d XP • %d beds • %d / %d seeds • %d Glimmers" % [lv,int(state.xp),g.capacity(),state.seen.size(),g.crops().size(),g.legacy.glimmers.balance()],18)
 if g.page=="beds":
  var bar=ProgressBar.new();bar.show_percentage=false;bar.custom_minimum_size.y=8;bar.value=100 if lv==100 else 100.0*(int(state.xp)-g.threshold(lv))/maxi(1,g.threshold(lv+1)-g.threshold(lv));parent.add_child(bar)
 var tabs=HFlowContainer.new();parent.add_child(tabs)
 for entry in [["Garden beds","beds"],["Seeds & harvests","inventory"],["Mastery tree","tree"],["Giant growers fair","fair"]]:
  var b=button(tabs,entry[0],func():
   if entry[1]=="tree":g.open_tree()
   else:g.page=entry[1];refresh(g));b.toggle_mode=true;b.set_pressed_no_signal(g.page==entry[1]);b.custom_minimum_size.x=190
 if g.page=="tree":tree(g,parent);return
 if g.page=="fair":g.fair.build(parent);return
 if g.page=="inventory":inventory(g,parent);return
 label(parent,"One seed per bed. Extra beds unlock at levels 5, 15, 30, 50, 75, 90 and 100. Harvests become food, ingredients or Glimmers.",15)
 var grid=GridContainer.new();grid.columns=2;grid.size_flags_horizontal=Control.SIZE_EXPAND_FILL;parent.add_child(grid)
 var shown=maxi(g.capacity(),1)
 for i in state.beds.size():
  if not state.beds[i].is_empty():shown=maxi(shown,i+1)
 for i in shown:
  var b:Dictionary=state.beds[i];var card=UI.card(grid,"BED "+str(i+1),"");card.get_parent().custom_minimum_size.x=425
  if not b.is_empty():icon(card,str(b.seed),2 if g.now()>=float(b.end) else 1)
  var status=label(card,g.bed_text(i));g.labels.append({"label":status,"index":i})
  if b.is_empty():
   var select=OptionButton.new();select.size_flags_horizontal=Control.SIZE_EXPAND_FILL;card.add_child(select);var ids=[]
   for id in g.crops():
    if int(state.seeds.get(id,0))>0 and lv>=int(g.crops()[id].level) and g.crops()[id].source!="seasonal":ids.append(id);select.add_item(str(g.crops()[id].name)+" ×"+str(int(state.seeds[id])))
   if ids.is_empty():select.add_item("No plantable seeds • visit Seeds & harvests")
   button(card,"Plant selected seed",func():
    if not ids.is_empty():g.plant(i,str(ids[select.selected]));refresh(g)).disabled=ids.is_empty() or i>=g.capacity() or not g.allowed()
  else:
   button(card,"Harvest when ready",func():g.harvest(i);refresh(g)).disabled=not g.allowed()
 label(parent,"New seeds: look for satchels near town scenery and realm trees or houses. Fishing and defeated Overcharge Conclaves can reveal rare seeds. Finding a high-level seed lets you save it until you can grow it.",16)
 button(parent,"Browse seeds, sources & harvested goods",func():g.page="inventory";refresh(g))
static func inventory(g:RefCounted,parent:Node)->void:
 var filters=HBoxContainer.new();parent.add_child(filters)
 var collection=OptionButton.new();collection.custom_minimum_size=Vector2(230,34);collection.size_flags_horizontal=Control.SIZE_EXPAND_FILL;filters.add_child(collection)
 var selections=[["Owned seeds & produce","owned"],["Rowan’s shop","shop"],["All seed discoveries","all"]]
 for i in selections.size():
  collection.add_item(selections[i][0])
  if g.inventory_filter==selections[i][1]:collection.selected=i
 collection.item_selected.connect(func(i):g.inventory_filter=selections[i][1];g.inventory_page=0;refresh(g))
 var families=OptionButton.new();families.custom_minimum_size=Vector2(180,34);families.size_flags_horizontal=Control.SIZE_EXPAND_FILL;filters.add_child(families);var names=["all","orchard","river","roots","flowers"]
 for i in names.size():
  families.add_item("All families" if i==0 else names[i].capitalize())
  if g.family==names[i]:families.selected=i
 families.item_selected.connect(func(i):g.family=names[i];g.inventory_page=0;refresh(g))
 button(filters,"Fish bait recipes",g.legacy.game.fishing.open_workshop).custom_minimum_size.y=34
 var eligible=[]
 for id in g.crops():
  var spec=g.crops()[id]
  if g.family!="all" and spec.family!=g.family:continue
  if g.inventory_filter=="owned" and int(g.state().seeds.get(id,0))+int(g.state().produce.get(id,0))==0:continue
  if g.inventory_filter=="shop" and spec.source!="shop":continue
  eligible.append(id)
 g.inventory_page=clampi(g.inventory_page,0,maxi(0,(eligible.size()-1)/12))
 var pages=HBoxContainer.new();parent.add_child(pages)
 var prev=button(pages,"Previous",func():g.inventory_page-=1;refresh(g));prev.disabled=g.inventory_page==0;prev.custom_minimum_size.y=30
 label(pages,"Page %d / %d • %d plants" % [g.inventory_page+1,maxi(1,ceili(eligible.size()/12.0)),eligible.size()],16)
 var next=button(pages,"Next",func():g.inventory_page+=1;refresh(g));next.disabled=(g.inventory_page+1)*12>=eligible.size();next.custom_minimum_size.y=30
 var grid=GridContainer.new();grid.columns=2;grid.size_flags_horizontal=Control.SIZE_EXPAND_FILL;parent.add_child(grid)
 for id in eligible.slice(g.inventory_page*12,(g.inventory_page+1)*12):
  var spec=g.crops()[id]
  var card=UI.card(grid,str(spec.name),"%s • Lv %d • %s • Seeds %d • Harvests %d" % [str(spec.get("rarity","Common")),int(spec.level),g.duration(float(spec.seconds)),int(g.state().seeds.get(id,0)),int(g.state().produce.get(id,0))]);card.get_parent().custom_minimum_size.x=425
  var art=HBoxContainer.new();card.add_child(art)
  for stage in [0,2,3]:
   var column=VBoxContainer.new();art.add_child(column);icon(column,str(id),stage,Vector2(115,90));label(column,{0:"Seed",2:"Mature plant",3:"Harvest"}[stage],13)
  label(card,str(spec.description)+(" Realm: "+str(g.legacy.game.realms.get(spec.realm,{}).get("name",spec.realm))+"." if not str(spec.realm).is_empty() else ""),15)
  label(card,"+%d harvest XP • %d Glimmers per produce • prepares %s ingredients" % [int(spec.xp),int(spec.price),str(spec.ingredient)],14)
  if spec.source=="shop":button(card,"Buy seed • %d Glimmers" % int(spec.seed_price),func():g.buy_seed(str(id));refresh(g)).disabled=g.level()<int(spec.level) or not g.allowed()
  var row=HFlowContainer.new();card.add_child(row);var stock=int(g.state().produce.get(id,0))
  button(row,"Sell 1",func():g.use_produce(str(id),"sell");refresh(g)).disabled=stock<1 or not g.allowed()
  button(row,"Prepare ingredient",func():g.use_produce(str(id),"ingredients");refresh(g)).disabled=stock<1 or not g.allowed()
  if not str(spec.food).is_empty():button(row,"Pack as food",func():g.use_produce(str(id),"food");refresh(g)).disabled=stock<1 or not g.allowed() or not g.legacy.game.provisions.packed.is_empty()
static func tree(g:RefCounted,parent:Node)->void:
 label(parent,"Explore all 64 perks in one connected tree. Wheel to zoom; drag to pan.",18)
 button(parent,"Open full Gardening mastery tree",g.open_tree)

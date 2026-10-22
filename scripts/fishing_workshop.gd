extends CanvasLayer
const UI=preload("res://scripts/studio_ui.gd")
const E=preload("res://scripts/fishing_ecology.gd")
const P=preload("res://scripts/fishing_progress.gd")
var fishing:Node
var panel:PanelContainer
var notice=""
var previous=""
var selected_tab=0
var pot_labels:Array=[]
var tree_zoom=.9
var tree_branch=0
func setup(f:Node)->void:
 fishing=f;layer=92;previous=f.menu_key();f.game.set("shop_open" if f.multi else "menu","fishing_workshop");f.game.mobile.reset_controls();build()
func close()->void:
 fishing.game.set("shop_open" if fishing.multi else "menu",previous)
 if previous=="legacy":fishing.game.legacy.render()
 fishing.workshop=null;queue_free()
func build()->void:
 pot_labels.clear()
 for child in get_children():remove_child(child);child.queue_free()
 var shade=ColorRect.new();shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);shade.color=Color(.02,.05,.08,.96);add_child(shade)
 panel=PanelContainer.new();UI.apply(panel);add_child(panel)
 var col=VBoxContainer.new();panel.add_child(col);var top=HBoxContainer.new();col.add_child(top)
 var compact=selected_tab==1
 fishing.label(top,"RIPPLE & REEL • "+("FISHING MASTERY" if compact else "ANGLER'S WORKSHOP"),20 if compact else 24);fishing.button(top,"Close",close)
 var prog=fishing.records().progress;var level=prog.level();var xp=int(prog.state().xp)
 fishing.label(col,"Fishing level %d / 80 • %d XP • %d Glimmers" % [level,xp,fishing.game.legacy.glimmers.balance()],16)
 if not compact:
  fishing.label(col,prog.title()+" • rarity weight +%.1f%% • Bag %d/%d" % [10.0*clampf((level-1)/39.0,0,1),fishing.records().state().kept.size(),fishing.records().capacity()],15)
  var bar=ProgressBar.new();bar.custom_minimum_size.y=14;bar.show_percentage=false;bar.value=100 if level==P.MAX_LEVEL else 100.0*(xp-P.threshold(level))/maxi(1,P.threshold(level+1)-P.threshold(level));col.add_child(bar)
  fishing.label(col,notice if not notice.is_empty() else "All rod fish are possible from level one. Unlock more methods and fish bait as you grow. Keep or release: both earn XP.",15)
 elif not notice.is_empty():fishing.label(col,notice,15)
 var tabs=TabContainer.new();tabs.size_flags_vertical=Control.SIZE_EXPAND_FILL;col.add_child(tabs)
 for name in ["Gear & fish bait","Mastery tree","Baskets","Cosmetics"]:
  var margin=MarginContainer.new();margin.name=name;tabs.add_child(margin)
  margin.add_theme_constant_override("margin_top",16);margin.add_theme_constant_override("margin_bottom",8)
  var scroll=ScrollContainer.new();scroll.size_flags_vertical=Control.SIZE_EXPAND_FILL;scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_AUTO if name=="Mastery tree" else ScrollContainer.SCROLL_MODE_DISABLED;margin.add_child(scroll)
  var body=VBoxContainer.new();body.size_flags_horizontal=Control.SIZE_EXPAND_FILL;body.add_theme_constant_override("separation",12);scroll.add_child(body)
  var touch=preload("res://scripts/touch_list_scroll.gd").attach(scroll)
  touch.horizontal_drag=name=="Mastery tree"
  match name:
   "Gear & fish bait":gear_ui(body)
   "Mastery tree":tree_ui(body)
   "Baskets":pot_ui(body)
   "Cosmetics":cosmetic_ui(body)
 tabs.current_tab=selected_tab;tabs.tab_changed.connect(func(i:int):
  selected_tab=i;call_deferred("build")
  if i==1:fishing.open_mastery())
 fit()
func feedback(value:String)->void:notice=value;build()
func gear_ui(body:Node)->void:
 if not fishing.multi:
  var sea=UI.card(body,"DEEP SEA ROD • COASTAL VOYAGES","Permanent equipment • 1,200 Glimmers • Unlocks the river pier boat route to saltwater habitats, sea cages and the hidden Night Island.")
  var owned=bool(fishing.records().state().get("deep_sea_rod",false))
  var buy=fishing.button(sea,"Owned ✓" if owned else "Buy Deep Sea Rod • 1,200 Glimmers",func():fishing.game.voyage.purchase();feedback(fishing.game.message))
  buy.disabled=owned or fishing.game.mode!="town"
 var p=fishing.records().progress
 fishing.label(body,"ROD • patient casts and full XP. NET • a quick timed scoop for small fish and creatures. BASKET • five fish after 20 real minutes, then stops. Perks improve fill time and capacity up to ten. Start with a free rod and bare hook. Buy a net at level 5 and baskets at level 10. Equipment is permanent; fish bait is consumed.",17)
 var row=HBoxContainer.new();body.add_child(row)
 for method in ["rod","net","pot"]:
  var b=fishing.button(row,method.capitalize()+(" ✓" if p.state().method==method else ""),func():p.state().method=method;fishing.records().save();feedback("Selected "+method+". Return to a shore marker."));b.disabled=not p.method_unlocked(method)
 for id in P.GEAR:
  var spec=P.GEAR[id];var box=UI.card(body,str(spec.name),"Fishing level %d • %d Glimmers • %s" % [spec.level,spec.cost,"owned" if p.state().gear.get(id,false) else "not owned"])
  var buy=fishing.button(box,"Owned" if p.state().gear.get(id,false) else "Buy equipment",func():feedback(p.buy_gear(id)));buy.disabled=p.level()<int(spec.level) or bool(p.state().gear.get(id,false))
 if not fishing.multi and fishing.game.town_life.events.active("visitors",fishing.game.town_life.calendar):
  var fruit=UI.card(body,"Faraway Flavours • visiting stall","Sunstar Fruit • 12 CC • packs into your food slot. Monday & Thursday, 10:00–15:00.")
  fishing.button(fruit,"Buy Sunstar Fruit",func():fishing.game.provisions.buy("sunstar_fruit");feedback(fishing.game.message))
 for id in E.BAITS:
  var spec=E.BAITS[id];var box=UI.card(body,spec.name+(" • unlimited" if id=="basic" else " • "+str(p.state().bait.get(id,0))+" in box"),spec.description)
  if id in ["honeygrain","moonmoth","saltflash","kelp_crumble","roe"]:
   var art=TextureRect.new();art.texture=preload("res://scripts/source_art.gd").texture("res://assets/fishing/bait_"+id+".svg");art.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;art.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;art.custom_minimum_size=Vector2(80,64);box.add_child(art)
  var controls=HFlowContainer.new();box.add_child(controls)
  var equip=fishing.button(controls,"Equip"+(" ✓" if p.state().selected_bait==id else ""),func():p.state().selected_bait=id;fishing.records().save();feedback("Selected "+str(spec.name)));equip.disabled=not p.bait_unlocked(id) or (id!="basic" and int(p.state().bait.get(id,0))<=0)
  if not p.bait_unlocked(id):fishing.label(box,"Unlocks at fishing level %d" % int(P.BAIT_LEVELS[id]),16)
  if id!="basic":
   var names=[]
   for ingredient in spec.needs:names.append(str(spec.needs[ingredient])+" "+str(preload("res://scripts/lodge_catalog.gd").INGREDIENTS[ingredient].name))
   if spec.has("fish_source"):names.append("1 ordinary Common/Uncommon kept rod fish (not trophy/favourite/displayed)")
   fishing.label(box,"Recipe: "+" + ".join(names)+" → "+str((8 if p.has("cook") else 6)+int(p.perk_bonus("bait_yield")))+" fish bait",15)
   var craft=fishing.button(controls,"Craft batch",func():feedback(p.craft(id)));craft.disabled=not p.bait_unlocked(id)
   var buy=fishing.button(controls,"Buy 3 • %d Glimmers" % int(spec.cost),func():feedback(p.buy(id,fishing.game)));buy.disabled=not p.bait_unlocked(id)
 if p.bait_unlocked("scraps") and not fishing.records().state().kept.is_empty():
  var scraps=UI.card(body,"Recycle a kept catch into River Scraps","This releases the chosen specimen and clears its aquarium/favourite slots. Its discovery record remains.")
  var pick=OptionButton.new();scraps.add_child(pick)
  for catch in fishing.records().state().kept:pick.add_item(str(fishing.C.fish()[catch.species].name)+" • %.2f kg" % float(catch.kg))
  fishing.button(scraps,"Make 6 scraps from selected catch…",func():
   var catch_id=str(fishing.records().state().kept[pick.selected].id)
   var dialog=ConfirmationDialog.new();dialog.title="Turn this catch into fish bait?";dialog.dialog_text="The kept specimen will be released from your collection and displays. Your journal remains.";add_child(dialog)
   dialog.confirmed.connect(func():
    if int(p.state().bait.scraps)>990:dialog.queue_free();feedback("Your fish bait box is full.");return
    if fishing.records().specimen(catch_id).is_empty():dialog.queue_free();return
    fishing.records().release(catch_id);p.state().bait.scraps=int(p.state().bait.scraps)+6;fishing.records().save();dialog.queue_free();feedback("Made six River Scraps."))
   dialog.canceled.connect(dialog.queue_free);dialog.popup_centered(Vector2i(460,190)))
 fishing.label(body,"Gatherers' Lodge → worms, herbs and insects. Seed House harvests → two herb/petal ingredients in addition to food. Sell catches at the Sales counter inside Ripple & Reel → buy consumable fish bait here. Profitable Market days earn a daily Glimmer reward. Special fish bait shifts species groups; it never unlocks a level-gated fish.",16)
func tree_ui(body:Node)->void:
 var prog=fishing.records().progress
 fishing.label(body,"%d points available • 60 perks across six connected branches" % prog.available_points(),20)
 fishing.label(body,"One full tree. Zoom with the mouse wheel or + / −, drag to explore, then select a badge for its details.",16)
 fishing.button(body,"Open full Fishing mastery tree",fishing.open_mastery)
func pot_ui(body:Node)->void:
 if not fishing.multi and fishing.game.get("voyage")!=null and fishing.game.voyage.active:
  fishing.label(body,"Voyage cages are shown on the boat chart. Anchor near a marker to deploy or recover. Their catches remain unbanked until you return safely. Town baskets wait in town.",18);return
 var p=fishing.records().progress;var now=E.context(fishing.game).utc
 fishing.label(body,"%d / %d baskets placed. Cast a basket at a shore marker, then claim here from any location. New baskets hold %d fish before they stop. Its catches are determined for its ready time, not your collection time. Dawn baskets must finish before 06:00." % [p.state().pots.size(),p.basket_limit(),p.basket_capacity()],17)
 fishing.label(body,p.basket_summary(now),18)
 for i in p.state().pots.size():
  var pot=p.state().pots[i];var ready=now>=float(pot.ready)
  var box=UI.card(body,fishing.basket_location(str(pot.pool)),"%d fish ready to collect" % p.basket_count(pot) if ready else "%d real minutes remaining" % ceili((float(pot.ready)-now)/60))
  var countdown=fishing.label(box,"",17)
  if ready:fishing.picture(box,str(pot.catch.species),Vector2(130,70));fishing.label(box,str(fishing.C.fish()[pot.catch.species].name)+" • %.2f kg" % float(pot.catch.kg),18)
  var row=HBoxContainer.new();box.add_child(row)
  var b=fishing.button(row,"Inspect catch",func():fishing.open_basket(i));b.disabled=not ready
  if ready:
   fishing.button(row,"Keep all (%d)" % p.basket_count(pot),func():feedback(p.claim_all(i,now,true)))
   fishing.button(row,"Release all • +%d%% XP" % roundi(p.release_bonus()*100),func():feedback(p.claim_all(i,now,false)))
  pot_labels.append({"label":countdown,"ready":float(pot.ready),"button":b})
  fishing.button(row,"Retrieve basket…",func():
   var dialog=ConfirmationDialog.new();dialog.title="Retrieve this basket?";dialog.dialog_text="This cancels the basket and discards its catch. Fish bait is not refunded. Collect & keep or Collect & release to earn catch XP instead.";add_child(dialog)
   dialog.confirmed.connect(func():p.state().pots.remove_at(i);fishing.records().save();dialog.queue_free();feedback("Basket retrieved."));dialog.canceled.connect(dialog.queue_free);dialog.popup_centered(Vector2i(460,190)))
func cosmetic_ui(body:Node)->void:
 var p=fishing.records().progress
 for milestone in P.COSMETICS:
  var spec=P.COSMETICS[milestone];var box=UI.card(body,"Level %d • %s" % [milestone,spec.name],"Appearance only: rod, float and water glints. Your fishing title appears in this workshop and catch journal.")
  var b=fishing.button(box,"Equip"+(" ✓" if p.state().cosmetic==spec.id else ""),func():p.state().cosmetic=spec.id;fishing.records().save();feedback("Equipped "+str(spec.name)));b.disabled=p.level()<int(milestone);b.modulate=Color(str(spec.color))
func _process(_delta:float)->void:
 if is_instance_valid(panel):fit()
 var now=E.context(fishing.game).utc
 for item in pot_labels:
  if not is_instance_valid(item.label):continue
  var left=maxi(0,ceili(item.ready-now));item.label.text="READY • catch waiting!" if left==0 else "Ready in %02d:%02d" % [left/60,left%60];item.button.disabled=left>0
func _unhandled_input(event:InputEvent)->void:
 if event is InputEventKey and event.pressed and event.keycode==KEY_ESCAPE:close();get_viewport().set_input_as_handled()

func fit()->void:
 if not is_instance_valid(panel):return
 var v=fishing.game.get_viewport_rect().size
 panel.scale=Vector2.ONE;panel.size=Vector2(minf(1000,v.x-24),minf(850 if selected_tab==1 else 650,v.y-24));panel.position=(v-panel.size)*.5

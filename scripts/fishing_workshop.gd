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
  fishing.label(col,notice if not notice.is_empty() else "All rod fish are possible from level one. Unlock more methods and bait as you grow. Keep or release: both earn XP.",15)
 elif not notice.is_empty():fishing.label(col,notice,15)
 var tabs=TabContainer.new();tabs.size_flags_vertical=Control.SIZE_EXPAND_FILL;col.add_child(tabs)
 for name in ["Gear & bait","Mastery tree","Baskets","Cosmetics","Sell goods"]:
  var margin=MarginContainer.new();margin.name=name;tabs.add_child(margin)
  margin.add_theme_constant_override("margin_top",16);margin.add_theme_constant_override("margin_bottom",8)
  var scroll=ScrollContainer.new();scroll.size_flags_vertical=Control.SIZE_EXPAND_FILL;scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_AUTO if name=="Mastery tree" else ScrollContainer.SCROLL_MODE_DISABLED;margin.add_child(scroll)
  var body=VBoxContainer.new();body.size_flags_horizontal=Control.SIZE_EXPAND_FILL;body.add_theme_constant_override("separation",12);scroll.add_child(body)
  var touch=preload("res://scripts/touch_list_scroll.gd").attach(scroll)
  touch.horizontal_drag=name=="Mastery tree"
  match name:
   "Gear & bait":gear_ui(body)
   "Mastery tree":tree_ui(body)
   "Baskets":pot_ui(body)
   "Cosmetics":cosmetic_ui(body)
   "Sell goods":preload("res://scripts/glimmer_exchange.gd").build(body,fishing,feedback)
 tabs.current_tab=selected_tab;tabs.tab_changed.connect(func(i:int):selected_tab=i;call_deferred("build"))
 fit()
func feedback(value:String)->void:notice=value;build()
func gear_ui(body:Node)->void:
 var p=fishing.records().progress
 fishing.label(body,"ROD • patient casts and full XP. NET • a quick timed scoop for small fish and creatures. BASKET • one catch after 13–20 real minutes, then stops. Start with a free rod and bare hook. Buy a net at level 5 and baskets at level 10. Equipment is permanent; bait is consumed.",17)
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
  var controls=HFlowContainer.new();box.add_child(controls)
  var equip=fishing.button(controls,"Equip"+(" ✓" if p.state().selected_bait==id else ""),func():p.state().selected_bait=id;fishing.records().save();feedback("Selected "+str(spec.name)));equip.disabled=not p.bait_unlocked(id) or (id!="basic" and int(p.state().bait.get(id,0))<=0)
  if not p.bait_unlocked(id):fishing.label(box,"Unlocks at fishing level %d" % int(P.BAIT_LEVELS[id]),16)
  if id!="basic":
   var names=[]
   for ingredient in spec.needs:names.append(str(spec.needs[ingredient])+" "+str(preload("res://scripts/lodge_catalog.gd").INGREDIENTS[ingredient].name))
   fishing.label(box,"Recipe: "+" + ".join(names)+" → "+str((8 if p.has("cook") else 6)+int(p.perk_bonus("bait_yield")))+" bait",15)
   var craft=fishing.button(controls,"Craft batch",func():feedback(p.craft(id)));craft.disabled=not p.bait_unlocked(id)
   var buy=fishing.button(controls,"Buy 3 • %d Glimmers" % int(spec.cost),func():feedback(p.buy(id,fishing.game)));buy.disabled=not p.bait_unlocked(id)
 if p.bait_unlocked("scraps") and not fishing.records().state().kept.is_empty():
  var scraps=UI.card(body,"Recycle a kept catch into River Scraps","This releases the chosen specimen and clears its aquarium/favourite slots. Its discovery record remains.")
  var pick=OptionButton.new();scraps.add_child(pick)
  for catch in fishing.records().state().kept:pick.add_item(str(fishing.C.fish()[catch.species].name)+" • %.2f kg" % float(catch.kg))
  fishing.button(scraps,"Make 6 scraps from selected catch…",func():
   var catch_id=str(fishing.records().state().kept[pick.selected].id)
   var dialog=ConfirmationDialog.new();dialog.title="Turn this catch into bait?";dialog.dialog_text="The kept specimen will be released from your collection and displays. Your journal remains.";add_child(dialog)
   dialog.confirmed.connect(func():
    if int(p.state().bait.scraps)>990:dialog.queue_free();feedback("Your bait box is full.");return
    if fishing.records().specimen(catch_id).is_empty():dialog.queue_free();return
    fishing.records().release(catch_id);p.state().bait.scraps=int(p.state().bait.scraps)+6;fishing.records().save();dialog.queue_free();feedback("Made six River Scraps."))
   dialog.canceled.connect(dialog.queue_free);dialog.popup_centered(Vector2i(460,190)))
 fishing.label(body,"Gatherers' Lodge → worms, herbs and insects. Seed House harvests → two herb/petal ingredients in addition to food. Sell catches and gathered/grown ingredients in Sell goods → buy consumable bait here. Profitable Market days earn a daily Glimmer reward. Special bait shifts species groups; it never unlocks a level-gated fish.",16)
func tree_ui(body:Node)->void:
 var prog=fishing.records().progress
 fishing.label(body,"%d points available • %d / %d earned • 60 perks across six branches" % [prog.available_points(),prog.earned_points(),P.MAX_POINTS],19)
 fishing.label(body,"1 point every 3 levels through level 78. Click a node for its effect. Choose a fork; learn both forks for its crown.",15)
 var branches=HFlowContainer.new();body.add_child(branches)
 for index in P.BRANCHES.size():
  var branch=P.BRANCHES[index];var pick=fishing.button(branches,str(branch.name)+(" ✓" if tree_branch==index else ""),func():tree_branch=index;build());pick.modulate=Color(branch.color);pick.custom_minimum_size.y=34
 var row=HBoxContainer.new();body.add_child(row)
 fishing.button(row,"Reset • %d Glimmers…" % prog.reset_cost(),func():
  var d=ConfirmationDialog.new();d.title="Reset fishing mastery?";d.dialog_text="Refund all %d spent points for %d Glimmers. XP, equipment and fish stay yours. Collect or retrieve all baskets first. Each reset increases the next price by 250, up to 2,500 Glimmers." % [prog.state().talents.size(),prog.reset_cost()];add_child(d)
  d.confirmed.connect(func():d.queue_free();feedback(prog.reset_tree()));d.canceled.connect(d.queue_free);d.popup_centered(Vector2i(530,235)))
 var wrapper=Control.new();wrapper.custom_minimum_size=preload("res://scripts/fishing_tree.gd").CANVAS*tree_zoom
 var tree=preload("res://scripts/fishing_tree.gd").new();wrapper.add_child(tree);tree.branch_index=tree_branch;tree.setup(prog);tree.scale=Vector2.ONE*tree_zoom
 fishing.button(row,"−",func():tree_zoom=maxf(.65,tree_zoom-.15);tree.scale=Vector2.ONE*tree_zoom;wrapper.custom_minimum_size=preload("res://scripts/fishing_tree.gd").CANVAS*tree_zoom)
 fishing.label(row,"Zoom • drag/scroll",14)
 fishing.button(row,"+",func():tree_zoom=minf(1.6,tree_zoom+.15);tree.scale=Vector2.ONE*tree_zoom;wrapper.custom_minimum_size=preload("res://scripts/fishing_tree.gd").CANVAS*tree_zoom)
 fishing.button(row,"Overview",func():tree_zoom=.7;tree.scale=Vector2.ONE*tree_zoom;wrapper.custom_minimum_size=preload("res://scripts/fishing_tree.gd").CANVAS*tree_zoom)
 for control in row.get_children():
  if control is Button:control.size_flags_horizontal=Control.SIZE_SHRINK_BEGIN
 var center=func():tree.position.x=maxf(0,(wrapper.size.x-preload("res://scripts/fishing_tree.gd").CANVAS.x*tree_zoom)*.5)
 wrapper.resized.connect(center);center.call()
 body.add_child(wrapper)
 tree.selected.connect(func(id:String):
  var spec=P.TALENTS[id];var reason=prog.learn_reason(id)
  var d=ConfirmationDialog.new();d.title=str(spec.name);d.dialog_text=str(spec.text)+"\n\n"+("Learn for 1 point?" if reason.is_empty() else reason)
  d.get_ok_button().text="Learn • 1 point";d.get_ok_button().disabled=not reason.is_empty();add_child(d)
  d.confirmed.connect(func():
   var learned=prog.choose(id);d.queue_free();feedback("Learned "+str(spec.name) if learned else prog.learn_reason(id)))
  d.canceled.connect(d.queue_free);d.popup_centered(Vector2i(500,215)))
func pot_ui(body:Node)->void:
 var p=fishing.records().progress;var now=E.context(fishing.game).utc
 fishing.label(body,"%d / %d baskets placed. Cast a basket at a shore marker, then claim here from any location. The catch is determined for its ready time, not your collection time. Dawn baskets must finish before 06:00." % [p.state().pots.size(),p.basket_limit()],17)
 fishing.label(body,p.basket_summary(now),18)
 for i in p.state().pots.size():
  var pot=p.state().pots[i];var ready=now>=float(pot.ready)
  var box=UI.card(body,str(fishing.C.pools()[pot.pool].name),"Ready to collect" if ready else "%d real minutes remaining" % ceili((float(pot.ready)-now)/60))
  var countdown=fishing.label(box,"",17)
  if ready:fishing.picture(box,str(pot.catch.species),Vector2(130,70));fishing.label(box,str(fishing.C.fish()[pot.catch.species].name)+" • %.2f kg" % float(pot.catch.kg),18)
  var row=HBoxContainer.new();box.add_child(row)
  var b=fishing.button(row,"Inspect catch",func():fishing.open_basket(i));b.disabled=not ready
  pot_labels.append({"label":countdown,"ready":float(pot.ready),"button":b})
  fishing.button(row,"Retrieve basket…",func():
   var dialog=ConfirmationDialog.new();dialog.title="Retrieve this basket?";dialog.dialog_text="This cancels the basket and discards its catch. Bait is not refunded. Collect & keep or Collect & release to earn catch XP instead.";add_child(dialog)
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

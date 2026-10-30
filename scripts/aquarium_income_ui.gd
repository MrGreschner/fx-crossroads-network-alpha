extends CanvasLayer
const UI=preload("res://scripts/studio_ui.gd")
const C=preload("res://scripts/fishing_catalog.gd")
const CARDS=preload("res://scripts/fish_collection_ui.gd")
var fishing:Node
var panel:PanelContainer
var summary:Label
var notice:Label
var explanation:Label
var compact=false
var claim:Button
var clock=0.0
func setup(owner:Node)->void:
 fishing=owner;layer=94
 var shade=ColorRect.new();shade.color=Color(.02,.05,.07,.88);shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);add_child(shade)
 panel=PanelContainer.new();UI.apply(panel);add_child(panel)
 rebuild()
func rebuild()->void:
 compact=false
 for child in panel.get_children():panel.remove_child(child);child.queue_free()
 var col=VBoxContainer.new();col.add_theme_constant_override("separation",10);panel.add_child(col)
 var header=HBoxContainer.new();col.add_child(header);CARDS.text(header,"RIPPLE & REEL • AQUARIUM TAKINGS",23,Color("#f3dd9d"));CARDS.action(header,"Close",close,85)
 summary=CARDS.text(col,"",20,Color("#ffe0a0"))
 explanation=CARDS.text(col,"Townsfolk pay to see remarkable catches. Rarity and size increase each exhibit’s appeal; normal common catches earn nothing. Size is compared with its own species, so even a small fish can be a trophy.",15)
 var bar=HBoxContainer.new();col.add_child(bar);claim=CARDS.action(bar,"Collect visitor takings",func():notice.text=fishing.records().income.collect();refresh(),235)
 CARDS.action(bar,"Choose fish for the five cases",func():close();fishing.open_journal(),260)
 notice=CARDS.text(col,"Earnings continue away from the game for up to 24 hours per absence. The till holds 10,000 Glimmers. Rates are before wallet bonuses. No fee to display or collect.",14)
 var scroll=ScrollContainer.new();scroll.size_flags_vertical=Control.SIZE_EXPAND_FILL;scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;col.add_child(scroll);preload("res://scripts/touch_list_scroll.gd").attach(scroll)
 var list=VBoxContainer.new();list.size_flags_horizontal=Control.SIZE_EXPAND_FILL;list.add_theme_constant_override("separation",8);scroll.add_child(list)
 for slot in 5:
  var fish=fishing.records().specimen(str(fishing.records().state().display[slot]))
  var row=CARDS.framed(list,Color("#c8ac69") if not fish.is_empty() else Color("#507580"))
  if fish.is_empty():
   CARDS.text(row,"CASE %d • Empty\nChoose a kept catch to attract visitors." % (slot+1),17)
   CARDS.action(row,"Choose fish",func():close();fishing.open_journal(),120)
  else:
   fishing.picture(row,str(fish.species),Vector2(130,75),fish)
   var facts=VBoxContainer.new();facts.size_flags_horizontal=Control.SIZE_EXPAND_FILL;row.add_child(facts)
   CARDS.text(facts,"CASE %d • %s" % [slot+1,C.fish()[fish.species].name],18)
   CARDS.text(facts,"%s • %.2f kg%s" % [C.fish()[fish.species].rarity,fish.kg," • TROPHY" if C.is_trophy(fish) else ""],14)
   CARDS.text(facts,"%d Glimmers / real hour" % fishing.records().income.rate(fish),16,Color("#f0d18c"))
   var actions=VBoxContainer.new();row.add_child(actions);CARDS.action(actions,"Inspect fish",func():fishing.show_catch_details(str(fish.id)),125)
   CARDS.action(actions,"Remove from case",func():fishing.records().clear_display(slot);rebuild(),155)
 refresh()
func refresh()->void:
 var income=fishing.records().income;income.advance()
 summary.text="%d Glimmers ready   •   %d / real hour   •   Wallet: %d" % [income.ready(),income.hourly(),fishing.game.legacy.glimmers.balance()]
 claim.disabled=income.ready()<=0 or not income.allowed()
func _process(delta:float)->void:
 if not is_instance_valid(fishing.room):close();return
 clock+=delta
 if clock>=1:clock=0;refresh()
 var view=fishing.game.get_viewport_rect().size
 var small=view.y<500
 if small!=compact:
  compact=small
  explanation.text="Rare and unusually large catches attract visitors. Trophy size is relative to its species." if small else "Townsfolk pay to see remarkable catches. Rarity and size increase each exhibit’s appeal; normal common catches earn nothing. Size is compared with its own species, so even a small fish can be a trophy."
  notice.text="Up to 24h away • Till: 10,000 Glimmers • Rates before bonuses" if small else "Earnings continue away from the game for up to 24 hours per absence. The till holds 10,000 Glimmers. Rates are before wallet bonuses. No fee to display or collect."
 fishing.fit_panel(panel,Vector2(minf(920,maxf(700,view.x-24)),minf(650,maxf(340,view.y-24))))
func _unhandled_input(event:InputEvent)->void:
 if event is InputEventKey and event.pressed and not event.echo and event.keycode==KEY_ESCAPE:close();get_viewport().set_input_as_handled()
func close()->void:
 fishing.aquarium_panel=null;queue_free()

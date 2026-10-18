extends CanvasLayer
## Read-only specimen inspection; never catches, awards XP, or changes the saved fish.
const C=preload("res://scripts/fishing_catalog.gd")
const E=preload("res://scripts/fishing_ecology.gd")
const UI=preload("res://scripts/studio_ui.gd")
var fishing:Node
var catch_id=""
var panel:PanelContainer
func setup(owner:Node,id:String)->void:
 fishing=owner;catch_id=id;layer=96
 var specimen:Dictionary=fishing.records().specimen(id)
 if specimen.is_empty():close();return
 var spec:Dictionary=C.fish()[specimen.species]
 var shade=ColorRect.new();shade.color=Color(.02,.05,.07,.86);shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);add_child(shade)
 panel=PanelContainer.new();panel.name="FishDetails";add_child(panel);UI.apply(panel)
 var col=VBoxContainer.new();panel.add_child(col)
 var header=HBoxContainer.new();col.add_child(header)
 fishing.label(header,str(spec.name)+(" • TROPHY" if C.is_trophy(specimen) else ""),26).size_flags_horizontal=Control.SIZE_EXPAND_FILL
 fishing.button(header,"Close details",close)
 var row=HBoxContainer.new();row.add_theme_constant_override("separation",20);col.add_child(row)
 var image=TextureRect.new();image.custom_minimum_size=Vector2(245,130);image.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;image.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
 var crop=AtlasTexture.new();crop.atlas=C.texture(str(specimen.species));crop.region=C.display_region(specimen);image.texture=crop;row.add_child(image)
 var facts=VBoxContainer.new();facts.size_flags_horizontal=Control.SIZE_EXPAND_FILL;row.add_child(facts)
 fishing.label(facts,"%.2f kg  •  %.1f cm" % [specimen.kg,specimen.cm],25).modulate=Color("#ffe1a7")
 fishing.label(facts,str(spec.rarity)+" • "+("Trophy specimen" if C.is_trophy(specimen) else "Kept specimen"),18).modulate=Color(str(spec.color))
 fishing.label(facts,str(spec.get("note","")),17)
 var summary=UI.card(col,"SIZE & RECORD",C.size_summary(specimen))
 var record:Dictionary=fishing.records().state().journal.get(str(specimen.species),{})
 if not record.is_empty():
  fishing.label(summary,"Your species records: %.2f kg • %.1f cm • %d caught" % [record.kg,record.cm,record.count],16)
  fishing.label(summary,"Matches your current weight record" if is_equal_approx(float(specimen.kg),float(record.kg)) else "%.2f kg below your current weight record" % maxf(0,float(record.kg)-float(specimen.kg)),16).modulate=Color("#ade0cd")
 if C.is_trophy(specimen):fishing.label(summary,"Trophy catches earn +50% base catch XP; fishing mastery can increase this bonus.",16).modulate=Color("#ffdb7d")
 var provenance=UI.card(col,"CATCH DETAILS")
 var method=str(specimen.get("method",""));var bait=str(specimen.get("bait",""))
 fishing.label(provenance,"Water: "+str(C.pools().get(str(specimen.pool),{}).get("name",specimen.pool))+" • Date: "+str(specimen.get("date","Not recorded")),17)
 fishing.label(provenance,"Method: "+str({"rod":"Rod","net":"Net","pot":"Baited basket"}.get(method,"Not recorded"))+" • Bait: "+str(E.BAITS.get(bait,{}).get("name","Not recorded")),17)
 fishing.label(provenance,"Habitat: "+str(spec.get("habitat",""))+"\n"+E.window_text(spec),16)
 var places=PackedStringArray()
 for n in 5:
  if str(fishing.records().state().display[n])==id:places.append("Tank "+str(n+1))
 if fishing.records().state().favorite==id:places.append("Player-card favourite")
 fishing.label(col,"Displayed: "+(", ".join(places) if not places.is_empty() else "In your fish bag"),16).modulate=Color("#abd7d6")
 layout()
func layout()->void:
 var view=fishing.game.get_viewport_rect().size
 panel.size=Vector2(820,570);var logical=panel.get_combined_minimum_size().max(Vector2(820,570));panel.size=logical
 var fit=minf(1,minf((view.x-24)/logical.x,(view.y-24)/logical.y));panel.scale=Vector2.ONE*fit;panel.position=(view-logical*fit)*.5
func _process(_delta:float)->void:
 if fishing==null:return
 if fishing.records().specimen(catch_id).is_empty():close();return
 layout()
func _unhandled_input(event:InputEvent)->void:
 if event is InputEventKey and event.pressed and not event.echo and event.keycode==KEY_ESCAPE:close();get_viewport().set_input_as_handled()
func close()->void:
 if is_instance_valid(fishing):fishing.inspector=null
 queue_free()

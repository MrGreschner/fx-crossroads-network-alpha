extends RefCounted
## Common numerical reference scales, not balance ratings or DPS estimates.
static func entries(hero:Dictionary)->Array:
 var primary:Dictionary=hero.get("primary",{})
 var delay=maxf(0,float(primary.get("cooldown",0)))
 var rate=1.0/delay if delay>0 else 0.0
 var definitions=[
  ["Health",float(hero.get("max_health",100)),200.0,"HP","#d68d92","Base maximum health."],
  ["Attack damage",float(primary.get("damage",0)),50.0,"","#e4b577","Base primary damage per hit/tick/companion; not total cast damage or DPS. See ability details for summons, multi-hit and charge effects."],
  ["Attack range",float(primary.get("range",0)),700.0,"px","#88bdc9","Primary reach or targeting range, not projectile speed or area radius."],
  ["Attack speed",rate,4.0,"/s","#c0addd","Primary activations per second before charge time, passives or items. Summons have their own attack rate. Base cooldown: %.2fs."%delay],
  ["Move speed",float(hero.get("speed",230)),350.0,"px/s","#9ac8a0","Base movement speed before effects, equipment or abilities."]
 ]
 var result:Array=[]
 for spec in definitions:
  var amount=maxf(0,float(spec[1]));var units=str(spec[3]);var value=("%.2f/s"%rate if delay>0 else "Hold") if str(spec[0])=="Attack speed" else (str(roundi(amount))+(" "+units if not units.is_empty() else ""))
  result.append({"label":str(spec[0]),"value":value,"amount":amount,"ceiling":float(spec[2]),"ratio":clampf(amount/float(spec[2]),0,1),"tint":str(spec[4]),"tip":str(spec[5])+" Full bar: "+str(spec[2])+units+"; larger values remain shown numerically."})
 return result
## Each attack owns its type and measurements; no single primary-only rating.
static func attack_type(a:Dictionary)->String:
 var s=str(a.get("style",""))
 if s in ["monk_primary","monk_secondary"]:return "Melee / ranged stances"
 if s in ["summon","mosaic_seed","mosaic_guardian","hive_lantern","raise_remains","v90_puppets","fern_double"]:return "Summon"
 if s in ["melee","slash","punch","scratch","kick","identity_strike","scissor_feint","echo_cut","rune_slash","chain_sweep","twin_fang","v91_scissors","crab_pincers","v90_reed","rune_hammer","mini_jabs","oar_sweep","grave_cleave","v90_chop","cat_sweep","gopher_claw","beaver_bite","tail_slap","hearth_combo","fault_steps","piston_jab","quill_claw","v90_wing"]:return "Melee"
 if s in ["block","crab_shell","mirror_guard","spell_snare","vacuum_intake"]:return "Guard / counter"
 if s in ["heal_wave","rescue_buoy","rune_cycle","v90_steps","rally_banner","tailwind_seam","hearth_kindle","snack_break","pocket_rain","ribbon_stitch","kindred_dart","kindred_fan","harbor_note","hearth_light","v90_pot","sluice_pool","relay_field","chill_aura"]:return "Support / area" if s in ["v90_pot","sluice_pool","relay_field","chill_aura","pocket_rain"] else "Support"
 if s in ["traffic_order","gathering_knot","rewind_chime","rift_rotate","erase_release","magnet_pull","classroom_management","wick_face","mosaic_scatter","compass_turn","latchline","corner_lens","v90_lasso"]:return "Control / utility"
 if s in ["rune_step","history_rewind","witch_flight","mini_shift","echo_feint","red_covenant"]:return "Movement / utility"
 if s in ["charge","body_bounce","grapnel_rush","shell_lob","seam_ride","windlass_swing","gopher_dive","quill_lunge","v90_ascent","acorn_hop","acorn_kick","tumble_pour"]:return "Movement attack"
 if s in ["flame","fire_breath","magma_breath","page_channel","silk_tripline","spiral_shards","orbit_shards","twister_charge","twister_stride"]:return "Channel / area" if s!="page_channel" else "Ranged channel"
 if s in ["chalkstroke","bloom_seed","pulse_wave","pulse_burst","ground_sequence","fish_splash","brush_crush","waterfall_wave","grave_toll","stone_hoist","target_aoe","manual_mines"]:return "Area / control"
 if s in ["missile_volley","projectile","burst_projectile","corkscrew_key","scatterlight","apiary_needle","time_dart","bailiff_thread","return_disc","tide_needle","windwheel","gravespark","facet_spear","mirror_fan","rift_pin","v91_pistol","shuttle_stitch","echo_brand","pact_needle","threaded_needles","sail_needle","ricochet_projectile","water_jet","cross_shot","tea_shot","chain","navigator_bolt","homing","volt_note","spiral_shot","golf_drive","witch_chain","split_lance","paradox_split","advanced_knowledge","wick_fire","blood_crescent","magnet_pin","whistle_wave","lantern_comet"]:return "Ranged"
 return "Specialized"
static func measurement(label:String,amount:float,ceiling:float,units:String,tint:String,tip:String,value:String="")->Dictionary:
 amount=maxf(0,amount) if is_finite(amount) else 0.0
 return {"label":label,"amount":amount,"ratio":clampf(amount/ceiling,0,1),"ceiling":ceiling,"value":value if not value.is_empty() else str(snappedf(amount,.01)).trim_suffix(".0")+(" "+units if not units.is_empty() else ""),"tint":tint,"tip":tip+" Full bar: "+str(ceiling)+(" "+units if not units.is_empty() else "")+"; values above the scale remain shown numerically."}
static func attack_entries(hero:Dictionary,slot:String)->Array:
 var a:Dictionary=hero.get(slot,{});var s=str(a.get("style",""));var result:Array=[]
 var damage=maxf(0,float(a.get("damage",0)));var label="Base hit";var value="";var tip="Base damage for one hit, projectile or summon hit. Multi-hit, status effects, charge and passive bonuses are described below."
 if s=="heal_wave":label="Healing";damage=float(a.get("heal",35 if slot=="special" else 25));tip="Health restored, not damage. The pulse heals you and nearby allies."
 if s=="scatterlight":label="Cast dmg";tip="Maximum total if all seven rays hit the same target; 6 per ray."
 if s=="monk_primary":label="Hit M/R";value="8 / 16";damage=16;tip="Melee: three8damage jabs. Ranged: one16damage dagger. Stances switch every12seconds."
 if s=="monk_secondary":label="Hit / tick";value="14 / 6";tip="Melee:14per kick. Ranged:6per0.25second flame tick, plus burn."
 if s in ["flame","fire_breath","magma_breath"]:label="Dmg/tick";tip="Damage per tick, not total cast damage. Tick interval and burn are in the ability details."
 if s=="v90_pot":label="Dmg/sec";tip="4damage per second to enemies; the pot also heals allies."
 if s=="twister_stride":label="Dmg/tick";tip="7damage per0.5second tick while transformed."
 if s=="twister_charge":label="Dmg/tick";value="6-14.4";damage=14.4;tip="6to14.4damage per0.5second tick, depending on charge; up to4funnels."
 if a.has("hold_charge"):
  var hi=damage*float(a.hold_charge.get("damage",1))
  if hi!=damage:value=str(snappedf(damage,.1)).trim_suffix(".0")+"-"+str(snappedf(hi,.1)).trim_suffix(".0");damage=maxf(damage,hi);tip+=" Range shows tap to fully charged hit damage."
 if s in ["block","mirror_guard","crab_shell","spell_snare"]:damage=0
 if damage<=0:value="Utility";tip="No fixed direct damage. This ability changes movement, protection, allies or battlefield control; read its effect below."
 result.append(measurement(label,damage,50,"","#e4b577",tip,value))
 var reach=float(a.get("range",0));label="Reach";value="";tip="Authored targeting or attack reach in game units; area radius is a separate measurement."
 if s=="monk_primary":value="85 / 420";reach=420;tip="Melee85reach; ranged420reach."
 if attack_type(a)=="Summon":label="Target";tip="Command or placement targeting reach, not the companion's own attack reach."
 if reach<=0:
  label="Area";reach=float(a.get("radius",a.get("blast_radius",0)));tip="Effect radius, not targeting reach."
 if s=="heal_wave":label="Area";reach=float(a.get("radius",180));tip="Healing pulse radius around you; inherited projectile reach is not used."
 if s in ["block","mirror_guard","crab_shell"]:label="Scope";reach=0;value="Self";tip="Guard follows the hero; it is not an aimed ranged attack."
 if s in ["twister_stride","v90_pot"]:label="Area";tip="Damage/contact radius around the active effect."
 if reach<=0 and value.is_empty():value="See effect";tip="No fixed reach is published for this ability; see the effect description."
 result.append(measurement(label,reach,700,"px","#88bdc9",tip,value))
 var delay=maxf(0,float(a.get("cooldown",0)));label="Cooldown";value="";tip="Base recovery; lower is faster. Excludes charge, passives, equipment and ability-specific mechanics."
 if s=="page_channel":label="Page gap";delay=.22;tip="While held, a page is released every0.22seconds. This is emission interval, not a separate cast cooldown."
 if s=="v91_pistol":label="Reload";delay=float(a.get("reload_seconds",3));value=str(snappedf(delay,.1)).trim_suffix(".0")+" s / 6 shots";tip="Six rounds at your click pace, then3seconds reloading. There is no fixed per-shot cooldown."
 elif delay<=0:value="Hold / effect"
 result.append(measurement(label,delay,12,"s","#c0addd",tip,value))
 # Only show projectile/travel speed when this attack actually moves; inherited melee speed fields are not projectile speeds.
 var travel=attack_type(a) in ["Ranged","Movement attack","Ranged channel"] and a.has("speed")
 if travel:result.append(measurement("Travel",float(a.speed),800,"px/s","#91bdb1","Projectile or attack travel speed; this is not the hero's movement speed."))
 elif a.has("duration") and s!="heal_wave":result.append(measurement("Duration",float(a.duration),6,"s","#91bdb1","Base effect duration; see details for charge and conditional extensions."))
 elif (a.has("radius") or a.has("blast_radius")) and str(result[1].label)!="Area":result.append(measurement("Area",float(a.get("blast_radius",a.get("radius",0))),250,"px","#91bdb1","Effect radius, not targeting reach."))
 return result
static func add_title(parent:Node,text:String,tint:String="#f0d49d")->Label:
 var label=Label.new();label.text=text;label.add_theme_font_size_override("font_size",12);label.modulate=Color(tint);parent.add_child(label);return label
static func add_row(parent:Node,entry:Dictionary)->void:
 var col=VBoxContainer.new();col.add_theme_constant_override("separation",1);col.tooltip_text=entry.tip;parent.add_child(col)
 var top=HBoxContainer.new();top.add_theme_constant_override("separation",6);col.add_child(top)
 var name=add_title(top,entry.label,"#d8e5e5");name.size_flags_horizontal=Control.SIZE_EXPAND_FILL
 var number=add_title(top,entry.value,"#ffffff");number.horizontal_alignment=HORIZONTAL_ALIGNMENT_RIGHT
 var bar=ProgressBar.new();bar.custom_minimum_size=Vector2(20,5);bar.show_percentage=false;bar.value=entry.ratio*100;bar.mouse_filter=Control.MOUSE_FILTER_IGNORE
 var track=StyleBoxFlat.new();track.bg_color=Color("#0b242b");track.set_corner_radius_all(2);bar.add_theme_stylebox_override("background",track)
 var fill=StyleBoxFlat.new();fill.bg_color=Color(entry.tint);fill.set_corner_radius_all(2);bar.add_theme_stylebox_override("fill",fill);col.add_child(bar)
static func add_to(parent:Node,hero:Dictionary)->PanelContainer:
 var panel=PanelContainer.new();panel.name="HeroBaseStats";panel.size_flags_horizontal=Control.SIZE_EXPAND_FILL
 var skin=StyleBoxFlat.new();skin.bg_color=Color("#15353d");skin.border_color=Color("#426773");skin.set_border_width_all(1);skin.set_corner_radius_all(7);skin.set_content_margin_all(8);panel.add_theme_stylebox_override("panel",skin);parent.add_child(panel)
 var outer=VBoxContainer.new();panel.add_child(outer)
 var columns=HBoxContainer.new();columns.add_theme_constant_override("separation",14);outer.add_child(columns)
 for slot in ["primary","secondary"]:
  var col=VBoxContainer.new();col.name=slot.capitalize()+"Stats";col.size_flags_horizontal=Control.SIZE_EXPAND_FILL;col.size_flags_stretch_ratio=1.0;col.custom_minimum_size.x=145;col.add_theme_constant_override("separation",4);columns.add_child(col)
  var a:Dictionary=hero.get(slot,{})
  add_title(col,slot.to_upper(),"#e4b577" if slot=="primary" else "#88bdc9")
  var name=add_title(col,str(a.get("name","No ability")),"#ffffff");name.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
  var type=add_title(col,attack_type(a),"#a9c9cb");type.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
  for entry in attack_entries(hero,slot):add_row(col,entry)
 var vital=VBoxContainer.new();vital.name="HeroVitals";vital.custom_minimum_size.x=128;vital.add_theme_constant_override("separation",7);columns.add_child(vital)
 add_title(vital,"HERO")
 add_row(vital,measurement("Health",float(hero.get("max_health",100)),200,"HP","#d68d92","Base maximum health before passives and equipment."))
 add_row(vital,measurement("Move speed",float(hero.get("speed",230)),350,"px/s","#9ac8a0","Hero movement speed before effects and equipment."))
 var note=add_title(outer,"Base values before items/passives. Shared bar scales; cooldown: lower is faster.","#aac5c8");note.add_theme_font_size_override("font_size",10);note.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
 return panel

extends RefCounted
const UI=preload("res://scripts/studio_ui.gd")
const C=preload("res://scripts/waylight_catalog.gd")
static func label(parent:Node,value:String,size:int=16)->void:
 var l=Label.new();l.text=value;l.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;l.add_theme_font_size_override("font_size",size);parent.add_child(l)
static func confirm(l:Node,title:String,description:String,action:Callable)->void:
 var d=ConfirmationDialog.new();d.title=title;d.dialog_text=description;l.add_child(d)
 d.confirmed.connect(func():d.queue_free();action.call();l.render());d.canceled.connect(d.queue_free);d.popup_centered(Vector2i(500,220))
static func build(l:Node,body:Node)->void:
 var g=l.game;var p=g.waylight.progress;var s=p.state()
 var wallet=UI.card(body,"INVENTORY","Glimmers %d   •   Waylight Shards %d   •   Waydust %d" % [l.glimmers.balance(),s.shards,s.dust])
 label(wallet,"Prepare food, choose three CC items and equip two relics before your next adventure.")
 var food=UI.card(body,"FOOD • "+g.provisions.name_of(g.provisions.packed),g.provisions.summary(g.provisions.packed))
 l.button(food,"Visit Food Stand",func():l.close();g.menu="food";g.list_preview[g.menu]=0)
 var items=UI.card(body,"ADVENTURE ITEMS • THREE SLOTS","Purchased with CC. Item buttons 1, 2 and 3 activate your supplies during a run.")
 for n in 3:
  var spec=g.items.get(g.loadout[n],{}) if n<g.loadout.size() else {}
  var row=UI.card(items,"SLOT %d • %s" % [n+1,str(spec.get("name","Empty"))],str(spec.get("description","Choose an item at the Supply Vendor.")))
 l.button(items,"Visit Supply Vendor",func():l.close();g.menu="supplies";g.list_preview[g.menu]=0)
 var relics=UI.card(body,"RELICS • TWO SLOTS","Subtle permanent bonuses for solo adventures. Competition rules, training and current multiplayer disable relic effects.")
 if not s.attuned:
  var locked=l.button(relics,"Relics locked • complete Portal Attunement first",func():pass);locked.disabled=true;locked.tooltip_text="Complete Portal Attunement first. Visit the central portal → Attunement for your milestones."
  label(relics,"Clear Sunfield Expanse or Frostbound Rink, then extract with six Crossing Seals in the solo Between Attunement Challenge. Afterward, spend shards on the daily overcharge for a chance at a relic.")
  l.button(relics,"View Attunement Challenge",func():l.close();g.waylight.open(3))
  return
 label(relics,"Supporting bonuses across both slots are capped at +6% damage, +8% health and 4% cooldown reduction. Equip different relic types.")
 var fair=CheckButton.new();fair.text="Competition rules • relics disabled";fair.button_pressed=bool(s.fair);relics.add_child(fair);fair.toggled.connect(func(on:bool):s.fair=on;p.save())
 for n in 2:
  var item=p.item(str(s.equipped[n]));var box=UI.card(relics,"RELIC SLOT %d • %s" % [n+1,"Empty" if item.is_empty() else C.display_name(item)])
  if not item.is_empty():
   label(box,str(C.RELICS[item.type].effect))
   l.button(box,"Unequip",func():s.equipped[n]="";p.save();l.render())
 if p.fisher_ready():l.button(relics,"Claim Riverkeeper's Covenant • master fisher",func():l.notice.text=p.fisher_claim();l.render())
 else:label(relics,"Riverkeeper's Covenant • claimed" if s.fisher_claimed else "Master fisher relic • reach fishing level 80 and discover 50 species.")
 label(relics,"COLLECTION • %d / 60" % s.relics.size(),20)
 if s.relics.is_empty():label(relics,"No relics yet. The daily overcharge offers a chance after a successful clear; ten eligible clears without a drop guarantee one.")
 for v in s.relics:
  var box=UI.card(relics,"%s • Rank %d" % [C.display_name(v),int(v.rank)],str(C.RELICS[v.type].effect))
  var icon=preload("res://scripts/waylight_ui.gd").RelicIcon.new();icon.type=str(v.type);icon.custom_minimum_size=Vector2(66,66);box.add_child(icon)
  label(box,"Effect strength %.2f • %s +%.2f%% • Found in %s" % [C.effective(v),C.STATS[v.stat],C.stat_bonus(v)*100,C.NAMES.get(v.source,v.source)])
  var row=HFlowContainer.new();box.add_child(row)
  for n in 2:l.button(row,"Equip slot %d" % [n+1],func():p.equip(str(v.id),n);l.render())
  var rank=int(v.rank)+1;var upgrade=l.button(row,"Upgrade • %d shards + %d dust" % [rank*10,rank*2] if rank<=3 else "Maximum rank",func():l.notice.text=p.upgrade(str(v.id));l.render());upgrade.disabled=rank>3
  l.button(row,"Reroll stat…",func():confirm(l,"Reroll supporting stat?","Spend 8 shards and 1 Waydust. Strength may improve or decrease; the main effect and rank stay.",func():l.notice.text=p.reroll(str(v.id),g.waylight.rng)))
  l.button(row,"Salvage…",func():confirm(l,"Salvage this relic?","Permanently remove this relic for %d Waydust." % [2+int(v.rank)],func():l.notice.text=p.salvage(str(v.id))))

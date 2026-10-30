extends RefCounted
const C=preload("res://scripts/fishing_catalog.gd")
const E=preload("res://scripts/fishing_ecology.gd")
const UI=preload("res://scripts/studio_ui.gd")
const PALETTE={"Common":"#9ec8bc","Uncommon":"#80d5a2","Rare":"#7cbced","Very rare":"#b49afa","Legendary":"#edc66c","Mystical":"#ed99cf","Fabled":"#f4d28a"}
static func text(parent:Node,value:String,font:int=15,color:Color=Color("#d6e7e9"))->Label:
 var l=Label.new();l.text=value;l.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;l.add_theme_font_size_override("font_size",font);l.add_theme_color_override("font_color",color);l.size_flags_horizontal=Control.SIZE_EXPAND_FILL;parent.add_child(l);return l
static func action(parent:Node,title:String,callback:Callable,width:float=0)->Button:
 var b=Button.new();b.text=title;b.custom_minimum_size=Vector2(width,32);b.add_theme_font_size_override("font_size",14)
 for state in ["normal","hover","pressed","focus"]:b.add_theme_stylebox_override(state,UI.box("#234a59" if state=="normal" else "#356477","#527d8c" if state=="normal" else "#b4dfdc",6,6))
 parent.add_child(b);b.pressed.connect(callback);return b
static func framed(parent:Node,accent:Color)->HBoxContainer:
 var frame=PanelContainer.new();var skin=UI.box("#153440",accent.to_html(),9,10);skin.border_width_left=4;frame.add_theme_stylebox_override("panel",skin);parent.add_child(frame)
 var row=HBoxContainer.new();row.add_theme_constant_override("separation",12);frame.add_child(row);return row
static func build(f:Node,parent:Node)->void:
 var col=VBoxContainer.new();col.add_theme_constant_override("separation",7);parent.add_child(col)
 var header=HBoxContainer.new();col.add_child(header);text(header,"RIPPLE & REEL • COLLECTION",22,Color("#f1ddad"));action(header,"Close",f.close_journal,80)
 var state=f.records().state()
 text(col,"%d / %d species • %d catches • %d / %d kept    |    Fishing level %d • %s" % [state.journal.size(),C.fish().size(),int(state.total),f.records().bag_count(),f.records().capacity(),f.records().progress.level(),f.records().progress.title()],14)
 var shortcuts=HBoxContainer.new();shortcuts.add_theme_constant_override("separation",8);col.add_child(shortcuts)
 action(shortcuts,"Gear, fish bait & mastery",f.open_workshop)
 if is_instance_valid(f.room):
  action(shortcuts,"Aquarium income",f.open_aquarium_income)
  action(shortcuts,"Storage & selling",f.open_sales)
 action(shortcuts,"Weekly challenge",f.game.legacy.weekly.open_board)
 var task=f.game.legacy.weekly.fishing_task();var target=C.fish()[task.species]
 text(shortcuts,"Weekly: %s • %.2f+ kg" % [target.name,float(task.kg)],14)
 var tabs=TabContainer.new();f.collection_tabs=tabs;tabs.size_flags_vertical=Control.SIZE_EXPAND_FILL;col.add_child(tabs)
 tabs.add_theme_stylebox_override("panel",UI.box("#0d2631","#608c9c",8,8))
 for i in 2:
  var page=VBoxContainer.new();page.name=["Kept catches","Species journal"][i];page.add_theme_constant_override("separation",7);tabs.add_child(page)
  if i==1:filters(f,page)
  var frame=PanelContainer.new();frame.size_flags_vertical=Control.SIZE_EXPAND_FILL;frame.add_theme_stylebox_override("panel",UI.box("#0e2935","#426d7c",6,6));page.add_child(frame)
  var scroll=ScrollContainer.new();scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;scroll.size_flags_vertical=Control.SIZE_EXPAND_FILL;scroll.size_flags_horizontal=Control.SIZE_EXPAND_FILL;frame.add_child(scroll);f.collection_scrolls.append(scroll);preload("res://scripts/touch_list_scroll.gd").attach(scroll)
  var body=VBoxContainer.new();body.add_theme_constant_override("separation",9);body.size_flags_horizontal=Control.SIZE_EXPAND_FILL;scroll.add_child(body)
  if i==0:kept(f,body)
  else:species(f,body)
  scroll.set_deferred("scroll_vertical",int(f.collection_offsets[i]))
 tabs.current_tab=clampi(f.collection_tab,0,1);tabs.tab_changed.connect(func(index):f.collection_tab=index)
static func kept(f:Node,body:Node)->void:
 var state=f.records().state();var catches:Array=state.kept
 if catches.is_empty():text(body,"Your collection starts here. Keep a catch at any fishing hole to see its size, records and aquarium options.",18);return
 var list=VBoxContainer.new();kept_filters(f,body,func():fill_kept(f,list));list.size_flags_horizontal=Control.SIZE_EXPAND_FILL;list.add_theme_constant_override("separation",9);body.add_child(list)
 fill_kept(f,list)
 if not state.favorite.is_empty():action(body,"Clear player-card favourite",func():f.records().set_favorite("");f.refresh_journal())
static func kept_filters(f:Node,parent:Node,changed:Callable=Callable())->void:
 var row=HBoxContainer.new();parent.add_child(row)
 var search=LineEdit.new();search.placeholder_text="Search kept fish by name…";search.text=f.kept_query;search.size_flags_horizontal=Control.SIZE_EXPAND_FILL;search.custom_minimum_size.y=36;row.add_child(search)
 var sort=OptionButton.new();row.add_child(sort)
 for title in ["Name A–Z","Weight: heaviest","Relative size: largest","Rarity: highest","Newest caught","Oldest caught","Sale value: highest"]:sort.add_item(title)
 sort.select(f.kept_sort)
 var update=func():
  if changed.is_valid():changed.call()
  else:fill_kept(f,parent.get_child(parent.get_child_count()-1))
 search.text_changed.connect(func(value):f.kept_query=value;update.call())
 sort.item_selected.connect(func(index):f.kept_sort=index;update.call())
static func selected_catches(f:Node)->Array:
 var catches=f.records().state().kept.filter(func(c):return f.kept_query.strip_edges().is_empty() or str(C.fish()[c.species].name).to_lower().contains(f.kept_query.to_lower().strip_edges()))
 catches.sort_custom(func(a,b):
  var va=0.0;var vb=0.0
  if f.kept_sort==1:va=float(a.kg);vb=float(b.kg)
  elif f.kept_sort==2:va=float(a.kg)/C.mean_kg(a.species);vb=float(b.kg)/C.mean_kg(b.species)
  elif f.kept_sort==3:va=PALETTE.keys().find(str(C.fish()[a.species].rarity));vb=PALETTE.keys().find(str(C.fish()[b.species].rarity))
  elif f.kept_sort in [4,5]:
   var date_a=str(a.date);var date_b=str(b.date)
   if float(a.get("caught_at",0))>0 and float(b.get("caught_at",0))>0 and a.caught_at!=b.caught_at:return a.caught_at>b.caught_at if f.kept_sort==4 else a.caught_at<b.caught_at
   if date_a!=date_b:return date_a>date_b if f.kept_sort==4 else date_a<date_b
   return f.records().state().kept.find(a)>f.records().state().kept.find(b) if f.kept_sort==4 else f.records().state().kept.find(a)<f.records().state().kept.find(b)
  elif f.kept_sort==6:va=f.game.legacy.glimmers.fish_price(a);vb=f.game.legacy.glimmers.fish_price(b)
  if va!=vb:return va>vb
  return (str(C.fish()[a.species].name)+str(a.id)).naturalnocasecmp_to(str(C.fish()[b.species].name)+str(b.id))<0)
 return catches
static func fill_kept(f:Node,list:Node,selling=false)->void:
 for child in list.get_children():list.remove_child(child);child.queue_free()
 var catches=selected_catches(f)
 if catches.is_empty():text(list,"No kept catches match this search.",17)
 for catch in catches:catch_card(f,list,catch,selling)
static func catch_card(f:Node,body:Node,catch:Dictionary,selling:bool=false)->void:
 var spec:Dictionary=C.fish()[catch.species];var id=str(catch.id);var trophy=C.is_trophy(catch);var color=Color(PALETTE.get(spec.rarity,"#93cdd4"));var state=f.records().state()
 var row=framed(body,Color("#edc66c") if trophy else color);row.get_parent().set_meta("catch_id",id)
 var portrait=VBoxContainer.new();portrait.custom_minimum_size.x=145;row.add_child(portrait);f.picture(portrait,str(catch.species),Vector2(145,90),catch)
 text(portrait,("TROPHY" if trophy else str(spec.rarity)).to_upper(),13,Color("#f7d881") if trophy else color).horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
 var info=VBoxContainer.new();info.size_flags_horizontal=Control.SIZE_EXPAND_FILL;info.add_theme_constant_override("separation",5);row.add_child(info)
 text(info,str(spec.name)+(" • FAVOURITE" if state.favorite==id else ""),19,color)
 text(info,"%s • %s" % [spec.rarity,C.pools()[catch.pool].name],13)
 text(info,"%.2f kg    •    %.1f cm" % [float(catch.kg),float(catch.cm)],19,Color("#f1e5c7"))
 var mean=C.mean_kg(str(catch.species));var percentile=C.size_percentile(str(catch.species),float(catch.kg),clampf(float(catch.get("trophy_rate",.025)),0,1))
 text(info,"%.0f%% of species average (%.2f kg)" % [float(catch.kg)/maxf(.001,mean)*100,mean],14)
 var meter=preload("res://scripts/fish_size_meter.gd").new();meter.percentile=percentile;meter.accent=color;meter.tooltip_text="Estimated size rank for this species, using the catch size model. This is not a comparison with live player records.";info.add_child(meter)
 var best=float(state.journal.get(str(catch.species),{}).get("kg",catch.kg))
 text(info,("Your species weight record" if float(catch.kg)+.005>=best else "%.0f%% of your species best (%.2f kg)" % [float(catch.kg)/maxf(.001,best)*100,best])+" • Estimated size rank ~%.0f%%" % percentile,13)
 var actions=VBoxContainer.new();actions.custom_minimum_size.x=180;actions.add_theme_constant_override("separation",5);row.add_child(actions)
 action(actions,"Fish details",f.show_catch_details.bind(id),180)
 if selling:
  text(actions,"%d Glimmers" % f.game.legacy.glimmers.fish_price(catch),20,Color("#ffe0a0"))
  action(actions,"Sell fish…" if C.is_trophy(catch) or PALETTE.keys().find(str(spec.rarity))>=3 else "Sell fish",func():f.sales.sell(id),180)
  if C.is_trophy(catch) or PALETTE.keys().find(str(spec.rarity))>=3:text(actions,"Protected catch • confirmation required",12,Color("#f6d587"))
  return
 action(actions,"Sell at Ripple & Reel",f.open_sales.bind(id),180).disabled=f.game.mode!="town"
 action(actions,"Featured on card" if state.favorite==id else "Feature on card",func():f.records().set_favorite(id);f.refresh_journal(),180)
 text(info,"Aquarium appeal: %d Glimmers / real hour on display" % f.records().income.rate(catch),14,Color("#f0d18c"))
 var tank=OptionButton.new();tank.custom_minimum_size=Vector2(180,32);tank.add_theme_font_size_override("font_size",14);tank.add_item("Display in tank…")
 for n in 5:tank.add_item("Tank "+str(n+1)+(" • this fish" if state.display[n]==id else ""))
 actions.add_child(tank);tank.item_selected.connect(func(index):
  if index>0:f.records().showcase(id,index-1);f.refresh_journal())
 var placed=[]
 for n in 5:
  if state.display[n]==id:placed.append(str(n+1))
 if not placed.is_empty():text(actions,"On display: tank "+", ".join(placed),12,Color("#a0e0bf"))
 action(actions,"Release…",func():
  var dialog=ConfirmationDialog.new();dialog.title="Release "+str(spec.name)+"?";dialog.dialog_text="Removes this kept fish and its tank/favourite placement. Your species journal and personal best remain.";f.journal.add_child(dialog);dialog.confirmed.connect(func():f.records().release(id);dialog.queue_free();f.refresh_journal());dialog.canceled.connect(dialog.queue_free);dialog.popup_centered(Vector2i(460,180)),180)
static func filters(f:Node,parent:Node)->void:
 var row=HBoxContainer.new();row.add_theme_constant_override("separation",8);parent.add_child(row)
 for kind in ["discovery","rarity","location"]:
  var choice=OptionButton.new();choice.name="Journal"+kind.capitalize();choice.custom_minimum_size=Vector2(0,34);choice.size_flags_horizontal=Control.SIZE_EXPAND_FILL;choice.add_theme_font_size_override("font_size",14);row.add_child(choice);var ids=["all"]
  choice.add_item({"discovery":"All species","rarity":"All rarities","location":"All locations"}[kind])
  if kind=="discovery":
   ids.append_array(["seen","unseen"]);choice.add_item("Discovered species");choice.add_item("Undiscovered species")
  elif kind=="rarity":
   for rarity in PALETTE:ids.append(rarity);choice.add_item(rarity)
  else:
   for pool in C.pools():
    if pool in f.records().known_pools():ids.append(pool);choice.add_item(str(C.pools()[pool].name))
  var selected=f.journal_discovery if kind=="discovery" else f.journal_rarity if kind=="rarity" else f.journal_pool
  choice.select(maxi(0,ids.find(selected)))
  choice.item_selected.connect(func(index):
   if kind=="discovery":f.journal_discovery=ids[index]
   elif kind=="rarity":f.journal_rarity=ids[index]
   else:f.journal_pool=ids[index]
   f.refresh_journal(1))
static func filtered_ids(f:Node)->Array:
 var ids=[];var known=f.records().known_pools();var journal:Dictionary=f.records().state().journal
 for id in C.fish():
  var seen=journal.has(id)
  if f.journal_discovery=="seen" and not seen or f.journal_discovery=="unseen" and seen:continue
  if f.journal_rarity!="all" and str(C.fish()[id].rarity)!=f.journal_rarity:continue
  if f.journal_pool!="all" and (f.journal_pool not in known or id not in C.pools()[f.journal_pool].fish):continue
  ids.append(id)
 ids.sort_custom(func(a,b):
  if journal.has(a)!=journal.has(b):return journal.has(a)
  return str(C.fish()[a].name).naturalnocasecmp_to(str(C.fish()[b].name))<0)
 return ids
static func species(f:Node,body:Node)->void:
 var ids=filtered_ids(f);text(body,"%d species shown • %d / %d waters discovered. Visit an active shore marker to add its location filter." % [ids.size(),f.records().known_pools().size(),C.pools().size()],14)
 if ids.is_empty():text(body,"No species match these filters. Try All rarities or explore another fishing hole.",18);return
 for id in ids:
  var seen=f.records().state().journal.has(id);var spec:Dictionary=C.fish()[id];var color=Color(PALETTE.get(spec.rarity,"#8ab5c4")) if seen else Color("#506d7d");var row=framed(body,color)
  if seen:f.picture(row,str(id),Vector2(125,75))
  else:
   var mystery=Label.new();mystery.text="?";mystery.add_theme_font_size_override("font_size",48);mystery.custom_minimum_size=Vector2(125,75);mystery.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;mystery.modulate=Color("#698796");row.add_child(mystery)
  var info=VBoxContainer.new();info.size_flags_horizontal=Control.SIZE_EXPAND_FILL;info.add_theme_constant_override("separation",5);row.add_child(info)
  text(info,str(spec.name) if seen else "Undiscovered species",19,color if seen else Color("#a4bcc7"))
  if seen:
   var rec:Dictionary=f.records().state().journal[id];text(info,"%s • %d caught • Best %.2f kg / %.1f cm" % [spec.rarity,int(rec.count),float(rec.kg),float(rec.cm)],15)
   text(info,str(spec.note)+" • "+E.window_text(spec),14)
   var locations=[]
   for pool in C.pools():
    if pool in f.records().known_pools() and id in C.pools()[pool].fish:locations.append(str(C.pools()[pool].name))
   text(info,"Known waters: "+(", ".join(locations) if not locations.is_empty() else "Explore to locate this species again"),13,Color("#92cfcc"))
  else:text(info,"Catch this species to reveal its appearance and feeding notes. Hidden fishing locations stay undisclosed.",14)

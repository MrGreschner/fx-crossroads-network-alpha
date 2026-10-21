extends CanvasLayer
## Portable profiles, authored mastery techniques, town projects and Elder dialogue.
const PATH="user://fx_legacy.json"
const FILES=["crossroads_profile.json","fx_journey.json","fx_provisions.json","fx_prepared_supply.json","fx_quests_wayfarer_solo.json","fx_quests_wayfarer_party.json","fx_descent_best.json","fx_learning.json","fx_education_access.json","fx_teacher_classes.json"]
const PROJECTS={
 "flowers":{"name":"Town Flowerbeds","need":{"talk":3,"water":3},"reward":"A planted public garden with benches and butterflies."},
 "bakery":{"name":"Pondside Bakery","need":{"food":1,"clears":1},"reward":"One free Berry Bun after each successful adventure. Food slot must be empty."},
 "market":{"name":"Covered Market","need":{"food":2,"clears":3},"reward":"Save 1 CC on purchases costing at least 10 CC. Refunding returns only what you paid."},
 "mill":{"name":"River Watermill","need":{"silverfall":1,"quests":1,"clears":5},"reward":"A moving river and waterwheel. Bakery also offers free Antidote Pears; choose one food per clear."},
 "statue":{"name":"Champions’ Heritage Tree","need":{"distinct":3,"damage":5000},"reward":"An old heritage tree with your equipped mastery title on its plaque."},
 "library":{"name":"Quest Reading Room","need":{"quests":2,"talk":5},"reward":"An open reading garden with a quest preparation guide."},
 "fellowship":{"name":"Fellowship Pavilion","need":{"coop_clears":1},"reward":"A new meeting pavilion with team preparation tips and a co-op records board."},
 "relay":{"name":"Relay Workshop","need":{"coop_clears":3,"coop_distinct":2},"reward":"A new supply workshop. The bakery can offer a free Hearty Stew instead of its usual provision; still one food per successful adventure."},
 "observatory":{"name":"Expedition Observatory","need":{"coop_descent":10},"reward":"Clear ten Ram Descent floors with a team to add a telescope and party achievements to the lookout."},
 "bastion":{"name":"Veteran Gate Wall","need":{"defense30":1},"automatic":true,"reward":"Automatically earned by clearing Gate Defence wave 30. Stone blocks, iron braces and stronger gate towers appear in town."},
 "clinic":{"name":"Healer Supply Wing","need":{"clears":4,"food":3},"reward":"Bakery also offers Cleansing Tea. Still one free provision per successful adventure."}}
var fishing_records=preload("res://scripts/fishing_records.gd").new()
var gardening=preload("res://scripts/gardening.gd").new()
var community=preload("res://scripts/community_records.gd").new()
var lodge_economy=preload("res://scripts/lodge_economy.gd").new()
var weekly=preload("res://scripts/weekly_activities.gd").new()
var cosmetics=preload("res://scripts/player_cosmetics.gd").new()
var daily=preload("res://scripts/daily_challenge.gd").new()
const WATER_BEDS=[Vector2(1320,1005),Vector2(1320,1065),Vector2(1320,1125)]
var card=preload("res://scripts/profile_card.gd").new()
var portrait_picker_open:=false
var game:Node
var arcade:=false
var data:Dictionary={}
var builds:Dictionary={}
var root:Control
var body:VBoxContainer
var heading:Label
var notice:Label
var page:=""
var journal_hero:="ram"
var pending:Dictionary={}
var teacher_backup:Dictionary={}
var teacher_review_password=false
var education_password=false
var asking_code:=false
var native_dialog:FileDialog
var js_callback:JavaScriptObject
var callback_held:JavaScriptObject
var tick:=0.0
var last_menu:=""
var bread_credit:=false
var flash:=0.0
var last_saved_json:=""
var recovery_required=false
var ELDER_TOPICS:Dictionary={}
var mastery_tab:Button
var profile_scroll:ScrollContainer
var profile_tabs:Dictionary={}
var community_navigation:VBoxContainer
var points_glow:StyleBoxFlat
var point_notice:=false
var applied_glow:=false
var quick_normal:StyleBoxFlat
var point_check:=0.0
var mine=preload("res://scripts/idle_mine.gd").new()
var crowns=preload("res://scripts/rolling_crowns.gd").new()
var glimmers=preload("res://scripts/glimmers.gd").new()
var commerce=preload("res://scripts/commerce.gd").new()
func defaults()->Dictionary:
 return {"name":"Traveler","encounters":{},"favourites":[],"realm_counts":{},"heroes":{},"town":{},"tasks":{"talk":0,"water":0,"food":0,"quests":0,"clears":0,"realm_clears":0,"damage":0,"realms":[],"coop_clears":0,"coop_realms":[],"coop_distinct":0,"coop_descent":0,"coop_defense":0,"defense_best":0,"defense30":0},"card":card.defaults(),"talked":[],"watered":[],"quest_ids":[],"title":"Traveler","teacher":false,"bread":false}
func setup(owner:Node,multi:bool=false)->void:
 game=owner;arcade=multi;card.legacy=self;data=defaults()
 var value:Dictionary=preload("res://scripts/profile_store.gd").read(PATH,func(candidate:Dictionary):
  var probe:Dictionary=candidate.duplicate(true);probe.teacher=false
  if not probe.has_all(["name","tasks","heroes"]):return false
  return validate({"format":"fx-crossroads-profile","version":1,"progress":probe,"saves":{}}))
 if not value.is_empty():data.merge(value,true)
 elif FileAccess.file_exists(PATH) or FileAccess.file_exists(PATH+".bak"):
  recovery_required=true;get_tree().root.set_meta("fx_local_recovery",true)
  for suffix in ["",".bak"]:
   if FileAccess.file_exists(PATH+suffix) and not FileAccess.file_exists(PATH+suffix+".recovery"):DirAccess.copy_absolute(PATH+suffix,PATH+suffix+".recovery")
 var tasks:Dictionary=defaults().tasks;tasks.merge(data.tasks,true);data.tasks=tasks
 if not card.valid(data.get("card",{})):data.card=card.defaults()
 card.state();card.recover_abandoned()
 # Old persisted teacher sessions are not permission to enter the new temporary mode.
 if not preload("res://scripts/profile_store.gd").testing() and bool(data.get("teacher",false)):
  var backup:Dictionary=data.get("teacher_backup",{})
  if not backup.is_empty():data=backup.duplicate(true)
  data.teacher=false;data.erase("teacher_backup");data.erase("backup_saves")
 teacher_backup={}
 glimmers.legacy=self;glimmers.state()
 weekly.legacy=self;fishing_records.legacy=self;fishing_records.state();lodge_economy.setup(self);daily.setup(self);cosmetics.setup(self);crowns.setup(self);mine.setup(self);commerce.setup(self);gardening.setup(self);community.setup(self)
 layer=35
 root=PanelContainer.new();root.position=Vector2(110,45);root.size=Vector2(1060,640);root.visible=false;add_child(root)
 var style:=StyleBoxFlat.new();style.bg_color=Color("#142b32");style.border_color=Color("#c7ad78");style.set_border_width_all(2);style.set_corner_radius_all(8);root.add_theme_stylebox_override("panel",style)
 var margins:=MarginContainer.new();margins.add_theme_constant_override("margin_left",24);margins.add_theme_constant_override("margin_right",24);margins.add_theme_constant_override("margin_top",16);margins.add_theme_constant_override("margin_bottom",16);root.add_child(margins)
 var col:=VBoxContainer.new();col.add_theme_constant_override("separation",10);margins.add_child(col)
 heading=Label.new();heading.add_theme_font_size_override("font_size",27);col.add_child(heading)
 var tabs:=HFlowContainer.new();tabs.add_theme_constant_override("h_separation",6);col.add_child(tabs)
 for item in [["Profile","profile"],["Inventory","inventory"],["Fishing","fishing"],["Gardening","gardening"],["Mastery","mastery"],["Town projects","town"],["Records & style","records"],["Settings","settings"],["Elder Ram","elder"]]:
  var tab:=button(tabs,str(item[0]),open_page.bind(str(item[1])))
  tab.add_theme_font_size_override("font_size",16);tab.custom_minimum_size.y=34
  tab.toggle_mode=true;profile_tabs[str(item[1])]=tab
  if item[1]=="mastery":mastery_tab=tab
 var divider=HSeparator.new();divider.name="PlayerMenuDivider";divider.custom_minimum_size.y=9
 var divider_style=StyleBoxLine.new();divider_style.color=Color("#678b91");divider_style.thickness=2;divider.add_theme_stylebox_override("separator",divider_style);col.add_child(divider)
 community_navigation=VBoxContainer.new();community_navigation.name="PinnedRecordsNavigation";community_navigation.visible=false;col.add_child(community_navigation)
 var scroll:=ScrollContainer.new();profile_scroll=scroll;scroll.size_flags_vertical=Control.SIZE_EXPAND_FILL;scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;col.add_child(scroll)
 body=VBoxContainer.new();body.size_flags_horizontal=Control.SIZE_EXPAND_FILL;body.add_theme_constant_override("separation",12);scroll.add_child(body)
 notice=Label.new();notice.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;col.add_child(notice)
 var footer:=HBoxContainer.new();col.add_child(footer);button(footer,"Back to town",close);button(footer,"Cloud account",func():close();get_node("/root/FXAccount").open())
 if not arcade:
  var quick:=Button.new();quick.text="Profile / Mastery / Town";quick.position=Vector2(820,12);quick.size=Vector2(300,42);quick.add_theme_font_size_override("font_size",17);quick.pressed.connect(func():
   if game.menu=="characters":open_hero(game.selected_character)
   else:open_page("profile"));quick.name="Quick";add_child(quick)
  preload("res://scripts/top_button_style.gd").apply(quick)
  quick.size=Vector2(300,44)
  quick_normal=quick.get_theme_stylebox("normal")
  points_glow=quick_normal.duplicate()
  points_glow.border_color=Color("#edc977");points_glow.set_border_width_all(2)
  quick.tooltip_text="Your player card, fishing, mastery, town projects and settings"
 if OS.has_feature("web"):
  js_callback=JavaScriptBridge.create_callback(import_web)
  JavaScriptBridge.get_interface("window").fxCrossroadsImport=js_callback
func save()->void:
 if recovery_required:
  if is_instance_valid(notice):notice.text="Local profile needs recovery. Original files preserved. Open Cloud account for recovery options."
  return
 if mine.legacy!=null:mine.advance()
 if bool(data.get("teacher",false)) and not preload("res://scripts/profile_store.gd").testing():return
 preload("res://scripts/release_support.gd").scan_mastery(self)
 var serialized:=JSON.stringify(data)
 if serialized==last_saved_json and FileAccess.file_exists(PATH):return
 var result:Error=preload("res://scripts/profile_store.gd").write(PATH,data,serialized,func(candidate:Dictionary):return validate({"format":"fx-crossroads-profile","version":1,"progress":candidate,"saves":{}}))
 if result==OK:last_saved_json=serialized
 if result!=OK and is_instance_valid(notice):notice.text="Could not save progress on this device. Download your profile before leaving."
func record(id:String)->Dictionary:
 if not data.heroes.has(id):data.heroes[id]={"clears":0,"realm_clears":0,"damage":0,"realms":[],"points":0,"technique":false,"final_technique":false,"tuning":[0,0,0]}
 var entry:Dictionary=data.heroes[id]
 if not entry.has("final_technique"):entry.final_technique=false
 return entry
func hero_for(owner:String)->String:return str(game.hero_ids.get(owner,"ram")) if arcade else str(game.character_id)
func eligible(id:String,title:bool=false)->bool:
 if bool(data.teacher):return true
 var entry:=record(id);var spec:Dictionary=game.characters.get(id,{}).get("mastery",{}).get("title_requirements" if title else "technique_requirements",{})
 if not title and spec.has("duet_realm"):return bool(entry.get("duet_clear",false)) and float(entry.damage)>=float(spec.get("damage",10000))
 return int(entry.clears)>=int(spec.get("clears",3)) and entry.realms.size()>=int(spec.get("distinct_realms",2)) and float(entry.damage)>=float(spec.get("damage",10000))
func final_eligible(id:String)->bool:
 if bool(data.teacher):return true
 var rec:=record(id);var req:Dictionary=game.characters.get(id,{}).get("mastery",{}).get("final_requirements",{})
 return int(rec.clears)>=int(req.get("clears",12)) and rec.realms.size()>=int(req.get("distinct_realms",6)) and float(rec.damage)>=float(req.get("damage",85000))
func crit_tier(id:String)->int:
 if bool(data.teacher):return 3
 var tier:=0;var milestones:Array=game.characters.get(id,{}).get("mastery",{}).get("crit_milestones",[{"clears":3},{"clears":6},{"clears":9}])
 for n in mini(3,milestones.size()):
  if int(record(id).clears)>=maxi(1,int(milestones[n].get("clears",(n+1)*3))):tier=n+1
 return tier
func crown_bonus(owner:String)->Dictionary:
 var normalized=arcade and (bool(game.get_meta("crown_competition",false)) or game.practice_match()) or not arcade and game.practice
 var rank=preload("res://scripts/rolling_crowns.gd").timed_tier(build(owner),Time.get_unix_time_from_system()) if arcade else preload("res://scripts/rolling_crowns.gd").tier_from(crowns.total())
 return preload("res://scripts/rolling_crowns.gd").bonus(rank,normalized)
func critical_stats(owner:String)->Dictionary:
 var tier:=clampi(int(build(owner).get("crit_tier",0)),0,3)
 var milestones:Array=game.characters.get(hero_for(owner),{}).get("mastery",{}).get("crit_milestones",[])
 var spec:Dictionary=milestones[tier-1] if tier>0 and milestones.size()>=tier else {}
 var powers=crown_bonus(owner)
 var chance=clampf(float(spec.get("chance",tier*.02)),0,.06)+float(powers.chance)
 var extra=clampf(float(spec.get("bonus",tier*.2)),0,.6)*game.adventure.combat.v98.crit_multiplier(owner)+float(powers.damage)
 if game.adventure.combat.support_aura(owner,"kitchen_aura"):chance=minf(.5,chance+.04);extra=maxf(.5,extra)
 return {"chance":chance,"multiplier":1+extra}
func critical(owner:String,amount:float,point:Vector2,roll:float=-1)->float:
 if amount<=0 or not is_finite(amount) or owner=="enemy" or owner.is_empty():return amount
 if arcade and not game.hero_ids.has(owner):return amount
 var stats=critical_stats(owner)
 if (randf() if roll<0 else roll)>=float(stats.chance):return amount
 if arcade:game.damage_labels.append({"pos":point-Vector2(22,68),"time":.7,"text":"CRIT!"})
 else:game.add_float_text(point-Vector2(22,68),"CRIT!",Color("#f5c777"))
 return amount*float(stats.multiplier)
func final_toggle(id:String)->void:
 if not final_eligible(id):return
 record(id).final_technique=not bool(record(id).final_technique);save();render()
func payload(id:String)->Dictionary:
 var rec:=record(id)
 return {"technique":bool(rec.technique) and eligible(id),"final_technique":bool(rec.final_technique) and final_eligible(id),"crit_tier":crit_tier(id),"crown_damage":int(minf(1e12,crowns.total())),"crown_expiry":crowns.expiry_schedule(true) if arcade else [],"tuning":rec.tuning.duplicate(),"points":int(rec.points),"title":str(data.title)}
func sanitize_build(value:Variant)->Dictionary:
 if not value is Dictionary:return {"technique":false,"tuning":[0,0,0],"points":0}
 var crown_amount=float(value.get("crown_damage",0)) if preload("res://scripts/workshop_project.gd").number(value.get("crown_damage",0),0,1e12) else 0.0
 var expiry=preload("res://scripts/rolling_crowns.gd").clean_expiry(value.get("crown_expiry",[]),preload("res://scripts/rolling_crowns.gd").tier_from(crown_amount),Time.get_unix_time_from_system())
 var points:=clampi(int(value.get("points",0)),0,6);var tuning:Array=[0,0,0];var remaining:=mini(points,4)
 var raw:Variant=value.get("tuning",[])
 if raw is Array:
  for n in mini(3,raw.size()):tuning[n]=clampi(int(raw[n]),-mini(2,remaining),mini(2,remaining));remaining-=absi(int(tuning[n]))
 return {"technique":bool(value.get("technique",false)),"final_technique":bool(value.get("final_technique",false)),"crit_tier":clampi(int(value.get("crit_tier",0)),0,3),"crown_damage":crown_amount,"crown_expiry":expiry,"tuning":tuning,"points":points}
func build(owner:String)->Dictionary:
 if arcade and game.has_method("network_build"):return game.network_build(owner)
 var id:=hero_for(owner)
 if arcade and owner!=game.my_id:return builds.get(owner,{"technique":false,"tuning":[0,0,0]})
 return payload(id)
func preview_stats(id:String,kind:String,original:Dictionary)->Dictionary:
 return authored_stats(id,kind,original,payload(id))
func stats(owner:String,kind:String,original:Dictionary)->Dictionary:
 var result=authored_stats(hero_for(owner),kind,original,build(owner))
 if arcade and game.get("expedition")!=null and game.expedition.special() and result.has("cooldown"):result.cooldown*=1-game.expedition.relics.bonus(owner,"focus")
 return result
func authored_stats(id:String,kind:String,original:Dictionary,choice:Dictionary)->Dictionary:
 var result:=original.duplicate(true)
 if bool(choice.get("technique",false)):
  var tech:Dictionary=game.characters.get(id,{}).get("mastery",{}).get("technique",{})
  if str(tech.get("ability",""))==kind:
   if tech.get("attack",{}) is Dictionary and not tech.get("attack",{}).is_empty():result=tech.attack.duplicate(true)
   for key in tech.get("multiply",{}):
    if result.has(key) and (result[key] is float or result[key] is int):result[key]=float(result[key])*float(tech.multiply[key])
   for key in tech.get("set",{}):result[key]=tech.set[key]
 if bool(choice.get("final_technique",false)) and str(original.get("style",""))!="saw_stomp":
  var final:Dictionary=game.characters.get(id,{}).get("mastery",{}).get("final_technique",{})
  if str(final.get("ability",""))==kind:result=final.get("attack",original).duplicate(true)
 var tune:Array=choice.get("tuning",[0,0,0]);var power:=int(tune[0]);var guard:=int(tune[2])
 if result.has("damage"):result.damage=float(result.damage)*(1.0+.04*power-.03*guard)
 if result.has("cooldown"):
  result.cooldown=float(result.cooldown)*(1.0+.05*power)
  if not arcade and game.get("waylight")!=null:result.cooldown*=1-game.waylight.combat.bonus("focus")
 return result
func hp_factor(owner:String)->float:return 1.0+.05*int(build(owner).get("tuning",[0,0,0])[1])
func speed_factor(owner:String)->float:return 1.0-.03*int(build(owner).get("tuning",[0,0,0])[1])
func hurt_factor(owner:String)->float:return 1.0-.04*int(build(owner).get("tuning",[0,0,0])[2])
func channel_speed(owner:String)->float:
 var effective:=stats(owner,"secondary",game.characters.get(hero_for(owner),{}).get("secondary",{}))
 return float(effective.get("channel_move",0))
func add_damage(id:String,amount:float)->void:
 if amount<=0 or bool(data.teacher) or preload("res://scripts/profile_store.gd").progression_blocked():return
 cosmetics.add_damage(amount);crowns.add_damage(amount)
 record(id).damage=float(record(id).damage)+amount;data.tasks.damage=float(data.tasks.damage)+amount
func clear_adventure(id:String,realm:String)->void:
 if bool(data.teacher) or preload("res://scripts/profile_store.gd").progression_blocked():return
 daily.realm_clear(id,realm)
 preload("res://scripts/named_records.gd").cleared(self,realm,float(game.run_time))
 var entry:=record(id);entry.clears=int(entry.clears)+1
 if realm not in entry.realms:
  entry.realms.append(realm);entry.points=mini(6,int(entry.points)+1)
 data.tasks.clears=int(data.tasks.clears)+1
 if realm not in ["descent","defense","quests","town","practice"]:data.tasks.realm_clears=int(data.tasks.get("realm_clears",0))+1
 if realm not in data.tasks.realms:data.tasks.realms.append(realm)
 if realm=="silverfall":data.tasks["silverfall"]=int(data.tasks.get("silverfall",0))+1
 if realm not in ["descent","defense","quests","town","practice"]:
  if not data.has("realm_counts") or not data.realm_counts is Dictionary:data.realm_counts={}
  data.realm_counts[realm]=realm_clears(realm)+1
 data.bread=true;card.cleared(realm)
 save()
func realm_clears(id:String)->int:return maxi(0,int(data.get("realm_counts",{}).get(id,0)))
func realm_mastered(id:String)->bool:return realm_clears(id)>=10
func quest_done(id:String)->void:
 if bool(data.teacher) or preload("res://scripts/profile_store.gd").progression_blocked() or id in data.quest_ids:return
 data.quest_ids.append(id);data.tasks.quests=int(data.tasks.quests)+1;save()
func discount(cost:int)->int:return maxi(0,cost-(1 if bool(data.town.get("market",false)) and cost>=10 else 0))
const MATERIALS={"market":{"gold":10,"ore":5},"mill":{"gold":30,"ore":15,"gems":1},"statue":{"gold":15,"ore":6},"library":{"gold":10,"ore":5},"fellowship":{"gold":15,"ore":10},"relay":{"gold":20,"ore":15},"observatory":{"gold":35,"ore":15,"gems":1},"clinic":{"gold":15,"ore":5}}
func material_cost(id:String)->Dictionary:return MATERIALS.get(id,{})
func materials_ready(id:String)->bool:
 if bool(data.teacher):return true
 var wallet:Dictionary=mine.state().wallet
 for key in material_cost(id):
  if float(wallet.get(key,0))<float(material_cost(id)[key]):return false
 return true
func town_ready(id:String)->bool:
 for key in PROJECTS[id].need:
  var have:int=data.tasks.realms.size() if key=="distinct" else int(data.tasks.get(key,0))
  if have<int(PROJECTS[id].need[key]):return false
 return materials_ready(id)
func build_project(id:String)->void:
 if id not in PROJECTS or not town_ready(id) or bool(data.town.get(id,false)):return
 if mine.readonly():return
 for key in material_cost(id):mine.state().wallet[key]-=float(material_cost(id)[key])
 data.town[id]=true;save();notice.text="Built "+str(PROJECTS[id].name)+"!";render()
func give_food()->void:
 if game.provisions.packed.is_empty():notice.text="Buy or harvest food first. Donating uses your packed food.";return
 game.provisions.packed="";game.provisions.save();data.tasks.food=int(data.tasks.food)+1;save();notice.text="Moss thanks you for the supplies.";render()
func talk(id:String)->void:
 if id not in data.talked:data.talked.append(id);data.tasks.talk=int(data.tasks.talk)+1;save()
func water(id:String)->void:
 if id in data.watered:notice.text="This bed is already watered.";return
 data.watered.append(id);data.tasks.water=int(data.tasks.water)+1;save();notice.text="Watered the flowerbed.";render()
func claim_food(id:String)->void:
 if not bool(data.town.get("bakery",false)) or not bool(data.bread):notice.text="Build the bakery, then clear an adventure to earn a provision.";return
 if not game.provisions.packed.is_empty():notice.text="Your food slot must be empty.";return
 if id=="antidote_pear" and not bool(data.town.get("mill",false)):return
 if id=="cleansing_tea" and not bool(data.town.get("clinic",false)):return
 if id=="hearty_stew" and not bool(data.town.get("relay",false)):return
 game.provisions.packed=id;game.provisions.paid=0;game.provisions.save();data.bread=false;save();notice.text="Packed your free provision. Next successful adventure earns another.";render()
func title_equip(id:String)->void:
 if not eligible(id,true):return
 data.title=str(game.characters[id].mastery.title);game.journey.data.title=data.title
 if data.title not in game.journey.data.unlocked:game.journey.data.unlocked.append(data.title)
 game.journey.save();save();render()
func technique_toggle(id:String)->void:
 if not eligible(id):return
 record(id).technique=not bool(record(id).technique);save();render()
func tune(id:String,index:int,change:int)->void:
 var rec:=record(id);var proposed:Array=rec.tuning.duplicate();proposed[index]=clampi(int(proposed[index])+change,-2,2)
 if absi(int(proposed[0]))+absi(int(proposed[1]))+absi(int(proposed[2]))>mini(4,int(rec.points)):notice.text="Earn a point from a new realm, or remove a point from another choice.";return
 rec.tuning=proposed;save();render()
func button(parent:Node,label:String,action:Callable)->Button:
 var item:=Button.new();item.text=label;item.custom_minimum_size=Vector2(0,42);item.add_theme_font_size_override("font_size",19);item.pressed.connect(action);parent.add_child(item);return item
func text(value:String)->void:
 var label:=Label.new();label.text=value;label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;label.add_theme_font_size_override("font_size",19);body.add_child(label)
func open_page(which:String)->void:
 if arcade or game.mode!="town":return
 if which=="mastery":acknowledge_mastery()
 refresh_point_notice()
 page=which;game.menu="legacy";root.visible=true;game.mobile.reset_controls();notice.text="";render();fit_profile_panel();profile_scroll.set_deferred("scroll_vertical",0)
func open_hero(id:String)->void:
 journal_hero=id;open_page("mastery")
func close()->void:
 root.visible=false;page="";game.menu="";game.mobile.reset_controls();save()
func render()->void:
 for child in body.get_children():body.remove_child(child);child.queue_free()
 heading.text="CROSSROADS • "+str(data.name)+(" • GAME DEV" if bool(data.teacher) else "")
 for child in community_navigation.get_children():community_navigation.remove_child(child);child.queue_free()
 community_navigation.visible=page=="community"
 if page=="community":community.build_navigation(community_navigation)
 for key in profile_tabs:
  var tab:Button=profile_tabs[key];tab.button_pressed=key==page or key=="records" and page=="community"
  var skin=StyleBoxFlat.new();skin.bg_color=Color("#294d59") if tab.button_pressed else Color("#132b34");skin.border_color=Color("#e9c985");skin.border_width_bottom=3 if tab.button_pressed else 0;skin.set_corner_radius_all(5);skin.set_content_margin_all(9)
  tab.add_theme_stylebox_override("normal",skin);tab.add_theme_stylebox_override("pressed",skin)
 match page:
  "profile":profile_ui()
  "inventory":preload("res://scripts/player_inventory.gd").build(self,body)
  "community":community.build(body)
  "gardening":gardening.build(body)
  "fishing":fishing_ui()
  "records":records_ui()
  "settings":settings_ui()
  "mastery":mastery_ui()
  "town":town_ui()
  "elder":elder_ui()
  "cosmetics":
   text("GLEAM ATELIER • your style, your story")
   text("Choose earned cosmetics below. Daily and weekly effects show their expiry; permanent rewards stay with your profile.")
   cosmetics.ui(body);daily.ui(body);crowns.ui(body)
   button(body,"Choose titles & journey effects",func():root.hide();game.menu="journey_cosmetics")
func learning_open()->void:
 if not preload("res://scripts/education_access.gd").student():return
 var page=load("res://scripts/learning_page.gd").new();add_child(page);page.setup(self)
func profile_ui()->void:
 var view=preload("res://scripts/player_card_view.gd").new();view.legacy=self;body.add_child(view)
 button(body,"Choose card portrait • "+str(card.unlocked_portraits())+" unlocked",func():portrait_picker_open=not portrait_picker_open;render())
 if portrait_picker_open:portrait_ui()
 crowns.ui(body)
 text("Glimmers: %d   •   Waylight Shards: %d" % [glimmers.balance(),game.waylight.progress.state().shards])
 text("Your card grows with your adventures. Fishing has its own tab; save transfers and player settings are in Settings.")
 button(body,"Save & player settings",open_page.bind("settings"))
func fishing_ui()->void:
 preload("res://scripts/fishing_dashboard.gd").build(self,body)
func records_ui()->void:
 var ui=preload("res://scripts/studio_ui.gd")
 button(body,"Community records • heroes, fish, realms & Waylight",community.open)
 text("YOUR ADVENTURE RECORDS")
 var overview=HFlowContainer.new();overview.add_theme_constant_override("h_separation",10);body.add_child(overview)
 var clears=0;var mastered=0
 for id in game.manifest.regions if not arcade else preload("res://network/realms.gd").ids():clears+=realm_clears(str(id))
 for id in data.heroes:
  if card.portrait_star(str(id)):mastered+=1
 for pair in [["Realm clears",clears],["Mastered heroes",mastered],["Arena wins",int(card.state().arena.standard.wins)+int(card.state().arena.random.wins)]]:
  var stat=ui.card(overview,str(pair[1]),str(pair[0]));stat.get_parent().custom_minimum_size=Vector2(185,72)
 text("ARENA • player KOs and monster defeats")
 var row=HBoxContainer.new();row.name="ArenaRecordCards";body.add_child(row)
 for kind in ["standard","random"]:
  var rec:Dictionary=card.state().arena[kind];var box=ui.card(row,"Standard heroes" if kind=="standard" else "Random heroes");box.get_parent().size_flags_horizontal=Control.SIZE_EXPAND_FILL
  var grid=GridContainer.new();grid.columns=2;grid.add_theme_constant_override("h_separation",24);box.add_child(grid)
  for pair in [["Player KOs",rec.kills],["Monster defeats",rec.npc_kills],["Deaths",rec.deaths],["Current KO streak",rec.kill_streak],["Best KO streak",rec.best_kill_streak]]:
   var name=Label.new();name.text=str(pair[0]);name.size_flags_horizontal=Control.SIZE_EXPAND_FILL;grid.add_child(name)
   var value=Label.new();value.text=str(int(pair[1]));value.modulate=Color("#efd39b");grid.add_child(value)
 var explain=button(body,"How portraits, stickers & trophies are earned",func():pass)
 var guide=ui.card(body,"REWARD MILESTONES","Portrait: first hero technique • Gold star: final technique.\nStickers: Expert / Extreme realm clears.\nWin streak trophies: Bronze 1 • Silver 3 • Gold 5 • Platinum 10 • Astral 20.\nDraws preserve a win streak; losses or leaving an active arena end it.");guide.get_parent().hide()
 explain.pressed.connect(func():guide.get_parent().visible=not guide.get_parent().visible)
 text("STYLE & WEEKLY REWARDS")
 cosmetics.ui(body);crowns.ui(body)
func settings_ui()->void:
 var support=preload("res://scripts/release_support.gd")
 if support.backup_due(self):
  text("NEW MASTERY EARNED • Back up your profile to keep this milestone.")
  var backup_row:=HBoxContainer.new();backup_row.add_theme_constant_override("separation",12);body.add_child(backup_row)
  button(backup_row,"Back up profile now",export_profile).size_flags_horizontal=Control.SIZE_EXPAND_FILL
  button(backup_row,"Dismiss reminder",func():data.backup_reminder.pending=false;save();render()).size_flags_horizontal=Control.SIZE_EXPAND_FILL
 text("Saved on this device. Download and verify your profile before clearing a shared computer. Upload it to continue elsewhere; Game Dev progress is temporary.")
 if bool(data.teacher):button(body,"Exit game Dev mode • restore my profile",disable_teacher)
 if not arcade and preload("res://scripts/education_access.gd").student():button(body,"Student Mode • assignments & portfolio",learning_open)
 if not arcade and preload("res://scripts/education_access.gd").teacher():button(body,"Teacher Mode • class dashboard",func():load("res://scripts/teacher_dashboard.gd").open(self))
 text("GAME DEV: temporary testing. Your normal profile is protected; refresh or Exit game Dev mode to resume progress." if bool(data.teacher) else "Your progress saves on this browser. Download your profile before leaving a shared PC; upload it on another device to continue.")
 var field:=LineEdit.new();field.text=str(data.name);field.placeholder_text="Player name (no password needed)";field.max_length=32;field.custom_minimum_size.y=44;body.add_child(field)
 button(body,"Save player name",func():data.name=field.text.strip_edges().left(32);save();render()).disabled=bool(data.teacher)
 var stability=get_node_or_null("/root/FXStability")
 if stability!=null:
  button(body,"School performance: "+("ON" if stability.school_mode else "OFF")+" • "+str(stability.fps_limit)+" FPS",func():stability.toggle();render())
  button(body,"Download diagnostic report",stability.download)
  if stability.interrupted:text("The previous session was interrupted (a refresh, tab close or crash). If the game froze, download diagnostics before restarting the browser.")
 button(body,"Download profile",export_profile).disabled=bool(data.teacher)
 button(body,"Upload profile…",pick_import).disabled=bool(data.teacher)
 button(body,"Start a different player…",func():pending={"new":true};import_preview()).disabled=bool(data.teacher)
 text("Profiles are personal saves, not online accounts. Import replaces this browser's progress. Your downloaded file remains a backup.")
func portrait_ui()->void:
 button(body,"Use Traveler silhouette",card.select_portrait.bind(""))
 var grid:=GridContainer.new();grid.columns=6;grid.add_theme_constant_override("h_separation",8);grid.add_theme_constant_override("v_separation",8);body.add_child(grid)
 for id in game.manifest.characters:
  var unlocked:bool=card.portrait_unlocked(str(id));var title:=str(game.characters[id].name)
  var tile:=Button.new();tile.custom_minimum_size=Vector2(150,90);tile.text=title;tile.add_theme_font_size_override("font_size",13);tile.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS;tile.tooltip_text=title+(" • portrait unlocked" if unlocked else " • unlock the first mastery technique to use this portrait");tile.disabled=not unlocked
  if unlocked:tile.icon=game.art.get(str(game.characters[id].get("sprite",id))+"_idle");tile.expand_icon=true;tile.add_theme_constant_override("icon_max_width",44)
  if card.portrait_star(str(id)):
   var star=TextureRect.new();star.texture=preload("res://scripts/ui_reward_icons.gd").texture();star.position=Vector2(4,4);star.size=Vector2(20,20);star.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;star.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;star.mouse_filter=Control.MOUSE_FILTER_IGNORE;tile.add_child(star)
  tile.pressed.connect(card.select_portrait.bind(str(id)));grid.add_child(tile)
func requirement_text(spec:Dictionary)->String:
 if spec.has("duet_realm"):return "Clear Confluence Foundry in co-op with Tide Keeper and Spark Keeper, plus 10,000 damage on this hero."
 return str(int(spec.get("clears",3)))+" clears, "+str(int(spec.get("distinct_realms",2)))+" different realms, "+str(int(spec.get("damage",10000)))+" combat damage"
func result_line(id:String)->String:
 var rec:=record(id)
 return "Mastery: "+str(rec.clears)+" clears • "+str(int(rec.damage))+" damage • "+str(rec.points)+" points"+(" • Technique unlocked" if eligible(id) else "")
func mastery_label(parent:Node,value:String,size:int=17)->Label:
 var label:=Label.new();label.text=value;label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;label.add_theme_font_override("font",preload("res://assets/fonts/CrossroadsUI.ttf"));label.add_theme_font_size_override("font_size",size);parent.add_child(label);return label
func mastery_panel(parent:Node)->VBoxContainer:
 var panel:=PanelContainer.new();panel.size_flags_horizontal=Control.SIZE_EXPAND_FILL;parent.add_child(panel)
 var skin:=StyleBoxFlat.new();skin.bg_color=Color("#203c46");skin.border_color=Color("#46616b");skin.set_border_width_all(1);skin.set_corner_radius_all(10);skin.content_margin_left=16;skin.content_margin_right=16;skin.content_margin_top=14;skin.content_margin_bottom=14;panel.add_theme_stylebox_override("panel",skin)
 var col:=VBoxContainer.new();col.add_theme_constant_override("separation",10);panel.add_child(col);return col
func mastery_card(parent:Node,id:String,final:bool)->void:
 var spec:Dictionary=game.characters[id].mastery;var rec:=record(id)
 var entry:Dictionary=spec.get("final_technique" if final else "technique",{})
 var req:Dictionary=spec.get("final_requirements" if final else "technique_requirements",{})
 var ready:bool=final_eligible(id) if final else eligible(id)
 var equipped:bool=bool(rec.final_technique) if final else bool(rec.technique)
 var col:=mastery_panel(parent)
 mastery_label(col,"FINAL TECHNIQUE" if final else "FIRST TECHNIQUE",14).modulate=Color("#d5b879")
 mastery_label(col,str(entry.get("name","Alternate ability")),22)
 mastery_label(col,str(entry.get("ability","Ability")).capitalize()+" • "+("Equipped" if equipped and ready else "Unlocked" if ready else "Locked"),16).modulate=Color("#a9ded6")
 var detail:=mastery_label(col,str(entry.get("description","")),17)
 detail.visible=false
 var more:=button(col,"What changes?",func():detail.visible=not detail.visible)
 more.add_theme_font_size_override("font_size",16);more.custom_minimum_size.y=32
 var progress:=ProgressBar.new();progress.custom_minimum_size.y=12;progress.show_percentage=false;progress.max_value=1
 progress.value=1 if ready else minf(minf(float(rec.clears)/maxf(1,float(req.get("clears",3))),float(rec.realms.size())/maxf(1,float(req.get("distinct_realms",2)))),float(rec.damage)/maxf(1,float(req.get("damage",10000))))
 if req.has("duet_realm"):progress.value=1 if ready else 0
 col.add_child(progress)
 if not ready and req.has("duet_realm"):
  mastery_label(col,requirement_text(req),14)
 elif not ready:
  mastery_label(col,"%d/%d clears • %d/%d realms • %s/%s damage" % [int(rec.clears),int(req.get("clears",3)),rec.realms.size(),int(req.get("distinct_realms",2)),str(int(rec.damage)),str(int(req.get("damage",10000)))],14)
 var action:Callable=final_toggle.bind(id) if final else technique_toggle.bind(id)
 var equip:=button(col,("Switch to original" if equipped else "Equip technique") if ready else "Keep adventuring to unlock",action);equip.disabled=not ready;equip.add_theme_font_size_override("font_size",17)
func mastery_ui()->void:
 var ids:Array=game.manifest.characters
 var id:=journal_hero;var rec:=record(id);var spec:Dictionary=game.characters[id].mastery
 var head:=HBoxContainer.new();head.add_theme_constant_override("separation",14);body.add_child(head)
 var portrait:=TextureRect.new();portrait.texture=game.art.get(str(game.characters[id].get("sprite",id))+"_idle");portrait.custom_minimum_size=Vector2(64,72);portrait.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;portrait.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;head.add_child(portrait)
 var info:=VBoxContainer.new();info.size_flags_horizontal=Control.SIZE_EXPAND_FILL;head.add_child(info)
 var picker:=OptionButton.new();picker.custom_minimum_size.y=42;info.add_child(picker)
 for hero_id in ids:picker.add_item(str(game.characters[hero_id].name)+(" • +%d points" % unspent_points(str(hero_id)) if unspent_points(str(hero_id))>0 else ""))
 picker.select(maxi(0,ids.find(journal_hero)));picker.item_selected.connect(func(index:int):journal_hero=str(ids[index]);render())
 mastery_label(info,"%d clears • %d realms • %s damage" % [int(rec.clears),rec.realms.size(),str(int(rec.damage))],16)
 var title:=button(info,"Wear title: "+str(spec.title) if eligible(id,true) else "Title: "+str(spec.title)+" • locked",title_equip.bind(id));title.disabled=not eligible(id,true);title.add_theme_font_size_override("font_size",14);title.custom_minimum_size.y=28;title.tooltip_text="Unlock: "+requirement_text(spec.get("title_requirements",{}))
 mastery_label(body,"ABILITY CHOICES • optional, free to switch",18)
 var cards:=HBoxContainer.new();cards.add_theme_constant_override("separation",14);body.add_child(cards);mastery_card(cards,id,false);mastery_card(cards,id,true)
 var crit:=mastery_panel(body);mastery_label(crit,"CRITICAL HITS • automatic rewards",19)
 var crit_row:=HBoxContainer.new();crit_row.add_theme_constant_override("separation",10);crit.add_child(crit_row)
 var milestones:Array=spec.get("crit_milestones",[])
 for n in mini(3,milestones.size()):
  var m:Dictionary=milestones[n];var tile:=mastery_panel(crit_row)
  mastery_label(tile,("✓ " if crit_tier(id)>n else "○ ")+str(int(m.clears))+" clears",17)
  mastery_label(tile,str(roundi(clampf(float(m.chance),0,.06)*100))+"% chance • +"+str(roundi(clampf(float(m.bonus),0,.6)*100))+"% damage",15)
 var tuning:=mastery_panel(body);var used:int=absi(int(rec.tuning[0]))+absi(int(rec.tuning[1]))+absi(int(rec.tuning[2]))
 var tuning_heading:=mastery_label(tuning,"PLAYSTYLE SLIDERS • %d / %d points used" % [used,mini(4,int(rec.points))],19)
 mastery_label(tuning,"Spend points in either direction. Centre is neutral; moving back refunds points.",15)
 var names=["Faster attacks ↔ Stronger attacks","Faster movement ↔ More health","More damage ↔ More defence"]
 for n in 3:
  mastery_label(tuning,str(names[n]),16)
  var row:=HBoxContainer.new();row.add_theme_constant_override("separation",12);tuning.add_child(row)
  var slider:=HSlider.new();slider.min_value=-2;slider.max_value=2;slider.step=1;slider.value=int(rec.tuning[n]);slider.custom_minimum_size=Vector2(420,38);slider.size_flags_horizontal=Control.SIZE_EXPAND_FILL;row.add_child(slider)
  var value_label:=mastery_label(row,tuning_text(n,int(rec.tuning[n])),15);value_label.custom_minimum_size.x=340
  slider.value_changed.connect(func(value:float):
   var proposed:Array=record(id).tuning.duplicate();proposed[n]=int(value)
   var cost:int=absi(int(proposed[0]))+absi(int(proposed[1]))+absi(int(proposed[2]))
   if cost>mini(4,int(record(id).points)):slider.set_value_no_signal(record(id).tuning[n]);notice.text="Return another slider towards centre to free a point.";return
   record(id).tuning=proposed;value_label.text=tuning_text(n,int(value));tuning_heading.text="PLAYSTYLE SLIDERS • %d / %d points used" % [cost,mini(4,int(record(id).points))];notice.text="";save())
  slider.drag_ended.connect(func(_changed:bool):render())
 mastery_label(body,"Progress comes from completed adventures. Training and game Dev testing do not count.",14)
func town_ui()->void:
 text("YOUR TOWN • RESOURCES & DISCOVERIES")
 text("Glimmers: %d • Waylight Shards: %d • Mine depth: %dm" % [glimmers.balance(),game.waylight.progress.state().shards,mine.depth()*30])
 text("Ore level %d • Gem level %d • Market sales %.0f • Operating profit %.0f" % [commerce.ore_level(),commerce.gem_level(),commerce.state().revenue,commerce.state().profit])
 button(body,"Crossroads Market • business & resources",commerce.open)
 button(body,"Deepwell Mine • collect & upgrade",mine.open)
 button(body,"Town almanac • discovered events",game.town_life.calendar.almanac.open)
 button(body,"Portal expeditions • Waylight & relics",func():game.waylight.open(1))
 text("Help your town through adventures and small acts. Projects follow this player profile; they are not a shared server-wide town.")
 button(body,"Donate my packed food to Moss",give_food)
 text("Crossroads Coins (CC) buy combat supplies. Mine Gold, ore and gems help finish buildings. Flowerbeds and your first bakery require no mining materials.")
 button(body,"Visit Idle Mining • collect materials",func():root.hide();game.menu="";mine.open())
 for id in PROJECTS:
  var spec:Dictionary=PROJECTS[id];var requirements:=""
  for key in spec.need:
   var have:int=data.tasks.realms.size() if key=="distinct" else int(data.tasks.get(key,0))
   requirements+=str(key).capitalize()+": "+str(have)+"/"+str(spec.need[key])+"   "
  var materials=""
  for key in material_cost(str(id)):
   var name={"gold":"Mine Gold","ore":"Ore","gems":"Gems"}[key]
   materials+=name+": "+str(int(mine.state().wallet[key]))+"/"+str(material_cost(str(id))[key])+"   "
  text(str(spec.name)+"\n"+requirements+("\n"+materials if not materials.is_empty() else "")+"\n"+str(spec.reward))
  if bool(spec.get("automatic",false)):
   text("Built" if bool(data.town.get(id,false)) else "Earned automatically when wave 30 is cleared, not when it starts.");continue
  var action:=button(body,"Built" if bool(data.town.get(id,false)) else "Build "+str(spec.name),build_project.bind(str(id)));action.disabled=bool(data.town.get(id,false)) or not town_ready(str(id))
 if bool(data.town.get("library",false)):button(body,"Read the quest preparation guide",func():notice.text="Pack cleansing food, read your abilities, and check the quest journal after each conversation. Bring a support hero for a long expedition. Completed quests save separately for solo and party adventures.")
 if bool(data.town.get("bakery",false)):
  button(body,"Collect free Berry Bun",claim_food.bind("berry_bun"))
  if bool(data.town.get("mill",false)):button(body,"Choose free Antidote Pear instead",claim_food.bind("antidote_pear"))
  if bool(data.town.get("clinic",false)):button(body,"Choose free Cleansing Tea instead",claim_food.bind("cleansing_tea"))
  if bool(data.town.get("relay",false)):button(body,"Choose free Hearty Stew instead",claim_food.bind("hearty_stew"))
func elder_ui()->void:
 if not arcade:
  button(body,"Elder Ram • Welcome & first adventures",func():game.presentation.elder_guide.begin("welcome"))
  var guide=button(body,"Elder Ram • The Between, shards & relics",func():game.presentation.elder_guide.begin("between"))
  guide.disabled=not game.presentation.elder_guide.earned_between()
  guide.tooltip_text="Clear Sunfield Expanse or Frostbound Rink to discover this path."
 text("Elder Ram: Hello, traveler! Welcome to Crossroads: Realms Beyond. Find your path. Create what’s next. Ask me anything, or pick a topic below.")
 chat_ui()
 var topics={
  "Crossroads: Realms Beyond • our world":"Crossroads is our town, a meeting place for travellers, creators and the worlds beyond the portal. Follow a path into adventure, build your own hero or realm in Crossroads Studio, or take time to fish and help the town grow. Find your path. Create what’s next.",
  "First adventure & training":"The first nine heroes offer a short practice adventure. Speak to the training guide to replay it, learn buffs and try bouncing attacks or projectile counters. All 80 heroes are available; the hall has numbered search, favourites and role filters.",
  "Abilities, buffs & mastery":"Primary starts at level 1, secondary at 3, passive at 5 and special at 6. In the hall, tap each ability for full details. Mastery techniques are optional alternatives: earn the first with 10,000 damage plus clears, and the final with 85,000 plus more varied clears. Crit rewards arrive at 3, 6 and 9 clears. Sliders trade one strength for another; a glowing Profile button means newly earned mastery points. Open Mastery to clear the notification; unspent points remain beside each hero in the selector.",
  "Arena, teams & spectators":"The stadium offers free-for-all or teams, map choice, up to eight fighters and a separate spectator host. Opening Act is off by default: start at level 10. Practice solo with up to three AI heroes; bots grant damage mastery but no PvP trophies or records. Use Leaderboard during play; it also appears while waiting to respawn.",
  "Gather your party":"Host a public or private room, share its code, or browse waiting Public Rooms. Change your hero without leaving. Tap Silver or Blue before starting team matches. Friends can request to join supported live adventures; new arrivals start at level 1. After a match, stay together in the lobby to play again.",
  "Gate Defence & Ram Descent":"Gate Defence has three paths, outposts, marching guards and opposing hero rivals. Upgrade at buildings and beat the wave-30 guardian to earn the stronger town wall. One to three heroes can defend. Ram Descent supports up to four: clear dungeon floors, watch your XP bar, and manage health carefully—new floors do not heal you automatically.",
  "Battlegrounds":"Beyond the north gate, two teams build armies from personal barracks. Choose 3v3 or 4v4; upgrade soldiers, archers, healers and stronger units, then break the enemy heart. The central item shop rewards control of the middle. The war-zone map also has dangerous falling air strikes.",
  "Realms, quests & exploration":"The portal lists realms by difficulty; encounter enemies to reveal named portraits, with bosses shown separately. Ten clears earn a realm star. Follow the east bridge and forest trail to Wayfarer Wilds for a longer quest expedition, villagers, dungeons and the snowy summit. The Challenge Lodge offers five quick trial styles and three weekly featured trials. The Gatherers’ Lodge sends timed crews for herbs and rare seeds; Willowglass Apothecary brews these into potions for your separate consumable slot.",
  "Weekly activities":"Every Sunday starts eight appearance-only rewards: a species-and-size fishing target, a profitable market day, three player-only arena goals, Descent floor 10, two lodge trials and Gate Defence wave 10. Check Adventures, Records & style or Gleam Atelier. Equip one earned effect for the rest of the week. Game Dev, Playtest, continued practice and bot arena matches do not earn these rewards.",
  "Lodges, gathering & potions":"Daily Mission is a separate daily objective in the main menu and Adventures. Challenge Lodge offers five quick combat trials at level 10. Bronze, silver and gold medals unlock cosmetics; clear three featured weekly trials for a temporary lantern. No realm clears or mastery progress. Gatherers’ Lodge sends timed crews for herbs, mushrooms, bark, insects and petals. Claim returns and occasional rare seeds; brew consumable bottles at Willowglass Apothecary. Potions use ordinary item slots. Upgrade the apothecary with ingredients for new recipes.",
  "Food, seeds & a growing town":"Carry three equipment items, one consumable and one automatically eaten food. Visit the Food Stand; healing food triggers at its health threshold and cleansing food removes matching effects. Grow plants and unlock more seeds at the Seed House. Clears, co-op accomplishments and helping townsfolk build projects. Death returns you to the healer house with your chosen hero.",
  "Player card, cosmetics & saving":"Profile holds lifetime statistics, arena trophies, difficult-realm badges and earned hero portraits. Journey cosmetics has buttons to equip ribbons and titles. Download your personal profile before changing computers; Upload replaces this device's progress. New/Clear removes local progress—download it first. Transfers are available in town.",
  "Student playtesting":"Options opens a Playtest Notebook: record what you tested, three issues, suggested fixes and a reflection. Copy or download the report; nothing is submitted automatically. Game Dev mode is for experiments and does not earn profile progress. Reports can be exported while testing.",
  "Performance, sound & help":"Options in the main menu controls the FPS cap, school performance mode and local crash reports. Sound has an easy mute button. Double-tap Escape for the pause menu; online matches keep running. A downloadable edition avoids browser graphics overhead and still connects to the same rooms. Report the hero, mode and action when something breaks."
 }
 topics["Media • capture and filming"]="Type media here to enable a green-bordered filming session. Use the Camera panel to choose four zoom levels and framing offsets. Normal progress still counts; this mode grants no powers. F9 hides the controls, F10 hides the gameplay HUD and F8 captures a clean PNG after three seconds. Photo tools include composition guides, aspect framing and a captioned portfolio in your profile. OBS records video. Game Dev users have the same tools; testing does not save portfolio work."
 topics["Commerce & marketing"]="Crossroads Coins (CC) buy items and food; mining has separate Mine Gold, ore and gems for small town construction costs. Crossroads Market is southwest of the pond, beside the mountain. For a quick start choose Basic setup, then Open market. Or collect mine materials, prepare goods, choose customer group, price, channel and message, forecast results, then choose how long a business day lasts (5 minutes to 24 hours) and open the market. It settles after that time, even if you leave. Decisions stay locked during trading. Compare revenue against stock costs, advertising and overhead. Upgrades improve quality, service or reach but have costs. Reports download your decisions for assessment. Profile separates ore/gem levels from sales and profit. Market cash can be reinvested as Mine Gold; it never changes hero combat."
 topics["Crossroads Studio • how to use the labs"]="Crossroads Studio is the public creative building in the western campus, open to everyone. Crossroads Academy is its separate school building to the south: the classroom door needs unlocked Student or Teacher access (Game Dev can enter too). Hero Workshop assembles artwork, abilities and passives. Object Lab makes props, buildings and editable layered pixel art. Realm Builder paints terrain with separate movement/projectile collision and places saved props and enemies; Finalize & Play explores the realm without awarding profile progress. Alternate Forms in Hero Artwork can be attached to abilities for a chosen duration. Finalize installs work locally; Student Mode adds submission snapshots. Artwork is evidence of practical design tool use, so there is no duplicate tool-use essay. 2-D Design 2 builds a realm; Raster Graphics 1 and 2 use progressively harder asset packs. Ability Lab builds attacks and animated effects; charge settings and code levels explain the logic. Behaviour Lab designs decisions such as keeping distance or fleeing. Enemy Lab combines poses, behaviour and up to three attacks, then lets you battle your creation. Start from an example or Clear All, test one change at a time, save your project, and export files to share. Partner Up invites one collaborator. Your player ZIP backs up creations; a test report explains what you changed and observed."
 topics["Deepwell Mine • idle mining"]="Enter the mine west of town, below Ram Descent. Commission the camp with its own starter Mine Gold, hire ram diggers, balance lift capacity and fresh air, collect your depot and excavate new shafts. Profitable market days also earn a modest 20 CC supply dividend once per real day; collect it in the Market floor tab. The mine works between visits and travels in your downloaded player profile. It never changes hero combat. Buildings, timed boosts, refining and milestones are explained inside."
 topics["Playtest Mode • student testing"]="Type playtest in this chat to start Playtest Mode. Anyone can use it. Combat stays normal, player progress and profile transfers stop, and F8 opens checkpoints, performance information and your notebook. Exit Playtest Mode restores your saved profile; reports stay separate. It does not unlock heroes or give powers."
 topics["Daily Mission & glow"]="Daily Mission is one featured objective from 50 shuffled tasks, separate from the Challenge Lodge’s combat trials and weekly trials. Read the objective in Adventures, then choose Play today’s mission. Use the main menu to jump into the activity. Finish it in normal play to earn a one of eight rotating animated cosmetic effects until local midnight. No combat bonus, no Game Dev credit. Download your profile to bring your reward to another computer."
 topics["Charged attacks & aiming"]="Some attacks fire when you release the button. Hold for more power, turn toward your target, then release. Ground markers appear only while aiming. The Living Book instead channels pages while held. Cancelling a charge never spends the attack."
 topics["Returning or sharing a computer"]="Continue goes straight into the game. New game offers a fresh local profile and the starter tutorial. Back up your own profile before giving the computer to someone else. My memory is woolly; your download should not be."
 topics["Custom builds & Forced Balance"]="Save a valid draft to play it from Custom heroes. Forced Balance trades damage, reach and area for cooldown, and health or protection for movement. Public custom rooms require a checked budget. Private rooms can allow experimental builds. Cyan sigils identify customs; violet sparks identify experimental ones."
 if preload("res://scripts/education_access.gd").state().student or preload("res://scripts/education_access.gd").state().teacher:
  topics["Student Mode • outcome portfolios"]="Student access opens assignment tools and your portfolio. The classroom Education Guide lists nine projects and evidence progress bars. Save a brief before building, attach work and tests, then submit a frozen version. Practice checks verify concept answers and IPO predictions; a teacher decides outcome achievement. Join your teacher's ED submission code to send your education portfolio, then Send latest progress after further work. Download your player profile on shared computers."
 if preload("res://scripts/education_access.gd").state().teacher:
  topics["Teacher review • class view"]="Teacher Mode gives a class dashboard, outcome marking, a 31-seat lesson broadcast and Spotlight. Host a Submit assignment room and share its ED code. Joining students consent to send their educational portfolio; no full game profile is sent. Review snapshots, quick checks and journals, save ratings, then students accept returned feedback. Class records remain on your device and in your profile download. Passcodes are local classroom shortcuts, not secure authentication."
 topics["Idle Mining • minerals"]="Idle Mining grows while you adventure. Coal, silver, rubies, sapphires, diamonds and moonstone unlock with deeper shafts. Collect the depot, then assay specimens for Mine Gold. Copper, iron, cobalt, mithril, emberite and starsteel seams appear at shafts 2, 4, 7, 11, 15 and 18. Collect these ores and coal, then forge bars in Smelter & metals. Bars can be sold at Crossroads Market or used for deeper construction. Deliver one reinforcement batch to shorten a running build by 35%. Adventures now opens the Mine and Market directly. Ore and gems also feed Crossroads Market; forecast sales, set a message and compare profit in Reports. Download your profile to preserve both simulations."
 topics["Create, share & Showcase"]="Studio → Projects & Showcase shows your next step: save, test the exact revision, finalize, then share a frozen submission. A teacher can approve it for a class Showcase pack or return feedback. Import the returned file, improve your editable copy and test again. Adventures → Build, trade & create opens the Showcase directly. Profile ZIP includes this journey and feedback. Checkmarks show recorded actions, not grades."
 topics["Fishing • Ripple & Reel"]="Ripple & Reel is the enterable aquarium on the southeast riverbank, south of the training yard. Talk to Bramble to discover a free fishing rod. Find bubbling water, stand at its shore marker and press F or Cast. Wait for a bite, then press F / Hook before the gold window closes. Moving or taking damage cancels a cast; combat stays live. Keep or release: both reveal a species, and size is independent of rarity. Display five kept fish inside the shop and choose one for your player card. Fish follow real-world hours, weekdays and game weather. Some river and pond fish bite only by day or night; the northern dawn shoal appears only from 04:00–06:00. Explore other realm waters too. Start with a free rod and bare hook. Buy the net at fishing level 5 and baited baskets at level 10; each basket fills once after twenty real minutes. Craft or buy fish bait in the Angler’s Workshop, available in your Profile or collection. Both keeping and releasing earn fishing XP, with cosmetic rewards through level 80 and 26 mastery points to choose from 60 connected perks across six specializations. Reset mastery in town for Glimmers. Trophy fish weigh at least 250% of their species average and earn 50% extra catch XP. Every species is catchable from level one in the right conditions. Catches travel in Download Profile. Practice and test catches do not earn normal profile progress."
 ELDER_TOPICS=topics
 for label in topics:button(body,str(label),func():notice.text="Elder Ram: "+str(topics[label]);talk("elder"))

func chat_ui()->void:
 text("Elder Ram: Password?" if asking_code else "Ask the keeper of knowledge")
 var row:=HBoxContainer.new();row.add_theme_constant_override("separation",12);body.add_child(row)
 var field:=LineEdit.new();field.placeholder_text="Password" if asking_code else "Ask about heroes, daily missions, friends, saving…";field.max_length=180;field.custom_minimum_size=Vector2(0,48);field.size_flags_horizontal=Control.SIZE_EXPAND_FILL;field.secret=asking_code;row.add_child(field)
 var submit:=func():
  var question:String=field.text.strip_edges()
  if question.is_empty():return
  answer(question);field.text=""
 field.text_submitted.connect(func(_value:String):submit.call());button(row,"Ask",submit)
 var entry=preload("res://scripts/mobile_text_entry.gd").new();field.add_child(entry);entry.setup(field)
 if asking_code:field.grab_focus()
 text("Quick topics")
func question_ui()->void:render()
func answer(value:String)->void:
 if value in ["studentModeOff","teacherModeOff"]:
  var kind="student" if value=="studentModeOff" else "teacher"
  notice.text=(kind.capitalize()+" access removed from this profile. Saved work is retained.") if preload("res://scripts/education_access.gd").revoke(kind) else "Exit testing mode before changing saved access."
  render();return
 if value=="studentModeOn":
  if preload("res://scripts/education_access.gd").unlock("student"):notice.text="Student access unlocked for this profile. Visit Crossroads Academy for assignments."
  else:notice.text="Exit testing mode before unlocking a saved education profile."
  render();return
 if value=="teacherModeOn":education_password=true;asking_code=true;question_ui();return
 if education_password:
  education_password=false;asking_code=false
  if value=="56Gt9" and preload("res://scripts/education_access.gd").unlock("teacher"):close();load("res://scripts/teacher_dashboard.gd").open(self);return
  notice.text="That is not the teacher passcode, or this profile is in testing mode.";render();return
 if teacher_review_password:
  teacher_review_password=false;asking_code=false
  if value=="fx97" and preload("res://scripts/education_access.gd").teacher():close();preload("res://scripts/teacher_review.gd").open(self);return
  notice.text="Elder Ram: That is not the teacher passcode.";render();return
 if value=="teacher":teacher_review_password=true;asking_code=true;question_ui();return
 if asking_code:
  asking_code=false
  if value=="R4ms!90":enable_teacher();return
  notice.text="Elder Ram: That isn't the passcode.";render();return
 if value=="playtest":
  if get_tree().root.get_node("FXDevSession").active:notice.text="Exit Game Dev mode first, then ask me for playtest.";return
  get_tree().root.get_node("FXResearch").begin();close();return
 if value=="media":
  if get_tree().root.get_node("FXResearch").active:notice.text="Exit Playtest Mode before enabling Media mode for normal progress.";return
  game.media.enable();close();return
 if value=="gameDev":asking_code=true;question_ui();return
 var q:=value.to_lower();var reply:="I'm best at explaining Crossroads. Ask about food, mastery, saving, controls, friends, quests or town projects."
 if "rebrand" in q or "game name" in q or "realms beyond" in q or q=="fx":reply="Welcome to Crossroads: Realms Beyond! Crossroads is our town; the portal opens onto the realms beyond. Our motto is: Find your path. Create what’s next. Adventure, fish, build a hero or create a world in Studio—the choice is yours."
 elif "fish" in q or "rod" in q or "aquarium" in q:reply=str(ELDER_TOPICS.get("Fishing • Ripple & Reel","Visit Ripple & Reel and talk to Bramble."))
 elif "balance" in q or "custom" in q:reply=str(ELDER_TOPICS.get("Custom builds & Forced Balance","Try Forced Balance in Studio."))
 elif "teacher" in q:reply=str(ELDER_TOPICS.get("Teacher review","Ask your teacher."))
 elif "market" in q or "commerce" in q or "business" in q or "marketing" in q:reply="For your first market day, press Basic setup: 30 market cash buys five sorted ore units and sets beginner prices. Choose a day duration, press Open Market, and return to Reports after the timer. For more control, collect mine materials, prepare goods at Crossroads Market, target a customer group and set your price, advertising channel and message. Make a forecast, run one business day, then compare sales, stock costs, advertising and profit in Reports. Profile shows mine levels separately from commerce results. Download your business report for your teacher. Sales are not profit—my wool accountant insists on that."
 elif "showcase" in q or "submission" in q or "feedback" in q:reply=str(ELDER_TOPICS.get("Create, share & Showcase","Open Studio → Projects & Showcase."))
 elif "lab" in q or "studio" in q or "code" in q or "creation" in q:reply="Studio has six connected labs: Hero Workshop, Ability Lab, Behaviour Lab, Enemy Lab, Object Lab and Realm Builder. Projects & Showcase connects testing, frozen submissions, useful feedback and teacher-curated publishing. Load an example, change one thing, test, then save/export. The code levels and teaching notes help explain why your change works. Partner Up allows two students to build together. Back up your player ZIP before changing computers."
 elif "mine" in q or "mining" in q or "diggers" in q:reply=str(ELDER_TOPICS.get("Idle Mining • minerals","Visit Idle Mining.")) # Deepwell Mine is your own idle operation. Enter west of town below Ram Descent, or use Visit my mine on Profile. Collect its separate gold, ore and gems, hire diggers and upgrade airflow, lifts and storage. It keeps producing between visits, with 24-hour offline catch-up and safe full-depot pauses. Download your profile to keep it on another computer."
 elif "weekly" in q:reply=str(ELDER_TOPICS.get("Weekly activities","Open Weekly activities in Adventures."))
 elif "daily" in q or "mission" in q or "glow" in q:reply=str(ELDER_TOPICS.get("Daily Mission & glow","Check today’s mission in Adventures."))
 elif "charge" in q or "hold" in q:reply=str(ELDER_TOPICS.get("Charged attacks & aiming","Hold, aim and release."))
 elif "joke" in q or "funny" in q:reply="Why did the ram bring a ladder to the dungeon? He heard the difficulty was going up. I shall see myself out… slowly."
 elif "thank" in q:reply="You’re welcome! Knowledge shared is knowledge multiplied. Unlike my biscuits, which mysteriously divide."
 elif "who are you" in q:reply="I’m the Elder Ram: keeper of knowledge, collector of stories, and undefeated champion of sitting on this spot."
 elif "tutorial" in q or "new game" in q:reply=str(ELDER_TOPICS.get("Returning or sharing a computer","New game starts First Steps; Continue resumes town."))
 elif "battleground" in q or "barrack" in q:reply=str(ELDER_TOPICS.get("Battlegrounds","Build armies from your barracks and destroy the opposing heart."))
 elif "continue" in q or "practice run" in q:reply="Defeated alone? Continue restores full health in the same battle with your XP and abilities. That whole attempt becomes practice: no mastery, records or completion unlocks. Enemy discoveries still save. Play again starts a fresh attempt that can earn progress."
 elif "unlock realm" in q or "locked realm" in q:reply="Whispering Grove and Ember Quarry start open. Beat either to open Honeyglass Gardens and Firstbell Elementary; beat either of those to open Sunfield Expanse and Frostbound Rink. Beat either moderate adventure to open all medium realms. Three different medium wins open challenging; one challenging win opens hard; four different hard wins open expert; two expert wins open Extreme. Co-op clears count too. Playtest opens every realm for testing. Mining shafts 5–10 need a cleared Descent floor 5; shafts 11–20 need floor 10."
 elif "arena" in q or "spectat" in q or "leaderboard" in q:reply="The stadium starts at level 10 unless Opening Act is enabled. Choose teams, a map, bots or a spectator host before hosting. The bottom-left Leaderboard button shows live damage, kills, hero KOs and deaths. Bot matches do not award arena trophies."
 elif "descent" in q:reply="Watch the XP bar and protect your health: clearing a floor no longer gives a free heal. Bring a support hero or food, and invite up to three friends."
 elif "gate" in q or "defen" in q:reply="Defend three outposts and their long roads. Up to three heroes can play; marching guards share bounty. Buy upgrades at buildings. Clear the wave-30 guardian to earn the town wall."
 elif "lodge" in q or "challenge" in q or "trial" in q or "potion" in q or "gather" in q:reply=ELDER_TOPICS.get("Lodges, gathering & potions","Gather ingredients, brew potions and try the Challenge Lodge.")
 elif "cosmetic" in q or "ribbon" in q:reply="Visit Gleam Atelier to preview your current hero, inspect locked styles and equip earned effects. Its Competitive tab explains server-compared weekly top-ten and lifetime top-five styles; those appear in multiplayer lobbies only. Titles & ribbons opens your Journey collection. Appearance effects never add combat power."
 elif "fps" in q or "lag" in q or "crash" in q or "sound" in q:reply="Open main-menu Options to lower the FPS cap, use school mode, mute sound or download a diagnostic report. The downloadable edition uses the same multiplayer rooms."
 elif "food" in q or "poison" in q:reply="Cleansing food is eaten when its matching harmful effect arrives. Healing food is eaten at its listed health threshold. You can only pack one."
 elif "save" in q or "profile" in q or "account" in q:reply="Open Profile to download your save. Upload it on another device. There is no login server, so export your newest progress before leaving."
 elif "master" in q or "title" in q:reply="Clear different realms and deal real combat damage to earn both techniques and your master title. Crit tiers arrive after 3, 6 and 9 successful clears. Techniques are optional; tuning points always have trade-offs."
 elif "friend" in q or "coop" in q or "code" in q:reply="Choose a multiplayer activity, host a room and share its code, or browse Public Rooms. Change heroes in the waiting room; everyone should use the current game build."
 elif "die" in q or "death" in q:reply="Tessa welcomes you at the healer house. Your chosen hero and earned mastery remain. Unused food remains packed."
 elif "level" in q or "attack" in q or "control" in q:reply="Move with WASD, interact with E, primary with left mouse, secondary with right mouse at level 3, and special with Space at level 6. Touch controls provide the same actions."
 elif "quest" in q:reply="Follow the forest path past training, speak to the villagers and open your journal for the next objective."
 elif "water" in q or "build" in q or "town" in q:reply="Water the three marked flowerbeds using E or Interact. Speak to town vendors, donate a food item and clear adventures. Open Town projects to see exact requirements."
 elif "hello" in q or "hi"==q:reply="Good to see you! Try a hero you haven't played, or help finish a town project."
 elif "stuck" in q or "bug" in q:reply="Tell your teacher which hero, realm and action caused the problem. Download your profile before refreshing when possible."
 elif "best" in q or "strong" in q:reply="The best hero is one whose strengths you enjoy. Try ranged attacks, melee, support and control in the training yard."
 notice.text="Elder Ram: "+reply
func enable_teacher()->void:
 var session:Node=get_node("/root/FXDevSession")
 if session.active:return
 # Save normal progress first; from this point all profile writes are memory-only.
 save()
 if not arcade:game.save_profile()
 game.journey.save();game.provisions.save()
 session.begin();data.teacher=true;fishing_records.state();mine.preview();flash=1.5
 for id in game.manifest.characters:
  var rec:=record(str(id));rec.clears=12;rec.damage=85000;rec.realms=game.manifest.regions.duplicate();rec.points=6
 for id in PROJECTS:data.town[id]=true
 data.bread=true;save()
 game.journey.data.unlocked=game.journey.TITLES.duplicate();game.journey.save()
 if not arcade:
  game.add_float_text(game.position_in_world,"GAME DEV • ALL UNLOCKED",Color("#ffcf60"))
 notice.text="Elder Ram: Game Dev mode is temporary. Everything is unlocked for testing. No scores, unlocks, saves or profile transfers count. Exit via Profile to restore your normal account; refreshing also exits.";render()
func disable_teacher()->void:
 get_node("/root/FXDevSession").finish()
func blocked_transfer()->bool:
 if not preload("res://scripts/profile_store.gd").testing():return false
 notice.text="Exit testing mode first. Profile saving, downloads, uploads and resets are disabled during testing."
 return true
func save_names()->Array:
 var names:Array=FILES.duplicate()
 var regions:Array=game._json("res://content/manifest.json").get("regions",[]) if arcade else game.manifest.get("regions",[])
 for id in regions:names.append("fx_coop_"+str(id)+".json")
 return names
func bundle()->Dictionary:
 if preload("res://scripts/profile_store.gd").testing():return {}
 var files:Dictionary={}
 for name in save_names():
  if FileAccess.file_exists("user://"+name):
   var value:Variant=JSON.parse_string(FileAccess.get_file_as_string("user://"+name))
   if value is Dictionary:files[name]=value
 if bool(data.teacher):files=data.get("backup_saves",files).duplicate(true)
 return {"format":"fx-crossroads-profile","version":1,"exported":Time.get_datetime_string_from_system(true),"progress":teacher_backup.duplicate(true) if bool(data.teacher) and not teacher_backup.is_empty() else data.duplicate(true),"saves":files}
func export_profile()->void:
 if blocked_transfer():return
 if arcade or game.mode!="town":notice.text="Return to town before uploading or downloading a profile.";return
 save();game.save_profile();game.journey.save();game.provisions.save()
 var payload:=bundle()
 var exported_backup:Dictionary=data.get("backup_reminder",{}).duplicate(true)
 exported_backup.pending=false;exported_backup.last_export=Time.get_datetime_string_from_system(true);payload.progress.backup_reminder=exported_backup
 var path="user://fx_player_bundle.zip"
 if preload("res://scripts/studio_bundle.gd").make(payload,path)!=OK:notice.text="Could not create profile ZIP.";return
 if OS.has_feature("web"):
  JavaScriptBridge.download_buffer(FileAccess.get_file_as_bytes(path),"crossroads-player.zip","application/zip");preload("res://scripts/release_support.gd").exported(self);notice.text="Download requested: crossroads-player.zip • includes heroes, abilities and Studio draft."
 else:
  native_dialog=FileDialog.new();native_dialog.access=FileDialog.ACCESS_FILESYSTEM;native_dialog.file_mode=FileDialog.FILE_MODE_SAVE_FILE;native_dialog.add_filter("*.zip","Crossroads player + Studio");native_dialog.current_file="crossroads-player.zip";add_child(native_dialog)
  native_dialog.file_selected.connect(func(selected:String):
   if DirAccess.copy_absolute(path,selected)==OK:preload("res://scripts/release_support.gd").exported(self);notice.text="Player ZIP saved, including Studio creations."
   else:notice.text="Could not save ZIP. Choose another folder."
   native_dialog.queue_free()
  );native_dialog.popup_centered(Vector2i(900,520))
func pick_import()->void:
 if blocked_transfer():return
 if arcade or game.mode!="town":notice.text="Return to town before uploading or downloading a profile.";return
 if OS.has_feature("web"):
  JavaScriptBridge.eval("(()=>{const p=document.createElement('input');p.type='file';p.accept='.zip,.json,application/zip,application/json';p.style.position='fixed';p.style.left='-9999px';document.body.appendChild(p);p.oncancel=()=>p.remove();p.onchange=async()=>{const f=p.files[0];if(!f){p.remove();return;}if(f.size>134217728){window.fxCrossroadsImport('TOO_LARGE');p.remove();return;}try{if(f.name.toLowerCase().endsWith('.zip')){const r=new FileReader();r.onload=()=>window.fxCrossroadsImport('ZIP:'+String(r.result).split(',')[1]);r.readAsDataURL(f);}else{window.fxCrossroadsImport(await f.text());}}catch(e){window.fxCrossroadsImport('READ_FAILED');}finally{p.remove();}};p.click();})()",true)
 else:
  native_dialog=FileDialog.new();native_dialog.access=FileDialog.ACCESS_FILESYSTEM;native_dialog.file_mode=FileDialog.FILE_MODE_OPEN_FILE;native_dialog.add_filter("*.zip,*.json","Crossroads player profile");add_child(native_dialog)
  native_dialog.file_selected.connect(func(path:String):
   if path.to_lower().ends_with(".zip"):import_zip(path)
   else:read_import(FileAccess.get_file_as_string(path))
   native_dialog.queue_free()
  );native_dialog.popup_centered(Vector2i(900,520))
func import_web(args:Array)->void:
 if args.size()>0:
  var value=str(args[0])
  if value.begins_with("ZIP:"):
   if value.length()>178956972:notice.text="ZIP too large.";return
   var path="user://fx_import_bundle.zip";var f=FileAccess.open(path,FileAccess.WRITE)
   if f!=null:f.store_buffer(Marshalls.base64_to_raw(value.substr(4)));f.close();import_zip(path)
  else:read_import(value)
func read_import(content:String)->void:
 if blocked_transfer():return
 if arcade or game.mode!="town":notice.text="Return to town before uploading or downloading a profile.";return
 if content.length()>67108864:notice.text="Profile is too large. Choose a Crossroads profile download.";return
 var parser:=JSON.new()
 if parser.parse(content)!=OK:notice.text="Could not read this profile. Your current progress is unchanged.";return
 var parsed:Variant=parser.data
 if not validate(parsed):notice.text="This isn't a supported Crossroads profile. Your current progress is unchanged.";return
 pending=parsed;import_preview()
func import_zip(path:String)->void:
 if blocked_transfer() or arcade or game.mode!="town":return
 var result=preload("res://scripts/studio_bundle.gd").read(path)
 if not result.error.is_empty():notice.text=result.error;return
 if not validate(result.payload):notice.text="Invalid profile. Current progress is unchanged.";return
 pending=result.payload;import_preview()
func validate(value:Variant)->bool:
 for kind in ["object","realm"]:
  if value is Dictionary and value.has("studio_"+kind+"_draft") and not preload("res://scripts/studio_world_project.gd").validate(kind,value["studio_"+kind+"_draft"]).is_empty():return false
 if value is Dictionary and value.has("music") and not preload("res://scripts/music_library.gd").validate(value.music).is_empty():return false
 for kind in ["enemy","behavior"]:
  if value is Dictionary and value.has("studio_"+kind+"_draft"):
   if not load("res://scripts/studio_"+("enemy_project" if kind=="enemy" else "behavior")+".gd").validate(value["studio_"+kind+"_draft"]).is_empty():return false
 if value is Dictionary and value.has("studio") and not preload("res://scripts/studio_library.gd").validate(value.studio).is_empty():return false
 if value is Dictionary and value.has("studio_draft") and not preload("res://scripts/workshop_project.gd").validate(value.studio_draft).is_empty():return false
 if not value is Dictionary or str(value.get("format",""))!="fx-crossroads-profile" or int(value.get("version",0))!=1:return false
 if not value.get("progress") is Dictionary or not value.get("saves") is Dictionary:return false
 if value.progress.has("analytics_id") and (not value.progress.analytics_id is String or not preload("res://scripts/play_insights.gd").valid_id(value.progress.analytics_id)):return false
 var progress:Dictionary=value.progress
 if not progress.get("tasks",{}) is Dictionary:return false
 if not progress.get("tasks",{}).get("realms",[]) is Array:return false
 var encounters:Variant=progress.get("encounters",{})
 if not encounters is Dictionary or encounters.size()>256:return false
 for list in encounters.values():
  if not list is Array or list.size()>256:return false
  for kind in list:
   if not kind is String or kind.length()>100:return false
 if not progress.get("favourites",[]) is Array or progress.get("favourites",[]).size()>256:return false
 for id in progress.get("favourites",[]):
  if not id is String or id.length()>32:return false
 if not progress.get("heroes",{}) is Dictionary or not progress.get("town",{}) is Dictionary or not progress.get("tasks",{}) is Dictionary:return false
 var known_heroes=JSON.parse_string(FileAccess.get_file_as_string("res://content/manifest.json")).characters
 if not progress.get("mastery_seen",{}) is Dictionary or progress.get("mastery_seen",{}).size()>known_heroes.size():return false
 for id in progress.get("mastery_seen",{}):
  var seen=progress.mastery_seen[id]
  if id not in known_heroes or not (seen is int or seen is float) or not is_finite(float(seen)) or float(seen)<0 or float(seen)>4 or float(seen)!=floor(float(seen)):return false
 if progress.has("education"):
  if not progress.education is Dictionary or progress.education.size()!=1 or not progress.education.get("studio_seconds",0) is float and not progress.education.get("studio_seconds",0) is int:return false
  if not is_finite(float(progress.education.studio_seconds)) or float(progress.education.studio_seconds)<0 or float(progress.education.studio_seconds)>315360000:return false
 if bool(progress.get("teacher",false)):return false
 if progress.has("elder_guidance") and not preload("res://scripts/elder_guidance.gd").valid(progress.elder_guidance):return false
 if progress.has("glimmers") and not preload("res://scripts/glimmers.gd").valid(progress.glimmers):return false
 if progress.has("competitive") and not preload("res://scripts/competitive_progress.gd").valid(progress.competitive):return false
 if progress.has("giant_garden") and not preload("res://scripts/giant_garden.gd").valid(progress.giant_garden):return false
 if progress.has("gardening") and not preload("res://scripts/gardening.gd").valid(progress.gardening):return false
 if progress.has("named_records") and not preload("res://scripts/named_records.gd").valid(progress.named_records):return false
 if progress.has("community_records") and not preload("res://scripts/community_records.gd").valid(progress.community_records):return false
 if progress.has("waylight") and not preload("res://scripts/waylight_progress.gd").valid(progress.waylight):return false
 if progress.has("fishing") and not preload("res://scripts/fishing_records.gd").valid(progress.fishing):return false
 if progress.has("lodges") and not preload("res://scripts/lodge_catalog.gd").valid(progress.lodges):return false
 if progress.has("mine") and not preload("res://scripts/idle_mine.gd").valid(progress.mine):return false
 if progress.has("media_portfolio") and not preload("res://scripts/media_portfolio.gd").valid(progress.media_portfolio):return false
 if progress.has("commerce") and not preload("res://scripts/commerce.gd").valid(progress.commerce):return false
 if progress.has("rolling_damage") and not preload("res://scripts/rolling_crowns.gd").valid(progress.rolling_damage):return false
 if progress.has("weekly_activities") and not weekly.valid(progress.weekly_activities):return false
 if progress.has("cosmetic_rankings") and not preload("res://scripts/cosmetic_rankings.gd").valid(progress.cosmetic_rankings):return false
 if progress.has("cosmetics") and not cosmetics.valid(progress.cosmetics):return false
 if progress.has("daily") and not daily.valid(progress.daily):return false
 if progress.has("card") and not card.valid(progress.card):return false
 if not progress.get("realm_counts",{}) is Dictionary:return false
 for id in progress.get("realm_counts",{}):
  var count:Variant=progress.realm_counts[id]
  if not id is String or not (count is int or count is float) or not is_finite(float(count)) or float(count)<0 or float(count)>1000000:return false
 if not progress.get("tasks",{}).get("coop_realms",[]) is Array:return false
 for key in ["talk","water","food","quests","clears","realm_clears","damage","silverfall","coop_clears","coop_distinct","coop_descent","coop_defense","defense_best","defense30"]:
  var number:Variant=progress.get("tasks",{}).get(key,0)
  if not (number is float or number is int) or not is_finite(float(number)) or float(number)<0:return false
 for key in value.saves:
  if key not in save_names() or not value.saves[key] is Dictionary:return false
  var stored:Dictionary=value.saves[key]
  if key=="fx_prepared_supply.json" and not preload("res://scripts/prepared_supply.gd").valid(stored,game.items):return false
  if key=="fx_education_access.json" and not preload("res://scripts/education_access.gd").valid(stored):return false
  if key=="fx_teacher_classes.json" and not load("res://scripts/teacher_store.gd").valid(stored):return false
  if key=="fx_learning.json" and not preload("res://scripts/learning_store.gd").valid(stored):return false
  if key=="crossroads_profile.json" and not stored.get("records",{}) is Dictionary:return false
  if key=="fx_journey.json" and (not stored.get("quest",{}) is Dictionary or not stored.get("unlocked",[]) is Array):return false
  if str(key).begins_with("fx_quests_"):
   if not stored.get("states",{}) is Dictionary:return false
   for state in stored.get("states",{}).values():
    if not state is Dictionary or not state.get("targets",[]) is Array:return false
 for id in progress.get("heroes",{}):
  if not id is String or id.length()>32:return false
  var rec:Variant=progress.heroes[id]
  if not rec is Dictionary or not rec.get("realms",[]) is Array or not rec.get("tuning",[]) is Array:return false
  if rec.has("duet_clear") and not rec.duet_clear is bool:return false
  for key in ["clears","damage","points"]:
   var number:Variant=rec.get(key,0)
   if not (number is float or number is int) or not is_finite(float(number)) or float(number)<0:return false
  for number in rec.get("tuning",[]):
   if not (number is float or number is int) or not is_finite(float(number)):return false
 for key in ["talked","watered","quest_ids"]:
  if not progress.get(key,[]) is Array:return false
 return true
func import_preview()->void:
 for child in body.get_children():body.remove_child(child);child.queue_free()
 text("Start a new player?" if pending.has("new") else "Upload preview: "+str(pending.progress.get("name","Traveler"))+"\nExported: "+str(pending.get("exported","unknown"))+"\nHeroes with progress: "+str(pending.progress.get("heroes",{}).size()))
 text("This replaces this device’s progress and Studio library. Download first to keep them. Custom heroes: "+str(pending.get("studio",{}).get("heroes",{}).size())+" • abilities: "+str(pending.get("studio",{}).get("abilities",{}).size())+" • enemies: "+str(pending.get("studio",{}).get("enemies",{}).size())+" • behaviours: "+str(pending.get("studio",{}).get("behaviors",{}).size()))
 button(body,"Download current profile first",export_profile);button(body,"Confirm replacement",apply_import);button(body,"Cancel",func():pending={};render())
func apply_import()->void:
 var account=get_node_or_null("/root/FXAccount")
 if account!=null and account.loaded and not account.applying:notice.text="Sign out of the cloud account before replacing or resetting this device profile.";return
 if blocked_transfer():return
 if arcade or game.mode!="town":notice.text="Return to town before uploading or downloading a profile.";return
 var fresh:=pending.has("new")
 if not fresh and not validate(pending):return
 if get_tree().root.has_meta("fx_local_recovery"):get_tree().root.remove_meta("fx_local_recovery")
 if not fresh:
  var music_issue=preload("res://scripts/music_library.gd").save_data(pending.get("music",preload("res://scripts/music_library.gd").fresh()))
  if not music_issue.is_empty():notice.text=music_issue;return
  var issue=preload("res://scripts/studio_library.gd").save_data(pending.get("studio",{"heroes":{},"abilities":{}}))
  if not issue.is_empty():notice.text=issue;return
  for kind in ["enemy","behavior"]:
   DirAccess.remove_absolute("user://fx_"+kind+"_lab.json")
   if pending.has("studio_"+kind+"_draft"):
    var file=FileAccess.open("user://fx_"+kind+"_lab.json",FileAccess.WRITE)
    if file!=null:file.store_string(JSON.stringify(pending["studio_"+kind+"_draft"]))
  for kind in ["object","realm"]:
   DirAccess.remove_absolute("user://fx_"+kind+"_lab.json")
   if pending.has("studio_"+kind+"_draft"):
    var f=FileAccess.open("user://fx_"+kind+"_lab.json",FileAccess.WRITE)
    if f!=null:f.store_string(JSON.stringify(pending["studio_"+kind+"_draft"]))
  if pending.has("studio_draft"):
   var f=FileAccess.open(preload("res://scripts/workshop_project.gd").PATH,FileAccess.WRITE)
   if f!=null:f.store_string(JSON.stringify(pending.studio_draft))
  else:DirAccess.remove_absolute(preload("res://scripts/workshop_project.gd").PATH)
 recovery_required=false
 data=defaults()
 if not fresh:
  data.merge(pending.progress,true)
  var tasks:Dictionary=defaults().tasks;tasks.merge(data.tasks,true);data.tasks=tasks
 card.state();mine.setup(self);commerce.setup(self)
 data.teacher=false;data.erase("teacher_backup");data.name=str(data.get("name","Traveler")).left(32)
 for id in data.heroes:
  var rec:Dictionary=data.heroes[id];rec.realms=rec.get("realms",[]);rec.technique=bool(rec.get("technique",false));rec.final_technique=bool(rec.get("final_technique",false));rec.points=clampi(int(rec.get("points",0)),0,6);rec.tuning=sanitize_build(rec).tuning;rec.damage=clampf(float(rec.get("damage",0)),0,1000000000);rec.clears=clampi(int(rec.get("clears",0)),0,1000000)
 for name in save_names():
  preload("res://scripts/profile_store.gd").erase("user://"+name)
  if not fresh and pending.saves.has(name):
   var f:=FileAccess.open("user://"+name,FileAccess.WRITE)
   if f!=null:f.store_string(JSON.stringify(pending.saves[name]))
 preload("res://scripts/profile_store.gd").erase(PATH)
 save();get_tree().root.remove_meta("fx_hero") if get_tree().root.has_meta("fx_hero") else null;game.provisions.packed="";game.provisions.crop="empty"
 get_tree().reload_current_scene()
func unspent_points(id:String)->int:
 var rec:Dictionary=data.heroes.get(id,{})
 var tuning:Array=rec.get("tuning",[0,0,0])
 var used:=0
 for value in tuning:used+=absi(int(value))
 return maxi(0,mini(4,int(rec.get("points",0)))-used)
func acknowledge_mastery()->void:
 if not data.has("mastery_seen"):data.mastery_seen={}
 var changed=false
 for id in data.heroes:
  var earned=mini(4,int(data.heroes[id].get("points",0)))
  if int(data.mastery_seen.get(id,0))<earned:data.mastery_seen[id]=earned;changed=true
 if changed:save()
func refresh_point_notice()->void:
 point_notice=false
 for id in data.heroes:
  if unspent_points(str(id))>0 and mini(4,int(data.heroes[id].get("points",0)))>int(data.get("mastery_seen",{}).get(id,0)):point_notice=true;break
 if is_instance_valid(mastery_tab):
  mastery_tab.modulate=Color("#ffe1a0") if point_notice else Color.WHITE
  mastery_tab.text="Mastery •" if point_notice else "Mastery"
  mastery_tab.tooltip_text="Unspent mastery points available" if point_notice else "Hero mastery"
func _process(delta:float)->void:
 daily.step(delta);cosmetics.step(delta);crowns.step(delta);mine.step(delta);commerce.step(delta);gardening.step(delta);community.step(delta)
 if arcade:return
 point_check-=delta
 if point_check<=0:point_check=.4;refresh_point_notice()
 flash=maxf(0,flash-delta)
 var town:bool=game.mode=="town"
 var quick:Button=get_node("Quick")
 quick.visible=town and game.menu.is_empty() and (game.get("session_menu")==null or game.session_menu.page.is_empty())
 preload("res://scripts/town_top_bar.gd").place(quick,"profile",get_viewport().get_visible_rect().size)
 if point_notice!=applied_glow:
  applied_glow=point_notice;quick.add_theme_stylebox_override("normal",points_glow if point_notice else quick_normal)
 if point_notice and quick.visible:
  points_glow.bg_color=Color("#294653").lerp(Color("#69582d"),.22+.12*sin(Time.get_ticks_msec()*.004))
 quick.text="Mastery for this hero" if game.menu=="characters" else "Profile / Mastery / Town"
 fit_profile_panel()
 if game.menu=="elder" and last_menu!="elder":
  var guidance=game.presentation.elder_guide.pending()
  if not guidance.is_empty():game.presentation.elder_guide.begin(guidance)
  else:talk("elder");open_page("elder")
 if game.menu in ["supplies","healer","seedhouse","food","wayfinder"] and game.menu!=last_menu:talk(game.menu)
 last_menu=game.menu
 tick+=delta
 if tick>5:tick=0;save()
 if not town or not game.menu.is_empty():return
 if game.town_life.events.interact(game):return
 for item in [["fellowship",Vector2(1800,1550)],["relay",game.town_v109.ENTRIES.relay],["observatory",Vector2(1720,480)]]:
  if bool(data.town.get(item[0],false)) and game.position_in_world.distance_to(item[1])<65:
   game.hint="E • "+str(PROJECTS[item[0]].name)
   if Input.is_action_just_pressed("interact"):
    open_page("town");notice.text="Plan roles, pack food and check each hero’s abilities before a team adventure." if item[0]=="fellowship" else "The bakery now offers Hearty Stew: one free provision per successful adventure." if item[0]=="relay" else "Party records: "+str(data.tasks.get("coop_clears",0))+" co-op clears • Descent "+str(data.tasks.get("coop_descent",0))+" floors • Defence "+str(data.tasks.get("coop_defense",0))+" waves."
   return
 for n in 3:
  var point:Vector2=WATER_BEDS[n]
  if game.position_in_world.distance_to(point)<60:
   game.hint="E  Water flowerbed "+str(n+1)
   if Input.is_action_just_pressed("interact"):water(str(n));game.message="Flowerbed watered.";game.message_time=3
func town_blocked(point:Vector2)->bool:
 for id in ["fellowship","relay"]:
  if card_building_rect(id).has_point(point):return true
 return Rect2(2100,1420,115,140).has_point(point)
func card_building_rect(id:String)->Rect2:
 return game.town_v109.solid_rect(id)
func draw_card_projects(canvas:Node,camera:Vector2,font:Font)->void:
 game.town_v109.draw_projects(canvas,camera,data)
 if bool(data.town.get("observatory",false)):
  var p:=Vector2(1720,310)-camera;canvas.draw_line(p,p+Vector2(32,-27),Color("#c5b782"),14);canvas.draw_circle(p+Vector2(33,-28),10,Color("#8bcece"));canvas.draw_line(p,p+Vector2(-17,25),Color("#ae9367"),4);canvas.draw_line(p,p+Vector2(17,25),Color("#ae9367"),4)
  canvas.draw_string(font,p+Vector2(-74,65),"EXPEDITION OBSERVATORY",HORIZONTAL_ALIGNMENT_LEFT,-1,12,Color("#f0dbab"))
 if bool(data.town.get("bastion",false)):
  # Match the existing north fence points. The gate opening stays walkable.
  for piece in game.town_art:
   if str(piece.sprite)!="town_fence":continue
   var p:Vector2=piece.pos-camera;var w:=float(piece.size.x)
   canvas.draw_rect(Rect2(p+Vector2(-w*.5,-26),Vector2(w,45)),Color("#687e85"))
   for row in 3:
    for n in maxi(1,int(w/28)):canvas.draw_rect(Rect2(p+Vector2(-w*.5+n*28+(14 if row%2 else 0),-24+row*14),Vector2(25,11)),Color("#a7b3ac"))
   for n in maxi(1,int(w/40)):canvas.draw_rect(Rect2(p+Vector2(-w*.5+n*40,-36),Vector2(20,15)),Color("#99aaa5"))
  for x in [760,1040]:
   var p:=Vector2(x,240)-camera;canvas.draw_rect(Rect2(p-Vector2(21,83),Vector2(42,103)),Color("#879b9d"));canvas.draw_rect(Rect2(p-Vector2(26,91),Vector2(52,16)),Color("#bac3b3"));canvas.draw_line(p-Vector2(18,56),p+Vector2(18,15),Color("#465768"),6)
  canvas.draw_string(font,Vector2(795,337)-camera,"VETERAN GATE • WAVE 30",HORIZONTAL_ALIGNMENT_LEFT,-1,14,Color("#f0dbab"))
func draw_town(canvas:Node,camera:Vector2)->void:
 if arcade or game.mode!="town":return
 var font:Font=preload("res://assets/fonts/CrossroadsUI.ttf")
 draw_card_projects(canvas,camera,font)
 game.town_v109.draw_future_sites(canvas,camera,data)
 if flash>0:canvas.draw_rect(Rect2(Vector2.ZERO,canvas.VIEW),Color(1,1,.85,minf(.85,flash)))
 for n in 3:
  var p:Vector2=WATER_BEDS[n]-camera
  canvas.draw_rect(Rect2(p-Vector2(25,15),Vector2(50,30)),Color("#604b32"))
  for k in 4:canvas.draw_circle(p+Vector2(k*10-15,0),5,Color("#75bb89") if str(n) in data.watered else Color("#a8aa6b"))
 if bool(data.town.get("flowers",false)):
  var bench:Vector2=Vector2(1300,960)-camera;canvas.draw_rect(Rect2(bench,Vector2(100,14)),Color("#ad8050"));canvas.draw_rect(Rect2(bench+Vector2(0,-17),Vector2(100,10)),Color("#c59a65"))
  for side in [10,80]:canvas.draw_line(bench+Vector2(side,12),bench+Vector2(side,30),Color("#4f443b"),5)
  for n in 4:
   var butterfly:Vector2=Vector2(1360+n*30+sin(Time.get_ticks_msec()*.002+n)*25,1130+cos(Time.get_ticks_msec()*.003+n)*18)-camera
   canvas.draw_circle(butterfly+Vector2(-4,0),4,Color("#eec4e9"));canvas.draw_circle(butterfly+Vector2(4,0),4,Color("#d3c2ed"))
  for n in 12:canvas.draw_circle(Vector2(1300+n%2*12,1000+n/2*24)-camera,5,Color("#f1c6df"))
 if bool(data.town.get("mill",false)):game.town_v109.draw_mill(canvas,camera)
 if bool(data.town.get("bakery",false)):
  preload("res://scripts/town_v176.gd").draw_bakery(canvas,camera)
 if bool(data.town.get("statue",false)):
  var p:=Vector2(950,1122)-camera
  canvas.draw_rect(Rect2(p-Vector2(68,14),Vector2(136,24)),Color("#334a4c"));canvas.draw_rect(Rect2(p-Vector2(68,14),Vector2(136,24)),Color("#b5a276"),false,1)
  canvas.draw_string(font,p+Vector2(-64,3),str(data.title),HORIZONTAL_ALIGNMENT_CENTER,128,12,Color("#eddaa3"))
 if bool(data.town.get("market",false)):canvas.draw_string(font,Vector2(1160,710)-camera,"COVERED MARKET • 1 CC SAVINGS",HORIZONTAL_ALIGNMENT_LEFT,-1,16,Color("#ffe6a1"))
 if bool(data.town.get("library",false)):
  var p:=Vector2(1020,1700)-camera;canvas.draw_rect(Rect2(p,Vector2(100,40)),Color("#8d6854"));canvas.draw_string(font,p+Vector2(5,25),"READING ROOM",HORIZONTAL_ALIGNMENT_LEFT,-1,12)
  for n in 8:canvas.draw_rect(Rect2(p+Vector2(n*12,-18),Vector2(9,18)),Color("#d8b382") if n%2==0 else Color("#8fc0b8"))
 if bool(data.town.get("clinic",false)):canvas.draw_string(font,Vector2(1840,850)-camera,"SUPPLY WING • TEA AVAILABLE",HORIZONTAL_ALIGNMENT_LEFT,-1,14,Color("#aee3d4"))

func tuning_text(axis:int,value:int)->String:
 if value==0:return "Neutral • 0 points"
 if axis==0:return "%+d%% damage / %+d%% cooldown" % [value*4,value*5]
 if axis==1:return "%+d%% health / %+d%% movement" % [value*5,-value*3]
 return "%+d%% damage taken / %+d%% attack" % [-value*4,-value*3]

func fit_profile_panel()->void:
 var view=get_viewport().get_visible_rect().size
 var base=Vector2(1060,640)
 if page in ["community","gardening"]:base=Vector2(clampf(view.x-40,400,1240),clampf(view.y-40,640,860))
 root.size=base;root.scale=Vector2.ONE*minf(1,minf((view.x-24)/base.x,(view.y-24)/base.y));root.position=(view-root.size*root.scale)*.5

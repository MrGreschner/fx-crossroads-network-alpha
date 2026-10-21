extends RefCounted
## Read-only field guide: reads authored base stats and the profile's discovered encounters.
var game:Node
var entries:Array=[]
var rows:VBoxContainer
var detail:VBoxContainer
var query:=""
func known_entries()->Array:
 var merged:Dictionary={}
 if bool(game.legacy.data.get("teacher",false)):
  for realm in game.manifest.regions:
   if realm in ["town","practice","first_steps"]:continue
   for kind in game.catalog_ui.roster(str(realm)):
    var key=canonical_kind(str(kind))
    if not merged.has(key):merged[key]={"kind":key,"realm":str(realm),"places":[]}
    var place=str(game.realms.get(realm,{}).get("name",realm))
    if place not in merged[key].places:merged[key].places.append(place)
 for realm in game.legacy.data.get("encounters",{}):
  for kind in game.legacy.data.encounters[realm]:
   var key:=canonical_kind(str(kind))
   if not merged.has(key):merged[key]={"kind":key,"realm":str(realm),"places":[]}
   var place=str(game.realms.get(realm,{}).get("name",realm))
   if place not in merged[key].places:merged[key].places.append(place)
 var result:Array=merged.values()
 result.sort_custom(func(a,b):return enemy_name(a).naturalnocasecmp_to(enemy_name(b))<0)
 return result
func canonical_kind(kind:String)->String:
 if kind.begins_with("boss:") and game.enemy_types.has(kind.substr(5)):return kind.substr(5)
 return kind
func enemy_name(entry:Dictionary)->String:
 var kind:=str(entry.kind)
 if kind.begins_with("boss:"):return str(game.realms.get(entry.realm,{}).get("boss_name",kind.substr(5).replace("_"," ").capitalize()))
 return str(game.enemy_types.get(kind,{}).get("name",kind.replace("_"," ").capitalize()))
func stats(entry:Dictionary)->Dictionary:
 var kind:=str(entry.kind)
 if not kind.begins_with("boss:"):
  var d:Dictionary=game.enemy_types.get(kind,{}).duplicate(true);var realm:Dictionary=game.realms.get(entry.realm,{})
  if kind==str(realm.get("boss_type","")) or kind==str(realm.get("boss_sprite","")):d.health=float(realm.get("boss_health",d.get("health",250)))
  return d
 var r:Dictionary=game.realms.get(entry.realm,{})
 var d:Dictionary={"health":r.get("boss_health",0),"behaviour":"boss","name":enemy_name(entry)}
 for key in ["boss_damage","boss_speed","boss_secondary"]:
  if r.has(key):d[key.trim_prefix("boss_")]=r[key]
 return d
func description(entry:Dictionary)->String:
 var d:=stats(entry);var lines:Array[String]=[]
 lines.append("Base health: "+str(d.get("health","Not specified"))+"    •    Hit damage: "+str(d.get("damage","Varies by attack")))
 lines.append("Movement speed: "+str(d.get("speed","Varies by phase"))+"    •    Detection reach: "+str(d.get("aggro_range","Varies")))
 var behaviour:=str(d.get("behaviour","chase"))
 var notes:Dictionary={"melee":"Closes in for close-range attacks.","charger":"Rushes toward targets. Step aside from its charge path.","custom":"Uses a specialised attack pattern. Watch its warning areas and timing.","chase":"Closes in for melee attacks. Keep space and watch its wind-up.","ranged":"Keeps distance and fires projectiles. Close the gap or use cover.","burst_ranged":"Keeps distance and fires bursts. Dodge the full burst, not just its first shot.","dual_ranged":"Keeps distance and fires paired projectiles.","homing":"Fires tracking shots. Use cover and change direction.","summoner":"Summons reinforcements. Pressure the summoner before minions surround you.","boss":"Uses phase attacks and warning areas. Watch the ground and leave room to dodge."}
 lines.append("BEHAVIOUR\n"+str(notes.get(behaviour,behaviour.replace("_"," ").capitalize()+" — watch its movement and warning effects.")))
 lines.append("ATTACKS")
 if not d.has("custom_attack") and behaviour!="boss":lines.append(("Ranged projectile" if behaviour in ["ranged","homing","dual_ranged","burst_ranged"] else "Close hit")+": "+str(d.get("damage",0))+" base damage.")
 for key in ["custom_attack","secondary","attack_style","skill","summon_type","shot_name","shot_damage","shot_style","shot_cooldown","shot_speed","secondary_cooldown","skill_cooldown","blast_radius","summon_cooldown","max_summons","burn_dps","poison_dps"]:
  if d.has(key):lines.append(key.replace("_"," ").capitalize()+": "+str(d[key]).trim_prefix("v43_").trim_prefix("school_").trim_suffix("_logic").replace("_"," "))
 if d.get("custom_attack","")=="lob":lines.append("Lobs a projectile that explodes on landing; move out of the marked area.")
 if bool(d.get("flying",false)):lines.append("Flying enemy — may cross terrain that blocks ground units.")
 lines.append("Seen in: "+", ".join(PackedStringArray(entry.places)))
 lines.append("These are authored base values. Difficulty, phases and multiplayer scaling may change live values. Some special attacks are scripted; their damage varies.")
 return "\n\n".join(PackedStringArray(lines))
func build(owner:Node,col:VBoxContainer)->void:
 game=owner;entries=known_entries()
 owner.town_services.button(col,"Enter a Mistglass Rift • build your own battle",func():owner.mistglass_rift.open())
 owner.town_services.text(col,"ENEMY FIELD GUIDE • "+str(entries.size())+" discovered",22)
 owner.town_services.text(col,"Mistglass lenses remember foes you have encountered. Explore realms to add enemies and bosses. Select a portrait to study it.",17)
 var search:=LineEdit.new();search.placeholder_text="Search discovered enemies…";search.custom_minimum_size.y=42;col.add_child(search)
 var split:=HBoxContainer.new();split.custom_minimum_size.y=365;split.size_flags_vertical=Control.SIZE_EXPAND_FILL;split.add_theme_constant_override("separation",18);col.add_child(split)
 var left:=ScrollContainer.new();left.custom_minimum_size.x=320;left.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;split.add_child(left)
 rows=VBoxContainer.new();rows.size_flags_horizontal=Control.SIZE_EXPAND_FILL;left.add_child(rows)
 var right:=ScrollContainer.new();right.size_flags_horizontal=Control.SIZE_EXPAND_FILL;right.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;split.add_child(right)
 detail=VBoxContainer.new();detail.size_flags_horizontal=Control.SIZE_EXPAND_FILL;detail.add_theme_constant_override("separation",12);right.add_child(detail)
 search.text_changed.connect(func(value:String):query=value;render_rows())
 query="";render_rows()
 if entries.is_empty():owner.town_services.text(detail,"Your field guide is empty. Meet enemies in a realm, then return here. Unseen enemy names and stats stay hidden.",21)
 else:select(entries[0])
func render_rows()->void:
 for child in rows.get_children():rows.remove_child(child);child.queue_free()
 var count:=0
 for entry in entries:
  if not query.is_empty() and not query.to_lower() in enemy_name(entry).to_lower():continue
  count+=1
  var b:Button=game.town_services.button(rows,enemy_name(entry),select.bind(entry));b.custom_minimum_size=Vector2(305,62)
  b.icon=game.catalog_ui.portrait(str(entry.realm),str(entry.kind));b.expand_icon=true;b.add_theme_constant_override("icon_max_width",44)
 if count==0:game.town_services.text(rows,"No discovered enemies match.",17)
func select(entry:Dictionary)->void:
 for child in detail.get_children():detail.remove_child(child);child.queue_free()
 var header:=HBoxContainer.new();detail.add_child(header)
 var image:=TextureRect.new();image.custom_minimum_size=Vector2(80,80);image.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;image.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;image.texture=game.catalog_ui.portrait(str(entry.realm),str(entry.kind));header.add_child(image)
 game.town_services.text(header,enemy_name(entry),25).modulate=Color("#ffdc96")
 game.town_services.text(detail,description(entry),18)

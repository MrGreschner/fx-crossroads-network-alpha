extends RefCounted
## Approval comes from the downloaded public catalogue, never a local balance checkbox.
const POLICY=2
const NOTICE="PLAYTEST • Custom hero in play. This entire run is unofficial: no personal or community records."
static func hero_allowed(g:Node,id:String)->bool:
 if id.is_empty():return false
 var h:Dictionary=g.characters.get(id,{})
 if h.is_empty() or bool(h.get("npc_only",false)):return false
 if id in g.manifest.characters:return not h.has("studio_project")
 var service=g.get_tree().root.get_node_or_null("FXCommunityHeroes")
 if service==null or not service.catalog.has(id):return false
 var approved:Dictionary=service.catalog[id].project
 return h.has("studio_project") and preload("res://scripts/workshop_project.gd").fingerprint(h.studio_project)==preload("res://scripts/workshop_project.gd").fingerprint(approved)
static func begin(g:Node,ids:Array)->void:
 g.set_meta("records_unofficial",false)
 g.get_tree().root.set_meta("fx_record_game",weakref(g))
 if not g.has_node("RecordStatus"):
  var layer=CanvasLayer.new();layer.name="RecordStatus";layer.layer=50;g.add_child(layer)
  var status=preload("res://scripts/record_status.gd").new();status.game=g;layer.add_child(status)
 observe(g,ids)
static func observe(g:Node,ids:Array)->void:
 for id in ids:
  if not hero_allowed(g,str(id)):g.set_meta("records_unofficial",true)
static func blocked()->bool:
 var tree=Engine.get_main_loop() as SceneTree
 if tree==null or not tree.root.has_meta("fx_record_game"):return false
 var ref=tree.root.get_meta("fx_record_game",null)
 var g=ref.get_ref() if ref is WeakRef else null
 return is_instance_valid(g) and str(g.get("mode"))!="town" and bool(g.get_meta("records_unofficial",false))
static func warn(g:Node)->void:
 if not bool(g.get_meta("records_unofficial",false)) or g.get_tree().root.has_meta("fx_dedicated_server"):return
 var box=AcceptDialog.new();box.title="Unofficial playtest";box.dialog_text=NOTICE+"\nCustom multiplayer heroes use Forced Balance. Your existing records stay safe.";box.dialog_autowrap=true;g.add_child(box);box.confirmed.connect(box.queue_free);box.canceled.connect(box.queue_free);box.popup_centered(Vector2i(570,210))
static func badge(g:Node2D,c:Node2D)->void:
 if not bool(g.get_meta("records_unofficial",false)) or str(g.get("mode"))=="town":return
 var at=Vector2(g.get_viewport_rect().size.x*.5-190,72)
 c.draw_style_box(preload("res://scripts/studio_ui.gd").box("#30213b","#d7aaee",6,5),Rect2(at,Vector2(380,25)))
 c.draw_string(ThemeDB.fallback_font,at+Vector2(12,18),"PLAYTEST • UNOFFICIAL • NO RECORDS",HORIZONTAL_ALIGNMENT_LEFT,-1,15,Color("#f4ddff"))

static func archive_custom_personal(profile:Dictionary)->void:
 var records:Dictionary=profile.get("records",{})
 var archive:Dictionary=profile.get("playtest_records",{}) if profile.get("playtest_records",{}) is Dictionary else {}
 for key in records.keys():
  if str(key).get_slice(":",str(key).get_slice_count(":")-1).begins_with("custom_"):
   archive[key]=records[key];records.erase(key)
 if not archive.is_empty():profile.playtest_records=archive

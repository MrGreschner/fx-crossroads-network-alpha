extends Node
## Approved snapshots come only from the service. They never become editable custom drafts.
signal changed
const P=preload("res://scripts/workshop_project.gd")
var catalog:Dictionary={}
var incoming:Dictionary={}
var offset=0
var status="Community heroes have not loaded yet."
var timer=1.0
var fetching=false
var operation=""
var callback:Callable
var request:HTTPRequest
func _ready()->void:
 if OS.get_environment("FX_HERO_VALIDATOR")=="1":set_process(false);return
 request=HTTPRequest.new();request.timeout=25;request.body_size_limit=33554432;add_child(request);request.request_completed.connect(completed)
func endpoint()->String:
 return ("http://127.0.0.1:"+(OS.get_environment("PORT") if not OS.get_environment("PORT").is_empty() else "9080") if get_tree().root.get_meta("fx_dedicated_server",false) or OS.get_environment("FX_PROXY")=="1" else preload("res://scripts/brand.gd").insights_http()).trim_suffix("/")
func _process(delta:float)->void:
 timer-=delta
 if timer<=0 and not fetching:refresh()
func refresh()->void:
 if fetching:return
 operation="catalog";fetching=true;timer=60;offset=0;incoming.clear()
 var issue=request.request(endpoint()+"/heroes/catalog")
 if issue!=OK:fetching=false;status="Community heroes unavailable. Try refresh again.";timer=15
func submit(project:Dictionary,done:Callable)->void:
 if fetching:done.call("Community connection busy. Try again in a moment.");return
 var account=get_tree().root.get_node_or_null("FXAccount")
 if account==null or account.token.is_empty():done.call("Sign in to a cloud account first. Your username is attached automatically.");return
 var issue=preload("res://scripts/community_validation.gd").issue(project)
 if not issue.is_empty():done.call(issue);return
 var copy=project.duplicate(true);copy.author="";copy.reports=[];copy.notes={"hypothesis":"","method":"","observations":"","next_change":""}
 callback=done;operation="submit";fetching=true
 var err=request.request(endpoint()+"/heroes/submit",account.headers(),HTTPClient.METHOD_POST,JSON.stringify({"project":copy}))
 if err!=OK:fetching=false;done.call("Could not connect. Your draft is safe.")
func show_status(parent:Node)->void:
 if fetching:return
 var account=get_tree().root.get_node_or_null("FXAccount")
 var box=AcceptDialog.new();box.title="My community submissions";box.dialog_autowrap=true;parent.add_child(box);box.confirmed.connect(box.queue_free);box.canceled.connect(box.queue_free)
 if account==null or account.token.is_empty():box.dialog_text="Sign in to see your submissions.";box.popup_centered(Vector2i(620,300));return
 callback=func(message:String):
  if is_instance_valid(box):box.dialog_text=message;box.popup_centered(Vector2i(620,380))
 operation="mine";fetching=true
 if request.request(endpoint()+"/heroes/mine",account.headers())!=OK:fetching=false;callback.call("Could not load submissions. Your draft is safe.")
func completed(result:int,code:int,_headers:PackedStringArray,body:PackedByteArray)->void:
 fetching=false
 var parsed=JSON.parse_string(body.get_string_from_utf8());var data:Dictionary=parsed if parsed is Dictionary else {}
 var success=result==HTTPRequest.RESULT_SUCCESS and code>=200 and code<300
 if operation=="catalog":
  if not success:status="Community heroes unavailable. Try Refresh community.";timer=15;changed.emit();return
  var next={}
  for item in data.get("heroes",[]):
   if not item is Dictionary or not item.get("project") is Dictionary:continue
   var p:Dictionary=item.project
   if not preload("res://scripts/community_validation.gd").issue(p).is_empty():continue
   var id="community_"+str(item.get("id","")).replace("-","")
   if id.length()!=42:continue
   next[id]={"project":p,"author":str(item.get("username","Creator"))}
  incoming.merge(next)
  if data.get("next")!=null and int(data.next)>offset and int(data.next)<=10000:
   offset=int(data.next);fetching=true
   if request.request(endpoint()+"/heroes/catalog?offset="+str(offset))!=OK:fetching=false;status="Community refresh interrupted. Try again.";timer=15
   return
  catalog=incoming.duplicate(true);status="%d approved community heroes" % catalog.size();changed.emit();return
 if not callback.is_valid():return
 if not success:callback.call(str(data.get("error","Could not connect. Your draft is safe.")));return
 if operation=="submit":callback.call(str(data.get("message","Sent for admin review.")))
 if operation=="mine":
  var lines=PackedStringArray()
  for entry in data.get("submissions",[]):lines.append("%s • rev %d • %s\n%s" % [entry.get("name","Hero"),int(entry.get("revision",1)),str(entry.get("state","pending")).capitalize(),entry.get("review_note","")])
  callback.call("No submissions yet. Complete a Studio hero and send it for review." if lines.is_empty() else "\n\n".join(lines))
func install(game:Node)->void:
 for id in game.characters.keys():
  if str(id).begins_with("community_") and not catalog.has(id):
   game.characters.erase(id)
   if game.get("selected_character")==id:game.selected_character="ram";game.hero_preview="ram"
   if game.get("selected_hero")==id and not game.get("started"):game.selected_hero="ram";game.preferred_hero="ram"
   for pose in ["idle","walk1","walk2","attack"]:game.art.erase(str(id)+"_"+pose)
 for id in catalog:
  var entry:Dictionary=catalog[id];var p:Dictionary=entry.project
  var fingerprint=P.fingerprint(p)
  if game.characters.get(id,{}).get("studio_token","")==fingerprint:continue
  var h:Dictionary=p.hero.duplicate(true);h.id=id;h.sprite=id;h.cost=0;h.passive_effect="studio";h.studio_project=p.duplicate(true);h.studio_checked=true;h.studio_token=fingerprint;h.community_author=entry.author;h.passive=P.PASSIVES.get(p.hero.passive,"Custom passive")
  h.mastery={"technique":{"name":p.techniques[0].name,"ability":p.techniques[0].slot},"final_technique":{"name":p.techniques[1].name,"ability":p.techniques[1].slot}}
  game.characters[id]=h
  for pose in p.hero.art:
   var image=Image.new()
   if image.load_png_from_buffer(Marshalls.base64_to_raw(p.hero.art[pose]))==OK:game.art[id+"_"+pose]=ImageTexture.create_from_image(image)

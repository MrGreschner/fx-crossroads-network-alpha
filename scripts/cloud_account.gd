extends CanvasLayer
## Sessions are memory-only. Portable files never contain passwords, tokens or school identity.
const STORE=preload("res://scripts/profile_store.gd")
var token=""
var user:Dictionary={}
var revision=0
var loaded=false
var conflict=false
var save_error=false
var busy=false
var timer=60.0
var last_json=""
var endpoint=""
var request:HTTPRequest
var operation=""
var panel:PanelContainer
var col:VBoxContainer
var message="Welcome back. Your next adventure is waiting."
var mode="login"
var last_legacy:Node
var launched=false
var fetching=false
var applying=false
var shortcut:Button
var staged:Dictionary={}
var username:LineEdit
var password:LineEdit
var recovery_answer:LineEdit
var confirmation:LineEdit
var status_label:Label
var guest:Dictionary={}
var previous_menu="town"
var previous_mode=""
var card_popup:PanelContainer
func _ready()->void:
 layer=110;endpoint=preload("res://scripts/brand.gd").insights_http().trim_suffix("/")
 request=HTTPRequest.new();request.timeout=25;request.body_size_limit=4500000;add_child(request);request.request_completed.connect(completed)
 shortcut=Button.new();shortcut.text="Cloud account";shortcut.position=Vector2(18,86);shortcut.custom_minimum_size=Vector2(165,36);shortcut.pressed.connect(open);add_child(shortcut)
func legacy()->Node:
 var scene=get_tree().current_scene
 return scene.get("legacy") if scene!=null else null
func headers()->PackedStringArray:
 var h=PackedStringArray(["Content-Type: application/json"])
 if not token.is_empty():h.append("Authorization: Bearer "+token)
 return h
func record_headers()->PackedStringArray:
 return headers() if loaded and not conflict else PackedStringArray(["Content-Type: application/json"])
func call_api(path:String,payload:Variant=null,op:String="")->void:
 if busy:return
 busy=true;operation=op if not op.is_empty() else path
 var err=request.request(endpoint+"/accounts/"+path,headers(),HTTPClient.METHOD_GET if payload==null else HTTPClient.METHOD_POST,"" if payload==null else JSON.stringify(payload))
 if err!=OK:busy=false;notify("Could not connect. Your local progress is safe.")
func _process(delta:float)->void:
 var l=legacy()
 if l==null:return
 shortcut.visible=not l.arcade and l.game.mode=="town" and l.game.menu=="main" and not is_instance_valid(panel)
 if l!=last_legacy:
  last_legacy=l
  if not launched and not STORE.testing():
   launched=true
   # Sign-in is chosen from the main menu; protected local/cloud ownership is unchanged.
 if loaded and str(l.game.mode)!=previous_mode:
  previous_mode=str(l.game.mode)
  if previous_mode=="town":timer=minf(timer,2)
 if not loaded or conflict or busy or STORE.testing():return
 timer-=delta
 if timer<=0:timer=60;save_cloud()
func school_role()->String:return str(user.get("role","player")) if loaded else "player"
func private_ready()->bool:return true
func make_bundle(l:Node)->Dictionary:
 if loaded:l.data.name=str(user.username)
 l.save()
 if not l.arcade:l.game.save_profile();l.game.journey.save();l.game.provisions.save()
 var p=l.bundle()
 if loaded:p.progress.name=str(user.username)
 p.saves.erase("fx_education_access.json");p.saves.erase("fx_teacher_classes.json")
 p.studio=preload("res://scripts/studio_library.gd").load_data()
 p.music=preload("res://scripts/music_library.gd").load_data()
 for pair in [["studio_draft","user://fx_workshop_project.json"],["studio_enemy_draft","user://fx_enemy_lab.json"],["studio_behavior_draft","user://fx_behavior_lab.json"],["studio_object_draft","user://fx_object_lab.json"],["studio_realm_draft","user://fx_realm_lab.json"]]:
  var d=STORE.read(pair[1])
  if not d.is_empty():p[pair[0]]=d
 return p
func save_cloud(force=false)->void:
 var l=legacy()
 if not loaded or conflict or busy or l==null or STORE.progression_blocked() or not private_ready():return
 var p=make_bundle(l)
 if l.recovery_required or p.is_empty() or not l.validate(p):message="Profile validation failed. Cloud save paused; download a backup.";conflict=true;refresh();return
 var canonical=p.duplicate(true);canonical.erase("exported");var text=JSON.stringify(canonical)
 if not force and text==last_json:return
 staged=p;call_api("save",{"revision":revision,"profile":p},"save")
func backup_local(p:Dictionary)->void:
 STORE.write("user://fx_before_cloud.json",p)
func open()->void:
 var l=legacy()
 if l==null:return
 if l.arcade or l.game.mode!="town":message="Return to town to sign in or switch accounts.";return
 if is_instance_valid(panel):panel.show();refresh();return
 previous_menu=l.game.menu;l.game.menu="cloud_account"
 panel=PanelContainer.new();panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);add_child(panel)
 var style=StyleBoxFlat.new();style.bg_color=Color("#102c38");style.border_color=Color("#d9bc7d");style.set_border_width_all(2);panel.add_theme_stylebox_override("panel",style)
 var margin=MarginContainer.new();margin.add_theme_constant_override("margin_left",70);margin.add_theme_constant_override("margin_right",70);margin.add_theme_constant_override("margin_top",35);margin.add_theme_constant_override("margin_bottom",35);panel.add_child(margin)
 var scroll=ScrollContainer.new();scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;margin.add_child(scroll)
 col=VBoxContainer.new();col.size_flags_horizontal=Control.SIZE_EXPAND_FILL;col.add_theme_constant_override("separation",12);scroll.add_child(col);refresh()
func label(text:String,size=19)->void:
 var n=Label.new();n.text=text;n.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;n.add_theme_font_size_override("font_size",size);
 if size>=23:n.add_theme_color_override("font_color",Color("#ead3a2"))
 col.add_child(n)
func button(text:String,fn:Callable)->Button:
 var b=Button.new();b.text=text;b.custom_minimum_size.y=43;b.pressed.connect(fn)
 var style=StyleBoxFlat.new();style.bg_color=Color("#437563") if text.begins_with("Create account") or text.begins_with("Sign in") or text.begins_with("Load my") else Color("#345663");style.border_color=Color("#d9bc7d") if text.begins_with("Create account") or text.begins_with("Load my") else Color("#70999e");style.set_border_width_all(1);style.set_corner_radius_all(6);b.add_theme_stylebox_override("normal",style);var hover=style.duplicate();hover.bg_color=Color("#337387");b.add_theme_stylebox_override("hover",hover);col.add_child(b);return b
func field(hint:String,secret=false)->LineEdit:
 label(hint,15)
 var f=LineEdit.new();f.placeholder_text=hint;f.secret=secret;f.custom_minimum_size.y=45;f.virtual_keyboard_enabled=true;col.add_child(f);var mobile=preload("res://scripts/mobile_text_entry.gd").new();f.add_child(mobile);mobile.setup(f);return f
func notify(value:String)->void:
 message=value
 if is_instance_valid(status_label):status_label.text=message
 var d=AcceptDialog.new();d.title="Check your cloud account";d.dialog_text=value;d.ok_button_text="Got it";add_child(d);d.confirmed.connect(d.queue_free);d.canceled.connect(d.queue_free);d.popup_centered(Vector2i(520,180))
func refresh()->void:
 if not is_instance_valid(col):return
 for c in col.get_children():col.remove_child(c);c.queue_free()
 var l=legacy()
 var signed_header=loaded and not token.is_empty() and mode not in ["password","recovery"] and l!=null and not l.recovery_required
 if signed_header:build_signed_header(l)
 else:
  label("WELCOME TO CROSSROADS" if mode=="register" else "YOUR CROSSROADS ADVENTURE",28);label("Your next adventure starts here." if mode=="register" and message=="Welcome back. Your next adventure is waiting." else message,17);status_label=col.get_child(col.get_child_count()-1)
 if l!=null and l.recovery_required:
  label("LOCAL PROFILE RECOVERY",24);label("An existing profile could not be validated. It has been preserved and automatic local/cloud saving is paused. Download these files before importing a backup or loading a cloud profile.")
  button("Download preserved local save",download_recovery)
  button("Import a downloaded profile backup",func():close();legacy().pick_import())
 if not token.is_empty() and bool(user.get("username_warning",false)):
  label("USERNAME CHANGE REQUEST",22);label("Your username has been flagged as inappropriate. Please kindly choose a different game username. Your private game ID, progress and records will stay the same.",17)
  button("Choose a new username",func():mode="rename";refresh())
 if token.is_empty():
  label("A place to keep your adventures",23)
  label("Create an account to carry your progress between devices, or sign in to pick up where you left off. Your current device profile is kept safe while you choose.",17)
  label("Use a made-up game name, not your real name. Choose a private password that you do not use elsewhere.",15)
  username=field("Username • 3–20 letters / numbers / underscores");username.max_length=20
  password=field("Password • 9–128 characters",true);password.max_length=128
  if mode=="register":
   confirmation=field("Confirm password",true);confirmation.max_length=128
   label("Recovery question: What is the made-up name of your imaginary portal guardian?",17)
   label("Invent an answer. Use no real names or personal information. Remember it for password resets and account verification.",15)
   recovery_answer=field("Made-up answer • 6–64 letters / numbers / spaces",true);recovery_answer.max_length=64
  button("Create account" if mode=="register" else "Sign in",func():
   var name=username.text.strip_edges();var pw=password.text
   var pattern=RegEx.new();pattern.compile("^[A-Za-z][A-Za-z0-9_]{2,19}$")
   if not pattern.search(name):notify("Enter a username of 3–20 letters, numbers or underscores, starting with a letter.");return
   if mode=="register" and pw!=confirmation.text:notify("The passwords do not match. Please check both password fields.");return
   if pw.length()<9:notify("Enter a password with at least 9 characters.");return
   var payload={"username":name,"password":pw}
   if mode=="register":
    var answer=recovery_answer.text.strip_edges()
    if answer.length()<6:notify("Enter your made-up recovery answer with at least 6 characters. Use no real information.");return
    payload.answer=answer
   call_api("register" if mode=="register" else "login",payload,"auth"))
  button("Have an account? Sign in" if mode=="register" else "New here? Create an account",func():mode="login" if mode=="register" else "register";refresh())
  label("For password resets and account verification, keep your recovery answer private. Signing in does not upload or replace this device’s profile automatically.",16)
  button("Continue without cloud account",guest_play)
 elif mode=="rename":
  label("Choose a new game username",23);label("Your private game ID, saved progress and community records stay the same.",16)
  username=field("New username • 3–20 letters / numbers / underscores");username.max_length=20
  button("Update username",func():call_api("username",{"username":username.text.strip_edges()},"rename"))
  button("Back",func():mode="login";refresh())
 elif mode=="password":
  label("Change your password",23);username=field("Current password",true);password=field("New password • at least 9 characters",true);confirmation=field("Confirm new password",true)
  button("Update password",func():
   if password.text!=confirmation.text or password.text.length()<9:notify("Use at least 9 characters and matching passwords.");return
   call_api("password",{"current":username.text,"password":password.text},"password"))
  button("Cancel",func():mode="login";refresh())
 elif mode=="recovery":
  label("Recovery question: What is the made-up name of your imaginary portal guardian?",21)
  label("Invent an answer with no real names or personal information. Remember it for password resets and account verification.",16)
  username=field("Current password",true);recovery_answer=field("Made-up answer • 6–64 letters / numbers / spaces",true);recovery_answer.max_length=64
  button("Save recovery answer",func():
   if username.text.length()<9:notify("Enter your current password.");return
   if recovery_answer.text.strip_edges().length()<6:notify("Enter a made-up recovery answer of at least 6 characters.");return
   call_api("recovery",{"current":username.text,"answer":recovery_answer.text},"recovery"))
  button("Cancel",func():mode="login";refresh())
 elif not loaded:
  label("Welcome back, "+str(user.username)+"!",23)
  if not str(user.get("school_code","")).is_empty():label("Private game ID: "+str(user.school_code)+" • keep this for account verification",18)
  if user.get("has_save",false):
   label("Ready to return? Load your cloud profile below. Teacher and student tools appear in town after it loads.",17)
   button("Load my cloud profile",func():call_api("save",null,"load"))
   var owner_copy=STORE.read("user://fx_cloud_owner.json")
   if str(owner_copy.get("id",""))==str(user.id) and int(owner_copy.get("revision",-1))==revision:
    button("Recover this account’s newer local progress → save to cloud",func():loaded=true;conflict=false;backup_local(make_bundle(legacy()));save_cloud(true))
  else:
   label("Your account is ready! Now choose your starting point. You can bring this device’s progress into the cloud or begin a new adventure. We back up the local profile before replacing anything.")
   button("Keep this device’s progress → create cloud save",func():
    var current=legacy();guest=make_bundle(current);backup_local(guest);STORE.write("user://fx_cloud_guest.json",guest);loaded=true;revision=0;mark_owner();save_cloud(true))
   button("Start a fresh cloud profile",func():
    var current=legacy();guest=make_bundle(current);backup_local(guest);STORE.write("user://fx_cloud_guest.json",guest)
    var p={"format":"fx-crossroads-profile","version":1,"progress":current.defaults(),"saves":{},"studio":{"heroes":{},"abilities":{}}}
    loaded=true;revision=0;mark_owner();apply(p))
  if not bool(user.get("has_recovery",false)):button("Add recovery answer",func():mode="recovery";refresh())
  button("Sign out",sign_out)
 else:
  if not signed_header:build_signed_header(l)
  button("Save now",func():save_cloud(true)).disabled=busy or conflict
  button("Download this device’s profile backup",func():close();legacy().export_profile())
  if conflict:button("Load cloud save instead (local backup kept)",func():call_api("save",null,"load"))
  button("Set / change recovery answer",func():mode="recovery";refresh())
  button("Change password",func():mode="password";refresh())
  button("Sign out & restore guest profile",sign_out)
  if save_error or conflict:button("Sign out without uploading • download a backup first",confirm_offline_logout)
  button("Back to game",close)
func build_signed_header(l:Node)->void:
 var outer=col
 var header=GridContainer.new();header.name="SignedInHeader";header.columns=2 if get_viewport().get_visible_rect().size.x>=900 else 1;header.add_theme_constant_override("h_separation",28);header.add_theme_constant_override("v_separation",12);col.add_child(header)
 var details=VBoxContainer.new();details.name="AccountDetails";details.size_flags_horizontal=Control.SIZE_EXPAND_FILL;details.add_theme_constant_override("separation",12);header.add_child(details);col=details
 label("WELCOME TO CROSSROADS" if mode=="register" else "YOUR CROSSROADS ADVENTURE",28);label("Your next adventure starts here." if mode=="register" and message=="Welcome back. Your next adventure is waiting." else message,17);status_label=col.get_child(col.get_child_count()-1)
 label(str(user.username)+" • "+str(user.role).capitalize(),24)
 if not str(user.get("school_code","")).is_empty():label("Private game ID: "+str(user.school_code),18)
 label("Cloud revision "+str(revision)+" • "+("SAVING PAUSED — resolve conflict" if conflict else "automatic save every 60 seconds")+"\nDownloadable profiles still work as backups.",17)
 col=outer
 var right=VBoxContainer.new();right.name="CardPreviewArea";right.size_flags_horizontal=Control.SIZE_EXPAND_FILL;header.add_child(right)
 var preview=Button.new();preview.name="EnlargePlayerCard";preview.custom_minimum_size=Vector2(0,240 if header.columns==2 else 190);preview.clip_contents=true;preview.tooltip_text="Open your full player card";preview.pressed.connect(enlarge_card);right.add_child(preview)
 var card=preload("res://scripts/cloud_player_card.gd").new();card.name="CloudProfileCard";card.legacy=l;card.username=str(user.username);card.compact=true;preview.add_child(card);card.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);card.offset_left=8;card.offset_right=-8;card.offset_top=8;card.offset_bottom=-8
 var caption=Label.new();caption.text="Click / tap your card to enlarge";caption.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;caption.add_theme_font_size_override("font_size",15);right.add_child(caption)
func enlarge_card()->void:
 if is_instance_valid(card_popup):return
 var l=legacy()
 if not loaded or l==null:return
 card_popup=PanelContainer.new();card_popup.name="FullPlayerCard";card_popup.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);add_child(card_popup)
 var skin=StyleBoxFlat.new();skin.bg_color=Color("#10262e");skin.border_color=Color("#d9bc7d");skin.set_border_width_all(2);skin.set_content_margin_all(20);card_popup.add_theme_stylebox_override("panel",skin)
 var layout=VBoxContainer.new();layout.name="CardDetailLayout";layout.add_theme_constant_override("separation",10);card_popup.add_child(layout)
 var done=Button.new();done.name="CloseCard";done.text="Close player card";done.custom_minimum_size.y=44;done.pressed.connect(close_card);layout.add_child(done);done.grab_focus()
 var scroll=ScrollContainer.new();scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;scroll.size_flags_vertical=Control.SIZE_EXPAND_FILL;layout.add_child(scroll)
 var card=preload("res://scripts/cloud_player_card.gd").new();card.legacy=l;card.username=str(user.username);scroll.add_child(card)
func close_card()->void:
 if is_instance_valid(card_popup):card_popup.queue_free()
 card_popup=null
func download_recovery()->void:
 var l=legacy()
 for suffix in [".recovery",".bak.recovery",".bak"]:
  var path=l.PATH+suffix
  if not FileAccess.file_exists(path):continue
  if OS.has_feature("web"):JavaScriptBridge.download_buffer(FileAccess.get_file_as_bytes(path),"crossroads-recovery"+suffix+".json","application/json")
 message="Preserved save files requested. Keep them for recovery; do not clear browser storage.";refresh()
func sync_records()->void:
 var current=legacy()
 if loaded and not conflict and current!=null and current.community!=null:current.community.request_sync()
func mark_owner()->void:STORE.write("user://fx_cloud_owner.json",{"id":user.id,"username":user.username,"revision":revision})
func apply(p:Dictionary)->void:
 var l=legacy()
 if l==null or not l.validate(p):message="Cloud profile did not pass validation. Local progress unchanged.";loaded=false;refresh();return
 backup_local(make_bundle(l));p.progress.name=str(user.username) if loaded else str(p.progress.get("name","Traveler"));l.pending=p;applying=true
 close();l.game.mode="town";l.apply_import();applying=false
 call_deferred("sync_records")
static func public_error(value:String)->String:
 # Older deployed services may still return school-specific wording.
 if "Cloud accounts are not available yet" in value or "Cloud accounts unavailable" in value:
  return "Cloud accounts are temporarily unavailable. You can keep playing on this device and download a profile backup. Please try again later."
 return value.replace("unique school code", "unique private game ID")
func completed(result:int,code:int,_headers:PackedStringArray,bytes:PackedByteArray)->void:
 busy=false;var p=JSON.parse_string(bytes.get_string_from_utf8());var op=operation
 if result!=HTTPRequest.RESULT_SUCCESS or not p is Dictionary or code<200 or code>=300:
  message=str(p.get("error","Connection failed. Local progress is safe.")) if p is Dictionary else "Connection failed. Local progress is safe."
  message=public_error(message)
  if code==409 and op=="save":conflict=true
  if code==401 and op not in ["auth","password","recovery"]:loaded=false;token=""
  if op in ["save","save_logout"]:save_error=true
  timer=60
  if op in ["auth","password","recovery"]:notify(message)
  else:refresh()
  return
 match op:
  "auth":
   mode="login";token=p.token;user=p.user;revision=int(user.revision);loaded=false;message="Signed in. Choose your profile below.";refresh()
  "rename":
   user=p.user;mode="login";message="Username updated. Your account ID, progress and records are unchanged.";var l=legacy()
   if loaded and l!=null:l.data.name=str(user.username);l.save();mark_owner();call_deferred("sync_records")
   refresh()
  "recovery":user.has_recovery=true;mode="login";message="Recovery answer saved. Keep your made-up answer private.";refresh()
  "password":mode="login";message="Password updated. Other sessions have been signed out.";refresh()

  "load":
   if p.get("profile")==null:message="No cloud save exists for this account.";refresh();return
   var l=legacy()
   if not l.validate(p.profile):message="Unsupported cloud profile. Current device unchanged.";refresh();return
   if not FileAccess.file_exists("user://fx_cloud_guest.json"):STORE.write("user://fx_cloud_guest.json",make_bundle(l))
   revision=int(p.revision);loaded=true;conflict=false;last_json="";mark_owner();apply(p.profile)
  "save", "save_logout":
   save_error=false;revision=int(p.revision);mark_owner();var canonical=staged.duplicate(true);canonical.erase("exported");last_json=JSON.stringify(canonical);message="Cloud saved • revision "+str(revision);refresh()
   if op=="save_logout":call_api("logout",{},"logout")
   else:call_deferred("sync_records");get_tree().root.get_node("FXClassPro").sync_portfolio()
  "logout":finish_logout()
func sign_out()->void:
 if busy:return
 if loaded and not conflict:
  message="Save now before signing out if you want to keep your latest changes.";save_cloud(true)
  # Revoke the session only after the final upload succeeds.
  if busy:operation="save_logout";return
 call_api("logout",{},"logout")
func confirm_offline_logout()->void:
 var dialog=ConfirmationDialog.new();dialog.dialog_text="Cloud saving has not succeeded. Download this device's profile first if you need its latest progress. Sign out and restore the guest profile?";dialog.title="Sign out without a cloud save";add_child(dialog);dialog.confirmed.connect(func():finish_logout();dialog.queue_free());dialog.canceled.connect(dialog.queue_free);dialog.popup_centered(Vector2i(600,220))
func finish_logout()->void:
 mode="login";token="";user={};loaded=false;conflict=false;save_error=false;revision=0;last_json="";STORE.erase("user://fx_cloud_owner.json");guest_play()
func guest_play()->void:
 var restore=STORE.read("user://fx_cloud_guest.json")
 if not restore.is_empty():
  STORE.erase("user://fx_cloud_owner.json");STORE.erase("user://fx_cloud_guest.json");token="";user={};loaded=false;apply(restore);return
 close()
func close()->void:
 close_card()
 if is_instance_valid(panel):panel.queue_free()
 panel=null;col=null
 var l=legacy()
 if l!=null and not l.arcade:l.game.menu="town" if previous_menu=="cloud_account" else previous_menu

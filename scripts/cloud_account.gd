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
var message="Sign in to protect your progress across devices."
var mode="login"
var last_legacy:Node
var launched=false
var fetching=false
var applying=false
var shortcut:Button
var staged:Dictionary={}
var username:LineEdit
var password:LineEdit
var confirmation:LineEdit
var school_last:LineEdit
var school_first:LineEdit
var status_label:Label
var guest:Dictionary={}
var previous_menu="town"
var previous_mode=""
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
 if err!=OK:busy=false;message="Could not connect. Your local progress is safe.";refresh()
func _process(delta:float)->void:
 var l=legacy()
 if l==null:return
 shortcut.visible=not l.arcade and l.game.mode=="town" and l.game.menu=="main" and not is_instance_valid(panel)
 if l!=last_legacy:
  last_legacy=l
  if not launched and not STORE.testing():
   launched=true
   if FileAccess.file_exists("user://fx_cloud_owner.json") or l.recovery_required:call_deferred("open")
 if loaded and str(l.game.mode)!=previous_mode:
  previous_mode=str(l.game.mode)
  if previous_mode=="town":timer=minf(timer,2)
 if not loaded or conflict or busy or STORE.testing():return
 timer-=delta
 if timer<=0:timer=60;save_cloud()
func school_role()->String:return str(user.get("role","player")) if loaded else "player"
func private_ready()->bool:return not bool(user.get("needs_identity",false))
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
 var n=Label.new();n.text=text;n.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;n.add_theme_font_size_override("font_size",size);col.add_child(n)
func button(text:String,fn:Callable)->Button:
 var b=Button.new();b.text=text;b.custom_minimum_size.y=43;b.pressed.connect(fn)
 var style=StyleBoxFlat.new();style.bg_color=Color("#245867");style.border_color=Color("#609caa");style.set_border_width_all(1);style.set_corner_radius_all(6);b.add_theme_stylebox_override("normal",style);var hover=style.duplicate();hover.bg_color=Color("#337387");b.add_theme_stylebox_override("hover",hover);col.add_child(b);return b
func field(hint:String,secret=false)->LineEdit:
 var f=LineEdit.new();f.placeholder_text=hint;f.secret=secret;f.custom_minimum_size.y=45;f.virtual_keyboard_enabled=true;col.add_child(f);var mobile=preload("res://scripts/mobile_text_entry.gd").new();f.add_child(mobile);mobile.setup(f);return f
func refresh()->void:
 if not is_instance_valid(col):return
 for c in col.get_children():col.remove_child(c);c.queue_free()
 label("CROSSROADS • CLOUD ACCOUNT",28);label(message,17)
 var l=legacy()
 if l!=null and l.recovery_required:
  label("LOCAL PROFILE RECOVERY",24);label("An existing profile could not be validated. It has been preserved and automatic local/cloud saving is paused. Download these files before importing a backup or loading a cloud profile.")
  button("Download preserved local save",download_recovery)
  button("Import a downloaded profile backup",func():close();legacy().pick_import())
 if token.is_empty():
  label("Choose a game username and a password of your choice. Please do not use your real name. Keep names appropriate. Do not reuse your school password.")
  username=field("Username • 3–20 letters / numbers / underscores");username.max_length=20
  password=field("Password • 15–128 characters",true);password.max_length=128
  if mode=="register":confirmation=field("Confirm password",true);confirmation.max_length=128
  button("Create account" if mode=="register" else "Sign in",func():
   var name=username.text;var pw=password.text
   if mode=="register" and pw!=confirmation.text:message="The passwords do not match.";refresh();return
   if name.is_empty() or pw.length()<15:message="Enter a username and a password with at least 15 characters.";refresh();return
   call_api("register" if mode=="register" else "login",{"username":name,"password":pw},"auth");password.clear())
  button("Have an account? Sign in" if mode=="register" else "New here? Create an account",func():mode="login" if mode=="register" else "register";refresh())
  label("Forgot your password? Ask your teacher or the game administrator. Signing in does not upload or replace this device’s profile automatically.",16)
  button("Continue without cloud account",guest_play)
 elif mode=="password":
  label("Change your password",23);username=field("Current password",true);password=field("New password • at least 15 characters",true);confirmation=field("Confirm new password",true)
  button("Update password",func():
   if password.text!=confirmation.text or password.text.length()<15:message="Use at least 15 characters and matching passwords.";refresh();return
   call_api("password",{"current":username.text,"password":password.text},"password"))
  button("Cancel",func():mode="login";refresh())
 elif not private_ready():
  label("School identification • private",23);label("Your administrator assigned a "+str(user.role)+" account. Enter only the first five letters of your last name (all letters if shorter), and your first initial. This is for future marks and is never displayed publicly.")
  school_last=field("First five letters of last name");school_last.max_length=5;school_first=field("First initial");school_first.max_length=1
  button("Save private identification",func():call_api("identity",{"last":school_last.text,"initial":school_first.text},"identity"))
 elif not loaded:
  label("Signed in as "+str(user.username),23)
  if user.get("has_save",false):
   button("Load my cloud profile",func():call_api("save",null,"load"))
   var owner_copy=STORE.read("user://fx_cloud_owner.json")
   if str(owner_copy.get("id",""))==str(user.id) and int(owner_copy.get("revision",-1))==revision:
    button("Recover this account’s newer local progress → save to cloud",func():loaded=true;conflict=false;backup_local(make_bundle(legacy()));save_cloud(true))
  else:
   label("This account has no cloud save yet. Choose what to start with. Your current local profile is backed up before any replacement.")
   button("Keep this device’s progress → create cloud save",func():
    var current=legacy();guest=make_bundle(current);backup_local(guest);STORE.write("user://fx_cloud_guest.json",guest);loaded=true;revision=0;mark_owner();save_cloud(true))
   button("Start a fresh cloud profile",func():
    var current=legacy();guest=make_bundle(current);backup_local(guest);STORE.write("user://fx_cloud_guest.json",guest)
    var p={"format":"fx-crossroads-profile","version":1,"progress":current.defaults(),"saves":{},"studio":{"heroes":{},"abilities":{}}}
    loaded=true;revision=0;mark_owner();apply(p))
  button("Sign out",sign_out)
 else:
  label(str(user.username)+" • "+str(user.role).capitalize(),24);label("Cloud revision "+str(revision)+" • "+("SAVING PAUSED — resolve conflict" if conflict else "automatic save every 60 seconds")+"\nDownloadable profiles still work as backups.")
  button("Save now",func():save_cloud(true)).disabled=busy or conflict
  button("Download this device’s profile backup",func():close();legacy().export_profile())
  if conflict:button("Load cloud save instead (local backup kept)",func():call_api("save",null,"load"))
  button("Change password",func():mode="password";refresh())
  button("Sign out & restore guest profile",sign_out)
  if save_error or conflict:button("Sign out without uploading • download a backup first",confirm_offline_logout)
  button("Back to game",close)
func download_recovery()->void:
 var l=legacy()
 for suffix in [".recovery",".bak.recovery",".bak"]:
  var path=l.PATH+suffix
  if not FileAccess.file_exists(path):continue
  if OS.has_feature("web"):JavaScriptBridge.download_buffer(FileAccess.get_file_as_bytes(path),"crossroads-recovery"+suffix+".json","application/json")
 message="Preserved save files requested. Keep them for recovery; do not clear browser storage.";refresh()
func mark_owner()->void:STORE.write("user://fx_cloud_owner.json",{"id":user.id,"username":user.username,"revision":revision})
func apply(p:Dictionary)->void:
 var l=legacy()
 if l==null or not l.validate(p):message="Cloud profile did not pass validation. Local progress unchanged.";loaded=false;refresh();return
 backup_local(make_bundle(l));p.progress.name=str(user.username) if loaded else str(p.progress.get("name","Traveler"));l.pending=p;applying=true
 close();l.game.mode="town";l.apply_import();applying=false
func completed(result:int,code:int,_headers:PackedStringArray,bytes:PackedByteArray)->void:
 busy=false;var p=JSON.parse_string(bytes.get_string_from_utf8());var op=operation
 if result!=HTTPRequest.RESULT_SUCCESS or not p is Dictionary or code<200 or code>=300:
  message=str(p.get("error","Connection failed. Local progress is safe.")) if p is Dictionary else "Connection failed. Local progress is safe."
  if code==409 and op=="save":conflict=true
  if code==401:loaded=false;token=""
  if op in ["save","save_logout"]:save_error=true
  timer=60;refresh();return
 match op:
  "auth":
   mode="login";token=p.token;user=p.user;revision=int(user.revision);loaded=false;message="Signed in. Choose your profile below.";refresh()
  "password":mode="login";message="Password updated. Other sessions have been signed out.";refresh()
  "identity":user.needs_identity=false;message="Private identification saved.";refresh()
  "load":
   if p.get("profile")==null:message="No cloud save exists for this account.";refresh();return
   var l=legacy()
   if not l.validate(p.profile):message="Unsupported cloud profile. Current device unchanged.";refresh();return
   if not FileAccess.file_exists("user://fx_cloud_guest.json"):STORE.write("user://fx_cloud_guest.json",make_bundle(l))
   revision=int(p.revision);loaded=true;conflict=false;last_json="";mark_owner();apply(p.profile)
  "save", "save_logout":
   save_error=false;revision=int(p.revision);mark_owner();var canonical=staged.duplicate(true);canonical.erase("exported");last_json=JSON.stringify(canonical);message="Cloud saved • revision "+str(revision);refresh()
   if op=="save_logout":call_api("logout",{},"logout")
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
 if is_instance_valid(panel):panel.queue_free()
 panel=null;col=null
 var l=legacy()
 if l!=null and not l.arcade:l.game.menu="town" if previous_menu=="cloud_account" else previous_menu

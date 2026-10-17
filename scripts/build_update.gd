extends Node
## One bounded release check; unavailable networks do not prevent offline play.
const BUILD=171
var ENDPOINT=preload("res://scripts/brand.gd").service_http()+"/release"
var DOWNLOAD=preload("res://scripts/brand.gd").download_url()
var game:Node
var request:HTTPRequest
var latest=0
var checked=false
var shown=false
var status="Checking latest release…"
var ui:CanvasLayer
func setup(owner:Node)->void:
 game=owner
 if OS.has_feature("web"):checked=true;status="Browser build v%d" % BUILD;return
 check()
func check()->void:
 if request!=null:return
 checked=false;status="Checking latest release…";request=HTTPRequest.new();request.timeout=8;request.body_size_limit=4096;add_child(request);request.request_completed.connect(completed)
 var error=request.request(ENDPOINT,["Accept: application/json","Cache-Control: no-cache"])
 if error!=OK:completed(1,0,PackedStringArray(),PackedByteArray())
func completed(result:int,code:int,_headers:PackedStringArray,body:PackedByteArray)->void:
 checked=true;latest=0
 var data=JSON.parse_string(body.get_string_from_utf8()) if result==HTTPRequest.RESULT_SUCCESS and code==200 else null
 if data is Dictionary and (data.get("game_build") is float or data.get("game_build") is int) and data.game_build==floorf(data.game_build) and data.game_build>=1 and data.game_build<=100000:
  latest=int(data.game_build);status="Installed v%d • online v%d" % [BUILD,latest]
 else:status="Could not verify latest release. Offline play is available; retry in Options."
 if request!=null:request.queue_free();request=null
func blocked()->bool:return not OS.has_feature("web") and latest>BUILD
func _process(_dt:float)->void:
 if game==null or not blocked() or shown:return
 var arcade=game.has_method("_attack_request")
 if (arcade and not game.started) or (not arcade and game.mode=="town" and not game.has_node("FXIntro")):notice()
func notice()->void:
 if ui!=null:return
 shown=true;ui=CanvasLayer.new();ui.layer=95;add_child(ui)
 var overlay=ColorRect.new();overlay.color=Color(.02,.04,.06,.88);overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);ui.add_child(overlay)
 var center=CenterContainer.new();center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);overlay.add_child(center)
 var panel=PanelContainer.new();panel.custom_minimum_size=Vector2(600,0);center.add_child(panel)
 var skin=StyleBoxFlat.new();skin.bg_color=Color("#12343e");skin.border_color=Color("#edce84");skin.set_border_width_all(2);skin.set_corner_radius_all(15);skin.set_content_margin_all(24);panel.add_theme_stylebox_override("panel",skin)
 var col=VBoxContainer.new();col.add_theme_constant_override("separation",14);panel.add_child(col)
 for line in ["UPDATE AVAILABLE • v%d" % latest,"You have v%d. Download the latest game to play the current release." % BUILD,"SAVE YOUR PROFILE FIRST: return to town and download your player profile ZIP. Keep it somewhere safe, then install the new game and upload your ZIP if needed. It includes your progress and Studio creations."]:
  var l=Label.new();l.text=line;l.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;l.custom_minimum_size.x=550;l.add_theme_font_size_override("font_size",21);col.add_child(l)
 for spec in [["Back to menu • save profile first",false],["Open latest downloads",true]]:
  var b=Button.new();b.text=spec[0];b.custom_minimum_size.y=48;col.add_child(b)
  if spec[1]:
   b.disabled=DOWNLOAD.is_empty();b.text="Get the latest build from the game’s itch.io page" if DOWNLOAD.is_empty() else b.text
   b.pressed.connect(func():OS.shell_open(DOWNLOAD))
  else:b.pressed.connect(func():ui.queue_free();ui=null;game.session_menu.open("main"))

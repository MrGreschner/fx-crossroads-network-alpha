extends CanvasLayer
## Capture-only camera; no profile flags, testing permissions or combat effects.
var clean_view=false
var guide=0
var aspect=0
var guides:Control
var countdown=0.0
var capturing=false
var clean_layers:Array=[]
var clean_applied=false
var screenshot_note:Label
var shutter_label:Label
var caption_edit:TextEdit
var title_edit:LineEdit
var portfolio_panel:PanelContainer
var native_save:FileDialog
var game:Node
var active=false
var zoom=1.0
var framing=Vector2.ZERO
var panel:PanelContainer
var border:Control
var control_visible=false
var restore_button:Button
var normal_zoom=1.0
var tick=0.0
var enabled_before=false
func setup(owner:Node)->void:
 game=owner;layer=92
 var cfg=ConfigFile.new();cfg.load("user://fx_camera.cfg");normal_zoom=float(cfg.get_value("camera","zoom",1.0));if normal_zoom not in [.75,1.0,1.25]:normal_zoom=1.0
 var tree=get_tree()
 active=bool(tree.root.get_meta("fx_media_mode",false))
 var edge=Control.new();edge.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);edge.mouse_filter=Control.MOUSE_FILTER_IGNORE;add_child(edge);border=edge
 edge.draw.connect(func():
  if active and not clean_view and not capturing:edge.draw_rect(Rect2(Vector2(3,3),edge.size-Vector2(6,6)),Color("#71cf94"),false,3))
 panel=PanelContainer.new();panel.position=Vector2(16,106);add_child(panel);preload("res://scripts/studio_ui.gd").apply(panel)
 panel.custom_minimum_size=Vector2(300,0)
 var box=VBoxContainer.new();panel.add_child(box)
 var title=Label.new();title.text="MEDIA CAMERA • F9 hide/show";box.add_child(title)
 var help=Label.new();help.text="F8 • photo (3-second timer)\nF9 • show/hide controls\nF10 • clean view for OBS\nUse the buttons below on touch devices.";box.add_child(help)
 var music=Button.new();music.text="Music Studio";box.add_child(music);music.pressed.connect(func():var studio=preload("res://scripts/music_studio.gd").new();game.add_child(studio);studio.setup(game))
 var row=HBoxContainer.new();box.add_child(row)
 for value in [.5,.75,1.0,1.25,1.5]:
  var b=Button.new();b.text=str(value)+"×";b.custom_minimum_size=Vector2(57,36);row.add_child(b);b.pressed.connect(func():zoom=value;game.update_camera() if game.has_method("update_camera") else refresh_arcade())
 var arrows=HBoxContainer.new();box.add_child(arrows)
 for spec in [["←",Vector2(-80,0)],["↑",Vector2(0,-60)],["↓",Vector2(0,60)],["→",Vector2(80,0)]]:
  var b=Button.new();b.text=spec[0];b.custom_minimum_size=Vector2(45,36);arrows.add_child(b);b.pressed.connect(func():framing=(framing+spec[1]).clamp(Vector2(-320,-240),Vector2(320,240));refresh_camera())
 var reset=Button.new();reset.text="Reset framing";box.add_child(reset);reset.pressed.connect(func():zoom=1;framing=Vector2.ZERO;refresh_camera())
 var capture=Button.new();capture.text="Photo & film tools";box.add_child(capture);capture.pressed.connect(open_tools)
 var hide_button=Button.new();hide_button.text="Minimize camera controls";box.add_child(hide_button);box.move_child(hide_button,1);hide_button.pressed.connect(func():control_visible=false;update_visible())
 restore_button=Button.new();restore_button.text="Camera • show controls";restore_button.position=Vector2(16,164);restore_button.custom_minimum_size=Vector2(210,40);add_child(restore_button);preload("res://scripts/top_button_style.gd").apply(restore_button);restore_button.pressed.connect(func():control_visible=true;update_visible())
 var stop=Button.new();stop.text="Exit Media mode";box.add_child(stop);stop.pressed.connect(func():clean_view=false;apply_clean(false);active=false;control_visible=false;get_tree().root.remove_meta("fx_media_mode");zoom=1;framing=Vector2.ZERO;refresh_camera();border.queue_redraw())
 guides=preload("res://scripts/media_guides.gd").new();guides.media=self;add_child(guides);move_child(guides,0)
 shutter_label=Label.new();shutter_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;shutter_label.add_theme_font_size_override("font_size",42);shutter_label.modulate=Color("#ffe6a2");add_child(shutter_label);shutter_label.hide()
 update_visible()
func dev()->bool:
 if not is_inside_tree():return false
 var session=get_tree().root.get_node_or_null("FXDevSession")
 return session!=null and session.active
func enabled()->bool:return active or dev()
func factor()->float:
 if game==null:return 1.0
 if game.has_method("spectating") and game.spectating():return 1.0
 if not enabled():return normal_zoom
 return zoom
func offset()->Vector2:return Vector2.ZERO
func screen_point(point:Vector2)->Vector2:return (point-offset())/factor()
func world_mouse()->Vector2:return screen_point(game.get_global_mouse_position())+game.camera
func refresh_arcade()->void:
 var size=game.VIEW/factor()
 game.camera=(game.local_pos+framing-size*.5).clamp(Vector2.ZERO,(game.FIELD.size-size).max(Vector2.ZERO))
func refresh_camera()->void:
 if game.has_method("update_camera"):game.update_camera()
 else:refresh_arcade()
 game.queue_redraw()
func enable()->void:
 active=true;get_tree().root.set_meta("fx_media_mode",true);control_visible=true;update_visible();border.queue_redraw();refresh_camera()
func update_visible()->void:
 if game.get("started")!=null and not game.started:panel.hide();restore_button.hide();return
 var menu_clear=game.get("menu")==null or game.menu.is_empty()
 panel.visible=enabled() and control_visible and game.session_menu.page.is_empty() and menu_clear and not capturing
 restore_button.visible=enabled() and not control_visible and game.session_menu.page.is_empty() and menu_clear and not capturing and not clean_view
 if portfolio_panel!=null:portfolio_panel.visible=panel.visible and countdown<=0
func _process(delta:float)->void:
 if capturing:return
 if countdown>0:
  countdown-=delta;shutter_label.text=str(maxi(1,ceili(countdown)));shutter_label.position=Vector2(game.VIEW.x*.5-25,game.VIEW.y*.4)
  if countdown<=0:take_photo();return
 tick+=delta
 if tick<.1:return
 tick=0;update_visible()
 var hud_bottom=164.0 if str(game.get("mode"))=="town" else 106.0
 panel.position=Vector2(16,hud_bottom)
 var available_height=maxf(1,game.VIEW.y-hud_bottom-16)
 if portfolio_panel!=null:
  var factor=minf(1,minf((game.VIEW.x-48)/(panel.size.x+640+16),available_height/560))
  panel.scale=Vector2.ONE*factor;portfolio_panel.scale=Vector2.ONE*factor;portfolio_panel.position=panel.position+Vector2(panel.size.x*factor+16,0)
 else:panel.scale=Vector2.ONE*minf(1,minf((game.VIEW.x-32)/maxf(1,panel.size.x),available_height/maxf(1,panel.size.y)))
 var menu_clear=game.session_menu.page.is_empty() and (game.get("menu")==null or game.menu.is_empty())
 apply_clean(clean_view and enabled() and menu_clear)
 if guides!=null:guides.visible=enabled() and menu_clear
 if enabled_before!=enabled():enabled_before=enabled();border.queue_redraw();refresh_camera()
func _input(event:InputEvent)->void:
 if enabled() and event is InputEventKey and event.pressed and not event.echo and event.keycode==KEY_F9:control_visible=not control_visible;update_visible();get_viewport().set_input_as_handled()
 if enabled() and event is InputEventKey and event.pressed and not event.echo:
  if event.keycode==KEY_F8:request_photo();get_viewport().set_input_as_handled()
  elif event.keycode==KEY_F10:clean_view=not clean_view;apply_clean(clean_view);border.queue_redraw();game.queue_redraw();get_viewport().set_input_as_handled()

func ratio()->float:
 return [game.VIEW.x/game.VIEW.y,16.0/9,1.0,4.0/5][aspect]
func collect_layers(node:Node)->void:
 for child in node.get_children():
  if child==self:continue
  if child is CanvasLayer:
   clean_layers.append([weakref(child),child.visible]);child.hide()
  collect_layers(child)
func apply_clean(value:bool)->void:
 if clean_applied==value:return
 clean_applied=value
 if value:
  collect_layers(game)
  var education=get_tree().root.get_node_or_null("FXEducationTools")
  if education!=null:clean_layers.append([weakref(education),education.visible]);education.hide()
  var session=get_tree().root.get_node_or_null("FXDevSession")
  if session!=null:collect_layers(session)
 else:
  for entry in clean_layers:
   var node=entry[0].get_ref()
   if node!=null:
    var owner=node.get_parent()
    node.visible=entry[1] and (owner==null or owner.name!="FXDevSession" or owner.active)
  clean_layers.clear()
 game.queue_redraw()
func open_tools()->void:
 if portfolio_panel!=null:portfolio_panel.queue_free()
 portfolio_panel=PanelContainer.new();portfolio_panel.position=Vector2(340,100);portfolio_panel.size=Vector2(640,560);add_child(portfolio_panel);preload("res://scripts/studio_ui.gd").apply(portfolio_panel)
 var scroll=ScrollContainer.new();scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;portfolio_panel.add_child(scroll)
 var box=VBoxContainer.new();box.size_flags_horizontal=Control.SIZE_EXPAND_FILL;scroll.add_child(box)
 var top=HBoxContainer.new();box.add_child(top);var title=Label.new();title.text="PHOTO & FILM TOOLKIT";title.size_flags_horizontal=Control.SIZE_EXPAND_FILL;top.add_child(title)
 var close=Button.new();close.text="Close";top.add_child(close);close.pressed.connect(func():portfolio_panel.queue_free();portfolio_panel=null)
 var clean=CheckButton.new();clean.text="Clean view • hide HUD (F10)";clean.button_pressed=clean_view;box.add_child(clean);clean.toggled.connect(func(value:bool):clean_view=value;apply_clean(value);border.queue_redraw();game.queue_redraw())
 var choices=HBoxContainer.new();box.add_child(choices)
 var g=OptionButton.new();choices.add_child(g)
 for label in ["No composition guide","Rule of thirds","Centre / symmetry","Broadcast safe frame"]:g.add_item(label)
 g.selected=guide;g.item_selected.connect(func(index:int):guide=index;guides.queue_redraw())
 var framing_choice=OptionButton.new();choices.add_child(framing_choice)
 for label in ["Full screen","Landscape 16:9","Square 1:1","Portrait 4:5"]:framing_choice.add_item(label)
 framing_choice.selected=aspect;framing_choice.item_selected.connect(func(index:int):aspect=index;guides.queue_redraw())
 title_edit=LineEdit.new();title_edit.placeholder_text="Photo title";title_edit.max_length=80;box.add_child(title_edit)
 caption_edit=TextEdit.new();caption_edit.placeholder_text="Explain composition, audience and what you would improve.";caption_edit.custom_minimum_size.y=85;box.add_child(caption_edit)
 var shot=Button.new();shot.text="Capture clean PNG • 3 second countdown (F8)";shot.custom_minimum_size.y=44;box.add_child(shot);shot.pressed.connect(request_photo)
 screenshot_note=Label.new();screenshot_note.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;screenshot_note.text="OBS records video. F9 hides the camera panel; F10 hides gameplay HUD. Guides never appear in exported photos. Live multiplayer keeps running.";box.add_child(screenshot_note)
 var lessons=Button.new();lessons.text="Composition challenges & audio brief";box.add_child(lessons);lessons.pressed.connect(func():preload("res://scripts/studio_ui.gd").lesson(self,"TELL A STORY WITH A FRAME","Choose a brief. Capture, explain and revise.",[
 {"title":"Five-shot story","body":"Establish a place, introduce a subject, show an action, reveal a detail, and finish with a consequence. Use leading lines, negative space and foreground layers intentionally."},
 {"title":"Composition is a choice","body":"Place a character on a third; compare with centred symmetry. Use a road or bridge to guide the eye. Leave looking room in front of a moving subject. Explain why your audience should look there."},
 {"title":"Promotion & sound","body":"Make a 20-second OBS trailer for one audience. Plan an opening, action and ending. Score it in FL Studio; keep dialogue/effects clear. Export original effects into the Ability Lab Sound tab."},
 {"title":"Critique & revise","body":"Keep your first and revised frame. Explain one change, the reason, and whether another student noticed the intended subject. These tools teach composition and storytelling; real-camera exposure/lens practice still happens with a camera."}]))
 var gallery=Button.new();gallery.text="My portfolio • last 8 captioned thumbnails";box.add_child(gallery);gallery.pressed.connect(show_portfolio)
func request_photo()->void:
 if not enabled() or capturing or countdown>0:return
 if not game.session_menu.page.is_empty() or (game.get("menu")!=null and not game.menu.is_empty()):return
 countdown=3;shutter_label.show()
 if portfolio_panel!=null:portfolio_panel.hide()
func take_photo()->void:
 capturing=true;shutter_label.hide();restore_button.hide();panel.hide();border.hide();guides.hide();apply_clean(true)
 if portfolio_panel!=null:portfolio_panel.hide()
 game.queue_redraw();await get_tree().process_frame;await RenderingServer.frame_post_draw
 var image=get_viewport().get_texture().get_image()
 if aspect!=0:
  var r=guides.frame();image=image.get_region(Rect2i(r))
 var title=title_edit.text if is_instance_valid(title_edit) and not title_edit.text.is_empty() else "Crossroads frame"
 var caption=caption_edit.text if is_instance_valid(caption_edit) else ""
 preload("res://scripts/media_portfolio.gd").add(game,image,title,caption)
 var bytes=image.save_png_to_buffer();capturing=false;apply_clean(clean_view);border.show();guides.show();update_visible()
 if portfolio_panel!=null:portfolio_panel.show()
 if is_instance_valid(screenshot_note):screenshot_note.text="Photo captured. Full PNG downloads separately; a captioned thumbnail is kept in your profile (outside testing modes)."
 save_bytes(bytes,"crossroads-"+str(Time.get_unix_time_from_system()).replace(".","-")+".png","image/png")
func save_bytes(bytes:PackedByteArray,filename:String,mime:String)->void:
 if OS.has_feature("web"):JavaScriptBridge.download_buffer(bytes,filename,mime)
 else:
  native_save=FileDialog.new();native_save.access=FileDialog.ACCESS_FILESYSTEM;native_save.file_mode=FileDialog.FILE_MODE_SAVE_FILE;native_save.current_file=filename;add_child(native_save)
  var dialog=native_save
  dialog.file_selected.connect(func(path:String):var f=FileAccess.open(path,FileAccess.WRITE);if f!=null:f.store_buffer(bytes);dialog.queue_free())
  dialog.canceled.connect(dialog.queue_free)
  dialog.popup_centered(Vector2i(850,480))
func show_portfolio()->void:
 if portfolio_panel==null:return
 for child in portfolio_panel.get_children():child.queue_free()
 var scroll=ScrollContainer.new();scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;portfolio_panel.add_child(scroll)
 var box=VBoxContainer.new();box.size_flags_horizontal=Control.SIZE_EXPAND_FILL;scroll.add_child(box)
 var back=Button.new();back.text="Back to tools";box.add_child(back);back.pressed.connect(open_tools)
 var shots:Array=game.legacy.data.get("media_portfolio",[])
 var download=Button.new();download.text="Download photo reflection report";box.add_child(download);download.pressed.connect(func():save_bytes(preload("res://scripts/media_portfolio.gd").report(shots).to_utf8_buffer(),"crossroads-photo-reflection.md","text/markdown"))
 for entry in shots:
  var row=HBoxContainer.new();box.add_child(row);var pic=TextureRect.new();pic.custom_minimum_size=Vector2(160,100);pic.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;pic.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;var im=Image.new();im.load_png_from_buffer(Marshalls.base64_to_raw(entry.image));pic.texture=ImageTexture.create_from_image(im);row.add_child(pic)
  var detail=VBoxContainer.new();detail.size_flags_horizontal=Control.SIZE_EXPAND_FILL;row.add_child(detail)
  var label=Label.new();label.text=entry.title+"\n"+entry.caption;label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;label.size_flags_horizontal=Control.SIZE_EXPAND_FILL;detail.add_child(label)
  var edit=Button.new();edit.text="Edit reflection";edit.disabled=preload("res://scripts/profile_store.gd").testing();detail.add_child(edit);edit.pressed.connect(edit_reflection.bind(str(entry.time)))
 if shots.is_empty():var label=Label.new();label.text="Capture a frame and explain your choices to start.";box.add_child(label)
func _exit_tree()->void:
 apply_clean(false)

func edit_reflection(shot_time:String)->void:
 var shots:Array=game.legacy.data.get("media_portfolio",[])
 var index=-1
 for i in shots.size():
  if shots[i].time==shot_time:index=i;break
 if index<0:return
 var dialog=ConfirmationDialog.new();dialog.title="Reflect on this frame";dialog.ok_button_text="Save reflection";add_child(dialog);preload("res://scripts/studio_ui.gd").apply(dialog)
 var text=TextEdit.new();text.text=shots[index].caption;text.custom_minimum_size=Vector2(520,180);dialog.add_child(text)
 dialog.confirmed.connect(func():
  if not preload("res://scripts/profile_store.gd").testing():
   var current:Array=game.legacy.data.get("media_portfolio",[])
   for shot in current:
    if shot.time==shot_time:shot.caption=text.text.left(1200);break
   game.legacy.data.media_portfolio=current;game.legacy.save();show_portfolio()
  dialog.queue_free())
 dialog.canceled.connect(dialog.queue_free);dialog.popup_centered(Vector2i(600,280))

func set_normal_zoom(value:float)->void:
 if value not in [.75,1.0,1.25]:return
 normal_zoom=value
 var cfg=ConfigFile.new();cfg.set_value("camera","zoom",value);cfg.save("user://fx_camera.cfg")
 refresh_camera()

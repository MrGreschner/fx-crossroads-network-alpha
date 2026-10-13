extends SceneTree
func _initialize()->void:call_deferred("run")
func run()->void:
 var host=OS.get_cmdline_user_args().has("host")
 root.set_meta("fx_intro_seen",true);root.set_meta("fx_tutorial_offered",true)
 var g=load("res://scenes/main.tscn").instantiate();root.add_child(g);current_scene=g
 for n in 5:await process_frame
 g.set_process(false);g.presentation.close();g.session_menu.resume();var w=g.hero_workshop;w.open();w.panel.show();if is_instance_valid(w.hub):w.hub.hide()
 w.project=preload("res://scripts/workshop_project.gd").fresh();w.project.hero.name="Socket shared hero"
 var image=Image.create(32,32,false,Image.FORMAT_RGBA8);image.fill(Color.TRANSPARENT);w.project.hero.art.idle=Marshalls.raw_to_base64(image.save_png_to_buffer())
 var p=root.get_node("FXStudioPartner");p.open(w);p.service_url="ws://127.0.0.1:33478";p.name_field.text="Main" if host else "Partner"
 if not host:p.code_field.text=FileAccess.get_file_as_string("/tmp/fx138-invite.txt")
 p.connect_session(host)
 for n in 300:
  await create_timer(.05).timeout
  if not p.code.is_empty() and not p.shared.is_empty() and not p.waiting:break
 if p.code.is_empty() or p.shared.is_empty():push_error("Could not establish shared project");quit(1);return
 if host:
  var f=FileAccess.open("/tmp/fx138-invite.txt",FileAccess.WRITE);f.store_string(p.code);f.close()
 await create_timer(2).timeout
 var editor=preload("res://scripts/studio_pixel_editor.gd").new();w.add_child(editor);editor.setup(str(w.project.hero.art.get("idle","")),"Idle");editor.bind_live(["value","hero","art","idle"])
 await create_timer(.5).timeout
 editor.canvas.image.set_pixel(1 if host else 2,1 if host else 2,Color.RED if host else Color.BLUE);editor.live_dirty=true
 await create_timer(3).timeout
 var final=Image.new();final.load_png_from_buffer(Marshalls.base64_to_raw(w.project.hero.art.idle))
 var passed=final.get_pixel(1,1)==Color.RED and final.get_pixel(2,2)==Color.BLUE and editor.canvas.image.get_pixel(1,1)==Color.RED and editor.canvas.image.get_pixel(2,2)==Color.BLUE
 print("LIVE SOCKET ","HOST" if host else "PARTNER",": ",passed)
 p.leave();g.queue_free();await process_frame;quit(0 if passed else 1)

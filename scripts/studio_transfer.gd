extends Node
## Reusable native/web import, scoped to the open Lab.
signal received(text:String)
signal failed(message:String)
var callback:JavaScriptObject
var mode="json"
var max_bytes=2097152
func choose(kind:String="json")->void:
 mode=kind
 if OS.has_feature("web"):
  callback=JavaScriptBridge.create_callback(func(args:Array):
   if args.is_empty():return
   var value=str(args[0]);if value.begins_with("ERROR:"):failed.emit(value.substr(6))
   else:received.emit(value)
  )
  JavaScriptBridge.get_interface("window").fxStudioFileImport=callback
  var js="(()=>{const p=document.createElement('input');p.type='file';p.accept="+JSON.stringify(".png,image/png" if kind=="png" else ".json,application/json")+";p.onchange=async()=>{const f=p.files[0];if(!f)return;if(f.size>"+str(max_bytes)+"){window.fxStudioFileImport('ERROR:File is too large');return;}try{"
  js+="const r=new FileReader();r.onload=()=>window.fxStudioFileImport(String(r.result).split(',')[1]);r.readAsDataURL(f);" if kind=="png" else "window.fxStudioFileImport(await f.text());"
  JavaScriptBridge.eval(js+"}catch(e){window.fxStudioFileImport('ERROR:Could not read file');}};p.click();})()",true)
 else:
  var dialog=FileDialog.new();dialog.access=FileDialog.ACCESS_FILESYSTEM;dialog.file_mode=FileDialog.FILE_MODE_OPEN_FILE;dialog.add_filter("*.png" if kind=="png" else "*.json","Artwork" if kind=="png" else "Student project");add_child(dialog)
  dialog.file_selected.connect(func(path:String):
   var file=FileAccess.open(path,FileAccess.READ)
   if file==null or file.get_length()>max_bytes:failed.emit("Could not read this file, or it exceeds the allowed size.")
   elif mode=="png":received.emit(Marshalls.raw_to_base64(file.get_buffer(file.get_length())))
   else:received.emit(file.get_as_text())
   dialog.queue_free()
  )
  dialog.canceled.connect(dialog.queue_free);dialog.popup_centered(Vector2i(800,500))

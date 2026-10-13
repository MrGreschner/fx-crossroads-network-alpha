extends RefCounted
## Curated, portable starting points. Existing drafts and explicit edits take precedence.
static func all(kind:String)->Array:
 var data=JSON.parse_string(FileAccess.get_file_as_string("res://content/workshop/lab-examples.json"))
 return data.get(kind,[]).duplicate(true) if data is Dictionary else []
static func random_example(kind:String)->Dictionary:
 var choices=all(kind)
 return copy_as_new(kind,choices[randi()%choices.size()]) if not choices.is_empty() else {}
static func picker(parent:Node,kind:String,callback:Callable)->OptionButton:
 var choices=all(kind);var option=OptionButton.new();option.custom_minimum_size=Vector2(220,40);option.fit_to_longest_item=false;option.add_item("Load an example…");parent.add_child(option)
 for value in choices:option.add_item(str(value.hero.name) if kind=="hero" else str(value.name))
 option.item_selected.connect(func(index:int):if index>0:confirm(parent,func():callback.call(copy_as_new(kind,choices[index-1])));option.select(0))
 return option
static func confirm(parent:Node,callback:Callable)->void:
 var dialog=ConfirmationDialog.new();dialog.title="Replace this draft?";dialog.dialog_text="Download or save your draft first if you want to keep it. This replaces only this lab's current draft; saved library projects and your player profile stay unchanged.";dialog.ok_button_text="Start fresh / load";parent.add_child(dialog);preload("res://scripts/studio_ui.gd").apply(dialog)
 dialog.confirmed.connect(func():callback.call();dialog.queue_free());dialog.canceled.connect(dialog.queue_free);dialog.popup_centered(Vector2i(560,210))

static func copy_as_new(kind:String,value:Dictionary)->Dictionary:
 var copy=value.duplicate(true)
 if kind=="hero":copy.project_id=preload("res://scripts/workshop_project.gd").fresh().project_id
 if kind=="enemy":copy.id="enemy-"+str(Time.get_unix_time_from_system())+"-"+str(randi())
 return copy

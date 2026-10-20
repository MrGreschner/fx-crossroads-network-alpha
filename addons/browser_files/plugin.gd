@tool
extends EditorPlugin

var browser_export: EditorExportPlugin

class BrowserExport extends EditorExportPlugin:
	var output_path := ""
	func _get_name() -> String:
		return "CrossroadsBrowserFiles"
	func _export_begin(features: PackedStringArray, _debug: bool, path: String, _flags: int) -> void:
		output_path = path if features.has("web") else ""
	func _export_end() -> void:
		if output_path.is_empty():
			return
		if output_path.get_extension().to_lower() != "html":
			push_warning("Export Web to index.html, then ZIP the output folder to include the browser files.")
			return
		var files = JSON.parse_string(FileAccess.get_file_as_string("res://web/browser-files.json"))
		if not files is Array:
			push_error("Missing browser files manifest.")
			return
		for relative in files:
			var destination: String = output_path.get_base_dir().path_join(str(relative))
			DirAccess.make_dir_recursive_absolute(destination.get_base_dir())
			var error := DirAccess.copy_absolute(ProjectSettings.globalize_path("res://" + str(relative)), destination)
			if error != OK:
				push_error("Unable to export browser file: " + str(relative))

func _enter_tree() -> void:
	browser_export = BrowserExport.new()
	add_export_plugin(browser_export)

func _exit_tree() -> void:
	remove_export_plugin(browser_export)

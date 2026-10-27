extends RefCounted
## In-app pixel clipboard. Independent PNG copy; never writes another pose or OS clipboard.
const SIDE=80
const BASELINE=74
static var clipboard=""
static var source_label=""
static func copy_picture(encoded:String,label:String="picture")->bool:
 if not valid_encoding(encoded):return false
 if not preload("res://scripts/workshop_project.gd").png_error(Marshalls.base64_to_raw(encoded)).is_empty():return false
 clipboard=encoded;source_label=label;return true
static func open_guide(owner:Node)->Node:
 var guide=preload("res://scripts/studio_style233.gd").new();owner.add_child(guide);guide.setup();return guide

static func valid_encoding(encoded:String)->bool:
 if encoded.is_empty() or encoded.length()%4!=0 or encoded.length()>180000:return false
 var regex=RegEx.new();regex.compile("^[A-Za-z0-9+/]*={0,2}$");return regex.search(encoded)!=null

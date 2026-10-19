extends RefCounted
## Public identity is independent of stable save schemas and network contracts.
const TITLE="Crossroads: Realms Beyond"
const SHORT="Crossroads"
const SUBTITLE="Realms Beyond"
const TAGLINE="Find your path. Create what’s next."
const BUILD=186
static var cached:Dictionary={}
static func config()->Dictionary:
 if cached.is_empty():
  var value=JSON.parse_string(FileAccess.get_file_as_string("res://content/brand.json"))
  if value is Dictionary:cached=value
 return cached
static func download_url()->String:
 var url=str(config().get("download_url","")).strip_edges()
 return url if url.begins_with("https://") and not "\n" in url and not "\r" in url else ""
static func room_url()->String:
 var url=str(config().get("room_service_url","")).strip_edges()
 return url if url.begins_with("wss://") else "wss://fx-crossroads-rooms.onrender.com"
static func network_url()->String:
 var url=str(config().get("network_service_url","")).strip_edges()
 return url if url.begins_with("wss://") else ""
static func insights_http()->String:return network_url().replace("wss://","https://").trim_suffix("/")
static func service_http()->String:return room_url().replace("wss://","https://").trim_suffix("/")

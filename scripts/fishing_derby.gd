extends RefCounted

const BRAND=preload("res://scripts/brand.gd")
const UI=preload("res://scripts/studio_ui.gd")
const C=preload("res://scripts/fishing_catalog.gd")

static func submit(fishing:Node,catch:Dictionary)->void:
 if not fishing.game.legacy.community.allowed():return
 var account=fishing.get_node("/root/FXAccount")
 if not account.loaded or account.conflict:return
 var url:=BRAND.insights_http().trim_suffix("/")
 if url.is_empty():return
 var request:=HTTPRequest.new();request.timeout=8;fishing.add_child(request)
 request.request_completed.connect(func(_r,_c,_h,_b):request.queue_free(),CONNECT_ONE_SHOT)
 var body:={"id":catch.id,"pool":catch.pool,"species":catch.species,"kg":catch.kg}
 if request.request(url+"/fishing-derbies/entry",account.record_headers(),HTTPClient.METHOD_POST,JSON.stringify(body))!=OK:request.queue_free()

static func board(fishing:Node,parent:Control)->PanelContainer:
 var panel:=PanelContainer.new();UI.apply(panel);parent.add_child(panel)
 var col:=VBoxContainer.new();panel.add_child(col)
 fishing.label(col,"RIPPLE & REEL • DERBIES & TROPHIES",24)
 var scroll:=ScrollContainer.new();scroll.size_flags_vertical=Control.SIZE_EXPAND_FILL;scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;col.add_child(scroll)
 var body:=VBoxContainer.new();body.size_flags_horizontal=Control.SIZE_EXPAND_FILL;scroll.add_child(body)
 var status:Label=fishing.label(body,"Loading derby board…",17)
 fishing.button(col,"Back to Ripple & Reel",panel.queue_free)
 var request:=HTTPRequest.new();request.timeout=8;panel.add_child(request)
 request.request_completed.connect(func(_r:int,code:int,_h:PackedStringArray,bytes:PackedByteArray):
  var data=JSON.parse_string(bytes.get_string_from_utf8())
  if code!=200 or not data is Dictionary:
   status.text="The derby board is unavailable."
   return
  status.text="No derby is scheduled." if data.events.is_empty() else "Rod fishing • Sign in to enter • Heaviest eligible fish wins"
  for event in data.events:
   fishing.label(body,str(event.title)+" • "+str(event.state),21)
   fishing.label(body,"%s to %s UTC" % [str(event.starts).substr(0,16).replace("T"," "),str(event.ends).substr(0,16).replace("T"," ")],15)
   fishing.label(body,str(event.location)+" • "+str(C.fish().get(event.species,{}).get("name","Any species")),15)
   for entry in event.standings:
    var place:=int(entry.place)
    var award:=str(place)
    if event.state=="Finished" and place<=3:award=["Gold","Silver","Bronze"][place-1]
    fishing.label(body,"%s  %s • %.2f kg" % [award,entry.username,entry.kg],16)
 ,CONNECT_ONE_SHOT)
 if request.request(BRAND.insights_http().trim_suffix("/")+"/fishing-derbies")!=OK:status.text="The derby board is unavailable."
 return panel

extends RefCounted
static func build(parent:Node,l:Node,realm:String)->void:
 var ui=preload("res://scripts/garden_ui.gd");var state=preload("res://scripts/named_records.gd").state(l);var public=l.community.snapshot.get("named",{}).get("route_times",{})
 var row=HBoxContainer.new();parent.add_child(row)
 ui.label(parent,"List times: your best / community best • S = solo • Co = co-op",12)
 for route in ["solo","coop"]:
  var card=preload("res://scripts/studio_ui.gd").card(row,route.to_upper()+" • FASTEST CLEAR","")
  card.get_parent().size_flags_horizontal=Control.SIZE_EXPAND_FILL
  var personal=float(state.routes[route].all.get(realm,0));ui.label(card,"Personal: "+(preload("res://scripts/named_records_ui.gd").clock(personal) if personal>0 else "No clear yet"),15)
  var found=false
  for r in public.get(route,{}).get("all",[]):
   if r.get("key")==realm:preload("res://scripts/records_hall_ui.gd").run_row(card,l,r,"Community best",preload("res://scripts/named_records_ui.gd").clock(float(r.value)));found=true
  if not found:ui.label(card,"Community: not recorded / refresh pending",14)

static func summary(l:Node,realm:String)->String:
 var s=preload("res://scripts/named_records.gd").state(l);var public=l.community.snapshot.get("named",{}).get("route_times",{});var parts=[]
 for route in ["solo","coop"]:
  var own=float(s.routes[route].all.get(realm,0));var best=0.0
  for record in public.get(route,{}).get("all",[]):
   if record.get("key")==realm:best=float(record.value)
  var clock=preload("res://scripts/named_records_ui.gd")
  parts.append(("S" if route=="solo" else "Co")+": "+(clock.clock(own) if own>0 else "—")+" / "+(clock.clock(best) if best>0 else "—"))
 return "  •  ".join(parts)

extends CanvasLayer
var bg:RefCounted
var panel:VBoxContainer
var choices:VBoxContainer
var recall:Button
var order:Button
func setup(value:RefCounted)->void:
 bg=value;layer=34;panel=VBoxContainer.new();add_child(panel);preload("res://scripts/studio_ui.gd").apply(panel)
 recall=button(panel,"Recall to base",func():bg.command.request("order:recall"))
 order=button(panel,"Army orders ▾",func():choices.visible=not choices.visible)
 choices=VBoxContainer.new();panel.add_child(choices);choices.hide()
 for key in bg.command.ORDERS:
  button(choices,str(bg.command.ORDERS[key]),func():bg.command.request("order:"+key);choices.hide())
func button(parent:Node,title:String,action:Callable)->Button:
 var b=Button.new();b.text=title;b.clip_text=true;b.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS;b.tooltip_text=title;b.custom_minimum_size=Vector2(214,34);b.add_theme_font_size_override("font_size",14);parent.add_child(b);b.pressed.connect(action);return b
func _process(_dt:float)->void:
 var g:Node=bg.game;visible=g.started and g.mode=="battlegrounds" and g.shop_open.is_empty() and g.presentation.page.is_empty() and g.session_menu.page.is_empty() and bg.winner<0 and g.get("dedicated")!=true and bg.owners.has(g.my_id)
 if not visible:return
 panel.position=Vector2(g.VIEW.x-232,minf(290,g.VIEW.y-350));panel.size.x=214
 var b:Dictionary=bg.bases.get(bg.owners.get(g.my_id,""),{});var left=maxi(0,ceili(float(bg.command.recall_ready.get(g.my_id,0))-bg.clock))
 recall.text="Recall to base • "+("ready" if left<=0 else "%d:%02d" % [left/60,left%60]);recall.disabled=left>0 or int(g.health.get(g.my_id,0))<=0 or float(b.get("hp",0))<=0 or g.start_countdown>0
 order.text="Army: "+str(bg.command.ORDERS.get(str(b.get("order","open")),"Open attack")).trim_suffix(" • new recruits").replace("enemy ","")+" ▾"

extends CanvasLayer
var age=0.0
var duration=1.1
var kind=""
var surface:Control
func _ready()->void:
 layer=18;surface=Control.new();surface.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);surface.mouse_filter=Control.MOUSE_FILTER_IGNORE;add_child(surface);surface.draw.connect(render)
func play(value:String)->void:kind=value;age=0;surface.queue_redraw()
func _process(delta:float)->void:
 if kind.is_empty():return
 age+=delta
 if age>=duration:kind=""
 surface.queue_redraw()
func render()->void:
 if kind.is_empty():return
 var extent=surface.get_viewport_rect().size
 var alpha=sin(clampf(age/duration,0,1)*PI)
 var c=Color("#71dde7") if kind=="portal" else Color("#dcb486") if kind=="descent" else Color("#eedfb8")
 # A quiet arrival caption instead of a full-screen flash and expanding ring.
 var width=minf(480,extent.x*.7)
 var panel=Rect2(Vector2((extent.x-width)*.5,extent.y*.22),Vector2(width,42))
 surface.draw_rect(panel,Color(.06,.13,.16,alpha*.4))
 surface.draw_line(panel.position+Vector2(36,41),panel.end-Vector2(36,1),Color(c,alpha*.35),1)
 var label="WELCOME TO CROSSROADS" if kind=="town" else "DOWN INTO CAVE DESCENT" if kind=="descent" else "THROUGH THE CROSSROADS"
 surface.draw_string(ThemeDB.fallback_font,panel.position+Vector2(0,27),label,HORIZONTAL_ALIGNMENT_CENTER,width,18,Color(c,alpha*.75))

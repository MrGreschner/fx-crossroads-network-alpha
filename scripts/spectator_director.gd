extends CanvasLayer
## Local broadcast controls. The host's separate chair never joins combat.
var game:Node
var picker:OptionButton
var view_mode=0
var focus=Vector2.ZERO
var elapsed=0.0
var heat:Array=[]
func setup(owner:Node)->void:
 game=owner;layer=43;picker=OptionButton.new();add_child(picker);picker.custom_minimum_size=Vector2(295,40)
 for title in ["Overview • whole battlefield","Action • follow damage","Tour • cycle through heroes"]:picker.add_item(title)
 preload("res://scripts/top_button_style.gd").apply(picker)
 picker.item_selected.connect(func(index:int):view_mode=index;elapsed=0;focus=game.FIELD.size*.5)
 focus=game.FIELD.size*.5
func record_damage(point:Vector2,amount:float)->void:
 if not game.spectating():return
 heat.append({"point":point,"amount":amount,"life":5.0})
 if heat.size()>80:heat.pop_front()
func _process(delta:float)->void:
 if game==null:return
 picker.visible=game.started and game.spectating() and game.presentation.page.is_empty()
 picker.position=Vector2(game.get_viewport().get_visible_rect().size.x-315,8)
 elapsed+=delta
 for n in range(heat.size()-1,-1,-1):
  heat[n].life-=delta
  if heat[n].life<=0:heat.remove_at(n)
 var ids:Array=game.positions.keys().filter(func(id):return float(game.health.get(id,0))>0)
 if ids.is_empty():return
 var target:Vector2=game.positions[ids[int(elapsed/6)%ids.size()]]
 if view_mode==1 and not heat.is_empty():
  var strongest=heat[0]
  for event in heat:
   if float(event.amount)*float(event.life)>float(strongest.amount)*float(strongest.life):strongest=event
  target=strongest.point
 focus=focus.lerp(target,1-exp(-delta*2.8))
func _unhandled_input(event:InputEvent)->void:
 if picker.visible and event is InputEventKey and event.pressed and not event.echo and event.keycode==KEY_C:
  view_mode=(view_mode+1)%3;picker.select(view_mode);get_viewport().set_input_as_handled()

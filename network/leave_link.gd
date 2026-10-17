extends Node
## Keep an explicitly left socket alive briefly so its final packet is polled
## out before scene changes or a fresh Host/Join replaces the active connection.
var peer:WebSocketPeer
var until=0
func setup(value:WebSocketPeer)->void:
 peer=value;until=Time.get_ticks_msec()+1000
 if peer.get_ready_state()==WebSocketPeer.STATE_OPEN:peer.send_text(JSON.stringify({"type":"leave"}))
func _process(_delta:float)->void:
 if peer==null:queue_free();return
 peer.poll()
 if peer.get_ready_state()==WebSocketPeer.STATE_CLOSED:peer=null;queue_free();return
 if Time.get_ticks_msec()>=until:
  peer.close(1000,"left_room");peer.poll();peer=null;queue_free()

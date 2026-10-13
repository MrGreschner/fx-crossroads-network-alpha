extends SceneTree
func _initialize()->void:
 var peer:=WebRTCPeerConnection.new()
 var result:=peer.initialize({"iceServers":[{"urls":["stun:stun.cloudflare.com:3478"]}]})
 if result!=OK:push_error("Native WebRTC not registered. Install the official Godot 4.3+ extension before Windows export.");quit(1);return
 var channel:=peer.create_data_channel("probe",{"negotiated":true,"id":1})
 if channel==null:push_error("Native WebRTC data-channel creation failed.");peer.close();quit(1);return
 print("Native WebRTC initialization and data-channel creation passed.")
 peer.close();quit()

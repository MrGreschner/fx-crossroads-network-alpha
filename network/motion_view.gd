extends RefCounted
## Bounded present-time rendering. Never used for authoritative hits or collision.
var tracks:Dictionary={}
func sample(id:String,fallback:Vector2,now:float)->Vector2:
 if not tracks.has(id):return fallback
 var track:Dictionary=tracks[id]
 var elapsed=clampf(now-float(track.t),0,.12)
 return track.p+track.v*elapsed+track.offset*maxf(0,1-elapsed/.06)
func receive(id:String,p:Vector2,v:Vector2,now:float,ahead:float)->void:
 v=v.limit_length(900)
 var target=p+v*clampf(ahead,0,.20)
 var offset=Vector2.ZERO
 if tracks.has(id):
  # Respawns/teleports snap; ordinary turns and stops blend briefly.
  if p.distance_to(tracks[id].raw)<160:offset=sample(id,p,now)-target
 tracks[id]={"p":target,"raw":p,"v":v,"t":now,"offset":offset}

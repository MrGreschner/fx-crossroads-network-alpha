extends RefCounted
## Protocol 3: gzip binary packets contain replaceable full state; text packets
## carry reliable control/events. Coalesce BEFORE decompression and parsing.
const KEEP=5 # 200 ms at 20 Hz covers the adaptive buffer target (at most 180 ms).
var entries:Array=[]
var states:Array=[]
var dropped=0
func clear()->void:
 entries.clear();states.clear();dropped=0
func push(bytes:PackedByteArray,binary:bool)->void:
 var entry={"bytes":bytes,"binary":binary,"skip":false}
 entries.append(entry)
 if binary:
  states.append(entry)
  if states.size()>KEEP:
   var obsolete:Dictionary=states.pop_front()
   obsolete.bytes=PackedByteArray();obsolete.skip=true;dropped+=1
func packets()->Array:
 var result:Array=[]
 for entry in entries:
  if not entry.skip:result.append(entry)
 return result

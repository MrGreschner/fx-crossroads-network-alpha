extends RefCounted
## Slow hysteresis: never change gameplay or react to a single stall/tab suspension.
const SCALES=[1.0,.85,.70]
var tier=0
var slow_windows=0
var changes=0
var sample_clock=0.0
var cooldown=0.0
var frames:Array=[]
func observe(delta:float,active:bool)->bool:
 cooldown=maxf(0,cooldown-delta)
 if not active or delta<=0 or delta>.15:
  frames.clear();sample_clock=0;slow_windows=0;return false
 frames.append(delta);sample_clock+=delta
 if frames.size()>240:frames.pop_front()
 if sample_clock<2:return false
 sample_clock=0
 var ordered=frames.duplicate();ordered.sort();frames.clear()
 if ordered.size()<20:return false
 var median=float(ordered[ordered.size()/2])
 slow_windows=slow_windows+1 if median>.021 else 0
 if slow_windows>=2 and cooldown<=0 and tier<SCALES.size()-1:
  tier+=1;changes+=1;slow_windows=0;cooldown=8;return true
 return false
func reset()->void:
 tier=0;slow_windows=0;frames.clear();sample_clock=0;cooldown=3
func scale_for(balanced:bool)->float:return float(SCALES[tier]) if balanced else 1.0

extends RefCounted
static func text(value:Dictionary)->String:
 var source=JSON.stringify(value);var parts=PackedStringArray();var begin=0
 for index in source.length():
  var point=source.unicode_at(index)
  if point<128:continue
  parts.append(source.substr(begin,index-begin))
  if point<=65535:parts.append("\\u%04x" % point)
  else:point-=65536;parts.append("\\u%04x\\u%04x" % [55296+(point>>10),56320+(point&1023)])
  begin=index+1
 parts.append(source.substr(begin));return "".join(parts)

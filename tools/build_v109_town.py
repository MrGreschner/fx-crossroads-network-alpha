from pathlib import Path
p=Path(__file__).resolve().parents[1]/'assets'
def save(name,body):
 (p/f'{name}.svg').write_text('<svg xmlns="http://www.w3.org/2000/svg" width="320" height="270" viewBox="0 0 320 270">'+body+'</svg>')
def rect(x,y,w,h,c,stroke='#30454c',sw=3):return f'<rect x="{x}" y="{y}" width="{w}" height="{h}" fill="{c}" stroke="{stroke}" stroke-width="{sw}"/>'
def poly(points,c):return f'<polygon points="{points}" fill="{c}" stroke="#30454c" stroke-width="4"/>'
def circle(x,y,r,c):return f'<circle cx="{x}" cy="{y}" r="{r}" fill="{c}"/>'
base='<ellipse cx="160" cy="249" rx="154" ry="16" fill="#1d3434" opacity=".25"/>'
pav=base+rect(20,231,280,23,'#899386')+rect(35,222,250,10,'#ccb78d')+poly('20,100 160,22 300,100','#477783')+poly('35,98 160,39 285,98','#709d9f')+rect(20,100,280,13,'#d5bd8d')
for x in [42,126,186,270]:pav+=rect(x,112,10,111,'#d6bb85')+rect(x-3,209,16,13,'#9e8561')
pav+=rect(80,166,163,11,'#b3986d')+rect(96,176,10,35,'#896948')+rect(218,176,10,35,'#896948')+rect(63,199,198,9,'#b79c71')
for x in [110,160,207]:pav+=circle(x,162,8,'#ded7a7')+circle(x,161,4,'#83afad')
pav+=rect(90,87,141,27,'#19363f', '#d8bf82')
for x in [20,280]:pav+=rect(x,119,18,26,'#d7c183')+rect(x+4,123,10,18,'#f2dc9a')
save('fellowship_v109',pav)
work=base+rect(31,113,260,124,'#b5ab90')+rect(40,124,244,111,'#9f9e8c')+poly('10,111 55,51 264,51 309,111','#4b6e86')+rect(24,112,272,12,'#d7bf89')
for x in [49,234]:work+=rect(x,139,40,51,'#314b52')+rect(x+4,143,32,43,'#8cc5d2')+rect(x+18,143,4,43,'#d0bf93')
work+=rect(130,157,61,80,'#4a4542')+rect(137,164,47,72,'#977356')+circle(176,200,3,'#e2c38c')+rect(99,111,124,26,'#233e4a','#cdbb8b')+rect(110,74,104,16,'#c1ae7b')
for x in [44,223]:work+=rect(x,213,51,14,'#ae865b')+rect(x+5,227,6,15,'#745b43')+rect(x+41,227,6,15,'#745b43')
work+=rect(58,191,19,19,'#83b0b2')+circle(67,190,10,'#abc5b5')+rect(226,194,37,18,'#c3a376')+rect(241,194,5,18,'#dfcc9e')+rect(225,32,26,55,'#8c948a')+rect(219,29,38,11,'#bab6a0')+rect(118,239,87,10,'#b8a17e')
save('relay_v109',work)
mill=base+rect(20,111,205,130,'#bcc0a6')+rect(29,120,187,116,'#d6cfad')+poly('5,110 48,45 196,45 239,110','#436a79')+rect(15,111,222,12,'#b99768')
for y in [123,160,199]:mill+=rect(27,y,190,5,'#9a805c')
for x in [27,110,204]:mill+=rect(x,122,7,115,'#9a805c')
mill+=rect(122,162,57,73,'#6a5d4b')+rect(127,168,46,68,'#95714d')+rect(49,141,42,40,'#46626a')+rect(54,146,32,30,'#a2d1cd')+rect(67,145,5,33,'#ddd2a3')+rect(70,111,131,26,'#203c43','#cfb889')+rect(33,220,34,20,'#bb9770')+rect(29,216,44,6,'#dcc794')+rect(235,174,22,22,'#657779')+rect(178,236,63,12,'#b4a37e')
save('mill_v109',mill)
tower=base+rect(38,229,248,25,'#829fa2')+rect(74,115,172,119,'#b0c3b5')+rect(65,100,190,20,'#6a939b')+poly('49,100 160,16 272,100','#4e697c')+poly('74,94 160,32 247,94','#7f9ab8')+rect(104,102,113,23,'#264957','#ccbce1')+rect(81,132,158,7,'#718f96')+rect(115,170,89,65,'#355468')+poly('117,172 161,141 202,172','#8296b6')+rect(126,178,68,55,'#91c9cd')+circle(160,184,18,'#d6f1ee')
for x in [90,218]:tower+=rect(x,151,12,51,'#608293')+rect(x+2,154,8,41,'#badce3')
tower+=circle(160,50,12,'#d9c7ef')+circle(160,50,6,'#edebff')+rect(65,237,192,9,'#c6d6c4')
save('mistglass_v109',tower)
barr=base+rect(19,96,283,137,'#899893')+rect(27,104,267,124,'#bcc2af')+poly('9,96 47,36 270,36 312,96','#4d6682')+rect(15,96,291,12,'#d7bd84')+rect(112,151,96,83,'#344954')+rect(121,158,78,76,'#936b4c')+rect(157,159,5,74,'#5b4d40')+rect(84,97,157,28,'#243b4e','#d5b87d')
for x in [34,236]:
 barr+=rect(x,132,45,49,'#475d67')+rect(x+5,138,35,37,'#81aebb')+rect(x+21,138,4,37,'#d7c792')+rect(x,196,45,23,'#7c6a53')
for y in [115,189,223]:barr+=rect(28,y,265,4,'#8b9a90')
for x in [45,267]:barr+=rect(x,7,5,86,'#a99b7c')+poly(f'{x+5},10 {x+37},18 {x+5},45','#83b6cf')
barr+=rect(100,232,123,16,'#cbb48b')+circle(161,64,12,'#d6c797')+poly('155,59 161,53 167,59 163,70 159,70','#4e687b')
save('barracks_v109',barr)

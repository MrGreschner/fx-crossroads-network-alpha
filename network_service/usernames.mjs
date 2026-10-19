// ASCII-only public aliases prevent invisible characters and homoglyph ambiguity.
const reserved=['admin','administrator','teacher','moderator','crossroads','support','principal','student','god','null','undefined'];
const blocked=['fuck','shit','bitch','cunt','cock','dick','pussy','porn','sex','nigger','nigga','faggot','fag','retard','rape','rapist','nazi','hitler','kkk','suicide','killall','whore','slut','asshole','motherfucker','cum','penis','vagina','boob','tits','chink','spic','tranny','paki','kike','dyke','jizz','wank','blowjob','handjob','anal','dildo','hentai','pedo','xxx','phuck','fvck','fuk','nlgger','niqqer','nigg','niglet','whitepower','heilhitler','putain','merde','salope','connard','encule','puta'];
export function checkUsername(value){
 if(typeof value!=='string'||!/^[A-Za-z][A-Za-z0-9_]{2,19}$/.test(value))throw Object.assign(Error('Use 3–20 letters, numbers or underscores, starting with a letter. No spaces or symbols.'),{status:400});
 const key=value.toLowerCase(),flat=key.replaceAll('_','');
 const variants=new Set([flat]);
 const substitutions={'0':['o'],'1':['i','l'],'2':['z'],'3':['e'],'4':['a'],'5':['s'],'6':['g'],'7':['t'],'8':['b'],'9':['g']};
 let current=[''];for(const c of flat){current=current.flatMap(s=>(substitutions[c]||[c]).map(v=>s+v)).slice(0,256);}for(const x of current){variants.add(x);variants.add(x.replace(/(.)\1+/g,'$1'));}
 if([...variants].some(v=>reserved.some(w=>v.includes(w))||blocked.some(w=>v.includes(w)))||/(69|420|1488|88)$/.test(flat))throw Object.assign(Error('Please choose another appropriate game name. Do not use your real name or impersonate staff.'),{status:400});
 return {username:value,key};
}

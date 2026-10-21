// Only SQLSTATE/error class is exposed. Never disclose SQL, connection strings or data values.
export function dashboardFailure(error,route){
 const raw=String(error?.code||'');
 const code=/^[0-9A-Z]{5}$/.test(raw)?raw:['ECONNREFUSED','ECONNRESET','ENOTFOUND','ETIMEDOUT','EAI_AGAIN'].includes(raw)?raw:/timeout|timed out/i.test(String(error?.message||''))?'TIMEOUT':'UNKNOWN';
 let detail='The report request failed. Send this error code to the game developer.';
 if(code==='57014'||code==='TIMEOUT')detail='The report request timed out. The game database may be busy.';
 else if(code.startsWith('08')||['ECONNREFUSED','ECONNRESET','ENOTFOUND','ETIMEDOUT','EAI_AGAIN','57P01','57P02','57P03'].includes(code))detail='The server could not reach the database. Check the existing database service status.';
 else if(code==='42501')detail='The server database user cannot read the requested report table.';
 else if(['42P01','42703','42883'].includes(code))detail='The report query does not match the available database tables or fields.';
 else if(code.startsWith('22'))detail='A stored report contains a value this query cannot read.';
 console.error('Crossroads dashboard request failed',JSON.stringify({route:String(route).split('?')[0].slice(0,80),code}));
 return {error:`Report data could not load (${code}). ${detail}`,code};
}
// Accepted numeric JSON remains numeric. Old booleans, strings, arrays and objects
// are treated as missing observations; no stored records are changed or removed.
export function reportNumberSQL(value){
 return `(CASE WHEN jsonb_typeof(${value})='number' THEN CASE WHEN (${value})::numeric BETWEEN -1e15 AND 1e15 THEN (${value})::double precision END END)`;
}

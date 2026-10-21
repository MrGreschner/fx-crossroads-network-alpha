import { randomUUID, randomInt, createHash } from 'node:crypto';
import { inflateSync, deflateSync } from 'node:zlib';

// Pure room logic, shared by the WebSocket adapter and its tests.
export class Rooms {
  constructor({ now = () => Date.now(), random = Math.random } = {}) {
    this.education = new Map(); this.assessments = new Map(); this.partners = new Map(); this.classes = new Map(); this.clients = new Map(); this.rooms = new Map(); this.now = now; this.random = random;
  }
  connect(send) {
    const client = { id: randomUUID(), name: 'Player', room: '', send, seen: this.now(), rateAt: this.now(), count: 0, online: true, detachedAt: 0, token: randomUUID(), version: 0 };
    this.clients.set(client.id, client);
    send({ type: 'server_info', version: 30, features: ['public_rooms', 'join_random', 'resume_session', 'room_list', 'join_requests', 'arena_seats', 'spectator_host', 'arena_bots', 'battlegrounds', 'realtime_stream', 'classroom_broadcast', 'studio_partner', 'studio_live', 'custom_heroes', 'assessment_review', 'education_rooms'] });
    return client;
  }
  config(data) {
    const mode = ['defense', 'arena', 'coop', 'descent', 'battlegrounds'].includes(data.mode) ? data.mode : 'defense';
    const realm = typeof data.realm === 'string' && /^[a-z0-9_]{1,48}$/.test(data.realm) ? data.realm : 'grove';
    const rule = mode === 'battlegrounds' || data.rule === 'teams' ? 'teams' : 'ffa';
    const bg_team_size = Number(data.bg_team_size) === 3 ? 3 : 4;
    const bg_map = data.bg_map === 'warzone' ? 'warzone' : 'woodland';
    // Old builds can host/join by code, but never match a different game protocol.
    return { allow_custom: data.version >= 32 && data.allow_custom === true, mode, realm, rule, bg_map, bg_team_size, ai_difficulty: ['easy','medium','hard'].includes(data.ai_difficulty) ? data.ai_difficulty : 'medium', bots: mode === 'arena' && data.version >= 16 ? Math.max(0, Math.min(3, Math.trunc(Number(data.bots) || 0), Math.max(2, Math.min(8, Math.trunc(Number(data.seats) || 4))) - 1)) : 0, seats: mode === 'battlegrounds' ? bg_team_size * 2 : mode === 'arena' ? Math.max(2, Math.min(8, Math.trunc(Number(data.seats) || 4))) : (mode === 'defense' && data.version >= 17 ? 3 : mode === 'coop' && realm === 'wayfarer' ? 2 : 4), spectator: (mode === 'arena' || data.version >= 29 && ['battlegrounds','descent'].includes(mode)) && data.spectator === true, arena_map: ['crossroads','sand','storm','forest','clock'].includes(data.arena_map) ? data.arena_map : 'sand', opening: data.opening === true, no_items: data.no_items === true, random_heroes: data.random_heroes === true, version: [12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,32].includes(data.version) ? data.version : 0 };
  }
  customAllowed(room,data) { return data.custom !== true || room.config.allow_custom && (!room.public || data.balanced === true); }
  customStatus(client,data) {
    const room=this.rooms.get(client.room); if(!room || room.started)return;
    if(!this.customAllowed(room,data))return this.error(client,'This custom hero cannot enter this room.');
    client.custom=data.custom===true;client.balanced=data.balanced===true;
  }
  capacity(room) { return room.config.seats - room.config.bots + (room.config.spectator ? 1 : 0); }
  playerCount(room) { return room.members.size + room.config.bots - (room.config.spectator ? 1 : 0); }
  message(client, data) {
    if (!this.clients.has(client.id) || !data || typeof data !== 'object' || Array.isArray(data)) return;
    client.seen = this.now();
    if (this.now() - client.rateAt > 1000) { client.rateAt = this.now(); client.count = 0; }
    if (++client.count > 100) return this.error(client, 'Too many room requests.');
    if (String(data.type || '').startsWith('edu_')) return this.eduMessage(client,data);
    if (String(data.type || '').startsWith('partner_')) return this.partnerMessage(client,data);
    if (String(data.type || '').startsWith('class_')) return this.classMessage(client,data);
    if (String(data.type || '').startsWith('assessment_')) return this.assessmentMessage(client,data);
    switch (data.type) {
      case 'heartbeat': return;
      case 'resume': return this.resume(client, data);
      case 'host': return this.host(client, data);
      case 'join': return this.join(client, String(data.code || '').trim().toUpperCase(), data.name, data.version, data);
      case 'list_rooms': return this.listRooms(client, data);
      case 'join_request': return this.requestJoin(client, data);
      case 'join_reply': return this.replyJoin(client, data);
      case 'join_random': return this.randomJoin(client, data);
      case 'signal': return this.signal(client, data);
      case 'custom_status': return this.customStatus(client,data);
      case 'room_update': return this.update(client, data);
      case 'remove_peer': return this.removePeer(client, data);
      case 'leave': return this.leave(client);
      default: return this.error(client, 'Unknown room request.');
    }
  }
  error(client, message) { client.send({ type: 'error', message }); }
  roster(room) { return [...room.members].map(id => ({ id, name: this.clients.get(id)?.name || 'Player' })); }
  name(value) { return String(value || 'Player').trim().slice(0, 18) || 'Player'; }
  code() {
    const letters = 'ABCDEFGHJKLMNPQRSTUVWXYZ';
    for (;;) {
      const code = Array.from({ length: 6 }, () => letters[randomInt(letters.length)]).join('');
      if (!this.rooms.has(code)) return code;
    }
  }
  host(client, data) {
    if (client.room) return this.error(client, 'Leave your current room first.');
    if (this.rooms.size >= 250) return this.error(client, 'Room service is busy. Try again shortly.');
    client.name = this.name(data.name); client.version = this.config(data).version;
    const admission = {config:this.config(data),public:data.public===true};
    if (!this.customAllowed(admission,data)) return this.error(client,'Custom heroes are disabled, or this public build needs Forced Balance.');
    client.custom=data.custom===true; client.balanced=data.balanced===true;
    const room = { code: this.code(), host: client.id, members: new Set([client.id]), public: data.public === true,
      started: false, config: this.config(data), requests: new Map(), created: this.now() };
    this.rooms.set(room.code, room); client.room = room.code;
    client.send({ type: 'hosted', id: client.id, code: room.code, roster: this.roster(room), config: room.config, public: room.public, resume_token: client.version >= 13 ? client.token : '' });
  }
  join(client, code, name, version = 0, choice = {}) {
    if (client.room) return this.error(client, 'Leave your current room first.');
    const room = this.rooms.get(code);
    if (!room || !this.clients.has(room.host)) return this.error(client, 'Room not found. Check the code.');
    if (room.started) return this.error(client, 'This match has already started.');
    if (!this.customAllowed(room, choice)) return this.error(client, 'Custom heroes are disabled, or this public build needs Forced Balance.');
    client.custom = choice.custom === true; client.balanced = choice.balanced === true;
    if (room.config.version >= 13 && version !== room.config.version) return this.error(client, 'Use the same current game version as the host.');
    if (!this.clients.get(room.host)?.online) return this.error(client, 'Host is reconnecting. Try shortly.');
    if (room.members.size >= this.capacity(room)) return this.error(client, 'This room is full.');
    const existing = [...room.members];
    client.name = this.name(name); client.version = version; room.members.add(client.id); client.room = code;
    client.send({ type: 'joined', id: client.id, host_id: room.host, code, roster: this.roster(room), config: room.config, public: room.public, resume_token: client.version >= 13 ? client.token : '' });
    for (const id of existing) this.clients.get(id)?.send({ type: 'peer_joined', id: client.id, name: client.name });
  }
  listRooms(client, data) {
    this.sweep();
    const version = this.config(data).version;
    const rooms = [...this.rooms.values()].filter(r => r.public && !r.started && r.members.size < this.capacity(r) && r.config.version === version && this.clients.get(r.host)?.online)
      .map(r => ({ code: r.code, host: this.clients.get(r.host)?.name || 'Player', players: this.playerCount(r), ...r.config }));
    client.send({ type: 'room_list', rooms: rooms.slice(0,250) });
  }
  requestJoin(client, data) {
    const code = String(data.code || '').trim().toUpperCase(); const room = this.rooms.get(code);
    if (!room?.started) return this.join(client, code, data.name, data.version, data);
    if (!this.customAllowed(room,data)) return this.error(client,'This custom hero cannot enter this room.');
    client.custom=data.custom===true;client.balanced=data.balanced===true;
    if (client.room) return this.error(client, 'Leave your current room first.');
    if (room.config.version !== data.version || ![14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,32].includes(data.version)) return this.error(client, 'Use the same current game version as the host.');
    if (!['defense','descent'].includes(room.config.mode)) return this.error(client, 'Late joins are available in Defence and Descent only.');
    if (room.members.size >= this.capacity(room)) return this.error(client, 'This room is full.');
    if (!this.clients.get(room.host)?.online) return this.error(client, 'Host is reconnecting. Try shortly.');
    client.name = this.name(data.name); client.version = data.version;
    room.requests.set(client.id, this.now());
    this.clients.get(room.host).send({ type: 'join_requested', id: client.id, name: client.name });
    client.send({ type: 'join_pending', code, message: 'Waiting for the host to approve. You will enter at level 1.' });
  }
  replyJoin(client, data) {
    const room = this.rooms.get(client.room); const target = this.clients.get(String(data.id || ''));
    if (!room || room.host !== client.id || !target || !room.requests.has(target.id)) return;
    const requested = room.requests.get(target.id); room.requests.delete(target.id);
    if (this.now() - requested > 30000 || !target.online || target.room) return;
    if (!data.accept || room.members.size >= this.capacity(room) || !['defense','descent'].includes(room.config.mode)) return target.send({ type: 'error', message: 'Join request declined or room full.' });
    const existing = [...room.members]; room.members.add(target.id); target.room = room.code;
    target.send({ type: 'joined', id: target.id, host_id: room.host, code: room.code, roster: this.roster(room), config: room.config, public: room.public, started: room.started, resume_token: target.token });
    for (const id of existing) this.clients.get(id)?.send({ type: 'peer_joined', id: target.id, name: target.name, late: room.started });
  }
  randomJoin(client, data) {
    if (client.room) return this.error(client, 'Leave your current room first.');
    this.sweep();
    const config = this.config(data);
    const available = [...this.rooms.values()].filter(room => room.public && !room.started && room.members.size < this.capacity(room)
      && this.clients.has(room.host) && room.config.version === config.version && [12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,32].includes(config.version) && this.clients.get(room.host)?.online
      && room.config.mode === config.mode && (config.mode !== 'coop' || room.config.realm === config.realm)
      && (config.mode !== 'arena' || room.config.rule === config.rule));
    if (!available.length) return client.send({ type: 'no_rooms', message: 'No open public room for this mode. Create one and invite others to Join Random.' });
    // Fill existing parties first; choose randomly between equally full rooms.
    const fullness = Math.max(...available.map(room => room.members.size));
    const candidates = available.filter(room => room.members.size === fullness);
    const room = candidates[Math.min(candidates.length - 1, Math.floor(this.random() * candidates.length))];
    this.join(client, room.code, data.name, data.version, data);
  }
  update(client, data) {
    const room = this.rooms.get(client.room);
    if (!room || room.host !== client.id) return this.error(client, 'Only the host can change room status.');
    if (typeof data.started === 'boolean') room.started = data.started;
    if (data.public === true && [...room.members].some(id=>this.clients.get(id)?.custom && !this.clients.get(id)?.balanced)) return this.error(client,'Switch experimental customs to checked builds before making this room public.');
    if (typeof data.public === 'boolean') room.public = data.public;
    if (!room.started && data.settings && typeof data.settings === 'object') {
      const settings = this.config({ ...room.config, ...data.settings, version: room.config.version });
      if (!settings.allow_custom && [...room.members].some(id=>this.clients.get(id)?.custom)) return this.error(client,'Choose official heroes before disabling custom builds.');
      const capacity = settings.seats - settings.bots + (settings.spectator ? 1 : 0);
      if (capacity < room.members.size) {
        client.send({ type: 'room_status', started: room.started, public: room.public, config: room.config });
        return this.error(client, 'These settings have fewer seats than your current party.');
      }
      if (room.config.version >= 28) room.config = settings;
      else for (const key of ['arena_map','opening','no_items','random_heroes']) room.config[key] = settings[key];
    }
    for (const id of room.members) this.clients.get(id)?.send({ type: 'room_status', started: room.started, public: room.public, config: room.config });
  }
  signal(client, data) {
    const room = this.rooms.get(client.room); const target = this.clients.get(String(data.to || ''));
    if (!room || !target || target.room !== client.room || target.id === client.id) return;
    if (room.host !== client.id && room.host !== target.id) return;
    if (!data.signal || typeof data.signal !== 'object') return;
    target.send({ type: 'signal', from: client.id, signal: data.signal });
  }
  leave(client) {
    const room = this.rooms.get(client.room); client.room = '';
    if (!room) return;
    room.members.delete(client.id);
    if (room.host === client.id) {
      this.rooms.delete(room.code);
      for (const id of room.members) { const member = this.clients.get(id); if (member) { member.room = ''; member.send({ type: 'room_closed' }); } }
    } else for (const id of room.members) this.clients.get(id)?.send({ type: 'peer_left', id: client.id });
  }
  removePeer(client, data) {
    const room = this.rooms.get(client.room); const target = this.clients.get(String(data.id || ''));
    if (!room || room.host !== client.id || !target || target.id === client.id || target.room !== client.room) return;
    target.send({ type: 'room_closed', reason: data.manual === true ? 'The host removed you from the room.' : 'The party continued after the reconnect window.' });
    this.leave(target);
  }
  resume(temporary, data) {
    const token = String(data.token || '');
    const previous = [...this.clients.values()].find(c => c.token === token && c.version >= 13 && !c.online && c.room);
    if (!previous || this.now() - previous.detachedAt >= 45000 || !this.rooms.has(previous.room)) return this.error(temporary, 'Resume expired. Return to the lobby and create or join a room.');
    previous.send = temporary.send; previous.online = true; previous.seen = this.now(); previous.detachedAt = 0; previous.token = randomUUID(); previous.count = 0; previous.rateAt = this.now();
    this.clients.delete(temporary.id);
    const room = this.rooms.get(previous.room);
    previous.send({ type: 'resumed', id: previous.id, host_id: room.host, code: room.code, roster: this.roster(room), config: room.config, public: room.public, started: room.started, resume_token: previous.token });
    for (const id of room.members) if (id !== previous.id) this.clients.get(id)?.send({ type: 'peer_resumed', id: previous.id });
    return previous;
  }
  disconnect(client) {
    this.eduLeave(client); this.assessmentLeave(client); this.partnerLeave(client); this.classLeave(client);
    if (!this.clients.has(client.id) || !client.online) return;
    if (client.version >= 13 && client.room) {
      client.online = false; client.detachedAt = this.now();
      const room = this.rooms.get(client.room);
      for (const id of room?.members || []) if (id !== client.id) this.clients.get(id)?.send({ type: 'peer_reconnecting', id: client.id, seconds: 45 });
    } else { this.eduLeave(client); this.assessmentLeave(client); this.partnerLeave(client); this.classLeave(client); this.leave(client); this.clients.delete(client.id); }
  }
  sweep() {
    for (const room of [...this.education.values()]) {
      if(this.now()-room.created>=7200000){this.eduClose(room);continue;}
      for(const [id,u] of room.uploads)if(this.now()-u.created>90000){room.uploads.delete(id);this.clients.get(id)?.send({type:'error',message:'Upload timed out. Send latest progress to retry.'});}
      if(room.feedback && this.now()-room.feedback.created>90000){room.feedback=null;this.clients.get(room.host)?.send({type:'error',message:'Feedback timed out. Save ratings again to retry.'});}
    }
    for (const room of [...this.assessments.values()]) if (this.now()-room.created>=1800000) this.assessmentClose(room);
    for (const room of this.rooms.values()) for (const [id, time] of room.requests) if (this.now() - time > 30000) { room.requests.delete(id); this.clients.get(id)?.send({type:"error", message:"Join request expired. Try again."}); }
    for (const client of [...this.clients.values()]) {
      if (!client.online && this.now() - client.detachedAt >= 45000) { this.eduLeave(client); this.assessmentLeave(client); this.partnerLeave(client); this.classLeave(client); this.leave(client); this.clients.delete(client.id); }
      else if (client.online && this.now() - client.seen > 45000) { this.eduLeave(client); this.assessmentLeave(client); this.partnerLeave(client); this.classLeave(client); this.leave(client); this.clients.delete(client.id); }
    }
  }
  eduClose(r) { for(const id of [r.host,...r.students]){const c=this.clients.get(id);if(c){c.edu='';c.send({type:'edu_closed'});}}this.education.delete(r.code); }
  eduLeave(c) {const r=this.education.get(c.edu);c.edu='';if(!r)return;if(c.id===r.host)return this.eduClose(r);r.students.delete(c.id);r.uploads.delete(c.id);this.eduStatus(r);}
  eduStatus(r) {this.clients.get(r.host)?.send({type:'edu_status',count:r.students.size});}
  eduMessage(c,d) {
    this.sweep();
    if(d.type==='edu_host') {
      if(c.edu || d.teacher!==true || d.version!==1 || this.education.size>=10)return this.error(c,'Leave your room first, or try again shortly.');
      let code;do{code='ED'+this.code();}while(this.education.has(code));
      const r={code,host:c.id,students:new Set(),uploads:new Map(),feedback:null,created:this.now()};this.education.set(code,r);c.edu=code;c.send({type:'edu_joined',code});return this.eduStatus(r);
    }
    if(d.type==='edu_join') {
      const r=this.education.get(String(d.code||'').toUpperCase());if(c.edu || !r || d.version!==1 || r.students.size>=31)return this.error(c,'Submission room unavailable or full.');
      r.students.add(c.id);c.edu=r.code;c.send({type:'edu_joined',code:r.code});return this.eduStatus(r);
    }
    if(d.type==='edu_leave')return this.eduLeave(c);
    const r=this.education.get(c.edu);if(!r)return this.error(c,'Join a submission room first.');
    if(d.type==='edu_ack' && c.id===r.host && r.students.has(d.peer))return this.clients.get(d.peer)?.send({type:'edu_stored'});
    const feedback=d.type.startsWith('edu_feedback_');
    if(d.type==='edu_begin' || d.type==='edu_feedback_begin') {
      if(feedback ? c.id!==r.host || !r.students.has(d.peer) || r.feedback : !r.students.has(c.id) || r.uploads.has(c.id))return this.error(c,'Transfer unavailable.');
      if(!feedback && r.uploads.size>=4)return c.send({type:'edu_wait'});
      if(!Number.isInteger(d.length)||d.length<1||d.length>4194304||! /^[a-f0-9]{64}$/.test(d.token||'')||!feedback&&! /^[a-f0-9]{32}$/.test(d.student_id||''))return this.error(c,'Invalid transfer header.');
      const u={length:d.length,token:d.token,student_id:d.student_id||'',peer:feedback?d.peer:c.id,parts:[],size:0,index:0,created:this.now()};if(feedback)r.feedback=u;else r.uploads.set(c.id,u);return c.send({type:'edu_upload'});
    }
    if(d.type==='edu_chunk' || d.type==='edu_feedback_chunk') {
      const u=feedback?r.feedback:r.uploads.get(c.id);if(!u || feedback&&c.id!==r.host)return;
      const drop=()=>{if(feedback)r.feedback=null;else r.uploads.delete(c.id);};
      if(d.index!==u.index || typeof d.text!=='string' || d.text.length>10000 || /[^\x00-\x7f]/.test(d.text) || u.size+d.text.length>u.length){drop();return this.error(c,'Invalid transfer chunk.');}
      u.parts.push(d.text);u.size+=d.text.length;u.index++;if(u.size<u.length)return;
      const text=u.parts.join('');drop();let v;try{v=JSON.parse(text);}catch{return this.error(c,'Invalid portfolio JSON.');}
      if(createHash('sha256').update(text).digest('hex')!==u.token || v?.format!=='fx-crossroads-learning' || v.version!==1)return this.error(c,'Portfolio integrity failed.');
      const target=this.clients.get(feedback?u.peer:r.host);if(!target)return;
      target.send({type:'edu_transfer',peer:feedback?c.id:u.peer,length:u.length,token:u.token,student_id:u.student_id,direction:feedback?'feedback':'work'});
      u.parts.forEach((text,index)=>target.send({type:'edu_data',peer:feedback?c.id:u.peer,index,text}));return;
    }
  }
  partnerStatus(room) {
    const packet={type:'partner_status',code:room.code,writer:room.writer,live:!!room.live,revision:room.revision,roster:[...room.members].map(id=>({id,name:this.clients.get(id)?.name || 'Student'}))};
    for(const id of room.members)this.clients.get(id)?.send(packet);
  }
  partnerLeave(client) {
    const room=this.partners.get(client.partnerCode);client.partnerCode='';if(!room)return;
    room.members.delete(client.id);room.upload=null;
    if(!room.members.size){this.partners.delete(room.code);return;}
    if(room.writer===client.id)room.writer=[...room.members][0];this.partnerStatus(room);
  }
  partnerMessage(client,data) {
    if(data.type==='partner_leave'){this.partnerLeave(client);return;}
    if(data.type==='partner_host' || data.type==='partner_join'){
      if(client.partnerCode || client.room || client.classCode)return this.error(client,'Leave your current session first.');
      if(![30,31].includes(data.version))return this.error(client,'Update Crossroads: Realms Beyond before partnering.');
      let room;
      if(data.type==='partner_host'){
        if(this.partners.size>=100)return this.error(client,'Studio service is busy.');
        let code;do{code='SP'+this.code();}while(this.partners.has(code));
        room={code,members:new Set(),writer:client.id,live:data.version===31,revision:0,upload:null,cached:[],envelope:null};this.partners.set(code,room);
      }else{room=this.partners.get(String(data.code||'').trim().toUpperCase());if(!room || room.members.size>=2)return this.error(client,'Partner session not found or already full.');}
      if(room.live !== (data.version===31))return this.error(client,'Both partners must use the same Studio update.');
      client.name=this.name(data.name);client.partnerCode=room.code;room.members.add(client.id);client.send({type:'partner_identity',id:client.id});this.partnerStatus(room);
      for(const packet of room.cached)client.send(packet);return;
    }
    const room=this.partners.get(client.partnerCode);if(!room || !room.members.has(client.id))return this.error(client,'Join a Studio session first.');
    if(room.live && data.type==='partner_cursor'){
      if(!safeStudioPath(data.path)||!Number.isInteger(data.x)||!Number.isInteger(data.y)||data.x<0||data.y<0||data.x>255||data.y>255)return;
      for(const id of room.members)if(id!==client.id)this.clients.get(id)?.send({type:'partner_cursor',path:data.path,x:data.x,y:data.y});return;
    }
    if(room.live && data.type==='partner_delta_chunk'){
      room.deltas ??= new Map();const {index,count,text}=data;
      if(!Number.isInteger(index)||!Number.isInteger(count)||index<0||count<1||count>96||index>=count||typeof text!=='string'||text.length>24000)return this.error(client,'Invalid edit transfer.');
      if(index===0)room.deltas.set(client.id,{parts:[],count,at:this.now()});
      const upload=room.deltas.get(client.id);
      if(!upload||upload.count!==count||upload.parts.length!==index||this.now()-upload.at>15000){room.deltas.delete(client.id);return this.error(client,'Live edit interrupted.');}
      upload.parts.push(text);if(index+1<count)return;
      room.deltas.delete(client.id);let patch;try{const raw=upload.parts.join('');if(Buffer.byteLength(raw)>2200000)throw Error();patch=JSON.parse(raw);}catch{return this.error(client,'Invalid live edit.');}
      if(patch?.type!=='partner_patch')return this.error(client,'Invalid edit type.');return this.partnerEdit(client,room,patch);
    }
    if(room.live && ['partner_patch','partner_pixels'].includes(data.type))return this.partnerEdit(client,room,data);
    if(data.type==='partner_request'){this.clients.get(room.writer)?.send({type:'partner_requested',name:client.name});return;}
    if(data.type==='partner_pass'){
      if(room.writer!==client.id || room.upload)return this.error(client,'Finish sharing this draft before passing control.');
      const other=[...room.members].find(id=>id!==client.id);if(other){room.writer=other;this.partnerStatus(room);}return;
    }
    if(data.type!=='partner_chunk' || room.writer!==client.id)return this.error(client,'Only the student holding the pencil can edit.');
    const {index,count,revision,text}=data;
    if(!Number.isInteger(index)||!Number.isInteger(count)||count<1||count>96||index<0||index>=count||typeof text!=='string'||text.length>32768||(!room.live && revision!==room.revision))return this.error(client,'Invalid or stale Studio draft.');
    if(index===0)room.upload={parts:[],count,at:this.now()};
    const upload=room.upload;
    if(!upload || upload.count!==count || upload.parts.length!==index || this.now()-upload.at>15000){room.upload=null;return this.error(client,'Studio transfer interrupted. Try sharing again.');}
    upload.parts.push(text);if(index+1<count)return;
    room.upload=null;const raw=upload.parts.join('');let envelope;
    try{envelope=JSON.parse(raw);}catch{return this.error(client,'Invalid Studio JSON.');}
    if(Buffer.byteLength(raw)>2200000 || !['hero','ability','enemy','behavior'].includes(envelope.kind)||!envelope.value||typeof envelope.value!=='object'||Array.isArray(envelope.value))return this.error(client,'Unsupported Studio file.');
    room.envelope=envelope;room.revision++;room.cached=upload.parts.map((text,index)=>({type:'partner_chunk',index,count,revision:room.revision,text}));
    for(const id of room.members)if(id!==client.id)for(const packet of room.cached)this.clients.get(id)?.send(packet);
    client.send({type:'partner_saved',revision:room.revision});this.partnerStatus(room);
  }
  partnerEdit(client,room,data) {
    if(!room.envelope || data.kind!==room.envelope.kind)return this.error(client,'Wait for the main project to load.');
    let ops;
    try {
      if(data.type==='partner_pixels') {
        const path=data.path;
        if(!safeStudioPath(path) || !path.some(k=>['art','animation','charge_animation','minion_image'].includes(k)))throw Error();
        const existing=studioGet(room.envelope,path);
        const png=decodeStudioPNG(existing,Number(data.width),Number(data.height));
        if(!Array.isArray(data.runs)||data.runs.length>4096)throw Error();
        let count=0;
        for(const run of data.runs){
          if(!Array.isArray(run)||run.length!==3||!Number.isInteger(run[0])||!Number.isInteger(run[1])||run[0]<0||run[1]<1||run[0]+run[1]>png.w*png.h||typeof run[2]!=='string'||!/^#[0-9a-f]{8}$/i.test(run[2]))throw Error();
          count+=run[1];if(count>65536)throw Error();
          const rgba=Buffer.from(run[2].slice(1),'hex');for(let n=run[0];n<run[0]+run[1];n++)rgba.copy(png.raw,n*4);
        }
        ops=[{path,value:encodeStudioPNG(png)}];
      }else{
        if(!Array.isArray(data.ops)||data.ops.length<1||data.ops.length>128||Buffer.byteLength(JSON.stringify(data.ops))>2200000)throw Error();
        ops=data.ops;
      }
      const next=structuredClone(room.envelope);
      for(const op of ops){if(!safeStudioPath(op.path))throw Error();studioSet(next,op.path,op.value,op.erase===true);}
      const raw=JSON.stringify(next);if(Buffer.byteLength(raw)>2200000)throw Error();
      room.envelope=next;room.revision++;
      const count=Math.ceil(raw.length/24000);room.cached=Array.from({length:count},(_,index)=>({type:'partner_chunk',index,count,revision:room.revision,text:raw.slice(index*24000,(index+1)*24000)}));
      const packet={type:'partner_edit',kind:data.kind,ops,sender:client.id,revision:room.revision};
      const encoded=JSON.stringify(packet);
      for(const id of room.members){
        if(Buffer.byteLength(encoded)<=100000)this.clients.get(id)?.send(packet);
        else {const count=Math.ceil(encoded.length/24000);for(let index=0;index<count;index++)this.clients.get(id)?.send({type:'partner_edit_chunk',index,count,text:encoded.slice(index*24000,(index+1)*24000)});}
      }
    }catch{return this.error(client,'Invalid or oversized live edit. Your local draft is retained.');}
  }
  classStatus(room) {
    const roster=[...room.students].map(id=>({id,name:this.clients.get(id)?.name || 'Viewer'}));
    const packet={type:'class_status',code:room.code,host:room.host,roster,started:room.started};
    for(const id of [room.host,...room.students]) this.clients.get(id)?.send(packet);
  }
  classLeave(client) {
    const room=this.classes.get(client.classCode);if(!room){client.classCode='';return;}
    if(room.host===client.id){
      for(const id of room.students){const c=this.clients.get(id);if(c){c.classCode='';c.send({type:'class_closed',message:'The presenter ended the broadcast.'});}}
      this.classes.delete(room.code);
    } else {room.students.delete(client.id);this.classStatus(room);}
    client.classCode='';
  }
  classMessage(client,data) {
    if(data.type==='class_leave'){this.partnerLeave(client); this.classLeave(client);return;}
    if(data.type==='class_host'){
      if(data.version!==30 || data.dev!==true)return this.error(client,'Game Dev mode and the current game version are required.');
      if(client.room || client.classCode)return this.error(client,'Leave your current room first.');
      if(this.classes.size>=20)return this.error(client,'Broadcast service is busy.');
      let code;do{code='CL'+this.code();}while(this.classes.has(code));
      client.name=this.name(data.name);client.classCode=code;
      const room={code,host:client.id,students:new Set(),started:false,frameAt:-1000,frame:null};this.classes.set(code,room);
      client.send({type:'class_joined',id:client.id,host:true,code});this.classStatus(room);return;
    }
    if(data.type==='class_join'){
      if(client.room || client.classCode)return this.error(client,'Leave your current room first.');
      const code=String(data.code||'').trim().toUpperCase(),room=this.classes.get(code);
      if(data.version!==30 || !room)return this.error(client,'Broadcast not found. Check the code and game version.');
      if(room.students.size>=31)return this.error(client,'All 31 viewer seats are full.');
      client.name=this.name(data.name);client.classCode=code;room.students.add(client.id);
      client.send({type:'class_joined',id:client.id,host:false,code});this.classStatus(room);
      if(room.started){client.send({type:'class_start'});if(room.frame)client.send(room.frame);}return;
    }
    const room=this.classes.get(client.classCode);if(!room)return this.error(client,'Join a broadcast first.');
    if(client.id!==room.host)return this.error(client,'Only the presenter can control the broadcast.');
    if(data.type==='class_start'){
      room.started=true;for(const id of room.students)this.clients.get(id)?.send({type:'class_start'});this.classStatus(room);return;
    }
    if(data.type==='class_frame'){
      if(!room.started || this.now()-room.frameAt<450)return;
      if(typeof data.image!=='string' || data.image.length>110000 || !/^[A-Za-z0-9+/=]+$/.test(data.image))return;
      const bytes=Buffer.from(data.image,'base64');
      if(bytes.length<4 || bytes[0]!==255 || bytes[1]!==216 || bytes.at(-2)!==255 || bytes.at(-1)!==217)return;
      let offset=2,validSize=false;
      while(offset+4<bytes.length){
        if(bytes[offset]!==255)break;const marker=bytes[offset+1];offset+=2;
        if(marker===216 || marker===217)continue;const length=bytes.readUInt16BE(offset);
        if(length<2 || offset+length>bytes.length)break;
        if([192,193,194].includes(marker) && length>=8){const height=bytes.readUInt16BE(offset+3),width=bytes.readUInt16BE(offset+5);validSize=width>0 && height>0 && width<=1024 && height<=576;break;}
        offset+=length;
      }
      if(!validSize)return;
      const frame={type:'class_frame',image:data.image,seq:Math.trunc(Number(data.seq)||0)};room.frameAt=this.now();room.frame=frame;
      for(const id of room.students)this.clients.get(id)?.send(frame);return;
    }
    this.error(client,'Unknown classroom request.');
  }

  assessmentClose(room) {
    this.assessments.delete(room.code);
    for(const id of [room.host,room.viewer,room.request]) {
      const c=this.clients.get(id);if(c){c.assessment='';c.send({type:'assessment_closed'});}
    }
    room.work='';room.parts=[];room.feedback=null;
  }
  assessmentLeave(client) {
    const room=this.assessments.get(client.assessment);client.assessment='';if(!room)return;
    if(room.host===client.id)this.assessmentClose(room);
    else {if(room.viewer===client.id)room.viewer='';if(room.request===client.id)room.request='';room.feedback=null;this.clients.get(room.host)?.send({type:'assessment_reviewer_left'});}
  }
  assessmentSend(id,text,direction) {
    const c=this.clients.get(id);if(!c?.online)return;
    c.send({type:'assessment_transfer',length:text.length,token:createHash('sha256').update(text).digest('hex'),direction});
    for(let n=0;n<text.length;n+=10000)c.send({type:'assessment_data',index:n/10000,text:text.slice(n,n+10000)});
  }
  assessmentMessage(client,data) {
    const type=data.type;let room=this.assessments.get(client.assessment);
    const validHeader=()=>Number.isInteger(data.length)&&data.length>0&&data.length<=4194304&&typeof data.token==='string'&&/^[a-f0-9]{64}$/.test(data.token);
    if(type==='assessment_leave')return this.assessmentLeave(client);
    if(type==='assessment_host') {
      this.sweep();if(client.assessment)return this.error(client,'Stop the current review first.');
      if(data.version!==1||!validHeader())return this.error(client,'Invalid review header.');
      if(this.assessments.size>=8)return this.error(client,'Review service busy; review locally or use a downloaded portfolio.');
      let code;do{code='RV'+randomInt(0,36**6).toString(36).toUpperCase().padStart(6,'0');}while(this.assessments.has(code));
      room={code,host:client.id,viewer:'',request:'',created:this.now(),length:data.length,token:data.token,parts:[],index:0,work:'',feedback:null};
      this.assessments.set(code,room);client.assessment=code;client.send({type:'assessment_created',code});return;
    }
    if(type==='assessment_join') {
      if(client.assessment)return this.error(client,'Stop the current review first.');
      room=this.assessments.get(String(data.code||'').toUpperCase());
      if(data.version!==1||!room?.work||room.viewer||room.request)return this.error(client,'Review not ready, expired, or already occupied.');
      if(room.host===client.id)return this.error(client,'The student cannot join their own review.');
      client.assessment=room.code;room.request=client.id;client.send({type:'assessment_waiting'});
      this.clients.get(room.host)?.send({type:'assessment_requested',id:client.id,name:this.name(data.name)});return;
    }
    if(!room)return this.error(client,'Create or join a private review first.');
    if(type==='assessment_reject') {
      if(room.host!==client.id||!room.request)return this.error(client,'Only the student declines a pending reviewer.');
      const reviewer=this.clients.get(room.request);if(reviewer){reviewer.assessment='';reviewer.send({type:'assessment_closed'});}
      room.request='';client.send({type:'assessment_reviewer_left'});return;
    }
    if(type==='assessment_approve') {
      if(room.host!==client.id||room.request!==data.id)return this.error(client,'Only the student approves the pending reviewer.');
      room.viewer=room.request;room.request='';this.assessmentSend(room.viewer,room.work,'work');return;
    }
    if(type==='assessment_feedback_begin') {
      if(room.viewer!==client.id||!validHeader())return this.error(client,'Only the approved reviewer can send feedback.');
      room.feedback={length:data.length,token:data.token,parts:[],index:0};return;
    }
    if(type!=='assessment_chunk'&&type!=='assessment_feedback_chunk')return this.error(client,'Unknown review message.');
    const feedback=type==='assessment_feedback_chunk';
    if(feedback?room.viewer!==client.id||!room.feedback:room.host!==client.id||room.work)return this.error(client,'Review transfer not permitted.');
    const q=feedback?room.feedback:room;
    if(!Number.isInteger(data.index)||data.index!==q.index||typeof data.text!=='string'||data.text.length>10000||data.index*10000+data.text.length>q.length)return this.error(client,'Invalid review chunk.');
    q.parts.push(data.text);q.index++;
    q.bytes=(q.bytes||0)+Buffer.byteLength(data.text);
    if(q.bytes>4194304){if(feedback)room.feedback=null;else this.assessmentClose(room);return this.error(client,'Review exceeds byte limit.');}
    if(q.index*10000<q.length)return;
    const text=q.parts.join('');q.parts=[];
    if(text.length!==q.length||Buffer.byteLength(text)>4194304||createHash('sha256').update(text).digest('hex')!==q.token){if(feedback)room.feedback=null;else this.assessmentClose(room);return this.error(client,'Review failed integrity checks.');}
    let value;try{value=JSON.parse(text);}catch{return this.error(client,'Invalid review JSON.');}
    if(value?.format!=='fx-crossroads-learning'||value?.version!==1||!Array.isArray(value.submissions)||value.submissions.length>96){if(feedback)room.feedback=null;else this.assessmentClose(room);return this.error(client,'Not a learning portfolio.');}
    if(feedback){room.feedback=null;this.assessmentSend(room.host,text,'feedback');}
    else {room.work=text;client.send({type:'assessment_ready',code:room.code});}
  }

}

// Bounded PNG codec for Godot's normalized RGBA8 pixel canvases.
function safeStudioPath(path){return Array.isArray(path)&&path.length>=2&&path.length<=12&&path[0]==='value'&&path.every(k=>(typeof k==='string'&&k.length<=100&&!['__proto__','constructor','prototype'].includes(k))||(Number.isInteger(k)&&k>=0&&k<128));}
function studioGet(root,path){for(const key of path)root=root?.[key];return root;}
function studioSet(root,path,value,erase){const parent=studioGet(root,path.slice(0,-1));if(!parent||typeof parent!=='object')throw Error();const key=path.at(-1);if(Array.isArray(parent)&&(!Number.isInteger(key)||key>parent.length))throw Error();if(erase){if(Array.isArray(parent))parent.splice(key,1);else delete parent[key];}else parent[key]=value;}
export function decodeStudioPNG(encoded,w,h){
 if(!Number.isInteger(w)||!Number.isInteger(h)||w<1||h<1||w>256||h>256)throw Error();
 if(!encoded)return {w,h,raw:Buffer.alloc(w*h*4)};
 if(typeof encoded!=='string'||encoded.length>180000)throw Error();
 const b=Buffer.from(encoded,'base64');if(!b.subarray(0,8).equals(Buffer.from([137,80,78,71,13,10,26,10])))throw Error();
 let offset=8,blocks=[];
 while(offset+12<=b.length){const size=b.readUInt32BE(offset);if(offset+size+12>b.length)throw Error();const type=b.toString('ascii',offset+4,offset+8);const bytes=b.subarray(offset+8,offset+8+size);
 if(type==='IHDR'){if(size!==13||bytes.readUInt32BE(0)!==w||bytes.readUInt32BE(4)!==h||bytes[8]!==8||bytes[9]!==6||bytes[12]!==0)throw Error();}
 if(type==='IDAT')blocks.push(bytes);offset+=size+12;if(type==='IEND')break;}
 const stride=w*4,scan=inflateSync(Buffer.concat(blocks),{maxOutputLength:(stride+1)*h});if(scan.length!==(stride+1)*h)throw Error();
 const raw=Buffer.alloc(stride*h);for(let y=0;y<h;y++){const filter=scan[y*(stride+1)];if(filter>4)throw Error();for(let x=0;x<stride;x++){const left=x>=4?raw[y*stride+x-4]:0,up=y?raw[(y-1)*stride+x]:0,corner=y&&x>=4?raw[(y-1)*stride+x-4]:0;let predictor=0;
 if(filter===1)predictor=left;else if(filter===2)predictor=up;else if(filter===3)predictor=Math.floor((left+up)/2);else if(filter===4){const p=left+up-corner,a=Math.abs(p-left),b=Math.abs(p-up),c=Math.abs(p-corner);predictor=a<=b&&a<=c?left:b<=c?up:corner;}
 raw[y*stride+x]=(scan[y*(stride+1)+1+x]+predictor)&255;}}
 return {w,h,raw};
}
function crc32(bytes){let crc=0xffffffff;for(const byte of bytes){crc^=byte;for(let k=0;k<8;k++)crc=(crc>>>1)^((crc&1)?0xedb88320:0);}return (crc^0xffffffff)>>>0;}
export function encodeStudioPNG({w,h,raw}){const chunk=(name,data)=>{const type=Buffer.from(name);const b=Buffer.alloc(data.length+12);b.writeUInt32BE(data.length);type.copy(b,4);data.copy(b,8);b.writeUInt32BE(crc32(Buffer.concat([type,data])),data.length+8);return b;};const header=Buffer.alloc(13);header.writeUInt32BE(w);header.writeUInt32BE(h,4);header[8]=8;header[9]=6;const scan=Buffer.alloc((w*4+1)*h);for(let y=0;y<h;y++)raw.copy(scan,y*(w*4+1)+1,y*w*4,(y+1)*w*4);return Buffer.concat([Buffer.from([137,80,78,71,13,10,26,10]),chunk('IHDR',header),chunk('IDAT',deflateSync(scan)),chunk('IEND',Buffer.alloc(0))]).toString('base64');
}

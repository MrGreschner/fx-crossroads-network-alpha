import test from 'node:test';
import assert from 'node:assert/strict';
import { Rooms } from './rooms.mjs';
function harness() {
  let now = 1000; const rooms = new Rooms({ now: () => now, random: () => 0 });
  const client = () => { const messages = []; const connection = rooms.connect(packet => messages.push(packet)); return { connection, messages, last: () => messages.at(-1) }; };
  const send = (user, data) => rooms.message(user.connection, data);
  return { rooms, client, send, advance: ms => { now += ms; } };
}
const config = { mode: 'defense', version: 12, name: 'Player' };
test('private codes still work but random search cannot see them', () => {
  const h = harness(), host = h.client(), guest = h.client();
  h.send(host, { ...config, type: 'host' }); const code = host.last().code;
  h.send(guest, { ...config, type: 'join_random' }); assert.equal(guest.last().type, 'no_rooms');
  h.send(guest, { type: 'join', code }); assert.equal(guest.last().type, 'joined');
});
test('public rooms match mode/realm/rule/protocol and fill to four atomically', () => {
  const h = harness(), host = h.client(); h.send(host, { ...config, type: 'host', public: true });
  for (let i = 0; i < 3; i++) { const guest = h.client(); h.send(guest, { ...config, type: 'join_random' }); assert.equal(guest.last().type, 'joined'); }
  const extra = h.client(); h.send(extra, { ...config, type: 'join_random' }); assert.equal(extra.last().type, 'no_rooms');
  const other = h.client(); h.send(other, { ...config, mode: 'arena', type: 'join_random' }); assert.equal(other.last().type, 'no_rooms');
});
test('started and stale rooms disappear; only hosts change status', () => {
  const h = harness(), host = h.client(), guest = h.client(), searcher = h.client();
  h.send(host, { ...config, public: true, type: 'host' });
  h.send(guest, { ...config, type: 'join_random' });
  h.send(guest, { type: 'room_update', started: true }); assert.equal(guest.last().type, 'error');
  h.send(host, { type: 'room_update', started: true });
  h.send(searcher, { ...config, type: 'join_random' }); assert.equal(searcher.last().type, 'no_rooms');
  h.send(host, { type: 'room_update', started: false });
  h.send(searcher, { ...config, type: 'join_random' }); assert.equal(searcher.last().type, 'joined');
  h.advance(46000); h.rooms.sweep(); assert.equal(h.rooms.rooms.size, 0); assert.equal(h.rooms.clients.size, 0);
});
test('co-op realms and arena rules are isolated; legacy builds not randomly matched', () => {
  const h = harness(), host = h.client(), searcher = h.client();
  h.send(host, { ...config, type: 'host', public: true, mode: 'coop', realm: 'shattered_oath' });
  h.send(searcher, { ...config, type: 'join_random', mode: 'coop', realm: 'grove' }); assert.equal(searcher.last().type, 'no_rooms');
  h.send(searcher, { ...config, type: 'join_random', mode: 'coop', realm: 'shattered_oath' }); assert.equal(searcher.last().type, 'joined');
  const arena = h.client(), seeker = h.client(); h.send(arena, { ...config, type: 'host', public: true, mode: 'arena', rule: 'teams' });
  h.send(seeker, { ...config, type: 'join_random', mode: 'arena', rule: 'ffa' }); assert.equal(seeker.last().type, 'no_rooms');
  h.send(seeker, { ...config, type: 'join_random', mode: 'arena', rule: 'teams', version: 0 }); assert.equal(seeker.last().type, 'no_rooms');
});
test('disconnect cleans the roster and signals stay within the host party', () => {
  const h = harness(), host = h.client(), guest = h.client(), stranger = h.client();
  h.send(host, { ...config, type: 'host', public: true }); h.send(guest, { ...config, type: 'join_random' });
  const count = stranger.messages.length;
  h.send(host, { type: 'signal', to: stranger.connection.id, signal: { kind: 'ice' } }); assert.equal(stranger.messages.length, count);
  h.send(guest, { type: 'signal', to: host.connection.id, signal: { kind: 'ice' } }); assert.equal(host.last().type, 'signal');
  h.rooms.disconnect(guest.connection); assert.equal(host.last().type, 'peer_left');
  h.rooms.disconnect(host.connection); assert.equal(h.rooms.rooms.size, 0);
});

import http from 'node:http';
import WebSocket, { WebSocketServer } from 'ws';
import { Rooms } from './rooms.mjs';
import { releaseInfo, outdatedGame } from './release.mjs';

import { Analytics } from './analytics.mjs';
let analytics;
try { analytics = new Analytics({file:process.env.ANALYTICS_DB_FILE,key:process.env.ANALYTICS_ADMIN_KEY,hashKey:process.env.ANALYTICS_HASH_KEY,timezone:process.env.ANALYTICS_TIMEZONE||'America/Edmonton'}); } catch { console.error('Analytics configuration unavailable; multiplayer remains active.'); analytics=new Analytics(); }
const rooms = new Rooms();
const publishedRelease = releaseInfo();
const server = http.createServer(async (request, response) => {
  try { if (await analytics.handle(request,response)) return; } catch { response.writeHead(503);response.end(JSON.stringify({error:"Activity service unavailable."}));return; }
  if (request.url?.split('?')[0] === '/release') {
    response.writeHead(200, { 'Content-Type': 'application/json', 'Cache-Control': 'no-store', 'Access-Control-Allow-Origin': '*' });
    response.end(JSON.stringify(publishedRelease));
    return;
  }
  response.writeHead(200, { 'Content-Type': 'application/json', 'Cache-Control': 'no-store' });
  response.end(JSON.stringify({ service: 'FX Crossroads rooms', version: 30, publicRooms: true }));
});
const wss = new WebSocketServer({ server, maxPayload: 128 * 1024, perMessageDeflate: false });
wss.on('connection', ws => {
  const send = packet => { if (ws.readyState === WebSocket.OPEN && (packet.type !== 'class_frame' || ws.bufferedAmount < 128 * 1024)) ws.send(JSON.stringify(packet)); };
  let client = rooms.connect(send);
  ws.alive = true;
  ws.on('pong', () => { ws.alive = true; client.seen = Date.now(); });
  ws.on('message', (bytes, binary) => {
    if (binary) return;
    try {
      const packet = JSON.parse(bytes.toString());
      if (outdatedGame(packet, publishedRelease)) {
        send({ type: 'error', message: `Update to v${publishedRelease.game_build} before joining multiplayer. Save/download your player profile first, then get the latest game at fxcts.itch.io/fx-crossroads.` });
        return;
      }
      const result = rooms.message(client, packet); if (result?.id && rooms.clients.get(result.id) === result) client = result; }
    catch { if (ws.readyState === WebSocket.OPEN) ws.send(JSON.stringify({ type: 'error', message: 'Invalid room message.' })); }
  });
  ws.on('close', () => { if (client.send === send) rooms.disconnect(client); });
  ws.on('error', () => { if (client.send === send) rooms.disconnect(client); });
});
const timer = setInterval(() => {
  rooms.sweep();
  for (const ws of wss.clients) {
    if (!ws.alive) { ws.terminate(); continue; }
    ws.alive = false; ws.ping();
  }
}, 15000);
wss.on('close', () => clearInterval(timer));
server.listen(Number(process.env.PORT || 3000), '0.0.0.0', () => console.log('FX Crossroads room service v30 ready'));
for (const signal of ['SIGTERM', 'SIGINT']) process.on(signal, () => {
  clearInterval(timer);
  for (const ws of wss.clients) ws.close(1001, 'Room service restarting');
  wss.close(); server.close();
});

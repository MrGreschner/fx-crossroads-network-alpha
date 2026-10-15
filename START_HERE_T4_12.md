# T4.12 — server correction and client launch feedback

Both uploads are needed this time.

1. Extract FX_Crossroads_Network_Alpha_T4_12_Server_Update.zip.
2. In the GitHub website, on Render's tracked branch, OPEN the existing network folder. Add file > Upload files: upload server.gd from the extracted network folder. Commit.
3. OPEN the existing network_service folder. Add file > Upload files: upload gateway.mjs from the extracted network_service folder. Commit.
4. In Render choose Manual Deploy > Deploy latest commit. Wait for success. The /health page must report ready:true, build:T4.12, protocol:3.
5. Upload FX_Crossroads_Network_Alpha_T4_12_Web.zip to itch.io as the HTML game. Reload every device. Check the footer says T4.12 and server T4.12.

The server patch assumes the previous T4.9.1 bee-hit correction is installed. It changes exactly two runtime files. Upload into the existing folders; top-level copies do not replace the files the server runs. Do not upload the source ZIP as the itch game or server patch.

The goaltender wall previously never aged in the dedicated authority: the normal game's wall timer was in a loop the authority bypasses. The new authority expires it on the physics clock, honors paused rooms, and sends removal in snapshots. Its existing four-second solid-wall behavior is retained. Tests reproduce trapping at the impact point and verify movement and outgoing attack paths recover once it expires.

Soccer already used the generic stationary release cue. T4.12 enlarges that cue, draws a ball/foot streak for soccer and extends the cue from 80 to 140 ms. This gives clearer immediate feedback. Travelling projectiles remain server-confirmed on the shared world clock, and no speculative projectile damage is added.

F8 adds launch_received_ms (request to first authoritative shot packet), launch_drawn_ms (request to first visible playback), last_launch timestamps, action_ack_wait_ms and wall lifetime/count. These measure delays after the request is sent, not browser input latency or time waiting for cooldown before a request. Send reports from both devices if soccer still feels delayed; state whether it was the first click or repeated fire.

This release does not claim a complete fix for every reported one-second projectile delay: the browser test did not reproduce a full second. It addresses cue readability and makes the remaining timing measurable. Keep Balanced graphics for comparison. Physical Chromebook and phone validation is still required.

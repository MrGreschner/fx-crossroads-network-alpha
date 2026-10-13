# v161 — Private activity dashboard

Automatic anonymous activity reports cover web and downloadable play, including solo sessions. A small request starts after about five seconds and repeats about once a minute. Requests have an eight-second timeout, no retry backlog, and never block gameplay. Options includes a device-level anonymous activity toggle. Local crash reports still stay local; best-effort graphics-context-loss counts are sent separately when activity sharing is enabled.

Game Dev's testing desk (`backtick`) now has **Activity dashboard • private trends**. It requires Game Dev mode and a separate private server key entered into a masked field. The key is never written to profiles, exports, project files, or browser storage. Leaving Game Dev closes the dashboard and discards the field. Student, Teacher, Media and Playtest modes do not grant access.

The dashboard has 7/30/90-day ranges, daily engaged-profile/device/session bars, estimated active hours, recent device activity, popular official heroes and realms, activity categories, and best-effort multiplayer recovery / graphics-loss incident totals. Refresh retrieves data on demand; no emails or report downloads are required.

Server storage hashes random installation/profile/session identifiers with a private HMAC key. It rejects names, student work and unexpected payload fields. Reports are size/rate bounded and duplicate event IDs are ignored. Records expire after 90 days. Game Dev sessions are excluded from collection. Configuration/storage failure disables analytics while keeping rooms available.

These are estimates: shared computers, profile copies, clears, offline clients, opt-outs and blocked requests affect counts. They are not exact student headcounts, validated competition results, grades or complete crash detection. Active minutes stop after two minutes without input or when the app loses focus. Daily sessions can appear on more than one date; activity categories reflect the sampled state. Custom heroes are grouped as Custom, without their names/artwork. No profile contents, assignments, IP addresses, browser fingerprints or student names are stored in the activity database. Hosting providers may still maintain their own standard access logs.

The underlying hero attacks, progression and multiplayer rules are unchanged. Read DEPLOY_V161.md before publishing: durable analytics needs server configuration and a persistent disk.

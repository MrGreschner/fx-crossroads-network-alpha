export const DEFAULT_GAME_BUILD = 165;
export function releaseInfo(value = process.env.FX_GAME_VERSION) {
  const parsed = Number(value);
  const game_build = Number.isInteger(parsed) && parsed >= 1 && parsed <= 100000 ? parsed : DEFAULT_GAME_BUILD;
  return { game_build, version: `v${game_build}` };
}

export function outdatedGame(packet, published) {
  if (!['host', 'join', 'join_request'].includes(packet?.type)) return false;
  // Older clients cannot check /release, but can display this ordinary room error.
  const build = Number(packet.game_build);
  if (packet.game_build == null && published.game_build < 147) return false;
  return !Number.isInteger(build) || build < published.game_build;
}

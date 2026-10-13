import test from 'node:test';
import assert from 'node:assert/strict';
import { releaseInfo, DEFAULT_GAME_BUILD, outdatedGame } from './release.mjs';
test('published release follows explicit live build and bounded fallback', () => {
  assert.deepEqual(releaseInfo('147'), { game_build: 147, version: 'v147' });
  assert.equal(releaseInfo('148').game_build, 148);
  for (const invalid of ['garbage', '0', '-1', '148x', '147.5', '100001']) assert.equal(releaseInfo(invalid).game_build, DEFAULT_GAME_BUILD);
});

test('old gameplay clients get update instructions without disrupting room messages', () => {
  const live = releaseInfo('147');
  for (const type of ['host','join','join_request']) {
    assert.equal(outdatedGame({type, game_build:146}, live), true);
    assert.equal(outdatedGame({type}, live), true);
    assert.equal(outdatedGame({type, game_build:147}, live), false);
    assert.equal(outdatedGame({type, game_build:148}, live), false);
  }
  assert.equal(outdatedGame({type:'host'}, releaseInfo('146')), false);
  assert.equal(outdatedGame({type:'list_rooms'}, live), false);
  assert.equal(outdatedGame({type:'class_host'}, live), false);
  assert.equal(outdatedGame({type:'signal'}, live), false);
});

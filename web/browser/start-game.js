/* Crossroads browser entry point. Game settings are inert JSON from Godot. */
'use strict';
(() => {
  const loading = window.fxSunLoading;
  document.getElementById('retry').addEventListener('click', () => location.reload());
  try {
    const settings = JSON.parse(document.getElementById('crossroads-engine-settings').textContent);
    const engine = new Engine(settings);
    loading.engineGate
      .then(() => engine.startGame({onProgress: (current, total) => loading.progress(current, total)}))
      .then(() => loading.started())
      .catch(error => { loading.error(error); console.error(error); });
  } catch (error) {
    loading.error(error);
    console.error(error);
  }
})();

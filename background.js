/**
 * Smart Vision AI — Background Bootstrap
 * Initializes Three.js scene, mouse interaction, loading, and render loop
 */
(function () {
  'use strict';

  var sceneInstance = null;
  var rafId = null;
  var lastFrame = 0;
  var targetFPS = 60;
  var frameInterval = 1000 / targetFPS;

  /* ============================================================
     DOM READY — Wait for canvas and loader elements
     ============================================================ */
  function init() {
    var canvas = document.getElementById('svai-bg-canvas');
    var loader = document.getElementById('svai-loader');

    if (!canvas) {
      console.warn('[SVAI] Canvas not found — background skipped');
      return;
    }

    /* Re-init when Streamlit rerun injects a fresh canvas element */
    if (canvas.dataset.svaiActive === 'true') return;
    canvas.dataset.svaiActive = 'true';

    if (typeof THREE === 'undefined' || typeof SmartVisionScene === 'undefined') {
      console.warn('[SVAI] Three.js or SmartVisionScene not loaded');
      if (loader) loader.classList.add('svai-hidden');
      return;
    }

    bootScene(canvas, loader);
  }

  /* ============================================================
     SCENE BOOT — Create scene and start animation loop
     ============================================================ */
  function bootScene(canvas, loader) {
    try {
      sceneInstance = new SmartVisionScene(canvas);

      if (typeof SVAIAnimations !== 'undefined') {
        SVAIAnimations.init(sceneInstance);
        SVAIAnimations.playSceneIntro(sceneInstance);
      }

      bindMouseInteraction();
      bindClickExplosions();
      bindResize();
      startRenderLoop();

      setTimeout(function () {
        if (typeof SVAIAnimations !== 'undefined') {
          SVAIAnimations.hideLoader(function () {
            if (typeof SVAIAnimations !== 'undefined') {
              SVAIAnimations.initUICardFloat();
            }
          });
        } else if (loader) {
          loader.classList.add('svai-hidden');
        }
      }, 2800);
    } catch (err) {
      console.error('[SVAI] Scene boot failed:', err);
      if (loader) loader.classList.add('svai-hidden');
    }
  }

  /* ============================================================
     RENDER LOOP — 60 FPS with lazy pause when hidden
     ============================================================ */
  function startRenderLoop() {
    function loop(timestamp) {
      rafId = requestAnimationFrame(loop);

      if (timestamp - lastFrame < frameInterval) return;
      lastFrame = timestamp - (timestamp % frameInterval);

      if (!sceneInstance) return;

      var elapsed = sceneInstance.clock.getElapsedTime();
      sceneInstance.update(elapsed);
      sceneInstance.render();
    }

    rafId = requestAnimationFrame(loop);
  }

  /* ============================================================
     MOUSE INTERACTION — Parallax, glow, particle attraction
     ============================================================ */
  function bindMouseInteraction() {
    var handleMove = function (e) {
      if (!sceneInstance) return;
      var x = e.clientX !== undefined ? e.clientX : (e.touches && e.touches[0] ? e.touches[0].clientX : 0);
      var y = e.clientY !== undefined ? e.clientY : (e.touches && e.touches[0] ? e.touches[0].clientY : 0);
      sceneInstance.updateMouse(x, y);
    };

    window.addEventListener('mousemove', handleMove, { passive: true });
    window.addEventListener('touchmove', handleMove, { passive: true });
  }

  /* ============================================================
     CLICK EXPLOSIONS — Particle burst without blocking UI
     ============================================================ */
  function bindClickExplosions() {
    window.addEventListener('click', function (e) {
      if (!sceneInstance) return;

      var target = e.target;
      var isWidget = target.closest(
        'button, input, textarea, select, [data-testid="stSidebar"], .stButton, a, label'
      );

      if (!isWidget) {
        sceneInstance.spawnExplosion(e.clientX, e.clientY);
      }
    }, { passive: true });
  }

  /* ============================================================
     RESIZE — Debounced viewport update
     ============================================================ */
  function bindResize() {
    var resizeTimer;
    window.addEventListener('resize', function () {
      clearTimeout(resizeTimer);
      resizeTimer = setTimeout(function () {
        if (sceneInstance) sceneInstance.resize();
      }, 150);
    }, { passive: true });
  }

  /* ============================================================
     CLEANUP — Cancel animation frame on unload
     ============================================================ */
  window.addEventListener('beforeunload', function () {
    if (rafId) cancelAnimationFrame(rafId);
    if (sceneInstance) sceneInstance.dispose();
  });

  /* ============================================================
     START — Run when DOM is ready
     ============================================================ */
  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', init);
  } else {
    init();
  }
})();

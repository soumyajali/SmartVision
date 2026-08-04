/**
 * Smart Vision AI — GSAP Animation Controller
 * Smooth cinematic tweens for UI elements and 3D scene accents
 */
(function (global) {
  'use strict';

  var SVAIAnimations = {
    timeline: null,
    uiTimeline: null,
    initialized: false
  };

  /* ============================================================
     LOADER PROGRESS — Simulated boot sequence
     ============================================================ */
  SVAIAnimations.initLoader = function () {
    var bar = document.getElementById('svai-progress-bar');
    var status = document.getElementById('svai-loader-status');
    if (!bar || typeof gsap === 'undefined') return;

    var steps = [
      { width: '15%', text: 'INITIALIZING NEURAL CORE...' },
      { width: '35%', text: 'LOADING PARTICLE ENGINE...' },
      { width: '55%', text: 'CALIBRATING HOLOGRAPHIC DISPLAY...' },
      { width: '75%', text: 'SYNCING AI NODES...' },
      { width: '92%', text: 'ESTABLISHING VISUAL LINK...' },
      { width: '100%', text: 'SYSTEM ONLINE' }
    ];

    var tl = gsap.timeline();
    steps.forEach(function (step, i) {
      tl.to(bar, {
        width: step.width,
        duration: 0.45,
        ease: 'power2.out',
        onStart: function () {
          if (status) status.textContent = step.text;
        }
      }, i * 0.35);
    });

    return tl;
  };

  /* ============================================================
     HIDE LOADER — Fade out with scale effect
     ============================================================ */
  SVAIAnimations.hideLoader = function (callback) {
    var loader = document.getElementById('svai-loader');
    if (!loader) {
      if (callback) callback();
      return;
    }

    if (typeof gsap === 'undefined') {
      loader.classList.add('svai-hidden');
      if (callback) callback();
      return;
    }

    gsap.to(loader, {
      opacity: 0,
      duration: 0.9,
      ease: 'power2.inOut',
      onComplete: function () {
        loader.classList.add('svai-hidden');
        if (callback) callback();
      }
    });

    gsap.from('.section-title', {
      opacity: 0,
      y: 30,
      duration: 1.2,
      delay: 0.3,
      ease: 'power3.out'
    });
  };

  /* ============================================================
     SCENE INTRO — Camera dolly-in on boot
     ============================================================ */
  SVAIAnimations.playSceneIntro = function (sceneInstance) {
    if (!sceneInstance || typeof gsap === 'undefined') return;

    var cam = sceneInstance.camera;
    var startZ = cam.position.z + 12;
    cam.position.z = startZ;

    gsap.to(cam.position, {
      z: sceneInstance.baseCameraPos.z,
      duration: 2.8,
      ease: 'power3.out'
    });
  };

  /* ============================================================
     FLOATING UI — Subtle parallax on glass cards
     ============================================================ */
  SVAIAnimations.initUICardFloat = function () {
    if (typeof gsap === 'undefined') return;

    var cards = document.querySelectorAll('.card-box');
    cards.forEach(function (card, index) {
      gsap.to(card, {
        y: -10,
        duration: 2.5 + index * 0.4,
        repeat: -1,
        yoyo: true,
        ease: 'sine.inOut',
        delay: index * 0.3
      });
    });
  };

  /* ============================================================
     BUTTON RIPPLE — Neon click feedback
     ============================================================ */
  SVAIAnimations.initButtonRipples = function () {
    document.addEventListener('click', function (e) {
      var btn = e.target.closest('.stButton > button, [data-testid="stBaseButton-primary"], [data-testid="stBaseButton-secondary"]');
      if (!btn || typeof gsap === 'undefined') return;

      var ripple = document.createElement('span');
      ripple.className = 'svai-ripple';
      ripple.style.cssText = [
        'position:absolute',
        'border-radius:50%',
        'background:radial-gradient(circle,rgba(0,229,255,0.5) 0%,transparent 70%)',
        'pointer-events:none',
        'transform:scale(0)',
        'width:120px',
        'height:120px',
        'left:' + (e.offsetX - 60) + 'px',
        'top:' + (e.offsetY - 60) + 'px'
      ].join(';');

      btn.appendChild(ripple);

      gsap.to(ripple, {
        scale: 2.5,
        opacity: 0,
        duration: 0.7,
        ease: 'power2.out',
        onComplete: function () {
          ripple.remove();
        }
      });
    });
  };

  /* ============================================================
     SIDEBAR ENTRANCE — Slide-in glass panel
     ============================================================ */
  SVAIAnimations.animateSidebar = function () {
    if (typeof gsap === 'undefined') return;

    var sidebar = document.querySelector('[data-testid="stSidebar"]');
    if (!sidebar) return;

    gsap.from(sidebar, {
      x: -40,
      opacity: 0,
      duration: 1.0,
      ease: 'power3.out',
      delay: 0.5
    });
  };

  /* ============================================================
     HEADING GLOW PULSE — Gradient text animation
     ============================================================ */
  SVAIAnimations.initHeadingGlow = function () {
    if (typeof gsap === 'undefined') return;

    var titles = document.querySelectorAll('.section-title');
    titles.forEach(function (title) {
      gsap.to(title, {
        textShadow: '0 0 30px rgba(0,229,255,0.6)',
        duration: 2,
        repeat: -1,
        yoyo: true,
        ease: 'sine.inOut'
      });
    });
  };

  /* ============================================================
     ENERGY WAVE — Periodic scene pulse
     ============================================================ */
  SVAIAnimations.startEnergyWaves = function (sceneInstance) {
    if (!sceneInstance || typeof gsap === 'undefined') return;

    function pulse() {
      if (sceneInstance.holoSphereInner) {
        gsap.to(sceneInstance.holoSphereInner.scale, {
          x: 1.15,
          y: 1.15,
          z: 1.15,
          duration: 1.5,
          yoyo: true,
          repeat: 1,
          ease: 'sine.inOut',
          onComplete: function () {
            setTimeout(pulse, 4000 + Math.random() * 3000);
          }
        });
      } else {
        setTimeout(pulse, 5000);
      }
    }

    setTimeout(pulse, 2000);
  };

  /* ============================================================
     SCAN LINE — HUD scanning overlay on loader logo
     ============================================================ */
  SVAIAnimations.initScanEffect = function () {
    var logo = document.querySelector('.svai-loader-logo');
    if (!logo || typeof gsap === 'undefined') return;

    var scanLine = document.createElement('div');
    scanLine.style.cssText = [
      'position:absolute',
      'left:0',
      'right:0',
      'height:2px',
      'background:linear-gradient(90deg,transparent,#00E5FF,#00FFC6,transparent)',
      'box-shadow:0 0 8px #00E5FF',
      'top:0'
    ].join(';');
    logo.style.position = 'relative';
    logo.appendChild(scanLine);

    gsap.to(scanLine, {
      top: '100%',
      duration: 1.2,
      repeat: -1,
      ease: 'none'
    });
  };

  /* ============================================================
     MASTER INIT — Wire all UI animations
     ============================================================ */
  SVAIAnimations.init = function (sceneInstance) {
    if (SVAIAnimations.initialized) return;
    SVAIAnimations.initialized = true;

    SVAIAnimations.initScanEffect();
    SVAIAnimations.initLoader();
    SVAIAnimations.initButtonRipples();

    setTimeout(function () {
      SVAIAnimations.animateSidebar();
      SVAIAnimations.initUICardFloat();
      SVAIAnimations.initHeadingGlow();
      SVAIAnimations.startEnergyWaves(sceneInstance);
    }, 1200);
  };

  global.SVAIAnimations = SVAIAnimations;

})(typeof window !== 'undefined' ? window : this);

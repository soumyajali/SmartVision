/**
 * Smart Vision AI — Three.js Scene Engine
 * Full cinematic 3D background: particles, neural network, holographic objects
 * Optimized for 60 FPS with BufferGeometry, instancing, and capped pixel ratio
 */
(function (global) {
  'use strict';

  /* ============================================================
     COLOR PALETTE & CONSTANTS
     ============================================================ */
  var COLORS = {
    bg: 0x050816,
    primary: 0x00e5ff,
    secondary: 0x7b61ff,
    accent: 0x00ffc6,
    glow: 0x4fd1ff,
    white: 0xffffff
  };

  var PARTICLE_COUNT = 15000;
  var STAR_COUNT = 8000;
  var NEBULA_COUNT = 4000;
  var BINARY_COUNT = 3000;

  /* ============================================================
     SmartVisionScene — Main scene controller
     ============================================================ */
  function SmartVisionScene(container) {
    this.container = container;
    this.mouse = { x: 0, y: 0, targetX: 0, targetY: 0 };
    this.clock = new THREE.Clock();
    this.animatedGroups = [];
    this.neuralLines = null;
    this.neuralNodes = [];
    this.particleSystems = [];
    this.explosions = [];
    this.isVisible = true;
    this.pixelRatioCap = Math.min(window.devicePixelRatio || 1, 2);

    this._initRenderer();
    this._initScene();
    this._initCamera();
    this._initLights();
    this._createStarField();
    this._createNebulaParticles();
    this._createBinaryParticles();
    this._createParticleWave();
    this._createNeuralNetwork();
    this._createDigitalGrid();
    this._createHolographicSphere();
    this._createFloatingEarth();
    this._createAIBrain();
    this._createOrbitingRings();
    this._createHexGrid();
    this._createGlassCubes();
    this._createWireframeGeometry();
    this._createFloatingPolygons();
    this._createTorus();
    this._createLightBeams();
    this._createGlassPanels();
    this._createCircuitPattern();
    this._createFog();
    this._bindEvents();
  }

  /* ============================================================
     RENDERER — WebGL with GPU acceleration
     ============================================================ */
  SmartVisionScene.prototype._initRenderer = function () {
    this.renderer = new THREE.WebGLRenderer({
      canvas: this.container,
      antialias: true,
      alpha: true,
      powerPreference: 'high-performance',
      stencil: false
    });
    this.renderer.setClearColor(COLORS.bg, 1);
    this.renderer.setPixelRatio(this.pixelRatioCap);
    this.renderer.setSize(window.innerWidth, window.innerHeight);
    if (THREE.sRGBEncoding) this.renderer.outputEncoding = THREE.sRGBEncoding;
    this.renderer.toneMapping = THREE.ACESFilmicToneMapping;
    this.renderer.toneMappingExposure = 1.1;
  };

  /* ============================================================
     SCENE & CAMERA — Cinematic perspective
     ============================================================ */
  SmartVisionScene.prototype._initScene = function () {
    this.scene = new THREE.Scene();
    this.scene.background = new THREE.Color(COLORS.bg);
    this.scene.fog = new THREE.FogExp2(COLORS.bg, 0.012);
  };

  SmartVisionScene.prototype._initCamera = function () {
    this.camera = new THREE.PerspectiveCamera(
      55,
      window.innerWidth / window.innerHeight,
      0.1,
      500
    );
    this.camera.position.set(0, 2, 28);
    this.baseCameraPos = this.camera.position.clone();
  };

  /* ============================================================
     LIGHTING — Blue / purple / cyan cinematic rig
     ============================================================ */
  SmartVisionScene.prototype._initLights = function () {
    var ambient = new THREE.AmbientLight(0x1a2040, 0.6);
    this.scene.add(ambient);

    this.keyLight = new THREE.PointLight(COLORS.primary, 2.2, 120);
    this.keyLight.position.set(8, 12, 10);
    this.scene.add(this.keyLight);

    this.fillLight = new THREE.PointLight(COLORS.secondary, 1.6, 100);
    this.fillLight.position.set(-10, -4, 6);
    this.scene.add(this.fillLight);

    this.rimLight = new THREE.PointLight(COLORS.accent, 1.4, 80);
    this.rimLight.position.set(0, 8, -12);
    this.scene.add(this.rimLight);

    var dirLight = new THREE.DirectionalLight(COLORS.glow, 0.5);
    dirLight.position.set(0, 20, 0);
    this.scene.add(dirLight);
  };

  /* ============================================================
     STAR FIELD — 8000 distant stars for depth
     ============================================================ */
  SmartVisionScene.prototype._createStarField = function () {
    var positions = new Float32Array(STAR_COUNT * 3);
    var colors = new Float32Array(STAR_COUNT * 3);
    var sizes = new Float32Array(STAR_COUNT);

    for (var i = 0; i < STAR_COUNT; i++) {
      var i3 = i * 3;
      var radius = 40 + Math.random() * 160;
      var theta = Math.random() * Math.PI * 2;
      var phi = Math.acos(2 * Math.random() - 1);

      positions[i3] = radius * Math.sin(phi) * Math.cos(theta);
      positions[i3 + 1] = radius * Math.sin(phi) * Math.sin(theta);
      positions[i3 + 2] = radius * Math.cos(phi);

      var tint = Math.random();
      colors[i3] = 0.3 + tint * 0.7;
      colors[i3 + 1] = 0.6 + tint * 0.4;
      colors[i3 + 2] = 1.0;

      sizes[i] = Math.random() * 1.8 + 0.2;
    }

    var geo = new THREE.BufferGeometry();
    geo.setAttribute('position', new THREE.BufferAttribute(positions, 3));
    geo.setAttribute('color', new THREE.BufferAttribute(colors, 3));
    geo.setAttribute('size', new THREE.BufferAttribute(sizes, 1));

    var mat = new THREE.PointsMaterial({
      size: 0.15,
      vertexColors: true,
      transparent: true,
      opacity: 0.85,
      blending: THREE.AdditiveBlending,
      depthWrite: false,
      sizeAttenuation: true
    });

    this.stars = new THREE.Points(geo, mat);
    this.scene.add(this.stars);
    this.particleSystems.push(this.stars);
  };

  /* ============================================================
     NEBULA PARTICLES — Soft volumetric glow clusters
     ============================================================ */
  SmartVisionScene.prototype._createNebulaParticles = function () {
    var positions = new Float32Array(NEBULA_COUNT * 3);
    var colors = new Float32Array(NEBULA_COUNT * 3);

    for (var i = 0; i < NEBULA_COUNT; i++) {
      var i3 = i * 3;
      positions[i3] = (Math.random() - 0.5) * 80;
      positions[i3 + 1] = (Math.random() - 0.5) * 50;
      positions[i3 + 2] = (Math.random() - 0.5) * 80 - 20;

      var mix = Math.random();
      colors[i3] = mix < 0.5 ? 0.0 : 0.48;
      colors[i3 + 1] = mix < 0.5 ? 0.9 : 0.38;
      colors[i3 + 2] = mix < 0.5 ? 1.0 : 1.0;
    }

    var geo = new THREE.BufferGeometry();
    geo.setAttribute('position', new THREE.BufferAttribute(positions, 3));
    geo.setAttribute('color', new THREE.BufferAttribute(colors, 3));

    var mat = new THREE.PointsMaterial({
      size: 0.35,
      vertexColors: true,
      transparent: true,
      opacity: 0.35,
      blending: THREE.AdditiveBlending,
      depthWrite: false
    });

    this.nebula = new THREE.Points(geo, mat);
    this.scene.add(this.nebula);
    this.particleSystems.push(this.nebula);
  };

  /* ============================================================
     BINARY PARTICLES — Floating 0/1 data stream
     ============================================================ */
  SmartVisionScene.prototype._createBinaryParticles = function () {
    var positions = new Float32Array(BINARY_COUNT * 3);
    var velocities = [];

    for (var i = 0; i < BINARY_COUNT; i++) {
      var i3 = i * 3;
      positions[i3] = (Math.random() - 0.5) * 60;
      positions[i3 + 1] = (Math.random() - 0.5) * 40;
      positions[i3 + 2] = (Math.random() - 0.5) * 60;
      velocities.push({
        y: (Math.random() - 0.5) * 0.02,
        x: (Math.random() - 0.5) * 0.005
      });
    }

    var geo = new THREE.BufferGeometry();
    geo.setAttribute('position', new THREE.BufferAttribute(positions, 3));

    var mat = new THREE.PointsMaterial({
      color: COLORS.glow,
      size: 0.12,
      transparent: true,
      opacity: 0.5,
      blending: THREE.AdditiveBlending,
      depthWrite: false
    });

    this.binaryParticles = new THREE.Points(geo, mat);
    this.binaryParticles.userData.velocities = velocities;
    this.scene.add(this.binaryParticles);
    this.particleSystems.push(this.binaryParticles);
  };

  /* ============================================================
     PARTICLE WAVE — Sine-driven ripple field
     ============================================================ */
  SmartVisionScene.prototype._createParticleWave = function () {
    var waveCount = 2000;
    var positions = new Float32Array(waveCount * 3);
    var baseY = new Float32Array(waveCount);

    for (var i = 0; i < waveCount; i++) {
      var i3 = i * 3;
      positions[i3] = (i % 50 - 25) * 1.2;
      positions[i3 + 1] = -8;
      positions[i3 + 2] = (Math.floor(i / 50) - 20) * 1.2;
      baseY[i] = positions[i3 + 1];
    }

    var geo = new THREE.BufferGeometry();
    geo.setAttribute('position', new THREE.BufferAttribute(positions, 3));
    geo.userData.baseY = baseY;

    var mat = new THREE.PointsMaterial({
      color: COLORS.primary,
      size: 0.08,
      transparent: true,
      opacity: 0.4,
      blending: THREE.AdditiveBlending,
      depthWrite: false
    });

    this.particleWave = new THREE.Points(geo, mat);
    this.scene.add(this.particleWave);
  };

  /* ============================================================
     NEURAL NETWORK — AI nodes with dynamic connections
     ============================================================ */
  SmartVisionScene.prototype._createNeuralNetwork = function () {
    var nodeCount = 64;
    var nodeGeo = new THREE.SphereGeometry(0.12, 8, 8);
    var nodeMat = new THREE.MeshBasicMaterial({
      color: COLORS.primary,
      transparent: true,
      opacity: 0.85
    });

    var group = new THREE.Group();
    group.position.set(-12, 4, -15);

    for (var n = 0; n < nodeCount; n++) {
      var node = new THREE.Mesh(nodeGeo, nodeMat.clone());
      node.position.set(
        (Math.random() - 0.5) * 14,
        (Math.random() - 0.5) * 10,
        (Math.random() - 0.5) * 10
      );
      node.userData.phase = Math.random() * Math.PI * 2;
      node.userData.basePos = node.position.clone();
      group.add(node);
      this.neuralNodes.push(node);
    }

    var linePositions = [];
    for (var a = 0; a < nodeCount; a++) {
      for (var b = a + 1; b < nodeCount; b++) {
        if (Math.random() > 0.88) {
          linePositions.push(
            this.neuralNodes[a].position.x, this.neuralNodes[a].position.y, this.neuralNodes[a].position.z,
            this.neuralNodes[b].position.x, this.neuralNodes[b].position.y, this.neuralNodes[b].position.z
          );
        }
      }
    }

    var lineGeo = new THREE.BufferGeometry();
    lineGeo.setAttribute('position', new THREE.Float32BufferAttribute(linePositions, 3));
    var lineMat = new THREE.LineBasicMaterial({
      color: COLORS.secondary,
      transparent: true,
      opacity: 0.25,
      blending: THREE.AdditiveBlending
    });

    this.neuralLines = new THREE.LineSegments(lineGeo, lineMat);
    group.add(this.neuralLines);
    this.scene.add(group);
    this.neuralGroup = group;
    this.animatedGroups.push(group);
  };

  /* ============================================================
     DIGITAL GRID — Infinite floor grid with motion
     ============================================================ */
  SmartVisionScene.prototype._createDigitalGrid = function () {
    var gridHelper = new THREE.GridHelper(120, 60, COLORS.primary, COLORS.secondary);
    gridHelper.material.transparent = true;
    gridHelper.material.opacity = 0.12;
    gridHelper.position.y = -14;
    this.grid = gridHelper;
    this.scene.add(gridHelper);

    var planeGeo = new THREE.PlaneGeometry(120, 120, 1, 1);
    var planeMat = new THREE.MeshBasicMaterial({
      color: COLORS.secondary,
      transparent: true,
      opacity: 0.03,
      side: THREE.DoubleSide
    });
    this.gridPlane = new THREE.Mesh(planeGeo, planeMat);
    this.gridPlane.rotation.x = -Math.PI / 2;
    this.gridPlane.position.y = -14.01;
    this.scene.add(this.gridPlane);
  };

  /* ============================================================
     HOLOGRAPHIC SPHERE — Rotating energy core
     ============================================================ */
  SmartVisionScene.prototype._createHolographicSphere = function () {
    var geo = new THREE.IcosahedronGeometry(3.5, 2);
    var mat = new THREE.MeshPhongMaterial({
      color: COLORS.primary,
      emissive: COLORS.glow,
      emissiveIntensity: 0.35,
      transparent: true,
      opacity: 0.35,
      wireframe: true
    });

    this.holoSphere = new THREE.Mesh(geo, mat);
    this.holoSphere.position.set(14, 2, -8);

    var innerGeo = new THREE.SphereGeometry(2.8, 32, 32);
    var innerMat = new THREE.MeshBasicMaterial({
      color: COLORS.accent,
      transparent: true,
      opacity: 0.08,
      blending: THREE.AdditiveBlending
    });
    this.holoSphereInner = new THREE.Mesh(innerGeo, innerMat);
    this.holoSphere.add(this.holoSphereInner);

    this.scene.add(this.holoSphere);
    this.animatedGroups.push(this.holoSphere);
  };

  /* ============================================================
     FLOATING HOLOGRAPHIC EARTH
     ============================================================ */
  SmartVisionScene.prototype._createFloatingEarth = function () {
    var group = new THREE.Group();
    group.position.set(-16, -2, -5);

    var earthGeo = new THREE.SphereGeometry(2.2, 48, 48);
    var earthMat = new THREE.MeshPhongMaterial({
      color: COLORS.primary,
      emissive: 0x002244,
      emissiveIntensity: 0.4,
      transparent: true,
      opacity: 0.55,
      shininess: 80
    });
    this.earth = new THREE.Mesh(earthGeo, earthMat);
    group.add(this.earth);

    var wireGeo = new THREE.SphereGeometry(2.35, 24, 24);
    var wireMat = new THREE.MeshBasicMaterial({
      color: COLORS.glow,
      wireframe: true,
      transparent: true,
      opacity: 0.25
    });
    this.earthWire = new THREE.Mesh(wireGeo, wireMat);
    group.add(this.earthWire);

    var atmosGeo = new THREE.SphereGeometry(2.5, 32, 32);
    var atmosMat = new THREE.MeshBasicMaterial({
      color: COLORS.accent,
      transparent: true,
      opacity: 0.06,
      side: THREE.BackSide,
      blending: THREE.AdditiveBlending
    });
    this.earthAtmos = new THREE.Mesh(atmosGeo, atmosMat);
    group.add(this.earthAtmos);

    this.earthGroup = group;
    this.scene.add(group);
    this.animatedGroups.push(group);
  };

  /* ============================================================
     TRANSPARENT AI BRAIN — Rotating icosahedron cluster
     ============================================================ */
  SmartVisionScene.prototype._createAIBrain = function () {
    var group = new THREE.Group();
    group.position.set(6, 6, -12);

    for (var i = 0; i < 5; i++) {
      var geo = new THREE.IcosahedronGeometry(0.8 + i * 0.15, 1);
      var mat = new THREE.MeshPhongMaterial({
        color: COLORS.secondary,
        emissive: COLORS.secondary,
        emissiveIntensity: 0.2,
        transparent: true,
        opacity: 0.25 - i * 0.03,
        wireframe: i % 2 === 0
      });
      var mesh = new THREE.Mesh(geo, mat);
      mesh.userData.layer = i;
      group.add(mesh);
    }

    this.brainGroup = group;
    this.scene.add(group);
    this.animatedGroups.push(group);
  };

  /* ============================================================
     ORBITING RINGS — Saturn-style holographic bands
     ============================================================ */
  SmartVisionScene.prototype._createOrbitingRings = function () {
    var group = new THREE.Group();
    group.position.set(0, 0, -20);

    for (var r = 0; r < 3; r++) {
      var ringGeo = new THREE.TorusGeometry(5 + r * 1.5, 0.03, 8, 128);
      var ringMat = new THREE.MeshBasicMaterial({
        color: r === 0 ? COLORS.primary : r === 1 ? COLORS.secondary : COLORS.accent,
        transparent: true,
        opacity: 0.45 - r * 0.1,
        blending: THREE.AdditiveBlending
      });
      var ring = new THREE.Mesh(ringGeo, ringMat);
      ring.rotation.x = Math.PI / 2 + r * 0.3;
      ring.userData.speed = 0.002 + r * 0.001;
      group.add(ring);
    }

    this.ringsGroup = group;
    this.scene.add(group);
    this.animatedGroups.push(group);
  };

  /* ============================================================
     HEXAGONAL GRID — Honeycomb AI mesh
     ============================================================ */
  SmartVisionScene.prototype._createHexGrid = function () {
    var group = new THREE.Group();
    group.position.set(0, -10, -30);
    group.rotation.x = -Math.PI / 2.5;

    var hexShape = new THREE.Shape();
    var radius = 0.5;
    for (var i = 0; i < 6; i++) {
      var angle = (i / 6) * Math.PI * 2;
      var x = Math.cos(angle) * radius;
      var y = Math.sin(angle) * radius;
      if (i === 0) hexShape.moveTo(x, y);
      else hexShape.lineTo(x, y);
    }
    hexShape.closePath();

    var hexGeo = new THREE.ShapeGeometry(hexShape);
    var hexMat = new THREE.MeshBasicMaterial({
      color: COLORS.primary,
      transparent: true,
      opacity: 0.15,
      side: THREE.DoubleSide,
      blending: THREE.AdditiveBlending
    });

    for (var row = -8; row <= 8; row++) {
      for (var col = -8; col <= 8; col++) {
        var hex = new THREE.Mesh(hexGeo, hexMat.clone());
        hex.position.set(col * 1.05 + (row % 2) * 0.52, row * 0.9, 0);
        hex.userData.pulse = Math.random() * Math.PI * 2;
        group.add(hex);
      }
    }

    this.hexGrid = group;
    this.scene.add(group);
  };

  /* ============================================================
     FLOATING GLASS CUBES — Instanced translucent blocks
     ============================================================ */
  SmartVisionScene.prototype._createGlassCubes = function () {
    var count = 24;
    var geo = new THREE.BoxGeometry(0.6, 0.6, 0.6);
    var mat = new THREE.MeshPhongMaterial({
      color: COLORS.glow,
      transparent: true,
      opacity: 0.2,
      shininess: 100,
      emissive: COLORS.primary,
      emissiveIntensity: 0.15
    });

    this.glassCubes = new THREE.Group();
    for (var c = 0; c < count; c++) {
      var cube = new THREE.Mesh(geo, mat.clone());
      cube.position.set(
        (Math.random() - 0.5) * 40,
        (Math.random() - 0.5) * 25,
        (Math.random() - 0.5) * 30 - 10
      );
      cube.rotation.set(Math.random() * Math.PI, Math.random() * Math.PI, Math.random() * Math.PI);
      cube.userData.rotSpeed = {
        x: (Math.random() - 0.5) * 0.008,
        y: (Math.random() - 0.5) * 0.008,
        z: (Math.random() - 0.5) * 0.008
      };
      cube.userData.floatPhase = Math.random() * Math.PI * 2;
      cube.userData.baseY = cube.position.y;
      this.glassCubes.add(cube);
    }

    this.scene.add(this.glassCubes);
  };

  /* ============================================================
     WIREFRAME GEOMETRY — Dodecahedron & octahedron accents
     ============================================================ */
  SmartVisionScene.prototype._createWireframeGeometry = function () {
    this.wireGroup = new THREE.Group();

    var dodecaGeo = new THREE.DodecahedronGeometry(1.5, 0);
    var dodecaMat = new THREE.MeshBasicMaterial({
      color: COLORS.accent,
      wireframe: true,
      transparent: true,
      opacity: 0.35
    });
    var dodeca = new THREE.Mesh(dodecaGeo, dodecaMat);
    dodeca.position.set(-8, 8, -18);
    this.wireGroup.add(dodeca);

    var octaGeo = new THREE.OctahedronGeometry(1.2, 0);
    var octaMat = new THREE.MeshBasicMaterial({
      color: COLORS.primary,
      wireframe: true,
      transparent: true,
      opacity: 0.4
    });
    var octa = new THREE.Mesh(octaGeo, octaMat);
    octa.position.set(10, -4, -22);
    this.wireGroup.add(octa);

    this.scene.add(this.wireGroup);
    this.animatedGroups.push(this.wireGroup);
  };

  /* ============================================================
     FLOATING POLYGONS — Random polyhedra drift
     ============================================================ */
  SmartVisionScene.prototype._createFloatingPolygons = function () {
    this.polygonGroup = new THREE.Group();

    var shapes = [
      new THREE.TetrahedronGeometry(0.8),
      new THREE.OctahedronGeometry(0.7),
      new THREE.IcosahedronGeometry(0.6)
    ];

    for (var p = 0; p < 12; p++) {
      var geo = shapes[p % shapes.length];
      var mat = new THREE.MeshPhongMaterial({
        color: p % 2 === 0 ? COLORS.secondary : COLORS.accent,
        transparent: true,
        opacity: 0.2,
        flatShading: true,
        emissive: COLORS.glow,
        emissiveIntensity: 0.1
      });
      var mesh = new THREE.Mesh(geo, mat);
      mesh.position.set(
        (Math.random() - 0.5) * 35,
        (Math.random() - 0.5) * 20,
        (Math.random() - 0.5) * 25 - 5
      );
      mesh.userData.floatPhase = Math.random() * Math.PI * 2;
      mesh.userData.baseY = mesh.position.y;
      this.polygonGroup.add(mesh);
    }

    this.scene.add(this.polygonGroup);
  };

  /* ============================================================
     ROTATING TORUS — Energy portal ring
     ============================================================ */
  SmartVisionScene.prototype._createTorus = function () {
    var geo = new THREE.TorusGeometry(4, 0.08, 16, 100);
    var mat = new THREE.MeshBasicMaterial({
      color: COLORS.primary,
      transparent: true,
      opacity: 0.5,
      blending: THREE.AdditiveBlending
    });
    this.torus = new THREE.Mesh(geo, mat);
    this.torus.position.set(-4, 0, -25);
    this.torus.rotation.x = Math.PI / 3;
    this.scene.add(this.torus);
    this.animatedGroups.push(this.torus);
  };

  /* ============================================================
     ANIMATED LIGHT BEAMS — Volumetric-style columns
     ============================================================ */
  SmartVisionScene.prototype._createLightBeams = function () {
    this.beamsGroup = new THREE.Group();

    for (var b = 0; b < 5; b++) {
      var beamGeo = new THREE.CylinderGeometry(0.02, 0.15, 20, 8, 1, true);
      var beamMat = new THREE.MeshBasicMaterial({
        color: b % 2 === 0 ? COLORS.primary : COLORS.secondary,
        transparent: true,
        opacity: 0.12,
        side: THREE.DoubleSide,
        blending: THREE.AdditiveBlending,
        depthWrite: false
      });
      var beam = new THREE.Mesh(beamGeo, beamMat);
      beam.position.set((b - 2) * 8, 0, -15 - b * 2);
      beam.userData.pulse = Math.random() * Math.PI * 2;
      this.beamsGroup.add(beam);
    }

    this.scene.add(this.beamsGroup);
  };

  /* ============================================================
     FLOATING GLASS PANELS — Transparent UI shards
     ============================================================ */
  SmartVisionScene.prototype._createGlassPanels = function () {
    this.panelsGroup = new THREE.Group();

    for (var g = 0; g < 8; g++) {
      var panelGeo = new THREE.PlaneGeometry(2.5, 1.5);
      var panelMat = new THREE.MeshPhongMaterial({
        color: COLORS.glow,
        transparent: true,
        opacity: 0.08,
        side: THREE.DoubleSide,
        emissive: COLORS.primary,
        emissiveIntensity: 0.08,
        shininess: 120
      });
      var panel = new THREE.Mesh(panelGeo, panelMat);
      panel.position.set(
        (Math.random() - 0.5) * 30,
        (Math.random() - 0.5) * 18,
        (Math.random() - 0.5) * 20 - 8
      );
      panel.rotation.set(
        Math.random() * 0.5,
        Math.random() * Math.PI,
        Math.random() * 0.3
      );
      panel.userData.floatPhase = Math.random() * Math.PI * 2;
      this.panelsGroup.add(panel);
    }

    this.scene.add(this.panelsGroup);
  };

  /* ============================================================
     AI CIRCUIT PATTERN — PCB-style line network
     ============================================================ */
  SmartVisionScene.prototype._createCircuitPattern = function () {
    var points = [];
    var cx = 18;
    var cy = -6;
    var cz = -18;

    for (var i = 0; i < 40; i++) {
      points.push(new THREE.Vector3(
        cx + (Math.random() - 0.5) * 10,
        cy + (Math.random() - 0.5) * 6,
        cz + (Math.random() - 0.5) * 6
      ));
    }

    for (var j = 0; j < points.length - 1; j++) {
      if (Math.random() > 0.4) {
        var lineGeo = new THREE.BufferGeometry().setFromPoints([points[j], points[j + 1]]);
        var lineMat = new THREE.LineBasicMaterial({
          color: COLORS.accent,
          transparent: true,
          opacity: 0.2,
          blending: THREE.AdditiveBlending
        });
        this.scene.add(new THREE.Line(lineGeo, lineMat));
      }
    }
  };

  /* ============================================================
     FOG — Soft atmospheric depth
     ============================================================ */
  SmartVisionScene.prototype._createFog = function () {
    this.scene.fog = new THREE.FogExp2(COLORS.bg, 0.014);
  };

  /* ============================================================
     CLICK EXPLOSION — Particle burst on user click
     ============================================================ */
  SmartVisionScene.prototype.spawnExplosion = function (clientX, clientY) {
    var ndcX = (clientX / window.innerWidth) * 2 - 1;
    var ndcY = -(clientY / window.innerHeight) * 2 + 1;

    var vector = new THREE.Vector3(ndcX, ndcY, 0.5);
    vector.unproject(this.camera);
    var dir = vector.sub(this.camera.position).normalize();
    var pos = this.camera.position.clone().add(dir.multiplyScalar(20));

    var count = 120;
    var positions = new Float32Array(count * 3);
    var velocities = [];

    for (var i = 0; i < count; i++) {
      var i3 = i * 3;
      positions[i3] = pos.x;
      positions[i3 + 1] = pos.y;
      positions[i3 + 2] = pos.z;
      velocities.push(new THREE.Vector3(
        (Math.random() - 0.5) * 0.4,
        (Math.random() - 0.5) * 0.4,
        (Math.random() - 0.5) * 0.4
      ));
    }

    var geo = new THREE.BufferGeometry();
    geo.setAttribute('position', new THREE.BufferAttribute(positions, 3));
    var mat = new THREE.PointsMaterial({
      color: COLORS.accent,
      size: 0.25,
      transparent: true,
      opacity: 1,
      blending: THREE.AdditiveBlending,
      depthWrite: false
    });

    var explosion = new THREE.Points(geo, mat);
    explosion.userData.velocities = velocities;
    explosion.userData.life = 1.0;
    this.scene.add(explosion);
    this.explosions.push(explosion);
  };

  /* ============================================================
     MOUSE PARALLAX & PARTICLE ATTRACTION
     ============================================================ */
  SmartVisionScene.prototype.updateMouse = function (x, y) {
    this.mouse.targetX = (x / window.innerWidth - 0.5) * 2;
    this.mouse.targetY = (y / window.innerHeight - 0.5) * 2;
  };

  SmartVisionScene.prototype._applyMouseParallax = function () {
    this.mouse.x += (this.mouse.targetX - this.mouse.x) * 0.04;
    this.mouse.y += (this.mouse.targetY - this.mouse.y) * 0.04;

    this.camera.position.x = this.baseCameraPos.x + this.mouse.x * 3;
    this.camera.position.y = this.baseCameraPos.y - this.mouse.y * 2;
    this.camera.lookAt(0, 0, -10);

    this.keyLight.position.x = 8 + this.mouse.x * 4;
    this.keyLight.position.y = 12 - this.mouse.y * 3;
  };

  /* ============================================================
     ANIMATION LOOP — Per-frame updates
     ============================================================ */
  SmartVisionScene.prototype.update = function (elapsed) {
    if (!this.isVisible) return;

    var t = elapsed;

    this._applyMouseParallax();

    if (this.stars) this.stars.rotation.y = t * 0.008;
    if (this.nebula) {
      this.nebula.rotation.y = t * 0.003;
      this.nebula.rotation.x = Math.sin(t * 0.2) * 0.05;
    }

    if (this.binaryParticles) {
      var pos = this.binaryParticles.geometry.attributes.position;
      var vels = this.binaryParticles.userData.velocities;
      for (var i = 0; i < vels.length; i++) {
        var i3 = i * 3;
        pos.array[i3] += vels[i].x + this.mouse.x * 0.001;
        pos.array[i3 + 1] += vels[i].y;
        pos.array[i3 + 2] += Math.sin(t + i) * 0.001;
        if (pos.array[i3 + 1] > 25) pos.array[i3 + 1] = -25;
      }
      pos.needsUpdate = true;
    }

    if (this.particleWave) {
      var wavePos = this.particleWave.geometry.attributes.position;
      var baseY = this.particleWave.geometry.userData.baseY;
      for (var w = 0; w < baseY.length; w++) {
        var w3 = w * 3;
        var wx = wavePos.array[w3];
        var wz = wavePos.array[w3 + 2];
        wavePos.array[w3 + 1] = baseY[w] + Math.sin(wx * 0.3 + t * 1.5) * 0.8 + Math.cos(wz * 0.3 + t) * 0.5;
      }
      wavePos.needsUpdate = true;
    }

    if (this.holoSphere) {
      this.holoSphere.rotation.x = t * 0.15;
      this.holoSphere.rotation.y = t * 0.22;
      this.holoSphere.material.opacity = 0.3 + Math.sin(t * 2) * 0.08;
    }

    if (this.earthGroup) {
      this.earth.rotation.y = t * 0.12;
      this.earthWire.rotation.y = -t * 0.08;
      this.earthGroup.position.y = -2 + Math.sin(t * 0.5) * 0.4;
    }

    if (this.brainGroup) {
      this.brainGroup.rotation.y = t * 0.2;
      this.brainGroup.rotation.x = Math.sin(t * 0.3) * 0.15;
    }

    if (this.ringsGroup) {
      this.ringsGroup.children.forEach(function (ring) {
        ring.rotation.z += ring.userData.speed;
      });
    }

    if (this.glassCubes) {
      this.glassCubes.children.forEach(function (cube) {
        cube.rotation.x += cube.userData.rotSpeed.x;
        cube.rotation.y += cube.userData.rotSpeed.y;
        cube.position.y = cube.userData.baseY + Math.sin(t + cube.userData.floatPhase) * 0.6;
      });
    }

    if (this.torus) {
      this.torus.rotation.z = t * 0.25;
      this.torus.rotation.y = t * 0.1;
    }

    if (this.neuralNodes.length) {
      this.neuralNodes.forEach(function (node) {
        var bp = node.userData.basePos;
        node.position.y = bp.y + Math.sin(t * 1.5 + node.userData.phase) * 0.3;
        node.material.opacity = 0.6 + Math.sin(t * 3 + node.userData.phase) * 0.25;
      });
    }

    if (this.grid) {
      this.grid.position.z = (t * 0.5) % 2;
    }

    this.explosions = this.explosions.filter(function (exp) {
      exp.userData.life -= 0.025;
      exp.material.opacity = exp.userData.life;
      var epos = exp.geometry.attributes.position;
      var ev = exp.userData.velocities;
      for (var e = 0; e < ev.length; e++) {
        var e3 = e * 3;
        epos.array[e3] += ev[e].x;
        epos.array[e3 + 1] += ev[e].y;
        epos.array[e3 + 2] += ev[e].z;
      }
      epos.needsUpdate = true;
      if (exp.userData.life <= 0) {
        exp.geometry.dispose();
        exp.material.dispose();
        exp.parent.remove(exp);
        return false;
      }
      return true;
    });
  };

  SmartVisionScene.prototype.render = function () {
    if (this.isVisible) {
      this.renderer.render(this.scene, this.camera);
    }
  };

  /* ============================================================
     RESIZE HANDLER — Responsive viewport
     ============================================================ */
  SmartVisionScene.prototype.resize = function () {
    var w = window.innerWidth;
    var h = window.innerHeight;
    this.camera.aspect = w / h;
    this.camera.updateProjectionMatrix();
    this.renderer.setSize(w, h);
  };

  /* ============================================================
     EVENT BINDINGS — Visibility & lazy rendering
     ============================================================ */
  SmartVisionScene.prototype._bindEvents = function () {
    var self = this;

    document.addEventListener('visibilitychange', function () {
      self.isVisible = !document.hidden;
    });
  };

  SmartVisionScene.prototype.dispose = function () {
    this.renderer.dispose();
  };

  /* ============================================================
     EXPORT — Attach to global namespace
     ============================================================ */
  global.SmartVisionScene = SmartVisionScene;
  global.SVAI_PARTICLE_COUNT = PARTICLE_COUNT;

})(typeof window !== 'undefined' ? window : this);

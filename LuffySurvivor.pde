import processing.sound.*;

// ── Constantes globais ────────────────────────────────────────
final int   SCREEN_W       = 900;
final int   SCREEN_H       = 650;
final float DEFENSE_LINE_Y = SCREEN_H - 70;
final int   BASE_LIVES     = 5;

// ── Instâncias principais ─────────────────────────────────────
GameManager gm;
Player      player;

// ── Sons ──────────────────────────────────────────────────────
SoundFile gomuSound;
SoundFile bgMusic;

// ── Partículas ────────────────────────────────────────────────
ArrayList<Particle> particles;

// =============================================================
void setup() {
  size(900, 650);
  frameRate(60);
  noStroke();
  textFont(createFont("Courier New Bold", 20));
  noCursor();

  particles = new ArrayList<Particle>();
  gm        = new GameManager();
  player    = new Player(SCREEN_W / 2, SCREEN_H / 2);

  // ── Carrega som de soco ───────────────────────────────────
  try {
    gomuSound = new SoundFile(this, "gomuSound.mp3");
  } catch (Exception e) {
    println("[AUDIO] gomuSound.mp4 nao encontrado.");
    gomuSound = null;
  }

  // ── Carrega e inicia música de fundo em loop ──────────────
  try {
    bgMusic = new SoundFile(this, "music.mp3");
    bgMusic.loop();          // toca em loop contínuo
    bgMusic.amp(0.5);        // volume 50% para não sobrepor os efeitos
  } catch (Exception e) {
    println("[AUDIO] music.mp4 nao encontrado.");
    bgMusic = null;
  }
}

void draw() {
  background(15, 15, 25);
  drawGrid();
  drawDefenseLine();

  gm.update();
  gm.draw();

  updateParticles();

  // Cursor customizado visível apenas durante o jogo
  if (gm.state == GameManager.STATE_PLAYING ||
      gm.state == GameManager.STATE_UPGRADE) {
    drawCursor();
  }
}


// INPUT

void mousePressed() {
  if (mouseButton == LEFT) {
    switch (gm.state) {
      case GameManager.STATE_PLAYING:  player.triggerAttack();                    break;
      case GameManager.STATE_UPGRADE:  gm.handleUpgradeClick(mouseX, mouseY);    break;
      case GameManager.STATE_GAMEOVER: gm.reset();                                break;
      case GameManager.STATE_TITLE:    gm.startGame();                            break;
    }
  }
}

void mouseReleased() {
  if (mouseButton == LEFT) player.stopBarrage();
}

void keyPressed() {
  if (key == 'r' || key == 'R') { gm.reset(); return; }

  // Atalho de mute  [M]
  if (key == 'm' || key == 'M') {
    if (bgMusic != null) {
      if (bgMusic.isPlaying()) bgMusic.stop();
      else                     bgMusic.loop();
    }
    return;
  }

  if (gm.state == GameManager.STATE_PLAYING) {
    if (key == 'j' || key == 'J') player.activateHaki();
    if (key == 'g' || key == 'G') player.activateGear2();
  }
}

// HELPERS GLOBAIS DE DESENHO
void drawGrid() {
  stroke(30, 30, 50);
  strokeWeight(1);
  for (int x = 0; x < SCREEN_W; x += 40) line(x, 0, x, SCREEN_H);
  for (int y = 0; y < SCREEN_H; y += 40) line(0, y, SCREEN_W, y);
  noStroke();
}

void drawDefenseLine() {
  for (int i = 4; i > 0; i--) {
    stroke(200, 0, 0, 40 * i);
    strokeWeight(i * 3);
    line(0, DEFENSE_LINE_Y, SCREEN_W, DEFENSE_LINE_Y);
  }
  stroke(255, 50, 50);
  strokeWeight(2);
  line(0, DEFENSE_LINE_Y, SCREEN_W, DEFENSE_LINE_Y);
  noStroke();

  for (int i = 0; i < gm.lives; i++) {
    fill(220, 30, 30);
    ellipse(20 + i * 26, DEFENSE_LINE_Y + 18, 16, 16);
  }
  for (int i = gm.lives; i < BASE_LIVES; i++) {
    noFill();
    stroke(100, 30, 30);
    strokeWeight(1.5);
    ellipse(20 + i * 26, DEFENSE_LINE_Y + 18, 16, 16);
    noStroke();
  }
}

void drawCursor() {
  int mx = mouseX, my = mouseY;
  stroke(255, 255, 255, 160);
  strokeWeight(1);
  int cs = 8;
  line(mx - cs, my, mx + cs, my);
  line(mx, my - cs, mx, my + cs);
  noFill();
  stroke(255, 255, 255, 80);
  ellipse(mx, my, 18, 18);
  noStroke();
}


void spawnImpactParticles(float x, float y, color c) {
  for (int i = 0; i < 8; i++) particles.add(new Particle(x, y, c, false));
}

void spawnFireParticles(float x, float y) {
  for (int i = 0; i < 5; i++) particles.add(new Particle(x, y, color(255, 120, 20), true));
}

void updateParticles() {
  for (int i = particles.size() - 1; i >= 0; i--) {
    Particle p = particles.get(i);
    p.update();
    p.draw();
    if (p.isDead()) particles.remove(i);
  }
}

// SOM
void playGomuSound() {
  if (gomuSound == null) return;
  try {
    gomuSound.stop();
    gomuSound.play();
  } catch (Exception e) {
    println("[AUDIO] Erro ao tocar gomuSound: " + e.getMessage());
  }
}

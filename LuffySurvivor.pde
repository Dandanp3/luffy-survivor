// Constantes globais
final int   SCREEN_W        = 900;
final int   SCREEN_H        = 650;
final float DEFENSE_LINE_Y  = SCREEN_H - 70;   // Y da linha de defesa
final int   BASE_LIVES      = 5;

// Instancias principais 
GameManager gm;
Player      player;

// particulas de efeito
ArrayList<Particle> particles;

void setup() {
  size(900, 650);
  frameRate(60);
  noStroke();
  textFont(createFont("Courier New Bold", 20));

  particles = new ArrayList<Particle>();
  gm        = new GameManager();
  player    = new Player(SCREEN_W / 2, SCREEN_H / 2);
}


void draw() {
  // Fundo 
  background(15, 15, 25);
  drawGrid();

  // Linha de defesa 
  drawDefenseLine();

  // Atualiza e desenha com base no estado do jogo 
  gm.update();
  gm.draw();

  // Particulas 
  updateParticles();
}

// INPUT
void mousePressed() {
  if (mouseButton == LEFT) {
    if (gm.state == GameManager.STATE_PLAYING) {
      player.triggerAttack();
    } else if (gm.state == GameManager.STATE_GAMEOVER) {
      gm.reset();
    } else if (gm.state == GameManager.STATE_TITLE) {
      gm.startGame();
    }
  }
}

void keyPressed() {
  // Tecla R reinicia a qualquer momento
  if (key == 'r' || key == 'R') {
    gm.reset();
  }
}

// HELPERS DE DESENHO GLOBAIS

// Grade de fundo 
void drawGrid() {
  stroke(30, 30, 50);
  strokeWeight(1);
  for (int x = 0; x < SCREEN_W; x += 40) line(x, 0, x, SCREEN_H);
  for (int y = 0; y < SCREEN_H; y += 40) line(0, y, SCREEN_W, y);
  noStroke();
}

// Linha vermelha horizontal
void drawDefenseLine() {
  // Brilho/glow
  for (int i = 4; i > 0; i--) {
    stroke(200, 0, 0, 40 * i);
    strokeWeight(i * 3);
    line(0, DEFENSE_LINE_Y, SCREEN_W, DEFENSE_LINE_Y);
  }

  stroke(255, 50, 50);
  strokeWeight(2);
  line(0, DEFENSE_LINE_Y, SCREEN_W, DEFENSE_LINE_Y);
  noStroke();

  // icones de vida 
  for (int i = 0; i < gm.lives; i++) {
    fill(220, 30, 30);
    ellipse(20 + i * 26, DEFENSE_LINE_Y + 18, 16, 16);
  }
  // Vidas perdidas 
  for (int i = gm.lives; i < BASE_LIVES; i++) {
    noFill();
    stroke(100, 30, 30);
    strokeWeight(1.5);
    ellipse(20 + i * 26, DEFENSE_LINE_Y + 18, 16, 16);
    noStroke();
  }
}

// spawna particulas de impacto 
void spawnImpactParticles(float x, float y, color c) {
  for (int i = 0; i < 8; i++) {
    particles.add(new Particle(x, y, c));
  }
}


void updateParticles() {
  for (int i = particles.size() - 1; i >= 0; i--) {
    Particle p = particles.get(i);
    p.update();
    p.draw();
    if (p.isDead()) particles.remove(i);
  }
}

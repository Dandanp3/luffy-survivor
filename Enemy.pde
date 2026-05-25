class Enemy {

  // Posição e tamanho 
  float x, y;
  final float SIZE = 32;

  // Movimento 
  float speedY;           // velocidade de descida (px/frame)
  float trackStrength;    // 0..1 quanto segue o jogador horizontalmente

  // HP 
  int maxHP;
  int currentHP;

  // Estado 
  boolean alive = true;

  // Visual 
  color bodyColor  = color(40, 100, 220);   // azul
  color hpBarFull  = color(50, 220, 80);
  color hpBarEmpty = color(180, 40, 40);

  // Flash de dano 
  int   damageFlashTimer = 0;
  final int FLASH_DURATION = 8;

  // ID único para o HashSet de colisão 

  Enemy(float startX, int hp, float spd, float track) {
    x            = startX;
    y            = -SIZE / 2;   // começa acima da tela
    maxHP        = hp;
    currentHP    = hp;
    speedY       = spd;
    trackStrength = track;
  }

  void update(float playerX) {
    // Descida vertical
    y += speedY;

    // Tracking horizontal suave
    float dx = playerX - x;
    x += dx * trackStrength;

    // dx dentro dos limites horizontais
    x = constrain(x, SIZE / 2, SCREEN_W - SIZE / 2);

    // Decrementa flash
    if (damageFlashTimer > 0) damageFlashTimer--;
  }

  void draw() {
    if (!alive) return;

    // Sombra sutil
    fill(0, 0, 0, 60);
    noStroke();
    rectMode(CENTER);
    rect(x + 3, y + 4, SIZE, SIZE, 3);

    // Corpo — pisca branco ao receber dano
    color drawColor = (damageFlashTimer > 0 && damageFlashTimer % 3 < 2)
                      ? color(255, 255, 255)
                      : bodyColor;
    fill(drawColor);
    rect(x, y, SIZE, SIZE, 3);

    // Detalhe: "olhos" (dois pontos brancos)
    fill(255, 255, 255, 180);
    ellipse(x - 6, y - 5, 5, 5);
    ellipse(x + 6, y - 5, 5, 5);

    // Barra de HP 
    if (currentHP < maxHP) drawHPBar();

    rectMode(CORNER);
  }

  void drawHPBar() {
    float barW    = SIZE + 4;
    float barH    = 5;
    float barX    = x - barW / 2;
    float barY    = y - SIZE / 2 - 10;
    float fillW   = barW * ((float) currentHP / maxHP);

    // Fundo
    fill(60, 60, 60);
    rect(barX, barY, barW, barH, 2);

    // Preenchimento 
    float t = (float) currentHP / maxHP;
    color barColor = lerpColor(hpBarEmpty, hpBarFull, t);
    fill(barColor);
    rect(barX, barY, fillW, barH, 2);
  }

  boolean takeDamage(int dmg) {
    if (!alive) return false;
    currentHP -= dmg;
    damageFlashTimer = FLASH_DURATION;

    if (currentHP <= 0) {
      currentHP = 0;
      alive     = false;
      // Spawna partículas de morte
      spawnImpactParticles(x, y, bodyColor);
      return true;
    }
    // Spawna partículas menores de hit
    spawnImpactParticles(x, y, color(180, 200, 255));
    return false;
  }

  boolean crossedLine() {
    return y >= DEFENSE_LINE_Y;
  }

  boolean isAlive() { return alive; }
}

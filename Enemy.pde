class Enemy {

  float x, y;
  float SIZE;

  float speedY;
  float trackStrength;
  float baseSpeedY;  // guarda velocidade original para restaurar após stun

  int maxHP, currentHP;
  boolean alive  = true;
  boolean isBoss = false;

  color bodyColor;
  color hpBarFull  = color(50, 220, 80);
  color hpBarEmpty = color(180, 40, 40);

  int   damageFlashTimer = 0;
  final int FLASH_DUR    = 8;

  // Stun
  float stunTimer  = 0;   // frames restantes de stun
  float stunAngle  = 0;   // ângulo de rotação do cubo stunado

  Enemy(float sx, int hp, float spd, float track, boolean boss) {
    x             = sx;
    y             = boss ? -40 : -20;
    maxHP         = hp;
    currentHP     = hp;
    speedY        = spd;
    baseSpeedY    = spd;
    trackStrength = track;
    isBoss        = boss;

    if (boss) {
      SIZE      = 64;
      bodyColor = color(120, 20, 160);
    } else {
      SIZE      = 32;
      bodyColor = color(40, 100, 220);
    }
  }

  void update(float playerX) {
    // Stun: decrementa sempre dentro do update (não depende do player)
    if (stunTimer > 0) {
      stunTimer--;
      stunAngle += 0.18;
      // Stunado: desce em velocidade reduzida (evita ficar preso fora da tela)
      y += baseSpeedY * 0.3;
    } else {
      y += baseSpeedY;
      x += (playerX - x) * trackStrength;
      x = constrain(x, SIZE/2, SCREEN_W - SIZE/2);
    }

    if (damageFlashTimer > 0) damageFlashTimer--;
  }

  // Mantido por compatibilidade (não faz mais nada, update já cuida)
  void updateStun() {}

  void applyStun() {
    // stunDuration vem do JohnnyPlayer, mas como Enemy não tem referência,
    // o NailShot passa o valor ao chamar o método
    applyStun(60);
  }

  void applyStun(float frames) {
    stunTimer = frames;
    stunAngle = 0;
  }

  void draw() {
    if (!alive) return;

    pushMatrix();
    translate(x, y);
    if (stunTimer > 0) rotate(stunAngle);

    // Sombra
    fill(0, 0, 0, 60);
    noStroke();
    rectMode(CENTER);
    rect(3, 4, SIZE, SIZE, isBoss ? 8 : 3);

    // Corpo
    color dc = (damageFlashTimer > 0 && damageFlashTimer % 3 < 2)
               ? color(255) : bodyColor;
    fill(dc);
    rect(0, 0, SIZE, SIZE, isBoss ? 8 : 3);

    // Olhos
    if (isBoss) {
      fill(220, 0, 0, 200);
      ellipse(-12, -10, 10, 10);
      ellipse(12, -10, 10, 10);
      fill(255, 200, 0);
      // Coroa
      triangle(-20, -SIZE/2, 0, -SIZE/2 - 14, 20, -SIZE/2);
    } else {
      fill(255, 255, 255, 180);
      ellipse(-6, -5, 5, 5);
      ellipse(6, -5, 5, 5);
    }

    // Estrelinhas de stun girando acima
    if (stunTimer > 0) {
      float sr = SIZE/2 + 12;
      fill(255, 230, 0);
      for (int i = 0; i < 3; i++) {
        float sa = stunAngle + i * TWO_PI / 3;
        ellipse(cos(sa) * sr, sin(sa) * sr - SIZE/2 - 4, 7, 7);
      }
    }

    popMatrix();

    // Barra de HP (fora do pushMatrix para não rotacionar)
    drawHPBar();
    rectMode(CORNER);
  }

  void drawHPBar() {
    float barW  = SIZE + (isBoss ? 20 : 4);
    float barH  = isBoss ? 8 : 5;
    float barX  = x - barW/2;
    float barY  = y - SIZE/2 - (isBoss ? 14 : 10);
    float fillW = barW * ((float) currentHP / maxHP);

    noStroke();
    fill(60, 60, 60);
    rectMode(CORNER);
    rect(barX, barY, barW, barH, 2);
    fill(lerpColor(hpBarEmpty, hpBarFull, (float) currentHP / maxHP));
    rect(barX, barY, fillW, barH, 2);

    if (isBoss) {
      fill(255);
      textSize(10);
      textAlign(CENTER, CENTER);
      text(currentHP + "/" + maxHP, x, barY + barH/2);
      textAlign(LEFT, BASELINE);
    }
  }

  boolean takeDamage(int dmg) {
    if (!alive) return false;
    currentHP -= dmg;
    damageFlashTimer = FLASH_DUR;
    if (currentHP <= 0) {
      currentHP = 0;
      alive     = false;
      spawnImpactParticles(x, y, bodyColor);
      if (isBoss) {
        for (int i = 0; i < 3; i++)
          spawnImpactParticles(x + random(-20,20), y + random(-20,20), bodyColor);
        spawnFireParticles(x, y);
      }
      return true;
    }
    spawnImpactParticles(x, y, isBoss ? color(180,100,220) : color(180,200,255));
    return false;
  }

  boolean crossedLine() { return y >= DEFENSE_LINE_Y; }
  boolean isAlive()     { return alive; }
  boolean isStunned()   { return stunTimer > 0; }
}

class Enemy {

  float x, y;
  float SIZE;

  float speedY;
  float trackStrength;

  int maxHP, currentHP;
  boolean alive  = true;
  boolean isBoss = false;

  // Cores por tipo
  color bodyColor;
  color hpBarFull  = color(50, 220, 80);
  color hpBarEmpty = color(180, 40, 40);

  int   damageFlashTimer = 0;
  final int FLASH_DUR    = 8;

  Enemy(float sx, int hp, float spd, float track, boolean boss) {
    x            = sx;
    y            = boss ? -40 : -20;
    maxHP        = hp;
    currentHP    = hp;
    speedY       = spd;
    trackStrength = track;
    isBoss       = boss;

    if (boss) {
      SIZE      = 64;
      bodyColor = color(120, 20, 160);  // roxo escuro
    } else {
      SIZE      = 32;
      bodyColor = color(40, 100, 220);  // azul
    }
  }

  void update(float playerX) {
    y += speedY;
    x += (playerX - x) * trackStrength;
    x = constrain(x, SIZE/2, SCREEN_W - SIZE/2);
    if (damageFlashTimer > 0) damageFlashTimer--;
  }

  void draw() {
    if (!alive) return;

    // Sombra
    fill(0, 0, 0, 60);
    noStroke();
    rectMode(CENTER);
    rect(x + 3, y + 4, SIZE, SIZE, isBoss ? 8 : 3);

    // Corpo
    color dc = (damageFlashTimer > 0 && damageFlashTimer % 3 < 2)
               ? color(255, 255, 255) : bodyColor;
    fill(dc);
    rect(x, y, SIZE, SIZE, isBoss ? 8 : 3);

    // Brilho nos olhos (boss tem olhos maiores e vermelhos)
    if (isBoss) {
      fill(220, 0, 0, 200);
      ellipse(x - 12, y - 10, 10, 10);
      ellipse(x + 12, y - 10, 10, 10);
      // Coroa de boss
      fill(255, 200, 0);
      triangle(x - 20, y - SIZE/2,
               x,      y - SIZE/2 - 14,
               x + 20, y - SIZE/2);
    } else {
      fill(255, 255, 255, 180);
      ellipse(x - 6, y - 5, 5, 5);
      ellipse(x + 6, y - 5, 5, 5);
    }

    // Barra de HP
    drawHPBar();
    rectMode(CORNER);
  }

  void drawHPBar() {
    float barW  = SIZE + (isBoss ? 20 : 4);
    float barH  = isBoss ? 8 : 5;
    float barX  = x - barW/2;
    float barY  = y - SIZE/2 - (isBoss ? 14 : 10);
    float fillW = barW * ((float) currentHP / maxHP);

    fill(60, 60, 60);
    rect(barX, barY, barW, barH, 2);

    float t = (float) currentHP / maxHP;
    fill(lerpColor(hpBarEmpty, hpBarFull, t));
    rect(barX, barY, fillW, barH, 2);

    // Label HP no boss
    if (isBoss) {
      fill(255);
      textSize(10);
      textAlign(CENTER, CENTER);
      text(currentHP + " / " + maxHP, x, barY + barH/2);
      textAlign(LEFT, BASELINE);
    }
  }

  //Aplica dano. Retorna true se morreu
  boolean takeDamage(int dmg) {
    if (!alive) return false;
    currentHP -= dmg;
    damageFlashTimer = FLASH_DUR;
    if (currentHP <= 0) {
      currentHP = 0;
      alive     = false;
      spawnImpactParticles(x, y, bodyColor);
      if (isBoss) {
        // Explosão maior no boss
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
}

/**
 * TuskCompanion.pde — O Tusk ao lado do Johnny
 *
 * Fica no lado direito do Johnny como cubinho.
 * Muda de aparência com cada Act.
 * No Act 4: pode entrar em modo ULTIMATE (vontade de Gyro),
 *   saindo do lado do Johnny e atacando inimigos em barrage autônomo.
 *
 * Acts:
 *   1 = rosa pequeno, olhinhos, estrelas amarelas
 *   2 = rosa robótico com esferas azuis
 *   3 = rosa mecânico com garras e antena
 *   4 = rosa metálico grande com esporas/pingentes
 */
class TuskCompanion {

  int act = 1;

  // Posição ao lado do Johnny
  float x, y;
  float ownerX, ownerY;

  // Ultimate (Act 4)
  boolean ultimateActive = false;
  float   ultimateTimer  = 0;   // frames restantes
  float   ultimateDur    = 0;   // duração total em frames
  float   ultimateCooldown = 0;
  final float ULT_COOLDOWN = 3600;  // 60s

  // Durante a ultimate: alvo atual
  Enemy   ultTarget     = null;
  int     ultPunchTimer = 0;
  final int ULT_PUNCH_INTERVAL = 5;   // frames entre cada soco da barrage
  int     ultDamage     = 0;

  // Animação de voo até alvo
  boolean flyingToTarget = false;
  float   flyX, flyY;   // posição atual enquanto voa

  // Animação de flutuação (bobbing)
  float bobOffset = 0;

  // Cor base por act
  color baseColor() {
    switch (act) {
      case 1: return color(230, 130, 160);
      case 2: return color(200, 100, 160);
      case 3: return color(210, 80, 140);
      case 4: return color(220, 100, 150);
      default: return color(220, 120, 160);
    }
  }

  TuskCompanion() { flyX = 0; flyY = 0; }

  void update(float jx, float jy, ArrayList<Enemy> enemies, int dmg) {
    ownerX = jx;
    ownerY = jy;
    bobOffset = sin(frameCount * 0.08) * 4;
    ultDamage = dmg + act;  // Tusk tem bônus de dano por act

    if (ultimateCooldown > 0) ultimateCooldown--;

    if (ultimateActive) {
      updateUltimate(enemies);
    } else {
      // Posição normal: direita do Johnny
      x = jx + 44;
      y = jy + bobOffset;
    }
  }

  void updateUltimate(ArrayList<Enemy> enemies) {
    ultimateTimer--;

    // Seleciona alvo: inimigo mais próximo da linha de defesa
    if (ultTarget == null || !ultTarget.isAlive()) {
      ultTarget = findClosestToLine(enemies);
      if (ultTarget == null) {
        // Sem inimigos visíveis, aguarda
        flyX = ownerX + 44;
        flyY = ownerY;
        return;
      }
      flyingToTarget = true;
    }

    // Voa até o alvo
    if (flyingToTarget) {
      float dx = ultTarget.x - flyX;
      float dy = ultTarget.y - flyY;
      float d  = dist(flyX, flyY, ultTarget.x, ultTarget.y);
      if (d < 6) {
        flyingToTarget = false;
      } else {
        flyX += (dx / d) * 12;
        flyY += (dy / d) * 12;
      }
    }

    // Chegou: barrage
    if (!flyingToTarget && ultTarget != null && ultTarget.isAlive()) {
      x = ultTarget.x + sin(frameCount * 0.5) * 10;
      y = ultTarget.y - 4 + bobOffset;

      ultPunchTimer++;
      if (ultPunchTimer >= ULT_PUNCH_INTERVAL) {
        ultPunchTimer = 0;
        boolean killed = ultTarget.takeDamage(ultDamage);
        spawnImpactParticles(ultTarget.x + random(-8,8), ultTarget.y + random(-8,8),
                             color(255, 180, 60));
        spawnFireParticles(ultTarget.x, ultTarget.y - 10);
        if (killed) {
          ultTarget = null;
          flyingToTarget = false;
        }
      }
    } else if (!flyingToTarget) {
      flyX = ownerX + 44;
      flyY = ownerY;
    }

    x = flyingToTarget ? flyX : x;
    y = flyingToTarget ? flyY : y;

    // Fim da ultimate
    if (ultimateTimer <= 0) {
      endUltimate();
    }
  }

  void draw() {
    switch (act) {
      case 1: drawAct1(); break;
      case 2: drawAct2(); break;
      case 3: drawAct3(); break;
      case 4: drawAct4(); break;
    }

    // Aura da ultimate
    if (ultimateActive) {
      noFill();
      for (int i = 3; i > 0; i--) {
        stroke(255, 180, 50, 50 * i);
        strokeWeight(i * 2);
        ellipse(x, y, 50 + i*8, 50 + i*8);
      }
      noStroke();
    }
  }

  // Act 1 — cubinho rosa com estrelas e coração
  void drawAct1() {
    float s = 24;
    rectMode(CENTER);
    // Orelhas
    fill(baseColor());
    rect(x - s/2 - 4, y - 6, 8, 14, 3);
    rect(x + s/2 - 4, y - 6, 8, 14, 3);
    // Corpo
    fill(baseColor());
    rect(x, y, s, s, 5);
    // Estrela amarela
    fill(255, 210, 0);
    drawStar5(x, y - 3, 6, 3);
    // Olhos
    fill(60, 100, 220);
    ellipse(x - 5, y + 3, 5, 5);
    ellipse(x + 5, y + 3, 5, 5);
    // Bico
    fill(150, 90, 60);
    triangle(x - 3, y + 7, x + 3, y + 7, x, y + 11);
    // Corações pequenos embaixo
    fill(220, 60, 80);
    drawHeart(x - 6, y + s/2 + 6, 5);
    drawHeart(x + 6, y + s/2 + 6, 5);
    rectMode(CORNER);
  }

  // Act 2 — robótico com esferas azuis
  void drawAct2() {
    float s = 30;
    rectMode(CENTER);
    // Esferas azuis laterais (braços)
    fill(40, 80, 200);
    ellipse(x - s/2 - 10, y - 4, 18, 18);
    ellipse(x + s/2 + 10, y - 4, 18, 18);
    // Corpo rosa
    fill(baseColor());
    rect(x, y, s, s, 4);
    // Grade no rosto
    stroke(160, 60, 100);
    strokeWeight(1);
    line(x - 8, y - 2, x + 8, y - 2);
    line(x - 4, y - 8, x - 4, y + 4);
    line(x + 4, y - 8, x + 4, y + 4);
    noStroke();
    // Olhos
    fill(20, 20, 20);
    ellipse(x - 5, y - 4, 6, 6);
    ellipse(x + 5, y - 4, 6, 6);
    // Antenas
    fill(200, 100, 150);
    rect(x - 5, y - s/2 - 8, 4, 10, 2);
    rect(x + 5, y - s/2 - 8, 4, 10, 2);
    // Estrelas
    fill(255, 210, 0);
    drawStar5(x, y + 5, 5, 3);
    rectMode(CORNER);
  }

  // Act 3 — mecânico pesado com garras e antena grande
  void drawAct3() {
    float s = 34;
    rectMode(CENTER);
    // Corpo principal
    fill(baseColor());
    rect(x, y, s, s, 3);
    // Ombros
    fill(180, 70, 120);
    rect(x - s/2 - 6, y - 4, 10, 18, 3);
    rect(x + s/2 - 4, y - 4, 10, 18, 3);
    // Garras (triângulos)
    fill(160, 60, 100);
    triangle(x - s/2 - 8, y + 14, x - s/2 - 2, y + 14, x - s/2 - 5, y + 22);
    triangle(x + s/2 + 2, y + 14, x + s/2 + 8, y + 14, x + s/2 + 5, y + 22);
    // Antena
    stroke(200, 200, 100);
    strokeWeight(2);
    line(x, y - s/2, x, y - s/2 - 12);
    noStroke();
    fill(255, 220, 0);
    ellipse(x, y - s/2 - 14, 7, 7);
    // Olhos (dois pontos brancos + pupila)
    fill(220, 220, 220);
    ellipse(x - 7, y - 3, 8, 8);
    ellipse(x + 7, y - 3, 8, 8);
    fill(0);
    ellipse(x - 6, y - 2, 4, 4);
    ellipse(x + 8, y - 2, 4, 4);
    // Estrelas
    fill(255, 210, 0);
    drawStar5(x, y + 8, 5, 3);
    rectMode(CORNER);
  }

  // Act 4 — metálico grande com esporas/pingentes
  void drawAct4() {
    float s = 40;
    rectMode(CENTER);
    // Brilho metálico (aura dourada)
    for (int i = 2; i > 0; i--) {
      fill(255, 200, 50, 25 * i);
      rect(x, y, s + i*8, s + i*8, 6);
    }
    // Ombros grandes
    fill(190, 80, 130);
    rect(x - s/2 - 8, y - 6, 14, 22, 4);
    rect(x + s/2 - 6, y - 6, 14, 22, 4);
    // Corpo principal
    fill(baseColor());
    rect(x, y, s, s, 4);
    // Ferradura no peito (símbolo do Johnny)
    noFill();
    stroke(220, 200, 50);
    strokeWeight(3);
    arc(x, y + 4, 24, 20, PI, TWO_PI);
    noStroke();
    // Pingentes/esporas embaixo
    fill(200, 90, 140);
    for (int i = -2; i <= 2; i++) {
      ellipse(x + i * 8, y + s/2 + 7, 8, 12);
      fill(180, 70, 120);
      triangle(x + i*8 - 3, y + s/2 + 10, x + i*8 + 3, y + s/2 + 10, x + i*8, y + s/2 + 16);
      fill(200, 90, 140);
    }
    // Olhos
    fill(255, 60, 60);
    ellipse(x - 9, y - 4, 9, 9);
    ellipse(x + 9, y - 4, 9, 9);
    fill(20, 0, 0);
    ellipse(x - 8, y - 3, 5, 5);
    ellipse(x + 10, y - 3, 5, 5);
    // Estrelas douradas
    fill(255, 200, 0);
    drawStar5(x - 10, y + 8, 5, 3);
    drawStar5(x + 10, y + 8, 5, 3);
    rectMode(CORNER);
  }

  // Ativa a ultimate (Act 4 apenas)
  void activateUltimate(ArrayList<Enemy> enemies) {
    if (act < 4 || ultimateActive || ultimateCooldown > 0) return;
    ultimateActive = true;
    ultimateDur    = soundManager.ultimateDuration() * 60;
    ultimateTimer  = ultimateDur;
    ultTarget      = null;
    flyingToTarget = false;
    flyX = x;
    flyY = y;

    // Fade out da música
    fadeMusicOut(0.05);
    soundManager.play(soundManager.johnnyUltimate);
  }

  void endUltimate() {
    ultimateActive   = false;
    ultimateCooldown = ULT_COOLDOWN;
    ultTarget        = null;
    x = ownerX + 44;
    y = ownerY;
    fadeMusicIn();
  }

  // Inimigo mais próximo da linha de defesa e visível
  Enemy findClosestToLine(ArrayList<Enemy> enemies) {
    Enemy best = null;
    float bestDist = 9999;
    for (Enemy e : enemies) {
      if (!e.isAlive()) continue;
      if (e.y < 0 || e.y > SCREEN_H) continue;  // só visíveis
      float d = abs(e.y - DEFENSE_LINE_Y);
      if (d < bestDist) { bestDist = d; best = e; }
    }
    return best;
  }

  boolean isUltimateActive() { return ultimateActive; }

  // Helpers geométricos
  void drawStar5(float cx, float cy, float r1, float r2) {
    float a = -HALF_PI;
    float step = TWO_PI / 5;
    beginShape();
    for (int i = 0; i < 5; i++) {
      vertex(cx + cos(a) * r1, cy + sin(a) * r1);
      a += step / 2;
      vertex(cx + cos(a) * r2, cy + sin(a) * r2);
      a += step / 2;
    }
    endShape(CLOSE);
  }

  void drawHeart(float hx, float hy, float s) {
    beginShape();
    vertex(hx, hy + s * 0.3);
    bezierVertex(hx - s, hy - s * 0.5, hx - s * 1.5, hy + s * 0.8, hx, hy + s * 1.5);
    bezierVertex(hx + s * 1.5, hy + s * 0.8, hx + s, hy - s * 0.5, hx, hy + s * 0.3);
    endShape(CLOSE);
  }
}

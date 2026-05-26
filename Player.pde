class Player {

  final float W = 34, H = 34;
  float x, y;

  boolean nextArmIsLeft = false;
  ArmAttack currentAttack = null;

  // Visual
  color bodyColor = color(220, 30, 30);
  color hatColor  = color(210, 170, 30);

  // Flash de dano
  int hitFlashTimer = 0;
  final int HIT_FLASH_DUR = 15;

  // Haki
  boolean hakiUnlocked  = false;
  boolean hakiActive    = false;
  float   hakiDuration  = 600;
  float   hakiTimer     = 0;
  float   hakiCooldown  = 0;
  final float HAKI_COOLDOWN_FRAMES = 1500;
  final float HAKI_LEVEL_BONUS     = 90;

  // Gear 2
  boolean gear2Unlocked = false;
  boolean gear2Active   = false;
  float   gear2Duration = 600;
  float   gear2Timer    = 0;
  float   gear2Cooldown = 0;
  final float GEAR2_COOLDOWN_FRAMES = 1500;
  final float GEAR2_LEVEL_BONUS     = 90;

  // Barrage - segurar M1 com Gear 2 ativo
  boolean barrageHeld      = false;
  int     barrageFireTimer = 0;
  final int BARRAGE_INTERVAL = 6;

  // Dano base (aumentado pelo upgrade)
  int baseDamage = 1;

  Player(float sx, float sy) { x = sx; y = sy; }

  void update() {
    x = constrain(mouseX, W / 2, SCREEN_W - W / 2);
    y = constrain(mouseY, H / 2, DEFENSE_LINE_Y - H / 2);

    // Timer do Haki
    if (hakiActive) {
      hakiTimer--;
      if (hakiTimer <= 0) { hakiActive = false; hakiCooldown = HAKI_COOLDOWN_FRAMES; }
    } else if (hakiCooldown > 0) {
      hakiCooldown--;
    }

    // Timer do Gear 2
    if (gear2Active) {
      gear2Timer--;
      if (gear2Timer <= 0) { gear2Active = false; gear2Cooldown = GEAR2_COOLDOWN_FRAMES; }
      if (frameCount % 8 == 0) spawnFireParticles(x + random(-10, 10), y + random(-10, 10));
    } else if (gear2Cooldown > 0) {
      gear2Cooldown--;
    }

    // Barrage automático ao segurar M1 com Gear 2
    if (gear2Active && barrageHeld) {
      barrageFireTimer++;
      if (barrageFireTimer >= BARRAGE_INTERVAL) {
        barrageFireTimer = 0;
        fireArm();
      }
    }

    // Atualiza ataque ativo
    if (currentAttack != null) {
      currentAttack.update();
      if (currentAttack.isFinished()) currentAttack = null;
    }

    if (hitFlashTimer > 0) hitFlashTimer--;
  }

  void draw() {
    if (currentAttack != null) currentAttack.draw();

    // Corpo - pisca branco ao tomar dano
    color bc = (hitFlashTimer > 0 && hitFlashTimer % 4 < 2)
               ? color(255, 255, 255) : bodyColor;
    fill(bc);
    rectMode(CENTER);
    rect(x, y, W, H, 4);

    // Chapéu de palha
    fill(hatColor);
    rect(x, y - H/2 - 4, W + 8, 6, 2);

    // Ponto indicando qual braço ataca a seguir
    float dotX = nextArmIsLeft ? x - W/2 - 6 : x + W/2 + 6;
    fill(255, 204, 153, 180);
    ellipse(dotX, y, 7, 7);

    // Aura do Haki (anel preto)
    if (hakiActive) {
      noFill();
      for (int i = 3; i > 0; i--) {
        stroke(0, 0, 0, 60 * i);
        strokeWeight(i * 2.5);
        ellipse(x, y, W + 20 + i*4, H + 20 + i*4);
      }
      noStroke();
    }

    // Aura do Gear 2 (vapor rosa)
    if (gear2Active) {
      noFill();
      for (int i = 2; i > 0; i--) {
        stroke(255, 80, 80, 40 * i);
        strokeWeight(i * 3);
        ellipse(x, y, W + 14 + i*6, H + 14 + i*6);
      }
      noStroke();
    }

    rectMode(CORNER);
  }

  void triggerAttack() {
    if (gear2Active) {
      barrageHeld = true;
      barrageFireTimer = BARRAGE_INTERVAL;
    } else {
      if (currentAttack == null) fireArm();
    }
  }

  void stopBarrage() { barrageHeld = false; }

  void fireArm() {
    if (currentAttack == null || currentAttack.isFinished()) {
      currentAttack = new ArmAttack(this, nextArmIsLeft);
      nextArmIsLeft = !nextArmIsLeft;
      playGomuSound();
    }
  }

  void activateHaki() {
    if (!hakiUnlocked || hakiActive || hakiCooldown > 0) return;
    hakiActive = true;
    hakiTimer  = hakiDuration;
  }

  void activateGear2() {
    if (!gear2Unlocked || gear2Active || gear2Cooldown > 0) return;
    gear2Active = true;
    gear2Timer  = gear2Duration;
  }

  // Dano total considerando bônus dos poderes ativos
  int getTotalDamage() {
    float dmg = baseDamage;
    if (hakiActive)  dmg *= 1.5;
    if (gear2Active) dmg *= 1.4;
    return max(1, (int) dmg);
  }

  // Cor do braço conforme poderes ativos
  color getArmColor() {
    if (hakiActive && gear2Active) return color(30, 10, 10);
    if (hakiActive)                return color(20, 20, 20);
    if (gear2Active)               return color(255, 100, 110);
    return color(255, 204, 153);
  }

  void triggerHitFlash() { hitFlashTimer = HIT_FLASH_DUR; }
  ArmAttack getAttack()  { return currentAttack; }
}

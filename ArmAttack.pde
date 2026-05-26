class ArmAttack {

  static final int STRETCHING = 0;
  static final int RETRACTING = 1;
  static final int FINISHED   = 2;
  int phase = STRETCHING;

  Player owner;
  boolean isLeft;

  final float ARM_W      = 18;
  final float MAX_LENGTH = 220;
  float currentLength    = 0;

  // Velocidades — ajustadas dinamicamente pelo Gear 2
  float stretchSpeed;
  float retractSpeed;

  // Guarda o estado dos poderes no momento do disparo
  boolean wasGear2;
  boolean wasHaki;

  // Cor do braço — fixada no momento do disparo
  color armColor;
  color fistColor;

  // Anti-hit duplo: lista de referências diretas
  ArrayList<Enemy> hitEnemies = new ArrayList<Enemy>();

  ArmAttack(Player owner, boolean isLeft) {
    this.owner  = owner;
    this.isLeft = isLeft;

    wasGear2 = owner.gear2Active;
    wasHaki  = owner.hakiActive;

    // Gear 2: socos bem mais rápidos
    stretchSpeed = wasGear2 ? 38 : 18;
    retractSpeed = wasGear2 ? 52 : 26;

    armColor  = owner.getArmColor();
    fistColor = wasHaki ? color(10, 10, 10) : color(240, 160, 90);
    if (wasGear2 && !wasHaki) fistColor = color(230, 60, 70);
  }

  void update() {
    switch (phase) {
      case STRETCHING:
        currentLength += stretchSpeed;
        if (currentLength >= MAX_LENGTH) {
          currentLength = MAX_LENGTH;
          phase = RETRACTING;
          hitEnemies.clear();
        }
        break;
      case RETRACTING:
        currentLength -= retractSpeed;
        if (currentLength <= 0) {
          currentLength = 0;
          phase = FINISHED;
        }
        break;
    }
  }

  void draw() {
    if (phase == FINISHED) return;

    float offsetX = isLeft ? -owner.W/2 - ARM_W/2 : owner.W/2 + ARM_W/2;
    float armX    = owner.x + offsetX;
    float armTopY = owner.y - currentLength;

    // Glow / sombra
    color glowC = wasHaki ? color(0,0,0) : wasGear2 ? color(255,80,80) : color(255,204,153);
    for (int i = 3; i > 0; i--) {
      fill(red(glowC), green(glowC), blue(glowC), 25 * i);
      noStroke();
      rectMode(CORNER);
      rect(armX - ARM_W/2 - i, armTopY - i, ARM_W + i*2, currentLength + i*2, 6);
    }

    // Corpo do braço
    fill(armColor);
    noStroke();
    rectMode(CORNER);
    rect(armX - ARM_W/2, armTopY, ARM_W, currentLength, 6);

    // Punho
    fill(fistColor);
    float fs = ARM_W + 4;
    rectMode(CENTER);
    rect(armX, armTopY, fs, fs, 4);

    // Anel de impacto no punho (Gear 2)
    if (wasGear2 && phase == STRETCHING && currentLength > MAX_LENGTH * 0.8) {
      noFill();
      stroke(255, 120, 50, 160);
      strokeWeight(2);
      ellipse(armX, armTopY, fs + 12, fs + 12);
      noStroke();
    }

    // Label debug
    fill(255, 255, 255, 60);
    textSize(9);
    textAlign(CENTER, CENTER);
    text(isLeft ? "L" : "R", armX, armTopY - 10);
    rectMode(CORNER);
    textAlign(LEFT, BASELINE);
  }

  boolean checkHit(Enemy e) {
    if (phase == FINISHED) return false;
    for (int i = 0; i < hitEnemies.size(); i++)
      if (hitEnemies.get(i) == e) return false;

    float offsetX  = isLeft ? -owner.W/2 - ARM_W/2 : owner.W/2 + ARM_W/2;
    float armX     = owner.x + offsetX;
    float armTopY  = owner.y - currentLength;

    boolean overlap =
      (armX + ARM_W/2) > (e.x - e.SIZE/2) &&
      (armX - ARM_W/2) < (e.x + e.SIZE/2) &&
      owner.y          > (e.y - e.SIZE/2) &&
      armTopY          < (e.y + e.SIZE/2);

    if (overlap) {
      hitEnemies.add(e);

      // Partículas de fogo se Gear 2
      if (wasGear2) spawnFireParticles(e.x, e.y);

      return true;
    }
    return false;
  }

  boolean isFinished() { return phase == FINISHED; }
  boolean isActive()   { return phase != FINISHED && currentLength > 5; }
}

class ArmAttack {

  //  Fases do ataque 
  static final int STRETCHING = 0;
  static final int RETRACTING = 1;
  static final int FINISHED   = 2;

  int phase = STRETCHING;

  // Referência ao jogador
  Player owner;

  // Lado de origem 
  boolean isLeft;

  // Dimensões
  final float ARM_W      = 18;
  final float MAX_LENGTH = 220;
  float currentLength    = 0;

  // Velocidades 
  final float STRETCH_SPEED = 18;
  final float RETRACT_SPEED = 26;

  // Visual
  color armColor  = color(255, 204, 153);
  color fistColor = color(240, 160, 90);

  ArrayList<Enemy> hitEnemies = new ArrayList<Enemy>();

  ArmAttack(Player owner, boolean isLeft) {
    this.owner  = owner;
    this.isLeft = isLeft;
  }

  void update() {
    switch (phase) {

      case STRETCHING:
        currentLength += STRETCH_SPEED;
        if (currentLength >= MAX_LENGTH) {
          currentLength = MAX_LENGTH;
          phase = RETRACTING;
          hitEnemies.clear();   // limpa para o retorno poder acertar novos
        }
        break;

      case RETRACTING:
        currentLength -= RETRACT_SPEED;
        if (currentLength <= 0) {
          currentLength = 0;
          phase = FINISHED;
        }
        break;
    }
  }

  void draw() {
    if (phase == FINISHED) return;

    float offsetX = isLeft ? -owner.W / 2 - ARM_W / 2
                           :  owner.W / 2 + ARM_W / 2;
    float armX    = owner.x + offsetX;
    float armY    = owner.y;
    float armTopY = armY - currentLength;

    // Glow
    for (int i = 3; i > 0; i--) {
      fill(255, 204, 153, 30 * i);
      noStroke();
      rectMode(CORNER);
      rect(armX - ARM_W / 2 - i, armTopY - i,
           ARM_W + i * 2, currentLength + i * 2, 6);
    }

    // Corpo do braço
    fill(armColor);
    noStroke();
    rectMode(CORNER);
    rect(armX - ARM_W / 2, armTopY, ARM_W, currentLength, 6);

    // Punho
    fill(fistColor);
    float fistSize = ARM_W + 4;
    rectMode(CENTER);
    rect(armX, armTopY, fistSize, fistSize, 4);

    // Label debug L/R
    fill(255, 255, 255, 80);
    textSize(9);
    textAlign(CENTER, CENTER);
    text(isLeft ? "L" : "R", armX, armTopY - 10);

    rectMode(CORNER);
    textAlign(LEFT, BASELINE);
  }

  /**
   * Verifica colisão AABB com um inimigo.
   * Retorna true se colidiu e ainda não foi atingido nesta fase
   */
  boolean checkHit(Enemy e) {
    if (phase == FINISHED) return false;

    // Verifica se este inimigo já foi atingido nesta fase
    for (int i = 0; i < hitEnemies.size(); i++) {
      if (hitEnemies.get(i) == e) return false;
    }

    float offsetX  = isLeft ? -owner.W / 2 - ARM_W / 2
                             :  owner.W / 2 + ARM_W / 2;
    float armX     = owner.x + offsetX;
    float armTopY  = owner.y - currentLength;

    float armLeft   = armX - ARM_W / 2;
    float armRight  = armX + ARM_W / 2;
    float armBottom = owner.y;

    float eLeft   = e.x - e.SIZE / 2;
    float eRight  = e.x + e.SIZE / 2;
    float eTop    = e.y - e.SIZE / 2;
    float eBottom = e.y + e.SIZE / 2;

    boolean overlap = armRight  > eLeft   &&
                      armLeft   < eRight  &&
                      armBottom > eTop    &&
                      armTopY   < eBottom;

    if (overlap) {
      hitEnemies.add(e);   // registra referência direta ao objeto
      return true;
    }
    return false;
  }

  boolean isFinished() { return phase == FINISHED; }

  boolean isActive() { return phase != FINISHED && currentLength > 5; }
}

class Player {

  // Dimensões 
  final float W = 34;
  final float H = 34;

  // Posição
  float x, y;

  // Controle de braços
  // false = direita, true = esquerda
  boolean nextArmIsLeft = false;

  // Ataque ativo 
  ArmAttack currentAttack = null;

  // Visual 
  color bodyColor  = color(220, 30, 30);    // vermelho Luffy
  color hatColor   = color(210, 170, 30);   // dourado (chapéu de palha)

  // animação de "hit"
  int   hitFlashTimer = 0;
  final int HIT_FLASH_DURATION = 15;        // frames

  Player(float startX, float startY) {
    x = startX;
    y = startY;
  }

  void update() {
    // Posição sempre igual ao mouse
    x = mouseX;
    y = mouseY;

    // Limita ao interior da tela 
    x = constrain(x, W / 2, SCREEN_W - W / 2);
    y = constrain(y, H / 2, DEFENSE_LINE_Y - H / 2);

    // Atualiza ataque ativo
    if (currentAttack != null) {
      currentAttack.update();
      if (currentAttack.isFinished()) {
        currentAttack = null;
      }
    }

    // Decrementa flash de dano
    if (hitFlashTimer > 0) hitFlashTimer--;
  }

  void draw() {
    // Desenha o braço/ataque primeiro (atrás do corpo)
    if (currentAttack != null) {
      currentAttack.draw();
    }

    // Corpo principal — quadrado vermelho
    color drawColor = (hitFlashTimer > 0 && hitFlashTimer % 4 < 2)
                      ? color(255, 255, 255)
                      : bodyColor;
    fill(drawColor);
    rectMode(CENTER);
    rect(x, y, W, H, 4);   // raio 4 para cantos levemente arredondados

    // Chapéu de palha 
    fill(hatColor);
    rect(x, y - H / 2 - 4, W + 8, 6, 2);

    // Indicador de qual braço ataca a seguir 
    float dotX = nextArmIsLeft ? x - W / 2 - 6 : x + W / 2 + 6;
    fill(255, 204, 153, 180);
    ellipse(dotX, y, 7, 7);

    rectMode(CORNER);  // restaura padrão global
  }

  void triggerAttack() {
    if (currentAttack == null) {
      currentAttack = new ArmAttack(this, nextArmIsLeft);
      nextArmIsLeft = !nextArmIsLeft;   // alterna para o próximo clique
    }
  }

  void triggerHitFlash() {
    hitFlashTimer = HIT_FLASH_DURATION;
  }

  //Retorna o ArmAttack ativo
  ArmAttack getAttack() {
    return currentAttack;
  }
}

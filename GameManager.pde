class GameManager {

  // Estados possiveis 
  static final int STATE_TITLE       = 0;
  static final int STATE_PLAYING     = 1;
  static final int STATE_TRANSITION  = 2;   // entre waves
  static final int STATE_GAMEOVER    = 3;

  int state = STATE_TITLE;

  //  Wave atual 
  int  currentWave      = 0;    // começa em 0, sobe antes do spawn
  int  score            = 0;

  // Vidas 
  int  lives            = BASE_LIVES;

  // Lista de inimigos 
  ArrayList<Enemy> enemies;

  // Fila de spawn 
  int  enemiesToSpawn   = 0;
  int  spawnInterval    = 80;   // frames entre cada spawn
  int  spawnTimer       = 0;

  // Timer de transição entre waves 
  final int TRANSITION_FRAMES = 180;   // 3 s a 60 fps
  int  transitionTimer  = 0;

  // Escalonamento por wave 
  // Fórmula: quantidade = BASE_ENEMIES + (wave-1) * ENEMIES_SCALE
  //          HP base    = BASE_HP + (wave-1) * HP_SCALE
  // mUDAR DEPOIS / TALVEZ
  final int BASE_ENEMIES    = 5;
  final int ENEMIES_SCALE   = 3;
  final int BASE_HP         = 2;
  final int HP_SCALE        = 2;

  // velocidade dos inimigos 
  // Aumenta levemente a cada wave
  float baseEnemySpeed() { return 1.0 + (currentWave - 1) * 0.15; }

  // Dano do braço por hit 
  final int ARM_DAMAGE = 1;

  GameManager() {
    enemies = new ArrayList<Enemy>();
  }

  void startGame() {
    state       = STATE_PLAYING;
    currentWave = 0;
    score       = 0;
    lives       = BASE_LIVES;
    enemies.clear();
    startNextWave();
  }

  void reset() {
    startGame();
  }

  // UPDATE 
  void update() {
    switch (state) {
      case STATE_TITLE:      break;
      case STATE_PLAYING:    updatePlaying();   break;
      case STATE_TRANSITION: updateTransition(); break;
      case STATE_GAMEOVER:   break;
    }
  }

  void updatePlaying() {
    // Atualiza jogador
    player.update();

    // Spawn de inimigos desta wave
    if (enemiesToSpawn > 0) {
      spawnTimer++;
      if (spawnTimer >= spawnInterval) {
        spawnTimer = 0;
        spawnEnemy();
        enemiesToSpawn--;
      }
    }

    // Atualiza inimigos, verifica linha e colisões
    for (int i = enemies.size() - 1; i >= 0; i--) {
      Enemy e = enemies.get(i);
      e.update(player.x);

      // Cruzou a linha de defesa?
      if (e.crossedLine()) {
        enemies.remove(i);
        lives--;
        player.triggerHitFlash();
        // Spawna efeito de alerta
        spawnImpactParticles(e.x, DEFENSE_LINE_Y, color(255, 50, 50));

        if (lives <= 0) {
          state = STATE_GAMEOVER;
          return;
        }
        continue;
      }

      // Colisão com braço
      ArmAttack arm = player.getAttack();
      if (arm != null && arm.isActive()) {
        if (arm.checkHit(e)) {
          boolean killed = e.takeDamage(ARM_DAMAGE);
          if (killed) {
            score += 10 * currentWave;
            enemies.remove(i);
          }
        }
      }
    }

    // Verifica fim de wave 
    if (enemiesToSpawn == 0 && enemies.isEmpty()) {
      state           = STATE_TRANSITION;
      transitionTimer = TRANSITION_FRAMES;
    }
  }

  void updateTransition() {
    transitionTimer--;
    if (transitionTimer <= 0) {
      startNextWave();
      state = STATE_PLAYING;
    }
    // Jogador ainda se move durante a transição
    player.update();
  }

  // DRAW 
  void draw() {
    switch (state) {
      case STATE_TITLE:      drawTitle();      break;
      case STATE_PLAYING:    drawPlaying();    break;
      case STATE_TRANSITION: drawTransition(); break;
      case STATE_GAMEOVER:   drawGameOver();   break;
    }
  }

  void drawPlaying() {
    // Inimigos
    for (Enemy e : enemies) e.draw();

    // Jogador (por cima dos inimigos)
    player.draw();

    // HUD
    drawHUD();
  }

  void drawTransition() {
    // Mostra o jogo congelado + banner de transição
    for (Enemy e : enemies) e.draw();
    player.draw();
    drawHUD();

    // Banner central
    float alpha = 220;
    fill(0, 0, 0, 150);
    rectMode(CENTER);
    rect(SCREEN_W / 2, SCREEN_H / 2, 420, 100, 12);
    rectMode(CORNER);

    fill(255, 220, 50, alpha);
    textSize(28);
    textAlign(CENTER, CENTER);
    text("WAVE " + currentWave + " COMPLETA!", SCREEN_W / 2, SCREEN_H / 2 - 18);

    int secsLeft = ceil((float) transitionTimer / 60);
    fill(200, 200, 200, alpha);
    textSize(16);
    text("Próxima wave em " + secsLeft + "...", SCREEN_W / 2, SCREEN_H / 2 + 18);

    textAlign(LEFT, BASELINE);
  }
  
  void drawTitle() {
    // Título
    fill(220, 30, 30);
    textSize(48);
    textAlign(CENTER, CENTER);
    text("LUFFY SURVIVOR", SCREEN_W / 2, SCREEN_H / 2 - 80);

    fill(255, 204, 153);
    textSize(18);
    text("~ Gomu Gomu no CLIQUE ~", SCREEN_W / 2, SCREEN_H / 2 - 30);

    fill(200, 200, 200);
    textSize(14);
    text("Mova o mouse para controlar o Luffy", SCREEN_W / 2, SCREEN_H / 2 + 20);
    text("Clique M1 para atacar (alterna braço E/D)", SCREEN_W / 2, SCREEN_H / 2 + 44);
    text("Destrua os inimigos antes que cruzem a linha vermelha!", SCREEN_W / 2, SCREEN_H / 2 + 68);

    // Botão iniciar
    float btnY = SCREEN_H / 2 + 120;
    fill(220, 30, 30);
    rectMode(CENTER);
    rect(SCREEN_W / 2, btnY, 220, 48, 10);
    fill(255);
    textSize(20);
    text("CLIQUE PARA INICIAR", SCREEN_W / 2, btnY);
    rectMode(CORNER);

    textAlign(LEFT, BASELINE);
  }

  void drawGameOver() {
    // Tela escurecida
    fill(0, 0, 0, 180);
    rect(0, 0, SCREEN_W, SCREEN_H);

    fill(220, 30, 30);
    textSize(52);
    textAlign(CENTER, CENTER);
    text("GAME OVER", SCREEN_W / 2, SCREEN_H / 2 - 70);

    fill(255, 220, 50);
    textSize(22);
    text("Wave " + currentWave + " | Score: " + score, SCREEN_W / 2, SCREEN_H / 2 - 10);

    fill(200, 200, 200);
    textSize(15);
    text("Clique ou [R] para recomeçar", SCREEN_W / 2, SCREEN_H / 2 + 40);

    textAlign(LEFT, BASELINE);
  }

  void drawHUD() {
    // Wave
    fill(255, 220, 50);
    textSize(16);
    textAlign(RIGHT, TOP);
    text("WAVE  " + currentWave, SCREEN_W - 14, 12);

    // Score
    fill(200, 200, 200);
    textSize(14);
    text("SCORE  " + score, SCREEN_W - 14, 34);

    // Fila de inimigos
    fill(140, 140, 180);
    textSize(12);
    text("A spawnar: " + enemiesToSpawn + "  |  Ativos: " + enemies.size(),
         SCREEN_W - 14, 54);

    textAlign(LEFT, BASELINE);
  }

  // HELPERS INTERNOS 
  void startNextWave() {
    currentWave++;
    int count = BASE_ENEMIES + (currentWave - 1) * ENEMIES_SCALE;
    enemiesToSpawn = count;
    spawnTimer     = 0;
    enemies.clear();
  }

  // Spawna um único inimigo com atributos da wave atual
  void spawnEnemy() {
    float spawnX   = random(30, SCREEN_W - 30);
    int   hp       = BASE_HP + (currentWave - 1) * HP_SCALE;
    float spd      = baseEnemySpeed();
    float track    = map(currentWave, 1, 10, 0.003, 0.012);  // tracking suave cresce com waves
    enemies.add(new Enemy(spawnX, hp, spd, track));
  }
}

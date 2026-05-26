class GameManager {

  static final int STATE_TITLE    = 0;
  static final int STATE_PLAYING  = 1;
  static final int STATE_UPGRADE  = 2;   // tela de escolha de upgrade
  static final int STATE_GAMEOVER = 3;

  int state = STATE_TITLE;

  int  currentWave = 0;
  int  score       = 0;
  int  lives       = BASE_LIVES;

  ArrayList<Enemy> enemies = new ArrayList<Enemy>();

  // Spawn 
  int   enemiesToSpawn   = 0;
  int   spawnTimer       = 0;
  int   spawnInterval    = 75;
  boolean bossSpawned    = false;   // boss desta wave já foi criado?
  boolean bossPending    = false;   // boss aguardando spawn (após normais)

  // escalonamento 
  final int BASE_ENEMIES  = 5;
  final int ENEMIES_SCALE = 3;
  final int BASE_HP       = 2;
  final int HP_SCALE      = 2;
  float baseSpeed()       { return 1.0 + (currentWave - 1) * 0.15; }

  // ── Tela de upgrade ───────────────────────────────────────
  // Cada upgrade é representado por um índice:
  //   0 = Aumento de Dano
  //   1 = Haki
  //   2 = Gear 2
  int[]   upgradeOptions   = new int[3];   // opções sorteadas
  boolean upgradeChosen    = false;

  // Retângulos dos 3 cards (calculados em drawUpgradeScreen)
  float[] cardX = new float[3];
  float[] cardY = new float[3];
  final float CARD_W = 210, CARD_H = 280;

  // Timers / feedback 
  int bossWarningTimer = 0;   // pisca "BOSS!" na tela

  void startGame() {
    state       = STATE_PLAYING;
    currentWave = 0;
    score       = 0;
    lives       = BASE_LIVES;
    enemies.clear();
    // Reseta upgrades do player
    player.baseDamage    = 1;
    player.hakiUnlocked  = false;
    player.hakiActive    = false;
    player.hakiDuration  = 600;
    player.hakiCooldown  = 0;
    player.gear2Unlocked = false;
    player.gear2Active   = false;
    player.gear2Duration = 600;
    player.gear2Cooldown = 0;
    startNextWave();
  }

  void reset() { startGame(); }
  
  void update() {
    switch (state) {
      case STATE_PLAYING:  updatePlaying();  break;
      case STATE_UPGRADE:  player.update();  break;
      default: break;
    }
  }

  void updatePlaying() {
    player.update();

    // Spawn normal 
    if (enemiesToSpawn > 0) {
      spawnTimer++;
      if (spawnTimer >= spawnInterval) {
        spawnTimer = 0;
        spawnNormalEnemy();
        enemiesToSpawn--;
      }
    }

    // Boss: quando normais acabaram + lista vazia 
    if (bossPending && !bossSpawned && enemiesToSpawn == 0 && enemies.isEmpty()) {
      spawnBoss();
      bossSpawned   = true;
      bossPending   = false;
      bossWarningTimer = 120;  // 2s de aviso
    }

    if (bossWarningTimer > 0) bossWarningTimer--;

    // Atualiza inimigos 
    for (int i = enemies.size() - 1; i >= 0; i--) {
      Enemy e = enemies.get(i);
      e.update(player.x);

      if (e.crossedLine()) {
        enemies.remove(i);
        lives -= e.isBoss ? 2 : 1;   // boss tira 2 vidas
        player.triggerHitFlash();
        spawnImpactParticles(e.x, DEFENSE_LINE_Y, color(255, 50, 50));
        if (lives <= 0) { state = STATE_GAMEOVER; return; }
        continue;
      }

      // Colisão com braço
      ArmAttack arm = player.getAttack();
      if (arm != null && arm.isActive()) {
        if (arm.checkHit(e)) {
          boolean killed = e.takeDamage(player.getTotalDamage());
          if (killed) {
            score += e.isBoss ? 100 * currentWave : 10 * currentWave;
            enemies.remove(i);
          }
        }
      }
    }

    // Verifica fim de wave 
    boolean waveOver = enemiesToSpawn == 0 && !bossPending && enemies.isEmpty();
    if (waveOver) {
      upgradeChosen = false;
      sortUpgradeOptions();
      state = STATE_UPGRADE;
    }
  }

  void draw() {
    switch (state) {
      case STATE_TITLE:    drawTitle();    break;
      case STATE_PLAYING:  drawPlaying();  break;
      case STATE_UPGRADE:  drawUpgrade();  break;
      case STATE_GAMEOVER: drawGameOver(); break;
    }
  }

  void drawPlaying() {
    for (Enemy e : enemies) e.draw();
    player.draw();
    drawHUD();
    drawPowerHUD();

    // Aviso de Boss
    if (bossWarningTimer > 0) {
      float a = map(bossWarningTimer, 0, 120, 0, 255);
      fill(200, 0, 0, a);
      textSize(52);
      textAlign(CENTER, CENTER);
      text("!! BOSS !!", SCREEN_W/2, SCREEN_H/2 - 60);
      textAlign(LEFT, BASELINE);
    }
  }

  void drawHUD() {
    fill(255, 220, 50);
    textSize(16);
    textAlign(RIGHT, TOP);
    text("WAVE  " + currentWave, SCREEN_W - 14, 12);

    fill(200, 200, 200);
    textSize(14);
    text("SCORE  " + score, SCREEN_W - 14, 34);

    fill(140, 140, 180);
    textSize(11);
    text("spawnar:" + enemiesToSpawn + " ativos:" + enemies.size(), SCREEN_W - 14, 54);
    textAlign(LEFT, BASELINE);
  }

  /** HUD dos poderes (Haki + Gear2) no canto inferior esquerdo */
  void drawPowerHUD() {
    float bx = 14, by = SCREEN_H - 130;

    // Haki 
    if (player.hakiUnlocked) {
      fill(40, 40, 40, 180);
      rectMode(CORNER);
      rect(bx, by, 130, 24, 4);

      if (player.hakiActive) {
        float pct = player.hakiTimer / player.hakiDuration;
        fill(20, 20, 20);
        rect(bx, by, 130 * pct, 24, 4);
        fill(180, 180, 255);
        textSize(11);
        textAlign(LEFT, CENTER);
        text("HAKI  " + nf(player.hakiTimer / 60.0, 1, 1) + "s", bx + 5, by + 12);
      } else if (player.hakiCooldown > 0) {
        float pct = 1.0 - player.hakiCooldown / player.HAKI_COOLDOWN_FRAMES;
        fill(60, 60, 80);
        rect(bx, by, 130 * pct, 24, 4);
        fill(120, 120, 150);
        textSize(11);
        textAlign(LEFT, CENTER);
        text("[J] CD " + nf(player.hakiCooldown / 60.0, 1, 1) + "s", bx + 5, by + 12);
      } else {
        fill(100, 255, 180);
        textSize(11);
        textAlign(LEFT, CENTER);
        text("[J] HAKI PRONTO", bx + 5, by + 12);
      }
    }

    by += 30;

    // Gear 2 
    if (player.gear2Unlocked) {
      fill(60, 20, 20, 180);
      rectMode(CORNER);
      rect(bx, by, 130, 24, 4);

      if (player.gear2Active) {
        float pct = player.gear2Timer / player.gear2Duration;
        fill(180, 40, 40);
        rect(bx, by, 130 * pct, 24, 4);
        fill(255, 160, 160);
        textSize(11);
        textAlign(LEFT, CENTER);
        text("GEAR2  " + nf(player.gear2Timer / 60.0, 1, 1) + "s", bx + 5, by + 12);
      } else if (player.gear2Cooldown > 0) {
        float pct = 1.0 - player.gear2Cooldown / player.GEAR2_COOLDOWN_FRAMES;
        fill(80, 40, 40);
        rect(bx, by, 130 * pct, 24, 4);
        fill(150, 80, 80);
        textSize(11);
        textAlign(LEFT, CENTER);
        text("[G] CD " + nf(player.gear2Cooldown / 60.0, 1, 1) + "s", bx + 5, by + 12);
      } else {
        fill(255, 120, 120);
        textSize(11);
        textAlign(LEFT, CENTER);
        text("[G] GEAR2 PRONTO", bx + 5, by + 12);
      }
    }

    textAlign(LEFT, BASELINE);
    rectMode(CORNER);
  }

  //  UPGRADE SCREEN
  void drawUpgrade() {
    // Fundo escurecido
    fill(0, 0, 0, 200);
    rect(0, 0, SCREEN_W, SCREEN_H);

    fill(255, 220, 50);
    textSize(30);
    textAlign(CENTER, CENTER);
    text("WAVE " + currentWave + " COMPLETA!", SCREEN_W/2, 80);

    fill(200, 200, 200);
    textSize(15);
    text("Escolha um upgrade:", SCREEN_W/2, 118);

    // Desenha os 3 cards
    float startX = SCREEN_W/2 - (3 * CARD_W + 2 * 20) / 2;
    for (int i = 0; i < 3; i++) {
      cardX[i] = startX + i * (CARD_W + 20);
      cardY[i] = SCREEN_H/2 - CARD_H/2 - 10;
      drawUpgradeCard(i, cardX[i], cardY[i]);
    }

    fill(140, 140, 140);
    textSize(12);
    text("Clique num card para escolher", SCREEN_W/2, SCREEN_H - 40);
    textAlign(LEFT, BASELINE);
  }

  void drawUpgradeCard(int idx, float cx, float cy) {
    int uType = upgradeOptions[idx];
    boolean hover = mouseX > cx && mouseX < cx + CARD_W &&
                    mouseY > cy && mouseY < cy + CARD_H;

    // Fundo do card
    color bgC = hover ? color(60, 60, 80) : color(35, 35, 55);
    fill(bgC);
    stroke(hover ? color(255,220,50) : color(80,80,120));
    strokeWeight(hover ? 2.5 : 1.5);
    rectMode(CORNER);
    rect(cx, cy, CARD_W, CARD_H, 12);
    noStroke();

    // Ícone grande central (forma geométrica simples)
    float iconX = cx + CARD_W/2;
    float iconY = cy + 95;
    drawUpgradeIcon(uType, iconX, iconY);

    // Título
    fill(255, 220, 50);
    textSize(16);
    textAlign(CENTER, CENTER);
    text(upgradeName(uType), cx + CARD_W/2, cy + 165);

    // Descrição
    fill(190, 190, 210);
    textSize(11);
    text(upgradeDesc(uType), cx + CARD_W/2, cy + 195);
    text(upgradeDesc2(uType), cx + CARD_W/2, cy + 212);
    text(upgradeDesc3(uType), cx + CARD_W/2, cy + 229);

    // Status atual
    fill(100, 200, 130);
    textSize(10);
    text(upgradeStatus(uType), cx + CARD_W/2, cy + 255);

    textAlign(LEFT, BASELINE);
  }

  void drawUpgradeIcon(int uType, float ix, float iy) {
    rectMode(CENTER);
    switch (uType) {
      case 0:  // Dano → punho rosa
        fill(255, 204, 153);
        rect(ix, iy, 44, 44, 6);
        fill(240, 160, 90);
        rect(ix, iy - 22, 48, 14, 4);
        break;
      case 1:  // Haki → punho preto com aura
        fill(20, 20, 20);
        rect(ix, iy, 44, 44, 6);
        noFill();
        for (int i = 3; i > 0; i--) {
          stroke(80, 80, 200, 60 * i);
          strokeWeight(i * 2);
          ellipse(ix, iy, 60 + i*8, 60 + i*8);
        }
        noStroke();
        break;
      case 2:  // Gear 2 → punho vermelho + fogo
        fill(255, 90, 100);
        rect(ix, iy, 44, 44, 6);
        // labaredas simuladas
        fill(255, 160, 0, 180);
        triangle(ix - 10, iy - 22, ix, iy - 44, ix + 10, iy - 22);
        triangle(ix + 8, iy - 22, ix + 22, iy - 40, ix + 18, iy - 18);
        triangle(ix - 18, iy - 18, ix - 22, iy - 40, ix - 8, iy - 22);
        break;
    }
    rectMode(CORNER);
    noStroke();
  }

  String upgradeName(int t) {
    switch (t) {
      case 0: return "AUMENTO DE DANO";
      case 1: return player.hakiUnlocked ? "HAKI +" : "DESBLOQUEAR HAKI";
      case 2: return player.gear2Unlocked ? "GEAR 2 +" : "DESBLOQUEAR GEAR 2";
      default: return "?";
    }
  }

  String upgradeDesc(int t) {
    switch (t) {
      case 0: return "+1 de dano base";
      case 1: return player.hakiUnlocked ? "+1.5s de duracao" : "Ativa com [J]";
      case 2: return player.gear2Unlocked ? "+1.5s de duracao" : "Ativa com [G]";
      default: return "";
    }
  }
  String upgradeDesc2(int t) {
    switch (t) {
      case 0: return "por soco";
      case 1: return player.hakiUnlocked ? "no Haki" : "Bracos pretos";
      case 2: return player.gear2Unlocked ? "no Gear 2" : "Socos ultra rapidos";
      default: return "";
    }
  }
  String upgradeDesc3(int t) {
    switch (t) {
      case 0: return "";
      case 1: return player.hakiUnlocked ? "" : "+50% dano  10s";
      case 2: return player.gear2Unlocked ? "" : "Barrage ao segurar M1";
      default: return "";
    }
  }
  String upgradeStatus(int t) {
    switch (t) {
      case 0: return "Dano atual: " + player.baseDamage;
      case 1: return player.hakiUnlocked
                     ? "Duracao: " + nf(player.hakiDuration/60.0,1,1) + "s"
                     : "BLOQUEADO";
      case 2: return player.gear2Unlocked
                     ? "Duracao: " + nf(player.gear2Duration/60.0,1,1) + "s"
                     : "BLOQUEADO";
      default: return "";
    }
  }

  void handleUpgradeClick(int mx, int my) {
    if (upgradeChosen) return;
    for (int i = 0; i < 3; i++) {
      if (mx > cardX[i] && mx < cardX[i] + CARD_W &&
          my > cardY[i] && my < cardY[i] + CARD_H) {
        applyUpgrade(upgradeOptions[i]);
        upgradeChosen = true;
        startNextWave();
        state = STATE_PLAYING;
        return;
      }
    }
  }

  void applyUpgrade(int uType) {
    switch (uType) {
      case 0:
        player.baseDamage++;
        break;
      case 1:
        if (!player.hakiUnlocked) { player.hakiUnlocked = true; }
        else                      { player.hakiDuration += player.HAKI_LEVEL_BONUS; }
        break;
      case 2:
        if (!player.gear2Unlocked) { player.gear2Unlocked = true; }
        else                       { player.gear2Duration += player.GEAR2_LEVEL_BONUS; }
        break;
    }
  }

  /** Garante que as 3 opções sejam sempre distintas */
  void sortUpgradeOptions() {
    ArrayList<Integer> pool = new ArrayList<Integer>();
    pool.add(0); pool.add(1); pool.add(2);
    for (int i = 0; i < 3; i++) {
      int pick = (int) random(pool.size());
      upgradeOptions[i] = pool.get(pick);
      pool.remove(pick);
    }
  }

  void drawTitle() {
    fill(220, 30, 30);
    textSize(48);
    textAlign(CENTER, CENTER);
    text("LUFFY SURVIVOR", SCREEN_W/2, SCREEN_H/2 - 90);

    fill(255, 204, 153);
    textSize(16);
    text("~ Gomu Gomu no MVP ~", SCREEN_W/2, SCREEN_H/2 - 44);

    fill(200, 200, 200);
    textSize(13);
    text("Mouse → mover  |  M1 → atacar  |  J → Haki  |  G → Gear 2", SCREEN_W/2, SCREEN_H/2 + 10);
    text("Destrua os inimigos antes que cruzem a linha vermelha!", SCREEN_W/2, SCREEN_H/2 + 32);
    text("A partir da Wave 5 surgem BOSSES!", SCREEN_W/2, SCREEN_H/2 + 54);

    float btnY = SCREEN_H/2 + 110;
    fill(220, 30, 30);
    rectMode(CENTER);
    rect(SCREEN_W/2, btnY, 230, 50, 10);
    fill(255);
    textSize(20);
    text("CLIQUE PARA INICIAR", SCREEN_W/2, btnY);
    rectMode(CORNER);
    textAlign(LEFT, BASELINE);
  }

  void drawGameOver() {
    fill(0, 0, 0, 190);
    rect(0, 0, SCREEN_W, SCREEN_H);
    fill(220, 30, 30);
    textSize(52);
    textAlign(CENTER, CENTER);
    text("GAME OVER", SCREEN_W/2, SCREEN_H/2 - 70);
    fill(255, 220, 50);
    textSize(22);
    text("Wave " + currentWave + "  |  Score: " + score, SCREEN_W/2, SCREEN_H/2 - 10);
    fill(200, 200, 200);
    textSize(15);
    text("Clique ou [R] para recomeçar", SCREEN_W/2, SCREEN_H/2 + 40);
    textAlign(LEFT, BASELINE);
  }

  void startNextWave() {
    currentWave++;
    int count = BASE_ENEMIES + (currentWave - 1) * ENEMIES_SCALE;
    enemiesToSpawn = count;
    spawnTimer     = 0;
    bossSpawned    = false;
    bossPending    = currentWave >= 5;   // boss a partir da wave 5
    enemies.clear();
  }

  void spawnNormalEnemy() {
    float sx    = random(30, SCREEN_W - 30);
    int   hp    = BASE_HP + (currentWave - 1) * HP_SCALE;
    float spd   = baseSpeed();
    float track = map(currentWave, 1, 15, 0.003, 0.014);
    enemies.add(new Enemy(sx, hp, spd, track, false));
  }

  void spawnBoss() {
    float sx   = SCREEN_W / 2;
    int   hp   = (BASE_HP + (currentWave - 1) * HP_SCALE) * 12;  // HP altíssimo
    float spd  = baseSpeed() * 0.45;   // mais lento
    enemies.add(new Enemy(sx, hp, spd, 0.006, true));
  }
}

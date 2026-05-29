/**
 * ============================================================
 *  Particle.pde — Partículas de impacto e fogo
 *
 *  CONSTRUTOR: Particle(float x, float y, color c, boolean isFire)
 *  isFire = true  → sobe, muda de laranja para amarelo
 *  isFire = false → explode em todas as direções
 * ============================================================
 */
class Particle {

  float x, y, vx, vy, size, alpha, alphaDecay, drag;
  color col;
  boolean isFire;

  // ==========================================================
  Particle(float px, float py, color c, boolean fire) {
    this.x      = px;
    this.y      = py;
    this.col    = c;
    this.isFire = fire;

    float angle = random(TWO_PI);
    float spd   = fire ? random(0.5, 2.5) : random(1.5, 5.5);
    vx = cos(angle) * spd;
    vy = fire ? -random(1.5, 4.0) : sin(angle) * spd;  // fogo sobe

    size       = fire ? random(6, 14) : random(4, 12);
    alpha      = random(180, 255);
    alphaDecay = fire ? random(3, 6)  : random(4, 9);
    drag       = fire ? random(0.88, 0.93) : random(0.92, 0.97);
  }

  // ==========================================================
  void update() {
    x    += vx;
    y    += vy;
    vx   *= drag;
    vy   *= isFire ? 0.96 : drag;
    size *= isFire ? 0.94 : 0.96;
    alpha -= alphaDecay;

    // Fogo: transição laranja → amarelo conforme sobe
    if (isFire && alpha > 60) {
      col = lerpColor(color(255, 30, 0), color(255, 220, 0), 1.0 - (alpha / 255.0));
    }
  }

  // ==========================================================
  void draw() {
    if (alpha <= 0) return;
    noStroke();
    fill(red(col), green(col), blue(col), alpha);
    if (isFire) {
      ellipse(x, y, size * 0.7, size);   // forma de chama (elipse vertical)
    } else {
      ellipse(x, y, size, size);
    }
  }

  // ==========================================================
  boolean isDead() { return alpha <= 0 || size < 0.5; }
}

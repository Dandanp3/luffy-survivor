class Particle {

  float x, y;
  float vx, vy;
  float size;
  color col;
  float alpha;
  float alphaDecay;
  float drag;           // fator de desaceleração (0..1)

  Particle(float x, float y, color c) {
    this.x = x;
    this.y = y;
    this.col = c;

    // Velocidade aleatoria em todas as direções
    float angle = random(TWO_PI);
    float speed = random(1.5, 5.5);
    vx = cos(angle) * speed;
    vy = sin(angle) * speed;

    size       = random(4, 12);
    alpha      = random(180, 255);
    alphaDecay = random(4, 9);
    drag       = random(0.92, 0.97);
  }

  void update() {
    x    += vx;
    y    += vy;
    vx   *= drag;
    vy   *= drag;
    size *= 0.96;       // encolhe suavemente
    alpha -= alphaDecay;
  }

  void draw() {
    if (alpha <= 0) return;
    noStroke();
    fill(red(col), green(col), blue(col), alpha);
    ellipse(x, y, size, size);
  }

  boolean isDead() {
    return alpha <= 0 || size < 0.5;
  }
}

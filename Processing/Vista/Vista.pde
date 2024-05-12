
color[] colors = new color[4];

void setup(){
  colors[0] = color(185, 200, 255);
  colors[1] = color(255, 179, 186);
  colors[2] = color(186, 255, 201);
  colors[3] = color(255, 255, 186);
  noStroke();
  size(1400, 650);
  for (int i = 0; i < colors.length; i++){
    fill(colors[i]);
    rect(i * width/8, 0, width/8, height);
  };
  fill(255);
  rect(width/2, 0, width/8, height);
}

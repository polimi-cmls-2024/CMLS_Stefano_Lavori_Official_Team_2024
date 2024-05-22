import controlP5.*;
import oscP5.*;
import netP5.*;
OscP5 oscP5;
NetAddress myRemoteLocation, myRemoteLocation_dist, myRemoteLocation_flanger;

color[] colors = {color(185, 200, 255), color(255, 179, 186), color(186, 255, 201), color(255, 255, 186)};
int white = 0xffffffff;
int black = 0xff000000;
int[] colorsSwitch = {0xff0066cc, 0xffcc0000, 0xff00994c, 0xffffdf0b};
int[] in_rainbows = {0xffa2dce6, 0xffec2327, 0xffedb31e, 0xff45b74a, 0xfff36525, 0xff4686c7, 0xfff7ed4a};
float dimXblock1 = width/2;
String[] buttonLabels = {"Trig Loop", "Vel Loop", "Notes Loop", "Mod Loop"};
String[] sliderLabels = {"Pitch Fundamental", "Velocity Bias", "Modulation Bias"};
int x_pos, y_pos, radius, n, t, rotate, steps_index, triggers_index, value_trig, Euclid_steps;
int logic_operator, scale, wavetype;
ArrayList<Integer> triggers = new ArrayList<Integer>();

ArrayList<Knob> knobs_supercollider = new ArrayList<Knob>();
ArrayList<Knob> knobs_juice = new ArrayList<Knob>();
ArrayList<Toggle> toggles = new ArrayList<Toggle>();

float Name0, Name1, Name2, x, y, z, oldZ, BPM, control_diameter;

String[][] names_1= {{"Euclid steps", "Euclid triggers", "Euclid rotation", "Logic operator"},
  {"Trig probability", "Velocity loop length", "Trig loop length", "Rhythm permutations"},
  {"Glide", "Notes loop length", "Notes permutation", "Scale"},
  {"Modulation loop length", "Modulation interpolation", "Pitch granulator", "Granulator Dry/Wet"}
};

String[][] names_2 = {{"Fold Amount", "Dist Amount", "F&D Dry/Wet"},
  {"Wave type", "Rate", "Depth"},
  {"Feedback", "Width", "Flanger Dry/Wet"},
  {"Color", "Stereo", ""}
};

ArrayList<Slider2D> sliders = new ArrayList<Slider2D>();


float[][] initVals_1 = {{1, 1, 0, 1},
  {0, 1, 1, 0},
  {0, 1, 5, 1},
  {1, 0, 1, 0}};
float[][] minVals_1  = {{1, 1, 0, 1},
  {0, 1, 1, 0},
  {-1, 1, 0, 1},
  {1, 0, 0.5, 0}};
float[][] maxVals_1= {{32, 32, 32, 4},
  {1, 32, 32, 20},
  {1, 32, 20, 10},
  {32, 1, 2, 1}};


int slider_select = 0;

float[][] initVals_2 = {{1, 1, 0},
  {1, 440, 0.6},
  {0.9, 0, 0},
  {0, 1, 0}};
float[][] minVals_2  = {{1, 1, 0},
  {1, 0.1, 0.1},
  {0, 0, 0},
  {0, 0, 0}};
float[][] maxVals_2= {{60, 1000, 1},
  {4, 20000, 1},
  {1, 100, 1},
  {1, 1, 0}};

int ticks = 1;
boolean snap = false;

ControlP5 cp5;
boolean toggleValue = false;

void setup() {
  oscP5 = new OscP5(this, 24);
  myRemoteLocation = new NetAddress("127.0.0.1", 57120);
  myRemoteLocation_dist = new NetAddress("127.0.0.1", 9001);
  myRemoteLocation_flanger = new NetAddress("127.0.0.1", 9001);

  smooth();
  cp5 = new ControlP5(this);
  cp5.addCallback(
    new CallbackListener() {
    void controlEvent(CallbackEvent theEvent) {
      //print(theEvent);
      switch(theEvent.getAction()) {
      case ControlP5.ACTION_RELEASE_OUTSIDE:
      case ControlP5.ACTION_RELEASE:
        sendOscMessage();
        break;
      }
    }
  }
  );
  noStroke();
  control_diameter=75;
  size(1200, 650);
  for (int i = 0; i < colors.length; i++) {
    rectMode(CENTER);
    //creation of top buttons
    Toggle tog = cp5.addToggle(buttonLabels[i])
      .setPosition(width/16 + i*width/8 - 25, 20)
      .setSize(50, 20)
      .setValue(false)
      .setMode(ControlP5.DEFAULT)
      .setColorLabel(0)
      .setColorBackground(0xffA0A0A0)
      .setColorActive(colorsSwitch[i])
      .setColorForeground(0xffBBBBBB);
    toggles.add(tog);
    //creation of knobs in block_one and block_two
    switch(i) {
    case 0:
      for (int j = 0; j<4; j++) {
        ticks = (int)maxVals_1[i][j]-(int)minVals_1[i][j];
        Knob knob = makeKnobs(names_1[i][j], minVals_1[i][j], maxVals_1[i][j], initVals_1[i][j], width/16 + i*width/8 - 25, 80 + j*80, black, colorsSwitch[i], white, ticks, true);
        knobs_supercollider.add(
          knob
          );
      }
      for (int j = 0; j<3; j++) {
        ticks = (int)maxVals_2[i][j]-(int)minVals_2[i][j];
        if (j == 1) {
          snap = true;
        }
        Knob knob = makeKnobs(names_2[i][j], minVals_2[i][j], maxVals_2[i][j], initVals_2[i][j], width*11/16 + j*width/8 - 25, height/8, white, in_rainbows[i+1], white, ticks, snap);
        knobs_juice.add(
          knob
          );
        snap=false;
      }
      break;
    case 1:
      for (int j = 0; j<4; j++) {
        ticks = (int)maxVals_1[i][j]-(int)minVals_1[i][j];
        if (j !=0 ) {
          snap = true;
        } else snap = false;
        Knob knob = makeKnobs(names_1[i][j], minVals_1[i][j], maxVals_1[i][j], initVals_1[i][j], width/16 + i*width/8 - 25, 80 + j*80, black, colorsSwitch[i], white, ticks, snap);
        knobs_supercollider.add(
          knob
          );
      }
      for (int j = 0; j<3; j++) {
        ticks = (int)maxVals_2[i][j]-(int)minVals_2[i][j];
        if (j == 0) {
          snap = true;
        } else snap = false;
        Knob knob = makeKnobs(names_2[i][j], minVals_2[i][j], maxVals_2[i][j], initVals_2[i][j], width*11/16 + j*width/8 - 25, height*3/8, white, in_rainbows[i+1], white, ticks, snap);
        knobs_juice.add(
          knob
          );
      }
      break;
    case 2:
      for (int j = 0; j<4; j++) {
        ticks = (int)maxVals_1[i][j]-(int)minVals_1[i][j];
        if (j == 0) {
          snap = false;
        } else snap = true;

        Knob knob = makeKnobs(names_1[i][j], minVals_1[i][j], maxVals_1[i][j], initVals_1[i][j], width/16 + i*width/8 - 25, 80 + j*80, black, colorsSwitch[i], white, ticks, snap);
        knobs_supercollider.add(
          knob
          );
      }
      for (int j = 0; j<3; j++) {
        Knob knob = makeKnobs(names_2[i][j], minVals_2[i][j], maxVals_2[i][j], initVals_2[i][j], width*11/16 + j*width/8 - 25, height*9/16, white, in_rainbows[i+1], white, 1, false);
        knobs_juice.add(
          knob
          );
      }
      break;
    case 3:
      for (int j = 0; j<4; j++) {
        ticks = (int)maxVals_1[i][j]-(int)minVals_1[i][j];
        snap=false;
        if (j==0) {
          snap=true;
        }
        Knob knob = makeKnobs(names_1[i][j], minVals_1[i][j], maxVals_1[i][j], initVals_1[i][j], width/16 + i*width/8 - 25, 80 + j*80, black, colorsSwitch[i], black, ticks, snap);
        knobs_supercollider.add(
          knob
          );
      }
      for (int j = 0; j<2; j++) {
        Knob knob = makeKnobs(names_2[i][j], minVals_2[i][j], maxVals_2[i][j], initVals_2[i][j], width*12/16 + j*width/8 - 25, height*6/8, white, in_rainbows[4], white, 1, false);
        knobs_juice.add(
          knob
          );
      }
      break;
    }
    rectMode(CORNER);
    fill(colors[i]);
    rect(i * width/8, 0, width/8, height*5/8);
  };
  //creation of sliders
  for (int i = 0; i <3; i++) {
    sliders.add(cp5.addSlider2D("Name"+i)
      .setPosition(width/35+i*width/6, height*11/16)
      .setMinMax(0, 0, 1, 1)
      .setSize(150, 150)
      .setValue(0.4, 0.9)
      .setColorBackground(0xff7d3c98)
      .setColorCaptionLabel(0xff8e7ab5)
      .setColorValueLabel(0xff8e7ab5)
      .setLabelVisible(false)
      );
  };
  //creation of control knob
  Knob knob = makeKnobs("BPM", 30, 300, 120, width/2+width/30, height*9/16, white, black, white, 270, true);
  knob.setRadius(control_diameter/2);

  fill(0xff8e7ab5);
  rect(0, height*5/8, width/2, height);  //slider block
  fill(in_rainbows[4]);
  rect(width/2, 0, width/8, height);   //control block
  fill(40);
  rect(width*5/8, 0, width, height);   //effect block
  fill(245);
  textSize(20);
  textAlign(CENTER);
  text("Folder&Distortion", width*13/16, height/16);
  text("Flanger", width*13/16, height*5/16);
  fill(245);
  textSize(15);
  for (int i=0; i<3; i++) {
    textAlign(CENTER);
    smooth();
    pushMatrix();
    translate(25+i*width/6, height*7/8);
    rotate(PI*3/2);
    text("Variance", 0, 0);
    popMatrix();

    textAlign(LEFT);
    text(sliderLabels[i], width/35+i*width/6, height*19/20);
  }

  smooth();


  oldZ = 0;

  x_pos = width/2 + width/16;
  y_pos = height - 100;
  radius = 100;
  n = (int)knobs_supercollider.get(0).getValue();
  t = (int)knobs_supercollider.get(1).getValue();
  rotate = (int)knobs_supercollider.get(2).getValue();
  value_trig = 1;
  triggers = calculateTriggers(n, t, rotate);
}

void draw() {
  smooth();
  rectMode(CORNER);
  strokeWeight(0);
  fill(40);
  rect(width/2, 0, width/8, height);
  strokeWeight(2);
  //creation of play/stop buttons
  fill(in_rainbows[3]);
  stroke(colors[2]);
  circle(width/2+width/16, 100, control_diameter);
  triangle(width/2+width/16 + 20, 100, width/2+width/16 - 20*cos(PI/3), 100 - 20*sin(PI/3), width/2+width/16 - 20*cos(PI/3), 100 + 20*sin(PI/3));
  fill(in_rainbows[1]);
  stroke(colors[1]);
  circle(width/2+width/16, 250, control_diameter);
  rectMode(CENTER);
  square(width/2+width/16, 250, 30);

  if (sqrt(sq(mouseX - width/2-width/16)+sq(mouseY-100))<37.5) {
    fill(colors[2]);
    stroke(colors[2]);
    triangle(width/2+width/16 + 20, 100, width/2+width/16 - 20*cos(PI/3), 100 - 20*sin(PI/3), width/2+width/16 - 20*cos(PI/3), 100 + 20*sin(PI/3));
  }
  if (sqrt(sq(mouseX - width/2-width/16)+sq(mouseY-250))<37.5) {
    fill(colors[1]);
    stroke(colors[1]);
    square(width/2+width/16, 250, 30);
  }
  //writing play and stop
  fill(245);
  textSize(20);
  textAlign(CENTER);
  text("Play", width/2+width/16, 165);
  text("Stop", width/2+width/16, 315);

  //handle logic operator label
  logic_operator = (int)knobs_supercollider.get(3).getValue();
  noStroke();
  fill(colors[0]);
  rect(width/16, 375, 40, 13);
  switch(logic_operator) {
  case 1:
    knobs_supercollider.get(3).setCaptionLabel("OR");
    break;
  case 2:
    knobs_supercollider.get(3).setCaptionLabel("AND");
    break;
  case 3:
    knobs_supercollider.get(3).setCaptionLabel("XOR");
    break;
  case 4:
    knobs_supercollider.get(3).setCaptionLabel("NAND");
    break;
  }
  //handle scale label
  scale = (int)knobs_supercollider.get(11).getValue();
  fill(colors[2]);
  rect(width/16 + width/4, 375, 80, 13);
  switch(scale) {
  case 1:
    knobs_supercollider.get(11).setCaptionLabel("Chromatic \n    Scale");
    break;
  case 2:
    knobs_supercollider.get(11).setCaptionLabel("Major");
    break;
  case 3:
    knobs_supercollider.get(11).setCaptionLabel("Minor");
    break;
  case 4:
    knobs_supercollider.get(11).setCaptionLabel("Major Pentatonic");
    break;
  case 5:
    knobs_supercollider.get(11).setCaptionLabel("Minor Pentatonic");
    break;
  case 6:
    knobs_supercollider.get(11).setCaptionLabel("Dorian");
    break;
  case 7:
    knobs_supercollider.get(11).setCaptionLabel("Lydian");
    break;
  case 8:
    knobs_supercollider.get(11).setCaptionLabel("Phrygian");
    break;
  case 9:
    knobs_supercollider.get(11).setCaptionLabel("Mixolydian");
    break;
  case 10:
    knobs_supercollider.get(11).setCaptionLabel("Iwato");
    break;
  }
  //handle wavetype label
  wavetype = (int)knobs_juice.get(3).getValue();
  noStroke();
  fill(40);
  rect(width*11/16, 300, 50, 13);
  switch(wavetype) {
  case 1:
    knobs_juice.get(3).setCaptionLabel("SQUARE \n  WAVE");
    break;
  case 2:
    knobs_juice.get(3).setCaptionLabel("TRIANGLE");
    break;
  case 3:
    knobs_juice.get(3).setCaptionLabel("SAWTOOTH");
    break;
  case 4:
    knobs_juice.get(3).setCaptionLabel("SINE");
    break;
  }
  n = (int)knobs_supercollider.get(0).getValue();
  t = (int)knobs_supercollider.get(1).getValue();
  rotate = (int)knobs_supercollider.get(2).getValue();
  //fill(255, 40, 52);
  triggers = calculateTriggers(n, t, rotate);
  smooth();
  noFill();
  //circle(x, y, r);

  beginShape();
  for (int i = 0; i< n; i++) {
    float angle = PI * 0.5 - i * TWO_PI / n;
    float dx = radius/2 * cos(angle);
    float dy = radius/2 * sin(angle);
    if (triggers.get(i) == 1) {
      vertex(x_pos + dx, y_pos - dy);
      stroke(230, 255);
      strokeWeight(10);
    } else {
      stroke(230, 127);
      strokeWeight(10);
    }

    point(x_pos + dx, y_pos - dy);
    stroke(230, 255);
    strokeWeight(5);
  }
  endShape(CLOSE);
}

public Knob makeKnobs(String name, float minimum_val, float maximum_val, float initial_val, float x_pos, float y_pos,
  int color_label, int color_background, int color_value, int tick_marks, boolean snap) {

  Knob knob = cp5.addKnob(name)
    .setRange(minimum_val, maximum_val)
    .setValue(initial_val)
    .setPosition(x_pos, y_pos)
    .setRadius(25)
    .setColorLabel(color_label)
    .setViewStyle(Knob.ELLIPSE)
    .setDragDirection(Knob.VERTICAL)
    .setColorBackground(color_background)
    .setColorForeground(white)
    .setColorActive(white)
    .setColorValue(color_value)
    .setNumberOfTickMarks(tick_marks)
    .snapToTickMarks(snap)
    .hideTickMarks();

  return knob;
}

/* incoming osc message are forwarded to the oscEvent method. */
void oscEvent(OscMessage theOscMessage) {
  /* print the address pattern and the typetag of the received OscMessage */
  print("### received an osc message.");
  print(" addrpattern: " + theOscMessage.addrPattern());
  println(" X: " + theOscMessage.get(0).floatValue() + " Y: " + theOscMessage.get(1).floatValue() + " Z: " + theOscMessage.get(2).floatValue());
  x = theOscMessage.get(0).floatValue();
  y = theOscMessage.get(1).floatValue();
  z = theOscMessage.get(2).floatValue();
  // we check if there is a transition from 0 to 1 (release part of the pressing stage)
  // of the z value of the joystick so we can detect when the button is pressed
  if (oldZ < 0.5f && z > 0.5f) {
    Slider2D curr_slider = sliders.get(slider_select);
    curr_slider.setColorBackground(0xff7d3c98);
    slider_select = (slider_select + 1) % 4;
    if (slider_select < 3) {
      curr_slider.setColorBackground(0xffb399dd);
    }
    oldZ = 1;
  } else if (oldZ > 0.5f && z < 0.5f) {
    oldZ = 0;
  }

  if (slider_select != 3) {
    Slider2D curr_slider = sliders.get(slider_select);
    float minX = curr_slider.getMinX();
    float maxX = curr_slider.getMaxX();

    float minY = curr_slider.getMinY();
    float maxY = curr_slider.getMaxY();
    curr_slider.setValue(map_interval(x, minX, maxX), maxY-map_interval(y, minY, maxY));
    sendOscMessage();
  }
}

public float map_interval(float n, float min, float max) {
  float mapped_n = ((max - min) * n) + min;
  mapped_n *= 100;
  mapped_n = round(mapped_n);
  mapped_n /= 100;

  return mapped_n;
}

ArrayList<Integer> calculateTriggers(int steps, int pulses, int rotate) {
  ArrayList<Integer> trigs = new ArrayList<Integer>();

  rotate += 1;
  rotate = rotate % steps;
  int bucket = 0;

  //fill track with rhythm
  for (int i=0; i< steps; i++) {
    bucket += pulses;
    if (bucket >= steps) {
      bucket -= steps;
      trigs.add(1);
    } else {
      trigs.add(0);
    }
  }

  //rotate
  if (rotate > 0) {
    trigs = rotateSeq(trigs, steps, rotate);
  }


  return trigs;
}

ArrayList<Integer> rotateSeq(ArrayList<Integer> seq2, int steps, int rotate) {
  ArrayList<Integer> output = new ArrayList<Integer>();
  int val = steps - rotate;
  for (int i = 0; i < seq2.size(); i++) {
    output.add(seq2.get(abs((i+val) % seq2.size())));
  }
  return output;
}

void mouseClicked() {
  if (sqrt(sq(mouseX - width/2-width/16)+sq(mouseY-100))<37.5) {
    println("Tasto 1");
    OscMessage myMessage = new OscMessage("/play");
    oscP5.send(myMessage, myRemoteLocation);
  }

  if (sqrt(sq(mouseX - width/2-width/16)+sq(mouseY-250))<37.5) {
    println("Tasto 2");
    OscMessage myMessage = new OscMessage("/stop");
    oscP5.send(myMessage, myRemoteLocation);
  }
}

void sendOscMessage() {
  // supercollider message
  OscMessage myMessage = new OscMessage("/vars");
  for (int i = 0; i < knobs_supercollider.size(); i++) {
    Knob singleKnob = knobs_supercollider.get(i);
    float value = singleKnob.getValue();
    myMessage.add(value);
  }
  for (int i = 0; i < sliders.size(); i++) {
    Slider2D slid = sliders.get(i);
    float[] values = slid.getArrayValue();
    myMessage.add(values[0]);
    myMessage.add(1 - values[1]);
  }
  oscP5.send(myMessage, myRemoteLocation);

  //BPM message
  OscMessage myMessageBpm = new OscMessage("/bpm");
  myMessageBpm.add(BPM);
  oscP5.send(myMessageBpm, myRemoteLocation);

  //Dist folder message
  OscMessage myMessageDist = new OscMessage("/distFolderParams");
  for (int i = 0; i < 3; i++) {
    Knob singleKnob = knobs_juice.get(i);
    float value = singleKnob.getValue();
    myMessageDist.add(value);
  }
  oscP5.send(myMessageDist, myRemoteLocation_dist);

  // Flanger message
  OscMessage myMessageFlang = new OscMessage("/flangerParams");
  for (int i = 3; i < knobs_juice.size(); i++) {
    Knob singleKnob = knobs_juice.get(i);
    float value = singleKnob.getValue();
    myMessageFlang.add(value);
  }
  oscP5.send(myMessageFlang, myRemoteLocation_flanger);

  // Toggles message
  OscMessage myMessageLoop = new OscMessage("/loop");
  for (int i = 0; i < toggles.size(); i++) {
    Toggle tog = toggles.get(i);
    Boolean value = tog.getState();
    if (value) myMessageLoop.add(1);
    else myMessageLoop.add(0);
  }
  oscP5.send(myMessageLoop, myRemoteLocation);
}

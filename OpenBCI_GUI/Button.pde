
////////////////////
//
// This class creates and manages a button for use on the screen to trigger actions.
//
// Created: Chip Audette, Oct 2013.
// Modified: Conor Russomanno, Oct 2014
// 
// Based on Processing's "Button" example code
//
////////////////////

class Button {
  
  int but_x, but_y, but_dx, but_dy;      // Position of square button
  //int rectSize = 90;     // Diameter of rect
  color color_pressed = color(200);
  color color_highlight = color(102);
  color color_notPressed = color(255);
  color buttonStrokeColor = bgColor;
  color textColorActive = color(255);
  color textColorNotActive = bgColor;
  color rectHighlight;
  //boolean isMouseHere = false;
  boolean buttonHasStroke = true;
  boolean isActive = false;
  boolean isDropdownButton = false;
  boolean drawHand = false;
  boolean wasPressed = false;
  public String but_txt;
  PFont buttonFont = f2;

  public Button(int x, int y, int w, int h, String txt, int fontSize) {
    setup(x, y, w, h, txt);
    //println(PFont.list()); //see which fonts are available
    //font = createFont("SansSerif.plain",fontSize);
    //font = createFont("Lucida Sans Regular",fontSize);
    // font = createFont("Arial",fontSize);
    //font = loadFont("SansSerif.plain.vlw");
  }

  public void setup(int x, int y, int w, int h, String txt) {
    but_x = x;
    but_y = y;
    but_dx = w;
    but_dy = h;
    setString(txt);
  }
  
  public void setString(String txt) {
    but_txt = txt;
    //println("Button: setString: string = " + txt);
  }
  
  public boolean isActive() {
    return isActive;
  }
  
  public void setIsActive(boolean val) {
    isActive = val;
  }

  public void makeDropdownButton(boolean val){
    isDropdownButton = val;
  }
  
  public boolean isMouseHere() {
    if ( overRect(but_x, but_y, but_dx, but_dy) ) {
      // cursor(HAND);
      return true;
    } 
    else {
      return false;
    }
  }

  color getColor() {
    if (isActive) {
      return color_pressed;
    } else {    
      return color_notPressed;
    }
  }

  public void setColorPressed(color _color){
    color_pressed = _color;
  }
  public void setColorNotPressed(color _color){
    color_notPressed = _color;
  }

  public void setStrokeColor(color _color){
    buttonStrokeColor = _color;
  }

  public void hasStroke(boolean _trueORfalse){
    buttonHasStroke = _trueORfalse;
  }

  boolean overRect(int x, int y, int width, int height) {
    if (mouseX >= x && mouseX <= x+width && 
      mouseY >= y && mouseY <= y+height) {
      return true;
    } 
    else {
      return false;
    }
  }

  public void draw(int _x, int _y){
    but_x = _x;
    but_y = _y;
    draw();
  }

  public void draw() {
    //draw the button
    fill(getColor());
    if(buttonHasStroke){
      stroke(buttonStrokeColor); //button border
    }else{
      noStroke();
    }
    // noStroke();
    rect(but_x,but_y,but_dx,but_dy);
    
    //draw the text
    if(isActive){
      fill(textColorActive);
    }else{
      fill(textColorNotActive);
    }
    stroke(255);
    textFont(buttonFont);  //load f2 ... from control panel 
    textSize(12);
    textAlign(CENTER, CENTER);
    textLeading(round(0.9*(textAscent()+textDescent())));
//    int x1 = but_x+but_dx/2;
//    int y1 = but_y+but_dy/2;
    int x1, y1;
    if (false) {
      //auto wrap
      x1 = but_x;
      y1 = but_y;
      int w = but_dx-2*2; //use a 2 pixel buffer on the left and right sides 
      int h = but_dy;
      text(but_txt,x1,y1,w,h);
    } else {
      //no auto wrap
      x1 = but_x+but_dx/2;
      y1 = but_y+but_dy/2;
      text(but_txt,x1,y1);
    }

    //draw open/close arrow if it's a dropdown button
    if(isDropdownButton){
      pushStyle();
        fill(255);
        noStroke();
        // smooth();
        // stroke(255);
        // strokeWeight(1);
        if(isActive){
          float point1x = but_x + (but_dx - ((3f*but_dy)/4f));
          float point1y = but_y + but_dy/3f;
          float point2x = but_x + (but_dx-(but_dy/4f));
          float point2y = but_y + but_dy/3f;
          float point3x = but_x + (but_dx - (but_dy/2f));
          float point3y = but_y + (2f*but_dy)/3f;
          triangle(point1x, point1y, point2x, point2y, point3x, point3y); //downward triangle, indicating open
        } else{
          float point1x = but_x + (but_dx - ((3f*but_dy)/4f));
          float point1y = but_y + (2f*but_dy)/3f;
          float point2x = but_x + (but_dx-(but_dy/4f));
          float point2y = but_y + (2f*but_dy)/3f;
          float point3x = but_x + (but_dx - (but_dy/2f));
          float point3y = but_y + but_dy/3f;
          triangle(point1x, point1y, point2x, point2y, point3x, point3y); //upward triangle, indicating closed
        }
      popStyle();
    }

    if(systemMode == 0){
      if(!isMouseHere() && drawHand){
        cursor(ARROW);
        drawHand = false;
        verbosePrint("don't draw hand");
      }
      //if cursor is over button change cursor icon to hand!
      if(isMouseHere() && !drawHand){
        cursor(HAND);
        drawHand = true;
        verbosePrint("draw hand");
      } 
    }
  }
};




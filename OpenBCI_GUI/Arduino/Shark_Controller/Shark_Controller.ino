/*
    CONTROL THE SWIMMING SHARK!
    
    modified from Chip Audette's code here
    https://github.com/chipaudette/EEGHacker/blob/master/Arduino/TestHexBugController/TestHexBugController.ino
    
    This controls the SWIMMING SHARK
    http://www.amazon.com/William-Mark-AS001-Remote-Control/dp/B005FYEAJ8
    The SWIMMING SHARK controller buttons makes connection to GND when pressed. 
    I am sharing GND between the controller and Arduino. Then using pins 13, 12, 11, 10.
    Made by Joel Murphy, Winter, 2015
*/


#define PIN_GROUND A1
int pins[]= {13, 12, 11, 10};
#define NPINS 4
#define RIGHT 3
#define CLIMB 1
#define LEFT  2
#define DIVE 0

volatile char inChar;
unsigned long lastCommand_millis = 0;
int commndDuration_millis = 300;
int swimCounter = 0;
boolean swimming, diving, lefting, climbing, righting;


void setup() {
  // initialize serial:
  Serial.begin(115200);
  
  // print help
  Serial.println("SHARKController: starting...");
  Serial.println("Commands Include: ");
  Serial.println("    'O' = Swim");
  Serial.println("    'P' = Dive");
  Serial.println("    '{' = Left");
  Serial.println("    '}' = Climb");
  Serial.println("    '|' = Right");
  
  swimming = diving = righting = climbing = lefting = false;
  //initialize the pins
  stopAllPins();
}

void stopAllPins() {
  //stopping all pins means putting them into a high impedance state
  //Serial.println("Stopping All Pins...");
  for (int Ipin=0; Ipin < NPINS; Ipin++) {
//    digitalWrite(pins[Ipin],LOW);
    pinMode(pins[Ipin],INPUT);
  }
}

void loop() {
  // print the string when a newline arrives:
  if (millis() > lastCommand_millis+commndDuration_millis) {
    lastCommand_millis = millis()+5000; //don't do this branch for a while
    stopAllPins();
    
    if(swimming){
      swimCounter++;
      delay(400);
      if(swimCounter % 2 == 0){
        issueCommand(LEFT);
      }else{
        issueCommand(RIGHT);
      }
      if(swimCounter == 3){
        swimming = false;
      }
    }
    
    diving = righting = climbing = lefting = false;
  }
  
  
      
}

void issueCommand(int command_pin_ind) {
  if (command_pin_ind < NPINS) {
    stopAllPins();
    pinMode(pins[command_pin_ind],OUTPUT);
    digitalWrite(pins[command_pin_ind],LOW);
    lastCommand_millis = millis();  //time the command was received

  }
}
 

/*
  SerialEvent occurs whenever a new data comes in the
 hardware serial RX.  This routine is run between each
 time loop() runs, so using delay inside loop can delay
 response.  Multiple bytes of data may be available.
 */
void serialEvent() {
  while (Serial.available()) {
    char inChar = (char)Serial.read();
    Serial.print("Received "); Serial.println(inChar);
    switch (inChar) {
     case 'O':
       if(swimming){return;}
       swimming = true;
       swimCounter = 0;
       issueCommand(LEFT);
       break;
     case 'P':
       if(diving){return;}
       if(swimming) swimming = false;
       diving = true;
       issueCommand(DIVE); break;
     case '{':
       if(lefting){return;}
       if(swimming) swimming = false;
       lefting = true;
       issueCommand(LEFT); break;
     case '}':
       if(climbing){return;}
       if(swimming) swimming = false;
       climbing = true;
       issueCommand(CLIMB); break;
     case '|':
       if(righting){return;}
       if(swimming) swimming = false;
       righting = true;
       issueCommand(RIGHT); break;
       
     }
  }
}




////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//
//  This file contains all key commands for interactivity with GUI & OpenBCI
//  Created by Chip Audette, Joel Murphy, & Conor Russomanno
//  - Extracted from OpenBCI_GUI because it was getting too klunky
//
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

//interpret a keypress...the key pressed comes in as "key"
void keyPressed() {
  //note that the Processing variable "key" is the keypress as an ASCII character
  //note that the Processing variable "keyCode" is the keypress as a JAVA keycode.  This differs from ASCII  
  //println("OpenBCI_GUI: keyPressed: key = " + key + ", int(key) = " + int(key) + ", keyCode = " + keyCode);
  
  if(!controlPanel.isOpen){ //don't parse the key if the control panel is open
    if ((int(key) >=32) && (int(key) <= 126)) {  //32 through 126 represent all the usual printable ASCII characters
      parseKey(key);
    } else {
      parseKeycode(keyCode);
    }
  }
}

void parseKey(char val) {
  int Ichan; boolean activate; int code_P_N_Both;
  
  //assumes that val is a usual printable ASCII character (ASCII 32 through 126)
  switch (val) {
    case '1':
      deactivateChannel(1-1); 
      break;
    case '2':
      deactivateChannel(2-1); 
      break;
    case '3':
      deactivateChannel(3-1); 
      break;
    case '4':
      deactivateChannel(4-1); 
      break;
    case '5':
      deactivateChannel(5-1); 
      break;
    case '6':
      deactivateChannel(6-1); 
      break;
    case '7':
      deactivateChannel(7-1); 
      break;
    case '8':
      deactivateChannel(8-1); 
      break;
    case 'q':
      activateChannel(1-1); 
      break;
    case 'w':
      activateChannel(2-1); 
      break;
    case 'e':
      activateChannel(3-1); 
      break;
    case 'r':
      activateChannel(4-1); 
      break;
    case 't':
      activateChannel(5-1); 
      break;
    case 'y':
      activateChannel(6-1); 
      break;
    case 'u':
      activateChannel(7-1); 
      break;
    case 'i':
      activateChannel(8-1); 
      break;
    case 's':
      println("case s...");
      stopRunning();
      // stopButtonWasPressed();
      break;
    case 'b':
      println("case b...");
      startRunning();
      // stopButtonWasPressed();
      break;
    case 'n':
      println(openBCI.state);
      break;

    case '?':
      printRegisters();
      break;
      
    //change the state of the impedance measurements...activate the P-channels
    case '!':
      Ichan = 1; activate = true; code_P_N_Both = 0;  setChannelImpedanceState(Ichan-1,activate,code_P_N_Both);
      break;
    case '@':
      Ichan = 2; activate = true; code_P_N_Both = 0;  setChannelImpedanceState(Ichan-1,activate,code_P_N_Both);
      break;
    case '#':
      Ichan = 3; activate = true; code_P_N_Both = 0;  setChannelImpedanceState(Ichan-1,activate,code_P_N_Both);
      break;
    case '$':
      Ichan = 4; activate = true; code_P_N_Both = 0;  setChannelImpedanceState(Ichan-1,activate,code_P_N_Both);
      break;
    case '%':
      Ichan = 5; activate = true; code_P_N_Both = 0;  setChannelImpedanceState(Ichan-1,activate,code_P_N_Both);
      break;
    case '^':
      Ichan = 6; activate = true; code_P_N_Both = 0;  setChannelImpedanceState(Ichan-1,activate,code_P_N_Both);
      break;
    case '&':
      Ichan = 7; activate = true; code_P_N_Both = 0;  setChannelImpedanceState(Ichan-1,activate,code_P_N_Both);
      break;
    case '*':
      Ichan = 8; activate = true; code_P_N_Both = 0;  setChannelImpedanceState(Ichan-1,activate,code_P_N_Both);
      break;
      
    //change the state of the impedance measurements...deactivate the P-channels
    case 'Q':
      Ichan = 1; activate = false; code_P_N_Both = 0;  setChannelImpedanceState(Ichan-1,activate,code_P_N_Both);
      break;
    case 'W':
      Ichan = 2; activate = false; code_P_N_Both = 0;  setChannelImpedanceState(Ichan-1,activate,code_P_N_Both);
      break;
    case 'E':
      Ichan = 3; activate = false; code_P_N_Both = 0;  setChannelImpedanceState(Ichan-1,activate,code_P_N_Both);
      break;
    case 'R':
      Ichan = 4; activate = false; code_P_N_Both = 0;  setChannelImpedanceState(Ichan-1,activate,code_P_N_Both);
      break;
    case 'T':
      Ichan = 5; activate = false; code_P_N_Both = 0;  setChannelImpedanceState(Ichan-1,activate,code_P_N_Both);
      break;
    case 'Y':
      Ichan = 6; activate = false; code_P_N_Both = 0;  setChannelImpedanceState(Ichan-1,activate,code_P_N_Both);
      break;
    case 'U':
      Ichan = 7; activate = false; code_P_N_Both = 0;  setChannelImpedanceState(Ichan-1,activate,code_P_N_Both);
      break;
    case 'I':
      Ichan = 8; activate = false; code_P_N_Both = 0;  setChannelImpedanceState(Ichan-1,activate,code_P_N_Both);
      break;
      
      
    //change the state of the impedance measurements...activate the N-channels
    case 'A':
      Ichan = 1; activate = true; code_P_N_Both = 1;  setChannelImpedanceState(Ichan-1,activate,code_P_N_Both);
      break;
    case 'S':
      Ichan = 2; activate = true; code_P_N_Both = 1;  setChannelImpedanceState(Ichan-1,activate,code_P_N_Both);
      break;
    case 'D':
      Ichan = 3; activate = true; code_P_N_Both = 1;  setChannelImpedanceState(Ichan-1,activate,code_P_N_Both);
      break;
    case 'F':
      Ichan = 4; activate = true; code_P_N_Both = 1;  setChannelImpedanceState(Ichan-1,activate,code_P_N_Both);
      break;
    case 'G':
      Ichan = 5; activate = true; code_P_N_Both = 1;  setChannelImpedanceState(Ichan-1,activate,code_P_N_Both);
      break;
    case 'H':
      Ichan = 6; activate = true; code_P_N_Both = 1;  setChannelImpedanceState(Ichan-1,activate,code_P_N_Both);
      break;
    case 'J':
      Ichan = 7; activate = true; code_P_N_Both = 1;  setChannelImpedanceState(Ichan-1,activate,code_P_N_Both);
      break;
    case 'K':
      Ichan = 8; activate = true; code_P_N_Both = 1;  setChannelImpedanceState(Ichan-1,activate,code_P_N_Both);
      break;
      
    //change the state of the impedance measurements...deactivate the N-channels
    case 'Z':
      Ichan = 1; activate = false; code_P_N_Both = 1;  setChannelImpedanceState(Ichan-1,activate,code_P_N_Both);
      break;
    case 'X':
      Ichan = 2; activate = false; code_P_N_Both = 1;  setChannelImpedanceState(Ichan-1,activate,code_P_N_Both);
      break;
    case 'C':
      Ichan = 3; activate = false; code_P_N_Both = 1;  setChannelImpedanceState(Ichan-1,activate,code_P_N_Both);
      break;
    case 'V':
      Ichan = 4; activate = false; code_P_N_Both = 1;  setChannelImpedanceState(Ichan-1,activate,code_P_N_Both);
      break;
    case 'B':
      Ichan = 5; activate = false; code_P_N_Both = 1;  setChannelImpedanceState(Ichan-1,activate,code_P_N_Both);
      break;
    case 'N':
      Ichan = 6; activate = false; code_P_N_Both = 1;  setChannelImpedanceState(Ichan-1,activate,code_P_N_Both);
      break;
    case 'M':
      Ichan = 7; activate = false; code_P_N_Both = 1;  setChannelImpedanceState(Ichan-1,activate,code_P_N_Both);
      break;
    case '<':
      Ichan = 8; activate = false; code_P_N_Both = 1;  setChannelImpedanceState(Ichan-1,activate,code_P_N_Both);
      break;

      
    case 'm':
     String picfname = "OpenBCI-" + getDateString() + ".jpg";
     println("OpenBCI_GUI: 'm' was pressed...taking screenshot:" + picfname);
     saveFrame(picfname);    // take a shot of that!
     break;

    default:
     println("OpenBCI_GUI: '" + key + "' Pressed...sending to OpenBCI...");
     // if (openBCI.serial_openBCI != null) openBCI.serial_openBCI.write(key);//send the value as ascii with a newline character
     if (serial_openBCI != null) serial_openBCI.write(key);//send the value as ascii with a newline character
    
     break;
  }
}

void parseKeycode(int val) { 
  //assumes that val is Java keyCode
  switch (val) {
    case 8:
      println("OpenBCI_GUI: parseKeycode(" + val + "): received BACKSPACE keypress.  Ignoring...");
      break;   
    case 9:
      println("OpenBCI_GUI: parseKeycode(" + val + "): received TAB keypress.  Toggling Impedance Control...");
      //gui.showImpedanceButtons = !gui.showImpedanceButtons;
      gui.incrementGUIpage();
      break;    
    case 10:
      println("OpenBCI_GUI: parseKeycode(" + val + "): received ENTER keypress.  Ignoring...");
      break;
    case 16:
      println("OpenBCI_GUI: parseKeycode(" + val + "): received SHIFT keypress.  Ignoring...");
      break;
    case 17:
      //println("OpenBCI_GUI: parseKeycode(" + val + "): received CTRL keypress.  Ignoring...");
      break;
    case 18:
      println("OpenBCI_GUI: parseKeycode(" + val + "): received ALT keypress.  Ignoring...");
      break;
    case 20:
      println("OpenBCI_GUI: parseKeycode(" + val + "): received CAPS LOCK keypress.  Ignoring...");
      break;
    case 27:
      println("OpenBCI_GUI: parseKeycode(" + val + "): received ESC keypress.  Stopping OpenBCI...");
      stopRunning();
      break; 
    case 33:
      println("OpenBCI_GUI: parseKeycode(" + val + "): received PAGE UP keypress.  Ignoring...");
      break;    
    case 34:
      println("OpenBCI_GUI: parseKeycode(" + val + "): received PAGE DOWN keypress.  Ignoring...");
      break;
    case 35:
      println("OpenBCI_GUI: parseKeycode(" + val + "): received END keypress.  Ignoring...");
      break; 
    case 36:
      println("OpenBCI_GUI: parseKeycode(" + val + "): received HOME keypress.  Ignoring...");
      break; 
    case 37:
      println("OpenBCI_GUI: parseKeycode(" + val + "): received LEFT ARROW keypress.  Ignoring...");
      break;  
    case 38:
      println("OpenBCI_GUI: parseKeycode(" + val + "): received UP ARROW keypress.  Ignoring...");
      break;  
    case 39:
      println("OpenBCI_GUI: parseKeycode(" + val + "): received RIGHT ARROW keypress.  Ignoring...");
      break;  
    case 40:
      println("OpenBCI_GUI: parseKeycode(" + val + "): received DOWN ARROW keypress.  Ignoring...");
      break;
    case 112:
      println("OpenBCI_GUI: parseKeycode(" + val + "): received F1 keypress.  Ignoring...");
      break;
    case 113:
      println("OpenBCI_GUI: parseKeycode(" + val + "): received F2 keypress.  Ignoring...");
      break;  
    case 114:
      println("OpenBCI_GUI: parseKeycode(" + val + "): received F3 keypress.  Ignoring...");
      break;  
    case 115:
      println("OpenBCI_GUI: parseKeycode(" + val + "): received F4 keypress.  Ignoring...");
      break;  
    case 116:
      println("OpenBCI_GUI: parseKeycode(" + val + "): received F5 keypress.  Ignoring...");
      break;  
    case 117:
      println("OpenBCI_GUI: parseKeycode(" + val + "): received F6 keypress.  Ignoring...");
      break;  
    case 118:
      println("OpenBCI_GUI: parseKeycode(" + val + "): received F7 keypress.  Ignoring...");
      break;  
    case 119:
      println("OpenBCI_GUI: parseKeycode(" + val + "): received F8 keypress.  Ignoring...");
      break;  
    case 120:
      println("OpenBCI_GUI: parseKeycode(" + val + "): received F9 keypress.  Ignoring...");
      break;  
    case 121:
      println("OpenBCI_GUI: parseKeycode(" + val + "): received F10 keypress.  Ignoring...");
      break;  
    case 122:
      println("OpenBCI_GUI: parseKeycode(" + val + "): received F11 keypress.  Ignoring...");
      break;  
    case 123:
      println("OpenBCI_GUI: parseKeycode(" + val + "): received F12 keypress.  Ignoring...");
      break;     
    case 127:
      println("OpenBCI_GUI: parseKeycode(" + val + "): received DELETE keypress.  Ignoring...");
      break;
    case 155:
      println("OpenBCI_GUI: parseKeycode(" + val + "): received INSERT keypress.  Ignoring...");
      break; 
    default:
      println("OpenBCI_GUI: parseKeycode(" + val + "): value is not known.  Ignoring...");
      break;
  }
}
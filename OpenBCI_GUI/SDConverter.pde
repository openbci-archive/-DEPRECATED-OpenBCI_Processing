
//////////////////////////////////
//
//		This file contains code used to convert HEX files (stored by OpenBCI on the local SD) into 
//		text files that can be used for PLAYBACK mode.
//		Created: Conor Russomanno - 10/22/14 (based on code written by Joel Murphy summer 2014)
//
//////////////////////////////////

//variables for SD file conversion
BufferedReader dataReader;
String dataLine;
PrintWriter dataWriter;
String convertedLine;
String thisLine;
String h;
String[] hexNums;
float[] floatData = new float[20];
String logFileName;
long thisTime;
long thatTime;

public void convertSDFile() {
  println("");
  try {
    dataLine = dataReader.readLine();
  } 
  catch (IOException e) {
    e.printStackTrace();
    dataLine = null;
  }

  if (dataLine == null) {
    // Stop reading because of an error or file is empty
    thisTime = millis() - thatTime;
    controlPanel.convertingSD = false;
    println("nothing left in file"); 
    println("SD file conversion took "+thisTime+" mS");
    dataWriter.flush();
    dataWriter.close();
  } else {
    //        println(dataLine);
    hexNums = splitTokens(dataLine, ",");

    if (hexNums[0].charAt(0) == '%') {
      //          println(dataLine);
      dataWriter.println(dataLine);
      println(dataLine);
    } else {
      if (hexNums.length < 13){
          convert8channelLine();
        }else{
          convert16channelLine();
        }
    }
  }
}

void createPlaybackFileFromSD() {
  logFileName = "data/EEG_Data/SDconverted-"+getDateString()+".txt";
  dataWriter = createWriter(logFileName);
  dataWriter.println("%OBCI Data Log - " + getDateString());
}

void sdFileSelected(File selection) {
  if (selection == null) {
    println("Window was closed or the user hit cancel.");
  } else {
    println("User selected " + selection.getAbsolutePath());
    dataReader = createReader(selection.getAbsolutePath()); // ("positions.txt");
    controlPanel.convertingSD = true;
    println("Timing SD file conversion...");
    thatTime = millis();
  }
}



void convert16channelLine() {
  for (int i=0; i<hexNums.length; i++) {
    h = hexNums[i];
    if (i > 0) {
      if (h.charAt(0) > '7') {  // if the number is negative 
        h = "FF" + hexNums[i];   // keep it negative
      } else {                  // if the number is positive
        h = "00" + hexNums[i];   // keep it positive
      }
      if (i > 16) { // accelerometer data needs another byte
        if (h.charAt(0) == 'F') {
          h = "FF" + h;
        } else {
          h = "00" + h;
        }
      }
    }
    // println(h); // use for debugging
    if (h.length()%2 == 0) {  // make sure this is a real number
      floatData[i] = unhex(h);
    } else {
      floatData[i] = 0;
    }


    //if not first column(sample #) or columns 9-11 (accelerometer), convert to uV
    if (i>=1 && i<=16) {
      floatData[i] *= openBCI.get_scale_fac_uVolts_per_count();
    }else if(i != 0){
      floatData[i] *= openBCI.get_scale_fac_accel_G_per_count();
    }

    if(i == 0){  
      dataWriter.print(int(floatData[i]));  // print the sample counter
    }else{
      dataWriter.print(floatData[i]);  // print the current channel value
    }
    if (i < hexNums.length-1) {  // print the current channel value
      dataWriter.print(",");  // print "," separator
    }
  }
  dataWriter.println();
}

void convert8channelLine() {
  for (int i=0; i<hexNums.length; i++) {
    h = hexNums[i];
    if (i > 0) {
      if (h.charAt(0) > '7') {  // if the number is negative 
        h = "FF" + hexNums[i];   // keep it negative
      } else {                  // if the number is positive
        h = "00" + hexNums[i];   // keep it positive
      }
      if (i > 8) { // accelerometer data needs another byte
        if (h.charAt(0) == 'F') {
          h = "FF" + h;
        } else {
          h = "00" + h;
        }
      }
    }
    // println(h); // use for debugging
    if (h.length()%2 == 0) {  // make sure this is a real number
      floatData[i] = unhex(h);
    } else {
      floatData[i] = 0;
    }


    //if not first column(sample #) or columns 9-11 (accelerometer), convert to uV
    if (i>=1 && i<=8) {
      floatData[i] *= openBCI.get_scale_fac_uVolts_per_count();
    }else if(i != 0){
      floatData[i] *= openBCI.get_scale_fac_accel_G_per_count();
    }

    if(i == 0){  
      dataWriter.print(int(floatData[i]));  // print the sample counter
    }else{
      dataWriter.print(floatData[i]);  // print the current channel value
    }
    if (i < hexNums.length-1) {  
      dataWriter.print(",");  // print "," separator
    }
  }
  dataWriter.println();
}
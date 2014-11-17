///////////////////////////////////////////////
//
// GUI for controlling the ADS1299-based OpenBCI
//
// Created: Chip Audette, Oct 2013 - May 2014
// Modified: Conor Russomanno & Joel Murphy, August 2014 - Oct 2014
//
// Requires gwoptics graphing library for processing.  Built on V0.5.0
// http://www.gwoptics.org/processing/gwoptics_p5lib/
//
// Requires ControlP5 library, but an older one.  This will only work
// with the ControlP5 library that is included with this GitHub repository
//
// No warranty.  Use at your own risk.  Use for whatever you'd like.
// 
///////////////////////////////////////////////

import ddf.minim.analysis.*; //for FFT
//import ddf.minim.*;  // commented because too broad.. contains "Controller" class which is also contained in ControlP5... need to be more specific // To make sound.  Following minim example "frequencyModulation"
import ddf.minim.ugens.*;  // To make sound.  Following minim example "frequencyModulation"
import java.lang.Math; //for exp, log, sqrt...they seem better than Processing's built-in
import processing.core.PApplet;
import java.util.*; //for Array.copyOfRange()
import java.util.Map.Entry;
import processing.serial.*;  //for serial communication to Arduino/OpenBCI
import java.awt.event.*; //to allow for event listener on screen resize

boolean isVerbose = true; //set true if you want more verbosity in console

long timeOfLastFrame = 0;
int newPacketCounter = 0;

//used to switch between application states
int systemMode = 0; /* Modes: 0 = system stopped/control panel setings / 10 = gui / 20 = help guide */

//choose where to get the EEG data
final int DATASOURCE_NORMAL = 3;  //looking for signal from OpenBCI board via Serial/COM port, no Aux data
final int DATASOURCE_PLAYBACKFILE = 1;  //playback from a pre-recorded text file
final int DATASOURCE_SYNTHETIC = 2;  //Synthetically generated data
final int DATASOURCE_NORMAL_W_AUX = 0; // new default, data from serial with Accel data CHIP 2014-11-03
public int eegDataSource = -1; //default to none of the options

//Serial communications constants
OpenBCI_ADS1299 openBCI = new OpenBCI_ADS1299(); //dummy creation to get access to constants, create real one later
String openBCI_portName = "N/A";  //starts as N/A but is selected from control panel to match your OpenBCI USB Dongle's serial/COM

int openBCI_baud = 115200; //baud rate from the Arduino
// final int OpenBCI_Nchannels = 8; //normal OpenBCI has 8 channels
//use this for when daisy-chaining two OpenBCI boards
// public int OpenBCI_Nchannels = 8; //daisy chain has 16 channels

//here are variables that are used if loading input data from a CSV text file...double slash ("\\") is necessary to make a single slash
String playbackData_fname = "N/A"; //only used if loading input data from a file
// String playbackData_fname;  //leave blank to cause an "Open File" dialog box to appear at startup.  USEFUL!
float playback_speed_fac = 1.0f;  //make 1.0 for real-time.  larger for faster playback
int currentTableRowIndex = 0;
Table_CSV playbackData_table;
int nextPlayback_millis = -100; //any negative number

// boolean printingRegisters = false;

long timeOfInit;
long timeSinceStopRunning = 1000;

//other data fields
float dataBuffX[];
float dataBuffY_uV[][]; //2D array to handle multiple data channels, each row is a new channel so that dataBuffY[3][] is channel 4
float dataBuffY_filtY_uV[][];
float data_elec_imp_ohm[];

color bgColor = color(1, 18, 41);

//SD Card setting (if eegDataSource == 0)
int sdSetting = 0; //0 = do not write; 1 = 5 min; 2 = 15 min; 3 = 30 min; etc...
String sdSettingString = "Do not write to SD";
//int nchan = 12; //normally, nchan = OpenBCI_Nchannels.  Choose a smaller number to show fewer on the GUI
// int nchan = OpenBCI_Nchannels; //normally, nchan = OpenBCI_Nchannels.  Choose a smaller number to show fewer on the GUI

int nchan = 8; //normally, nchan = OpenBCI_Nchannels.  Choose a smaller number to show fewer on the GUI
// int nchan_active_at_startup = nchan;  //how many channels to be LIVE at startup
int n_aux_ifEnabled = 3;  // this is the accelerometer data CHIP 2014-11-03

int prev_time_millis = 0;
final int nPointsPerUpdate = 50; //update screen after this many data points.  
float yLittleBuff[] = new float[nPointsPerUpdate];
DataStatus is_railed[];
final int threshold_railed = int(pow(2,23)-1000);  //fully railed should be +/- 2^23, so set this threshold close to that value
final int threshold_railed_warn = int(pow(2,23)*0.75); //set a somewhat smaller value as the warning threshold

float yLittleBuff_uV[][] = new float[nchan][nPointsPerUpdate]; //small buffer used to send data to the filters

//create objects that'll do the EEG signal processing
EEG_Processing eegProcessing;
EEG_Processing_User eegProcessing_user;

//fft constants
int Nfft = 256; //set resolution of the FFT.  Use N=256 for normal, N=512 for MU waves

FFT fftBuff[] = new FFT[nchan];   //from the minim library
float[] smoothFac = new float[]{0.75, 0.9, 0.95, 0.98, 0.0, 0.5};
final int N_SMOOTHEFAC = 6;
int smoothFac_ind = 0;

//plotting constants
Gui_Manager gui;
float default_vertScale_uV = 200.0f;
float displayTime_sec = 5f;
float dataBuff_len_sec = displayTime_sec+3f; //needs to be wider than actual display so that filter startup is hidden

//Control Panel for (re)configuring system settings
ControlPanel controlPanel;
Button controlPanelCollapser;
PlotFontInfo fontInfo;

//program constants
boolean isRunning=false;
boolean redrawScreenNow = true;
int openBCI_byteCount = 0;
int inByte = -1;    // Incoming serial data

//Help Widget initiation
HelpWidget helpWidget;

//file writing variables
OutputFile_rawtxt fileoutput;
String output_fname;
String fileName = "N/A";

//serial port open or closed(?)
boolean portIsOpen = false;
Serial serial_openBCI = null;

//for screen resizing
boolean screenHasBeenResized = false;
float timeOfLastScreenResize = 0;
float timeOfGUIreinitialize = 0;
int reinitializeGUIdelay = 125;

//openBCI data packet
final int nDataBackBuff = 3*(int)openBCI.fs_Hz;
DataPacket_ADS1299 dataPacketBuff[] = new DataPacket_ADS1299[nDataBackBuff]; //allocate the array, but doesn't call constructor.  Still need to call the constructor!
int curDataPacketInd = -1;
int lastReadDataPacketInd = -1;

void appendAndShift(float[] data, float[] newData) {
  int nshift = newData.length;
  int end = data.length-nshift;
  for (int i=0; i < end; i++) {
    data[i]=data[i+nshift];  //shift data points down by 1
  }
  for (int i=0; i<nshift;i++) {
    data[end+i] = newData[i];  //append new data
  }
}

void prepareData(float[] dataBuffX, float[][] dataBuffY_uV, float fs_Hz) {
  //initialize the x and y data
  int xoffset = dataBuffX.length - 1;
  for (int i=0; i < dataBuffX.length; i++) {
    dataBuffX[i] = ((float)(i-xoffset)) / fs_Hz; //x data goes from minus time up to zero
    for (int Ichan = 0; Ichan < nchan; Ichan++) { 
      dataBuffY_uV[Ichan][i] = 0f;  //make the y data all zeros
    }
  }
}

void initializeFFTObjects(FFT[] fftBuff, float[][] dataBuffY_uV, int N, float fs_Hz) {

  float[] fooData;
  for (int Ichan=0; Ichan < nchan; Ichan++) {
    //make the FFT objects...Following "SoundSpectrum" example that came with the Minim library
    //fftBuff[Ichan] = new FFT(Nfft, fs_Hz);  //I can't have this here...it must be in setup
    fftBuff[Ichan].window(FFT.HAMMING);

    //do the FFT on the initial data
    fooData = dataBuffY_uV[Ichan];
    fooData = Arrays.copyOfRange(fooData, fooData.length-Nfft, fooData.length); 
    fftBuff[Ichan].forward(fooData); //compute FFT on this channel of data
  }
}

//set window size
int win_x = 1024;  //window width
int win_y = 768; //window height

PImage logo;

//========================SETUP============================//
//========================SETUP============================//
//========================SETUP============================//
void setup() {
  
  //open window
  size(win_x, win_y, P2D);
  // size(displayWidth, displayHeight, P2D);
  //if (frame != null) frame.setResizable(true);  //make window resizable
  //attach exit handler
  //prepareExitHandler();
  frameRate(16);
  // smooth(); //turn this off if it's too slow

  frame.setResizable(true); 

  //listen for window resize ... used to adjust elements in application
  frame.addComponentListener(new ComponentAdapter() { 
    public void componentResized(ComponentEvent e) { 
      if(e.getSource()==frame) { 
       println("RESIZED");
       screenHasBeenResized = true;
       timeOfLastScreenResize = millis();
       // initializeGUI();
      } 
    } 
  }
  );

  //set up controlPanelCollapser button
  fontInfo = new PlotFontInfo();

  helpWidget = new HelpWidget(0, win_y - 30, win_x, 30);

  // println("..." + this);
  controlPanelCollapser = new Button(0, 0, 256, int((float)win_y*(0.03f)), "SYSTEM CONTROL PANEL", fontInfo.buttonLabel_size);
  controlPanelCollapser.setIsActive(true);
  controlPanelCollapser.makeDropdownButton(true);
  controlPanel = new ControlPanel(this); 

  logo = loadImage("logo2.png");

}
//====================== END--OF ==========================//
//========================SETUP============================//
//========================SETUP============================//

int pointCounter = 0;
int prevBytes = 0; 
int prevMillis=millis();
int byteRate_perSec = 0;
int drawLoop_counter = 0;

//used to init system based on initial settings
void initSystem(){

  verbosePrint("-- Init 0 --");
  timeOfInit = millis(); //store this for timeout in case init takes too long

  //prepare data variables
  verbosePrint("Preparing data variables...");
  dataBuffX = new float[(int)(dataBuff_len_sec * openBCI.fs_Hz)];
  dataBuffY_uV = new float[nchan][dataBuffX.length];
  dataBuffY_filtY_uV = new float[nchan][dataBuffX.length];
  //data_std_uV = new float[nchan];
  data_elec_imp_ohm = new float[nchan];
  is_railed = new DataStatus[nchan];
  for (int i=0; i<nchan;i++) is_railed[i] = new DataStatus(threshold_railed,threshold_railed_warn);
  for (int i=0; i<nDataBackBuff;i++) { 
    //dataPacketBuff[i] = new DataPacket_ADS1299(nchan+n_aux_ifEnabled);
    // dataPacketBuff[i] = new DataPacket_ADS1299(OpenBCI_Nchannels+n_aux_ifEnabled);
    dataPacketBuff[i] = new DataPacket_ADS1299(nchan,n_aux_ifEnabled);
  }
  eegProcessing = new EEG_Processing(nchan,openBCI.fs_Hz);
  eegProcessing_user = new EEG_Processing_User(nchan,openBCI.fs_Hz);

  //initialize the data
  prepareData(dataBuffX, dataBuffY_uV,openBCI.fs_Hz);

  verbosePrint("-- Init 1 --");

  //initialize the FFT objects
  for (int Ichan=0; Ichan < nchan; Ichan++) { 
    println("a--"+Ichan);
    fftBuff[Ichan] = new FFT(Nfft, openBCI.fs_Hz);
  };  //make the FFT objects
  println("b");
  initializeFFTObjects(fftBuff, dataBuffY_uV, Nfft, openBCI.fs_Hz);

  //prepare some signal processing stuff
  //for (int Ichan=0; Ichan < nchan; Ichan++) { detData_freqDomain[Ichan] = new DetectionData_FreqDomain(); }

  verbosePrint("-- Init 2 --");

  //prepare the source of the input data
  switch (eegDataSource) {
    case DATASOURCE_NORMAL: case DATASOURCE_NORMAL_W_AUX:
      
      // int nDataValuesPerPacket = OpenBCI_Nchannels;
      int nEEDataValuesPerPacket = nchan;
      boolean useAux = false;
      if (eegDataSource == DATASOURCE_NORMAL_W_AUX) useAux = true;  //switch this back to true CHIP 2014-11-04
      openBCI = new OpenBCI_ADS1299(this, openBCI_portName, openBCI_baud, nEEDataValuesPerPacket, useAux, n_aux_ifEnabled); //this also starts the data transfer after XX seconds
      break;
    case DATASOURCE_SYNTHETIC:
      //do nothing
      break;
    case DATASOURCE_PLAYBACKFILE:
      //open and load the data file
      println("OpenBCI_GUI: loading playback data from " + playbackData_fname);
      try {
        playbackData_table = new Table_CSV(playbackData_fname);
      } catch (Exception e) {
        println("setup: could not open file for playback: " + playbackData_fname);
        println("   : quitting...");
        exit();
      }
      println("OpenBCI_GUI: loading complete.  " + playbackData_table.getRowCount() + " rows of data, which is " + round(float(playbackData_table.getRowCount())/openBCI.fs_Hz) + " seconds of EEG data");
      
      //removing first column of data from data file...the first column is a time index and not eeg data
      playbackData_table.removeColumn(0);
      break;
    default: 
  }

  verbosePrint("-- Init 3 --");

  //initilize the GUI
  initializeGUI();
  
  //final config
  // setBiasState(openBCI.isBiasAuto);
  verbosePrint("-- Init 4 --");

  //open data file
  if ((eegDataSource == DATASOURCE_NORMAL) || (eegDataSource == DATASOURCE_NORMAL_W_AUX)) openNewLogFile(fileName);  //open a new log file

  nextPlayback_millis = millis(); //used for synthesizeData and readFromFile.  This restarts the clock that keeps the playback at the right pace.
  
  if(eegDataSource != DATASOURCE_NORMAL && eegDataSource != DATASOURCE_NORMAL_W_AUX){
    systemMode = 10; //tell system it's ok to leave control panel and start interfacing GUI
  }
  //sync GUI default settings with OpenBCI's default settings...
  // syncWithHardware(); //this starts the sequence off ... read in OpenBCI_ADS1299 iterates through the rest based on the ASCII trigger "$$$"
  // verbosePrint("-- Init 5 [COMPLETE] --");
}

int hardwareSyncStep = 0; //start this at 0...
boolean readyToSend = false; //system waits for $$$ after requesting information from OpenBCI board
boolean currentlySyncing = false;
long timeOfLastCommand = 0;

void syncWithHardware(){
  switch (hardwareSyncStep) {
    case 1: //send # of channels (8 or 16) ... (regular or daisy setup)
      println("[1] Sending channel count (" + nchan + ") to OpenBCI...");
      if(nchan == 8){
        serial_openBCI.write('c');
      }
      if(nchan == 16){
        serial_openBCI.write('C');
      }
      break;
    case 2: //reset hardware to default registers 
      println("[2] Reseting OpenBCI registers to default... writing \'d\'...");
      serial_openBCI.write("d"); 
      break;
    case 3: //ask for series of channel setting ASCII values to sync with channel setting interface in GUI
      println("[3] Retrieving OpenBCI's channel settings to sync with GUI... writing \'D\'... waiting for $$$...");
      readyToSend = false; //wait for $$$ to iterate... applies to commands expecting a response
      serial_openBCI.write("D"); 
      break;
    case 4: //check existing registers
      println("[4] Retrieving OpenBCI's full register map for verification... writing \'?\'... waiting for $$$...");
      readyToSend = false; //wait for $$$ to iterate... applies to commands expecting a response
      serial_openBCI.write("?"); 
      break;
    case 5:
      serial_openBCI.write('j'); // send OpenBCI's 'j' commaned to make sure any already open SD file is closed before opening another one...
      switch (sdSetting){
        case 0: //"Do not write to SD"
          //do nothing
          break;
        case 1: //"5 min max"
          serial_openBCI.write("A");
          break;
        case 2: //"5 min max"
          serial_openBCI.write("S");
          break;
        case 3: //"5 min max"
          serial_openBCI.write("F");
          break;
        case 4: //"5 min max"
          serial_openBCI.write("G");
          break;
        case 5: //"5 min max"
          serial_openBCI.write("H");
          break;
        case 6: //"5 min max"
          serial_openBCI.write("J");
          break;
        case 7: //"5 min max"
          serial_openBCI.write("K");
          break;
        case 8: //"5 min max"
          serial_openBCI.write("L");
          break;
      }
      println("[5] Writing selected SD setting (" + sdSettingString + ") to OpenBCI...");
      if(sdSetting != 0){
        readyToSend = false; //wait for $$$ to iterate... applies to commands expecting a response
      }
      break;
    case 6:
      output("The GUI is done intializing. Click outside of the control panel to interact with the GUI.");
      openBCI.changeState(openBCI.STATE_STOPPED);
      systemMode = 10;
      break; 
  }
}

void haltSystem(){
  println("Halting system for reconfiguration of settings...");
  stopRunning();  //stop data transfer

  //reset variables for data processing
  curDataPacketInd = -1;
  lastReadDataPacketInd = -1;
  pointCounter = 0;
  prevBytes = 0; 
  prevMillis=millis();
  byteRate_perSec = 0;
  drawLoop_counter = 0;
  // eegDataSource = -1;
  //set all data source list items inactive

  // stopDataTransfer(); // make sure to stop data transfer, if data is streaming and being drawn

  if ((eegDataSource == DATASOURCE_NORMAL) || (eegDataSource == DATASOURCE_NORMAL_W_AUX)){
    closeLogFile();  //close log file
    if (serial_openBCI != null){
      serial_openBCI.write('j'); // tell the SD file to close if one is open...
      openBCI.closeSerialPort();   //disconnect from serial port
      openBCI.prevState_millis = 0;  //reset OpenBCI_ADS1299 state clock to use as a conditional for timing at the beginnign of systemUpdate()
      hardwareSyncStep = 0; //reset Hardware Sync step to be ready to go again...
    }
  }
  systemMode = 0;
}

void initializeGUI(){

  println("1");
  String filterDescription = eegProcessing.getFilterDescription();
  println("2");
  gui = new Gui_Manager(this, win_x, win_y, nchan, displayTime_sec,default_vertScale_uV,filterDescription, smoothFac[smoothFac_ind]);
  println("3");
  //associate the data to the GUI traces
  gui.initDataTraces(dataBuffX, dataBuffY_filtY_uV, fftBuff, eegProcessing.data_std_uV, is_railed,eegProcessing.polarity);
  println("4");
  //limit how much data is plotted...hopefully to speed things up a little
  gui.setDoNotPlotOutsideXlim(true);
  println("5");
  gui.setDecimateFactor(2);
  println("6");
  // gui.cc.loadDefaultChannelSettings();
  println("7");
}

//======================== DRAW LOOP =============================//
//======================== DRAW LOOP =============================//
//======================== DRAW LOOP =============================//

void draw() {
  drawLoop_counter++;
  systemUpdate();
  systemDraw();
}

void systemUpdate(){ // for updating data values and variables

  //has it been 3000 milliseconds since we initiated the serial port? We want to make sure we wait for the OpenBCI board to finish its setup()
  if(millis() - openBCI.prevState_millis > openBCI.COM_INIT_MSEC && openBCI.prevState_millis != 0 && openBCI.state == openBCI.STATE_COMINIT){
    openBCI.state = openBCI.STATE_SYNCWITHHARDWARE;
    timeOfLastCommand = millis();
  }

  //if we are in SYNC WITH HARDWARE state ... trigger a command
  if(openBCI.state == openBCI.STATE_SYNCWITHHARDWARE && currentlySyncing == false){
    if(millis() - timeOfLastCommand > 200 && readyToSend == true){
      timeOfLastCommand = millis();
      hardwareSyncStep++;
      syncWithHardware();
    }
  }
  
  win_x = width;
  win_y = height;
  // println(width + ", " + height);
  
  //updates while in intro screen
  if(systemMode == 0){

  }
  
  if(systemMode == 10){
    if (isRunning) {
      //get the data, if it is available

      pointCounter = getDataIfAvailable(pointCounter);
      
      //has enough data arrived to process it and update the GUI?
      if (pointCounter >= nPointsPerUpdate) {
        pointCounter = 0;  //reset for next time
  
        //process the data
        processNewData();
  
        //try to detect the desired signals, do it in frequency space...for OpenBCI_GUI_Simpler
        //detectInFreqDomain(fftBuff,inband_Hz,guard_Hz,detData_freqDomain);
        //gui.setDetectionData_freqDomain(detData_freqDomain);
        //tell the GUI that it has received new data via dumping new data into arrays that the GUI has pointers to
        
        // println("packet counter = " + newPacketCounter);
        // for(int i = 0; i < eegProcessing.data_std_uV.length; i++){
        //   println("eegProcessing.data_std_uV[" + i + "] = " + eegProcessing.data_std_uV[i]);
        // }
        if((millis() - timeOfGUIreinitialize) > reinitializeGUIdelay){ //wait 1 second for GUI to reinitialize
          // gui.update(eegProcessing.data_std_uV,data_elec_imp_ohm);
          // println("attempting to update GUI...");
          try{
            gui.update(eegProcessing.data_std_uV,data_elec_imp_ohm);
          } catch (Exception e){
            println(e.getMessage());
            reinitializeGUIdelay = reinitializeGUIdelay * 2;
            println("New GUI reinitialize delay = " + reinitializeGUIdelay);
          }
        }
        else{
          println("reinitializing GUI after resize... not updating GUI");
        }
        
        ///add raw data to spectrogram...if the correct channel...
        //...look for the first channel that is active (meaning button is not active) or, if it
        //     hasn't yet sent any data, send the last channel even if the channel is off
  //      if (sendToSpectrogram & (!(gui.chanButtons[Ichan].isActive()) | (Ichan == (nchan-1)))) { //send data to spectrogram
  //        sendToSpectrogram = false;  //prevent us from sending more data after this time through
  //        for (int Idata=0;Idata < nPointsPerUpdate;Idata++) {
  //          gui.spectrogram.addDataPoint(yLittleBuff_uV[Ichan][Idata]);
  //          gui.tellGUIWhichChannelForSpectrogram(Ichan);
  //          //gui.spectrogram.addDataPoint(100.0f+(float)Idata);
  //        }
  //      }
          
        redrawScreenNow=true;
      } 
      else {
        //not enough data has arrived yet... only update the channel controller
      }
    }

    gui.cc.update(); //update Channel Controller even when not updating certain parts of the GUI... (this is a bit messy...)
    updateButtons(); //make sure all system buttons are up to date

    //re-initialize GUI if screen has been resized and it's been more than 1/2 seccond (to prevent reinitialization of GUI from happening too often)
    if(screenHasBeenResized == true && (millis() - timeOfLastScreenResize) > reinitializeGUIdelay){
      screenHasBeenResized = false;
      println("reinitializing GUI");
      timeOfGUIreinitialize = millis();
      initializeGUI();
    }
  }

  controlPanel.update();
}

void systemDraw(){ //for drawing to the screen
    
  //redraw the screen...not every time, get paced by when data is being plotted    
  background(bgColor);  //clear the screen

  if(systemMode == 10){
    int drawLoopCounter_thresh = 100;
    if ((redrawScreenNow) || (drawLoop_counter >= drawLoopCounter_thresh)) {
      //if (drawLoop_counter >= drawLoopCounter_thresh) println("OpenBCI_GUI: redrawing based on loop counter...");
      drawLoop_counter=0; //reset for next time
      redrawScreenNow = false;  //reset for next time
      
      //update the title of the figure;
      switch (eegDataSource) {
        case DATASOURCE_NORMAL: case DATASOURCE_NORMAL_W_AUX:
          frame.setTitle(int(frameRate) + " fps, Byte Count = " + openBCI_byteCount + ", bit rate = " + byteRate_perSec*8 + " bps" + ", " + int(float(fileoutput.getRowsWritten())/openBCI.fs_Hz) + " secs Saved, Writing to " + output_fname);
          break;
        case DATASOURCE_SYNTHETIC:
          frame.setTitle(int(frameRate) + " fps, Using Synthetic EEG Data");
          break;
        case DATASOURCE_PLAYBACKFILE:
          frame.setTitle(int(frameRate) + " fps, Playing " + int(float(currentTableRowIndex)/openBCI.fs_Hz) + " of " + int(float(playbackData_table.getRowCount())/openBCI.fs_Hz) + " secs, Reading from: " + playbackData_fname);
          break;
      } 
    }

    //wait 1 second for GUI to reinitialize
    if((millis() - timeOfGUIreinitialize) > reinitializeGUIdelay){ 
      // println("attempting to draw GUI...");
      try{
        // println("GUI DRAW!!! " + millis());
        gui.draw(); //draw the GUI
      } catch (Exception e){
        println(e.getMessage());
        reinitializeGUIdelay = reinitializeGUIdelay * 2;
        println("New GUI reinitialize delay = " + reinitializeGUIdelay);
      }
    }
    else{
      //reinitializing GUI after resize
      println("reinitializing GUI after resize... not drawing GUI");
    }

  }

  //control panel
  if(controlPanel.isOpen){
    controlPanel.draw();
  }
  controlPanelCollapser.draw();
  helpWidget.draw();

  if((openBCI.state == openBCI.STATE_COMINIT || openBCI.state == openBCI.STATE_SYNCWITHHARDWARE) && systemMode == 0){
    //make out blink the text "Initalizing GUI..."
    if(millis()%1000 < 500){
      output("Iniitializing communication w/ your OpenBCI board...");
    } else{
      output("");
    }

    if(millis() - timeOfInit > 10000){
      haltSystem();
      initSystemButton.but_txt = "START SYSTEM";
      output("Init timeout. Verify your Serial/COM Port. Power DOWN/UP your OpenBCI & USB Dongle. Then retry Initialization.");
    }
  }

  // use commented code below to verify frameRate and check latency
  // println("Time since start: " + millis() + " || Time since last frame: " + str(millis()-timeOfLastFrame));
  // timeOfLastFrame = millis();
}

//called from systemUpdate when mode=10 and isRunning = true
int getDataIfAvailable(int pointCounter) {
  
  if ( (eegDataSource == DATASOURCE_NORMAL) || (eegDataSource == DATASOURCE_NORMAL_W_AUX) ) {
    //get data from serial port as it streams in

      //first, get the new data (if any is available)
      // openBCI.finalizeCOMINIT(); //this is trying to listen to the openBCI hardware.  New data is put into dataPacketBuff and increments curDataPacketInd.
      
      //next, gather any new data into the "little buffer"
      while ( (curDataPacketInd != lastReadDataPacketInd) && (pointCounter < nPointsPerUpdate)) {
        lastReadDataPacketInd = (lastReadDataPacketInd+1) % dataPacketBuff.length;  //increment to read the next packet
        for (int Ichan=0; Ichan < nchan; Ichan++) {   //loop over each cahnnel
          //scale the data into engineering units ("microvolts") and save to the "little buffer"
          yLittleBuff_uV[Ichan][pointCounter] = dataPacketBuff[lastReadDataPacketInd].values[Ichan] * openBCI.scale_fac_uVolts_per_count;
        } 
        pointCounter++; //increment counter for "little buffer"
      }
  } else {
    // make or load data to simulate real time
        
    //has enough time passed?
    int current_millis = millis();
    if (current_millis >= nextPlayback_millis) {
      //prepare for next time
      int increment_millis = int(round(float(nPointsPerUpdate)*1000.f/openBCI.fs_Hz)/playback_speed_fac);
      if (nextPlayback_millis < 0) nextPlayback_millis = current_millis;
      nextPlayback_millis += increment_millis;

      // generate or read the data
      lastReadDataPacketInd = 0;
      for (int i = 0; i < nPointsPerUpdate; i++) {
        // println();
        dataPacketBuff[lastReadDataPacketInd].sampleIndex++;
        switch (eegDataSource) {
          case DATASOURCE_SYNTHETIC: //use synthetic data (for GUI debugging)   
            synthesizeData(nchan, openBCI.fs_Hz, openBCI.scale_fac_uVolts_per_count, dataPacketBuff[lastReadDataPacketInd]);
            break;
          case DATASOURCE_PLAYBACKFILE: 
            currentTableRowIndex=getPlaybackDataFromTable(playbackData_table,currentTableRowIndex,openBCI.scale_fac_uVolts_per_count, dataPacketBuff[lastReadDataPacketInd]);
            break;
          default:
            //no action
        }
        //gather the data into the "little buffer"
        for (int Ichan=0; Ichan < nchan; Ichan++) {
          //scale the data into engineering units..."microvolts"
          yLittleBuff_uV[Ichan][pointCounter] = dataPacketBuff[lastReadDataPacketInd].values[Ichan]* openBCI.scale_fac_uVolts_per_count;
        }
        pointCounter++;
      } //close the loop over data points
      //if (eegDataSource==DATASOURCE_PLAYBACKFILE) println("OpenBCI_GUI: getDataIfAvailable: currentTableRowIndex = " + currentTableRowIndex);
      //println("OpenBCI_GUI: getDataIfAvailable: pointCounter = " + pointCounter);
    } // close "has enough time passed"
  } 
  return pointCounter;
}

void processNewData() {

  byteRate_perSec = (int)(1000.f * ((float)(openBCI_byteCount - prevBytes)) / ((float)(millis() - prevMillis)));
  prevBytes = openBCI_byteCount; 
  prevMillis=millis();
  float foo_val;
  float prevFFTdata[] = new float[fftBuff[0].specSize()];
  double foo;

  //update the data buffers
  for (int Ichan=0;Ichan < nchan; Ichan++) {
    //append the new data to the larger data buffer...because we want the plotting routines
    //to show more than just the most recent chunk of data.  This will be our "raw" data.
    appendAndShift(dataBuffY_uV[Ichan], yLittleBuff_uV[Ichan]);
    
    //make a copy of the data that we'll apply processing to.  This will be what is displayed on the full montage
    dataBuffY_filtY_uV[Ichan] = dataBuffY_uV[Ichan].clone();
  }
    
  //if you want to, re-reference the montage to make it be a mean-head reference
  if (false) rereferenceTheMontage(dataBuffY_filtY_uV);
  
  //update the FFT (frequency spectrum)
  for (int Ichan=0;Ichan < nchan; Ichan++) {  

    //copy the previous FFT data...enables us to apply some smoothing to the FFT data
    for (int I=0; I < fftBuff[Ichan].specSize(); I++) prevFFTdata[I] = fftBuff[Ichan].getBand(I); //copy the old spectrum values
    
    //prepare the data for the new FFT
    float[] fooData_raw = dataBuffY_uV[Ichan];  //use the raw data for the FFT
    fooData_raw = Arrays.copyOfRange(fooData_raw, fooData_raw.length-Nfft, fooData_raw.length);   //trim to grab just the most recent block of data
    float meanData = mean(fooData_raw);  //compute the mean
    for (int I=0; I < fooData_raw.length; I++) fooData_raw[I] -= meanData; //remove the mean (for a better looking FFT
    
    //compute the FFT
    fftBuff[Ichan].forward(fooData_raw); //compute FFT on this channel of data
    
    
    
//    //convert units on fft data
//    if (false) {
//      //convert units to uV_per_sqrtHz...is this still correct?? CHIP 2014-10-24
//      //final float mean_winpow_sqr = 0.3966;  //account for power lost when windowing...mean(hamming(N).^2) = 0.3966
//      final float mean_winpow = 1.0f/sqrt(2.0f);  //account for power lost when windowing...mean(hamming(N).^2) = 0.3966
//      final float scale_raw_to_rtHz = pow((float)fftBuff[0].specSize(),1)*fs_Hz*mean_winpow; //normalize the amplitude by the number of bins to get the correct scaling to uV/sqrt(Hz)???
//      double foo;
//      for (int I=0; I < fftBuff[Ichan].specSize(); I++) {  //loop over each FFT bin
//        foo = sqrt(pow(fftBuff[Ichan].getBand(I),2)/scale_raw_to_rtHz);
//        fftBuff[Ichan].setBand(I,(float)foo);
//        //if ((Ichan==0) & (I > 5) & (I < 15)) println("processFreqDomain: uV/rtHz = " + I + " " + foo);
//      }
//    } else {
      //convert to uV_per_bin...still need to confirm the accuracy of this code.  
      //Do we need to account for the power lost in the windowing function?   CHIP  2014-10-24
        for (int I=0; I < fftBuff[Ichan].specSize(); I++) {  //loop over each FFT bin
          fftBuff[Ichan].setBand(I,(float)(fftBuff[Ichan].getBand(I) / fftBuff[Ichan].specSize()));
        }       
//    }
    
    //average the FFT with previous FFT data so that it makes it smoother in time
    double min_val = 0.01d;
    for (int I=0; I < fftBuff[Ichan].specSize(); I++) {   //loop over each fft bin
      if (prevFFTdata[I] < min_val) prevFFTdata[I] = (float)min_val; //make sure we're not too small for the log calls
      foo = fftBuff[Ichan].getBand(I); if (foo < min_val) foo = min_val; //make sure this value isn't too small
      
       if (true) {
        //smooth in dB power space
        foo =   (1.0d-smoothFac[smoothFac_ind]) * java.lang.Math.log(java.lang.Math.pow(foo,2));
        foo += smoothFac[smoothFac_ind] * java.lang.Math.log(java.lang.Math.pow((double)prevFFTdata[I],2)); 
        foo = java.lang.Math.sqrt(java.lang.Math.exp(foo)); //average in dB space
      } else { 
        //smooth (average) in linear power space
        foo =   (1.0d-smoothFac[smoothFac_ind]) * java.lang.Math.pow(foo,2);
        foo+= smoothFac[smoothFac_ind] * java.lang.Math.pow((double)prevFFTdata[I],2); 
        // take sqrt to be back into uV_rtHz
        foo = java.lang.Math.sqrt(foo);
      }
      fftBuff[Ichan].setBand(I,(float)foo); //put the smoothed data back into the fftBuff data holder for use by everyone else
    } //end loop over FFT bins
  } //end the loop over channels.
  
  //apply additional processing for the time-domain montage plot (ie, filtering)
  eegProcessing.process(yLittleBuff_uV,dataBuffY_uV,dataBuffY_filtY_uV,fftBuff);
  
  //apply user processing
  // ...yLittleBuff_uV[Ichan] is the most recent raw data since the last call to this processing routine
  // ...dataBuffY_filtY_uV[Ichan] is the full set of filtered data as shown in the time-domain plot in the GUI
  // ...fftBuff[Ichan] is the FFT data structure holding the frequency spectrum as shown in the freq-domain plot in the GUI
  eegProcessing_user.process(yLittleBuff_uV,dataBuffY_uV,dataBuffY_filtY_uV,fftBuff);
  
  //look to see if the latest data is railed so that we can notify the user on the GUI
  for (int Ichan=0;Ichan < nchan; Ichan++) is_railed[Ichan].update(dataPacketBuff[lastReadDataPacketInd].values[Ichan]);

  //compute the electrode impedance. Do it in a very simple way [rms to amplitude, then uVolt to Volt, then Volt/Amp to Ohm]
  for (int Ichan=0;Ichan < nchan; Ichan++) data_elec_imp_ohm[Ichan] = (sqrt(2.0)*eegProcessing.data_std_uV[Ichan]*1.0e-6) / openBCI.leadOffDrive_amps;     
}

//here is the routine that listens to the serial port.
//if any data is waiting, get it, parse it, and stuff it into our vector of 
//pre-allocated dataPacketBuff
void serialEvent(Serial port) {
  //check to see which serial port it is
  // if (port == openBCI.serial_openBCI) {
  // println("SE " + millis());
  if (port == serial_openBCI) {
    // boolean echoBytes = !openBCI.isStateNormal(); 
    boolean echoBytes;

    if(openBCI.isStateNormal() != true){  // || printingRegisters == true){
      echoBytes = true;
    } else{
      echoBytes = false;
    }

    // openBCI.read(true);
    openBCI.read(echoBytes);
    openBCI_byteCount++;
    if (openBCI.isNewDataPacketAvailable) {
      //copy packet into buffer of data packets
      curDataPacketInd = (curDataPacketInd+1) % dataPacketBuff.length; //this is also used to let the rest of the code that it may be time to do something
      openBCI.copyDataPacketTo(dataPacketBuff[curDataPacketInd]);  //resets isNewDataPacketAvailable to false
      
      // //write this chunk of data to file
      // println("-------------------------------------------------------------------------");
      // println("New Packet Available [" + tempCounter + "]");
      // println("dataPacketBuff[curDataPacketInd] = " + dataPacketBuff[curDataPacketInd]);
      // println("openBCI.scale_fac_uVolts_per_count = " + openBCI.scale_fac_uVolts_per_count);
      // println("nchan = " + nchan);
      newPacketCounter++;

      fileoutput.writeRawData_dataPacket(dataPacketBuff[curDataPacketInd],openBCI.scale_fac_uVolts_per_count,openBCI.scale_fac_accel_G_per_count);
    }
  } 
  else {
    inByte = port.read();
  }
}

String getDateString() {
    String fname = year() + "-";
    if (month() < 10) fname=fname+"0";
    fname = fname + month() + "-";
    if (day() < 10) fname = fname + "0";
    fname = fname + day(); 
    
    fname = fname + "_";
    if (hour() < 10) fname = fname + "0";
    fname = fname + hour() + "-";
    if (minute() < 10) fname = fname + "0";
    fname = fname + minute() + "-";
    if (second() < 10) fname = fname + "0";
    fname = fname + second();
    return fname;
}
  
//swtich yard if a click is detected
void mousePressed() {

  verbosePrint("mousePressed");
  
  //if not in initial setup...
  if(systemMode >= 10){

    //limit interactivity of main GUI if control panel is open
    if(controlPanel.isOpen == false){
      //was the stopButton pressed?

      gui.mousePressed(); // trigger mousePressed function in GUI
      //most of the logic below should be migrated into the Gui_manager specific function above

      if (gui.stopButton.isMouseHere()) { 
        gui.stopButton.setIsActive(true);
        stopButtonWasPressed(); 
      }
      
      // //was the gui page button pressed?
      // if (gui.guiPageButton.isMouseHere()) {
      //   gui.guiPageButton.setIsActive(true);
      //   gui.incrementGUIpage();
      // }

      //check the buttons
      switch (gui.guiPage) {
        case Gui_Manager.GUI_PAGE_CHANNEL_ONOFF:
          //check the channel buttons
          for (int Ibut = 0; Ibut < gui.chanButtons.length; Ibut++) {
            if (gui.chanButtons[Ibut].isMouseHere()) { 
              toggleChannelState(Ibut);
            }
          }

          //check the detection button
          //if (gui.detectButton.updateIsMouseHere()) toggleDetectionState();      
          //check spectrogram button
          //if (gui.spectrogramButton.updateIsMouseHere()) toggleSpectrogramState();
          
          break;
        case Gui_Manager.GUI_PAGE_IMPEDANCE_CHECK:
          // ============ DEPRECATED ============== //
          // //check the impedance buttons
          // for (int Ibut = 0; Ibut < gui.impedanceButtonsP.length; Ibut++) {
          //   if (gui.impedanceButtonsP[Ibut].isMouseHere()) { 
          //     toggleChannelImpedanceState(gui.impedanceButtonsP[Ibut],Ibut,0);
          //   }
          //   if (gui.impedanceButtonsN[Ibut].isMouseHere()) { 
          //     toggleChannelImpedanceState(gui.impedanceButtonsN[Ibut],Ibut,1);
          //   }
          // }
          // if (gui.biasButton.isMouseHere()) { 
          //   gui.biasButton.setIsActive(true);
          //   setBiasState(!openBCI.isBiasAuto);
          // }      
          // break;
        case Gui_Manager.GUI_PAGE_HEADPLOT_SETUP:
          if (gui.intensityFactorButton.isMouseHere()) {
            gui.intensityFactorButton.setIsActive(true);
            gui.incrementVertScaleFactor();
          }
          if (gui.loglinPlotButton.isMouseHere()) {
            gui.loglinPlotButton.setIsActive(true);
            gui.set_vertScaleAsLog(!gui.vertScaleAsLog); //toggle the state
          }
          if (gui.filtBPButton.isMouseHere()) {
            gui.filtBPButton.setIsActive(true);
            incrementFilterConfiguration();
          }
          if (gui.smoothingButton.isMouseHere()) {
            gui.smoothingButton.setIsActive(true);
            incrementSmoothing();
          }
          if (gui.showPolarityButton.isMouseHere()) {
            gui.showPolarityButton.setIsActive(true);
            toggleShowPolarity();
          }
          if (gui.maxDisplayFreqButton.isMouseHere()) {
            gui.maxDisplayFreqButton.setIsActive(true);
            gui.incrementMaxDisplayFreq();
          }
          
    //      //check the detection button
    //      if (gui.detectButton.updateIsMouseHere()) {
    //       gui.detectButton.setIsActive(true);
    //       toggleDetectionState();
    //      }      
    //      //check spectrogram button
    //      if (gui.spectrogramButton.updateIsMouseHere()) {
    //        gui.spectrogramButton.setIsActive(true);
    //        toggleSpectrogramState();
    //      }

          break;
        //default:
      }
      
      //check the graphs
      if (gui.isMouseOnFFT(mouseX,mouseY)) {
        GraphDataPoint dataPoint = new GraphDataPoint();
        gui.getFFTdataPoint(mouseX,mouseY,dataPoint);
        println("OpenBCI_GUI: FFT data point: " + String.format("%4.2f",dataPoint.x) + " " + dataPoint.x_units + ", " + String.format("%4.2f",dataPoint.y) + " " + dataPoint.y_units);
      } else if (gui.headPlot1.isPixelInsideHead(mouseX,mouseY)) {
        //toggle the head plot contours
        gui.headPlot1.drawHeadAsContours = !gui.headPlot1.drawHeadAsContours;
      } else if (gui.isMouseOnMontage(mouseX,mouseY)) {
        //toggle the display of the montage values
        gui.showMontageValues  = !gui.showMontageValues;
      }
    }
  }

  //=============================//
  // CONTROL PANEL INTERACTIVITY //
  //=============================//

  //was control panel button pushed
  if (controlPanelCollapser.isMouseHere()) {
    if(controlPanelCollapser.isActive && systemMode == 10){
      controlPanelCollapser.setIsActive(false);
      controlPanel.isOpen = false;
    }
    else{
      controlPanelCollapser.setIsActive(true);
      controlPanel.isOpen = true;
    }
  } else{
    if(controlPanel.isOpen){
      controlPanel.CPmousePressed();
    }
  }

  //interacting with control panel
  if(controlPanel.isOpen){
    //close control panel if you click outside...
    if(systemMode == 10){
      if(mouseX > 0 && mouseX < controlPanel.w && mouseY > 0 && mouseY < controlPanel.initBox.y+controlPanel.initBox.h){
        println("clicked in CP box");
        controlPanel.CPmousePressed();
      }
      //if clicked out of panel
      else{
        println("outside of CP clicked");
        controlPanel.isOpen = false;
        controlPanelCollapser.setIsActive(false);
        output("Press the \"Press to Start\" button to initialize the data stream.");
      }
    }
  }

  redrawScreenNow = true;  //command a redraw of the GUI whenever the mouse is pressed
}

void mouseReleased() {

  verbosePrint("mouseReleased");

  //some buttons light up only when being actively pressed.  Now that we've
  //released the mouse button, turn off those buttons.

  //interacting with control panel
  if(controlPanel.isOpen){
    //if clicked in panel
    controlPanel.CPmouseReleased();
  }

  if(systemMode >= 10){

    gui.mouseReleased();
    redrawScreenNow = true;  //command a redraw of the GUI whenever the mouse is released
  }

  if(screenHasBeenResized){
    println("screen has been resized...");
    screenHasBeenResized = false;
  }
}

void printRegisters(){
  if (serial_openBCI != null) {
    println("Writing ? to OpenBCI...");
    serial_openBCI.write('?');
  }
  // printingRegisters = true;
}

void stopRunning() {
    // openBCI.changeState(0); //make sure it's no longer interpretting as binary
    verbosePrint("stopRunning...");
    output("Data stream stopped.");
    if (openBCI != null) {
      openBCI.stopDataTransfer();
    }
    timeSinceStopRunning = millis(); //used as a timer to prevent misc. bytes from flooding serial...
    isRunning = false;
    // openBCI.changeState(0); //make sure it's no longer interpretting as binary
    // systemMode = 0;
    // closeLogFile();
}

void startRunning() {
    verbosePrint("startRunning...");
    output("Data stream started.");
    if ((eegDataSource == DATASOURCE_NORMAL) || (eegDataSource == DATASOURCE_NORMAL_W_AUX)) {
      if (openBCI != null) openBCI.startDataTransfer();
    }
    isRunning = true;
}

//execute this function whenver the stop button is pressed
void stopButtonWasPressed() {
  //toggle the data transfer state of the ADS1299...stop it or start it...
  if (isRunning) {
    println("openBCI_GUI: stopButton was pressed...stopping data transfer...");
    stopRunning();
  } 
  else { //not running
    println("openBCI_GUI: startButton was pressed...starting data transfer...");
    startRunning();
    nextPlayback_millis = millis();  //used for synthesizeData and readFromFile.  This restarts the clock that keeps the playback at the right pace.
  }
}

void updateButtons(){
  //update the stop button with new text based on the current running state
  //gui.stopButton.setActive(isRunning);
  if (isRunning) {
    //println("OpenBCI_GUI: stopButtonWasPressed (a): changing string to " + Gui_Manager.stopButton_pressToStop_txt);
    gui.stopButton.setString(Gui_Manager.stopButton_pressToStop_txt); 
  } 
  else {
    //println("OpenBCI_GUI: stopButtonWasPressed (a): changing string to " + Gui_Manager.stopButton_pressToStart_txt);
    gui.stopButton.setString(Gui_Manager.stopButton_pressToStart_txt);
  }
}

final float sine_freq_Hz = 10.0f;
float sine_phase_rad = 0.0;
void synthesizeData(int nchan, float fs_Hz, float scale_fac_uVolts_per_count, DataPacket_ADS1299 curDataPacket) {
  float val_uV;
  for (int Ichan=0; Ichan < nchan; Ichan++) {
    if (isChannelActive(Ichan)) { 
      val_uV = randomGaussian()*sqrt(fs_Hz/2.0f); // ensures that it has amplitude of one unit per sqrt(Hz) of signal bandwidth
      //val_uV = random(1)*sqrt(fs_Hz/2.0f); // ensures that it has amplitude of one unit per sqrt(Hz) of signal bandwidth
      if (Ichan==0) val_uV*= 10f;  //scale one channel higher
      
      if (Ichan==1) {
        //add sine wave at 10 Hz at 10 uVrms
        sine_phase_rad += 2.0f*PI * sine_freq_Hz / fs_Hz;
        if (sine_phase_rad > 2.0f*PI) sine_phase_rad -= 2.0f*PI;
        val_uV += 10.0f * sqrt(2.0)*sin(sine_phase_rad);
      }
    } 
    else {
      val_uV = 0.0f;
    }
    curDataPacket.values[Ichan] = (int) (0.5f+ val_uV / scale_fac_uVolts_per_count); //convert to counts, the 0.5 is to ensure rounding
  }
}

int getPlaybackDataFromTable(Table datatable, int currentTableRowIndex, float scale_fac_uVolts_per_count, DataPacket_ADS1299 curDataPacket) {
  float val_uV = 0.0f;
  
  //check to see if we can load a value from the table
  if (currentTableRowIndex >= datatable.getRowCount()) {
    //end of file
    println("OpenBCI_GUI: hit the end of the playback data file.  starting over...");
    //if (isRunning) stopRunning();
    currentTableRowIndex = 0;
  } else {
    //get the row
    TableRow row = datatable.getRow(currentTableRowIndex);
    currentTableRowIndex++; //increment to the next row
    
    //get each value
    for (int Ichan=0; Ichan < nchan; Ichan++) {
      if (isChannelActive(Ichan) && (Ichan < datatable.getColumnCount())) {
        val_uV = row.getFloat(Ichan);
      } else {
        //use zeros for the missing channels
        val_uV = 0.0f;
      }

      //put into data structure
      curDataPacket.values[Ichan] = (int) (0.5f+ val_uV / scale_fac_uVolts_per_count); //convert to counts, the 0.5 is to ensure rounding
    }
  }
  return currentTableRowIndex;
}

//toggleChannelState: : Ichan is [0 nchan-1]
void toggleChannelState(int Ichan) {
  if ((Ichan >= 0) && (Ichan < gui.chanButtons.length)) {
    if (isChannelActive(Ichan)) {
      deactivateChannel(Ichan);      
    } 
    else {
      activateChannel(Ichan);
    }
  }
}

//Ichan is zero referenced (not one referenced)
boolean isChannelActive(int Ichan) {
  boolean return_val = false;
  
  //account for 16 channel case...because the channel 9-16 (aka 8-15) are coupled to channels 1-8 (aka 0-7)
  // if ((Ichan > 7) && (OpenBCI_Nchannels > 8)) Ichan = Ichan - 8;
  if ((Ichan > 7) && (nchan > 8)) Ichan = Ichan - 8;

    
  //now check the state of the corresponding channel button
  if ((Ichan >= 0) && (Ichan < gui.chanButtons.length)) {
    boolean button_is_pressed = gui.chanButtons[Ichan].isActive();
    if (button_is_pressed) { //button is pressed, which means the channel was NOT active
      return_val = false;
    } else { //button is not pressed, so channel is active
      return_val = true;
    }
  }
  return return_val;
}

//activateChannel: Ichan is [0 nchan-1] (aka zero referenced)
void activateChannel(int Ichan) {
  println("OpenBCI_GUI: activating channel " + (Ichan+1));
  if(eegDataSource == DATASOURCE_NORMAL || eegDataSource == DATASOURCE_NORMAL_W_AUX){
    if (serial_openBCI != null){
      verbosePrint("**");
      openBCI.changeChannelState(Ichan, true); //activate
    }
  }
  if (Ichan < gui.chanButtons.length){
    gui.chanButtons[Ichan].setIsActive(false); //an active channel is a light-colored NOT-ACTIVE button
    channelSettingValues[Ichan][0] = '0'; 
    gui.cc.update();
  }
}  
void deactivateChannel(int Ichan) {
  println("OpenBCI_GUI: deactivating channel " + (Ichan+1));
  if(eegDataSource == DATASOURCE_NORMAL || eegDataSource == DATASOURCE_NORMAL_W_AUX){
    if (serial_openBCI != null) {
      verbosePrint("***");
      openBCI.changeChannelState(Ichan, false); //de-activate
    }
  }
  if (Ichan < gui.chanButtons.length) {
    gui.chanButtons[Ichan].setIsActive(true); //a deactivated channel is a dark-colored ACTIVE button
    channelSettingValues[Ichan][0] = '1'; 
    gui.cc.update();
  }
}

//void toggleDetectionState() {
//  gui.detectButton.setIsActive(!gui.detectButton.isActive());
//  showFFTFilteringData = gui.detectButton.isActive();
//  gui.showFFTFilteringData(showFFTFilteringData);
//}
//
//void toggleSpectrogramState() {
//  gui.spectrogramButton.setIsActive(!gui.spectrogramButton.isActive());
//  gui.setShowSpectrogram(gui.spectrogramButton.isActive());
//



// void toggleChannelImpedanceState(Button but, int Ichan, int code_P_N_Both) {
//   boolean newstate = false;
//   println("OpenBCI_GUI: toggleChannelImpedanceState: Ichan " + Ichan + ", code_P_N_Both " + code_P_N_Both);
//   if ((Ichan >= 0) && (Ichan < gui.impedanceButtonsP.length)) {

//     //find what state we were, because that sets what state we need
//     newstate = !(but.isActive()); //toggle the state

//     //set the desired impedance state
//     setChannelImpedanceState(Ichan,newstate,code_P_N_Both);
//   }
// }


// ========= DEPRECATED =========== //
// void setChannelImpedanceState(int Ichan,boolean newstate,int code_P_N_Both) {
//   if ((Ichan >= 0) && (Ichan < gui.impedanceButtonsP.length)) {
//     //change the state of the OpenBCI channel itself
//     if (openBCI != null) openBCI.changeImpedanceState(Ichan,newstate,code_P_N_Both);
    
//     //now update the button state
//     if ((code_P_N_Both == 0) || (code_P_N_Both == 2)) {
//       //set the P channel
//       gui.impedanceButtonsP[Ichan].setIsActive(newstate);
//     } else if ((code_P_N_Both == 1) || (code_P_N_Both == 2)) {
//       //set the N channel
//       gui.impedanceButtonsN[Ichan].setIsActive(newstate);
//     }
//   }
// }


//=========== DEPRECATED w/ CHANNEL CONTROLLER ===========//
// void setBiasState(boolean state) {
//   openBCI.isBiasAuto = state;
  
//   //send message to openBCI
//   if (openBCI != null) openBCI.setBiasAutoState(state);
  
//   //change button text
//   if (openBCI.isBiasAuto) {
//     gui.biasButton.but_txt = "Bias\nAuto";
//   } else {
//     gui.biasButton.but_txt = "Bias\nFixed";
//   }
// }

void openNewLogFile(String _fileName) {
  //close the file if it's open
  if (fileoutput != null) {
    println("OpenBCI_GUI: closing log file");
    closeLogFile();
  }
  
  //open the new file
  fileoutput = new OutputFile_rawtxt(openBCI.fs_Hz, _fileName);
  output_fname = fileoutput.fname;
  println("openBCI: openNewLogFile: opened output file: " + output_fname);
  output("openBCI: openNewLogFile: opened output file: " + output_fname);
}

void closeLogFile() {
  if (fileoutput != null) fileoutput.closeFile();
}

void incrementFilterConfiguration() {
  eegProcessing.incrementFilterConfiguration();
  
  //update the button strings
//  gui.filtBPButton.but_txt = "BP Filt\n" + filtCoeff_bp[currentFilt_ind].short_name;
//  gui.titleMontage.string = "EEG Data (" + filtCoeff_bp[currentFilt_ind].name + ", " + filtCoeff_notch[currentFilt_ind].name + ")"; 
  gui.filtBPButton.but_txt = "BP Filt\n" + eegProcessing.getShortFilterDescription();
  gui.titleMontage.string = "EEG Data (" + eegProcessing.getFilterDescription() + ")"; 
  
}
  
void incrementSmoothing() {
  smoothFac_ind++;
  if (smoothFac_ind >= N_SMOOTHEFAC) smoothFac_ind = 0;
  
  //tell the GUI
  gui.setSmoothFac(smoothFac[smoothFac_ind]);
  
  //update the button
  gui.smoothingButton.but_txt = "Smooth\n" + smoothFac[smoothFac_ind];
}

void toggleShowPolarity() {
  gui.headPlot1.use_polarity = !gui.headPlot1.use_polarity;
  
  //update the button
  gui.showPolarityButton.but_txt = "Show Polarity\n" + gui.headPlot1.getUsePolarityTrueFalse();
}

void fileSelected(File selection) {  //called by the Open File dialog box after a file has been selected
  if (selection == null) {
    println("no selection so far...");
  } else {
    //inputFile = selection;
    playbackData_fname = selection.getAbsolutePath();
  }
}

void verbosePrint(String _string){
  if(isVerbose){
    println(_string);
  }
}

void delay(int delay)
{
  int time = millis();
  while(millis() - time <= delay);
}

// here's a function to catch whenever the window is being closed, so that
// it stops OpenBCI
// from: http://forum.processing.org/one/topic/run-code-on-exit.html

// must add "prepareExitHandler();" in setup() for Processing sketches 
// private void prepareExitHandler () {
//  Runtime.getRuntime().addShutdownHook(
//    new Thread(new Runnable() {
//        public void run () {
//          //System.out.println("SHUTDOWN HOOK");
//          println("OpenBCI_GUI: executing shutdown code...");
//          try {
//            stopRunning();
//            if (openBCI != null) {
//              openBCI.closeSerialPort();
//            }
//            stop();
//          } catch (Exception ex) {
//            ex.printStackTrace(); // not much else to do at this point
//          }
//        }
//      }
//    )
//  );
// }  



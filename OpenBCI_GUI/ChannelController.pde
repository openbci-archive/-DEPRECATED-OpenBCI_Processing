class ChannelController {

	public float x1, y1, w1, h1, x2, y2, w2, h2; //all 1 values refer to the left panel that is always visible ... al 2 values refer to the right panel that is only visible when showFullController = true
	public int montage_w, montage_h;
	public int rowHeight;
	public int buttonSpacing;
	boolean showFullController = false;

	int spacer1 = 3;
	int spacer2 = 5; //space between buttons

	int numSettingsPerChannel = 6; //each channel has 6 different settings

	// [Number of Channels] x 6 array of buttons for channel settings
	Button[][] channelSettingButtons = new Button [nchan][numSettingsPerChannel];  // [channel#][Button#]
	char[][] channelSettingValues = new char [nchan][numSettingsPerChannel]; // [channel#][Button#-value] ... this will incfluence text of button

	//buttons just to the left of 
	Button[][] impedanceCheckButtons = new Button [nchan][2];
	char [][] impedanceCheckValues = new char [nchan][2];

	// Array for storing SRB2 history settings of channels prior to shutting off .. so you can return to previous state when reactivating channel
	char[] previousSRB2 = new char [nchan];
	// Array for storing SRB2 history settings of channels prior to shutting off .. so you can return to previous state when reactivating channel
	char[] previousBIAS = new char [nchan];

	//maximum different values for the different settings (Power Down, Gain, Input Type, BIAS, SRB2, SRB1) of 
	//refer to page 44 of ADS1299 Datasheet: http://www.ti.com/lit/ds/symlink/ads1299.pdf
	char[] maxValuesPerSetting = {
		'1', // Power Down :: (0)ON, (1)OFF
		'6', // Gain :: (0) x1, (1) x2, (2) x4, (3) x6, (4) x8, (5) x12, (6) x24 ... default
		'7', // Channel Input :: (0)Normal Electrode Input, (1)Input Shorted, (2)Used in conjunction with BIAS_MEAS, (3)MVDD for supply measurement, (4)Temperature Sensor, (5)Test Signal, (6)BIAS_DRP ... positive electrode is driver, (7)BIAS_DRN ... negative electrode is driver
		'1', // BIAS :: (0) Yes, (1) No
		'1', // SRB2 :: (0) Open, (1) Closed
		'1'}; // SRB1 :: (0) Yes, (1) No ... this setting affects all channels ... either all on or all off

	//variables used for channel write timing in writeChannelSettings()
	long timeOfLastWrite = 0;
	boolean isWritingChannel = false;
	int channelToWrite = -1;
	int writeCounter = 0;

	boolean rewriteWhenDoneWriting = false;
	int channelToWriteWhenDoneWriting = 0;

	ChannelController(float _xPos, float _yPos, float _width, float _height, int _montage_w, int _montage_h){
		//positioning values for left panel (that is always visible)
		x1 = _xPos;
		y1 = _yPos;
		w1 = _width;
		h1 = _height;

		//positioning values for right panel that is only visible when showFullController = true (behind the graph)
		x2 = x1 + w1;
		y2 = y1;
		w2 = _montage_w;
		h2 = h1;

		createChannelSettingButtons();
	}

	public void loadDefaultChannelSettings(){
		verbosePrint("loading default channel settings to GUI's channel controller...");
		for(int i = 0; i < nchan; i++){
			for(int j = 0; j < numSettingsPerChannel; j++){ //channel setting values
				channelSettingValues[i][j] = char(openBCI.defaultChannelSettings.toCharArray()[j]); //parse defaultChannelSettings string created in the OpenBCI_ADS1299 class
				if(j == numSettingsPerChannel - 1){
					println(char(openBCI.defaultChannelSettings.toCharArray()[j]));
				} else{
					print(char(openBCI.defaultChannelSettings.toCharArray()[j]) + ",");
				}
			}
			for(int k = 0; k < 2; k++){ //impedance setting values
				impedanceCheckValues[i][k] = '0';
			}
		}
		update(); //update 1 time to refresh button values based on new loaded settings
	}

	public void update(){
		for(int i = 0; i < nchan; i++){ //for every channel
			//update buttons based on channelSettingValues[i][j]
			for(int j = 0; j < numSettingsPerChannel; j++){		
				switch(j){  //what setting are we looking at
					case 0: //on/off ??
						if(channelSettingValues[i][j] == '0') channelSettingButtons[i][0].setColorNotPressed(color(255));// power down == false, set color to vibrant
						if(channelSettingValues[i][j] == '1') channelSettingButtons[i][0].setColorNotPressed(color(75)); // channelSettingButtons[i][0].setString("B"); // power down == true, set color to dark gray, indicating power down
					case 1: //GAIN ??
						if(channelSettingValues[i][j] == '0') channelSettingButtons[i][1].setString("x1");
						if(channelSettingValues[i][j] == '1') channelSettingButtons[i][1].setString("x2");
						if(channelSettingValues[i][j] == '2') channelSettingButtons[i][1].setString("x4");
						if(channelSettingValues[i][j] == '3') channelSettingButtons[i][1].setString("x6");
						if(channelSettingValues[i][j] == '4') channelSettingButtons[i][1].setString("x8");
						if(channelSettingValues[i][j] == '5') channelSettingButtons[i][1].setString("x12");
						if(channelSettingValues[i][j] == '6') channelSettingButtons[i][1].setString("x24");
					case 2: //input type ??
						if(channelSettingValues[i][j] == '0') channelSettingButtons[i][2].setString("Normal");
						if(channelSettingValues[i][j] == '1') channelSettingButtons[i][2].setString("Shorted");
						if(channelSettingValues[i][j] == '2') channelSettingButtons[i][2].setString("BIAS_MEAS");
						if(channelSettingValues[i][j] == '3') channelSettingButtons[i][2].setString("MVDD");
						if(channelSettingValues[i][j] == '4') channelSettingButtons[i][2].setString("Temp.");
						if(channelSettingValues[i][j] == '5') channelSettingButtons[i][2].setString("Test");
						if(channelSettingValues[i][j] == '6') channelSettingButtons[i][2].setString("BIAS_DRP");
						if(channelSettingValues[i][j] == '7') channelSettingButtons[i][2].setString("BIAS_DRN");
					case 3: //BIAS ??
						if(channelSettingValues[i][j] == '0') channelSettingButtons[i][3].setString("Don't Include");
						if(channelSettingValues[i][j] == '1') channelSettingButtons[i][3].setString("Include");
					case 4: // SRB2 ??
						if(channelSettingValues[i][j] == '0') channelSettingButtons[i][4].setString("Off");
						if(channelSettingValues[i][j] == '1') channelSettingButtons[i][4].setString("On");
					case 5: // SRB1 ??
						if(channelSettingValues[i][j] == '0') channelSettingButtons[i][5].setString("No");
						if(channelSettingValues[i][j] == '1') channelSettingButtons[i][5].setString("Yes");
				}
			}
			for(int k = 0; k < 2; k++){
				switch(k){
					case 0: // P Imp Buttons
						if(impedanceCheckValues[i][k] == '0'){
							impedanceCheckButtons[i][0].setColorNotPressed(color(75));
							impedanceCheckButtons[i][0].setString("0");
						}
						if(impedanceCheckValues[i][k] == '1'){
							impedanceCheckButtons[i][0].setColorNotPressed(color(255));
							impedanceCheckButtons[i][0].setString("1");
						}
					case 1: // N Imp Buttons
						if(impedanceCheckValues[i][k] == '0'){
							impedanceCheckButtons[i][1].setColorNotPressed(color(75));
							impedanceCheckButtons[i][1].setString("0");
						}
						if(impedanceCheckValues[i][k] == '1'){
							impedanceCheckButtons[i][1].setColorNotPressed(color(255));
							impedanceCheckButtons[i][1].setString("1");
						}
				}
			}
		}
		//then reset to 1

		//
		if(isWritingChannel){
			writeChannelSettings(channelToWrite);
		}

		if(rewriteWhenDoneWriting && isWritingChannel == false){
			initChannelWrite(channelToWriteWhenDoneWriting);
			rewriteWhenDoneWriting = false;
		}
	}

	public void draw(){

		pushStyle();
		noStroke();

		//draw phantom rectangle to cover up random crap from Graph2D... we are replacing this stuff with the Montage Controller
		fill(31,69,110);
		rect(x1 - 2, y1-(height*0.01f), w1, h1+(height*0.02f));

		//BG of montage controller (for debugging mainly)
		// fill(255,255,255,123);
		// rect(x1, y1 - 1, w1, h1);

		//channel buttons
		for(int i = 0; i < nchan; i++){
			channelSettingButtons[i][0].draw(); //draw on/off channel buttons
			//draw impedance buttons
			for(int j = 0; j < 2; j++){
				impedanceCheckButtons[i][j].draw();
			}
		}

		if(showFullController){
			//background
			noStroke();
			fill(0,0,0,100);
			rect(x1 + w1, y1, w2, h2);

			// [numChan] x 5 ... all channel setting buttons (other than on/off) 
			for(int i = 0; i < nchan; i++){
				for(int j = 1; j < 6; j++){
					// println("drawing button " + i + "," + j);
					// println("Button: " + channelSettingButtons[i][j]);
					channelSettingButtons[i][j].draw();
				}
			}

			//draw column headers for channel settings behind EEG graph
			fill(255);
			text("PGA Gain", x2 + (w2/10)*1, y1 - 12);
			text("Input Type", x2 + (w2/10)*3, y1 - 12);
			text("BIAS", x2 + (w2/10)*5, y1 - 12);
			text("SRB2", x2 + (w2/10)*7, y1 - 12);
			text("SRB1", x2 + (w2/10)*9, y1 - 12);

			//if mode is not from OpenBCI, draw a dark overlay to indicate that you cannot edit these settings
			if(eegDataSource != DATASOURCE_NORMAL && eegDataSource != DATASOURCE_NORMAL_W_AUX){
				fill(0,0,0,200);
				rect(x2,y2,w2,h2);
				fill(255);
				textSize(24);
				text("DATA SOURCE (LIVE) only", x2 + (w2/2), y2 + (h2/2));
			}
		}
		popStyle();

	}

	public void mousePressed(){
		//if fullChannelController and one of the buttons (other than ON/OFF) is clicked

		//if dataSource is coming from OpenBCI, allow user to interact with channel controller
		if(eegDataSource == DATASOURCE_NORMAL || eegDataSource == DATASOURCE_NORMAL_W_AUX){
			if(showFullController){
				for(int i = 0; i < nchan; i++){ //When [i][j] button is clicked
					for(int j = 1; j < numSettingsPerChannel; j++){		
						if(channelSettingButtons[i][j].isMouseHere()){
							//increment [i][j] channelSettingValue by, until it reaches max values per setting [j], 
							channelSettingButtons[i][j].wasPressed = true;
							channelSettingButtons[i][j].isActive = true;
						}
					}
				}	
			}
		}
		//on/off button and Imp buttons can always be clicked/released
		for(int i = 0; i < nchan; i++){
			if(channelSettingButtons[i][0].isMouseHere()){
				channelSettingButtons[i][0].wasPressed = true;
				channelSettingButtons[i][0].isActive = true;
			}

			//only allow editing of impedance if dataSource == from OpenBCI
			if(eegDataSource == DATASOURCE_NORMAL || eegDataSource == DATASOURCE_NORMAL_W_AUX){
				if(impedanceCheckButtons[i][0].isMouseHere()){
					impedanceCheckButtons[i][0].wasPressed = true;
					impedanceCheckButtons[i][0].isActive = true;
				}
				if(impedanceCheckButtons[i][1].isMouseHere()){
					impedanceCheckButtons[i][1].wasPressed = true;
					impedanceCheckButtons[i][1].isActive = true;
				}
			}
		}

	}

	public void mouseReleased(){
		//if fullChannelController and one of the buttons (other than ON/OFF) is released
		if(showFullController){
			for(int i = 0; i < nchan; i++){ //When [i][j] button is clicked
				for(int j = 1; j < numSettingsPerChannel; j++){		
					if(channelSettingButtons[i][j].isMouseHere() && channelSettingButtons[i][j].wasPressed == true){
						if(channelSettingValues[i][j] < maxValuesPerSetting[j]){
							channelSettingValues[i][j]++;	//increment [i][j] channelSettingValue by, until it reaches max values per setting [j], 
						} else {
							channelSettingValues[i][j] = '0';
						}	
						// if you're not currently writing a channel and not waiting to rewrite after you've finished mashing the button
						if(!isWritingChannel && rewriteWhenDoneWriting == false){
							initChannelWrite(i);//write new ADS1299 channel row values to OpenBCI
						}
						else{ //else wait until a the current write has finished and then write again ... this is to not overwrite the wrong values while writing a channel
							verbosePrint("CONGRATULATIONS, YOU'RE MASHING BUTTONS!");
							rewriteWhenDoneWriting = true;
							channelToWriteWhenDoneWriting = i;
						}

					}

					// if(!channelSettingButtons[i][j].isMouseHere()){
					channelSettingButtons[i][j].isActive = false;
					channelSettingButtons[i][j].wasPressed = false;
					// }
				}
			}
		}
		//ON/OFF button can always be clicked/released
		for(int i = 0; i < nchan; i++){
			//was on/off clicked?
			if(channelSettingButtons[i][0].isMouseHere() && channelSettingButtons[i][0].wasPressed == true){
				if(channelSettingValues[i][0] < maxValuesPerSetting[0]){
					channelSettingValues[i][0] = '1';	//increment [i][j] channelSettingValue by, until it reaches max values per setting [j], 
					// channelSettingButtons[i][0].setColorNotPressed(color(25,25,25));
					powerDownChannel(i);
				} else {
					channelSettingValues[i][0] = '0';
					// channelSettingButtons[i][0].setColorNotPressed(color(255));
					powerUpChannel(i);
				}
				// writeChannelSettings(i);//write new ADS1299 channel row values to OpenBCI
			}

			//was P imp check button clicked?
			if(impedanceCheckButtons[i][0].isMouseHere() && impedanceCheckButtons[i][0].wasPressed == true){
				if(impedanceCheckValues[i][0] < '1'){
					impedanceCheckValues[i][0] = '1';	//increment [i][j] channelSettingValue by, until it reaches max values per setting [j], 
					// channelSettingButtons[i][0].setColorNotPressed(color(25,25,25));
					writeImpedanceSettings(i);
					verbosePrint("a");
				} else {
					impedanceCheckValues[i][0] = '0';
					// channelSettingButtons[i][0].setColorNotPressed(color(255));
					writeImpedanceSettings(i);
					verbosePrint("b");
				}
				// writeChannelSettings(i);//write new ADS1299 channel row values to OpenBCI
			}

			//was N imp check button clicked?
			if(impedanceCheckButtons[i][1].isMouseHere() && impedanceCheckButtons[i][1].wasPressed == true){
				if(impedanceCheckValues[i][1] < '1'){
					impedanceCheckValues[i][1] = '1';	//increment [i][j] channelSettingValue by, until it reaches max values per setting [j], 
					// channelSettingButtons[i][0].setColorNotPressed(color(25,25,25));
					writeImpedanceSettings(i);
					verbosePrint("c");
				} else {
					impedanceCheckValues[i][1] = '0';
					// channelSettingButtons[i][0].setColorNotPressed(color(255));
					writeImpedanceSettings(i);
					verbosePrint("d");
				}
				// writeChannelSettings(i);//write new ADS1299 channel row values to OpenBCI
			}


			channelSettingButtons[i][0].isActive = false;
			channelSettingButtons[i][0].wasPressed = false;
			impedanceCheckButtons[i][0].isActive = false;
			impedanceCheckButtons[i][0].wasPressed = false;
			impedanceCheckButtons[i][1].isActive = false;
			impedanceCheckButtons[i][1].wasPressed = false;
		}

		update(); //update once to refresh button values
	}

	public void fillValuesBasedOnDefault(byte _defaultValues){
		//interpret incoming HEX value (from OpenBCI) and pass into all default channelSettingValues
		//decode byte from OpenBCI and break it apart into the channelSettingValues[][] array
	}

	public void powerDownChannel(int _numChannel){
		verbosePrint("Powering down channel " + _numChannel);
		//save SRB2 and BIAS settings in 2D history array (to turn back on when channel is reactivated)
		previousBIAS[_numChannel] = channelSettingValues[_numChannel][3];
		previousSRB2[_numChannel] = channelSettingValues[_numChannel][4];
		channelSettingValues[_numChannel][3] = '0'; //make sure to disconnect from BIAS
		channelSettingValues[_numChannel][4] = '0'; //make sure to disconnect from SRB2

		//writeChannelSettings
		initChannelWrite(_numChannel);//writeChannelSettings
	}

	public void powerUpChannel(int _numChannel){
		verbosePrint("Powering up channel " + _numChannel);
		//replace SRB2 and BIAS settings with values from 2D history array
		channelSettingValues[_numChannel][3] = previousBIAS[_numChannel];
		channelSettingValues[_numChannel][4] = previousSRB2[_numChannel];

		initChannelWrite(_numChannel);//writeChannelSettings
	}

	public void initChannelWrite(int _numChannel){
		//after clicking any button, write the new settings for that channel to OpenBCI
		verbosePrint("Writing channel settings " + _numChannel + " to OpenBCI!");
		timeOfLastWrite = millis();
		isWritingChannel = true;
		channelToWrite = _numChannel;
	}

	public void writeChannelSettings(int _numChannel){
		if(millis() - timeOfLastWrite >= 50){
			verbosePrint("---");
			switch (writeCounter){
				case 0: //start sequence by send 'x'
					verbosePrint("x" + " :: " + millis());
					serial_openBCI.write('x');
					break;
				case 1: //send channel number
					verbosePrint(str(_numChannel+1) + " :: " + millis());
					serial_openBCI.write((char) ('0'+(_numChannel+1)));
					break;
				case 2: case 3: case 4: case 5: case 6: case 7:
					verbosePrint(channelSettingValues[_numChannel][writeCounter-2] + " :: " + millis());
					serial_openBCI.write(channelSettingValues[_numChannel][writeCounter-2]);
					//value for ON/OF
					break;
				// case 3:
				// 	//value for PGA Gain
				// 	break;
				// case 4:
				// 	//value for input type
				// 	break;
				// case 5:
				// 	//value for BIAS
				// 	break;
				// case 6:
				// 	//value for SRB2
				// 	break;
				// case 7:
				// 	//value for SRB1
				// 	break;
				case 8:
					verbosePrint("X" + " :: " + millis());
					serial_openBCI.write('X'); // send 'X' to end message sequence
					break;
				case 9:
					verbosePrint("done writing channel.");
					isWritingChannel = false;
					writeCounter = -1;

					// //unclick buttons
					// for(int i = 0; i < nchan; i++){
					// 	for(int j = 1; j < numSettingsPerChannel; j++){		
					// 		channelSettingButtons[i][j].isActive = false;
					// 		channelSettingButtons[i][j].wasPressed = false;
					// 	}
					// }
					break;
			}
			timeOfLastWrite = millis();
			writeCounter++;
		}
	}

	public void writeImpedanceSettings(int _numChannel){
		//after clicking an impedance button, write the new impedance settings for that channel to OpenBCI
			//after clicking any button, write the new settings for that channel to OpenBCI
		verbosePrint("Writing impedance settings for channel " + _numChannel + " to OpenBCI!");
		//write setting 1, delay 5ms.. write setting 2, delay 5ms, etc.
		int tempCounter = 0;
		boolean writingImpedance = true;
		long timeOfLastWrite = millis();
		while(writingImpedance){
			if(millis() - timeOfLastWrite >= 5){
				if(tempCounter == 0){ //send 'x' to indicate start of channel packet
					verbosePrint("z" + " :: " + millis());
					// serial_openBCI.write('x');
				}
				if(tempCounter == 1){
					verbosePrint(str(_numChannel) + " :: " + millis());
					// serial_openBCI.write(tempCounter);
				}
				if(tempCounter > 1 && tempCounter < 2 + 2){
					verbosePrint(impedanceCheckValues[_numChannel][tempCounter-2] + " :: " + millis());
					// serial_openBCI.write(channelSettingValues[_numChannel][tempCounter]);
				}
				if(tempCounter == 2 + 2){ //2 impedance settings per channel + 2 for 'z' & numChan
					verbosePrint("Z" + " :: " + millis());
					// serial_openBCI.write('X');
				}
				timeOfLastWrite = millis();
				tempCounter++;
			}
			if(tempCounter == numSettingsPerChannel+3){
				verbosePrint("Done writing impedance settings for channel " + _numChannel);
				writingImpedance = false;
			}
		}
	}

	public void createChannelSettingButtons(){
		//the size and space of these buttons are dependendant on the size of the screen and full ChannelController
		
		verbosePrint("creating channel setting buttons...");
		int buttonW = 0;
		int buttonX = 0;
		int buttonH = 0;
		int buttonY = 0; //variables to be used for button creation below
		String buttonString = "";
		Button tempButton;

		//create all activate/deactivate buttons (left-most button in widget left of EEG graph). These buttons are always visible
		for(int i = 0; i < nchan; i++){
			buttonW = int((w1 - (spacer1 *4)) / 3);
			buttonX = int(x1 + (spacer1));
			// buttonH = int((h1 / (nchan + 1)) - (spacer1/2));
			buttonH = buttonW;
			buttonY = int(y1 + ((h1/(nchan+1))*(i+1)) - (buttonH/2));
			buttonString = str(i+1);
			tempButton = new Button (buttonX, buttonY, buttonW, buttonH, buttonString, 14);
			channelSettingButtons[i][0] = tempButton;
		}
		//create all (P)ositive impedance check butttons ... these are the buttons just to the right of activate/deactivate buttons ... These are also always visible
		//create all (N)egative impedance check butttons ... these are the buttons just to the right of activate/deactivate buttons ... These are also always visible
		for(int i = 0; i < nchan; i++){
			for(int j = 1; j < 3; j++){
				buttonW = int((w1 - (spacer1 *4)) / 3);
				buttonX = int(x1 + j*(buttonW) + (j+1)*(spacer1));
				// buttonH = int((h2 / (nchan + 1)) - (spacer2/2));
				buttonY = int(y1 + ((h1/(nchan+1))*(i+1)) - (buttonH/2));
				buttonString = "0";
				tempButton = new Button (buttonX, buttonY, buttonW, buttonH, buttonString, 14);
				impedanceCheckButtons[i][j-1] = tempButton;
			}
		}	

		//create all other channel setting buttons... these are only visible when the user toggles to "showFullController = true"
		for(int i = 0; i < nchan; i++){
			for(int j = 1; j < 6; j++){
				buttonW = int((w2 - (spacer2*6)) / 5);
				buttonX = int((x2 + (spacer2 * (j))) + ((j-1) * buttonW));
				// buttonH = int((h2 / (nchan + 1)) - (spacer2/2));
				buttonY = int(y2 + ((h2/(nchan+1))*(i+1)) - (buttonH/2));
				buttonString = "N/A";
				tempButton = new Button (buttonX, buttonY, buttonW, buttonH, buttonString, 14);
				channelSettingButtons[i][j] = tempButton;
			}
		}
	}
};


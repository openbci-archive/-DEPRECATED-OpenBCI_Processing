class ChannelController {

	public float x1, y1, w1, h1, x2, y2, w2, h2; //all 1 values refer to the left panel that is always visible ... al 2 values refer to the right panel that is only visible when showFullController = true
	public int montage_w, montage_h;
	public int rowHeight;
	public int buttonSpacing;
	boolean showFullController = false;

	int spacer1 = 3;
	int spacer2 = 5; //space between buttons

	// [Number of Channels] x 6 array of buttons for channel settings
	Button[][] channelSettingButtons = new Button [nchan][6];  // [channel#][Button#]
	int[][] channelSettingValues = new int [nchan][6]; // [channel#][Button#-value] ... this will incfluence text of button

	//buttons just to the left of 
	Button[][] impedanceCheckButtons = new Button [nchan][2];
	int [][] impedanceCheckValues = new int [nchan][2];

	// Array for storing SRB2 history settings of channels prior to shutting off .. so you can return to previous state when reactivating channel
	int[] previousSRB2 = new int [nchan];
	// Array for storing SRB2 history settings of channels prior to shutting off .. so you can return to previous state when reactivating channel
	int[] previousBIAS = new int [nchan];

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

	public void update(){

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

		}

		popStyle();

	}

	public void fillValuesBasedOnDefault(){
		//interpret incoming HEX value (from OpenBCI) and pass into all default channelSettingValues
	}

	public void writeChannelSettings(int _numChannel){
		//after clicking any button, write the new settings for that channel to OpenBCI
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


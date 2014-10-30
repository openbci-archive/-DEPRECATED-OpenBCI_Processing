class ChannelController {

	public float x, y, w, h;
	public int montage_w, montage_h;
	public int rowHeight;
	public int buttonSpacing;
	boolean showFullController = false;

	// [Number of Channels] x 6 array of buttons for channel settings
	Button[][] channelSettingButtons = new Button [nchan][6];  // [channel#][Button#]
	int[][] channelSettingValues = new int [nchan][6]; // [channel#][Button#-value] ... this will incfluence text of button

	// Array for storing SRB2 history settings of channels prior to shutting off .. so you can return to previous state when reactivating channel
	int[] previousSRB2 = new int [nchan];
	// Array for storing SRB2 history settings of channels prior to shutting off .. so you can return to previous state when reactivating channel
	int[] previousBIAS = new int [nchan];

	ChannelController(float _xPos, float _yPos, float _width, float _height, int _montage_w, int _montage_h){
		x = _xPos;
		y = _yPos;
		w = _width;
		h = _height;

		montage_w = _montage_w; //keep track of gMontage width
		montage_h = _montage_h;	//keep track of gMontage height

		// channelSettingButtons = new Button
	}

	public void update(){

	}

	public void draw(){

		pushStyle();
		noStroke();

		//draw phantom rectangle to cover up random crap from Graph2D... we are replacing this stuff with the Montage Controller
		fill(25);
		rect(x, y-(height*0.01f), w, h+(height*0.02f));

		//BG of montage controller (for debugging mainly)
		fill(255,255,255,123);
		rect(x, y, w, h);

		if(showFullController){
			fill(0,0,255,123);
			rect(x + w, y, montage_w, montage_h);
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
		//create all activate/deactivate buttons (left-most button in widget left of EEG graph). These buttons are always visible

		//create all (P)ositive impedance check butttons ... these are the buttons just to the right of activate/deactivate buttons ... These are also always visible

		//create all (N)egative impedance check butttons ... these are the buttons just to the right of activate/deactivate buttons ... These are also always visible

		//create all other channel setting buttons... these are only visible when the user toggles to "showFullController = true"

	}
};


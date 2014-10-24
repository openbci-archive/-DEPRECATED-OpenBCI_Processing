class MontageController {

	public float mc_xPos, mc_yPos, mc_width, mc_height;

	MontageController(float _xPos, float _yPos, float _width, float _height){
		mc_xPos = _xPos;
		mc_yPos = _yPos;
		mc_width = _width;
		mc_height = _height;

		println(mc_xPos);
		println(mc_yPos);
		println(mc_width);
		println(mc_height);
	}

	public void update(){

	}

	public void draw(){

		pushStyle();
		noStroke();

		//draw phantom rectangle to cover up random crap from Graph2D... we are replacing this stuff with the Montage Controller
		fill(25);
		rect(mc_xPos, mc_yPos-(height*0.01f), mc_width, mc_height+(height*0.02f));

		//BG of montage controller (for debugging mainly)
		fill(255,255,255,123);
		rect(mc_xPos, mc_yPos, mc_width, mc_height);

		popStyle();

	}
};


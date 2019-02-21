// DCV-pHluorin Analyzer - Set options

/*
This macro is used to create options for the DCV-pHluorin toolset

Modify
	2018.12.21 - Created
*/

var majVer = 2;
var minVer = 00;
var about = "Developed by Alessandro Moro<br>"
			+ "<i>Department of Functional Genomics</i> (FGA)<br>"
			+ "<i>Centre of neuroscience and cognitive research</i> (CNCR)<br>"
			+ "<i>Vrij Universiteit</i> (VU) Amsterdam.<br>"
			+ "<i>email: a.moro@vu.nl</i><br><br><br>";

			
// Initialize the variables
var normMethods;
var	BGframes;
var	nh4Start;
var	gapFrames;
var	sigma;
var	snr;
var	detSigma;
var	cleSigma;
var	ROI_size;
var	roiOver;
var	ROI_shape;
var	Autoadd;
var batchAnalysis;
//var	AlignStack;
//var	semiAuto;
//var	nIteration;
//var	detectEvery;
var	bRemove;
var	bInclude;
//var	subPixel;
var	InvertedLUT;
var	StartZoom;
var	saveas;
var	folder;
var	Autosave;
var	MovetoZoom;
var nStim
var stimL

whichOption = getArgument(); // possibles: firstTime, setDefault, loadOptions, setOptions
if (matches(whichOption, "firstTime")) {
	setDefaultOptions();
	loadOptions();
	setOptions();
	loadOptions();
} else if (matches(whichOption, "setDefault")) {
	setDefaultOptions();
	loadOptions();
} else if (matches(whichOption, "loadOptions")) {
	loadOptions();
} else if (matches(whichOption, "setOptions")) {
	loadOptions();
	setOptions();
	loadOptions();
}

// set the default display option
function setDefaultOptions(){
	//  this function uses the ij.Prefs file to store the options; if it is the first time that the program is called it will create a default value, there is no need for a reset as those are marely personal taste of the end user
	call("ij.Prefs.set", "DCVpHluorin.normMethods", "Rolling average");
	call("ij.Prefs.set", "DCVpHluorin.bgFrames", 30);
	call("ij.Prefs.set", "DCVpHluorin.nh4Start", 80);
	//call("ij.Prefs.set", "DCVpHluorin.gapFrames", 1);
	call("ij.Prefs.set", "DCVpHluorin.sigma", 0.6);
	call("ij.Prefs.set", "DCVpHluorin.snr", 3);
	call("ij.Prefs.set", "DCVpHluorin.detSigma", 2);
	call("ij.Prefs.set", "DCVpHluorin.cleSigma", 2);	
	call("ij.Prefs.set", "DCVpHluorin.ROI_size", 2);
	call("ij.Prefs.set", "DCVpHluorin.roiOver", 0);
	call("ij.Prefs.set", "DCVpHluorin.ROI_shape", "Rectangle");
	call("ij.Prefs.set", "DCVpHluorin.Autoadd", true);
	call("ij.Prefs.set", "DCVpHluorin.batchAnalysis", true);
	//call("ij.Prefs.set", "DCVpHluorin.AlignStack", false);
	//call("ij.Prefs.set", "DCVpHluorin.semiAuto", false);
	//call("ij.Prefs.set", "DCVpHluorin.nIteration", 1);
	//call("ij.Prefs.set", "DCVpHluorin.detectEvery", 90);
	call("ij.Prefs.set", "DCVpHluorin.bRemove", false);
	call("ij.Prefs.set", "DCVpHluorin.bInclude", false);
	//call("ij.Prefs.set", "DCVpHluorin.subPixel", false);
	call("ij.Prefs.set", "DCVpHluorin.InvertedLUT", false);
	call("ij.Prefs.set", "DCVpHluorin.StartZoom", false);
	call("ij.Prefs.set", "DCVpHluorin.saveas", "fullname");
	call("ij.Prefs.set", "DCVpHluorin.folder", getDirectory("Home"));
	call("ij.Prefs.set", "DCVpHluorin.Autosave", true);
	call("ij.Prefs.set", "DCVpHluorin.MovetoZoom", false);
	call("ij.Prefs.set", "DCVpHluorin.nStim", 1);
	call("ij.Prefs.set", "DCVpHluorin.stimL", 50);	
}
// get the display options from the ij.Prefs
function loadOptions(){
	// get the options from the ij.Prefs
	normMethods = call("ij.Prefs.get", "DCVpHluorin.normMethods", true);
	BGframes = call("ij.Prefs.get", "DCVpHluorin.bgFrames", true);
	nh4Start = call("ij.Prefs.get", "DCVpHluorin.nh4Start", true);
	//gapFrames = call("ij.Prefs.get", "DCVpHluorin.gapFrames", true);
	sigma = call("ij.Prefs.get", "DCVpHluorin.sigma", true);
	snr = call("ij.Prefs.get", "DCVpHluorin.snr", true);
	detSigma = call("ij.Prefs.get", "DCVpHluorin.detSigma", true);
	cleSigma = call("ij.Prefs.get", "DCVpHluorin.cleSigma", true);	
	ROI_size = call("ij.Prefs.get", "DCVpHluorin.ROI_size", true);
	roiOver = call("ij.Prefs.get", "DCVpHluorin.roiOver", true);
	ROI_shape = call("ij.Prefs.get", "DCVpHluorin.ROI_shape", true);
	Autoadd = call("ij.Prefs.get", "DCVpHluorin.Autoadd", true);
	batchAnalysis = call("ij.Prefs.get", "DCVpHluorin.batchAnalysis", true);
	//AlignStack = call("ij.Prefs.get", "DCVpHluorin.AlignStack", true);
	//semiAuto = call("ij.Prefs.get", "DCVpHluorin.semiAuto", true);
	//nIteration = call("ij.Prefs.get", "DCVpHluorin.nIteration", true);
	//detectEvery = call("ij.Prefs.get", "DCVpHluorin.detectEvery", true);
	bRemove = call("ij.Prefs.get", "DCVpHluorin.bRemove", true);
	bInclude = call("ij.Prefs.get", "DCVpHluorin.bInclude", true);
	//subPixel = call("ij.Prefs.get", "DCVpHluorin.subPixel", true);
	InvertedLUT = call("ij.Prefs.get", "DCVpHluorin.InvertedLUT", true);
	StartZoom = call("ij.Prefs.get", "DCVpHluorin.StartZoom", true);
	saveas = call("ij.Prefs.get", "DCVpHluorin.saveas", true);
	folder = call("ij.Prefs.get", "DCVpHluorin.folder", true);
	Autosave = call("ij.Prefs.get", "DCVpHluorin.Autosave", true);
	MovetoZoom = call("ij.Prefs.get", "DCVpHluorin.MovetoZoom", true);	
	nStim = call("ij.Prefs.get", "DCVpHluorin.nStim", true);
	stimL = call("ij.Prefs.get", "DCVpHluorin.stimL", true);
}
// new dialog for the options
function setOptions() {
	// at first detection parameters - more important
	Dialog.create("DCV-pHluorin analysis parameters");
	Dialog.addMessage("Movie parameters");
	Dialog.addRadioButtonGroup("Movie normalization method", newArray("Baseline subtraction", "Rolling average"), 1, 2, normMethods);
	Dialog.addNumber("Baseline frames", BGframes);
	Dialog.addNumber("Start of NH4 (frame)", nh4Start);
	//Dialog.addNumber("Gap between frames for normalization", gapFrames);
	Dialog.addMessage("Detection parameters");
	Dialog.addNumber("Number of stimulations", nStim);
	Dialog.addNumber("Stimulation time (in frames)", stimL);
	Dialog.addSlider("Smoothing radius (0.6 default)", 0.3, 1.5, sigma);
	Dialog.addNumber("SNR (between 30-80)", snr);
	Dialog.addNumber("Detection threshold (n*StDev image)", detSigma);
	Dialog.addMessage("ROI parameters");
	Dialog.addNumber("Cleaning threshold (n*StDev trace)", cleSigma);
	Dialog.addNumber("ROI size", ROI_size);
	Dialog.addNumber("Maximum pxs overlap between ROIs", roiOver);
	Dialog.addRadioButtonGroup("ROI shape", newArray("Rectangle", "Oval"), 1, 2, ROI_shape);
	Dialog.addCheckbox("Auto add ROI", Autoadd);
	Dialog.addMessage("Advance Options");
	Dialog.addCheckbox("Batch detection", false);
	Dialog.addCheckbox("Remove regions", bRemove);
	Dialog.addCheckbox("Detect at selection", bInclude);
	Dialog.addCheckbox("General Options", false);
	Dialog.addCheckbox("Reset parameters?", false);
	Dialog.show();
	normMethods = Dialog.getRadioButton();
	BGframes = Dialog.getNumber();
	nh4Start = Dialog.getNumber();
	//gapFrames = Dialog.getNumber();
	nStim = Dialog.getNumber();
	stimL = Dialog.getNumber();
	sigma = Dialog.getNumber();
	snr = Dialog.getNumber();
	detSigma = Dialog.getNumber();
	cleSigma = Dialog.getNumber();
	ROI_size = Dialog.getNumber();
	roiOver = Dialog.getNumber();
	ROI_shape = Dialog.getRadioButton();
	Autoadd = Dialog.getCheckbox();
	bRemove = Dialog.getCheckbox();
	bInclude = Dialog.getCheckbox();
	generalOption = Dialog.getCheckbox();
	bReset = Dialog.getCheckbox();
	/*
		if (advOption) {	
		// check the possible frame divisors
		usedFrames = nh4Start - (1 + gapFrames);
		nDiv = "Possible frames are: 1";
		for(ii = 2; ii <= usedFrames; ii++){
			if(usedFrames % ii == 0){
				nDiv = nDiv + ", " + ii;
			}
		}
		Dialog.create("DCV-pHluorin advance options");
		Dialog.addCheckbox("Align stack", AlignStack);
		Dialog.addCheckbox("Semi automatic detection", semiAuto);
		Dialog.addNumber("Number of detection iterations (1-3 suggested)", nIteration);
		Dialog.addNumber("Detect every N frames", detectEvery);
		Dialog.addMessage(nDiv);
		Dialog.addCheckbox("Sub pixel resolution?", subPixel);
		Dialog.show();
		AlignStack = Dialog.getCheckbox();
		semiAuto = Dialog.getCheckbox();
		nIteration = Dialog.getNumber();
		detectEvery = Dialog.getNumber();
		subPixel = Dialog.getCheckbox();
	}
	*/
	if (generalOption) {
		Dialog.create("DCV-pHluorin general options");
		Dialog.addCheckbox("Inverted LUT", InvertedLUT);
		Dialog.addCheckbox("Zoom in at start", StartZoom);
		Dialog.addChoice("Save ROIs as:", newArray("cs and cell ID", "fullname"), saveas);
		Dialog.addChoice("Save ROI in:" ,newArray("Current Folder", "Specific Folder", "New Folder"), folder);
		Dialog.addCheckbox("Autosave after measuring", Autosave);
		Dialog.addCheckbox("Full zoom to ROI", MovetoZoom);
		Dialog.show();
		InvertedLUT = Dialog.getCheckbox();
		StartZoom = Dialog.getCheckbox();
		saveas = Dialog.getChoice();
		folder = Dialog.getChoice();
		Autosave = Dialog.getCheckbox();
		MovetoZoom = Dialog.getCheckbox();
	}
	if(bReset){
		setDefaultParameters(true);
	} else {
		// set the new parameters to the ij.Prefs file
		call("ij.Prefs.set", "DCVpHluorin.normMethods", normMethods);
		call("ij.Prefs.set", "DCVpHluorin.bgFrames", BGframes);
		call("ij.Prefs.set", "DCVpHluorin.nh4Start", nh4Start);
		call("ij.Prefs.set", "DCVpHluorin.gapFrames", gapFrames);
		call("ij.Prefs.set", "DCVpHluorin.sigma", sigma);
		call("ij.Prefs.set", "DCVpHluorin.snr", snr);
		call("ij.Prefs.set", "DCVpHluorin.detSigma", detSigma);
		call("ij.Prefs.set", "DCVpHluorin.cleSigma", cleSigma);	
		call("ij.Prefs.set", "DCVpHluorin.ROI_size", ROI_size);
		call("ij.Prefs.set", "DCVpHluorin.roiOver", roiOver);
		call("ij.Prefs.set", "DCVpHluorin.ROI_shape", ROI_shape);
		call("ij.Prefs.set", "DCVpHluorin.Autoadd", Autoadd);
		//call("ij.Prefs.set", "DCVpHluorin.AlignStack", AlignStack);
		//call("ij.Prefs.set", "DCVpHluorin.semiAuto", semiAuto);
		//call("ij.Prefs.set", "DCVpHluorin.nIteration", nIteration);
		//call("ij.Prefs.set", "DCVpHluorin.detectEvery", detectEvery);
		call("ij.Prefs.set", "DCVpHluorin.bRemove", bRemove);
		call("ij.Prefs.set", "DCVpHluorin.bInclude", bInclude);
		//call("ij.Prefs.set", "DCVpHluorin.subPixel", subPixel);
		call("ij.Prefs.set", "DCVpHluorin.InvertedLUT", InvertedLUT);
		call("ij.Prefs.set", "DCVpHluorin.StartZoom", StartZoom);
		call("ij.Prefs.set", "DCVpHluorin.saveas", saveas);
		call("ij.Prefs.set", "DCVpHluorin.folder", folder);
		call("ij.Prefs.set", "DCVpHluorin.Autosave", Autosave);
		call("ij.Prefs.set", "DCVpHluorin.MovetoZoom", MovetoZoom);
		call("ij.Prefs.set", "DCVpHluorin.nStim", nStim);
		call("ij.Prefs.set", "DCVpHluorin.stimL", stimL);
	}
}
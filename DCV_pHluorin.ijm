// DCV-pHluorin Analyzer

/*
This toolset implement different functionality for the analysis of neuropeptide labelled with pHluorin. it was developed and tested using NPY-pHluorin.
The idea of this toolset is to provide an semi-automatic analysis of dense-core vesicles fusion events in primary neuronal culture.
The toolset consists of: ROI placement (automatic; exporting as maximum projection for SynD);
						 Manual ROI placement;
						 ROI interaction (save, measure, navigate);
						 ROI frame reader.
The toolset will provide different options to match the end user.

Start developing 2015.12.01

Modify
	20.03.02 - Released with bug fixed for placing the first ROI
*/

var majVer = 2;
var minVer = 00;
var about = "Developed by Alessandro Moro<br>"
			+ "<i>Department of Functional Genomics</i> (FGA)<br>"
			+ "<i>Centre of neuroscience and cognitive research</i> (CNCR)<br>"
			+ "<i>Vrij Universiteit</i> (VU) Amsterdam.<br>"
			+ "<i>email: a.moro@vu.nl al.moro@outlook.com</i><br><br><br>";

var DCV_dir = getDirectory("imagej") + "macros\\toolsets\\DCVpHluorin";
// even before starting check if it's the first time it's run
function firstCheck() {
	bFirst = call("ij.Prefs.get", "DCVpHluorin.bFirst", true);
	if(bFirst == 1){
		runMacro(DCV_dir+"//DCVpHluorin_setOptions.ijm", "firstTime"); 
		call("ij.Prefs.set", "DCVpHluorin.bFirst", false);
	}
}

/////////////////////////////////////
/////////CREATE THE TOOLSET/////////
////////////////////////////////////

// leave one empty slot
macro "Unused Tool -1-" {} 

// Start Analysis -> fusion detection; export to SynD; Options
var sCmds1 = newMenu("Start Analysis Menu Tool", newArray("Fusion detection", "Export to SynD", "Get NH4 pool"));
macro "Start Analysis Menu Tool - C555T1d13 T9d13 R01fbR2397 Cd00T1d13 T9d13 D00D01D02D03D0dD0eD0fD10D11D12D13D14D1cD1dD1eD1fD20D21D24D25D2bD2cD2eD2fD30D31D35D36D3aD3bD3eD3fD40D41D46D47D49D4aD4eD4fD50D51D57D58D59D5eD5fD60D61D68D6eD6fD70D71D7eD7fD80D81D82D83D8cD8dD8eD8fD90D91D92D93D9cD9dD9eD9f"{
	firstCheck();
	cmd1 = getArgument();
	if (cmd1 == "Fusion detection"){
		runMacro(DCV_dir+"//DCVpHluorin_newDetection.ijm"); 
	} else if (cmd1 == "Export to SynD"){
		runMacro(DCV_dir+"//DCVpHluorin_exportToSynD.ijm");
	} else if (cmd1 == "Get NH4 pool"){
		runMacro(DCV_dir+"//DCVpHluorin_getNH4.ijm"); 
	}
}

// Place ROIs -> automatically with defined size, shape and add them to ROI manager, double click for specific options
macro "Place ROIs Tool -C5d5T1d13 T9d13 R0977 Cdd0T1d13 T9d13 D1dD2aD2bD2cD37D38D39D3aD3bD3eD43D44D45D46D47D48D49D4aD4dD4eD53D54D55D56D57D58D59D5cD5dD63D64D65D66D67D68D6bD6cD6dD73D74D75D76D77D7aD7bD7cD7dD84D85D86D87D89D8aD8bD8cD92D93D95D96D97D98D99D9aD9bD9cDa1Da2Da3Da4Da6Da7Da8Da9DaaDabDacDb2Db3Db4Db5Db7Db8Db9DbaDbbDbcDc3Dc4Dc5Dc6Dc8Dc9DcaDcbDccDd4Dd5Dd6De5De6"{
	firstCheck();
	ROI_size = call("ij.Prefs.get", "DCVpHluorin.ROI_size", true);
	ROI_shape = call("ij.Prefs.get", "DCVpHluorin.ROI_shape", true);
	Autoadd = call("ij.Prefs.get", "DCVpHluorin.Autoadd", true);
	// get the selected ROI
	prevROI = roiManager("index");
	if (prevROI == -1) {
		prevName = " ";
	} else {
		prevName = Roi.getName;
	}
	// Add or remove Roi manually
	getCursorLoc(x, y, z, flags);
	x1 = x - floor(ROI_size / 2);
	y1 = y - floor(ROI_size / 2);
	
	// Use the flag "Alt" to find the Roi in the Manager and delete it
	if (isKeyDown("alt")){
		nROI = roiManager("count");
		r = 0;
		bROI = 0;
		while((r < nROI) && (bROI == 0)){
			roiManager("Select", r);
			bROI = selectionContains(x, y);
			r++;
		}
		if (bROI == 1)
			roiManager("Delete");
	}else{
		// add roi acconding to shape and size
		if (ROI_shape == "Rectangle"){
			makeRectangle(x1, y1, ROI_size, ROI_size);
		} else {
			makeOval(x1, y1, ROI_size, ROI_size);
		}
	if (Autoadd == 1){
		roiManager("Add");
		nRoi = roiManager("count");
		if (nRoi > 1) {
			roiManager("select", nRoi-2);
			lastID = Roi.getName;
			lastID = split(lastID, "-");
			newID = parseInt(lastID[0]) + 1;
			newID = IJ.pad(newID, 4);
		} else {
			newID = "0000";
		}
		roiManager("select", nRoi-1);
		roiManager("rename", newID+"-"+getSliceNumber());
		// reselected the old ROI
		if (isOpen(prevName)) {
			roiManager("select", prevROI);
		}
	}
}

}

macro "Place ROIs Tool Options ..."{
	firstCheck();
	ROI_size = call("ij.Prefs.get", "DCVpHluorin.ROI_size", true);
	ROI_shape = call("ij.Prefs.get", "DCVpHluorin.ROI_shape", true);
	// small dialog only to change the ROI shape and size
	if(matches(ROI_shape,"Rectagle")){
		roiShape = 1;
	}else{
		roiShape = 2;
	}
	shapes = newArray("Rectangle", "Oval");
	Dialog.create("ROI shape and size ");
	Dialog.addRadioButtonGroup("Shape", shapes, 1, 2, roiShape);
	Dialog.addSlider("Size", 1, 10, ROI_size);
	Dialog.show();
	NewShape = Dialog.getRadioButton();
	NewSize  = Dialog.getNumber();
	ROI_shape = NewShape;
	ROI_size  = NewSize;
	// save the new shape and size
	call("ij.Prefs.set", "DCVpHluorin.ROI_size", ROI_size);
	call("ij.Prefs.set", "DCVpHluorin.ROI_shape", ROI_shape);
}


// Save ROIs -> with the proper name, cs and cell ID or full name, in the proper folder
var sCmds2 = newMenu("ROIs Interacion Menu Tool", newArray("Save ROI", "Measure ROIs", "Check ROIs", "-", "Fix ROI Manager", "Clean ROI Manager"));
macro "ROIs Interacion Menu Tool - C5d5T1d13 T9d13 R9077  C555T1d13 T9d13 D2aD3aD3bD4aD4bD4cD50D51D52D53D54D55D56D57D58D59D5aD5bD5cD5dD60D61D62D63D64D65D66D67D68D69D6aD6bD6cD6dD6eD70D71D72D73D74D75D76D77D78D79D7aD7bD7cD7dD7eD7fD80D81D82D83D84D85D86D87D88D89D8aD8bD8cD8dD8eD90D91D92D93D94D95D96D97D98D99D9aD9bD9cD9dDaaDabDacDbaDbbDca"{
	cmd2 = getArgument();
	firstCheck();
	if (cmd2 == "Save ROI")
		runMacro(DCV_dir+"//DCVpHluorin_SaveROIs.ijm", "saveROI"); 
	else if (cmd2 == "Measure ROIs")
		runMacro(DCV_dir+"//DCVpHluorin_SaveROIs.ijm", "measureROI");
	else if (cmd2 == "Check ROIs") {
		run("DCVpHluorin CheckROIs");
	}
	else if (cmd2 == "Fix ROI Manager")
		runMacro(DCV_dir+"//DCVpHluorin_SaveROIs.ijm", "fixRoiManager");
	else
		runMacro(DCV_dir+"//DCVpHluorin_RoiManagerCleaner.ijm");
}

// ROIs frames -> read all the RoiSet.zip file in the specified folder reporting the name and frame number
var sCmds3 = newMenu("ROIs Frames Reader Menu Tool", newArray("From ROI Manager", "From Folder"));
macro "ROIs Frames Reader Menu Tool - C5d5T1d13 T9d13 R9077R9977 C555T1d13 T9d13 L00f0L03f3L06f6L09f9L0cfcL0fbf"{
	cmd3 = getArgument();
	firstCheck();
	if (cmd3 == "From ROI Manager") {
		runMacro(DCV_dir+"//DCVpHluorin_SaveROIFrame.ijm", "manager");
	} else {
		runMacro(DCV_dir+"//DCVpHluorin_SaveROIFrame.ijm", "folder");
	}
}

// Options
macro "Options... Action Tool - C77bD3eD4eD5eD6bD6cD6dD7aD89D98Da7Db6Dc6Dd6De4De5D2aD5dDa2Dd5D59D68D69D77D78D86D87D96D1aD1bD1cD29D2bD39D49D4bD4cD4dD58D67D76D85D92D93D94Da1Db1Db2Db4Dc1Dc4Dd4De3D5aD6aD79D88D95D97Da5Da6D19D91D4aD5bDa4Db5D3aD5cDa3Dc5"{
	firstCheck();
	runMacro(DCV_dir+"//DCVpHluorin_setOptions.ijm", "setOptions");
}

// Documentation!!!
macro "Help... Action Tool - C000D84Cb9fD25De7CaaaD14D2dDa0DafDecDfaCedfD49D4aD4bD4cD58D68D9bDb9DbaDbbDbcC889D2cDebCddfD52CcccD0bD22CeeeD00D03D0cD0fD10D1fD20D2fD30D40Dc0Dd0DdfDe0DefDf0Df1Df2Df3DfcDfeDffC666D07D70CdcfD34D35Dc4CbacD86D91CfefD6bD6dD7cD8cD8dD8eD9cD9dDadC97aDd3De5CedfD99CeeeD01D02D04D0dD0eD11D12D1eD21D3fDcfDd1De1De2DeeDf4DfdCfefD7dC545D94Da5CdbeDa4Da7CbabD05D50DaeCfefD7eC98aD32Da1CecfD39D3aD3bD46D48D57D67Da8Db6Db8Dc9DcaDcbDccCdcdD81C878D1bD60D65CdcfD29D36D38D47D77Db7Dc8Dd9DdaCcbcD7aDbfDc1De3C98bD16D24D75DeaCedfD56D66D73D76D83D93Da3C212D7bD88D96D97CcaeD26D3cDdbCaaaD3eD5fCfdfD59C889D15D1aD78Dc2CdcfD45Db4Db5Dc6CdddD13D31D4fDdeDedDfbC777D09D7fD85D90Df7CeceDbdCbadD18D55Db2De9Ca9aD5eDcdDceDdcC656D08D64D80D87D8bCdbfD28D2aD37Dc7Dd8CbbbD1cD42Dd2Df5CfdfD5aD5bD5cD5dD69D6aD6cD9aDa9DabDacC999D0aD41DddDf6CdddD1dD2eD9eDb0C888D06D4eD6fD9fDf9CcbdD54D71D98Dc3Ca9dD17D19Dd4De6C000D74D79D95CcafDd5Dd6De8CedfD62D72D92C889D51Db1DbeCedfD53D63Da2CdcdD6eC777D8fDf8CdcfD43D44Db3Dc5CbadD2bD33C99aD23De4C545D89Da6CcbfD27Dd7CbabD61CedfD82DaaC98aD3dCdceD4dD8a"{
	message = "<html>"
	 + "<h2>Version " + majVer + "." + minVer + "</h2><br>"
	 + about + "<br>"
	 + "The documentation could be found "
	 + "<a href=\"https://github.com/alemoro/DCVpHluorin_toolseet\">here.</a><br>"
	 + "<a href=\"http://www.johanneshjorth.se/SynD/SynD.html\">SynD</a><br>"
	 + "<a href=\"https://dreamdealer.net/redmine/projects\">Fusion Analysis 2</a><br>"
	 + "<a href=\"http://bigwww.epfl.ch/thevenaz/stackreg/\">StackReg</a><br>"
	 + "<a href=\"http://imagej.net/MorphoLibJ\">MorphoLibJ</a><br>"
	 + "<a href=\"https://imagej.net/Spots_colocalization_(ComDet)\">ComDet</a>.<br>"
	Dialog.create("Help");
	Dialog.addMessage("Version " + majVer + "." + minVer + ", \nclick \"Help\" for more");
	Dialog.addHelp(message);
	Dialog.show;
	//showMessage("Not very usefull", message);
}
// DCV-pHluorin Analyzer - measure and save ROIs

/*
This macro is used to create options for the DCV-pHluorin toolset

Modify
	2018.12.21 - Created

Version
	Base - DCV_pHluorin v2.0
	Function - DCVpHluorin_setOption v1.0

Developed by Alessandro Moro
Department of Functional Genomics (FGA)
Centre of neuroscience and cognitive research (CNCR)
Vrij Universiteit (VU) Amsterdam.
email: a.moro@vu.nl; al.moro@outlook.com
*/
			
// Initialize the variables
DCV_dir = getDirectory("imagej") + "macros//toolsets//DCVpHluorin";
// get the options from the ij.Prefs
saveas = call("ij.Prefs.get", "DCVpHluorin.saveas", true);
folder = call("ij.Prefs.get", "DCVpHluorin.folder", true);
Autosave = call("ij.Prefs.get", "DCVpHluorin.Autosave", true);
InvertedLUT = call("ij.Prefs.get", "DCVpHluorin.InvertedLUT", true);
nh4Start = call("ij.Prefs.get", "DCVpHluorin.nh4Start", true);
bgFrames = call("ij.Prefs.get", "DCVpHluorin.bgFrames", true);

whichOption = getArgument(); // possibles: saveROI, measureROI
if (matches(whichOption, "saveROI")) {
	SaveROIs();
} else if (matches(whichOption, "measureROI")) {
	MeasureEvents();
} else if (matches(whichOption, "saveNH4")) {
	saveNH4();
} else {
	fixRoiManager();
}

// basically the Roi Manager multimeasure option, plus copy already the table and save automatically (in case)
function MeasureEvents(){
	if (Autosave == 1)
		SaveROIs();
	if (InvertedLUT == 1)
		run("Invert", "stack");
	setBatchMode("hide");
	resetMinAndMax();
	roiManager("Deselect");
	roiManager("Multi Measure");
	setBatchMode("exit and display");
	String.copyResults();
}

// save the Roi Manager as a zip file with the proper name in the proper folder
function SaveROIs(){
	if (folder == "Current Folder"){
  		wd = getDirectory("Image");
  	} else if (folder == "Specific Folder"){
  		wd = getDirectory("Choose a Directory");
  	} else if (folder == "New Folder"){
  		wd = getDirectory("Choose a Directory");
  	}
	
	fullname = getTitle; // get the file name of the image
	if ((endsWith(fullname, ".stk")) || (endsWith(fullname, ".tif"))){
		fullname = substring(fullname, 0, lengthOf(fullname)-4);
		} else {
			if (endsWith(fullname, ".tiff")){
				fullname = substring(fullname, 0, lengthOf(fullname)-5);
			}
		}
	
	if (saveas == "cs and cell ID"){
		name = substring(fullname, lengthOf(fullname)-7, lengthOf(fullname)); //retrive the last part of the name (cs and cell number)
	} else {
		name = fullname;
	}
	roiManager("Save", wd + "RoiSet_" + name + ".zip");
}

// Save the NH4Cl response
function saveNH4() {
	setBatchMode(true);
	imgID = getImageID();
	if (folder == "Current Folder"){
  		wd = getDirectory("Image");
  	} else if (folder == "Specific Folder"){
  		wd = getDirectory("Choose a Directory");
  	} else if (folder == "New Folder"){
  		wd = getDirectory("Choose a Directory");
  	}
	
	fullname = getTitle; // get the file name of the image
	if ((endsWith(fullname, ".stk")) || (endsWith(fullname, ".tif"))){
		fullname = substring(fullname, 0, lengthOf(fullname)-4);
		} else {
			if (endsWith(fullname, ".tiff")){
				fullname = substring(fullname, 0, lengthOf(fullname)-5);
			}
		}
	
	if (saveas == "cs and cell ID"){
		name = substring(fullname, lengthOf(fullname)-7, lengthOf(fullname)); //retrive the last part of the name (cs and cell number)
	} else {
		name = fullname;
	}
	roiManager("Save", wd + "NH4Set_" + name + ".zip");
	// get the intensity
	newStart = parseInt(nh4Start) - parseInt(bgFrames);
	run("Z Project...", "start="+newStart+" projection=[Max Intensity]");
	maxID = getImageID();
	run("Set Measurements...", "mean redirect=None decimal=3");
	roiManager("deselect");
	roiManager("multi-measure measure_all");
	saveAs("Results", wd + "NH4Res_" + name + ".csv");
	selectWindow("Results");
	run("Close");
	selectImage(maxID);
	close();
}

// fix miss saved ROI Manager
function fixRoiManager(){
	nRoi = roiManager("Count");
	for(r=0;r<nRoi;r++){
		showStatus("Fixing ROI Manager");
		showProgress(r/nRoi);
		roiManager("Select", r);
		Roi.getBounds(x, y, width, height)
		if(width<0){
			if(height<0){
				newX = x+width;
				newY = y+height;
				newW = -1*width;
				newH = -1*height;
			} else {
				newX = x+width;
				newY = y;
				newW = -1*width;
				newH = height;
			}
		} else {
			if(height<0){
				newX = x;
				newY = y+height;
				newW = width;
				newH = -1*height;
			} else {
				newX = x;
				newY = y;
				newW = width;
				newH = height;
			}
		}
		if (ROI_shape == "Rectangle"){
			makeRectangle(newX, newY, newW, newH);
		} else {
			makeOval(newX, newY, newW, newH);
		}
		roiManager("Update");
	}
}
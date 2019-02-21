// DCV-pHluorin Analyzer - measure and save ROIs

/*
This macro is used to create options for the DCV-pHluorin toolset

Modify
	2018.12.21 - Created
*/

majVer = 2;
minVer = 00;
about = "Developed by Alessandro Moro<br>"
			+ "<i>Department of Functional Genomics</i> (FGA)<br>"
			+ "<i>Centre of neuroscience and cognitive research</i> (CNCR)<br>"
			+ "<i>Vrij Universiteit</i> (VU) Amsterdam.<br>"
			+ "<i>email: a.moro@vu.nl</i><br><br><br>";

			
// Initialize the variables
DCV_dir = getDirectory("imagej") + "macros//toolsets//DCVpHluorin";
// get the options from the ij.Prefs
saveas = call("ij.Prefs.get", "DCVpHluorin.saveas", true);
folder = call("ij.Prefs.get", "DCVpHluorin.folder", true);
Autosave = call("ij.Prefs.get", "DCVpHluorin.Autosave", true);
InvertedLUT = call("ij.Prefs.get", "DCVpHluorin.InvertedLUT", true);

whichOption = getArgument(); // possibles: saveROI, measureROI
if (matches(whichOption, "saveROI")) {
	SaveROIs();
} else if (matches(whichOption, "measureROI")) {
	MeasureEvents();
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
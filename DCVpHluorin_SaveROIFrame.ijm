// DCV-pHluorin Analyzer - save events frame start

/*
This macro is used to create a csv of the putative frames for the start of the events for the DCV-pHluorin toolset

Modify
	2020.02.26 - Created

Version
	Base - DCV_pHluorin v2.0
	Function - DCVpHluorin_SaveROIFrame v1.0

Developed by Alessandro Moro
Department of Functional Genomics (FGA)
Centre of neuroscience and cognitive research (CNCR)
Vrij Universiteit (VU) Amsterdam.
email: a.moro@vu.nl; al.moro@outlook.com
*/
			
// Initialize the variables
DCV_dir = getDirectory("imagej") + "macros//toolsets//DCVpHluorin";
whichOption = getArgument(); // possibles: manager, folder
if (matches(whichOption, "manager")) {
	setBatchMode(true);
	if (nImages != 1) {
		imgTitle = getString("Name for the RoiSet", "");
	} else {
		imgTitle = replace(getTitle(), ".tif", "");
	}
	newImage("Dummy", "8-bit", 512, 512, 1);
	readRoiManager(imgTitle);
} else {
	workDir = getDirectory("Choose a Directory");
	workFile = getFileList(workDir);
	nFile = workFile.length;
	setBatchMode(true);
	newImage("Dummy", "8-bit", 512, 512, 1);
	for (f=0; f<nFile; f++) {
		fileName = workFile[f];
		showProgress(f/nFile);
		if (endsWith(fileName, ".zip")) {
			roiManager("open", workDir+fileName);
			imgTitle = replace(fileName, "RoiSet_", "");
			imgTitle = replace(imgTitle, ".zip", "");
			readRoiManager(imgTitle);
		}
		roiManager("reset");
	}
}



function readRoiManager(imgTitle) {
	nRoi = roiManager("count");
	for (r=0; r<nRoi; r++) {
		roiManager("select", r);
		roiName = Roi.getName;
		roiName = split(roiName, "-");
		roiID = roiName[0];
		events = Array.slice(roiName,1,roiName.length);
		frames = newArray(events.length+2);
		frames[0] = imgTitle;
		frames[1] = roiID;
		for (e=0; e<events.length; e++) {
			frames[e+2] = events[e];
		}
		Array.print(frames);
	}
}

/*
workDir = getDirectory("Choose a Directory");
workFile = getFileList(workDir);
nFile = workFile.length;
newImage("Dummy", "8-bit", 512, 512, 1);
for (f=0; f<nFile; f++) {
	fileName = workFile[f];
	if (endsWith(fileName, ".zip")) {
		roiManager("open", workDir+fileName);
		imgName = replace(fileName, "RoiSet_", "");
		imgName = replace(imgName, ".zip", "");
		nRoi = roiManager("count");
		for (r=0; r<nRoi; r++) {
			roiManager("select", r);
			roiName = Roi.getName;
			roiName = split(roiName, "-");
			roiID = roiName[0];
			events = Array.slice(roiName,1,roiName.length-1);
			for (e=0; e<events.length; e++) {
				print(imgName+","+roiID+","+events[e]);
			}
		}
		roiManager("reset");
	}
}
*/
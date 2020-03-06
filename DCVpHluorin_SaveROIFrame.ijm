// DCV-pHluorin Analyzer - save events frame start

/*
This macro is used to create a csv of the putative frames for the start of the events for the DCV-pHluorin toolset

Modify
	2020.02.26 - Created
	2020.03.06 - add function to calculate the number of events per site (in a 3 px area)

Version
	Base - DCV_pHluorin v2.0
	Function - DCVpHluorin_SaveROIFrame v1.1

Developed by Alessandro Moro
Department of Functional Genomics (FGA)
Centre of neuroscience and cognitive research (CNCR)
Vrij Universiteit (VU) Amsterdam.
email: a.moro@vu.nl; al.moro@outlook.com
*/
			
// Initialize the variables
DCV_dir = getDirectory("imagej") + "macros//toolsets//DCVpHluorin";
whichOption = getArgument(); // possibles: manager, folder, colocalization
if (matches(whichOption, "manager")) {
	setBatchMode(true);
	if (nImages != 1) {
		imgTitle = getString("Name for the RoiSet", "");
	} else {
		imgTitle = replace(getTitle(), ".tif", "");
	}
	newImage("Dummy", "8-bit", 512, 512, 1);
	readRoiManager(imgTitle);
} else if (matches(whichOption, "folder")) {
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
} else {
	workDir = getDirectory("Choose a Directory");
	workFile = getFileList(workDir);
	nFile = workFile.length;
	setBatchMode(true);
	newImage("Dummy", "8-bit", 512, 512, 1);
	if (getBoolean("Append?")) {
		row=nResults;
	} else {
		row = 0;
	}
	// loop throught the files
	for (f=0; f<nFile; f++) {
		fileName = workFile[f];
		showProgress(f/nFile);
		if (endsWith(fileName, ".zip")) {
			roiManager("open", workDir+fileName);
			imgTitle = replace(fileName, "RoiSet_", "");
			imgTitle = replace(imgTitle, ".zip", "");
			// get the number of events and the center of the ROI
			nRoi = roiManager("count");
			nEvents = 0;
			eventsRoi = newArray(nRoi);
			xLocationRoi = newArray(nRoi);
			yLocationRoi = newArray(nRoi);
			for (r=0; r<nRoi; r++) {
					roiManager("select", r);
					roiName = Roi.getName;
					roiName = split(roiName, "-");
					eventsRoi[r] = roiName.length - 1;
					nEvents = nEvents + eventsRoi[r];
					Roi.getBounds(x, y, width, height);
					xLocationRoi[r] = x + (width / 2);
					yLocationRoi[r] = y + (height / 2);
			}
			// calculate the distance between ROIs
			colocalizationRoi = newArray(nRoi);
			for (r1=0; r1<nRoi; r1++) {
				tempCol = 0;
				for (r2=r1+1; r2<nRoi; r2++) {
					tempDist = sqrt(pow(xLocationRoi[r1] - xLocationRoi[r2], 2) + pow(yLocationRoi[r1] - yLocationRoi[r2], 2));
					tempCol = tempCol + eventsRoi[r1]-1; // if there are more than one event in the ROI they do colocalize
					if (tempDist < 3.5) { // 3.5 is based on a px size = 0.4 um might need adjustment
						tempCol = tempCol + eventsRoi[r2]; // if two ROIs are closer then the desired size all the events in the second ROI are colocalizing with the previous
					}
				}
				colocalizationRoi[r1] = tempCol;
			}
			// get the actual numbers
			nColocalization = 0;
			multipleSite = 0;
			allSite = 0;
			for (r=0; r<nRoi; r++) {
				allSite = allSite + colocalizationRoi[r];
				if (colocalizationRoi[r] > 1) {
					multipleSite++; // increase the size of ROI with multiple events by one (site)
					nColocalization = nColocalization + colocalizationRoi[r];
				}
			}
			// output the data in a table
			setResult("CellID", row, imgTitle);
			setResult("Number ROI", row, nRoi);
			setResult("Number Events", row, nEvents);
			setResult("Number Colocalization", row, nColocalization/allSite*100);
			setResult("Sites multiple events", row, multipleSite/nRoi*100);
			row++;
			roiManager("reset");
		}
	}
	updateResults();
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

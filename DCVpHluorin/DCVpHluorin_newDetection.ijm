// DCV-pHluorin Analyzer - new semiAutomatic detection

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
var DCV_dir = getDirectory("imagej") + "macros//toolsets//DCVpHluorin";
runMacro(DCV_dir+"//DCVpHluorin_setOptions.ijm", "setOptions");
// get the options from the ij.Prefs
var normMethods = call("ij.Prefs.get", "DCVpHluorin.normMethods", true);
var BGframes = call("ij.Prefs.get", "DCVpHluorin.bgFrames", true);
var nh4Start = call("ij.Prefs.get", "DCVpHluorin.nh4Start", true);
//gapFrames = call("ij.Prefs.get", "DCVpHluorin.gapFrames", true);
var sigma = call("ij.Prefs.get", "DCVpHluorin.sigma", true);
var snr = call("ij.Prefs.get", "DCVpHluorin.snr", true);
var detSigma = call("ij.Prefs.get", "DCVpHluorin.detSigma", true);
var cleSigma = call("ij.Prefs.get", "DCVpHluorin.cleSigma", true);	
var ROI_size = call("ij.Prefs.get", "DCVpHluorin.ROI_size", true);
var ROI_shape = call("ij.Prefs.get", "DCVpHluorin.ROI_shape", true);
var batchAnalysis = call("ij.Prefs.get", "DCVpHluorin.batchAnalysis", true);
var bRemove = call("ij.Prefs.get", "DCVpHluorin.bRemove", true);
var bInclude = call("ij.Prefs.get", "DCVpHluorin.bInclude", true);
var nStim = call("ij.Prefs.get", "DCVpHluorin.nStim", true);
var stimL = call("ij.Prefs.get", "DCVpHluorin.stimL", true);

// Semi automatic detection
var stimS = newArray(2); //stimS[0] = 50; stimS[1] = 130;
for (s = 0; s < nStim; s++) {
	stimS[s] = getNumber("Stimulation "+ (1+s) +" start", 50);
}

setBatchMode("hide");
tic = getTime();
if (batchAnalysis) {
	workDir = getDirectory("Select Movie folder");
	workFile = getFileList(workDir);
	for (o = 0; o < workFile.length; o++){
		if (endsWith(workFile[o], ".tif")){
			open(workDir + workFile[o]);
			orImg = getImageID();
			detectEvents();
			runMacro(DCV_dir+"//DCVpHluorin_SaveROIs.ijm", "saveROI"); 
			roiManager("Reset");
		}
	}
} else {
	orImg = getImageID();
	detectEvents();
	setBatchMode("Exit and display");
}

function detectEvents() {
	// create a duplicate image with gaussin blur
	run("Duplicate...", "duplicate");
	gaussID = getImageID();
	if (matches(normMethods, "Baseline subtraction")) {
		run("Z Project...", "stop="+BGframes+" projection=[Average Intensity]");
		avgID = getImageID();
		imageCalculator("Subtract stack", gaussID, avgID);
		selectImage(avgID); close();
	}
	run("Gaussian Blur 3D...", "x="+sigma+" y="+sigma+" z="+sigma);
	for (s = 0; s < nStim; s++) {
		stimE = stimS[s]+stimL;
		selectImage(gaussID);
		run("Z Project...", "start="+stimS[s]+" stop="+stimE+" projection=[Standard Deviation]");
		//setBatchMode("Exit and display");
		//waitForUser("Evaluate SNR");
		//return;
		stdImg = getImageID();
		run("Duplicate...", " ");
		dupID = getImageID();
		runMacro(DCV_dir+"\\DCVpHluorin_autoLUT.ijm"); 
		run("8-bit");
		run("Find Maxima...", "noise="+snr+" output=List");
		oldRoi = roiManager("Count");
		for(r=0; r < nResults; r++){
			xLoc = round(getResult("X", r) - 1);
			yLoc = round(getResult("Y", r) - 1);
			makeRectangle(xLoc, yLoc, 3, 3);
			roiManager("Add");
		}
		selectWindow("Results"); run("Close");
		selectImage(dupID);close();
		nRoi = roiManager("Count");
		mean = newArray(4);
		for(r=oldRoi+1;r<nRoi;r++){
			showProgress(-(r+1),nRoi);
			showStatus("Adjust ROI Placement " +r+"/"+nRoi);
			// get a baseline level
			roiManager("Select", r);
			Roi.getBounds(x0, y0, w0, h0);
			b = 0;
			for(x=0;x<2;x++){
				for(y=0;y<2;y++){
					makeRectangle(x0+x,y0+y,2,2);
					getStatistics(a, mean[b], m, M, std, h);
					b++;
				}
			}
			// check the sub Roi with the highest fusion peak
			max = Array.rankPositions(mean);
			if(max[3] == 0){
				makeRectangle(x0, y0, 2, 2);	
			} else if(max[3] == 1){
				makeRectangle(x0, y0+1, 2, 2);
			} else if(max[3] == 2){
				makeRectangle(x0+1, y0, 2, 2);
			} else {
				makeRectangle(x0+1, y0+1, 2, 2);
			}
			roiManager("Update");
		}
		selectImage(stdImg); close();
	}
	selectImage(gaussID); close();
	nRoi = roiManager("count");
	l = 0;
	//setBatchMode(true);
	while(l<nRoi){
		showProgress(l+1,nRoi);
		showStatus("Detecting Frame " + l+1 +"/" + nRoi);
		roiManager("Select",l);
		run("Plot Z-axis Profile");
		Plot.getValues(xpoints, vesicle);
		run("Close");
		vesicle = Array.slice(vesicle,0,nh4Start);
		baseline = Array.slice(vesicle,0,BGframes);
		Array.getStatistics(baseline, baseMin, baseMax, baseMean, baseStdDev);
		FF0 = newArray(vesicle.length);
		for(i=0; i<vesicle.length; i++){
			FF0[i] = vesicle[i] / baseMean;
		}
		vesicle = FF0;
		rollStd = newArray(vesicle.length);
		Array.fill(rollStd,0);
		// calculate a walking standard deviation
		startFrame = (-1)+BGframes;
		for(i=startFrame; i<rollStd.length; i++){
			tempArray = Array.slice(vesicle,i - startFrame,i);
			Array.getStatistics(tempArray, tempMin, tempMax, tempMean, tempStd);
			rollStd[i] = tempMean + detSigma * tempStd;
		}
		// calculate the difference between the STD and the trace to find the point the goes above
		rollDiff = newArray(vesicle.length);
		Array.fill(rollDiff,0);
		for(i=startFrame; i<rollStd.length; i++){
			rollDiff[i] = vesicle[i] - rollStd[i];
		}
		// sort the array (from lower to higher) and invert it
		rollIdx = Array.rankPositions(rollDiff);
		rollIdx = Array.invert(rollIdx);
		rIdx = rollIdx[0];
		if(rollDiff[rIdx] > 0){
			setSlice(rIdx);
			roiManager("update");
			l++;
		} else {
			roiManager("delete");
			nRoi = roiManager("count");
			
		}
	}
	run("Remove Overlay");
}
//waitForUser(((getTime()-tic)/1000) + " seconds");
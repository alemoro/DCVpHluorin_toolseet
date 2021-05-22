// DCV-pHluorin Analyzer - new semiAutomatic detection

/*
This macro is used to create options for the DCV-pHluorin toolset

Modify
	2018.12.21 - Created
	2020.02.10 - Update detection to use outliers
	2020.03.09 - Start adding a function to determine if an event is slow or fast rising + bug fixed to delete the ROI if no event is detected
	2020.12.19 - Add a top hat filter instead of the unsharp mask

Version
	Base - DCV_pHluorin v2.0
	Function - DCVpHluorin_newDetection v1.0a

Developed by Alessandro Moro
Department of Functional Genomics (FGA)
Centre of neuroscience and cognitive research (CNCR)
Vrij Universiteit (VU) Amsterdam.
email: a.moro@vu.nl; al.moro@outlook.com
*/



			
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
var stimS = newArray(100);
// Here you can add a shortcut for the start of the stimulation

if (nStim == 5) {
	stimS[0] = 15; stimS[1] = 55; stimS[2] = 95; stimS[3] = 135; stimS[4] = 205;
} else if (nStim == 2) {
	stimS[0] = 55; stimS[1] = 139;
} else if (nStim == 3) {
	stimS[0] = 50; stimS[1] = 65; stimS[2] = 80; // 61 - 109
} else if (nStim == 16) {
	for (s=0; s<8; s++) {
		stimS[s] = 60 + 3*s;
	}
	for (s=8; s<16; s++) {
		stimS[s] = 143 + 3*(s-8);
	}
} else {
	for (s = 0; s < nStim; s++) {
		stimS[s] = getNumber("Stimulation "+ (1+s) +" start", 50);
	}
}

/*
// Or use this line to enter the start of the stimulation manually each time
for (s = 0; s < nStim; s++) {
	stimS[s] = getNumber("Stimulation "+ (1+s) +" start", 50);
}
*/

if (bRemove) {
	orImg = getImageID();
	setBatchMode(true);
	run("Duplicate...", " ");
	dupID = getImageID();
	run("Gaussian Blur...", "sigma=1");
	setAutoThreshold("Triangle dark");
	run("Create Selection");
	selectImage(orImg);
	run("Restore Selection");
	selectImage(dupID);
	close();
	waitForUser("Please draw the area to discard (hold SHIFT for compaund areas)");
	newImage("Untitled", "8-bit black", getWidth(), getHeight(), 1);
	rmvID = getImageID();
	run("Restore Selection");
	setForegroundColor(255, 255, 255);
	run("Fill", "slice");
	run("Select None");
	selectImage(orImg);
	run("Select None");
}
setBatchMode("hide");
if (batchAnalysis) {
	workDir = getDirectory("Select Movie folder");
	workFile = getFileList(workDir);
	for (o = 0; o < workFile.length; o++){
		if (endsWith(workFile[o], ".tif")){
			open(workDir + workFile[o]);
			setBatchMode("hide");
			detectEvents();
			runMacro(DCV_dir+"//DCVpHluorin_SaveROIs.ijm", "saveROI"); 
			roiManager("Reset");
			close();
		}
	}
} else {
	detectEvents();
	setBatchMode("Exit and display");
}

function detectEvents() {
	orImg = getImageID();
	// get a duplicate image and work with this
	run("Select None");
	run("Duplicate...", "duplicate");
	dupID = getImageID();
	if (matches(normMethods, "Baseline subtraction")) {
		run("Z Project...", "stop="+BGframes+" projection=[Average Intensity]");
		avgID = getImageID();
		imageCalculator("Subtract stack", dupID, avgID);
		selectImage(avgID); close();
	}
	// enhance edges
	for (s = 0; s < nStim; s++) {
		stimE = stimS[s]+stimL;
		run("Z Project...", "start="+stimS[s]+" stop="+stimE+" projection=[Standard Deviation]");
		stdImg = getImageID();
		if (matches(normMethods, "B&W Opening")) {
			selectImage(dupID);
			run("Z Project...", "start="+stimS[s]+" stop="+stimE+" projection=[Max Intensity]");
			maxID = getImageID();
			selectImage(dupID);
			run("Z Project...", "start="+stimS[s]+" stop="+stimE+" projection=[Average Intensity]");
			avgID = getImageID();
			imageCalculator("Multiply", stdImg, maxID);
			imageCalculator("Divide", stdImg, avgID);
			selectImage(maxID); close();
			selectImage(avgID); close();
			//run("Maximum...", "radius="+sigma);
			//run("Minimum...", "radius="+sigma);
			//run("Gaussian Blur...", "sigma="+sigma);
			//run("Sharpen");
		}
		run("8-bit");
		IJversion = IJ.getFullVersion;
		versionNumber = substring(IJversion,2,lengthOf(IJversion)-2);
		versionNumber = parseInt(versionNumber, 36);
		if (versionNumber >= parseInt("53f", 36)) {
			run("Top Hat...", "radius="+ROI_size);
		} else {
			run("Unsharp Mask...", "radius="+ROI_size+" mask=0.7");
		}
		if (bInclude) {
			setBatchMode("Exit and display");
			waitForUser("Evaluate SNR");
			snr = getNumber("New SNR", snr);
			selectImage(stdImg); close();
			bInclude = call("ij.Prefs.set", "DCVpHluorin.bInclude", false);
			snr = call("ij.Prefs.set", "DCVpHluorin.snr", snr);
			selectImage(dupID); close();
			return;
		}
		if (snr == 0) {
			setAutoThreshold("Triangle dark no-reset");
			run("Create Selection");
			getStatistics(Sarea, Smean, Smin, Smax, Sstd, Shistogram);
			run("Make Inverse");
			getStatistics(Narea, Nmean, Nmin, Nmax, Nstd, Nhistogram);
			resetThreshold();
			run("Select None");
			snr = ((Smean-Nmean) / Nstd);
		}
		run("Find Maxima...", "noise="+snr+" output=List exclude");
		oldRoi = roiManager("Count");
		for(r=0; r < nResults; r++){
			xLoc = getResult("X", r) - 1;
			yLoc = getResult("Y", r) - 1;
			makeRectangle(xLoc, yLoc, 3, 3);
			roiManager("Add");
		}
		selectWindow("Results"); run("Close");
		selectImage(stdImg); close();
	}
	selectImage(dupID);close();
	nRoi = roiManager("count");
	l = 0;
	//setBatchMode(true);
	if (bRemove) {
		rSize = parseInt(ROI_size);
		selectImage(rmvID);
		nRoi = roiManager("count");
		r=0;
		while (r<nRoi) {
			roiManager("Select", r);
			getStatistics(rA, rMean, rMin, rMax, rStd, rHist);
			if (rMean < (255*((rSize*rSize)/2)/(rSize*rSize))) {
				r++;
			} else {
				roiManager("select", r);
				roiManager("delete");
			}
			nRoi = roiManager("count");
		}
		close();
	}
	// detect the fusion event in the trace
	/*
	while(l<nRoi){
		showProgress(l+1,nRoi);
		showStatus("Detecting Frame " + l+1 +"/" + nRoi);
		roiManager("Select",l);
		run("Plot Z-axis Profile");
		Plot.getValues(xpoints, vesicle);
		run("Close");
		vesicle = Array.slice(vesicle,0,nh4Start);
		// before anything else do a weigthed walking average of width 3
		avgVes = newArray(vesicle.length);
		for (i = 0; i < vesicle.length; i++) {
			if (i == 0) {
				avgVes[i] = ((vesicle[i] * sigma) + vesicle[i] + (vesicle[i+1] * sigma)) / (1 + (parseFloat(sigma)*2));
			} else if (i == vesicle.length-1) {
				avgVes[i] = ((vesicle[i-1] * sigma) + vesicle[i] + (vesicle[i] * sigma)) / (1 + (parseFloat(sigma)*2));
			} else {
				avgVes[i] = ((vesicle[i-1] * sigma) + vesicle[i] + (vesicle[i+1] * sigma)) / (1 + (parseFloat(sigma)*2));
			}
		}
		baseline = Array.slice(avgVes,0,BGframes);
		Array.getStatistics(baseline, baseMin, baseMax, baseMean, baseStdDev);
		rollStd = newArray(avgVes.length);
		Array.fill(rollStd,0);
		// calculate a walking standard deviation
		startFrame = BGframes;
		for(i=startFrame; i<rollStd.length; i++){
			tempArray = Array.slice(avgVes,i - startFrame,i);
			Array.getStatistics(tempArray, tempMin, tempMax, tempMean, tempStd);
			rollStd[i] = tempMean + detSigma * tempStd;
		}
		// calculate the difference between the STD and the trace to find the point the goes above
		rollDiff = newArray(avgVes.length);
		Array.fill(rollDiff,0);
		vesDiff = newArray(avgVes.length);
		Array.fill(vesDiff, 0);
		Array.getStatistics(avgVes, tempMin, tempMax, vesMean, vesStd);
		for(i=startFrame; i<rollStd.length; i++){
			rollDiff[i] = avgVes[i] - rollStd[i];
		}
		// Check for the presence of one outlier in the first derivative
		dVes = newArray(avgVes.length-1);
		for (i=startFrame; i<dVes.length; i++) {
			dVes[i] = avgVes[i+1] - vesicle[i];
		}
		// calculate the percentiles (25, 50, 75th)
		dSort = Array.slice(dVes,15,dVes.length-1);
		Array.sort(dSort);
		vesQ = calculatePercentile(dSort);
		IQR = vesQ[2] - vesQ[0];
		hThr = vesQ[2] + cleSigma * IQR;
		// get values that are above the the threshold
		nEvents = 0;
		evStart = newArray(dVes.length);
		for (i=0; i<dVes.length; i++) {
			if (dVes[i] >= hThr) {
				evStart[nEvents] = i;
				nEvents++;
			}
		}
		// Save the Roi only if there is an event
		bKeep = false;
		name = IJ.pad(l, 4);
		if (nEvents>0) {
			for (i = 0; i < nEvents; i++) {
				// Check if the actually signal is higher than its baseline
				if ((evStart[i]) < (parseInt(nh4Start) - 5)) {
					bStd = (rollDiff[evStart[i]+3] > 0) || (rollDiff[evStart[i]+4] > 0) || (rollDiff[evStart[i]+2] > 0);
					// add a new filter for slow events
					//bFast = isFast(vesicle, evStart[i]+3);
					bFast = true;
					if (bStd && bFast) {
						bKeep = true;
						if (i == 0) {
							name = name+"-"+evStart[i]+2;
						} else {
							if ((evStart[i]-evStart[i-1])>1) {
								name = name+"-"+evStart[i]+2;
							}
						}
					}
				}
			}
		}
		if (!(indexOf(name, "-") > 0)) {
			bKeep = false;
		}
		if (bKeep) {
			roiManager("rename", name);
			l++;
		} else {
			roiManager("delete");
			nRoi--;
		}
	}	
	runMacro(DCV_dir+"//DCVpHluorin_RoiManagerCleaner.ijm");
	*/
	run("Remove Overlay");
	if (ROI_size == 2) {
		nRoi = roiManager("Count");
		mean = newArray(4);
		for(r=oldRoi;r<nRoi;r++){
			showProgress(-(r+1),nRoi);
			showStatus("Adjust ROI Placement " +r+"/"+nRoi);
			// get a baseline level
			roiManager("Select", r);
			Roi.getBounds(x0, y0, w0, h0);
			run("Duplicate...", "duplicate range=1-"+nh4Start);
			roiID = getImageID;
			b = 0;
			for(x=0;x<2;x++){
				for(y=0;y<2;y++){
					makeRectangle(0+x,0+y,2,2);
					getStatistics(a, mean[b], m, M, std, h);
					b++;
				}
			}
			selectImage(roiID); close();
			selectImage(orImg);
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
	}
}

function calculatePercentile(testArray) {
	percentiles = newArray(3);
	arraySize = testArray.length;
	// get the indices for the 25th, 50th and 75th percentiles
	q25 = arraySize * 0.25;
	q50 = arraySize * 0.50;
	q75 = arraySize * 0.75;
	// calculate the values
	if ((q25 % 1) > 0) {
		percentiles[0] = testArray[floor(q25)];
	} else {
		percentiles[0] = (testArray[q25-1] + testArray[q25]) / 2;
	}
	if ((q50 % 1) > 0) {
		percentiles[1] = testArray[floor(q50)];
	} else {
		percentiles[1] = (testArray[q50-1] + testArray[q50]) / 2;
	}
	if ((q75 % 1) > 0) {
		percentiles[2] = testArray[floor(q75)];
	} else {
		percentiles[2] = (testArray[q75-1] + testArray[q75]) / 2;
	}
	return percentiles;
}

function isFast(trace, eventStart) {
	tempTrace = Array.slice(trace,eventStart-5,eventStart+5);
	// calculate the groth factor
	workTrace = newArray(10);
	for (i = 1; i < tempTrace.length; i++) {
		workTrace[i-1] = tempTrace[i] / tempTrace[i-1];
	}
	growthTrace = Array.slice(workTrace,0,9);
	Array.sort(growthTrace);
	growthQs = calculatePercentile(growthTrace);
	growthIQR = growthQs[2] - growthQs[0];
	growthThr = growthQs[2] + 1.5 * growthIQR;
	if ((workTrace[3] >= growthThr) || (workTrace[4] >= growthThr)) {
		bFast = true;
	} else {
		bFast = false;
	}
	return bFast;
}

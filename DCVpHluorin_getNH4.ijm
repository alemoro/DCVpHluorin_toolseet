// DCV-pHluorin Analyzer - Identify ROIs for NH4Cl response

/*
This macro is used to create options for the DCV-pHluorin toolset

Modify
	2018.12.21 - Created
	2020.02.05 - Improve detection centering the start of NH4

Version
	Base - DCV_pHluorin v2.0
	Function - DCVpHluorin_getNH4 v1.0

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

if (batchAnalysis) {
	workDir = getDirectory("Select Movie folder");
	workFile = getFileList(workDir);
	nImgs=0;
	for (o = 0; o < workFile.length; o++){
		if (endsWith(workFile[o], ".tif")){
			nImgs++;
		}
	}
	dT = 5; // estimate 5 minutes per image
	titleDlg = "[Progress]";
	run("Text Window...", "name="+ titleDlg +" width=50 height=4 monospaced");
	setBatchMode(true);
	waitForUser("Starting");
	for (o = 0; o < workFile.length; o++){
		if (endsWith(workFile[o], ".tif")){
			t0 = getTime();
			print(titleDlg, "\\Update:"+o+"/"+nImgs+" ("+(o*nImgs)/nImgs+"%)\nAnalysis will take ~ "+(dT*(nImgs-o))+" min\n"+getBar(o, nImgs));
			open(workDir + workFile[o]);
			orImg = getImageID();
			getNH4();
			runMacro(DCV_dir+"//DCVpHluorin_SaveROIs.ijm", "saveNH4"); 
			roiManager("Reset");
			t1 = getTime();
			dT = (t1- t0) / 6000;
		}
	}
	print(titleDlg, "\\Close");
} else {
	setBatchMode("hide");
	imgID = getImageID();
	getNH4();
	if (roiManager("count") > 0) {
		selectImage(imgID);
		runMacro(DCV_dir+"//DCVpHluorin_SaveROIs.ijm", "saveNH4");
	}
	setBatchMode("Exit and display");
}

function getBar(p1, p2) {
      n = 20;
      bar1 = "--------------------";
      bar2 = "********************";
      index = round(n*(p1/p2));
      if (index<1) index = 1;
      if (index>n-1) index = n-1;
      return substring(bar2, 0, index) + substring(bar1, index+1, n);
}

function getNH4() {
	orImg = getImageID();
	if (bRemove) {
		setBatchMode("Exit and display");
		orImg = getImageID();
		waitForUser("Please draw the area to discard (hold SHIFT for compaund areas)");
		setBatchMode("hide");
		newImage("Untitled", "8-bit black", getWidth(), getHeight(), 1);
		rmvID = getImageID();
		run("Restore Selection");
		setForegroundColor(255, 255, 255);
		run("Fill", "slice");
		run("Select None");
		selectImage(orImg);
		run("Select None");
	}
	run("Select None");
	// get the Std around the NH4 response
	nh4Start = parseInt(nh4Start);
	sFrame = nh4Start - (nSlices - nh4Start); // to have the start of the NH4 at the center
	run("Z Project...", "start="+sFrame+" projection=[Standard Deviation]");
	stdImg = getImageID;
	// get also an average of the baseline, and the maximum
	selectImage(orImg);
	run("Z Project...", "start="+sFrame+" stop="+nh4Start+" projection=[Average Intensity]");
	avgID = getImageID();
	selectImage(orImg);
	run("Z Project...", "start="+sFrame+" projection=[Max Intensity]");
	maxID = getImageID();
	imageCalculator("Subtract", maxID, avgID);
	selectImage(avgID);
	close();
	// return to the stdImg and prepare it for spot detection
	selectImage(stdImg);
	run("8-bit");
	IJversion = IJ.getFullVersion;
	versionNumber = substring(IJversion,2,lengthOf(IJversion)-2);
	versionNumber = parseInt(versionNumber, 36);
	if (versionNumber >= parseInt("53f", 36)) {
		run("Top Hat...", "radius=2");
	} else {
		run("Unsharp Mask...", "radius=1 mask=0.90");
	}
	if (bInclude) {
		setBatchMode("Exit and display");
		waitForUser("Evaluate SNR");
		snr = getNumber("New SNR", snr);
		bInclude = call("ij.Prefs.set", "DCVpHluorin.bInclude", false);
		snr = call("ij.Prefs.set", "DCVpHluorin.snr", snr);
		selectImage(maxID); close();
		selectImage(stdImg); close();
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
		snr = (Smean-Nmean) / Nstd;
	}
	run("Find Maxima...", "noise="+snr+" output=List exclude");
	intGap = newArray(nResults);
	sortGap = newArray(nResults);
	selectImage(maxID);
	for(r=0; r < nResults; r++){
		xLoc = getResult("X", r) - 1;
		yLoc = getResult("Y", r) - 1;
		makeRectangle(xLoc, yLoc, 3, 3);
		roiManager("Add");
	}
	selectWindow("Results");
	run("Close");
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
	// get the intensity gap
	nRoi = roiManager("count");
	selectImage(maxID);
	for (r = 0; r < nRoi; r++) {
		roiManager("select", r);
		getStatistics(area, intGap[r], min, max, std, histogram);
		sortGap[r] = intGap[r];
	}
	// get the percentiles as a measure of the optimal range of intensities
	Array.sort(sortGap);
	gapQ = calculatePercentile(sortGap);
	selectImage(stdImg);
	close();
	selectImage(maxID);
	close();
	nRoi = roiManager("count");
	l = 0;
	r = 0;
	while(l<nRoi){
		selectImage(orImg);
  		roiManager("Select",l);
		run("Plot Z-axis Profile");
		Plot.getValues(xpoints, vesicle);
		run("Close");
		vesicle = Array.slice(vesicle,sFrame,vesicle.length);
		// Check for the presence of one outlier in the first derivative
		dVes = newArray(vesicle.length-1);
		for (i=0; i<dVes.length; i++) {
			dVes[i] = vesicle[i+1] - vesicle[i];
		}
		// calculate the median
		vesMed = dVes;
		Array.sort(vesMed);
		// calculate the percentiles (25, 50, 75th)
		vesQ = calculatePercentile(vesMed);
		IQR = vesQ[2] - vesQ[0];
		hThr = vesQ[2] + cleSigma * IQR;
		
		// since the array is sorted, check if the last number is higher than the threshold
		if (dVes[dVes.length-1] > hThr) {
			l++;
		} else {
			// first try to see if the intensity jump is high
			if ((intGap[r] >= gapQ[0]) && (intGap[r] <= gapQ[2])) {
				l++;
			} else {
				roiManager("delete");
			}
		}
		/*
		// first check intensity, otherwhise outlier change
		if ((intGap[r] >= gapQ[0]) && (intGap[r] <= gapQ[2])) {
			l++;
		} else {
			if (dVes[dVes.length-1] > hThr) {
				l++;
			} else {
				roiManager("delete");
			}
		}
		*/
		nRoi = roiManager("count");
		r++;
	}	
	run("Remove Overlay");
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
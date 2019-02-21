// DCV-pHluorin Analyzer - Fusion detection

/*
This macro is used to detect potential regions in the movie with fusion after normlize the movie as a dF or thresholded image stack

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

// get the variables from the IJ preferences
var DCV_dir = getDirectory("imagej") + "macros\\toolsets\\DCVpHluorin";
runMacro(DCV_dir+"\\DCVpHluorin_setOptions.ijm", "loadOptions"); 
var normMethods = call("ij.Prefs.get", "DCVpHluorin.normMethods", true);
var BGframes = call("ij.Prefs.get", "DCVpHluorin.bgFrames", true);
var nh4Start = call("ij.Prefs.get", "DCVpHluorin.nh4Start", true);
var gapFrames = call("ij.Prefs.get", "DCVpHluorin.gapFrames", true);
var sigma = call("ij.Prefs.get", "DCVpHluorin.sigma", true);
var detSigma = call("ij.Prefs.get", "DCVpHluorin.detSigma", true);

// actual function
imgTitle = getTitle();
if (matches(normMethods, "Baseline subtraction")) {
	// new code based on threshold
	run("Z Project...", "stop=" + BGframes + " projection=[Average Intensity]");
	rename("AVG");
	selectWindow(imgTitle);
	run("Z Project...", "stop=" + BGframes + " projection=[Standard Deviation]");
	rename("STD32");
	// NEW::normalize the standard deviation image back to 16 bits
	getStatistics(STD32area, STD32mean, STD32min, STD32max, STD32std, STD32histogram);
	run("Duplicate...", " ");
	rename("STD");
	run("16-bit");
	getStatistics(STD16area, STD16mean, STD16min, STD16max, STD16std, STD16histogram);
	STDconversion = STD16mean / STD32mean;
	selectWindow("STD32"); close();
	selectWindow("STD");
	run("Divide...", "value="+STDconversion);
	resetMinAndMax();
	run("Multiply...", "value="+detSigma);
	imageCalculator("Add create", "AVG","STD");
	rename("THR");
	selectWindow("AVG"); close();
	selectWindow("STD"); close();
	imageCalculator("Subtract create stack", imgTitle,"THR");
	rename("Thresholded");
	run("Z Project...", "projection=[Max Intensity]");
	rename("max_thr");
	getStatistics(thrA, thrMean, thrMin, thrMax, thrStd, thrHist);
	selectWindow("THR"); close();
	selectWindow("max_thr"); close();
	selectWindow("Thresholded");
	setMinAndMax(0, thrMax);
	run("8-bit");
	run("Gaussian Blur...", "sigma=1 stack");
	run("Duplicate...", "duplicate range=" + (1+gapFrames) + "-" + (nh4Start-1));
	rename("Diff_Img");
	selectWindow("Thresholded");close();
} else {
	// go to the stack subtraction function
	run("Duplicate...", "duplicate range=1-" + nh4Start -1);
	rename("tempDiff");	
	setPasteMode("Subtract");
	run("Gaussian Blur 3D...", "x=" + sigma +" y=" + sigma +" z=" + sigma);
	run("Set Slice...", "slice="+nSlices);
	run("Select All");
	// gap frames are useful to detect better event that need more than one frame to arrive at the maximum, events that are only one frame will be detect anyhow
	for(i=nSlices; i>gapFrames; i--) {
		setSlice(i-gapFrames);
	   	run("Copy");
	   	setSlice(i);
		run("Paste");
	}
	run("Select None");
	selectWindow("tempDiff");
	run("Duplicate...", "duplicate range=" + (1+gapFrames) + "-" + nSlices);
	rename("Diff_Img");
	setSlice(1);
	run("Min...", "value=1 stack"); // to avoid 0 in pixel values
	// Try to increase the SNR ratio
	getStatistics(tM_area, tM_mean, tM_min, tM_max, tM_std, tM_hist);
	run("Subtract...", "value=" + floor(tM_mean) + " stack");
	selectWindow("tempDiff"); close();
}

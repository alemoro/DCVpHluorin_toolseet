// DCV-pHluorin Analyzer - save events frame start

/*
This macro is used to create a csv of the putative frames for the start of the events for the DCV-pHluorin toolset

Modify
	20.02.26 - Created
	20.03.06 - add function to calculate the number of events per site (in a 3 px area)
	20.06.06 - add new function to calculate the fusion parameters | bug fix in event colocalization

Version
	Base - DCV_pHluorin v2.0
	Function - DCVpHluorin_SaveROIFrame v1.2

Developed by Alessandro Moro
Department of Functional Genomics (FGA)
Centre of neuroscience and cognitive research (CNCR)
Vrij Universiteit (VU) Amsterdam.
email: a.moro@vu.nl; al.moro@outlook.com
*/
			
// Initialize the variables
DCV_dir = getDirectory("imagej") + "macros//toolsets//DCVpHluorin";
var baseFrames = call("ij.Prefs.get", "DCVpHluorin.bgFrames", true);
var nh4Start = call("ij.Prefs.get", "DCVpHluorin.nh4Start", true);
whichOption = getArgument(); // possibles: manager, folder, colocalization
if (matches(whichOption, "manager")) {
	if (nImages != 1) {
		exit("Error: Image not found.\nThe image to analyze should be open.");
	} else {
		//runMacro(DCV_dir+"//DCVpHluorin_SaveROIs.ijm", "saveROI");
		roiManager("reset");
		calculateFusionParameters(false);
	}
	/*
	setBatchMode(true);
	if (nImages != 1) {
		imgTitle = getString("Name for the RoiSet", "");
	} else {
		imgTitle = replace(getTitle(), ".tif", "");
	}
	newImage("Dummy", "8-bit", 512, 512, 1);
	readRoiManager(imgTitle);
	*/
} else if (matches(whichOption, "folder")) {
	calculateFusionParameters(true);
	/*
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
	*/
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
				tempCol = tempCol + eventsRoi[r1]-1; // if there are more than one event in the ROI they do colocalize
				for (r2=r1+1; r2<nRoi; r2++) {
					tempDist = sqrt(pow(xLocationRoi[r1] - xLocationRoi[r2], 2) + pow(yLocationRoi[r1] - yLocationRoi[r2], 2));
					if (tempDist < 4.3) { // 3.6 is based on a px size = 0.4 um might need adjustment, 4.3 indicates that two 3x3 px events are consider colocalizing if they only touch each other
						tempCol = tempCol + eventsRoi[r2]; // if two ROIs are closer then the desired size all the events in the second ROI are colocalizing with the previous
					}
				}
				colocalizationRoi[r1] = tempCol;
			}
			// get the actual numbers
			nColocalization = 0;
			multipleSite = 0;
			allSite = (nEvents * (nEvents-1)) / 2;
			for (r=0; r<nRoi; r++) {
				if (colocalizationRoi[r] >= eventsRoi[r]) {
					multipleSite++; // increase the size of ROI with multiple events by one (site)
					nColocalization = nColocalization + colocalizationRoi[r];
				}
			}
			// output the data in a table
			setResult("CellID", row, imgTitle);
			setResult("Number ROI", row, nRoi);
			setResult("Number Events", row, nEvents);
			setResult("Events Colocalization", row, nColocalization/nEvents*100);
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

function calculateFusionParameters(bFolder) {
	res = 0; // cumulative number of results
	pRes = 0; // previous number of results (change when a new cell is loaded)
	if (bFolder) {
		// loop through the movies in one folder
		imgDir = getDirectory("Select images folder");
		dirFile = getFileList(imgDir);
		nFile = dirFile.length;
	} else {
		// search only the current image
		imgDir = getDirectory("image");
		imgTitle = getTitle();
		dirFile = getFileList(imgDir);
		for (srcImg = 0; srcImg < dirFile.length; srcImg++) {
			if (matches(dirFile[srcImg], imgTitle)) {
				fileID = srcImg;
				srcImg = dirFile.length;
			}
		}
		nFile = 1;
	}
	// get some additional options
	Dialog.create("Export fusion data");
	Dialog.addNumber("Baseline frames", 5);
	Dialog.addNumber("NH4 start", nh4Start);
	Dialog.addCheckbox("Synaptic fusion", true);
	Dialog.addCheckbox("Pool estimation", true);
	Dialog.show();
	baseFrames = Dialog.getNumber();
	nh4Start = Dialog.getNumber();
	bSynaptic = Dialog.getCheckbox();
	bPool = Dialog.getCheckbox();
	// get the synaptic folder and name
	synID = 0;
	if (bSynaptic) {
		// loop through the synaptic masks
		synDir = getDirectory("Select synapse folder");
		Dialog.create("File name correction");
		Dialog.addString("Synapse ID", "syn");
		Dialog.addString("Movie ID", "dyn123");
		Dialog.show();
		synName = Dialog.getString();
		movName = Dialog.getString();
	}
	// get the NH4 response folder
	nZip = 0;
	if (bPool) {
		poolDir = getDirectory("Select NH4 response folder");
		// check how many .zip files exist
		for (i = 0; i < nFile; i++) {
			if (endsWith(dirFile[i], ".zip")) {
				nZip++;
			}
		}
		// create an array to store the fusion mode of the fusion peak;
		namePool = newArray(nZip);
		rawPool = newArray(nZip); // raw number of puncta
		cor1Pool = newArray(nZip); // adjusted based on the fusion data
		cor2Pool = newArray(nZip); // adjusted based on the puncta data
	}
	nZip = 0;
	setBatchMode(true);
	for (fImg = 0; fImg < nFile; fImg++) {
		if (!bFolder) {
			fImg = fileID;
		}
		if (endsWith(dirFile[fImg], ".tif")) {
			showStatus("Analyzing cell " + dirFile[fImg]);
			open(imgDir + dirFile[fImg]);
			imgID = getImageID();
			imgTitle = getTitle();
			nameParts = split(imgTitle, "_");
			// open the RoiManager and detect neurites
			if (File.exists(imgDir + "RoiSet_" + replace(imgTitle, ".tif", ".zip"))) {
				nZip++;
				roiManager("open", imgDir + "RoiSet_" + replace(imgTitle, ".tif", ".zip"));
				nRoi = roiManager("count");
				// get the x location of all points
				allXC = newArray(nRoi);
				allYC = newArray(nRoi);
				for (r = 0; r < nRoi; r++) {
					roiManager("select", r);
					Roi.getBounds(allXC[r], allYC[r], width, height);
				}
				if (bSynaptic) {
					if (File.exists(synDir + replace(imgTitle, movName, synName))) {
						open(synDir + replace(imgTitle, movName, synName));
						synID = getImageID();
						run("Create Selection");
						//waitForUser("1");
						Roi.getContainedPoints(xpoints, ypoints);
						selectImage(imgID);
					} else {
						synID = 0;
					}
				}
				showStatus("Analyzing cell " + dirFile[fImg]);
				// loop through the roi
				for (r = 0; r < nRoi; r++) {
					roiManager("select", r);
					Roi.getBounds(x, y, width, height);
					xC = x+1;
					yC = y+1;
					roiName = split(Roi.getName, "-");
					vesID = roiName[0];
					nEv = roiName.length; // remove the VesID
					// get the intensity profile
					selectImage(imgID);
					run("Plot Z-axis Profile");
					Plot.getValues(timeFrames, vesicle);
					run("Close");
					// calculate Synaptic localization
					synLoc = "N.D.";
					minSynDist = "NaN";
					if (synID < 0) {
						selectImage(synID);
						roiManager("select", r);
						getStatistics(area, synMean, min, max, std, histogram);
						if (synMean > 60) {
							synLoc = "Syn";
						} else {
							synLoc = "Extra-Syn";
						}
						// calculate the average distance (in px) from the closest point on a synapse
						nPoints = xpoints.length;
						minSynDist = 512;
						//waitForUser(minSynDist);
						for (pp = 0; pp < nPoints; pp++) {
							tempDist = sqrt(pow(xpoints[pp] - xC, 2) + pow(ypoints[pp] - yC, 2));
							if (tempDist < minSynDist) {
								minSynDist = tempDist;
							}
						}
						selectImage(imgID);
					}
					//waitForUser(minSynDist);
					// calculate the minimum distance from other roi
					minRoiDist = 512;
					if (nEv > 2) {
						minRoiDist = 0;
					} else {
						for (rp = 0; rp < nRoi; rp++) {
							if (rp != r) {
								xCP = allXC[rp]+1;
								yCP = allYC[rp]+1;
								tempRoiDist = sqrt(pow(xCP - xC, 2) + pow(yCP - yC, 2));
								if (tempRoiDist < minRoiDist) {
									minRoiDist = tempRoiDist;
								}
							}
						}
					}
					// loop through the events	
					for (e = 1; e < nEv; e++) {
						// get the fusion frame
						fuseStart = roiName[e];
						// get the fusion duration - get the average of the intensity +- 1 frame to the starting point, then look for the first (two) frames that goes below this value
						startPoints = Array.slice(vesicle, fuseStart-3, fuseStart+1);
						startPoints = Array.getStatistics(startPoints, min, max, thrInt, thrSTD);
						testFrames = Array.slice(vesicle, fuseStart+1, nh4Start);
						nFrames = testFrames.length;
						for (f = 0; f < nFrames; f++) {
							if (f == nFrames - 1) {
								fuseDuration = nFrames + 2;
							} else {
								bFirst = testFrames[f] <= thrInt;
								if (bFirst) {
									bSecond = testFrames[f+1] <= thrInt;
									if (bSecond) {
										fuseDuration = f + 2;
										f = nFrames;
									}
								}
							}
						}
						// get the fusion peak: average of event (from start to end) over the average of baseline (5 frames)
						fuseS = Array.slice(vesicle, fuseStart-baseFrames, fuseStart);
						Array.getStatistics(fuseS, min, max, baseInt, stdDev);
						if (fuseDuration >= 5) {
							fuseF = Array.slice(vesicle, fuseStart, fuseStart+baseFrames);
						} else {
							fuseF = Array.slice(vesicle, fuseStart, fuseStart+fuseDuration);
						}
						Array.getStatistics(fuseF, min, max, peakInt, stdDev);
						fusePeak = peakInt / baseInt;
						// end by saving and increase the results raw by 1
						setResult("CellID", res, replace(imgTitle, ".tif", ""));
						setResult("Condition", res, nameParts[1]);
						setResult("VesicleID", res, vesID);
						setResult("FusionStart", res, parseInt(fuseStart)/2-0.5);
						setResult("FusionDuration", res, fuseDuration/2);
						setResult("FusionPeak", res, fusePeak);
						setResult("Localize", res, synLoc);
						//waitForUser(minSynDist);
						setResult("SynDistance(px)", res, minSynDist);
						setResult("RoiDistance(px)", res, minRoiDist);
						setResult("RawPeak", res, peakInt);
						res++;
					}
				}
				// close image and reset RoiManager
				if (synID < 0) {				
					selectImage(synID); close();
				}
				selectImage(imgID); close();
				roiManager("reset");
				if (bPool) {
					// calculate the pool for this cell; first get the pool data
					lines = split(File.openAsString(poolDir + "NH4Res_" + replace(imgTitle, ".tif", ".csv")), "\n");
					val = newArray(lines.length - 1);
					for (i = 1; i < lines.length; i++) {
						tempVal = split(lines[i], ",\t");
						val[i-1] = parseFloat(tempVal[1]);
					}
					// calculate the median intensity and adjust the values
					Array.sort(val);
					punctaQ = calculatePercentile(val);
					medPuncta = 0;
					for (i = 0; i < val.length; i++) {
						medPuncta = medPuncta + round(val[i] / punctaQ[1]);
					}
					// get the fusion data
					tempPeak = newArray(res-1-pRes);
					for (i = pRes; i < res-1; i++) {
						tempPeak[i-pRes] = getResult("RawPeak", i);
					}
					// calculate the median intensity and adjust the values
					Array.sort(tempPeak);
					peakQ = calculatePercentile(tempPeak);
					if (peakQ[1] == 0) {
						Array.print(tempPeak);
						//waitForUser("a");
					}
					medPeak = 0;
					for (i = 0; i < val.length; i++) {
						medPeak = medPeak + round(val[i] / peakQ[1]);
					}
					// now store the data
					namePool[nZip-1] = replace(imgTitle, ".tif", "");
					rawPool[nZip-1] = val.length; // raw number of puncta
					cor1Pool[nZip-1] = medPeak; // adjusted based on the fusion data
					cor2Pool[nZip-1] = medPuncta; // adjusted based on the puncta data
				}
				pRes = res;
			}
		}
	}
	
	updateResults();
	IJ.renameResults("Vesicles Parameters");
	if (bPool) {
		for (i = 0; i < namePool.length; i++) {
			setResult("Title", i, namePool[i]);
			setResult("rawPool", i, rawPool[i]);
			setResult("FuseCorrected", i, cor1Pool[i]);
			setResult("PunctaCorrected", i, cor2Pool[i]);
		}
		updateResults();
		IJ.renameResults("Pool values");
	}
}






// Adjust Roi Manager name with fusion time
/*
imgDir = getDirectory("Select images folder");
dirFile = getFileList(imgDir);
nFile = dirFile.length;
// find the txt file
for (i = 0; i < nFile; i++) {
	if (endsWith(dirFile[i], ".txt")) {
		txtID = i;
		i = nFile;
	}
}
allRoi = split(File.openAsString(imgDir + dirFile[txtID]), "\n");
noTot =allRoi.length;
for (i = 1; i < noTot; i++) {
	tempIDs = split(allRoi[i], ",");
	cellID = tempIDs[0];
	if (i==1) {
		roiManager("open", imgDir + "RoiSet_" + cellID + ".zip");
		adjustRoiName(cellID, Array.slice(allRoi, i, noTot-1));
		roiManager("save", imgDir + "RoiSet_" + cellID + ".zip");
		roiManager("reset");
	} else {
		oldIDs = split(allRoi[i-1], ",");
		if (matches(cellID, oldIDs[0])) {
			// do nothing
		} else {
			// new cell
			roiManager("open", imgDir + "RoiSet_" + cellID + ".zip");
			adjustRoiName(cellID, Array.slice(allRoi, i, noTot));
			roiManager("save", imgDir + "RoiSet_" + cellID + ".zip");
			roiManager("reset");
		}
	}
}


function adjustRoiName(cellID, tempRois) {
	nRoi = roiManager("count");
	for (r = 0; r < nRoi; r++) {
		roiManager("select", r);
		// check the the roi is still in the correct cell
		testIDs = split(tempRois[r], ",");
		if (matches(testIDs[0], cellID)) {
			roiManager("rename", testIDs[1]);
		} else {
			if (r == nRoi-1) {
				roiManager("delete");
			} else {
				waitForUser(cellID + " Roi n " + r);
			}
		}
	}
}
*/

// Calculate only the synaptic distance
/*
imgDir = getDirectory("Select images folder");
dirFile = getFileList(imgDir);
nFile = dirFile.length;
synDir = getDirectory("Select images folder");
Dialog.create("File name correction");
Dialog.addString("Synapse ID", "synapsin");
Dialog.addString("Movie ID", "dynamins");
Dialog.show();
synName = Dialog.getString();
movName = Dialog.getString();
res=nResults;
setBatchMode(true);
for (i = 0; i < nFile; i++) {
	if (endsWith(dirFile[i], ".zip")) {
		roiManager("open", imgDir + dirFile[i]);
		cellID = replace(dirFile[i], "RoiSet_", "");
		cellID = replace(cellID, ".zip", ".tif");
		nRoi = roiManager("count");
		allXC = newArray(nRoi);
		allYC = newArray(nRoi);
		if (File.exists(synDir + replace(cellID, movName, synName))) {
			open(synDir + replace(cellID, movName, synName));
			synID = getImageID();
			run("Create Selection");
			showProgress(i/nFile);
			showStatus("Analyzing cell " + cellID);
			Roi.getContainedPoints(xpoints, ypoints);
			nPoints = xpoints.length;
			for (r = 0; r < nRoi; r++) {
				roiManager("select", r);
				Roi.getBounds(allXC[r], allYC[r], width, height);
			}
			for (r = 0; r < nRoi; r++) {
				// min distance from synapses
				roiManager("select", r);
				roiName = split(Roi.getName, "-");
				vesID = roiName[0];
				nEv = roiName.length;
				if (nEv > 1) {
					roiManager("select", r);
					xC = allXC[r]+1;
					yC = allYC[r]+1;
					minSynDist = 512;
					for (pp = 0; pp < nPoints; pp++) {
						tempDist = sqrt(pow(xpoints[pp] - xC, 2) + pow(ypoints[pp] - yC, 2));
						if (tempDist < minSynDist) {
							minSynDist = tempDist;
						}
					}
					// min distance from other ROI
					minRoiDist = 512;
					if (nEv > 2) {
						minRoiDist = 0;
					} else {
						for (rp = 0; rp < nRoi; rp++) {
							if (rp != r) {
								xCP = allXC[rp]+1;
								yCP = allYC[rp]+1;
								tempRoiDist = sqrt(pow(xCP - xC, 2) + pow(yCP - yC, 2));
								if (tempRoiDist < minRoiDist) {
									minRoiDist = tempRoiDist;
								}
							}
						}
					}
					for (e = 1; e < nEv; e++) {
						setResult("CellID", res, replace(cellID, ".tif", ""));
						setResult("SynDistance(px)", res, minSynDist);
						setResult("RoiDistance(px)", res, minRoiDist);
						res++;
					}
				}
			}
			close(synID);
		}
		roiManager("reset");
	}
}
updateResults();


run("Create Selection");
Roi.getContainedPoints(xpoints, ypoints);
nRoi = roiManager("count");
for (r = 0; r < nRoi; r++) {
	roiManager("select", r);
	Roi.getBounds(x, y, width, height);
	xC = x+1;
	yC = y+1;
	roiName = split(Roi.getName, "-");
	vesID = roiName[0];
	nEv = roiName.length; // remove the VesID
	roiManager("select", r);
	nPoints = xpoints.length;
	minSynDist = 512;
	for (pp = 0; pp < nPoints; pp++) {
		tempDist = sqrt(pow(xpoints[pp] - xC, 2) + pow(ypoints[pp] - yC, 2));
		if (tempDist < minSynDist) {
			minSynDist = tempDist;
		}
	}
	for (e = 1; e < nEv; e++) {
		print(minSynDist);
	}
}

*/
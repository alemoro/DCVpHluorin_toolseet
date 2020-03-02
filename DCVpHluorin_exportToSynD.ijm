// DCV-pHluorin Analyzer - export for SynD-SynJ

/*
This macro is used to create options for the DCV-pHluorin toolset

Modify
	2018.12.21 - Created

Version
	Base - DCV_pHluorin v2.0
	Function - DCVpHluorin_exportToSynD v1.0

Developed by Alessandro Moro
Department of Functional Genomics (FGA)
Centre of neuroscience and cognitive research (CNCR)
Vrij Universiteit (VU) Amsterdam.
email: a.moro@vu.nl; al.moro@outlook.com
*/
			
// Initialize the variables
var DCV_dir = getDirectory("imagej") + "macros//toolsets//DCVpHluorin";
// get the options from the ij.Prefs
var nh4Start = call("ij.Prefs.get", "DCVpHluorin.nh4Start", true);
var bgFrames = call("ij.Prefs.get", "DCVpHluorin.bgFrames", true);
var morphology = call("ij.Prefs.get", "DCVpHluorin.synMorphology", true);
var synapses = call("ij.Prefs.get", "DCVpHluorin.synSynapses", true);
var other = call("ij.Prefs.get", "DCVpHluorin.synOther", true);

Dialog.create("Export to SynD-SynJ");
Dialog.addChoice("Morphology (red)", newArray("NH4 Average", "NH4 Max", "NH4 Std Dev"), morphology);
Dialog.addChoice("Synapses (green)", newArray("NH4 Average", "NH4 Max", "NH4 Std Dev", "Synapses"), synapses);
Dialog.addChoice("Other (blue)", newArray("NH4 Average", "NH4 Max", "NH4 Std Dev", "Synapses"), other);
Dialog.addCheckbox("Process folder", true);
Dialog.show();
morphology = Dialog.getChoice();
synapses = Dialog.getChoice();
other = Dialog.getChoice();
bBatch = Dialog.getCheckbox();

// save the preferences
call("ij.Prefs.set", "DCVpHluorin.synMorphology", morphology);
call("ij.Prefs.set", "DCVpHluorin.synSynapses", synapses);
call("ij.Prefs.set", "DCVpHluorin.synOther", other);

bSyn = false;
synDir = "synapticDirectory";
if ((matches(synapses, "Synapses")) || (matches(other, "Synapses"))) {
	synDir = getDirectory("Select synapse folder");
	bSyn = true;
}
setBatchMode(true);
if (bBatch) {
	workDir = getDirectory("Select movie folder");
	workFile = getFileList(workDir);
	for (f = 0; f < workFile.length; f++){
		if (endsWith(workFile[f], ".tif")){
			open(workDir + workFile[f]);
			exportToSynJ(bSyn, synDir);
		}
	}
} else {
	exportToSynJ(bSyn, synDir);
	setBatchMode("Exit and display");
}

function exportToSynJ(bSyn, synDir) {
	title = getTitle();
	imgDir = getDirectory("Image");
	name = replace(title, ".tif", "_pool");
	imgID = getImageID();
	if (bSyn) {
		title = replace(title, ".tif", "");
		nameParts = split(title, "_");
		synFile = getFileList(synDir);
		for (s = 0; s < synFile.length; s++){
			synName = synFile[s];
			synName = substring(synName, 0, lengthOf(synName)-4);
			synPart = split(synName, "_");
			bCont = (matches(synPart [0], nameParts[0])) && (matches(synPart [2], nameParts[2])) && (matches(synPart [3], nameParts[3]));
			if (bCont) {
				open(synDir + synFile[s]);
				oldID = getImageID();
				run("Duplicate...", " ");
				snpID = getImageID();
				selectImage(oldID);
				close();
				s = synFile.length;
			}
		}
		selectImage(imgID);
	}
	newStart = parseInt(nh4Start) - parseInt(bgFrames);
	run("Z Project...", "stop=" + bgFrames + " projection=[Average Intensity]");
	bkgID = getImageID();
	imageCalculator("Subtract create stack", imgID, bkgID);
	dupID = getImageID();
	selectImage(bkgID); close();
	selectImage(dupID);
	if (matches(morphology, "NH4 Average")) {
		run("Z Project...", "start="+newStart+" projection=[Average Intensity]");
	} else if (matches(morphology, "NH4 Max")) {
		run("Z Project...", "start="+newStart+" projection=[Max Intensity]");
	} else if (matches(morphology, "NH4 Std Dev")) {
		run("Z Project...", "start="+newStart+" projection=[Standard Deviation]");
		run("16-bit");
	}
	rename("morphology"); morID = getImageID();
	selectImage(dupID);
	if (matches(synapses, "NH4 Average")) {
		run("Z Project...", "start="+newStart+" projection=[Average Intensity]");
	} else if (matches(synapses, "NH4 Max")) {
		run("Z Project...", "start="+newStart+" projection=[Max Intensity]");
	} else if (matches(synapses, "NH4 Std Dev")) {
		run("Z Project...", "start="+newStart+" projection=[Standard Deviation]");
		run("16-bit");
	} else {
		selectImage(snpID);
	}
	rename("synapses"); synID = getImageID();
	selectImage(dupID);
	if (matches(other, "NH4 Average")) {
		run("Z Project...", "start="+newStart+" projection=[Average Intensity]");
	} else if (matches(other, "NH4 Max")) {
		run("Z Project...", "start="+newStart+" projection=[Max Intensity]");
	} else if (matches(other, "NH4 Std Dev")) {
		run("Z Project...", "start="+newStart+" projection=[Standard Deviation]");
		run("16-bit");
	} else {
		selectImage(snpID);
	}
	rename("other"); othID = getImageID();
	run("Merge Channels...", "c1=morphology c2=synapses c3=other create");
	poolID = getImageID();
	saveAs("Tif", imgDir + "\\" + name + ".tif");
	//selectImage(dupID); close();
}

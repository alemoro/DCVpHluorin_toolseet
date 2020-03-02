// DCV-pHluorin Analyzer - RoiManager cleaner function

/*
This macro is used to create options for the DCV-pHluorin toolset

Modify
	2018.12.21 - Created

Version
	Base - DCV_pHluorin v2.0
	Function - DCVpHluorin_RoiManagerCleaner v1.0

Developed by Alessandro Moro
Department of Functional Genomics (FGA)
Centre of neuroscience and cognitive research (CNCR)
Vrij Universiteit (VU) Amsterdam.
email: a.moro@vu.nl; al.moro@outlook.com
*/

// Initialize the variables
var DCV_dir = getDirectory("imagej") + "macros//toolsets//DCVpHluorin";
roiOver = call("ij.Prefs.get", "DCVpHluorin.roiOver", true);

nRoi = roiManager("count");
r = 0;
setBatchMode("hide");
while(r<nRoi){
	showProgress(-(r+1),nRoi);
	showStatus("Cleaning Roi Manager " +r+"/"+nRoi);
	roiManager("Select", r);
	r1 = 0;
	Roi.getBounds(x0, y0, width0, height0);
	roiArea = width0*height0;
	while(r1<nRoi){
		if(r==r1){r1++;}
		if(r1 < nRoi){
			roiManager("Select", r1);
			bROI = 0;
			for(x = x0; x < x0+width0; x++){
				for(y = y0; y <y0+height0; y++){
					bROI = bROI + Roi.contains(x,y);
				}
			}
			if(bROI > roiOver){
				roiManager("Delete");
				nRoi = nRoi - 1;
				r1 = r1;
			} else {
				r1++;
			}
		}
	}
	r++;
}
setBatchMode("Exit and display");
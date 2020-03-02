// DCV-pHluorin Analyzer - Groovy plugins to check ROI and add/remove events

/*
This groovy plugin allow the user to evaluate the starting point of the events per ROI, adding and removing them as well as removing the ROI if no real events are present


Modify
	20.02.28 - Add new event will not continue to the next ROI

Version
	Base - DCV_pHluorin v2.0
	Function - DCVpHluorin_CheckROIs v1.0

Developed by Alessandro Moro
Department of Functional Genomics (FGA)
Centre of neuroscience and cognitive research (CNCR)
Vrij Universiteit (VU) Amsterdam.
email: a.moro@vu.nl; al.moro@outlook.com
*/

// @ImagePlus img
// @OpService ops
// @UIService ui
// @RoiManager rm

import ij.IJ
import ij.process.ImageStatistics
import net.imglib2.type.numeric.real.DoubleType
import net.imglib2.img.array.ArrayImgFactory
import ij.plugin.ZAxisProfiler
import ij.gui.Plot
import ij.gui.ProfilePlot
import ij.plugin.Profiler
import ij.gui.Overlay
import java.awt.Color
import ij.WindowManager
import ij.gui.NonBlockingGenericDialog
import ij.gui.GenericDialog
import java.awt.event.WindowEvent
import java.awt.event.KeyListener
import java.awt.Frame

imgTitle = img.getTitle()
imgID = img.getID()
imgWindow = WindowManager.getWindow(imgTitle)
rois = rm.getRoisAsArray()
nRoi = rm.getCount()
roiIdx = rm.getIndexes()
// Before start ask if starting from the start or from a specific ROI
gd = new GenericDialog("ROI check startup")
gd.addNumericField("Start from ROI", roiIdx[0], 0, 1, "")
gd.addCheckbox("Zoom to event?", false)
gd.showDialog()
int r = gd.getNextNumber() - 1
bZoom = gd.getCheckboxes()
while (r < nRoi) {
	// get the ROI
	rm.select(img, r)
	String roiName = rm.getName(r)
	events = roiName.split("-")
	roiID = events[0]
	events = events[1..-1]
	// zoom in to selection
	if (bZoom.state == true) {
		println(bZoom.state)
		IJ.run("To Selection", "")
		for (z=0; z<5; z++) {
			IJ.run("Out [-]", "")
		}
	}
	// get the value of the starting frame
	eventMean = []
	eventFrame = []
	for (String e : events) {
		eventFrame.add(e.toInteger())
		img.setSlice(e.toInteger())
		stats = img.getAllStatistics()
		eventMean.add(stats.mean)
	}
	// Now get the values for the plot
	imgBound = imgWindow.getBounds()
	int plotX = imgBound.x + imgBound.width
	int plotY = imgBound.y + imgBound.height / 3
	plot = ZAxisProfiler.getPlot(img)
	xValue = plot.getXValues()
	yValue = plot.getYValues()
	plot1 = new Plot(roiName, "Frame", "Mean", xValue, yValue)
	plot1.draw()
	plot1.setColor(Color.RED)
	plot1.setLineWidth(2)
	plot1.add("circle", (double[]) eventFrame, (double[]) eventMean)
	wPlot = plot1.show()
	plotBound = wPlot.getBounds()
	int plotW = plotBound.width
	int plotH = plotBound.height
	wPlot.setBounds(plotX, plotY, plotW, plotH)
	// Now for the cool part, add the nonmodal dialog to select the events
	plotBound = wPlot.getBounds()
	int dlgY = plotBound.y + plotBound.height
	nEvents = eventFrame.size()
	dKeep = new NonBlockingGenericDialog("ROIs Check " + (r+1) + " / " + nRoi)
	for (String e : events) {
		dKeep.addCheckbox(e, true)
	}
	//dKeep.setInsets(0, 30, 3)
	dKeep.addNumericField("New?", (double) 0, (int) 0, (int) 1, "")
	dKeep.addToSameRow()
	dKeep.addCheckbox("Finish?", false)
	dKeep.enableYesNoCancel("Next", "Previus")
	dKeep.setCancelLabel("Delete event")
	dKeep.setLocation(plotX, dlgY)
	dKeep.showDialog()
	// get the event back
	if (dKeep.wasCanceled()) {
		rm.runCommand("Delete")
	} else {
		keepEvent = roiID
		cB = dKeep.getCheckboxes()
		for (int e=0; e<nEvents; e++) {
			if (cB[e].state == true) {
				keepEvent += "-"+events[e]
			}
		}
		int newEvent = dKeep.getNextNumber()
		bNext = 1
		if (newEvent > 0) {
			keepEvent += "-"+newEvent
			bNext = 0
		}
		rm.rename(r, keepEvent)
		if (dKeep.wasOKed()) {
			if (bNext) {
				r+=1
			}
		} else {
			if (r>0) {
				r-=1
			} else {
				r = 0
			}
		}
		if (cB[-1].state) {
			r = rm.getCount()
		}
	}
	wPlot.close()
	rois = rm.getRoisAsArray()
	nRoi = rm.getCount()
}

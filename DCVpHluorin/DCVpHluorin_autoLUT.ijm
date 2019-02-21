// from Kota Miura EMBL http://imagej.1557.x6.nabble.com/Auto-Brightness-Contrast-and-setMinAndMax-td4968628.html
AUTO_THRESHOLD = 5000; 
getRawStatistics(pixcount); 
limit = pixcount/10; 
threshold = pixcount/AUTO_THRESHOLD; 
nBins = 256; 
getHistogram(values, histA, nBins); 
i = -1; 
found = false; 
do { 
	counts = histA[++i]; 
    if (counts > limit) counts = 0; 
    found = counts > threshold;
} while ((!found) && (i < histA.length-1)) 
hmin = values[i]; 
//hmin = 50;
i = histA.length; 
do { 
	counts = histA[--i]; 
	if (counts > limit) counts = 0; 
	found = counts > threshold; 
} while ((!found) && (i > 0)) 
hmax = values[i]; 
setMinAndMax(hmin, hmax); 
//print(hmin, hmax); 
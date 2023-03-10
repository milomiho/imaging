
#@ File (label = "Input directory", style = "directory") input
#@ File (label = "Output directory", style = "directory") output
#@ String (label = "File suffix", value = ".tif") suffix
#@ String (label = "Title contains") pattern
#@ String (label = "number of channels") nchannels
#@ String (label = "mask channel") mask // Specify which channel is used as the mask.

processFolder(input);

// function to scan folders/subfolders/files to find files with correct suffix
function processFolder(input) {
	list = getFileList(input);
	list = Array.sort(list);
	for (i = 0; i < list.length; i++) {
		//if (File.isDirectory(input + File.separator + list[i]))
			//processFolder(input + File.separator + list[i]);
		if (endsWith(list[i], suffix))
		if (matches(list[i], "(.*)"+pattern+"(.*)"))
			processFile(input, output, list[i]);
			//print(list[i]);
			
	}
}

function processFile(input, output, file) {
// Open image.
	print("Processing: " + file);
	open(input + File.separator + file);
	f = File.nameWithoutExtension;
	run("Split Channels");
// Process the mask channel
	selectWindow("C" + mask + "-" + file);
	run("Median...", "radius=3 stack");
	run("Threshold...");
	setThreshold(25, 255);
	run("Convert to Mask", "method=Default background=Dark black");
	run("Invert LUT");
	run("Fill Holes", "stack");
	saveAs("Tiff", output + File.separator + f + "_" + mask + ".tif");
// Make projections on the xy and yz plane for measuring the angles.
	run("3D Project...", "projection=[Brightest Point] axis=Y-Axis slice=1 initial=-90 total=0 rotation=0 lower=1 upper=255 opacity=0 surface=100 interior=50");
	selectWindow("Projections of " + f + "_" + mask);
	saveAs("Tiff", output + File.separator + f + "_yz.tif");
	close();
// Get the masked signals of other channels.
	selectWindow(f + "_" + mask + ".tif");
	run("Divide...", "value=255.000 stack");
	for (c = 1; c <= nchannels; c++) { 
		if(c != mask) {
			imageCalculator("Multiply create stack", "C" + c + "-" + file, f + "_" + mask + ".tif");
			selectWindow("Result of C" + c + "-" + file);
			saveAs("Tiff", output + File.separator + f + "_" + c + ".tif");
			close();
		}
	} 
// Close the windows.
	n = nImages;
	for (ii = 0; ii < n; ii++) {
		close();
	}
	
}

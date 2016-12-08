module HelloVis

import IO;
import vis::Figure;
import vis::Render;
import util::Editors;
import List;
import vis::KeySym;
import Series2;
import String;

loc file1 = |project://Series2-MC/src/HelloVis.rsc|;
loc file2 = |project://HelloWorld2/src/HelloWorld2.java|;
list[loc] clones1 = [|project://Series2-MC/src/HelloVis.rsc|(279,51,<12,6>,<14,47>), |project://Series2-MC/src/HelloVis.rsc|(279,51,<27,6>,<33,47>)];
list[loc] clones2 = [|project://HelloWorld2/src/HelloWorld2.java|(279,51,<1,6>,<28,47>)];

public loc testLoc = file1;

public void runTest()
{
	dataStructure = formData();

	//fileList = for (file <- allFiles) append toLocation(file);
	//figureList = for (item <- fileList) append makeFileVis(item, [], size(allFiles[item.uri]));
	
	figureList = for (item <- dataStructure) append makeFileVis(item, dataStructure[item], size(allFiles[item]));
	
	widthVal = size(figureList) * 100;
	
	render("Duplication Visualisation", hcat(figureList, top(), resizable(false, false), fillColor("aquamarine"), hgap(15)) );
}

public map[str, list[Duplicate]] formData()
{

	map[str,list[Duplicate]] fileDups = ();
	int count = 0;
	
  	for(dClass <- dupClasses)
 	{
    	for(dLoc <- dupClasses[dClass])
		{
        	if(dLoc.location.uri notin fileDups)
        	{
        		fileDups[dLoc.location.uri] = [dLoc];
        	}
        	else
        	{
				fileDups[dLoc.location.uri] += dLoc;
        	}
      	}
  	}
  	
  	return fileDups;
}

public Figure makeFileVis(str file, list[Duplicate] clones, int fileSize)
{
	loc location = toLocation(file);
	
	//generate a box for the file itself
	container = box(size(100, fileSize), resizable(false, false), fillColor("azure"));
	
	//get the bounds of the various clones
	list[tuple[int first, int second, Duplicate clone]] cloneLocations;
	
	cloneLocations = for (clone <- clones) append <clone.line.searchIndex, (clone.line.searchIndex + clone.length), clone>;
	
	println(cloneLocations);
	
	//generate the boxes showing the clones
	//cloneBoxes = for (tuple[num first, num second, Duplicate clone] bounds <- cloneLocations) append ( box
	//(		text("<bounds.first> - <bounds.second>"),
	//		resizable(true, false),
	//		size(100, (bounds.clone.length)),
	//		fillColor("Red"),
	//		valign(bounds.first / fileSize),
	//		onMouseDown(bool (int butnr, map[KeyModifier,bool] modifiers) { println(bounds.clone.location); return true; }
	//		))); 		
	list[Figure] cloneBoxes = [];
	int i = 0;		
	for (tuple[num first, num second, Duplicate clone] bounds <- cloneLocations)
	{
		loc locat = bounds.clone.location;
		println(bounds.first / fileSize);
		cloneBoxes += box(	text("<bounds.first> - <bounds.second>"),
				resizable(true, false),
				size(100, (bounds.clone.length)),
				fillColor(color("red")),
				valign(bounds.first / fileSize),
				hint("<bounds.clone.location>"),
				onMouseDown(bool (int butnr, map[KeyModifier,bool] modifiers) { edit(locat); return true; })
				);
				i+=1;
				println(bounds.clone.location);
	}
			
	//compose the above into a single figure
	cloneBoxesFigure = vcat(cloneBoxes, vsize(fileSize), resizable(false, false), top(), fillColor("red"));
	
	//overlay this on the container box
	cloneBoxesOverlaid = overlay([container, cloneBoxesFigure], resizable(false, false), top(), fillColor("green"));
	
	//add the filename
	finalFigure = vcat([text(location.file, top())] + cloneBoxesOverlaid + [text("<fileSize>", bottom())], resizable(false, false), top(), vgap(5), fillColor("blue"));

	return finalFigure;
}

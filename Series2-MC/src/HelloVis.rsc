module HelloVis

import IO;
import vis::Figure;
import vis::Render;
import util::Editors;
import List;
import vis::KeySym;
import Series2;
import String;

//run a test render on the last analyzed project
public void runTest()
{
	//manipulate the datastructure from the analysis & render it
	dataStructure = formData();
	renderClones(dataStructure, false);
}

//render the clone view
public void renderClones(map[str, list[Duplicate]] clones, bool filtered)
{
	//for each file, render it, and it's clones
	figureList = for (item <- clones)
		append makeFileVis(item, clones[item], size(allFiles[item]), filtered);
	
	//set the viewport width
	widthVal = size(figureList) * 100;
	
	//make Rascal render the figures
	render(filtered ? "Clone class" : "Duplication Visualisation", hcat(figureList, top(), resizable(false, false), fillColor("aquamarine"), hgap(15)) );
}

//manipulate the analysis data for rendering
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

public Figure makeFileVis(str file, list[Duplicate] clones, int fileSize, bool filterd)
{
	loc location = toLocation(file);
	
	//generate a box for the file itself
	container = box(size(100, fileSize), resizable(false, false), fillColor("azure"));
	
	//get the bounds of the various clones
	list[tuple[int first, int second, Duplicate clone]] cloneLocations;
	
	//make a tuple containing start and end locations for clone, plus the clone itself
	cloneLocations = for (clone <- clones) append <clone.line.searchIndex, (clone.line.searchIndex + clone.length), clone>;
	
	list[Figure] cloneBoxes = [];
	int i = 0;
	
	//pull each clone into a new tuple for field access		
	for (tuple[num first, num second, Duplicate clone] bounds <- cloneLocations)
	{
		Duplicate cln = bounds.clone;	//ensure clone loc is stored locally for click listener binding
		cloneBoxes += box(
				resizable(true, false),				//only w resizable
				size(100, (bounds.clone.length)),	//100 wide, height according to clone size
				fillColor(color("red")),			//make it angry red.
				valign(bounds.first / fileSize),	//align the box based on location in file
				hint("<bounds.clone.location>"),	//add a hint
				onMouseDown(bool (int butnr, map[KeyModifier,bool] modifiers) { filterd ? edit(bounds.clone.location) : renderClones(generateFileDups(cln), true)  ; return true; })
				);		//finally, bind mousedown event. If first click, drill down one level, otherwise, show clone
				i+=1;
				println(bounds.clone.location);
	}
	
	//overlay this on the container box
	cloneBoxesOverlaid = overlay([container] + cloneBoxes, resizable(false, false), top(), fillColor("green"));
	
	//add the filename
	finalFigure = vcat([text(location.file, top())] + cloneBoxesOverlaid + [text("<fileSize>", bottom())], resizable(false, false), top(), vgap(5), fillColor("blue"));

	//return a completed figure
	return finalFigure;
}

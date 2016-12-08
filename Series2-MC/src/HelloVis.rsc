module HelloVis

import IO;
import vis::Figure;
import vis::Render;
import util::Editors;
import List;
import vis::KeySym;
import Series2;
import String;

//test method
public void runTest()
{
	dataStructure = formData();
	renderClones(dataStructure, false);
}

//render the clone view
public void renderClones(map[str, list[Duplicate]] clones, bool filtered)
{
	//for each file (& clones) make the file visualisation
	figureList = for (item <- clones) append makeFileVis(item, clones[item], size(allFiles[item]), filtered);
	
	widthVal = size(figureList) * 100;
	
	//create the visualisation by hcatting file figures
	Figure fileFigure = hcat(figureList, top(), resizable(false, false), fillColor("aquamarine"), hgap(15));
	
	//generate upper box for menus, render the clones
	Figure upperBox = box(text("TODO: Menus. See MainMenu.rsc for src", align(0,0)),size(250,150));
	render(filtered ? "Clone Class" : "Duplication Visualisation", vcat([upperBox, fileFigure]));
}

//manipulate data for rendering
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

public Figure makeFileVis(str file, list[Duplicate] clones, int fileSize, bool filtered)
{
	loc location = toLocation(file);
	
	//generate a box for the file itself
	container = box(size(100, fileSize), resizable(false, false), fillColor("azure"));
	
	//get the bounds of the various clones
	list[tuple[int first, int second, Duplicate clone]] cloneLocations;
	
	//get tuples from list
	cloneLocations = for (clone <- clones) append <clone.line.searchIndex, (clone.line.searchIndex + clone.length), clone>;
		
	list[Figure] cloneBoxes = [];

	for (tuple[num first, num second, Duplicate clone] bounds <- cloneLocations)
	{
		Duplicate cln = bounds.clone;				//store temp clone for click listener
		cloneBoxes += box(							//make the box, add to list
				resizable(true, false),				//resizable only horizontal
				size(100, (bounds.clone.length)),	//set size according to clone size
				fillColor(color("red")),			//make it angry red
				valign(bounds.first / fileSize),	//align according to clone pos
				hint("<bounds.clone.location>"),	//add hint
				onMouseDown(bool (int butnr, map[KeyModifier,bool] modifiers)
				{
					//if we are clicking a filtered clone, show the clone
					//otherwise render the filtered clones
					filtered ? edit(bounds.clone.location) : renderClones(generateFileDups(cln), true);
					return true;
				}
				));
	}
	
	//overlay this on the container box
	cloneBoxesOverlaid = overlay([container] + cloneBoxes, resizable(false, false), top(), fillColor("green"));
	
	//add the filename
	finalFigure = vcat([text(location.file, top())] + cloneBoxesOverlaid + [text("<fileSize>", bottom())], resizable(false, false), top(), vgap(5), fillColor("blue"));

	//return the composited figure
	return finalFigure;
}

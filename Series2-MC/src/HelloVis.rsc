module HelloVis

import IO;
import vis::Figure;
import vis::Render;
import util::Editors;
import List;
import vis::KeySym;

loc file1 = |project://Series2-MC/src/HelloVis.rsc|;
loc file2 = |project://HelloWorld2/src/HelloWorld2.java|;
list[loc] clones1 = [|project://Series2-MC/src/HelloVis.rsc|(279,51,<12,6>,<14,47>), |project://Series2-MC/src/HelloVis.rsc|(279,51,<27,6>,<33,47>)];
list[loc] clones2 = [|project://HelloWorld2/src/HelloWorld2.java|(279,51,<1,6>,<28,47>)];
num filesize1 = 87.00;
num filesize2 = 36.00;

public void runTest()
{
	figure1 = makeFileVis(file1, clones1, filesize1);
	figure2 = makeFileVis(file2, clones2, filesize2);
	
	list[Figure] figures = [figure1, figure2];
	
	render("Duplication Visualisation", hcat(figures, hgap(30)));
}

public Figure makeFileVis(loc file, list[loc] clones, num fileSize)
{
	container = box(size(100, fileSize), resizable(true, true));
	
	cloneBoxBegins = for (clone <- clones) append clone.begin.line;
	cloneBoxEnds = for (clone <- clones) append clone.end.line;
	cloneBoxBounds = zip(cloneBoxBegins, cloneBoxEnds);
	
	//generate the boxes showing the clones
	cloneBoxes = for (bounds <- cloneBoxBounds) append ( box
	(
			resizable(true, false),
			size(100, (bounds.second - bounds.first)),
			fillColor("Red"),
			valign(bounds.first / fileSize),
			onMouseEnter(void () { println("Entering <file.file>"); }),
			onMouseExit(void () { println("Leaving <file.file>"); }),
			onMouseDown(bool (int butnr, map[KeyModifier,bool] modifiers) { edit(clones1[0]); return true; }
			)));
	
	//compose the above into a single figure
	cloneBoxesFigure = vcat(cloneBoxes, vsize(fileSize), resizable(true, false));
	
	//overlay this on the container box
	cloneBoxesOverlaid = overlay([container, cloneBoxesFigure], resizable(true, true));
	
	//add the filename
	finalFigure = vcat([text(file.file, top())] + cloneBoxesOverlaid, resizable(true, false));

	return finalFigure;
}

module HelloVis

import IO;
import vis::Figure;
import vis::Render;
import List;

loc file1 = |project://Series2-MC/src/HelloVis.rsc|;
loc file2 = |project://HelloWorld2/src/HelloWorld2.java|;
list[loc] clones1 = [|project://Series2-MC/src/HelloVis.rsc|(279,51,<12,6>,<14,47>), |project://Series2-MC/src/HelloVis.rsc|(279,51,<27,6>,<33,47>)];
list[loc] clones2 = [|project://HelloWorld2/src/HelloWorld2.java|(279,51,<1,6>,<28,47>)];
num filesize1 = 87.00;
num filesize2 = 36.00;

//loc file2 = ;

public void runTest()
{
	figure1 = makeFileVis(file1, clones1, filesize1);
	figure2 = makeFileVis(file2, clones2, filesize2);
	
	list[Figure] figures = [figure1, figure2];
	
	render(hcat(figures));
}

public Figure makeFileVis(loc file, list[loc] clones, num fileSize)
{
	container = box(size(100, fileSize), resizable(false, false));
	
	render("container <file.file>", container);
	
	cloneBoxBegins = for (clone <- clones) append clone.begin.line;
	cloneBoxEnds = for (clone <- clones) append clone.end.line;
	cloneBoxBounds = zip(cloneBoxBegins, cloneBoxEnds);
	
	//generate the boxes showing the clones
	cloneBoxes = for (bounds <- cloneBoxBounds) append (box( resizable(false, false), size(100, (bounds.second - bounds.first)), fillColor("Red"), valign(bounds.first / fileSize), onMouseEnter(void () { println("Entering <file.file>"); }), onMouseExit(void () { println("Leaving <file.file>"); })));
	
	//compose the above into a single figure
	cloneBoxesFigure = vcat(cloneBoxes, vsize(fileSize), resizable(false, false));
	
	//overlay this on the container box
	cloneBoxesOverlaid = overlay([container, cloneBoxesFigure], resizable(false, false));
	
	//add the filename
	finalFigure = vcat([text(file.file, top())] + cloneBoxesOverlaid, resizable(false, false));

	return finalFigure;
}

//public void runHelloVis()
//{
//
//	//main box
//	container = box(size(100, 300), resizable(false, false));
//
//	//boxes for clones
//	b0 = box(size(100,50), resizable(false, false), fillColor("Red"), valign(0.3), hsize(50));
//	b1 = box(size(100,50), resizable(false, false), fillColor("Green"), valign(0.8), hsize(50));
//
//	b2 = box(size(100,50), resizable(false, false), fillColor("Red"), valign(0.1), hsize(50));
//	b3 = box(size(100,50), resizable(false, false), fillColor("Green"), valign(0.4), hsize(50));
//
//	//columns for files, with clones as children
//	file1 = overlay([container, b0, b1]);
//	file2 = overlay([container, b1, b2]);
//	file3 = overlay([container]);;
//
//	//list files
//	files = [file1, file2, file3];
//
//	//make a slider to scale vertically
//	slider = scaleSlider(int() { return 0; },     					//min bound
//                                    int () { return 300; },  		//max bound
//                                    int () { return n; },			//current value
//                                    void (int s) {n = s;},    
//                        			width(100), resizable(false, false));
//    
//    //row1 = [ slider ];									//scaling slider
//    row2 = [text("File1"), text("File2"), text("File3")];	//file names
//	row3 = [ file1, file2, file3 ];							//file outlines
//       		
//	render(grid([/*row1,*/ row2, row3]));					//render the grid
//    
//}



module HelloVis

import IO;
import vis::Figure;
import vis::Render;
import util::Editors;
import util::Math;
import List;
import Map;
import vis::KeySym;
import Series2;
import String;
import MainMenu;

public map[str,str] classColors = ();
public int viewIndex = 0;
public Duplicate selectedClone;

public Figure topLeft = box();
public Figure topRight = box();
public Figure bottomHalf = box();

list[str] approvedColors = colorNames() - ["black","blue","darkblue","mediumblue","midnightblue","navy","azure"]; // Exclude the listed colors

// Tool settings
str topBarColor = "mediumaquamarine";
str backgroundColor = "snow";

int topBarHeight = 100;
int topRightWidth = 250;

Figure overView = box();

//test method
public void runTest()
{
	renderClones(("":[]), false);
}

//render the clone view
public void renderClones(map[str, list[Duplicate]] clones, bool filtered)
{
	if(clones != ("":[]))
	{
		// Project selected
		if(filtered)
		{
			//println();
			// Cloneclass view			
			topLeft = box(getCloneClassMetrics(getSixLines(clones[getOneFrom(clones)][0].line)), fillColor(topBarColor));
			topRight = box(button("Back to overview", void(){renderClones(generateFileDups(), false);},hsize(150), hgap(25), resizable(false, false)), fillColor(topBarColor), width(topRightWidth), resizable(false,true));//box(resizable(false, true), width(250), fillColor("lightgreen"));
			bottomHalf = box(getCloneFigure(clones, true));
		}
		else
		{
			topLeft = box(getMetrics(), fillColor(topBarColor));
			topRight = box(getMainMenu(), width(topRightWidth), fillColor(topBarColor), resizable(false,true));//box(resizable(false, true), width(250), fillColor("lightgreen"));
			
			bottomHalf = box(getCloneFigure(clones, false));
			
		}
	}
	else
	{
		// Mainmenu, no project selected
		topLeft = box(text("Clone Detection Tool", fontSize(40)), fillColor(topBarColor));
		topRight = box(getMainMenu(), width(topRightWidth), fillColor(topBarColor), resizable(false,true));//box(resizable(false, true), width(250), fillColor("lightgreen"));
		bottomHalf = box(text("Please select a project to analyze"));
	}
	Figure top = box(hcat([(topLeft), topRight]), height(topBarHeight), resizable(true, false));	
	render("Clone Detection Tool", (vcat([top, bottomHalf])));
	
}


public Figure getCloneFigure(map[str, list[Duplicate]] clones, bool filtered)
{	
	//for each file (& clones) make the file visualisation
	figureList = for (item <- clones) append makeFileVis(item, clones[item], size(allFiles[item]), filtered);
	sortedList = sort(figureList, bool(tuple[int len, Figure fig] a, tuple[int len, Figure fig] b){return a.len > b.len;});
	finalList = for (tuple[int len, Figure fig] fig <- sortedList) append fig.fig;
	widthVal = size(figureList) * 100;
	
	//create the visualisation by hcatting file figures
	return scrollable(hcat(finalList, top(), resizable(false, false), fillColor("aquamarine"), hgap(15)));
	
}

public Figure getMetrics()
{
	num percentage = 0;
	if(projectMetrics.lineCount > 0)
	{
		percentage =  (projectMetrics.duplicateLines-projectMetrics.subsumedLines)/projectMetrics.lineCount * 100.00;
	}		
	str metrics = "Results for <projectToProcess.authority>
			'The project has <projectMetrics.lineCount> lines for codes containting <projectMetrics.numberOfClones> clones this is <round(percentage,0.01)>% of the total project.
			'<projectMetrics.subsumedClones>(<projectMetrics.subsumedLines> LOC) of these clones are subsumed inside other clones. The biggest clone is <projectMetrics.biggestClone.length> LOC long.
			'There are <size(dupClasses)> clone classes. The biggest class contains <size(dupClasses[projectMetrics.biggestCloneClass])> clones.";
	metricFig = text(metrics);
	classClick = text("This is the biggest clone class(Click!)",fontColor("Blue"), left(),onMouseDown(bool (int butnr, map[KeyModifier,bool] modifiers){renderClones(generateFileDups(dupClasses[projectMetrics.biggestCloneClass][0]), true);return true;}));
	cloneClick = text("This is the biggest clone(Click!)",fontColor("Blue"), left(),onMouseDown(bool (int butnr, map[KeyModifier,bool] modifiers){renderClones(generateFileDups(projectMetrics.biggestClone), true);return true;}));
	return  vcat([metricFig, classClick, cloneClick], align(0,0));
}

public Figure getCloneClassMetrics(str classKey)
{

	Metrics classMetrics = getClassMetrics(classKey);
	num totalClassLines = classMetrics.numberOfClones*classMetrics.lineCount;
	num percentage = 0;
	if(totalClassLines > 0)
	{
		percentage = (totalClassLines-classMetrics.subsumedLines) / projectMetrics.duplicateLines * 100.00;
	}	
	str metrics = "This clone class contains <classMetrics.numberOfClones> clones. There are <classMetrics.subsumedClones>(<classMetrics.subsumedLines> LOC) subsumed clones in this class.
		'These clones are <classMetrics.lineCount> LOC which makes this class contain a total of <classMetrics.numberOfClones*classMetrics.lineCount> LOC.
		'This is <round(percentage, 0.01)>% of the total duplicate lines in this project";
	return text(metrics, align(0,0));
}


public tuple[int len, Figure fig] makeFileVis(str file, list[Duplicate] clones, int fileSize, bool filtered)
{
	loc location = toLocation(file);
	
	//generate a box for the file itself
	container = box(size(100, fileSize), resizable(false, false), fillColor("azure"));
	
	//get the bounds of the various clones
	list[tuple[int first, int second, Duplicate clone]] cloneLocations;
	
	//get tuples from list
	cloneLocations = for (clone <- clones) append <clone.line.searchIndex, (clone.line.searchIndex + clone.length), clone>;
		
	list[Figure] cloneBoxes = [];
	int len = 0;
	for (tuple[num first, num second, Duplicate clone] bounds <- cloneLocations)
	{
		Duplicate cln = bounds.clone;
		str lbl = "";
		if(cln.subsumed) lbl = "Subsumed";				//store temp clone for click listener
		cloneBoxes += box(
				text(lbl, fontSize(10)),							//make the box, add to list
				resizable(true, false),				//resizable only horizontal
				size(75, (bounds.clone.length)),	//set size according to clone size
				fillColor(color(getCloneClassColor(cln))),			//make it angry red
				valign(bounds.first / fileSize),	//align according to clone pos
				hint("<bounds.clone.location>"),	//add hint
				onMouseDown(bool (int butnr, map[KeyModifier,bool] modifiers)
				{
					//if we are clicking a filtered clone, show the clone
					//otherwise render the filtered clones
					if(filtered) edit(cln.location);
					else {renderClones(generateFileDups(cln), true);}
					return true;
				}
				));
		len = cln.length;
	}
	
	//overlay this on the container box
	cloneBoxesOverlaid = overlay([container] + cloneBoxes, resizable(false, false), top(), fillColor("green"));
	
	//add the filename
	finalFigure = vcat([text(location.file, top(), onMouseDown(bool (int butnr, map[KeyModifier,bool] modifiers){edit(location);return true;}))] + cloneBoxesOverlaid + [text("<fileSize>", bottom())], resizable(false, false), top(), vgap(5), fillColor("blue"));

	//return the composited figure
	return <len,finalFigure>;
}

public Figure getMainMenu()
{
	return vcat([
				combo(["smallsql", "hsqldb"], void(str s){ modifySelectedProject(s); }, hsize(200), resizable(false, false)),
				button("Analyse", void(){renderClones(generateFileDups(), false);}, hsize(100), hgap(25), resizable(false, false))
				], resizable(false, false));
}

public void modifySelectedProject(str s)
{
	if (s == "smallsql")
		projectToProcess = project2;
	else if (s == "hsqldb")
		projectToProcess = project1;
}

public str getCloneClassColor(Duplicate cln)
{
	str key = getSixLines(cln.line);
	if(key notin classColors)
	{
		classColors[key] = getOneFrom(approvedColors);
	}
	return classColors[key];
}

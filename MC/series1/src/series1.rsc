module series1

import lang::java::m3::Core;
import lang::java::jdt::m3::Core;
import analysis::m3::AST;
import lang::java::jdt::m3::AST;
import util::Benchmark;
import Set;
import List;
import IO;
import String;

public loc project1 = |project://HelloWorld2/src/|;
public loc project2 = |project://smallsql0.21_src/src/|;
public loc project3 = |project://hsqldb-2.3.1/src/|;

public void runTests(loc project)
{
	num simpleTotal = 0;
	num moreTotal = 0;
	num complexTotal = 0;
	num untestableTotal = 0;
	
	//start profiling
	startTime = getMilliTime();

	//generate the M3 model and run off a list of basic metrics
	model = createM3FromEclipseProject(project);
	units = toList(methods(model));
	totalLines = sum(unitsTotalLines(model));
	
	complexities = for(unit <- units) append getComplexity(unit, model);
	sizes = for(unit <- units) append countFileCodeLines(unit);
	
	//generate tuple with LOC and complexity
	list[tuple[int lines, int complexity]] complexityList = zip(sizes, complexities);
	
	//filter tuples by complexity, get a list of LOC numbers
	simple = for(unit <- complexityList) if (unit.complexity <= 10) append unit.lines;
	more = for(unit <- complexityList) if (unit.complexity >= 11 && unit.complexity <= 20) append unit.lines;
	complex = for(unit <- complexityList) if (unit.complexity >= 21 && unit.complexity <= 50) append unit.lines;
	untestable = for(unit <- complexityList) if (unit.complexity > 50) append unit.lines;
	
	//calculate percentages
	num percentageSimple = (sum([0]+simple) / totalLines) * 100;
	num percentageMore = (sum([0]+more) / totalLines) * 100;
	num percentageComplex = (sum([0]+complex) / totalLines) * 100;
	num percentageUntestable = (sum([0]+untestable) / totalLines) * 100;
	
	//output metrics
	println("Units in project: <getNumUnits(model)>");
	println("Total LOC in project: <totalLines>");
	println("% of lines in simple units: <percentageSimple>");
	println("% of lines in more complex units: <percentageMore>");
	println("% of lines in complex units: <percentageComplex>");
	println("% of lines in untestable units: <percentageUntestable>");
	println("% total (debugging purposes): <percentageSimple + percentageMore + percentageComplex + percentageUntestable>");
	
	//output profiling info
	endTime = getMilliTime();
	println("Duration: <endTime-startTime>ms");
	
}

public int getComplexity(loc l, M3 model)
{
	//start with a complexity of 1
	int complexity = 1;
	//generate the ast from the given loc
	ast = getMethodASTEclipse(l, model=model);
	
	//visit all statements in the ast, increment complexity accordingly
	visit(ast){
		case \if(icond,ithen,ielse): {	//if then else
       		complexity += 1; } 
    	case \if(icond,ithen): {		//if then
        	complexity += 1; } 
        case \switch(_,_): {			//switch statements
        	complexity += 1; }
        case \case(_): {				//cases in switch statements
        	complexity += 1; }
        case \for(_,_,_,_): {			//for loops
        	complexity += 1; }
        case \for(_,_,_,_,_): {			//for loops with lists of updaters
        	complexity += 1; }
        case \while(_,_): {				//while loops
        	complexity += 1; }	
        case \do(_,_): {				//do while
        	complexity += 1; }
	}
	
	return complexity;
}

//returns the number of units in a given project
public int getNumUnits(M3 m)
{
	return size(methods(m));
}

//returns a list of class sizes
public list[int] unitsTotalLines(M3 m)
{
	return mapper(toList(methods(m)), countFileCodeLines);
}

//returns total lines of code in each class, by summing class sizes
public int countTotalProjectLines2(M3 m)
{
	return sum(classesTotalLines(m));
}

//returns total lines of code in a project, from files
public int countTotalProjectLines(loc project)
{
	return sum(mapper(project.ls, countFileCodeLines));
}

//counts total lines of code in a given loc
public int countFileCodeLines(loc file)
{

	source = readFileLines(file);
	whiteLines = [s | s <- source, /^[ \t\r\n]*$/ := s];
	commentLines1 = [s | s <- source, /((\s|\/*)(\/\*|^(\s+\*))|^(\s*\/*\/))/ := s];
	
	//println(commentLines1);
	return size(source) - size(whiteLines) - size(commentLines1);			

}

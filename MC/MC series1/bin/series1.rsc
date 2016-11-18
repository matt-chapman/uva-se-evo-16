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
	numUnits = getNumUnits(model);
	unitsLines = unitsTotalLines(model);
	totalLines = sum(unitsLines);
	unitSizeDist = makeUnitSizeRank(unitsLines, numUnits);
	
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
	num percentageSimple = (sum([0.00]+simple) / totalLines) * 100;
	num percentageMore = (sum([0.00]+more) / totalLines) * 100;
	num percentageComplex = (sum([0.00]+complex) / totalLines) * 100;
	num percentageUntestable = (sum([0.00]+untestable) / totalLines) * 100;
	
	//output metrics
	println("Units in project: <numUnits>");
	println("Total LOC in project: <totalLines>");
	println("---");
	println("Distribution of unit sizes: ");
	println("0 \< Unit LOC \< 30: <unitSizeDist[0]>%");
	println("31 \<= Unit LOC \<= 44: <unitSizeDist[1]>%");
	println("45 \<= Unit LOC \<= 74: <unitSizeDist[2]>%");
	println("Unit LOC \> 75: <unitSizeDist[3]>%");
	println("% of lines in simple units: <percentageSimple>");
	println("% of lines in more complex units: <percentageMore>");
	println("% of lines in complex units: <percentageComplex>");
	println("% of lines in untestable units: <percentageUntestable>");
	println("% total (debugging purposes): <percentageSimple + percentageMore + percentageComplex + percentageUntestable>");
	println("");
	println("SIG SCORE COMPLEXITY = <makeComplexityRank(percentageSimple, percentageMore, percentageComplex, percentageUntestable)>");
	println("SIG SCORE VOLUME = <makeVolumeRank(totalLines)>");
	//println("SIG SCORE UNIT SIZE = <>");
	
	//output profiling info
	endTime = getMilliTime();
	println("Duration: <endTime-startTime>ms");
	
}

public int makeVolumeRank(num lines)
{
	num klines = lines / 1000;
	
	//++  0-66
	//+   66-246
	//o   246-665 
	//-   655-1,310 
	//--  > 1,310 
	
	if( klines > 0 && klines <= 66)
	{
		return 4;
	}
	else if ( klines >= 67 && klines <= 246)
	{
		return 3;
	}
	else if ( klines >= 247 && klines <= 665)
	{
		return 2;
	}
	else if ( klines >= 656 && klines <= 1310)
	{
		return 1;
	}
	else if ( klines > 1310)
	{
		return 0;
	}
}

public list[int] calcUnitSizeRanks(list[int] units)
{
	return for (numLines <- units)
		if(numLines > 0 && numLines <= 30)
			append 4;
		else if (numLines >= 31 && numLines < 44)
			append 3;
		else if (numLines >= 45 && numLines < 74)
			append 2;
		else if (numLines > 74)
			append 1;
}

public list[num] makeUnitSizeRank(list[int] units, num numUnits)
{

//★★★★★ - 19.5 10.9 3.9
//★★★★✩ - 26.0 15.5 6.5
//★★★✩✩ - 34.1 22.2 11.0
//★★✩✩✩ - 45.9 31.4 18.1

	//map[int rank, int j] mapOfRanks = distribution(calcUnitSizeRanks(units));
	num rank1 = 0;
	num rank2 = 0;
	num rank3 = 0;
	num rank4 = 0;
	
	ranks = sort(calcUnitSizeRanks(units));
	
	for (rank <- ranks)
		if (rank == 1) rank1 += 1;
		else if (rank == 2) rank2 += 1;
		else if (rank == 3) rank3 += 1;
		else if (rank == 4) rank4 += 1;
	
	list[num] totals = [rank4, rank3, rank2, rank1];
	
	return [ ((i / numUnits) * 100) | i <- totals];
	
}

public int makeComplexityRank(num low, num moderate, num high, num vhigh)
{
	//++      25% moderate, 0% high, 0% very high
	//+       30% moderate, 5% high, 0% very high
	//o       40% moderate, 10% high, 0% very high
	//-       50% moderate, 15% high, 5% very high
	//--      >50% moderate, >15% high, >5% very high
	
	if( moderate <= 25.0 && high == 0.0 && vhigh == 0.0 )
	{
		return 4;
	}
	else if ( moderate >= 26.0 && moderate < 30.0 && high > 0 && high <= 5 && vhigh == 0.0 )
	{
		return 3;
	}
	else if ( moderate >= 31.0 && moderate < 40 && high >=6 && high < 10 && vhigh == 0.0 )
	{
		return 2;
	}
	else if ( moderate >= 41.0 && moderate < 50.0 && high >= 11.0 && high < 15.0 && vhigh <= 5.0 )
	{
		return 1;
	}
	else if ( moderate > 50.0 || high > 15.0 || vhigh > 5)
	{
		return 0;
	}
	
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
public list[num] unitsTotalLines(M3 m)
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

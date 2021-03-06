module ComplexityAnalysis

import lang::java::m3::Core;
import lang::java::jdt::m3::Core;
import analysis::m3::AST;
import lang::java::jdt::m3::AST;
import util::Benchmark;
import util::Math;
import Set;
import List;
import IO;
import String;

public tuple[int,int] runComplexityAnalysis(M3 model)
{
	num simpleTotal = 0;
	num moreTotal = 0;
	num complexTotal = 0;
	num untestableTotal = 0;

	units = toList(methods(model));
	numUnits = getNumUnits(model);
	
	complexities = for(unit <- units) append getComplexity(unit, model);
	sizes = for(unit <- units) append countFileCodeLines(unit);
	
	sizesNoZeroes = for(size <- sizes) if (size != 0) append size;
	
	totalLines = sum(sizes);	
	
	//list[num] uSizeRanks = makeUnitSizeRank(sizes, numUnits);
	
	
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
	
	unitSizePercents = makeUnitSizePercents(sizes, numUnits);
	unitSizeRank = makeUnitSizeRank(unitSizePercents);
	
	//output metrics
	println("
			'UNIT SIZE
			'---
			'Units in project: <numUnits>
			'---
			'Units in low risk category	 		: <round(unitSizePercents[0], 0.01)>%
			'Units in med risk category    			: <round(unitSizePercents[1], 0.01)>%
			'Units in high risk category			: <round(unitSizePercents[2], 0.01)>%
			'Units in v.high risk category			: <round(unitSizePercents[3], 0.01)>%
			'
			'UNIT COMPLEXITY
			'---
			'LOC in simple units (not much risk)		: <round(percentageSimple,0.01)>% 
			'LOC in more complex units (moderate risk)	: <round(percentageMore,0.01)>%
			'LOC in complex units (high risk)		: <round(percentageComplex,0.01)>%
			'LOC in untestable units (very high risk)	: <round(percentageUntestable,0.01)>%");

	//println("SIG SCORE COMPLEXITY = <>");
	
	return <makeComplexityRank(percentageSimple, percentageMore, percentageComplex, percentageUntestable), unitSizeRank>;
	
}

//generates SIG complexity score for a project
public int makeComplexityRank(num low, num moderate, num high, num vhigh)
{
	if( moderate <= 25.0 && high == 0.0 && vhigh == 0.0 )
	{
		return 4;
	}
	else if ( moderate < 30.0 && high <= 5 && vhigh == 0.0 )
	{
		return 3;
	}
	else if ( moderate < 40 && high < 10 && vhigh == 0.0 )
	{
		return 2;
	}
	else if ( moderate < 50.0 && high < 15.0 && vhigh <= 5.0 )
	{
		return 1;
	}
	return 0;
}

//generates complexity score for given method
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
    	case \try(_,_): {				//try
        	complexity += 1; }
    	case \try(_,_,\finally): {		//try finally
        	complexity += 1; }
    	case \catch(_,_): {				//catch
        	complexity += 1; }
    	case \throw(_): {				//throw
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

//counts total lines of code in a given loc
public int countFileCodeLines(loc file)
{
	source = readFileLines(file);
	whiteLines = [s | s <- source, /^[ \t\r\n]*$/ := s];
	commentLines1 = [s | s <- source, /((\s|\/*)(\/\*|^(\s+\*))|^(\s*\/*\/))/ := s];
	
	return size(source) - size(whiteLines) - size(commentLines1);			
}

//create a rank for each unit based on LOC
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

public int makeUnitSizeRank(list[num] percents)
{
	if( percents[1] <= 25.0 && percents[2] == 0.0 && percents[3] == 0.0 )
	{
		return 4;
	}
	else if ( percents[1] < 30.0 && percents[2] <= 5 && percents[3] == 0.0 )
	{
		return 3;
	}
	else if ( percents[1] < 40 && percents[2] < 10 && percents[3] == 0.0 )
	{
		return 2;
	}
	else if ( percents[1] < 50.0 && percents[2] < 15.0 && percents[3] <= 5.0 )
	{
		return 1;
	}
	else if (percents[1] > 50.0 && percents[2] > 15.0 && percents[3] > 5.0)
	{
		return 0;
	}
}

public list[num] makeUnitSizePercents(list[int] units, num numUnits)
{

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

	//return [ ((i / numUnits) * 100) | i <- totals];
	
	return for (total <- totals) append ((total/numUnits) * 100);

}


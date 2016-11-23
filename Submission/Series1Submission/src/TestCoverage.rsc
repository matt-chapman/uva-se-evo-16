module TestCoverage

import Set;
import List;
import IO;
import String;
import lang::csv::IO;
import util::Math;

public num getTestCoverageMetrics(loc csvloc)
{

y = readCSV(#rel[str GROUP,str PACKAGE,str CLASS,num INSTRUCTION_MISSED,num INSTRUCTION_COVERED,num BRANCH_MISSED,num BRANCH_COVERED,num LINE_MISSED,num LINE_COVERED,num COMPLEXITY_MISSED,num COMPLEXITY_COVERED,num METHOD_MISSED,num METHOD_COVERED], csvloc, separator = ",");

instructionsCoveredList = for (line <- y) append line.INSTRUCTION_COVERED;
instructionsMissedList = for (line <- y) append line.INSTRUCTION_MISSED;

return getTestCoverageRank(getTestCoveragePercent(instructionsCoveredList, instructionsMissedList));

}

public num getTestCoveragePercent(list[num] instructionsCoveredList, list[num] instructionsMissedList)
{
	num instructionsCovered = sum(instructionsCoveredList);
	num instructionsMissed = sum(instructionsMissedList);
	num instructionsTotal = instructionsCovered + instructionsMissed;
	
	percentCoverage = (instructionsCovered / instructionsTotal) * 100;
	println("
			'TEST COVERAGE
			'---
			'Total instructions to be tested			: <instructionsTotal> Java bytecode instructions
			'Total instructions actually Tested		: <instructionsCovered> Java bytecode instructions
			'Total instructions missed			: <instructionsMissed> Java bytecode instructions
			'Percentage test coverage			: <round(percentCoverage,0.01)>%
			'");
	return percentCoverage;
}

public num getTestCoverageRank(num percent)
{
	if(percent >= 95.0)
		return 4;
	else if (percent >= 80.0 && percent < 95.0)
		return 3;
	else if (percent >= 60.0 && percent < 80.0)
		return 2;
	else if (percent >= 20.0 && percent < 60.0)
		return 1;
	else if (percent >= 0.0 && percent < 20.0)
		return 0;
}
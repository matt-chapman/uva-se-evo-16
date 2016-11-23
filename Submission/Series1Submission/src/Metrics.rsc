module Metrics

import ComplexityAnalysis;
import DuplicateAnalysis;
import VolumeAnalysis;
import TestCoverage;

import lang::java::m3::Core;
import lang::java::jdt::m3::Core;
import analysis::m3::AST;
import lang::java::jdt::m3::AST;
import lang::csv::IO;
import lang::xml::DOM;
import util::Benchmark;
import util::Math;
import Set;
import List;
import IO;
import String;

//project locations
public loc project1 = |project://HelloWorld2/src/|;
public loc project2 = |project://hsqldb-2.3.1/hsqldb/|;
public loc project3 = |project://smallsql0.21_src/src/|;

public loc csvloc1 = |project://Series1Submission/src/small.csv|;
public loc csvloc2 = |project://Series1Submission/src/large.csv|;

//"Main" method
public void runTests(loc project)
{

	/*	Should output the following:
	*	Volume metric
	*	Unit size metric
	*	Unit complexity metric
	*	Duplication metric
	*	Unit size risk profiles
	*	Unit complexity risk profiles
	*	SIG scores: volume, unit size, unit complexity, duplication
	*
	*/
	gc();	//garbage collect
	num startTime = getMilliTime();
	println("BEGINNING ANALYSIS
			'---");
			
	//create the M3 model from the given project
	model = createM3FromEclipseProject(project);
	
	//run Duplicate and volume analysis
	tuple[num total,num dup, num com] dupsAndLines = countDuplicatesAndLines(project);
	
	num commentRatio = round((dupsAndLines.com / (dupsAndLines.total+dupsAndLines.com))*100,0.01);
	num duplicationRatio = getDuplicatePercentage(dupsAndLines);
	
	println("VOLUME
			'---
			'Project volume					: <dupsAndLines.total> LOC
			'Comment ratio 					: <commentRatio>%
			'
			'DUPLICATION
			'---
			'Number of duplicates found  			: <dupsAndLines.dup> codeblocks
			'Duplicate lines of code				: <dupsAndLines.dup*6> LOC
			'Percentage of duplicate code			: <round(duplicationRatio,0.01)>%");
	
	
	//get duplicate score
	dRank = getDuplicateRanking(duplicationRatio);
	
	//get volume score
	vRank = makeVolumeRank(dupsAndLines.total);
	//run complexity analysis - prints details directly
	//INCLUDES OUTPUT OF UNIT SIZES	
	tuple[int cR, int suR] cResults = runComplexityAnalysis(model);	
	cRank = cResults.cR;
	sRank = cResults.suR;
	
	num tRank;
	
	if(project.uri == project2.uri)
	{
		tRank = getTestCoverageMetrics(csvloc2);
	}
	else if (project.uri == project3.uri)
	{
		tRank = getTestCoverageMetrics(csvloc1);
	}
	else tRank = 0;
		
	anRank = makeAnalysabilityRank(vRank,dRank,sRank,tRank);
	chRank = makeChangeabilityRank(cRank,dRank);
	stRank = makeStabilityRank(tRank);
	teRank = makeTestabilityRank(cRank,sRank,tRank);
	
	maRank = makeMaintainabilityRank(anRank,chRank,stRank,teRank);
	
	println("RANKING
			'---
			'Volume ranking					: <makeRankStr(vRank)>
			'CC ranking					: <makeRankStr(cRank)>
			'Duplication ranking				: <makeRankStr(dRank)>
			'Unit size ranking				: <makeRankStr(sRank)>
			'Testing ranking					: <makeRankStr(tRank)>
			'");
	
	
	println("SIG SCORES
			'---
			'Analysability score				: <makeRankStr(anRank)>
			'Changeability score				: <makeRankStr(chRank)>
			'Stability score    				: <makeRankStr(stRank)>
			'Testability score  				: <makeRankStr(teRank)>
			'                   				 ______
			'Maintainability score				: <makeRankStr(maRank)>
			'
			'FINISHED. After <(getMilliTime() - startTime) / 1000>s");
}

public int makeAnalysabilityRank(num vRank, num dRank, num sRank, num tRank)
{
	num average = (vRank + dRank + sRank + tRank)/4;
	return round(average);
}

public int makeChangeabilityRank(num cRank, num dRank)
{
	num average = (cRank + dRank )/2;
	return round(average);
}

public int makeStabilityRank(int tRank)
{
	return tRank;
}

public int makeTestabilityRank(num cRank, num sRank, num tRank)
{
	num average = (cRank + sRank + tRank)/3;
	return round(average);
}

public int makeMaintainabilityRank(num anRank, num chRank, num stRank, num teRank)
{
	num average = (anRank + chRank + stRank + teRank)/4;
	return round(average);
}

public str makeRankStr(int rank)
{
	if (rank == 4)
		return "++";
	else if (rank == 3)
		return "+";
	else if (rank == 2)
		return "o";
	else if (rank == 1)
		return "-";
	else return "--";
}
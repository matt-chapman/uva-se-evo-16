module Metrics

import ComplexityAnalysis;
import DuplicateAnalysis;
import Volume;

import lang::java::m3::Core;
import lang::java::jdt::m3::Core;
import analysis::m3::AST;
import lang::java::jdt::m3::AST;
import util::Benchmark;
import Set;
import List;
import IO;
import String;

public void runTests(loc project)
{
	model = createM3FromEclipseProject(project);
	
	//run complexity analysis - prints details directly
	runComplexityAnalysis(model);
	
	//run volume analysis
	tuple[num total,num dup] dupsAndLines = countDuplicatesAndLines(project);
	
	vRank = makeVolumeRank(dupsAndLines.total);
	
	println(vRank);
	
}
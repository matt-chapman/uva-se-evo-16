module Series2UnitTests

import CloneDetection;
import CloneVisualisation;
import Exception;
import IO;
import Map;
import List;
import String;
import util::Math;

//Ensure that an empty file won't crash it
test bool emptyFileClones()
{
		loc emptyFile = |project://HelloWorld2/src/Empty.java|;
		projectToProcess = emptyFile;
		analyze(emptyFile);
		//catch RuntimeException: return false;
		
		return true;
}

//test for known clones
test bool knownFileClones()
{
	loc knownClones = |project://HelloClones/src|;
	projectToProcess = knownClones;
	
	analyze(knownClones);
	
	if(projectMetrics.numberOfClones == 2)
		return true;
	else
		return false;
	
}

//run against the large project
test bool largeProjectTest()
{
	loc largeProject = |project://hsqldb-2.3.1/hsqldb/|;
	projectToProcess = largeProject;
	
	try analyze(largeProject);
	catch RuntimeException:
		return false;

	return true;
}

//test getDuplicates
test bool testGetDuplicates()
{
	loc knownClones = |project://HelloClones/src|;
	projectToProcess = knownClones;
	
	testResult = getDuplicates();
	//println(testResult);
	
	//there should be 2 duplicates in total
	//this covers all of the filtering code also
	if(testResult == 2)
		return true;
	else
		return false;
}

test bool testGrowDuplicates()
{
	loc knownClones = |project://HelloClones/src|;
	projectToProcess = knownClones;
	analyze(knownClones);
	
	//println(projectMetrics);
	
	//should grow to cover 26 lines, 13 in each file
	if(projectMetrics.lineCount == 26)
		return true;
	else
		return false;
}

test bool testGenerateFileDups()
{
	//as above, generate duplicates with known data, compare
	loc knownClones = |project://HelloClones/src|;
	projectToProcess = knownClones;
	analyze(knownClones);
	
	if (size(generateFileDups()) == 2)
		return true;
	else
		return false;
}

test bool testGenerateFileDups2()
{
	//as above, generate duplicates with known data, compare
	loc knownClones = |project://HelloClones/src|;
	projectToProcess = knownClones;
	analyze(knownClones);
	
	if (size(generateFileDups(projectMetrics.biggestClone)) == 2)
		return true;
	else
		return false;
	return true;
}

test bool testGetSixLines()
{
	filterProjectFiles(|project://HelloClones/src/|);

	testData = FileLine("", toLocation("project://HelloClones/src/HelloClones1.java"), 0);
	testResult = getSixLines(testData);
	
	//println(testResult);
	
	//returns first 6 lines. In test data this is 161 characters exactly.
	if(size(testResult) == 161 && startsWith(testResult, "public class HelloClones1 {") && endsWith(testResult, "System.out.println(\"Line 3\");"))
		return true;
	else
		return false;
}

test bool testFilterProjectFiles()
{
	filterProjectFiles(|project://HelloClones/src/|);
	
	if(size(allFiles) == 2)
		return true;
	else
		return false;
}

test bool testFilterLines()
{
	loc testData = |project://HelloWorld2/src/HelloWorld2.java|;
	
	if (size(filterLines(testData)) == 22)
		return true;
	else
		return false;
}

test bool testIsWhitespace()
{
	str testData = "	  ";
	
	if(isWhiteSpace(testData))
		return true;
	else
		return false;
}

test bool testIsComment()
{
	str testData1 = "//testcomment";
	str testData2 = "/*testcomment2*/";
	str testData3 = "/*
					*
					*	test comment
					*
					*/";
	
	if(isComment(testData1) && isComment(testData2) && isComment(testData3))
		return true;
	else
		return false;
	
}

//check the metrics are generated correctly 'n' shit
test bool testMetricsGeneration()
{
	loc knownClones = |project://HelloClones/src|;

	testData = Metrics(
	Duplicate(
		FileLine(
			"\tpublic static void main(String[] argv)",
			|project://HelloClones/src/HelloClones1.java|(29,39,<0,0>,<0,0>),
			1),
			|project://HelloClones/src/HelloClones1.java|(29,305,<0,0>,<0,0>),
			12,
			false),
			round(26.0,1),
			round(2.0,1),
			"\tpublic static void main(String[] argv)\t{\t\tSystem.out.println(\"Line 1\");\t\tSystem.out.println(\"Line 2\");\t\tSystem.out.println(\"Line 3\");\t\tSystem.out.println(\"Line 4\");",
			round(24.0,1),
			round(0.0,1),
			round(0.0,1));
			
	projectToProcess = knownClones;
	analyze(knownClones);
	
	if(projectMetrics == testData)
		return true;
	else
		return false;			
}

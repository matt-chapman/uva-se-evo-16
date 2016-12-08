module Series2Tests

import HelloVis;
import Series2;
import Exception;

//Ensure that an empty file won't crash it
test bool emptyFileClones()
{
		loc emptyFile = |project://HelloWorld2/src/Empty.java|;
		try analyze(emptyFile);
		catch RuntimeException: return false;
		finally return true;
			
}

//test for known clones
test bool knownFileClones()
{
	loc knownClones = |project://HelloWorld2/src/HelloWorld2.java|;
	
	return true;
}

//run against the large project
test bool largeProjectTest()
{
	loc largeProject = |project://smallsql0.21_src|;
	
	try analyize(largeProject);
	catch RuntimeException:
		return false;
	//finally return true;
}
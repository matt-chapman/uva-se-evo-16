module series1

import lang::java::m3::Core;
import lang::java::jdt::m3::Core;
import Set;
import List;
import IO;
import String;

public loc project1 = |project://HelloWorld2/src/|;
public loc project2 = |project://smallsql0.21_src/src/|;
public loc project3 = |project://hsqldb-2.3.1/src/|;

public void runTests(loc project)
{
	model = createM3FromEclipseProject(project);
	println("Total units: <getUnits(model)>");
	println("Total lines in classes: <classesTotalLines(model)>");
	println("Total lines in project: <countTotalProjectLines2(model)>");
}

public int getUnits(M3 m)
{
	return size(classes(m));
}

//returns a list of class sizes
public list[int] classesTotalLines(M3 m)
{
	return mapper(toList(classes(m)), countFileCodeLines);
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
	return (size(readFileLines(file)) - size([
			s | s <- readFileLines(file),
			/^[ \t\r\n]*$/ := s]));
}

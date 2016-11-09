module series1

import lang::java::m3::Core;
import lang::java::jdt::m3::Core;
import Set;
import List;
import IO;
import String;

public loc project1 = |project://HelloWorld2/src/|;
public loc project2 = |project://smallsql0.21_src/src/|;
public M3 model = createM3FromEclipseProject(project2);

public int getUnits(M3 m)
{
	return size(classes(m));
}

public int classesTotalLines(M3 m)
{
	mapper(toList(classes(model)), countFileCodeLines);
}

public int countTotalProjectLines2(M3 m)
{
	sum(classesTotalLines(m));
}

//returns total lines of code in a project
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

module series1

import lang::java::m3::Core;
import lang::java::jdt::m3::Core;
import analysis::m3::AST;
import lang::java::jdt::m3::AST;
import Set;
import List;
import IO;
import String;

public loc project1 = |project://HelloWorld2/src/|;
public loc project2 = |project://smallsql0.21_src/src/|;
public loc project3 = |project://hsqldb-2.3.1/src/|;

public void runTests(loc project)
{
	//generate the M3 model and run off a list of basic metrics
	model = createM3FromEclipseProject(project);
	println("Total units: <getUnits(model)>");
	println("Total lines in classes: <classesTotalLines(model)>");
	println("Total lines in project: <countTotalProjectLines2(model)>");
	
	//grab a list of units in the project
	units = toList(classes(model));
	//generate a list of unit complexities
	complexityList = for (unit <- units) append getComplexity(unit);
	//spit out the complexity per unit
	println("Complexity per unit: <complexityList>");
	
}

public int getComplexity(loc l)
{
	//start with a complexity of 1
	int complexity = 1;
	//generate the ast from the given loc
	ast = createAstFromFile(l, true, javaVersion="1.7");
	
	//TODO: add other statement types
	//visit all statements in the ast, increment complexity accordingly
	visit(ast){
		case \if(icond,ithen,ielse): {
       		complexity += 1; } 
    	case \if(icond,ithen): {
        	complexity += 1; } 
	}
	
	return complexity;
}

public void Test(loc project)
{
	model = createM3FromEclipseProject(project);
	units = classes(model);
	println(units[0]);
}

//print out all statements in a given location
void statements(loc location) {
        ast = createAstFromFile(location,true,javaVersion="1.7");
        for(/Statement s := ast) println(readFile(s@src));
}

//returns the number of units in a given project
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

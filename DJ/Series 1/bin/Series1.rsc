module Series1	

import lang::java::m3::Core;
import lang::java::jdt::m3::Core;

import analysis::m3::AST;
import util::Resources;

import util::FileSystem;
import List;
import Set;
import String;
import IO;
import Map;
import util::Benchmark;

public loc project = |project://HelloWorld2/src/|;
public loc project1 = |project://hsqldb-2.3.1/hsqldb/|;
public loc project2 = |project://smallsql0.21_src/src/|;

set[loc] getProjectfiles() { 
   bool containsFile(loc d) = isFile(d) ? (d.extension == "java") : false;
   return find(project1, containsFile);
}

public void analyze()
{
	startTime = getMilliTime();
	println("Found <countDuplicates(getProjectfiles())> duplicates");
	endTime = getMilliTime();
	println("Duration: <endTime-startTime>ms");
}

public int countDuplicates(set[loc] allFiles)
{	
	list[tuple[str string, loc location]] duplicates = [];
	map[str, loc] nonDuplicates = ();
	int duplicateCount = 0;
	//totalsizelist = for(filelns <- allLines) append size(filelns);
	totalsize = size(allFiles);
	for(file <- allFiles){
		list[tuple[str string, loc location]] fileLines = filterLines(file);
		int searchIndex = 0;
		int fileLinesSize = size(fileLines);
		while(searchIndex < fileLinesSize)
		{
			duplicateString = getSixLines(fileLines, searchIndex);
			if(searchIndex+5 < fileLinesSize && duplicateString != "" && (duplicateString in nonDuplicates)){ 
				duplicateCount += 1;
				searchIndex += 5;
				//totalsize -= 5;
				duplicates += fileLines[searchIndex];
				//println("Duplicate found!");
				//println(duplicateString);
				//println(fileLines[searchIndex].location);
				//println(nonDuplicates[duplicateString]);
			}
			else{
				nonDuplicates += (duplicateString : fileLines[searchIndex].location);
				searchIndex += 1;
				//totalsize -= 1;
			}
			
			println("Analyzing line:<searchIndex> of <fileLinesSize> Duplicatecount: <duplicateCount> and <totalsize> files to go.");
			
		}
		totalsize -= 1;
	}
	//print(duplicates);
	return duplicateCount;
}


public str getSixLines(list[tuple[str string,loc location]] lines, int startIndex)
{
	if(startIndex+5 < size(lines)){
		return "<lines[startIndex].string><lines[startIndex+1].string><lines[startIndex+2].string><lines[startIndex+3].string><lines[startIndex+4].string><lines[startIndex+5].string>";
	}
	else return "";
}

public list[tuple[str,loc]] filterLines(loc file)
{
	fileLines = readFileLines(file);

	lineIndex = 0;
	
	list[tuple[str,loc]] filteredLines = [];
	
	for (s <- fileLines){ 
		if(!isWhiteSpace(s) && !isComment(s)){
			filteredLines += <s,file(lineIndex, 0,<0,0>,<0,0>)>;
		}
		lineIndex += 2 + size(s);
	}
	return filteredLines;
}

bool isWhiteSpace(str s){
	if(!/^[ \t\r\n]*$/ := s) return false;
	return false;
}

bool isComment(str s){
	if(!/((\s|\/*)(\/\*|\s\*)|[^\w,\;]\s\/*\/)/ := s) return false;
	return false;
}

int countEmptyLines(list[str] lines){
	i = 0;
	  for(s <- lines)
	    if(/^[ \t\r\n]*$/ := s)  
	      i +=1;
	  return i;
}

int countTotalLines(loc file)
{
	lines = readFileLines(file);
	
	int totalLines = size(lines);
	println("Total lines: <totalLines>");
	
	totalLines -= countEmptyLines(lines);
	println("Empty: <countEmptyLines(lines)>");
	
	totalLines -= countComments(lines);
	println("Comments: <countComments(lines)>");
	
	return totalLines;	
}

int countComments(list[str] lines){
	i = 0;
	  for(s <- lines)
	  
	    if(/((\s|\/*)(\/\*|\s\*)|[^\w,\;]\s\/*\/)/ := s)  	
	      i +=1;
	  return i;
}
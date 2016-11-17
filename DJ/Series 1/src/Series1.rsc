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

set[loc] getProjectfiles(loc project) { 
   bool containsFile(loc d) = isFile(d) ? (d.extension == "java") : false;
   return find(project, containsFile);
}

public void analyze(loc project)
{
	startTime = getMilliTime();
	countDuplicates(getProjectfiles(project));
	println("Analyzing took <getMilliTime() - startTime>ms");
}

public num countDuplicates(set[loc] allFiles)
{	
	list[tuple[str string, loc location]] duplicates = [];
	map[str, loc] nonDuplicates = ();
	
	num duplicateCount = 0;
	num totalSize = 0;
	
	for(file <- allFiles){
	
		list[tuple[str string, loc location]] fileLines = filterLines(file);
		int searchIndex = 0;
		fileLinesSize = size(fileLines);
		totalSize += fileLinesSize;
		
		while(searchIndex < fileLinesSize-5)
		{			
			duplicateString = getSixLines(fileLines, searchIndex);
			
			// Calculate the length of the 6 lines
			fileLines[searchIndex].location.length = (fileLines[searchIndex+5].location.offset +size(fileLines[searchIndex+5].string)) - fileLines[searchIndex].location.offset;
			
			if(searchIndex < fileLinesSize && duplicateString != "" && (duplicateString in nonDuplicates))
			{ 
				duplicates += fileLines[searchIndex];
							
				//println("False Duplicate <duplicateCount> found!");
				//println(duplicateString);	
				//println(fileLines[searchIndex].location);
				//println(nonDuplicates[duplicateString]);
		
				duplicateCount += 1;
				//Skip next 5 lines
				searchIndex += 5;
			}
			else{				
				nonDuplicates += (duplicateString : fileLines[searchIndex].location);
				searchIndex += 1;
			}
			
			//println("Duplicatecount: <duplicateCount>");
			
		}
	}
	num procent = ((duplicateCount*6)/(totalSize))*100;
	println("Total line count: <totalSize>, <duplicateCount>(<procent>%) duplicate lines, Ranking: <getDuplicateRanking(procent)>");
	return duplicateCount;
}


public str getSixLines(list[tuple[str string,loc location]] lines, int startIndex)
{
	if(startIndex+5 < size(lines)){
		return "<lines[startIndex].string><lines[startIndex+1].string><lines[startIndex+2].string><lines[startIndex+3].string><lines[startIndex+4].string><lines[startIndex+5].string>";
	}
	else return "";
}

public int getDuplicateRanking(num percentage)
{
	if(percentage <= 3) return 4;
	else if(percentage <= 5) return 3;
	else if(percentage <= 10) return 2;
	else if(percentage <= 20) return 1;
	return 0;
}

public list[tuple[str,loc]] filterLines(loc file)
{
	fileLines = readFileLines(file);
	fileOffset = 0;
	
	list[tuple[str,loc]] filteredLines = [];
	
	for (s <- fileLines){ 
		if(!isWhiteSpace(s) && !isComment(s)){
			filteredLines += <s,file(fileOffset,size(s),<0,0>,<0,0>)>;
		}
		fileOffset +=  2 + size(s);
	}
	return filteredLines;
}

bool isWhiteSpace(str s){
	if(/^[ \t\r\n]*$/ := s) return true;
	return false;
}

bool isComment(str s){
	if(/((\s|\/*)(\/\*|^(\s+\*))|^(\s*\/*\/))/ := s) return true;
	return false;
}

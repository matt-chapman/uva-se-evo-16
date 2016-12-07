module Series1	

import lang::java::m3::Core;
import lang::java::m3::AST;
import lang::java::jdt::m3::Core;
import lang::java::jdt::m3::AST;

import lang::java::m3::AST;
import lang::java::m3::Core;
import lang::java::jdt::m3::Core;
import lang::java::jdt::m3::AST;

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

data Duplicate = Duplicate(str content, loc location, int searchIndex);

set[loc] getProjectfiles(loc project) { 
   bool containsFile(loc d) = isFile(d) ? (d.extension == "java") : false;
   return find(project, containsFile);
}

public void analyze(loc project3)
{
	startTime = getMilliTime();
	//asts = createAstsFromEclipseProject(project3, true);
	//iprintln(asts);
	//println(asts);
	countDuplicates(getProjectfiles(project3));
	println("Analyzing took <getMilliTime() - startTime>ms");
}

public num countDuplicates(set[loc] allFiles)
{	
	list[Duplicate] duplicates = [];
	map[str, list[Duplicate]] allLines = ();
	map[str, Duplicate] nonDuplicates = ();
	
	num duplicateCount = 0;
	num totalSize = 0;
	
	for(file <- allFiles){
	
		list[Duplicate] fileLines = filterLines(file);
		int searchIndex = 0;
		fileLinesSize = size(fileLines);
		allLines += (file.uri : fileLines);
		
		totalSize += fileLinesSize;
		
		while(searchIndex < fileLinesSize-5)
		{			
			duplicateString = getSixLines(fileLines, searchIndex);
			
			// Calculate the length of the 6 lines
			fileLines[searchIndex].location.length = (fileLines[searchIndex+5].location.offset +size(fileLines[searchIndex+5].content)) - fileLines[searchIndex].location.offset;
			
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
				nonDuplicates += (duplicateString : fileLines[searchIndex]);
				searchIndex += 1;
			}
			
			//println("Duplicatecount: <duplicateCount>");
			
		}
	}
	
	for(dup <- duplicates)
	{
		list[Duplicate] fileLns = allLines[dup.location.uri];
		
		//println(fileLns[dup.searchIndex].content);
		//println(dup.content);
		
		//println(nonDuplicates[getSixLines(fileLns, dup.searchIndex)]);
		original = nonDuplicates[getSixLines(fileLns, dup.searchIndex)];
		println(allLines[original.location.uri])[original.searchIndex].content;
		println(dup.location);
	}
	//print(duplicates)
	num procent = ((duplicateCount*6)/(totalSize))*100;
	println("Total line count: <totalSize>, <duplicateCount>(<procent>%) duplicate lines, Ranking: <getDuplicateRanking(procent)>");
	return duplicateCount;
}

public str getSixLines(list[Duplicate] lines, int startIndex)
{
	if(startIndex+5 < size(lines)){
		return "<lines[startIndex].content><lines[startIndex+1].content><lines[startIndex+2].content><lines[startIndex+3].content><lines[startIndex+4].content><lines[startIndex+5].content>";
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

public list[Duplicate] filterLines(loc file)
{
	fileLines = readFileLines(file);
	fileOffset = 0;
	sIndex = 0;
	list[Duplicate] filteredLines = [];
	
	for (s <- fileLines){ 
		if(!isWhiteSpace(s) && !isComment(s)){
			filteredLines += Duplicate(s,file(fileOffset,size(s),<0,0>,<0,0>),sIndex);
			sIndex = sIndex + 1;
		}
		fileOffset +=  1 + size(s);
		
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

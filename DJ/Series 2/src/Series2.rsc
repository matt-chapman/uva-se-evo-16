module Series2

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

data FileLine = FileLine(str content, loc location, int searchIndex);
data Duplicate = Duplicate(FileLine line, loc location, int length);

public map[str, list[FileLine]] allFiles = ();
public map[str, list[Duplicate]] dupClasses = ();

public loc project = |project://HelloWorld2/src/|;
public loc project1 = |project://hsqldb-2.3.1/hsqldb/|;
public loc project2 = |project://smallsql0.21_src/src/|;

set[loc] getProjectFiles(loc project) { 
   bool containsFile(loc d) = isFile(d) ? (d.extension == "java") : false;
   return find(project, containsFile);
}

public void analyze(loc proj)
{
	startTime = getMilliTime();
	filterProjectFiles(proj);
	getDuplicates();
	println("Analyzing took <getMilliTime() - startTime>ms");
}

public num getDuplicates()
{	
	list[Duplicate] duplicates = [];
	map[str, FileLine] nonDuplicates = ();
	
	num duplicateCount = 0;
	num totalSize = 0;
	
	for(file <- allFiles){
		fileLines = allFiles[file];
		int searchIndex = 0;
		
		fileLinesSize = size(fileLines);		
		totalSize += fileLinesSize;
		
		while(searchIndex < fileLinesSize-5)
		{			
			duplicateString = getSixLines(fileLines[searchIndex]);
			// Calculate the length of the 6 lines
			//fileLines[searchIndex].location.length = (fileLines[searchIndex+5].location.offset +size(fileLines[searchIndex+5].content)) - fileLines[searchIndex].location.offset;
			
			if(searchIndex < fileLinesSize && duplicateString != "" && (duplicateString in nonDuplicates))
			{ 
				if(duplicateString notin dupClasses)
				{
				 	dupClasses += (duplicateString : [Duplicate(fileLines[searchIndex],fileLines[searchIndex].location , 6)]);
				 	dupClasses[duplicateString] += Duplicate(nonDuplicates[duplicateString],nonDuplicates[duplicateString].location, 6);
				}
				else
				{
					if(Duplicate(fileLines[searchIndex],fileLines[searchIndex].location, 6) notin dupClasses[duplicateString])
					{
						dupClasses[duplicateString] += Duplicate(fileLines[searchIndex],fileLines[searchIndex].location, 6);
					}
					
				}
				//duplicates += Duplicate(fileLines[searchIndex], 6);

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
	
	//for(dup <- duplicates)
	//{
	//	list[Duplicate] fileLns = allLines[dup.location.uri];
	//	
	//	//println(fileLns[dup.searchIndex].content);
	//	//println(dup.content);
	//	
	//	//println(nonDuplicates[getSixLines(fileLns, dup.searchIndex)]);
	//	original = nonDuplicates[getSixLines(fileLns, dup.searchIndex)];
	//	println(allLines[original.location.uri])[original.searchIndex].content;
	//	println(dup.location);
	//}
	//print(duplicates)
	growDuplicates();
	setDuplicateLocations();
	
	for(dClass <- dupClasses)
	{
		dSize = size(dupClasses[dClass]);
		println("Classcount <dSize>");
		//if(dSize >= 3)
		//{
			for(dLoc <- dupClasses[dClass]) println("<dLoc.location> lenght:<dLoc.length>");
		//}
	}
	num procent = ((duplicateCount*6)/(totalSize))*100;
	println("Total line count: <totalSize>, <duplicateCount>(<procent>%) duplicate lines, in <size(dupClasses)> Clone Classes");
	return duplicateCount;
}

public void growDuplicates()
{
	bool growing = false;
	int lenght = 6;
	while(true){
		for(dClass <- dupClasses)
		{
			list[str] nextLines = [];
			for(dup <- dupClasses[dClass])
			{
				nextLines += getNextLine(dup);
			}
			int index = 0;
			while(index <= size(nextLines)-1)
			{
				list[str] temp = nextLines;
				str tempComp = temp[index];
				temp = delete(temp, index);
				if(tempComp != "" && tempComp in temp)
				{
					dupClasses[dClass][index].length += 1;
					growing = true;
				}
				index += 1;
			}
		}
		println("Try again! <lenght> <growing>");
		if(!growing) break;
		lenght += 1;
		growing = false;
	}
}

public void filterDuplicates()
{
	
	return;
}

public tuple[bool, bool] growPossible(Duplicate dup1, Duplicate dup2)
{
	if(dup1.line == dup2.line) return <false,false>;
	
	dup1Lines = allFiles[dup1.line.location.uri];
	dup2Lines = allFiles[dup2.line.location.uri];
	
	//Check if the end of the file is reached
	if(hasNextLine(dup1) && hasNextLine(dup2))
	{		
		if(dup1.length == dup2.length)
		{		
			if(dup1Lines[dup1.line.searchIndex+dup1.length] == dup2Lines[dup2.line.searchIndex+dup2.length]) 
				return <true,true>;
		}
		else if (dup1.length > dup2.length)
		{
			//dup1 is larger - so check if dup2 can grow
			if(dup1Lines[dup1.line.searchIndex+dup1.length-1] == dup2Lines[dup2.line.searchIndex+dup2.length])
				return <false,true>;
		}
		else if (dup1.length < dup2.length-1)
		{
			//dup2 is larger - so check if dup1 can grow
			if(dup1Lines[dup1.line.searchIndex+dup1.length] == dup2Lines[dup2.line.searchIndex+dup2.length-1])
				return <true,false>;
		}
	}
	return <false,false>;
}

public bool hasNextLine(Duplicate dup)
{
	list[FileLine] lines = allFiles[dup.line.location.uri];
	if(size(lines) <= dup.line.searchIndex + dup.length) return false;
	return true;
}

public str getNextLine(Duplicate dup)
{
	if(!hasNextLine(dup)) return "";
	else
	{
		return allFiles[dup.line.location.uri][dup.line.searchIndex + dup.length].content;
	}
}

public void setDuplicateLocations()
{
	for(dClass <- dupClasses)
	{
		int index = 0;
		for(dup <- dupClasses[dClass])
		{
			fileLines = allFiles[dup.line.location.uri];
			lastLine = fileLines[dup.line.searchIndex+(dup.length-1)];
			dupClasses[dClass][index].location.length = (lastLine.location.offset +size(lastLine.content)) - dup.line.location.offset;
			index = index + 1;
		}
	}
	return;
}


public str getSixLines(FileLine line)
{
	list[FileLine] lines = allFiles[line.location.uri];
	sIndex = line.searchIndex;
	
	if(sIndex+5 < size(lines)){
		return "<lines[sIndex].content><lines[sIndex+1].content><lines[sIndex+2].content><lines[sIndex+3].content><lines[sIndex+4].content><lines[sIndex+5].content>";
	}
	else return "";
}

public void filterProjectFiles(loc projectName)
{
	allProjectFiles = getProjectFiles(projectName);
	for(file <- allProjectFiles)
	{	
		allFiles += (file.uri : filterLines(file));
	}
	return;
}

public list[FileLine] filterLines(loc file)
{
	fileLines = readFileLines(file);
	fileOffset = 0;
	sIndex = 0;
	list[FileLine] filteredLines = [];
	
	for (s <- fileLines){ 
		if(!isWhiteSpace(s) && !isComment(s)){
			filteredLines += FileLine(s,file(fileOffset,size(s),<0,0>,<0,0>),sIndex);
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


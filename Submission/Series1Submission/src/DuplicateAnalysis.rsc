module DuplicateAnalysis

import util::Resources;

import util::FileSystem;
import List;
import Set;
import String;
import IO;
import Map;
import util::Benchmark;

private set[loc] getProjectfiles(loc project) { 
   bool containsFile(loc d) = isFile(d) ? (d.extension == "java") : false;
   return find(project, containsFile);
}

public tuple[num total,num dup, num com] countDuplicatesAndLines(loc project)
{	
	set[loc] allFiles = getProjectfiles(project);

	list[tuple[str string, loc location]] duplicates = [];
	map[str, loc] nonDuplicates = ();
	
	num duplicateCount = 0;
	num totalSize = 0;
	num commentCount = 0;
	
	
	for(file <- allFiles){
	
		tuple[num comments, list[tuple[str string, loc location]] fLines] lines = filterLines(file);
		
		commentCount += lines.comments;
		fileLines = lines.fLines;
		
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
				//duplicates += fileLines[searchIndex];
							
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
		}
	}
	return <totalSize,duplicateCount,commentCount>;
}


private str getSixLines(list[tuple[str string,loc location]] lines, int startIndex)
{
	if(startIndex+5 < size(lines)){
		return "<lines[startIndex].string><lines[startIndex+1].string><lines[startIndex+2].string><lines[startIndex+3].string><lines[startIndex+4].string><lines[startIndex+5].string>";
	}
	else return "";
}

public num getDuplicatePercentage(tuple[num total, num dup, num com] metrics)
{
	percentDuplicated = ((metrics.dup*6)/(metrics.total))*100;
	return percentDuplicated;
}

public int getDuplicateRanking(num percentage)
{
	if(percentage <= 3) return 4;
	else if(percentage <= 5) return 3;
	else if(percentage <= 10) return 2;
	else if(percentage <= 20) return 1;
	return 0;
}

public int makeSizeRanking(num lines)
{
	num kloc = lines/1000;
	if(kloc <= 66) return 4;
	else if(kloc <= 246) return 3;
	else if(kloc <= 665) return 2;
	else if(kloc <= 1310) return 1;
	return 0;
}

public tuple[num, list[tuple[str,loc]]] filterLines(loc file)
{
	fileLines = readFileLines(file);
	fileOffset = 0;
	
	commentCount = 0;
	
	list[tuple[str,loc]] filteredLines = [];
	
	for (s <- fileLines){ 
		if(!isWhiteSpace(s)){
			if(!isComment(s)){
				filteredLines += <s,file(fileOffset,size(s),<0,0>,<0,0>)>;
			}
			else
			{
				commentCount += 1;
			}
		}
		fileOffset +=  2 + size(s);
	}
	return <commentCount, filteredLines>;
}

private bool isWhiteSpace(str s){
	if(/^[ \t\r\n]*$/ := s) return true;
	return false;
}

private bool isComment(str s){
	if(/((\s|\/*)(\/\*|^(\s+\*))|^(\s*\/*\/))/ := s) return true;
	return false;
}

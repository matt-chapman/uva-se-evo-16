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
import DateTime;
import util::Math;
import util::Benchmark;

data FileLine = FileLine(str content, loc location, int searchIndex);
data Duplicate = Duplicate(FileLine line, loc location, int length, bool subsumed);

data Metrics = Metrics(Duplicate biggestClone, num lineCount, num numberOfClones, str biggestCloneClass, num duplicateLines, num subsumedClones, num subsumedLines);

public map[str, list[FileLine]] allFiles = ();
public map[str, list[Duplicate]] dupClasses = ();
public map[str, list[Duplicate]] dupClassesPreFilter = ();
public map[str, list[Duplicate]] fileDups = ();

public Metrics projectMetrics = Metrics(Duplicate(FileLine("", toLocation(""), 0),toLocation(""),0,false), 0,0, "",0,0,0);



public loc project = |project://HelloWorld2/src/|;
public loc project1 = |project://hsqldb-2.3.1/hsqldb/|;
public loc project2 = |project://smallsql0.21_src/src/|;

public loc resultFile = |project://Series2-MC/bin/|;

public str selectedProject;
public loc projectToProcess = project1;
public loc processedProject = toLocation("");

set[loc] getProjectFiles(loc project) { 
   bool containsFile(loc d) = isFile(d) ? (d.extension == "java") : false;
   return find(project, containsFile);
}

public void analyze(loc proj)
{
	allFiles = ();
	dupClasses = ();
	fileDups = ();
	processedProject = proj;
	//projectToProcess = proj;
	startTime = getMilliTime();
	println("Start filtering files...");
	filterProjectFiles(proj);
	getDuplicates();
	projectMetrics = calculateMetrics();
	writeResultsToFile();
	println("Analyzing took <getMilliTime() - startTime>ms");
}

public Metrics calculateMetrics()
{
	Metrics metr = Metrics(Duplicate(FileLine("", toLocation(""), 0),toLocation(""),0,false), 0,0, "", 0,0,0);
	for(dClass <- dupClasses)
	{
		if(metr.biggestCloneClass == "" || size(dupClasses[dClass]) > size(dupClasses[metr.biggestCloneClass])) metr.biggestCloneClass = dClass;
		for(dup <- dupClasses[dClass])
		{	
			metr.duplicateLines += dup.length;
			metr.numberOfClones += 1;
			if(dup.length > metr.biggestClone.length) metr.biggestClone = dup;
			if(dup.subsumed)
			{
				metr.subsumedClones += 1;
				metr.subsumedLines += dup.length;
			}
		}
	}
	for(file <-allFiles) metr.lineCount += size(allFiles[file]);
	return metr;
}

public Metrics getClassMetrics(str classKey)
{
	Metrics classMetrics = Metrics(Duplicate(FileLine("", toLocation(""), 0),toLocation(""),0,false), 0,0, "",0,0,0);
	list[Duplicate] classDuplicates = dupClasses[classKey];
	for (dup <- classDuplicates)
	{
		classMetrics.duplicateLines += dup.length;	
		classMetrics.lineCount = dup.length;
		classMetrics.numberOfClones += 1;
	}
	
	return classMetrics;
}

public num getDuplicates()
{	
	println("Start Analyzing...");
	list[Duplicate] duplicates = [];
	map[str, FileLine] nonDuplicates = ();
	
	dupClasses = ();
	
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
			
			if(searchIndex < fileLinesSize && duplicateString != "" && (duplicateString in nonDuplicates))
			{ 
				if(duplicateString notin dupClasses)
				{
				 	dupClasses += (duplicateString : [Duplicate(fileLines[searchIndex],fileLines[searchIndex].location , 6, false)]);
				 	dupClasses[duplicateString] += Duplicate(nonDuplicates[duplicateString],nonDuplicates[duplicateString].location, 6, false);
				}
				else
				{
					if(Duplicate(fileLines[searchIndex],fileLines[searchIndex].location, 6, false) notin dupClasses[duplicateString])
					{
						dupClasses[duplicateString] += Duplicate(fileLines[searchIndex],fileLines[searchIndex].location, 6, false);
					}
					
				}		
				duplicateCount += 1;
				//Skip next 5 lines
				searchIndex += 5;
			}
			else{				
				nonDuplicates += (duplicateString : fileLines[searchIndex]);
				searchIndex += 1;
			}
			
		}
	}
	println("Grow First duplicates....");
	growFirstDups();
	println("Start Growing....");
	growDuplicates();
	println("Growing ended");
	setDuplicateLocations();
	
	int lastFilter = 0;
	while(true) 
	{
		int thisFilter = filterDuplicates();
		if(lastFilter == thisFilter) break;
		lastFilter = thisFilter;
	}
	
	
	num procent = ((duplicateCount*6)/(totalSize))*100;
	println("Total line count: <totalSize>, <duplicateCount>(<procent>%) duplicate lines, in <size(dupClasses)> Clone Classes");
	return duplicateCount;
}

//This grows the first duplicate for each file and filters out all duplicates contained in that duplicate.
//This gives a performance boost for duplicate files and prevents growing duplicates which are discarded in the next step.
public void growFirstDups()
{
	map[str, list[Duplicate]] fDups = generateFileDups();
	map[str, Duplicate] firstFDups = ();
	
	//Get the first duplicate for each file
	for(file <- fDups)
	{
		temp = sort(fDups[file], bool(Duplicate a, Duplicate b){return a.line.location.offset < b.line.location.offset;});
		firstFDups[file] = temp[0];
	}
	int length = 6;
	
	//firstFDups only contain the first clone class of each file.
	for(file <- firstFDups)
	{
		str classStr = getSixLines(firstFDups[file].line);
		
		//This loop will compare the next line of the duplicates in the same clone class. If they are equal the duplicates can grow by one.
		//This is repeated until all duplicates stopped growing.
		while(true){
			growing = false;
			list[str] nextLines = [];
			//Get a list of the next lines for each duplicate within a clone class.
			for(dup <- dupClasses[classStr]) if(dup.length + 1 >= length) nextLines += getNextLine(dup);
			
			int index = 0;
			//Compare the next lines, if the next line of two duplicates are equal, both duplicates can grow by one.
			while(index <= size(nextLines)-1)
			{
				// get a temporary list of all nextlines
				list[str] tempNextLines = nextLines;
				// get the nextline which will be compared to all others
				str currentNextLine = tempNextLines[index];
				// remove the nextline which will be compared from the list
				tempNextLines = delete(tempNextLines, index);
				// check if the nextline is still present in the list, this would mean the nextline of atleast two duplicates are equal and so the duplicate can grow.
				if(currentNextLine != "" && currentNextLine in tempNextLines)
				{
					dupClasses[classStr][index].length += 1;
					growing = true;
				}
				index += 1;
			}
			// If all duplicates in the clone class stopped growing break out the while loop
			if(!growing) break;
		}
	}
	// Filter out duplicates contained within other duplicates
	filterDuplicates();
	return;	
}

public void growDuplicates()
{
	bool growing = false;
	int length = 6;
	int grow = 0;
	while(true){
		for(dClass <- dupClasses)
		{
			list[str] nextLines = [];
			for(dup <- dupClasses[dClass]) if(dup.length + 1 >= length) nextLines += getNextLine(dup);
			
			// go on to the next clone class if there are no next lines
			if(size(nextLines) == 0) continue;
			int index = 0;
			while(index <= size(nextLines)-1)
			{
				list[str] temp = nextLines;
				str tempComp = getNextLine(dupClasses[dClass][index]);
				temp = delete(temp, index);
				if(tempComp != "" && tempComp in temp)
				{
					dupClasses[dClass][index].length += 1;
					growing = true;
					grow += 1;
				}
				index += 1;
			}
		}
		println("Still growing! Growing <grow> clones with length <length>");
		if(!growing) break;
		length += 1;
		grow = 0;
		growing = false;
	}
}

public map[str, list[Duplicate]] generateFileDups()
{
	if(processedProject != projectToProcess) analyze(projectToProcess);
	map[str, list[Duplicate]] fDups = ();
	for(dClass <- dupClasses)
	{
			for(dLoc <- dupClasses[dClass])
			{
				if(dLoc.location.uri notin fDups)
				{
					fDups[dLoc.location.uri] = [dLoc];
				}
				else
				{
					fDups[dLoc.location.uri] += dLoc;
				}
			}
	}
	return fDups;
}

public map[str, list[Duplicate]] generateFileDups(Duplicate dup)
{
	map[str, list[Duplicate]] fDups = ();
	str key = getSixLines(dup.line);
	for(dLoc <- dupClasses[key])
	{
		if(dLoc.location.uri notin fDups)
		{
			fDups[dLoc.location.uri] = [dLoc];
		}
		else
		{
			fDups[dLoc.location.uri] += dLoc;
		}
	}	
	return fDups;
}

public int filterDuplicates()
{
	fileDups = generateFileDups();
	int count = 0;
	for(file <- fileDups)
	{
			fileDups[file] = sort(fileDups[file], bool(Duplicate a, Duplicate b){ return a.location.offset < b.location.offset; });
			int index = 0;
			int containedIndex = index;
			while(index+1 < size(fileDups[file]) && containedIndex+1 < size(fileDups[file]))
			{
				containedDuplicate = false;
				// Calculate the end of the duplicate
				int endDupli = fileDups[file][index].line.searchIndex + fileDups[file][index].length;
				
				// Calculate the end of the next duplicate
				Duplicate nextDup = fileDups[file][containedIndex+1];
				int endNext = nextDup.line.searchIndex + nextDup.length;
				
				// If the next duplicate end before the current duplicate ends, the next duplicate is contained in the current duplicate
				if(endNext <= endDupli && nextDup.line.searchIndex > fileDups[file][index].line.searchIndex)
				{
					setSubsumed(nextDup);
					containedDuplicate = true; 
					containedIndex += 1; 
					// Remove duplicate
					count += 1;
				}
				// If there was no duplicate contained: 
				if(!containedDuplicate) 
				{
					if(index < containedIndex) index = containedIndex;
					else {index += 1; containedIndex += 1;}
				}
			} 
			
	}
	for(dClass <- dupClasses)
	{		
		bool classIsSubsumed = true;
		for(dup <- dupClasses[dClass]) if(!dup.subsumed) classIsSubsumed = false;
		//println("Class subsumed <classIsSubsumed>");
		if(classIsSubsumed)
		{
			//println("Delete Class");
			for(dup <- dupClasses[dClass]) 
			{
				removeDuplicate(dup);
			}
		}
	}
	println("Found <count> duplicate duplicates");
	return count;
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

// Removes a duplicate from the clone classes
public bool removeDuplicate(Duplicate dup)
{
	str key = getSixLines(dup.line);
	list[Duplicate] dupClass = dupClasses[key];
	int index = 0;
	while(index < size(dupClass))
	{
		if(dup.location == dupClass[index].location)
		{
			dupClasses[key] = delete(dupClasses[key], index);
			if(size(dupClasses[key]) == 0) dupClasses = delete(dupClasses, key);
			return true;
		}
		index += 1;
	}
	return false;	
}

// Set the length of each clone
public void setDuplicateLocations()
{
	for(dClass <- dupClasses)
	{
		int index = 0;
		for(dup <- dupClasses[dClass])
		{
			//println("<dup.location> <dup.length>");
			fileLines = allFiles[dup.line.location.uri];
			lastLine = fileLines[dup.line.searchIndex+(dup.length-1)];
			dupClasses[dClass][index].location.length = (lastLine.location.offset +size(lastLine.content)) - dup.line.location.offset;
			index = index + 1;
		}
	}
	return;
}

// Get sixlines, this is also the key of each clone class
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
	allFiles = ();
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

public void setSubsumed(Duplicate dup)
{
	str key = getSixLines(dup.line);
	list[Duplicate] dupClass = dupClasses[key];
	int index = 0;
	while(index < size(dupClass))
	{
		if(dup.location == dupClass[index].location)
		{
			dupClasses[key][index].subsumed = true;
			return;
		}
		index += 1;
	}
	return;	
}

public void writeResultsToFile()
{
	fileLoc = resultFile + "Results-<printDate(now(), "MMdd-HHmmss")>";
	
	num percentage = 0;
	if(projectMetrics.lineCount > 0)
	{
		percentage = projectMetrics.duplicateLines / projectMetrics.lineCount * 100.00;
	}		
	
	str fileStr = "Results for <processedProject.authority>
			'The project has <projectMetrics.lineCount> lines for codes containting <projectMetrics.numberOfClones> clones this is <round(percentage,0.01)>% of the total project.
			'The biggest clone is <projectMetrics.biggestClone.length> LOC long.
			'There are <size(dupClasses)> clone classes. The biggest class contains <size(dupClasses[projectMetrics.biggestCloneClass])> clones.\n\n";
	
	int i = 1;
	for(dClass <- dupClasses)
	{
		fileStr += "Clone Class <i>\n";
		for(dup <- dupClasses[dClass])
		{
			fileStr += "	<dup.location>\n";
		}
		fileStr += "\n";
		i += 1;
	}
	
	writeFile(fileLoc, fileStr);
	return;
}


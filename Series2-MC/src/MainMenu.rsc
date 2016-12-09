module MainMenu

import HelloVis;
import Series2;

import vis::Figure;
import vis::Render;

//temp variables for the combobox
public str selectedProject;
public loc projectToProcess = project2;

//the projects we want to work on
public loc project = |project://HelloWorld2/src/|;
public loc project1 = |project://hsqldb-2.3.1/hsqldb/|;
public loc project2 = |project://smallsql0.21_src/src/|;

//callback for combobox
public void modifySelectedProject()
{
	if (selectedProject == "smallsql")
		projectToProcess = project2;
	else if (selectedProject == "hsqldb")
		projectToProcess = project1;
}

//generate the main menu
public void mainMenu()
{
	//create hcat containing combobox and button
	menu = getMainMenu();

	//render the above hcat
	render("Main Menu", menu);
}





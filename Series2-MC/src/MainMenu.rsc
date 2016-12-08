module MainMenu

import Series2;
import HelloVis;

import vis::Figure;
import vis::Render;

public str selectedProject;
public loc projectToProcess;

public loc project = |project://HelloWorld2/src/|;
public loc project1 = |project://hsqldb-2.3.1/hsqldb/|;
public loc project2 = |project://smallsql0.21_src/src/|;

public void modifySelectedProject()
{
	if (selectedProject == "smallsql")
		projectToProcess = project2;
	else if (selectedProject == "hsqldb")
		projectToProcess = project1;

}

public Figure mainMenu()
{
	menu = hcat([
				combo(["smallsql", "hsqldb"], void(str s){ selectedProject = s; modifySelectedProject(); }, hsize(200), resizable(false, false)),
				button("Analyse", void(){analyze(projectToProcess); runTest();}, hsize(100), resizable(false, false))
				], resizable(false, false));

	//render("Main Menu", menu);
}
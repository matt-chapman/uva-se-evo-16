module demo::basic::Quine

import IO;
import String;

public void quine(){
  println(program); 
  println("\"" + escape(program, ("\"" : "\\\"", "\\" : "\\\\")) + "\";"); 
}

str program = 
"module demo::basic::Quine

import IO;
import String;

public void quine(){
  println(program);
  println(\"\\\"\" + escape(program, (\"\\\"\" : \"\\\\\\\"\", \"\\\\\" : \"\\\\\\\\\")) + \"\\\";\");
}

str program ="; 
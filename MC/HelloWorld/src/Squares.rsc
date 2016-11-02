module demo::basic::Squares

import IO;                                   

// Print a table of squares

public void squares(int N){
  println("Table of squares from 1 to <N>"); 
  for(int I <- [1 .. N + 1])
      println("<I> squared = <I * I>");      
}

// a solution with a multi line string template:

public str squaresTemplate(int N) 
  = "Table of squares from 1 to <N>
    '<for (int I <- [1 .. N + 1]) {>
    '  <I> squared = <I * I><}>
    ";
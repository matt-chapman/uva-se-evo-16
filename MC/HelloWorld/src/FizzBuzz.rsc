module demo::basic::FizzBuzz

import IO;

public void fizzbuzz() {
   for(int n <- [1 .. 101]){
      fb = ((n % 3 == 0) ? "Fizz" : "") + ((n % 5 == 0) ? "Buzz" : "");
      println((fb == "") ?"<n>" : fb);
   }
}

public void fizzbuzz2() {
  for (n <- [1..101]) 
    switch(<n % 3 == 0, n % 5 == 0>) {
      case <true,true>  : println("FizzBuzz");
      case <true,false> : println("Fizz");
      case <false,true> : println("Buzz");
      default: println(n);
    }
}

public void fizzbuzz3() {
  for (n <- [1..101]) {
    if (n % 3 == 0) print("Fizz");
    if (n % 5 == 0) print("Buzz");
    else if (n % 3 != 0) print(n);
    println("");
  }
}
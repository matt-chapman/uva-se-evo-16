public class HelloWorld2 {
	
    //This is a comment
    public static void main(String[] argv)
    {
    	int x = 2;
    	
		/* This is a huge comment
		 * LOL
		 */
		String hello = new String("Hello World!");
		
		//This is another comment
		System.out.println(hello);
		
		if (x == 2){
			System.out.println("x == 2!");
		}
		else
			System.out.println("x != 2!");
		
		switch(x){
		case 1: System.out.println("x == 1!");
		case 2: System.out.println("x == 2!");
		case 3: System.out.println("x == 3!");
		}
		
		for (int i = 0; i<10; i++)
		{
			System.out.println(hello);
		}
	}
    
	//COMMENTS EVERYWHERE

}
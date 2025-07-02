// Compiled and run using vivado
// Copying classes

// simple class copy of data members
class first;
    int data = 12;
endclass

module dff_tb();
    first f1;
    first p1;
    
    initial begin
        f1 = new ();
        $display("f1 data: %0d", f1.data);
        f1.data = 20;
        p1 = new f1;
        $display("f1 data: %0d", f1.data);
        $display("p1 copied data: %0d", p1.data);
        p1.data = 34;
        $display("p1 new data: %0d", p1.data);
        $display("f1 data: %0d", f1.data);
    end
endmodule

// Copying strategy between classes, same outcome as top but with custom copy method
class first;
    int data = 12;
    
    function first copy();
        copy = new();
        copy.data = this.data;
    endfunction
endclass

module dff_tb();
    first f1, f2;
    
    initial begin
        f1 = new();
        f2 = new();
        $display("f1 data: %0d", f1.data);
        $display("f2 data: %0d", f2.data);
        
        f1.data = 25;
        f2 = f1.copy();
        $display("f1 data: %0d", f1.data);
        $display("f2 data: %0d", f2.data);
        
        f2.data = 30;
        $display("f1 data: %0d", f1.data);
        $display("f2 data: %0d", f2.data);
    end
endmodule

// Implementing Shallow Copy(class within a class): class copy has independent data members, but copied class points to original class
class first;
    int data = 12;
endclass

class second;
    int data_s = 10;
    first f1;
    
    function new();
        f1 = new();
    endfunction
endclass

module dff_tb();
    //s1 is class with a class
    //s2 is a copy of s1
    second s1, s2;
    
    initial begin
        s1 = new();
        $display("s1.data_s: %0d, s1.f1.data= %0d", s1.data_s, s1.f1.data);
        
        //Change s1 data before copying
        s1.data_s = 70;
        s2 = new s1;
        $display("s1.data_s: %0d, s1.f1.data= %0d", s1.data_s, s1.f1.data);
        $display("s2.data_s: %0d, s2.f1.data= %0d", s2.data_s, s2.f1.data);
        
        //Change s2 data
        //s1.data_s should retain value
        s2.data_s = 20;
        $display("s1.data_s: %0d, s1.f1.data= %0d", s1.data_s, s1.f1.data);
        $display("s2.data_s: %0d, s2.f1.data= %0d", s2.data_s, s2.f1.data);
        
        //Change the first class data via s2
        //s1.f1.data and s2.f2.data should both change
        s2.f1.data = 30;
        $display("s1.data_s: %0d, s1.f1.data= %0d", s1.data_s, s1.f1.data);
        $display("s2.data_s: %0d, s2.f1.data= %0d", s2.data_s, s2.f1.data);    
    end
endmodule

// Implementing Deep Copy (class within a class): Copied class has independent data members and class
class first;
    int data = 12;
    
    function first copy();
        copy = new();
        copy.data = this.data;
    endfunction
endclass

class second;
    int data_s = 10;
    first f1;
    
    function new();
        f1 = new();
    endfunction
    
    function second copy();
        copy = new();
        copy.data_s = this.data_s;
        copy.f1 = this.f1.copy;
    endfunction
endclass

module dff_tb();
    //s1 is class with a class
    //s2 is a copy of s1
    second s1, s2;
    
    initial begin
        s1 = new();
        s2 = new();
        $display("s1.data_s: %0d, s1.f1.data= %0d", s1.data_s, s1.f1.data);
        $display("s1.data_s: %0d, s1.f1.data= %0d", s1.data_s, s1.f1.data);
        
        //Change s1 data before copying
        //both s1.data_s and s2.data_s have the same value
        s1.data_s = 70;
        s2 = s1.copy;
        $display("s1.data_s: %0d, s1.f1.data= %0d", s1.data_s, s1.f1.data);
        $display("s2.data_s: %0d, s2.f1.data= %0d", s2.data_s, s2.f1.data);
        
        //Change s2 data
        //only s2.data_s changes
        s2.data_s = 20;
        $display("s1.data_s: %0d, s1.f1.data= %0d", s1.data_s, s1.f1.data);
        $display("s2.data_s: %0d, s2.f1.data= %0d", s2.data_s, s2.f1.data);
        
        //Change the first class data via s2
        //Only s2's copied class data(s2.f1.data) changes
        s2.f1.data = 30;
        $display("s1.data_s: %0d, s1.f1.data= %0d", s1.data_s, s1.f1.data);
        $display("s2.data_s: %0d, s2.f1.data= %0d", s2.data_s, s2.f1.data);
        
        //Change the first class data via s1
        //Only s1's class data(s2.f1.data) changes
        s1.f1.data = 35;
        $display("s1.data_s: %0d, s1.f1.data= %0d", s1.data_s, s1.f1.data);
        $display("s2.data_s: %0d, s2.f1.data= %0d", s2.data_s, s2.f1.data);    
    end
endmodule
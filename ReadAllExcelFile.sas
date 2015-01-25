option ENCODING="UTF-8";
libname output 'D:\phib';

%let rootPath = D:\phib\cus\;

filename DIRLIST pipe "dir &rootPath*.xlsx"; 

 
proc options option=encoding; run;

data output.dirlist ;                                               
infile dirlist lrecl=200 truncover;                          
input line $200.;                                            
if input(substr(line,1,10), ?? mmddyy10.) = . then delete;   
length file_name $ 100;                                      
file_name="&rootPath"||scan(line,-1," ");                    
keep file_name;
call symput ('num_files',_n_); 
run; 

proc printto log="d:\tmp.txt" NEW; run;
options mprint symbolgen;
%macro fileread;
	%do j=1 %to 5;
		data _null_; 
			set output.dirlist; 
			if _n_=&j then
			do;
				call symput ('filein',file_name); 
				call symput('read',left(trim(file_name)));
				call symput('dset',"output."||left(scan(scan(file_name,4,'\'),1,'.')));
			end;
		run;
	 	
		PROC IMPORT DATAFILE= "&read"
					OUT=&dset
		            DBMS=xlsx REPLACE;
		     GETNAMES=YES;
		RUN; 
	%end;                                                        
%mend fileread; 
%fileread; 
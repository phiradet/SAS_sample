/******************************************************************************  
AUTHOR                  : PBangcharoensap  
  
CREATE DATE             : 08/21/2013  (MM/DD/YYYY)
  
PURPOSE                 : Convert all ACCESS file (.mdb) in the given folder to SAS data table 
  
MODULE NAME             : Data Preparation  
  
INPUT PARAMS            : 	(1) src_data_folder: folder that .mdb files exists
  
OUTPUT PARAMS           :
  
MODIFICATION HISTORY (INCLUDES QA/PERFORMANCE TUNING CHANGES) :  
  
VER NO.     DATE           	NAME					LOG  
-------     ------         	-------                 -----  
v1.0        08/21/2013    	PBangcharoensap         Initial Version  
v1.1        08/21/2013    	PBangcharoensap         Reduce data step iteration  	
**********************************************************************************/  
*libname TLT_B 'D:\phib';

%LET src_data_folder = D:\phib;

/* Listing all .mdb file in the given folder */
filename DIRLIST pipe "dir &src_data_folder\*.mdb";

data TLT_B.mdb_list ;                                               
	infile dirlist lrecl=200 truncover;                          
	input line $200.;                                            
	if input(substr(line,1,10), ?? mmddyy10.) = . then delete;   
	length file_name $ 100;                                      
	file_path="&src_data_folder\"||scan(line,-1," ");
	file_name=scan(line,-1," ");
run;
 /*==========================================*/

/* Get number of access file in folder */
data _null_;
	set TLT_B.mdb_list nobs=n;
	call symputx('num_files',n);
	stop;
run;
%put num of tables = &num_files;
/*==========================================*/

/* Import file */
%macro import_file;		
	%do i=1 %to &num_files;
		data _null_;
			set TLT_B.mdb_list(firstobs=&i);
			call symputx('filename',file_name);
			call symputx('filepath',file_path);
			stop;
		run;
		
		/* get table schema */
		proc sql; 
			connect to odbc (noprompt="DRIVER=Driver do Microsoft Access (*.mdb);DBQ=&filepath;"); 
			create table TLT_B.SCHEMA as 
			select TABLE_NAME from connection to odbc(ODBC::SQLTables)
			where TABLE_TYPE='TABLE'; 
		quit;

		data _null_;
			set TLT_B.SCHEMA nobs=n;
			call symputx('num_tbls',n);
			stop;
		run;
		
		/* import file */
		%do j =1 %to &num_tbls;
			data _null_;
				set TLT_B.SCHEMA(firstobs=&j);;
				call symputx('tbl_name',TABLE_NAME);
				stop;
			run;

			%put Import &tbl_name[&j|&num_tbls] from &filename[&i|&num_files];

			proc sql;
				connect to ODBC (noprompt="DRIVER=Driver do Microsoft Access (*.mdb);DBQ=&filepath;");
				create table TLT_B.&tbl_name(compress=yes) as select * from connection to ODBC
				(select * from &tbl_name);
				disconnect from odbc;
			quit;
		%end;
	%end;
%mend import_file;

%import_file;
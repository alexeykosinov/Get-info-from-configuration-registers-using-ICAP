ECHO off

SET core_name_0=vio
SET core_name_1=icon

CD cores

coregen -p coregen.cgp -b %core_name_0%.xco
coregen -p coregen.cgp -b %core_name_1%.xco

RMDIR /S /Q xlnx_auto_0_xdb
RMDIR /S /Q tmp
RMDIR /S /Q _xmsgs
RMDIR /S /Q %core_name_0%.constraints
RMDIR /S /Q %core_name_1%.constraints

ERASE coregen.cgc
ERASE *.gise
ERASE *.xise
ERASE *.txt
ERASE *.tcl
ERASE *.xise
ERASE *.vho
ERASE *.xdc
ERASE *.ucf
ERASE *.ncf
ERASE *.cdc
ERASE summary.log

CD ..
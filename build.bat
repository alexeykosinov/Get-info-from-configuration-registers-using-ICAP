ECHO off
CLS
SET entity=sysinfo_top
SET part=xc6vlx240t-1-ff1156

ECHO Removing results from previous run
RMDIR /S /Q results
RMDIR /S /Q xst

MKDIR results

CD results

ECHO Synthesizing design
xst -intstyle xflow -ifn ..\args\xst.scr
ECHO Synthesizing design done (see report)


RMDIR /S /Q _xmsgs
IF NOT EXIST %entity%.lso GOTO nolso
	ERASE %entity%.lso
  
:nolso
IF NOT EXIST *.xrpt GOTO noxrp
	ERASE *.xrpt
  
:noxrp
IF NOT EXIST %entity%.ngc GOTO nongc
	MOVE /Y %entity%.ngc results\%entity%.ngc
  
:nongc
IF NOT EXIST *.srp GOTO nosrp
	MOVE /Y *.srp results\xst_report.srp

:nosrp
CD results

ngdbuild -intstyle silent -dd _ngo -sd ..\cores -nt timestamp -uc ..\top_sysinfo.ucf -p %part% %entity%.ngc 
map -intstyle silent -f ..\args\map.scr %entity%.ngd -detail -o mapped.ncd mapped.pcf
par -intstyle silent -f ..\args\par.scr mapped.ncd routed mapped.pcf
trce -intstyle silent -v 3 -s 2 -n 3 -fastpaths -u 16 routed.ncd mapped.pcf
bitgen -f ..\args\bitgen.scr routed.ncd routed mapped.pcf

ECHO Cleaning up the results directory
RMDIR /S /Q xlnx_auto_0_xdb
RMDIR /S /Q _xmsgs
IF NOT EXIST netlist.lst GOTO nolst
  ERASE netlist.lst
  
:nolst
IF NOT EXIST par_usage_statistics.html GOTO nopus
  ERASE par_usage_statistics.html
:nopus

IF NOT EXIST usage_statistics_webtalk.html GOTO nousw
  ERASE usage_statistics_webtalk.html
:nousw

CD ..

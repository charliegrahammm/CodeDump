PAUSE  
attrib -h -r -s %windir%\system32\catroot2  
attrib -h -r -s %windir%\system32\catroot2*.*  
net stop wuauserv 
net stop CryptSvc  
net stop BITS  
ren %windir%\system32\catroot2 catroot2.old  
ren %windir%\SoftwareDistribution SoftwareDistribution.old  
ren "%ALLUSERSPROFILE%\application dataMicrosoftNetworkdownloader" downloader.old  
net Start BITS  
net start CryptSvc  
net start wuauserv  
echo Windows Update should now work properly.
PAUSE
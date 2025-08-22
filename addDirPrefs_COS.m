function addDirPrefs_COS

groupName = 'cosProject';

if ispref(groupName,'dirPref')
    rmpref(groupName,'dirPref');
end

switch getenv('COMPUTERNAME')
    case 'MU00011697' %DS OFFICE LINUX
        %dirPref.rootDir = '/mnt/dshi0006_market/Massive/COSproject/';
        dirPref.rootDir = '/home/daisuke/tmp/COSproject/';
        dirPref.rawDir = '/mnt/hctsa-market/';
    case '' %MASSIVE
        dirPref.rootDir = '/fs03/fs11/Daisuke/tmpData/COSproject/';
        dirPref.rawDir ='';%to be defined
end
addpref(groupName,'dirPref',dirPref);

disp(dirPref)

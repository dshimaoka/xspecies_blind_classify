function addDirPrefs_COS

groupName = 'cosProject';

if ispref(groupName,'dirPref')
    rmpref(groupName,'dirPref');
end
switch getenv('COMPUTERNAME')
    case 'MU00011697' %DS OFFICE LINUX
        dirPref.rootDir = '/mnt/dshi0006_market/Massive/COSproject/';

    case '' %MASSIVE
        dirPref.rootDir = '/fs03/fs11/Daisuke/COSproject/';
end
addpref(groupName,'dirPref',dirPref);

disp(dirPref)

function setPaths_COS

switch getenv('COMPUTERNAME')
    case 'MU00011697' %DS OFFICE LINUX
        rmpath(genpath('/home/daisuke/Documents/git/tlab_ecog_hctsa'));
        addpath(genpath('/home/daisuke/Documents/git/xspecies_blind_classify'));
        rmpath('/home/daisuke/Documents/git/xspecies_blind_classify/obs');

        addpath(genpath('/home/daisuke/Documents/git/hctsa'));

        cd('/home/daisuke/Documents/git/xspecies_blind_classify/');
end

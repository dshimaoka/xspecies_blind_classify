%Description
%{

Run this before running anything else in MASSIVE

Add hctsa toolbox (and anything else, for MASSIVE)

%}

if isempty(getenv('COMPUTERNAME'))
    add_dir = {'/home/dshi0006/git/xspecies_blind_classify', '/home/dshi0006/git/hctsa'};
    rm_dir = {'/home/dshi0006/git/xspecies_blind_classify/obs'};

elseif strcmp(getenv('COMPUTERNAME'), 'MU00011697')
    add_dir = {'~/Documents/git/xspecies_blind_classify','~/Documents/git/hctsa'};
    rm_dir = {'/home/daisuke/Documents/git/xspecies_blind_classify/obs'};

    %for TISEAN
    [~,result]=system('echo -n $PATH');
    result = [result ' :~/bin'];
    setenv('PATH',result);

    cd('/home/daisuke/Documents/git/xspecies_blind_classify/');

elseif strcmp(getenv('COMPUTERNAME'), 'MU00175834')
    add_dir = {'C:\Users\dshi0006\git\xspecies_blind_classify'; 'C:\Users\dshi0006\git\hctsa'};
end


%should include:
%fly_blind_classify

%should include for preprocess.m but NOT include for TS_compute.m
%chronux_2_11

% currentpath = path;
% save('currentpath','currentpath');
restoredefaultpath;
for idir = 1:numel(add_dir)
    addpath(genpath(add_dir{idir}));
end
for idir = 1:numel(rm_dir)
    rmpath(genpath(rm_dir{idir}));
end



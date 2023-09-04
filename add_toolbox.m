%% Description

%{

Run this before running anything else in MASSIVE

Add hctsa toolbox (and anything else, for MASSIVE)

%}

if isempty(getenv('COMPUTERNAME'))
    toolbox_dir = {'/home/dshi0006/git/xspecies_blind_classify', '/home/dshi0006/git/hctsa'};
elseif strcmp(getenv('COMPUTERNAME'), 'MU00011697')
    toolbox_dir = {'~/Documents/git/xspecies_blind_classify','~/Documents/git/hctsa'};

    %for TISEAN
    [~,result]=system('echo -n $PATH');
    result = [result ' :~/bin'];
    setenv('PATH',result)
elseif strcmp(getenv('COMPUTERNAME'), 'MU00175834')
    toolbox_dir = {'C:\Users\dshi0006\git\xspecies_blind_classify'; 'C:\Users\dshi0006\git\hctsa'};
end


%should include:
%fly_blind_classify

%should include for preprocess.m but NOT include for TS_compute.m
%chronux_2_11

% currentpath = path;
% save('currentpath','currentpath');
restoredefaultpath;
for idir = 1:numel(toolbox_dir)
    addpath(genpath(toolbox_dir{idir}));
end



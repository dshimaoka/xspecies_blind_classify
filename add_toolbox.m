%% Description

%{

Run this before running anything else in MASSIVE

Add hctsa toolbox (and anything else, for MASSIVE)

%}

if isempty(getenv('COMPUTERNAME'))
    toolbox_dir = '/home/dshi0006/git';
else
    toolbox_dir = 'C:\Users\dshi0006\git';%'toolboxes/';
end


%should include:
%chronux_2_11
%fly_blind_classify

addpath(genpath(toolbox_dir));

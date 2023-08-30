%% Description

%{

Run this before running anything else in MASSIVE

Add hctsa toolbox (and anything else, for MASSIVE)

%}

toolbox_dir = 'C:\Users\dshi0006\git';%'toolboxes/';
%should include:
%chronux_2_11
%fly_blind_classify

addpath(genpath(toolbox_dir));

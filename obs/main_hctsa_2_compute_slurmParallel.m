function [] = main_hctsa_2_compute_slurmParallel(hctsa_mat)
% Compute HCTSA features on initialised HCTSA matrices
%
% Reference - https://rcc.uchicago.edu/docs/software/environments/matlab/#matlab-parallel
%
% Inputs:
%   hctsa_mat = string; initialised HCTSA .mat file

hctsa_dir = 'hctsa_space_subtractMean_removeLineNoise/';

% create a local cluster object
pc = parcluster('local');

% explicitly set the JobStorageLocation to the temp directory that was created in your sbatch script
pc.JobStorageLocation = strcat('JobStorageLocation/', getenv('SLURM_JOB_ID'));

% start the matlabpool with maximum available workers
% control how many workers by setting ntasks in your sbatch script
parpool(pc, str2num(getenv('SLURM_CPUS_ON_NODE')));

tic;
TS_Compute(true, [], [], [], [hctsa_dir hctsa_mat]);
toc

end
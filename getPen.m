function pen = getPen()
%pen = getPen
% draw SLURM ARRAY TASK ID
% if running in standalone, then always return 1

if getenv('SLURM_ARRAY_TASK_ID')
    idStr = getenv('SLURM_ARRAY_TASK_ID'); % get task ID string 
    fprintf('ID %s\n', idStr);
    arrayTaskID = str2num(idStr); % conv string to number
    pen = arrayTaskID;
else
    pen = 1;
end
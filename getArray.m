function [minArray, maxArray] = getArray(scriptName)
%  [minArray, maxArray] = getArray(scriptName)

fid = fopen(scriptName);
tgtDetected = 0;

while ~tgtDetected
    thisline = fgetl(fid);
    %disp(thisline)
    if ~isempty(strfind(thisline, '#SBATCH --array'));
        [arrays] = textscan(thisline,'#SBATCH --array=%d-%d');
        minArray = arrays{1};
        maxArray = arrays{2};
        tgtDetected = 1;
    end
end
fclose(fid);


function [dat, t, eventTimes, eventLabels] = loadOneChannel(fullPath_to_fileName, channelNumber, channelType)
if nargin < 3
    channelType = 'LFPx';
end
assert(logical(sum(strcmp(channelType,{'LFPx','Inpt'}))));
dataName = sprintf('%s_RZ2_chn%03d', channelType, channelNumber);

load(fullPath_to_fileName,'FIDX', dataName);

eventTimes = FIDX.time;
eventLabels = FIDX.evnt;


channelStruct = eval(dataName);

time_ori = channelStruct.t;
dat = channelStruct.dat;

t = time_ori(1):1e-3:time_ori(1)+1e-3*(numel(dat)-1);

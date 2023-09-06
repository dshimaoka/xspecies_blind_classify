function [dims, macaque, channel, condition, epoch] = decodeTimeSeries(timeseries)
%[dims, macaque, channel, condition, epoch] = decodeTimeSeries(timeseries)

data = timeseries(:,2);
for ii = 1:numel(data)
    dims(:,ii) = sscanf(data.Name{ii},'macaque%d,channel%d,epoch%d,condition%d');
end
macaque = dims(1,:);
channel = dims(2,:);
epoch=dims(3,:);
condition=dims(4,:);

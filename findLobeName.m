function [lobeIdx] = findLobeName(channelID, channelsByLobe)

for ilobe = 1:numel(channelsByLobe)
    theseChannels = channelsByLobe{ilobe};
    if sum(intersect(theseChannels, channelID))>0
        lobeIdx = ilobe;
    end
end
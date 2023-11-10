function [withinlobe, betweenlobes] = extractLobes(thisMatrix, tgtChannels, channelsByLobe)
% [withinlobe, betweenlobes] = extractLobes(thisMatrix, tgtChannels, channelsByLobe)

    withinlobe = [];
    betweenlobes = [];
    for ii = 1:numel(tgtChannels)

        for jj = 1:numel(tgtChannels)

            %disp([num2str(ii) '_' num2str(jj)]);

            ch_train = tgtChannels(ii);
            ch_validate = tgtChannels(jj);

            lobeIdx_train = findLobeName(ch_train, channelsByLobe);
            lobeIdx_validate = findLobeName(ch_validate, channelsByLobe);

            if ii < jj
                if lobeIdx_train == lobeIdx_validate
                    withinlobe = [withinlobe thisMatrix(ii,jj)];
                elseif lobeIdx_train ~= lobeIdx_validate
                    betweenlobes = [betweenlobes thisMatrix(ii,jj)];
                end
            end
        end
    end

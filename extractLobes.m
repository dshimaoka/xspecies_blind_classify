function [withinlobe, betweenlobes] = extractLobes(thisMatrix, tgtChannels_train, channelsByLobe_train,...
    tgtChannels_validate, channelsByLobe_validate)
% [withinlobe, betweenlobes] = extractLobes(thisMatrix, tgtChannels, channelsByLobe)

    withinlobe = [];
    betweenlobes = [];
    for ii = 1:numel(tgtChannels_train)

        for jj = 1:numel(tgtChannels_validate)

            %disp([num2str(ii) '_' num2str(jj)]);

            ch_train = tgtChannels_train(ii);
            ch_validate = tgtChannels_validate(jj);

            lobeIdx_train = findLobeName(ch_train, channelsByLobe_train);
            lobeIdx_validate = findLobeName(ch_validate, channelsByLobe_validate);

            if ii < jj
                if lobeIdx_train == lobeIdx_validate
                    withinlobe = [withinlobe thisMatrix(ii,jj)];
                elseif lobeIdx_train ~= lobeIdx_validate
                    betweenlobes = [betweenlobes thisMatrix(ii,jj)];
                end
            end
        end
    end

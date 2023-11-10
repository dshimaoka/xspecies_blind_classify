function [consistencies, consistencies_random] = getConsistency(TS_DataMat, TimeSeries, condNames)
%consistencies = getConsistency(directions_train, TS_DataMat, valid_features, condNames)
%
% INPUT:
%TS_DataMat:
%
% OUTPUT:
% consistencies: 1 x feature x epoch
%
% created from main_directionConsistency
%
% TODO:
% confirm which data to compute directions
% extend to multiple channels

if nargin < 3
    condNames = {'condition1','condition2'};
end

classifier =  TrainNMClassifier(TS_DataMat, TimeSeries, condNames);
directions = classifier.direction; %REVISE? - should come from training data?

[nChannels, nFeatures] = size(directions);
nEpochs = size(TS_DataMat,1)/2; %FIXME: for now assuming same #epochs between conditions
consistencies = nan(nChannels, nFeatures, nEpochs);

for ch = 1 : nChannels

    % Get valid features
    %feature_ids = find(valid_features);

    % Find rows corresponding to each class
    %   (assumes 2 classes only)
    %class_labels = [1 0]; % 1 = wake; 0 = anest
    %class1 = getIds(condNames{1}, TimeSeries); %AMEND
    class1 = contains(TimeSeries.Name,condNames{1});
    class2 = ~class1;
    classes = {class1, class2};


    % Get rows for each class
    rows = cell(size(classes));
    for class = 1 : length(classes)
        rows{class} = classes{class};
    end

    for f = 1:nFeatures%feature_ids

        % Get values for each class
        values = cell(size(classes));
        for class = 1 : length(classes)
            values{class} = TS_DataMat(rows{class}, f);
        end

        % Get direction of effect (from training data???)
        direction = directions(ch, f);

        % Flip epoch values to always test class1 > class2
        if direction == 0
            values = cellfun(@(x) x*-1, values, 'UniformOutput', false);
        end

        for epoch = 1 : length(values{1})

            % Find proportion of class2 epochs which are in the same
            % direction as the trained direction
            greater = values{1}(epoch) > values{2};

            consistencies(ch, f, epoch) = sum(greater) / numel(greater);

        end

    end
end

consistencies_random = getConsistencies_random(consistencies);
end


function consistencies_random = getConsistencies_random(consistencies)
% consistencies_random = getConsistencies_random(consistencies)
% created from chance_consistency.m

%% Chance distribution

dims = size(consistencies); % ch x features x flies x epochs

% Assumes equal number of epochs for each class
pool = (0:dims(end)) / dims(end);
consistencies_random = randsample(pool, numel(consistencies), true);
consistencies_random = reshape(consistencies_random, dims);
end

function [sig, ps, ps_fdr_th, sig_thresh, sig_thresh_fdr] = ...
    get_sig_features(performances, performances_random, ch_valid_features, alpha, q)
% Get features which perform significantly better than chance
% Conducts FDR correction for multiple corrections, on valid features
%
% Inputs:
%   performances = matrix (channels x features); accuracy/consistencies
%   performances_random = matrix (channels x features);
%   perf_type = 'nearestMean' or 'nearestMedian' or 'consis'
% Outputs
%   sig = logical matrix (channels x features)
%   ps = matrix (channels x features); holds uncorrected p-values
%   ps_fdr = matrix (channels x features); holds corrected p-values (by  #features)
%   sig_thresh = threshold value for p < .05, uncorrected across all
%       features
%   sig_thresh_fdr = vector (channels); holds threshold values for each
%       channel for corrected p < .05


perf_type = 'nearestMedian';

% % Deal with filenames
% switch(perf_type)
%     case {'nearestMedian', 'nearestMean'}
%         perf_string = ['class_' perf_type];
%         switch(data_set)
%             case 'train'
%                 data_string = 'crossValidation';
%                 hctsa_string = 'HCTSA_train';
%             case 'validate1'
%                 data_string = 'validate1_accuracy';
%                 hctsa_string = 'HCTSA_validate1';
%         end
%     case 'consis'
%         perf_string = 'consis_nearestMedian';
%         switch(data_set)
%             case 'train'
%                 data_string = 'train';
%                 hctsa_string = 'HCTSA_train';
%             case 'validate1'
%                 data_string = 'validate1';
%                 hctsa_string = 'HCTSA_validate1';
%         end      
% end
% 
% % File locations
% source_dir = ['results' preprocess_string '/'];
% source_file = [perf_string '_' data_string '.mat'];
% hctsa_prefix = ['../hctsa_space/' hctsa_string];

% % Load performance files
% perf = load([source_dir source_file]);
% switch(perf_type)
%     case {'nearestMedian', 'nearestMean'}
%         % average across cross-validations
%         performances = mean(perf.accuracies, 3);
%     case 'consis'
%         % average across epochs, flies
%         performances = mean(perf.consistencies, 4);
%         performances = mean(performances, 3);
% end
% 
% % Load chance distribution
% switch(perf_type)
%     case {'nearestMedian', 'nearestMean'}
%         rand_string = 'class_random';
%     case 'consis'
%         % average across epochs, flies
%         rand_string = 'consis_random';
% end
% rand_file = [rand_string '_' data_string];
% perf_random = load([source_dir rand_file]);
% switch(perf_type)
%     case {'nearestMedian', 'nearestMean'}
%         performances_random = perf_random.accuracies_random;
%     case 'consis'
%         performances_random = perf_random.consistencies_random;
%         performances_random = mean(performances_random, 4);
%         performances_random = mean(performances_random, 3);
% end

%INPUTS
if nargin < 4 || isempty(alpha)
alpha = 0.05;
end
if nargin <5 ||isempty(q)
q = 0.05;
end


%% Find significantly performing features
% One-tailed, better than chance
% p-value from distribution: https://www.jwilber.me/permutationtest/


% Get threshold from chance distribution
chance_dist = performances_random(1, :);
sig_thresh = prctile(chance_dist, (1-alpha)*100); % 95%tile -> alpha = 0.05

% Compare each feature to threshold, get p-value
ps = nan(size(performances));
for ch = 1 : size(performances, 1)
    for f = 1 : size(performances, 2)
        % Find how many in chance dist are greater
        nBetter = sum(chance_dist > performances(ch, f));
        % p-value
        ps(ch, f) = nBetter / numel(chance_dist);
    end
end

% Conduct FDR correction per channel
ps_fdr = nan(size(ps));
ps_fdr_th = nan(size(performances, 1), 1);
sig_thresh_fdr = nan(size(ps_fdr_th));
for ch = 1 : size(performances, 1)
    % FDR
    [pID, pN] = FDR(ps(ch, find(ch_valid_features(ch, :))), q);
    ps_fdr_th(ch) = pID; % nonparametric
    ps_fdr(ch,:) = ps(ch,:) * sum(ch_valid_features(ch, :)); %16/10/2023
 
    % Get corresponding accuracy
    sig_thresh_fdr(ch) = prctile(chance_dist, (1-ps_fdr_th(ch))*100);
end

% Number of significantly performing features
sig = ps < repmat(ps_fdr_th, [1, size(ps, 2)]);

end


%% Description

%{

Exclude any feature which has at least 1 NaN value across time series
Exclude any feature which has a constant value across time series

Exclusion is done per channel

% run this after main_hctsa_2
%}

%% Settings
theseChannels = [47];

file_prefix = 'HCTSA_validate1'; % HCTSA_train; HCTSA_validate1; HCTSA_validate2
file_suffix = '.mat';

preprocess_string = '_subtractMean_removeLineNoise';
data_server = '/mnt/dshi0006_market/Massive/COSproject';

out_dir = fullfile(data_server, ['hctsa_space' preprocess_string '/']);

%nChannels = 1; % is there an easy way to get this programmatically instead?

% %% Separate into channels
% 
% % Filter out sub-file for each channel, containing only values for that
% %   channel
% 
% % Separate out channels into separate HCTSA files
% for ch = 1 : nChannels
%     tic;
%     ch_string = ['channel' num2str(ch)];
%     ch_rows = TS_GetIDs(ch_string, [out_dir file_prefix file_suffix], 'ts');
%     TS_FilterData(...
%         [out_dir file_prefix file_suffix],...
%         ch_rows,...
%         [],...
%         [out_dir file_prefix '_' ch_string file_suffix]);
%     toc
% end

%% Re-add special values to TS_DataMat
% Note HCTSA replaces special values with 0
%   https://hctsa-users.gitbook.io/hctsa-manual/setup/hctsa_structure#quality-labels

for ch = theseChannels
    tic;
    ch_string = ['ch' num2str(ch)];
    file_string = [out_dir file_prefix '_' ch_string file_suffix];
    
    hctsa = matfile(file_string, 'Writable', true);
    TS_DataMat = hctsa.TS_DataMat;
    TS_Quality = hctsa.TS_Quality;
    
    % "Fatal" errors - treat as NaN
    TS_DataMat(TS_Quality == 1) = NaN;
    % Special value NaN
    TS_DataMat(TS_Quality == 2) = NaN;
    % Special value Inf
    TS_DataMat(TS_Quality == 3) = Inf;
    % Special value -Inf
    TS_DataMat(TS_Quality == 4) = -Inf;
    
    % Check for other cases
    if any(TS_Quality(:) > 4)
        tmp = unique(TS_Quality(:));
        disp([file_string ' TS_Quality ' num2str(tmp)]);
    end
    
    hctsa.TS_DataMat = TS_DataMat;
    hctsa.TS_Quality = TS_Quality;
    toc
end
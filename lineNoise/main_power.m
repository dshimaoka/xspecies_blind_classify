%% Description

%{

Computes power spectra for given data

%}

%% Load data

% Dror's data
source_file = '../../fly_phi/bin/workspace_results/split2250_bipolarRerefType1_lineNoiseRemoved_postPuffpreStim.mat';
tmp = load(source_file); % training data
data_t = tmp.fly_data;

% Rhiannon's data
source_file = '../data/delabelled_data.mat';
tmp = load(source_file);
data_v = tmp.delabelled_data; % validation data (blind)

%% Make data formats consistent

% Dror -> concatenate trials
% time-trials x channels x flies x conditions
data_t = permute(data_t, [1 3 2 4 5]); % time x trials x channels x flies x conditions
dims = size(data_t);
data_t = reshape(data_t, [dims(1)*dims(2) dims(3:end)]); % time-trials x channels x flies x conditions

% Rhiannon ->
% time x channels x repeats
data_v = cell2mat(struct2cell(data_v)); % channels x time x repeats;
data_v = permute(data_v, [2 1 3]);
data_v = data_v((1:size(data_t, 1)), :, :); % take same trial length as data_t

%% Global settings

sample_rate = 1000;

% Chronux function (multi-taper spectrum)
params = struct();
params.tapers = [5 9];
params.Fs = sample_rate;
params.pad = 0;
params.win = [0.750 0.375];
params.removeFreq = []; %50;

%% Power spectrum of each time-series
% No extra processing

tic;
%[powers_t, faxis] = getPower(data_t, params); % ~19 seconds (tapers [3 5]);
toc
tic;
[powers_v, faxis] = getPower(data_v(1:750, :, :), params); % ~40 seconds (tapers [3 5])
toc

%% Plot power spectra for each fly

ch = 6;
tr = 45; % reference trial

figure;
for fly = 1 : size(powers_t, 3)
    subplot(3, 5, fly);
    
    hold on;
    plot(faxis, log(powers_t(:, ch, fly, 1)), 'r'); % wake
    plot(faxis, log(powers_t(:, ch, fly, 2)), 'k'); % anest
    plot(faxis, log(powers_v(:, ch, tr)), 'b'); % validation trial
    
    xlim([1 120]);
    
    title(['fly' num2str(fly) ' ch' num2str(ch)]);
    xlabel('Hz');
    ylabel('log(power)');
end

%% Plot power spectra to help find trial with line noise

ch = 15;

figure;
for tr = 1 : size(powers_v, 3)
    subplot(6, 10, tr);
    plot(faxis, log(powers_v(:, ch, tr)));
    
    xlim([40 60]);
    xlim([0 100]);
    title(num2str(tr));
end

%% Based on previous plots, looks like ch1 epoch 37 has 50Hz noise

ch = 15;
tr = 37;

% Get subsection of timeseries
tlength = 1500;
window = (1:tlength);
tseries = data_v(window, ch, tr);
%tseries = detrend(tseries);

figure;

% Plot raw data
subplot(3, 3, [1 2]);
plot(tseries, 'k');
title(['original t-series (' num2str(tlength) 'ms)']);
xlabel('t (ms)');

% Plot spectrum
[tpower, freqs] = mtspectrumc(tseries, params);
subplot(3, 3, 3);
plot(freqs, log(tpower), 'k');
xlim([0 100]);
title('original power spectrum');
ylabel('log(power)'); xlabel('Hz');

% Plot again as reference to compare with cleaned data
subplot(3, 3, [7 8]); hold on;
plot(tseries, 'k');
title('after rmlinesc.m'); xlabel('t (ms)');
subplot(3, 3, 9);
plot(freqs, log(tpower), 'k');
xlim([0 100]);

% Fit without f0 specification
f0 = [];
[datafit, Amps, freqs, Fval, sig] = fitlinesc(tseries, params, [], [], f0);
subplot(3, 3, [4 5]);
plot(datafit);
[tpower, freqs] = mtspectrumc(datafit, params);
subplot(3, 3, 6);
plot(freqs, log(tpower));

% Fit with f0 specification
f0 = 50;
[datafit, Amps, freqs, Fval, sig] = fitlinesc(tseries, params, [], [], f0);
subplot(3, 3, [4 5]); hold on;
plot(datafit);
title('fitted sine waves (fitlinesc.m)'); xlabel('t (ms)');
legend('no-spec', 'spec-50Hz', 'location', 'east');
[tpower, freqs] = mtspectrumc(datafit, params);
subplot(3, 3, 6); hold on;
plot(freqs, log(tpower));
xlim([0 100]);
legend('no-spec', 'spec-50Hz');
title('fitted power spectrum'); ylabel('log(power)'); xlabel('Hz');

% Plot cleaned data and spectrum
f0 = [];
[datac] = rmlinesc(tseries, params, [], [], f0);
subplot(3, 3, [7 8]); % cleaned data
plot(datac);
subplot(3, 3, 9); hold on;
[tpower, freqs] = mtspectrumc(datac, params);
plot(freqs, log(tpower));

% Plot cleaned data and spectrum
f0 = 50;
[datac] = rmlinesc(tseries, params, [], [], f0);
subplot(3, 3, [7 8]); hold on;
plot(datac);
[tpower, freqs] = mtspectrumc(datac, params);
subplot(3, 3, 9); hold on;
plot(freqs, log(tpower));
xlim([0 100]);
title('after rmlinesc.m'); ylabel('log(power)'); xlabel('Hz');
legend('orig.', 'no-spec rm', 'spec-50Hz rm');

%% Example

fs = 1000; % Sampling frequency (samples per second)
dt = 1/fs; % seconds per sample.
StopTime = 0.75; % seconds.
t = (0:dt:StopTime-dt)'; % seconds.
F = 50; % Sine wave frequency (hertz)
data = sin(2*pi*F*t);

figure;
subplot(3, 2, 1);
plot(t, data);

[tpower, freqs] = mtspectrumc(data, params);
subplot(3, 2, 2);
plot(freqs, log(tpower));
xlim([0 100]);

datafit = fitlinesc(data, params, [], [], []);
subplot(3, 2, 3); plot(datafit);
[tpower, freqs] = mtspectrumc(datafit, params);
subplot(3, 2, 4); plot(freqs, log(tpower));
xlim([0 100]);

datafit = fitlinesc(data, params, [], [], 50);
subplot(3, 2, 5); plot(datafit);
[tpower, freqs] = mtspectrumc(datafit, params);
subplot(3, 2, 6); plot(freqs, log(tpower));
xlim([0 100]);

%%

fs = 1000; % Sampling frequency (samples per second)
dt = 1/fs; % seconds per sample.
StopTime = 0.75; % seconds.
t = (0:dt:StopTime-dt)'; % seconds.
F = 50; % Sine wave frequency (hertz)
data = sin(2*pi*F*t);

data = zeros(size(data))-1;

subplot(3, 2, 1); hold on;
plot(t, data);

[tpower, freqs] = mtspectrumc(data, params);
subplot(3, 2, 2); hold on;
plot(freqs, log(tpower));
xlim([0 100]);

datafit = fitlinesc(data, params, [], [], []);
subplot(3, 2, 3); hold on;
plot(datafit);
[tpower, freqs] = mtspectrumc(datafit, params);
subplot(3, 2, 4); hold on;
plot(freqs, log(tpower));
xlim([0 100]);

datafit = fitlinesc(data, params, [], [], 50);
subplot(3, 2, 5); hold on;
plot(datafit);
[tpower, freqs] = mtspectrumc(datafit, params);
subplot(3, 2, 6); hold on;
plot(freqs, log(tpower));
xlim([0 100]);

%% Power spectrum of each time-series
% With extra processing

s_lineNoise = 1;
s_detrend = 1;
s_zscore = 1;

% Do extra processing
if s_lineNoise == 1
    tic;
    [data_t_proc, data_t_fit] = removeLineNoise(data_t(1:750, :, :, :), params); % ~10 seconds (tapers = [3 5])
    toc
    tic;
    [data_v_proc, data_v_fit] = removeLineNoise(data_v(1:750, :, :), params); % ~21 seconds (tapers = [3 5])
    toc
end
if s_detrend == 1
    data_t_proc = detrendAll(data_t_proc);
    data_v_proc = detrendAll(data_v_proc);
end
if s_zscore == 1
    data_t_proc = zscore(data_t_proc, [], 1);
    data_v_proc = zscore(data_v_proc, [], 1);
end
%%
% Get power spectra
tic;
[powers_t_proc, faxis] = getPower(data_t_proc, params); % ~19 seconds (tapers [3 5]);
toc
tic;
[powers_v_proc, faxis] = getPower(data_v_proc, params); % ~40 seconds (tapers [3 5])
toc

%% Plot power spectra (processed)

ch = 6;
tr = 45; % reference trial

figure;
for fly = 1 : size(powers_t, 3)
    subplot(3, 5, fly);
    
    hold on;
    plot(faxis, log(powers_t_proc(:, ch, fly, 1)), 'r'); % wake
    plot(faxis, log(powers_t_proc(:, ch, fly, 2)), 'k'); % anest
    plot(faxis, log(powers_v_proc(:, ch, tr)), 'b', 'LineWidth', 1); % validation trial
    
    xlim([1 120]);
    
    title(['fly' num2str(fly) ' ch' num2str(ch)]);
    xlabel('Hz');
    ylabel('log(power)');
end

%% Figure printing

figure_name = 'power_spec_750_removed49-51';

set(gcf, 'PaperOrientation', 'Portrait');

%print(figure_name, '-dsvg', '-painters'); % SVG
%print(figure_name, '-dpdf', '-painters', '-bestfit'); % PDF
print(figure_name, '-dpng'); % PNG

%% Plot power spectra of removed line noise (fitted noise)

[power_t_fit, faxis] = getPower(data_t_fit, params);
[power_v_fit, faxis] = getPower(data_v_fit, params);

ch = 6;
tr = 45; % reference trial

figure;

for fly = 1 : size(powers_t, 3)
    subplot(3, 5, fly);
    
    hold on;
    plot(faxis, log(power_t_fit(:, ch, fly, 1)), 'r'); % wake
    plot(faxis, log(power_t_fit(:, ch, fly, 2)), 'k'); % anest
    plot(faxis, log(power_v_fit(:, ch, tr)), 'b', 'LineWidth', 1); % validation trial
    
    xlim([1 120]);
    
    title(['fly' num2str(fly) ' ch' num2str(ch)]);
    xlabel('Hz');
    ylabel('log(power)');
end

%% Plot power spectra of fitted line noise



%% Function for computing power spectra

function [powers, faxis] = getPower(data, params)
    % Inputs:
    %   data = matrix (time x repeat-dimensions...)
    %       repeat-dimensions can be any set of dimensions
    %   params = struct; Chronux params
    %
    % Outputs:
    %   powers = matrix (frequencies x repeat-dimensions...)
    %   faxis = vector of frequencies for power spectrum
    
    dims = size(data);
    data_r = reshape(data, [dims(1) prod(dims(2:end))]);
    
    % Create storage matrix (figure out how many freqs)
    [fpower, faxis] = mtspectrumc(data_r(:, 1), params);
    powers = zeros(length(faxis), size(data_r, 2));
    
    % Chronux multi-taper spectrum
    for r = 1 : size(data_r, 2)
        [fpower, faxis] = mtspectrumc(data_r(:, r), params);
        powers(:, r) = fpower;
    end
    
    % Reshape to match original dimensions
    powers = reshape(powers, [length(faxis) dims(2:end)]);
end

%% Function for removing line noise

function [data_c, data_fit] = removeLineNoise(data, params)
    % Inputs:
    %   data = matrix (time x repeat-dimensions...)
    %       repeat-dimensions can be any set of dimensions
    %   params = struct; Chronux params
    %
    % Outputs:
    %   data_c = matrix (time x repeat-dimensions...)
    %       Cleaned data
    %   data_fit = matrix (time x repeat-dimensions...)
    %       Fitted line noise data (which was removed to obtain data_c
    
    dims = size(data);
    data_r = reshape(data, [dims(1) prod(dims(2:end))]);
    
    data_c = zeros(size(data_r));
    data_fit = zeros(size(data_r));
    
    for r = 1 : size(data_r, 2)
        [cl_data, datafit] = rmlinesmovingwinc(data_r(:, r), params.win, [], params, [], [], params.removeFreq);
        datafit = fitlinesc(data_r(:, r), params, [], [], params.removeFreq);
        data_c(:, r) = cl_data;
        data_fit(:, r) = datafit;
    end
    
    % Reshape to match original dimensions
    data_c = reshape(data_c, dims);
    data_fit = reshape(data_fit, dims);
end

%% Function for detrending

function [data_d] = detrendAll(data)
    % Inputs:
    %   data = matrix (time x repeat-dimensions...)
    %       repeat-dimensions can be any set of dimensions
    %   params = struct; Chronux params
    %
    % Outputs:
    %   data_c = matrix (time x repeat-dimensions...)
    %       Cleaned data
    %   data_fit = matrix (time x repeat-dimensions...)
    %       Fitted line noise data (which was removed to obtain data_c
    
    dims = size(data);
    data_r = reshape(data, [dims(1) prod(dims(2:end))]);
    
    % Detrend
    data_d = detrend(data_r);
    
    % Reshape to match original dimensions
    data_d = reshape(data_d, dims);
end

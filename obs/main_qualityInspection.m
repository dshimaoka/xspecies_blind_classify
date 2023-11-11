%%

%% Load

source_file = 'HCTSA_train_channel6.mat';

preprocess_string = '_subtractMean_removeLineNoise';
source_dir = ['hctsa_space' preprocess_string '/'];

load([source_dir source_file]);

%% Special values
figure;

foo_error = TS_Quality == 1;
subplot(3, 1, 1);
plot(sum(foo_error));
plot(sum(foo_error)/size(foo_error, 1));
title('ch6 errors');
ylabel('prop.');

foo_nan = TS_Quality == 2;
subplot(3, 1, 2);
plot(sum(foo_nan)/size(foo_nan, 1));
title('ch6 nans');
subplot(3, 1, 3);

foo_inf = TS_Quality == 3 | TS_Quality == 4;
plot(sum(foo_inf)/size(foo_inf, 1));
title('ch6 infs');
xlabel('feature');

%% Constant values

same_thresh = repmat(TS_DataMat(1, :), [size(TS_DataMat, 1) 1]);
subtracted = TS_DataMat - same_thresh;
foo_const = all(subtracted == 0, 1);

%% Number of features with special cases

nNan_any = sum(any(foo_error | foo_nan, 1));
nNan_all = sum(all(foo_error | foo_nan, 1));

nConst = sum(foo_const & ~all(foo_error | foo_nan, 1));

function [thisAx] = show_NMclassifier_single(classifier_cv, ...
     thisAx)
%
% created from NMclassifier_cv_test.m

accuracy_train = classifier_cv.accuracy_train;
accuracy_validate = classifier_cv.accuracy_validate;
validFeatures = classifier_cv.validFeatures;

maccuracy_train = mean(accuracy_train,2);
maccuracy_validate = mean(accuracy_validate,2);

if nargin < 2
    thisAx = gca;
end
[~, bestFeature_tv(1)] = max(maccuracy_train);
[~, bestFeature_tv(2)] = max(maccuracy_validate);
bestFeature_tv_name(1) = classifier_cv.operations{bestFeature_tv(1), 4};
bestFeature_tv_name(2) = classifier_cv.operations{bestFeature_tv(2), 4};

a(1)=plot(thisAx, maccuracy_train(validFeatures), maccuracy_validate(validFeatures),'k.');
hold on
a(2)=plot(thisAx, maccuracy_train(bestFeature_tv(1)), maccuracy_validate(bestFeature_tv(1)), 'ro');
a(3)=plot(thisAx, maccuracy_train(bestFeature_tv(2)), maccuracy_validate(bestFeature_tv(2)), 'go');

xlim(thisAx, [.5 1]);
ylim(thisAx, [.5 1]);
line(thisAx, [.5 1],[.5 1],'color','k');
set(thisAx,'tickdir','out');
axis equal padded;
legend(a(2:3), bestFeature_tv_name{1}, bestFeature_tv_name{2},'location','southeast');
xlabel(thisAx, 'accuracy train');
ylabel(thisAx, 'accuracy validation');

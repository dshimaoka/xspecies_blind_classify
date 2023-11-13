function [thisAx] = show_NMclassifier_single(classifier_cv, ...
     thisAx, p_value, p_th)
%
% created from NMclassifier_cv_test.m

accuracy_train = classifier_cv.accuracy_train;
accuracy_validate = classifier_cv.accuracy_validate;
validFeatures = classifier_cv.validFeatures;

if nargin < 4
    p_th = 0.05;
end
if nargin < 3
    p_value = zeros(1,numel(validFeatures));
end
if nargin < 2 || isempty(thisAx)
    thisAx = gca;
end

maccuracy_train = mean(accuracy_train(validFeatures,:),2);
maccuracy_validate = mean(accuracy_validate(validFeatures,:),2);
p_value = p_value(validFeatures);

[~, bestFeature_tv(1)] = max(maccuracy_train);
[~, bestFeature_tv(2)] = max(maccuracy_validate);
bestFeature_tv_name(1) = classifier_cv.operations{bestFeature_tv(1), 4};
bestFeature_tv_name(2) = classifier_cv.operations{bestFeature_tv(2), 4};

if sum(p_value<p_th)>0
    a(1)=plot(thisAx, maccuracy_train(p_value<p_th), maccuracy_validate(p_value<p_th),'k.');
end
hold on
if sum(p_value>=p_th)>0
    a(2)=plot(thisAx, maccuracy_train(p_value>=p_th), maccuracy_validate(p_value>=p_th),'.','color',[.5 .5 .5]);
end
a(3)=plot(thisAx, maccuracy_train(bestFeature_tv(1)), maccuracy_validate(bestFeature_tv(1)), 'ro');
a(4)=plot(thisAx, maccuracy_train(bestFeature_tv(2)), maccuracy_validate(bestFeature_tv(2)), 'go');
axis equal;
xlim(thisAx, [.5 1]);
ylim(thisAx, [0 1]);
line(thisAx, [.5 1],[.5 1],'color','k');
set(thisAx,'tickdir','out');
legend(a(3:4), replace(bestFeature_tv_name{1},'_','-'), replace(bestFeature_tv_name{2},'_','-'),'location','southeast');
xlabel(thisAx, 'accuracy train');
ylabel(thisAx, 'accuracy validation');

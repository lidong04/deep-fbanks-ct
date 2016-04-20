function texture_experiments()
%TEXTURE_EXPERIMENTS  Run texture classification experiments
%    The experimens download a number of benchmark datasets in the
%    'data/' subfolder. Make sure that there are several GBs of
%    space available.
%
%    By default, experiments run with a lite option turned on. This
%    quickly runs all of them on tiny subsets of the actual data.
%    This is used only for testing; to run the actual experiments,
%    set the lite variable to false.
%
%    Running all the experiments is a slow process. Using parallel
%    MATLAB and several cores/machiens is suggested.

% Author: Mircea Cimpoi

% Copyright (C) 2013 Andrea Vedaldi
% All rights reserved.
%
% This file is part of the VLFeat library and is made available under
% the terms of the BSD license (see the COPYING file).

lite = false;
clear ex;
save_report = 0;

datasetList = {'curet', 'umd', 'uiuc', 'kth-tips', 'kth-tips-2a', ...
    'kth-tips-2b', 'fmd', 'dtd'}; % could add ALOT dataset -- 'alot';

numSplits = cell(1, numel(datasetList));

defaultNumSplits = 10;
if lite
  defaultNumSplits = 1;
end

for ii = 1 : numel(datasetList)
  numSplits{ii} = defaultNumSplits;
end

if ~lite
    % KTH-TIPS2-a (train on 3 samples test on the remaining one)
    numSplits{5} = 11 : 14;
    % KTH-TIPS2-b train on one sample, test on remaining three
    numSplits{6} = 4;
    % FMD -- 14 random splits;
    numSplits{7} = 14;
    % DTD -- 10 splits, predefined;
    numSplits{8} = 10;
end

featureType = 'dsift';

encTypes = {'fv', 'bovw', 'vlad'};
% For LLC and KCB, please download the code from
% http://www.robots.ox.ac.uk/~vgg/software/enceval_toolkit/
% and copy it in the code folder, then add to encTypes list: 'llc10k', 'kcb10k'
%
% For DeCAF features, and combining them with IFV: add 'raw_decaf' and
% 'fv+decaf' to encTypes list; Do not use in 'lite' setting;


if (lite)
  tag = 'lite';
else
  tag = 'ex';
end

meanAcc = zeros(numel(datasetList), numel(encTypes));
pmAcc = zeros(numel(datasetList), numel(encTypes));

for ii = 1 : numel(datasetList)
  for ee = 1 : numel(encTypes)
    if (1 ~= numel(numSplits{ii}))
      nSplits = numSplits{ii};
    else
      nSplits = 1 : numSplits{ii};
    end

    resAcc = zeros(1, numel(nSplits));

    for jj = nSplits
      ex.trainOpts = {'C', 10} ;
      ex.prefix = sprintf('%s-%s-seed-%d', encTypes{ee}, ...
        featureType, jj);

      switch  encTypes{ee}
        case 'fv'
          ex.opts = {...
            'type', encTypes{ee}, ...
            'numWords', 256, ...
            'layouts', {'1x1'}, ...
            'numPcaDimensions', 80, ...
            'extractorFn', @(x) getDenseSIFT(x, ...
                                           'step', 4, ...
                                         'scales', 2.^(1.5:-.5:-3))};

        case 'bovw'
          ex.opts = {...
            'type', 'bovw', ...
            'numWords', 4096, ...
            'layouts', {'1x1'}, ...
            'numPcaDimensions', 100, ...
            'whitening', true, ...
            'whiteningRegul', 0.01, ...
            'renormalize', true, ...
            'extractorFn', @(x) getDenseSIFT(x, ...
                                          'step', 4, ...
                                        'scales', 2.^(1:-.5:-3))};
        case 'vlad'
          ex.opts = { ...
            'type', 'vlad', ...
            'numWords', 256, ...
            'layouts', {'1x1'}, ...
            'numPcaDimensions', 100, ...
            'whitening', true, ...
            'whiteningRegul', 0.01, ...
            'renormalize', true, ...
            'extractorFn', @(x) getDenseSIFT(x, ...
                                         'step', 4, ...
                                       'scales', 2.^(1:-.5:-3))};
        % see comments above
        case 'llc10k'
          ex.opts = {...
            'type', 'llc', ...
            'numWords', 10000, ...
            'layouts', {'1x1'}, ...
            'numPcaDimensions', 100, ...
            'whitening', true, ...
            'whiteningRegul', 0.01, ...
            'renormalize', true, ...
            'extractorFn', @(x) getDenseSIFT(x, ...
                                          'step', 4, ...
                                        'scales', 2.^(1:-.5:-3))};

        case 'kcb10k'
          ex.opts = {...
            'type', 'kcb', ...
            'numWords', 10000, ...
            'layouts', {'1x1'}, ...
            'numPcaDimensions', 100, ...
            'whitening', true, ...
            'whiteningRegul', 0.01, ...
            'renormalize', true, ...
            'extractorFn', @(x) getDenseSIFT(x, ...
                                          'step', 4, ...
                                        'scales', 2.^(1:-.5:-3))};

       case 'raw_decaf'
          ex.prefix = sprintf('%s-%s-seed-%d', 'raw', ...
            'decaf', jj);
          featureType = 'decaf';
          ex.opts = {...
            'type', 'raw' };

        case 'fv+decaf'
          ex.prefix = sprintf('%s-%s-seed-%d', 'mix', 'fv+decaf', jj);
          ex.opts = {...
            'type', 'mix' };
          featureType = 'fv+decaf';
      end


      res = traintest(...
        'prefix', [tag '-' datasetList{ii} '-' ex.prefix], ...
        'seed', jj, ...
        'dataset', datasetList{ii}, ...
        'datasetDir', fullfile('data', datasetList{ii}), ...
        'lite', lite, ...
        'kernel', 'linear', ...
        'featureType', featureType, ...
         ex.trainOpts{:}, ...
        'encoderParams', ex.opts);

      resAcc(jj) = res.mAcc * 100;
    end

    if (1 ~= numel(numSplits{ii}))
      resAcc = resAcc(numSplits{ii});
    end
    meanAcc(ii, ee) = mean(resAcc);
    pmAcc(ii, ee) = std(resAcc);
  end
end

if 0
  imdb = load(fullfile('experiments', ...
    [tag '-' datasetList{ii} '-' resize_str ex.prefix], 'imdb.mat'));
  m_acc = mean(all_acc);

  for jj = 1 : numel(imdb.meta.classes)
    fprintf('%s\t%.2f\n', imdb.meta.classes{jj}, 100 * m_acc(jj));
  end
end

%% Print table
if (save_report)
    fid0 = fopen('reports.html', 'w');
    if (fid0 > 0)
      fprintf(fid0, '<table border="1">\n');
      fprintf(fid0, ['<tr><td rowspan="2">Dataset</td><td colspan="5">SIFT</td>' ...
        '<td rowspan="2">DeCAF</td><td rowspan="2">IFV + DeCAF</td></tr>\n']);
      fprintf(fid0, '<tr><td>IFV</td><td>BOVW</td><td>VLAD</td><td>LLC</td><td>KCB</td></tr>\n');
      for ii = 1 : size(meanAcc, 1)
        line = td(datasetList{ii});
        for jj = 1 : size(meanAcc, 2)
          line = [line td(sprintf('%.2f +/- %.2f', meanAcc(ii, jj), pmAcc(ii, jj)))];
        end
        fprintf(fid0, ['<tr>' line '</tr>\n']);
      end
      fprintf(fid0, '</table>\n');
      fclose(fid0);
    end
end
end

function y = td(x)
  y = ['<td>' x '</td>'];
end

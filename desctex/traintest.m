function results = traintest(varargin)
% RECOGNITION_DEMO  Demonstrates using VLFeat for image classification

if ~exist('vl_version')
  run(fullfile(fileparts(which(mfilename)), ...
               '..', '..', 'toolbox', 'vl_setup.m')) ;
end

opts.dataset = 'caltech101' ;
opts.prefix = 'bovw' ;
opts.encoderParams = {'type', 'bovw'} ;
opts.seed = 1 ;
opts.lite = true ;
opts.C = 10 ;
opts.kernel = 'linear' ;
opts.dataDir = 'data';
opts.featureType = 'dsift';
opts.experimentDir = 'experiments';
opts.useMasks = false;

for pass = 1:2
  opts.datasetDir = fullfile(opts.dataDir, opts.dataset) ;
  opts.resultDir = fullfile(opts.experimentDir, opts.prefix) ;
  opts.imdbPath = fullfile(opts.resultDir, 'imdb.mat') ;
  opts.encoderPath = fullfile(opts.resultDir, 'encoder.mat') ;
  opts.modelPath = fullfile(opts.resultDir, sprintf('model-%s.mat', ...
    opts.kernel)) ;
  opts.diaryPath = fullfile(opts.resultDir, 'diary.txt') ;
  opts.cacheDir = fullfile(opts.resultDir, 'cache') ;
  opts = vl_argparse(opts,varargin) ;
end

% do not do anything if the result data already exist
  if exist(fullfile(opts.resultDir, sprintf('result-%s.mat', opts.kernel))),
    load(fullfile(opts.resultDir, sprintf('result-%s.mat', opts.kernel)), 'ap', 'confusion') ;
    fprintf('%35s, mAP = %04.1f, mean acc = %04.1f\n', opts.prefix, ...
          100*mean(ap), 100*mean(diag(confusion))) ;

    if (1 == nargout)
      results.mAP = mean(ap);
      results.ap = ap;
      results.acc = diag(confusion);
      results.mAcc = mean(diag(confusion));
    end

    return ;
  end


vl_xmkdir(opts.cacheDir) ;
diary(opts.diaryPath) ; diary on ;
disp('options:' ); disp(opts) ;

% --------------------------------------------------------------------
%                                                   Get image database
% --------------------------------------------------------------------

if exist(opts.imdbPath)
  imdb = load(opts.imdbPath);
else
 switch opts.dataset
   case 'fmd', imdb = setupFMD(opts.datasetDir, 'seed', opts.seed, ...
       'lite', opts.lite) ;
   case 'dtd', imdb = setupDTD(opts.dataDir, 'seed', opts.seed, ...
       'keyOnly', 1, 'lite', opts.lite) ;
   case 'dtd-j', imdb = setupDTD(opts.dataDir, 'seed', opts.seed, ...
       'keyOnly', 0, 'lite', opts.lite) ;
   case 'kth-tips', imdb = setupKTH_TIPS(opts.dataDir,...
       'lite', opts.lite, 'variant', 'kth-tips', 'seed', opts.seed);
   case 'kth-tips-2b', imdb = setupKTH_TIPS(opts.dataDir,...
       'lite', opts.lite, 'variant', 'kth-tips-2b', 'seed', opts.seed);
   case 'kth-tips-2a', imdb = setupKTH_TIPS(opts.dataDir, ...
       'lite', opts.lite, 'variant', 'kth-tips-2a', 'seed', opts.seed);
   case 'curet', imdb = setupCuret(opts.datasetDir, 'seed', opts.seed, ...
       'lite', opts.lite);
   case 'uiuc', imdb = setupUIUC(opts.datasetDir, 'lite', opts.lite, ...
       'seed', opts.seed);
   case 'umd', imdb = setupUMD(opts.datasetDir, 'lite', opts.lite, ...
       'seed', opts.seed);
   case {'alot', 'alot2g'}
     opts.datasetDir = fullfile(opts.dataDir, 'alot');
     imdb = setupALOT(opts.datasetDir, 'variant', '2g', ...
       'lite', opts.lite, 'seed', opts.seed');
   otherwise, error('Unknown dataset type.') ;
 end
 save(opts.imdbPath, '-struct', 'imdb') ;
end

% --------------------------------------------------------------------
%                                      Train encoder and encode images
% --------------------------------------------------------------------
if (strcmp(opts.featureType, 'decaf'))
  try
    descrs = load(fullfile(imdb.imageDir, 'decaf_feats.mat'));
  catch
    descrs = load(fullfile(opts.datasetDir, 'decaf_feats.mat'));
  end
  descrs = descrs.feats'; % N_DIM x N_IMAGES

  descrs = bsxfun(@minus, descrs, mean(descrs, 2)) ;
  descrs = bsxfun(@times, descrs, 1./sqrt(sum(descrs.^2))) ;

elseif (strcmp(opts.featureType, 'fv+decaf'))
  encPath = opts.encoderPath;
  encPath = strrep(encPath, 'mix', 'fv');
  encPath = strrep(encPath, 'fv+decaf', 'dsift');
  fv_encoder = load_encoder(encPath);

  fvCache = opts.cacheDir;
  fvCache = strrep(fvCache, 'mix', 'fv');
  fvCache = strrep(fvCache, 'fv+decaf', 'dsift');

  fv_descrs = encodeImage(fv_encoder, cellfun(@(S) fullfile(imdb.imageDir, S), ...
    imdb.images.name, 'Uniform', 0), 'cacheDir', fvCache) ;

  try
    decaf_descrs = load(fullfile(imdb.imageDir, 'decaf_feats.mat'));
  catch
    decaf_descrs = load(fullfile(opts.datasetDir, 'decaf_feats.mat'));
  end
  decaf_descrs = decaf_descrs.feats'; % N_DIM x N_IMAGES

  decaf_descrs = bsxfun(@minus, decaf_descrs, mean(decaf_descrs, 2)) ;
  decaf_descrs = bsxfun(@times, decaf_descrs, 1./sqrt(sum(decaf_descrs.^2))) ;

  descrs = cat(1, fv_descrs, decaf_descrs);

else

  if exist(opts.encoderPath)
    encoder = load_encoder(opts.encoderPath) ;
  else
    numTrain = 5000 ;
    if opts.lite, numTrain = 10 ; end
    train = vl_colsubset(find(imdb.images.set <= 2), numTrain, 'uniform') ;
    paths = cellfun(@(S) fullfile(imdb.imageDir, S), imdb.images.name(train), ...
      'Uniform', 0);
    encoder = trainEncoder(paths, ...
                           opts.encoderParams{:}, ...
                           'lite', opts.lite) ;
    save(opts.encoderPath, '-struct', 'encoder') ;
    diary off ;
    diary on ;
  end

  if (isstr(encoder.extractorFn))
    encoder.extractorFn = str2func(encoder.extractorFn);
  end
  descrs = encodeImage(encoder, cellfun(@(S) fullfile(imdb.imageDir, S), ...
    imdb.images.name, 'Uniform', 0), ...
    'cacheDir', opts.cacheDir, 'useMasks', opts.useMasks) ;
  diary off ;
  diary on ;
end
% --------------------------------------------------------------------
%                                            Train and evaluate models
% --------------------------------------------------------------------

if isfield(imdb.images, 'class')
  classRange = unique(imdb.images.class) ;
else
  classRange = 1:numel(imdb.classes.imageIds) ;
end
numClasses = numel(classRange) ;

switch opts.kernel
  case 'linear'
  case 'hell'
    descrs = sign(descrs) .* sqrt(abs(descrs)) ;
  case 'chi2'
    descrs = vl_homkermap(descrs,1,'kchi2') ;
  otherwise
    assert(false) ;
end

descrs = bsxfun(@times, descrs, 1./sqrt(sum(descrs.^2))) ;

% train and test
% 1 - training data; 2 - validation; 3 - test;
% for training, we use train+val
train = find(imdb.images.set <= 2) ;
test = find(imdb.images.set == 3) ;

lambda = 1 / (opts.C*numel(train)) ;
par = {'Solver', 'sdca', 'Verbose', ...
       'BiasMultiplier', 1, ...
       'Epsilon', 0.001, ...
       'MaxNumIterations', 100 * numel(train)} ;

scores = cell(1, numel(classRange)) ;
ap = zeros(1, numel(classRange)) ;
ap11 = zeros(1, numel(classRange)) ;
w = cell(1, numel(classRange)) ;
b = cell(1, numel(classRange)) ;
for c = 1:numel(classRange)
  if isfield(imdb.images, 'class')
    y = 2 * (imdb.images.class == classRange(c)) - 1 ;
  else
    y = - ones(1, numel(imdb.images.id)) ;
    [~,loc] = ismember(imdb.classes.imageIds{classRange(c)}, imdb.images.id) ;
    y(loc) = 1 - imdb.classes.difficult{classRange(c)} ;
  end
  if all(y <= 0), continue ; end

  [w{c},b{c}] = vl_svmtrain(descrs(:,train), y(train), lambda, par{:}) ;
  scores{c} = w{c}' * descrs + b{c} ;

  [~,~,info] = vl_pr(y(test), scores{c}(test)) ;
  ap(c) = info.ap ;
  ap11(c) = info.ap_interp_11 ;
  fprintf('class %s AP %.2f; AP 11 %.2f\n', imdb.meta.classes{classRange(c)}, ...
          ap(c) * 100, ap11(c)*100) ;
end
scores = cat(1,scores{:}) ;
% -------------------------------------------------------------------------


diary off ;
diary on ;

% confusion matrix (can be computed only if each image has only one label)
if isfield(imdb.images, 'class')
  [~,preds] = max(scores, [], 1) ;
  confusion = zeros(numClasses) ;
  for c = 1:numClasses
    sel = find(imdb.images.class == classRange(c) & imdb.images.set == 3) ;
    tmp = accumarray(preds(sel)', 1, [numClasses 1]) ;
    tmp = tmp / max(sum(tmp),1e-10) ;
    confusion(c,:) = tmp(:)' ;
  end
else
  confusion = NaN ;
end

save(opts.modelPath, 'w', 'b') ;

save(fullfile(opts.resultDir, sprintf('result-%s.mat', opts.kernel)), ...
     'scores', 'ap', 'ap11', 'confusion', 'classRange', 'opts') ;


% figures
meanAccuracy = sprintf('mean accuracy: %f\n', mean(diag(confusion)));
mAP = sprintf('mAP: %.2f %%; mAP 11: %.2f', mean(ap) * 100, mean(ap11) * 100) ;

if (1 == nargout)
  results.mAP = mean(ap);
  results.mAcc = mean(diag(confusion));
end



figure(1) ; clf ;
imagesc(confusion) ; axis square ;
title([opts.prefix ' - ' meanAccuracy]) ;
vl_printsize(1) ;
print('-dpdf', fullfile(opts.resultDir, sprintf('result-confusion-%s.pdf', ...
  opts.kernel))) ;
print('-djpeg', fullfile(opts.resultDir, sprintf('result-confusion-%s.jpg', ...
  opts.kernel))) ;
figure(2) ; clf ; bar(ap * 100) ;
title([opts.prefix ' - ' mAP]) ;
ylabel('AP %%') ; xlabel('class') ;
grid on ;
vl_printsize(1) ;
ylim([0 100]) ;
print('-dpdf', fullfile(opts.resultDir, sprintf('result-ap-%s.pdf', ...
  opts.kernel))) ;

disp(meanAccuracy) ;
disp(mAP) ;
diary off ;

if isfield(imdb.images, 'class')
  [~,preds] = max(scores, [], 1) ;
  %confusion = zeros(numClasses) ;
  for cc = 1:numClasses
    sel = find(imdb.images.class == classRange(cc) & imdb.images.set == 3) ;
    %sel_wrong = (preds
  end
else
  confusion = NaN ;
end

end

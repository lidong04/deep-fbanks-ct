function imdb = setupKTH_TIPS(datasetDir, varargin)
% SETUPCALTECH256    Setup Caltech 256 and 101 datasets
%    This is similar to SETUPGENERIC(), with modifications to setup
%    Caltech-101 and Caltech-256 according to the standard
%    evaluation protocols. Specific options include:
%
%    Variant:: 'caltech256'
%      Either 'caltech101' or 'caltech256'.
%
%    AutoDownload:: true
%      Automatically download the data from the Internet if not
%      found at DATASETDIR.
%
%    See:: SETUPGENERIC().

% Author: Andrea Vedaldi

% Copyright (C) 2013 Andrea Vedaldi
% All rights reserved.
%
% This file is part of the VLFeat library and is made available under
% the terms of the BSD license (see the COPYING file).

opts.lite = true ;
opts.numTrain = 40 ;
opts.numTest = 41;
opts.numVal = 0;
opts.seed = 1 ;
opts.variant = 'kth-tips-2b' ;
opts.autoDownload = true ;
opts = vl_argparse(opts, varargin) ;

% Download and unpack
vl_xmkdir(datasetDir) ;
switch opts.variant
  case 'kth-tips'
    name = 'KTH_TIPS' ;
    checkClassName = 'sponge' ;
    url = 'http://www.nada.kth.se/cvap/databases/kth-tips/kth_tips_col_200x200.tar' ;
    numClasses = 10 ;
  % KTH-TIPS 2a does not have an equal number of images for each sample
  % 40 out of 44 have 108 images each; 4 have 72 images each
  case 'kth-tips-2b'
    name = 'KTH-TIPS2-b' ;
    checkClassName = 'wool' ;
    url = 'http://www.nada.kth.se/cvap/databases/kth-tips/kth-tips2-b_col_200x200.tar' ;
    numClasses = 11 ;
    % TODO: check how to split
    % Timofte BMVC12: samples with all their 108 images are distributed
    % over either train or testing set
    opts.numTrain = 108 ;
    opts.numTest = 324 ;
  case 'kth-tips-2a'
    name = 'KTH-TIPS2-a' ;
    checkClassName = 'wool' ;
    url = 'http://www.nada.kth.se/cvap/databases/kth-tips/kth-tips2-a_col_200x200.tar' ;
    numClasses = 11 ;
    % TODO: check how to split
    % Timofte BMVC12: samples with all their 108 images are distributed
    % over either train or testing set
    opts.numTrain = 108 ;
    opts.numTest = 324 ;
  otherwise
    error('Uknown dataset variant ''%s''.', opts.variant) ;
end

if exist(fullfile(datasetDir, checkClassName), 'file')
  % ok
elseif exist(fullfile(datasetDir, name, checkClassName), 'file')
  datasetDir = fullfile(datasetDir, name) ;
elseif opts.autoDownload
  fprintf('Downloading %s data to ''%s''. This will take a while.', opts.variant, datasetDir) ;
  untar(url, datasetDir) ;
  datasetDir = fullfile(datasetDir, name) ;
else
  error('Could not find %s dataset in ''%s''', opts.variant, datasetDir) ;
end

if (strcmp(opts.variant, 'kth-tips'))
  imdb = setupGeneric(datasetDir, ...
    'numTrain', opts.numTrain, 'numVal', 0, 'numTest', opts.numTest,  ...
    'expectedNumClasses', 10, ...
    'seed', opts.seed, 'lite', opts.lite, 'extension', '*.png') ;
else
  % Construct image database imdb structure
  imdb.meta.sets = {'train', 'val', 'test'} ;
  names = dir(datasetDir) ;
  names = {names([names.isdir]).name} ;
  names = setdiff(names, {'.', '..'}) ;
  imdb.meta.classes = names ;

  names = {} ;
  classes = {} ;
  for c = 1:numel(imdb.meta.classes)
    class = imdb.meta.classes{c} ;
    names{c} = {};
    classes{c} = [];
    samples{c} = [];
    crt_sample = 0;
    for suffix = 'a' : 'd'
      crt_sample = crt_sample + 1;
      tmp = dir(fullfile(datasetDir, class, ['sample_' suffix], '*.png')) ;
      names_sample = strcat([class filesep 'sample_' suffix filesep], {tmp.name}) ;
      classes_sample = repmat(c, 1, numel(names_sample)) ;
      names{c} = [names{c} names_sample];
      classes{c} = [classes{c} classes_sample];
      samples{c} = [samples{c} repmat(crt_sample, 1, numel(names_sample))];
    end
  end

  names = cat(2,names{:}) ;
  classes = cat(2,classes{:}) ;
  samples = cat(2, samples{:});
  sets = zeros(1,numel(names)) ;
  ids = 1:numel(names) ;

  opts.expectedNumClasses = numClasses;
  numClasses = numel(imdb.meta.classes) ;
  if ~isempty(opts.expectedNumClasses) && numClasses ~= opts.expectedNumClasses
    error('Expected %d classes in image database at %s.', opts.expectedNumClasses, datasetDir) ;
  end

  % split the data into train and test, one sample in train, with all
  % images, and the rest of samples in test; two samples in train, the
  % remaining two in test; then, three samples in train and one in test
  allsplits = {};
  cnt = 1;
  for ii = 1 : 3
    splits = combnk(1:4, ii);
    for pp = 1 : size(splits, 1)
      allsplits{cnt} = splits(pp, :);
      cnt = cnt + 1;
    end
  end

  for c = 1:numClasses
    sel = find(classes == c) ;

    crt_split = allsplits{opts.seed};
    selTrain = [];
    for pp = 1 : numel(crt_split)
        selTrain = [selTrain sel(samples(sel) == crt_split(pp))];
    end
    selVal = vl_colsubset(setdiff(sel, selTrain), opts.numVal) ;
    selTest = setdiff(sel, [selTrain selVal]) ;
    sets(selTrain) = 1 ;
    sets(selVal) = 2 ;
    sets(selTest) = 3 ;
  end

  ok = find(sets ~= 0) ;
  imdb.images.id = ids(ok) ;
  imdb.images.name = names(ok) ;
  imdb.images.set = sets(ok) ;
  imdb.images.class = classes(ok) ;
  imdb.imageDir = datasetDir ;

  if opts.lite
    ok = {} ;
    for c = 1:3
      ok{end+1} = vl_colsubset(find(imdb.images.class == c & imdb.images.set == 1), 5) ;
      ok{end+1} = vl_colsubset(find(imdb.images.class == c & imdb.images.set == 2), 5) ;
      ok{end+1} = vl_colsubset(find(imdb.images.class == c & imdb.images.set == 3), 5) ;
    end
    ok = cat(2, ok{:}) ;
    imdb.meta.classes = imdb.meta.classes(1:3) ;
    imdb.images.id = imdb.images.id(ok) ;
    imdb.images.name = imdb.images.name(ok) ;
    imdb.images.set = imdb.images.set(ok) ;
    imdb.images.class = imdb.images.class(ok) ;
  end
end

function imdb = setupCuret(datasetDir, varargin)
% SETUPCURET    Setup CUReT dataset
%    This is similar to SETUPGENERIC(), with modifications to setup
%    CUReT according to the standard
%    evaluation protocols.
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

opts.lite = false ;
opts.numTrain = 46 ;
opts.numTest = 46 ;
opts.numVal = 0;
opts.seed = 1 ;
opts.autoDownload = true ;
opts = vl_argparse(opts, varargin) ;

% Download and unpack
vl_xmkdir(datasetDir) ;
if exist(fullfile(datasetDir, 'curetcol', 'sample61'))
  % ok
elseif opts.autoDownload
  url = 'http://www.robots.ox.ac.uk/~vgg/research/texclass/data/curetcol.zip' ;
  fprintf('Downloading CUReT data to ''%s''. This will take a while.', datasetDir) ;
  unzip(url, datasetDir) ;
else
  error('CUReT not found in %s', datasetDir) ;
end

imdb = setupGeneric(fullfile(datasetDir, 'curetcol'), ...
  'numTrain', opts.numTrain, 'numVal', 0, 'numTest', opts.numTest,  ...
  'expectedNumClasses', 61, ...
  'seed', opts.seed, 'lite', opts.lite, 'extension', '*.png') ;

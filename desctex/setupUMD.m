function imdb = setupUMD(datasetDir, varargin)
% SETUPUMD   Setup UMD Texture Dataset
%    This is similar to SETUPCALTECH101(), with modifications to setup
%    the UMD Dataset accroding to the standard evaluation protocols.
%
%    See: SETUPCALTECH101().

% Author: Mircea Cimpoi

% Copyright (C) 2013 Andrea Vedaldi
% All rights reserved.
%
% This file is part of the VLFeat library and is made available under
% the terms of the BSD license (see the COPYING file).


opts.lite = false ;
opts.numTrain = 20 ;
opts.numTest = 20 ;
opts.numVal = 0;
opts.seed = 1 ;
opts.autoDownload = true ;
opts = vl_argparse(opts, varargin) ;

% Download and unpack
vl_xmkdir(datasetDir) ;
if exist(fullfile(datasetDir, '25'))
  % ok
elseif opts.autoDownload
  % The dataset is available for download as 5 zip archives
  url = 'http://www.cfar.umd.edu/~fer/High-resolution-data-base/textures-1.zip' ;
  fprintf('Downloading UMD-part1 data to ''%s''. This will take a while.\n', datasetDir) ;
  unzip(url, datasetDir) ;

  url = 'http://www.cfar.umd.edu/~fer/High-resolution-data-base/textures-2.zip' ;
  fprintf('Downloading UMD-part2 data to ''%s''. This will take a while.\n', datasetDir) ;
  unzip(url, datasetDir) ;

else
  error('UMD not found in %s', datasetDir) ;
end

imdb = setupGeneric(datasetDir, ...
  'numTrain', opts.numTrain, 'numVal', 0, 'numTest', opts.numTest,  ...
  'expectedNumClasses', 25, ...
  'seed', opts.seed, 'lite', opts.lite, 'extension', '*.png') ;

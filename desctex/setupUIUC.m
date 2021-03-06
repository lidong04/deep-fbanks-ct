function imdb = setupUIUC(datasetDir, varargin)
% SETUPUIUC    Setup UIUC Texture Dataset
%    This is similar to SETUPCALTECH101(), with modifications to setup
%    the UIUC Dataset accroding to the standard evaluation protocols.
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
if exist(fullfile(datasetDir, 'T25_plaid'))
  % ok
elseif opts.autoDownload
  % The dataset is available for download as 5 zip archives
  url = 'http://www-cvr.ai.uiuc.edu/ponce_grp/data/texture_database/T01-T05.zip' ;
  fprintf('Downloading UIUC-part1 data to ''%s''. This will take a while.\n', datasetDir) ;
  unzip(url, datasetDir) ;

  url = 'http://www-cvr.ai.uiuc.edu/ponce_grp/data/texture_database/T06-T10.zip' ;
  fprintf('Downloading UIUC-part2 data to ''%s''. This will take a while.\n', datasetDir) ;
  unzip(url, datasetDir) ;

  url = 'http://www-cvr.ai.uiuc.edu/ponce_grp/data/texture_database/T11-T15.zip' ;
  fprintf('Downloading UIUC-part3 data to ''%s''. This will take a while.\n', datasetDir) ;
  unzip(url, datasetDir) ;

  url = 'http://www-cvr.ai.uiuc.edu/ponce_grp/data/texture_database/T16-T20.zip' ;
  fprintf('Downloading UIUC-part4 data to ''%s''. This will take a while.\n', datasetDir) ;
  unzip(url, datasetDir) ;

  url = 'http://www-cvr.ai.uiuc.edu/ponce_grp/data/texture_database/T21-T25.zip' ;
  fprintf('Downloading UIUC-part5 data to ''%s''. This will take a while.\n', datasetDir) ;
  unzip(url, datasetDir) ;

else
  error('UIUC not found in %s', datasetDir) ;
end

imdb = setupGeneric(datasetDir, ...
  'numTrain', opts.numTrain, 'numVal', 0, 'numTest', opts.numTest,  ...
  'expectedNumClasses', 25, ...
  'seed', opts.seed, 'lite', opts.lite) ;

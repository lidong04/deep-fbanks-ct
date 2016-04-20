function imdb = setupALOT(datasetDir, varargin)
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
opts.numTest = 80 ;
opts.numVal = 0;
opts.seed = 1 ;
opts.autoDownload = true ;
opts.variant = '';
opts = vl_argparse(opts, varargin) ;

% Download and unpack
vl_xmkdir(datasetDir) ;
if exist(fullfile(datasetDir, '250'))
  % ok
elseif opts.autoDownload
  %download manually
  % http://aloi.science.uva.nl/public_alot/tars/alot_grey2.tar
  error('Please download ALOT manually');
else
  error('ALOT not found in %s', datasetDir) ;
end

imdb = setupGeneric(datasetDir, ...
  'numTrain', opts.numTrain, 'numVal', 0, 'numTest', opts.numTest,  ...
  'expectedNumClasses', 250, ...
  'seed', opts.seed, 'lite', opts.lite, 'extension', '*.png') ;

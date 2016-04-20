function descrs = encodeImage(encoder, im, varargin)
% ENCODEIMAGE   Apply an encoder to an image
%   DESCRS = ENCODEIMAGE(ENCODER, IM) applies the ENCODER
%   to image IM, returning a corresponding code vector PSI.
%
%   IM can be an image, the path to an image, or a cell array of
%   the same, to operate on multiple images.
%
%   ENCODEIMAGE(ENCODER, IM, CACHE) utilizes the specified CACHE
%   directory to store encodings for the given images. The cache
%   is used only if the images are specified as file names.
%
%   See also: TRAINENCODER().

% Author: Andrea Vedaldi

% Copyright (C) 2013 Andrea Vedaldi
% All rights reserved.
%
% This file is part of the VLFeat library and is made available under
% the terms of the BSD license (see the COPYING file).

opts.cacheDir = [] ;
opts.cacheChunkSize = 512 ;
opts.useMasks = false;
opts = vl_argparse(opts,varargin) ;

if (~isfield(opts, 'useMasks'))
  opts.useMasks = false;
end

if ~iscell(im), im = {im} ; end

% break the computation into cached chunks
startTime = tic ;
descrs = cell(1, numel(im)) ;
numChunks = ceil(numel(im) / opts.cacheChunkSize) ;

for c = 1:numChunks
  n  = min(opts.cacheChunkSize, numel(im) - (c-1)*opts.cacheChunkSize) ;
  chunkPath = fullfile(opts.cacheDir, sprintf('chunk-%03d.mat',c)) ;
  if ~isempty(opts.cacheDir) && exist(chunkPath)
    fprintf('%s: loading descriptors from %s\n', mfilename, chunkPath) ;
    load(chunkPath, 'data') ;
  else
    range = (c-1)*opts.cacheChunkSize + (1:n) ;
    fprintf('%s: processing a chunk of %d images (%3d of %3d, %5.1fs to go)\n', ...
      mfilename, numel(range), ...
      c, numChunks, toc(startTime) / (c - 1) * (numChunks - c + 1)) ;
    data = processChunk(encoder, im(range), opts.useMasks) ;
    if ~isempty(opts.cacheDir)
      save(chunkPath, 'data') ;
    end
  end
  descrs{c} = data ;
  clear data ;
end
descrs = cat(2,descrs{:}) ;

% --------------------------------------------------------------------
function psi = processChunk(encoder, im, useMasks)
% --------------------------------------------------------------------
v = ver;
hasParallelToolbox = any(strcmp('Parallel Computing Toolbox', {v.Name}));

psi = cell(1,numel(im)) ;

if numel(im) > 1 && hasParallelToolbox
  parfor i = 1:numel(im)
    psi{i} = encodeOne(encoder, im{i}, useMasks) ;
  end
else
  % avoiding parfor makes debugging easier
  for i = 1:numel(im)
    psi{i} = encodeOne(encoder, im{i}, useMasks) ;
  end
end
psi = cat(2, psi{:}) ;

% --------------------------------------------------------------------
function psi = encodeOne(encoder, imName, useMasks)
% --------------------------------------------------------------------

if (~isfield(encoder, 'scaling'))
  encoder.scaling = 0;
end
im = encoder.readImageFn(imName, encoder.scaling) ;

features = encoder.extractorFn(im) ;

if (useMasks)
  mask = encoder.readImageFn(strrep(imName, 'jpg', 'png'));
  validframes = find(mask(sub2ind(size(mask), ...
    uint16(features.frame(2, :)), uint16(features.frame(1, :))) > 0.5));
  features.descr = features.descr(:, validframes);
  features.frame = features.frame(:, validframes);
end

imageSize = size(im) ;
psi = {} ;
for i = 1:size(encoder.subdivisions,2)
  minx = encoder.subdivisions(1,i) * imageSize(2) ;
  miny = encoder.subdivisions(2,i) * imageSize(1) ;
  maxx = encoder.subdivisions(3,i) * imageSize(2) ;
  maxy = encoder.subdivisions(4,i) * imageSize(1) ;

  ok = ...
    minx <= features.frame(1,:) & features.frame(1,:) < maxx  & ...
    miny <= features.frame(2,:) & features.frame(2,:) < maxy ;

  descrs = encoder.projection * bsxfun(@minus, ...
                                       features.descr(:,ok), ...
                                       encoder.projectionCenter) ;
  if encoder.renormalize
    descrs = bsxfun(@times, descrs, 1./max(1e-12, sqrt(sum(descrs.^2)))) ;
  end

  w = size(im,2) ;
  h = size(im,1) ;
  frames = features.frame(1:2,:) ;
  frames = bsxfun(@times, bsxfun(@minus, frames, [w;h]/2), 1./[w;h]) ;

  switch encoder.type
    case 'bovw'
      [words,distances] = vl_kdtreequery(encoder.kdtree, encoder.words, ...
                                         descrs, ...
                                         'MaxComparisons', 100) ;
      z = vl_binsum(zeros(encoder.numWords,1), 1, double(words)) ;
      z = sqrt(z) ;

    case 'fv'
      z = vl_fisher(descrs, ...
                    encoder.means, ...
                    encoder.covariances, ...
                    encoder.priors, ...
                    'Improved') ;
    case 'vlad'
      [words,distances] = vl_kdtreequery(encoder.kdtree, encoder.words, ...
                                         descrs, ...
                                         'MaxComparisons', 15) ;
      assign = zeros(encoder.numWords, numel(words), 'single') ;
      assign(sub2ind(size(assign), double(words), 1:numel(words))) = 1 ;
      z = vl_vlad(descrs, ...
                  encoder.words, ...
                  assign, ...
                  'SquareRoot', ...
                  'NormalizeComponents') ;
    case {'llc', 'llc10k', 'llc25k'}
      % -- find K nearest neighbours in dictwords of imwords --
      if isempty(encoder.kdtree)
        distances = vl_alldist2(double(dictwords),double(imwords));
        % distances is MxN matrix where M is num of codewords
        % and N is number of descriptors in imwords
        [ix, ix] = sort(distances); %#ok<ASGLU>
        % ix is a KxN matrix containing
        % the indices of the K nearest neighbours of each image descriptor
        ix(K+1:end,:) = [];
      else

         ix = vl_kdtreequery(encoder.kdtree, single(encoder.words), ...
                                            single(descrs), ...
                                            'MaxComparisons', ...
                                            15, ...
                                            'NumNeighbors', 5);
      end

      z = LLCEncodeHelper(double(encoder.words), double(descrs), ...
                                          double(ix), double(1e-4), false);

    case {'kcb', 'kcb10k', 'kcb25k'}
    % START validate input parameters -------------------------------------
    %     default('K', 5);
    %     default('sigma', 45);
    % only used if a kdtree is specified
    %     default('maxComparisons', size(dictwords,2));
    % possible values: 'unc', 'pla', 'kcb'
    % see van Gemert et al. ECCV 2008 for details
    % 'inveuc' simply weights by the inverse of euclidean distance, then l1
    % normalizes
    %     default('kcbType', 'unc');
    %     default('outputFullMat', true);
    % END validate input parameters ---------------------------------------
      num_nn = 5;
      sigma_value = 45; % from kcbdemo
      kcb_type = 'unc';
      z = KCBEncode(descrs, encoder.words, num_nn, sigma_value, ...
        encoder.kdtree, 500, ...
        kcb_type, false);
    otherwise
      error('Unknown encoder type.')
  end
  z = z / max(sqrt(sum(z.^2)), 1e-12) ;
  psi{i} = z(:) ;
end
psi = cat(1, psi{:}) ;

% --------------------------------------------------------------------
function psi = getFromCache(name, cache)
% --------------------------------------------------------------------
[drop, name] = fileparts(name) ;
cachePath = fullfile(cache, [name '.mat']) ;
if exist(cachePath, 'file')
  data = load(cachePath) ;
  psi = data.psi ;
else
  psi = [] ;
end

% --------------------------------------------------------------------
function storeToCache(name, cache, psi)
% --------------------------------------------------------------------
[drop, name] = fileparts(name) ;
cachePath = fullfile(cache, [name '.mat']) ;
vl_xmkdir(cache) ;
data.psi = psi ;
save(cachePath, '-STRUCT', 'data') ;

% Inputs
%       B       -M x d codebook, M entries in a d-dim space
%       X       -N x d matrix, N data points in a d-dim space
%       knn     -number of nearest neighboring
%       lambda  -regulerization to improve condition
%---------------------------------------------------------------------
function [Coeff] = LLC_Encode(B, X, knn, beta)
%---------------------------------------------------------------------
if ~exist('knn', 'var') || isempty(knn),
    knn = 5;
end

if ~exist('beta', 'var') || isempty(beta),
    beta = 1e-4;
end

nframe=size(X,1);
nbase=size(B,1);

% find k nearest neighbors

XX = sum(X.*X, 2);
BB = sum(B.*B, 2);
D  = repmat(XX, 1, nbase)-2*X*B'+repmat(BB', nframe, 1);
IDX = zeros(nframe, knn);
for i = 1:nframe,
	d = D(i,:);
	[dummy, idx] = sort(d, 'ascend');
	IDX(i, :) = idx(1:knn);
end

% llc approximation coding
II = eye(knn, knn);
Coeff = zeros(nframe, nbase);
for i=1:nframe
   idx = IDX(i,:);
   z = B(idx,:) - repmat(X(i,:), knn, 1);           % shift ith pt to origin
   C = z*z';                                        % local covariance
   C = C + II*beta*trace(C);                        % regularlization (K>D)
   w = C\ones(knn,1);
   w = w/sum(w);                                    % enforce sum(w)=1
   Coeff(i,idx) = w';
end

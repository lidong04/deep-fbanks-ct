function [im, scale] = readImage(imagePath, resizing)
% READIMAGE   Read and standardize image
%    [IM, SCALE] = READIMAGE(IMAGEPATH) reads the specified image file,
%    converts the result to SINGLE class, and rescales the image
%    to have a maximum height of 480 pixels, returing the corresponding
%    scaling factor SCALE.
%
%    READIMAGE(IM) where IM is already an image applies only the
%    standardization to it.

% Author: Andrea Vedaldi

% Copyright (C) 2013 Andrea Vedaldi
% All rights reserved.
%
% This file is part of the VLFeat library and is made available under
% the terms of the BSD license (see the COPYING file).

if (nargin < 2)
  resizing = 0;
end

if ischar(imagePath)
  try
    im = imread(imagePath) ;
  catch
    error('Corrupted image %s', imagePath) ;
  end
else
  im = imagePath ;
end

im = im2single(im) ;

scale = 1;

if resizing > 0
  w = size(im, 2);
  h = size(im, 1);

  xc = uint16(w / 2);
  yc = uint16(h / 2);

  cropSz = min(w, h) - 1;

  left = max(1, uint16((w - cropSz) / 2));
  top = max(1, uint16((h - cropSz) / 2));

  im = imcrop(im, [left, top, cropSz, cropSz]);
  im = imresize(im, [resizing resizing]);
end

end

% if (size(im,1) > 480)
%   scale = 480 / size(im,1) ;
%   im = imresize(im, scale) ;
%   im = min(max(im,0),1) ;
% end


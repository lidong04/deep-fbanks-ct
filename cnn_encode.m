% -------------------------------------------------------------------------
function [code, area] = cnn_encode(im, regions, encoder)
% -------------------------------------------------------------------------
maxn = 500;
if ~isfield(encoder, 'numSpatialSubdivisions')
  encoder.numSpatialSubdivisions = 1 ;
end
switch encoder.type
%  case 'rcnn'
%    code_ = get_rcnn_features(encoder.net, ...
%      im, regions, ...
%      'regionBorder', encoder.regionBorder) ;
  case 'dcnn'
    gmm = [] ;
    if isfield(encoder, 'covariances'), gmm = encoder ; end
    if isfield(encoder, 'kdtree'), gmm = encoder ; end
    code_ = get_dcnn_features(encoder.net, ...
      im, regions, ...
      'encoder', gmm, ...
      'numSpatialSubdivisions', encoder.numSpatialSubdivisions, ...
      'maxNumLocalDescriptorsReturned', maxn) ;
  case 'dsift'
    gmm = [] ;
    if isfield(encoder, 'covariances'), gmm = encoder ; end
    if isfield(encoder, 'kdtree'), gmm = encoder ; end
    code_ = get_dcnn_features([], im, regions, ...
      'useSIFT', true, ...
      'encoder', gmm, ...
      'numSpatialSubdivisions', encoder.numSpatialSubdivisions, ...
      'maxNumLocalDescriptorsReturned', maxn) ;
end
code = code_ ;
area = regions.area ;

function test_one(use_cnn)

if nargin < 1
  use_cnn = 1;
% else
%   use_cnn = flag;
end

if use_cnn == 1
  encoderFile = '/home/lidong/deep-fbanks/data/test/dcnnfv-encoder.mat';
  svmFile = '/home/lidong/deep-fbanks/data/test/svm-param-cnn.mat';
else
  encoderFile = '/home/lidong/deep-fbanks/data/test/dsift-encoder.mat';
  svmFile = '/home/lidong/deep-fbanks/data/test/svm-param-sift.mat';
end

detector = detector_setup(encoderFile, svmFile);
fprintf('Detector setup finished.\n');

imgFile = '/home/lidong/deep-fbanks/data/test/slice.bmp';
regionFile = '/home/lidong/deep-fbanks/data/test/regions.bmp';

if ~exist(imgFile)
    fpritnf('input image is not fonund...exit.\n');
    return;
end
image = imread(imgFile);

regions = {};
if ~exist(regionFile)
  % full image as one region by default
  regions.basis = ones(size(image));
  regions.labels = {1};
  regions.area = prod(size(image));
  regions.segmentIndex = 1;
else
  regionBMP = imread(regionFile);
  [regions.basis, regions.area] = suppress_multi_regions(regionBMP(:,:,1));
  regions.labels = {1};
  regions.segmentIndex = 1;
end
    
% dtd = load('/home/lidong/deep-fbanks/data/test/dtd-classes.mat');
% detector.attr_classes = dtd.attr_classes;
% detector.threshold = 0.2;
% [attr_set, label] = texture_attributor(image, regions, detector);
% 
% for i=1:numel(attr_set)
%   fprintf('%s, %f\n', attr_set{i}.description{:}, attr_set{i}.belief);
% end
% 
% fprintf('\n');
% clear;

code = cnn_encode(image, regions, detector.encoder) ;
psi = cat(1, code{:});
pred = detector.w{1}'*psi + detector.b{1} ;
detector.threshold = 0.55;
if pred > detector.threshold
    fprintf('positive.\n');
else
    fprintf('negative.\n');
end

function [single_region_image, area] = suppress_multi_regions(image)
area = 0;
for row = 1:size(image,1)
  for col = 1:size(image,2)
    if image(row,col) == 0
      image(row,col) = 0;  
    else
      image(row,col) = 1;
      area = area + 1;
    end
  end
end

single_region_image = image;



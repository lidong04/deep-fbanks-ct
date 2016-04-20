function svm_train(use_cnn)

if nargin < 1
  use_cnn = 1;
% else
%   use_cnn = flag;
end

if use_cnn == 1
  encoderFile = '/home/lidong/deep-fbanks/data/test/dcnnfv-encoder.mat';
  svmFile = '/home/lidong/deep-fbanks/data/test/svm-param-cnn.mat';
  codeFile = '/home/lidong/deep-fbanks/data/test/dcnnfv-code.mat';
else
  encoderFile = '/home/lidong/deep-fbanks/data/test/dsift-encoder.mat';
  svmFile = '/home/lidong/deep-fbanks/data/test/svm-param-sift.mat';
  codeFile = '/home/lidong/deep-fbanks/data/test/dsift-code.mat';
end

detector = detector_setup(encoderFile, svmFile);
fprintf('Detector setup finished.\n');

imdb = get_image_database('/home/lidong/data/SVM_train/');
if exist(codeFile)
  load(codeFile, 'code', 'tag', 'valid') ;
else
  for i=1:numel(imdb.images.name)
    image = imread(imdb.images.name{i});
    reg = imread(imdb.regions.name{i});
    [regions.basis, regions.area] = suppress_multi_regions(reg(:,:,1));
    regions.labels = {1};
    regions.segmentIndex = 1;
    valid(i) = (regions.area > 0);
    if (~valid(i))
      fprintf('%d: empty region!\n', i);
      continue;
    end
    code(i) = cnn_encode(image, regions, detector.encoder) ;
    if imdb.images.label(i) == 1 % 'non-seed'
      tag(i) = -1;
    else
      tag(i) = 1;
    end
    fprintf('encoded %d / %d images.\n', i, numel(imdb.images.name));
  end
  code = code(:, valid);
  tag = tag(:, valid);
  savefast(codeFile, 'code', 'tag', 'valid');
end

psi = cat(2, code{:});
y = tag;

%psi = psi(:, imdb.regions.valid);
%y = y(:, imdb.regions.valid);

%start svm train.

train = ismember(imdb.images.set, [1 2]) ;
test = ismember(imdb.images.set, 3) ;

train = train(:, valid);
test = test(:, valid);

np = sum(y(train) > 0) ;
nn = sum(y(train) < 0) ;
n = np + nn ;

cols = (train & y ~= 0);
C = 1;
[w,b] = vl_svmtrain(psi(:, cols), y(:, cols), 1/(n* C), ...
    'epsilon', 0.001, 'verbose', 'biasMultiplier', 1, ...
    'maxNumIterations', n * 500) ;

pred = w'*psi + b ;

% try cheap calibration
mp = median(pred(train & y > 0)) ;
mn = median(pred(train & y < 0)) ;
b = (b - mn) / (mp - mn) ;
w = w / (mp - mn) ;
pred = w'*psi + b ;

%   [~,~,i]= vl_pr(y(train), pred(train)) ; 
%   [~,~,i]= vl_pr(y(test), pred(test)) ; 
%   [~,~,i]= vl_pr(y(train), pred(train), 'normalizeprior', 0.01) ; 
%   [~,~,i]= vl_pr(y(test), pred(test), 'normalizeprior', 0.01) ;  
[~,~,i]= vl_pr(y(train), pred(train)) ; ap = i.ap ; ap11 = i.ap_interp_11 ;
[~,~,i]= vl_pr(y(test), pred(test)) ; tap = i.ap ; tap11 = i.ap_interp_11 ;
[~,~,i]= vl_pr(y(train), pred(train), 'normalizeprior', 0.01) ; nap = i.ap ;
[~,~,i]= vl_pr(y(test), pred(test), 'normalizeprior', 0.01) ; tnap = i.ap ;

fprintf('Average Precision: train: %.1f, test: %.1f\n', ap*100, tap*100);
fprintf('Average Precision (normalized): train: %.1f, test: %.1f\n', nap*100, tnap*100);

svm_param.w = w;
svm_param.b = b;
save('data/exp01/dtd-seed-01/svm_w_b.mat', '-struct', 'svm_param');

fprintf('SVM trained and saved. \n');
clear;

function imdb = get_image_database(dataDir)
imdb.dataDir = dataDir;
cats = dir(dataDir) ;
cats = cats([cats.isdir] & ~ismember({cats.name}, {'.','..'})) ;
imdb.classes.name = {cats.name} ;
imdb.images.id = [] ;
imdb.sets = {'train', 'val', 'test'} ;

for c=1:numel(cats)
  ims = dir(fullfile(imdb.dataDir, imdb.classes.name{c}, '*grayscale.bmp'));
  imdb.images.name{c} = cellfun(@(S) fullfile(imdb.dataDir, imdb.classes.name{c}, S), ...
    {ims.name}, 'Uniform', 0);
  imdb.images.label{c} = c * ones(1,numel(ims)) ;
  rgs = dir(fullfile(imdb.dataDir, imdb.classes.name{c}, '*region.bmp'));
  imdb.regions.name{c} = cellfun(@(S) fullfile(imdb.dataDir, imdb.classes.name{c}, S), ...
    {rgs.name}, 'Uniform', 0);
end
imdb.images.name = horzcat(imdb.images.name{:}) ;
imdb.images.label = horzcat(imdb.images.label{:}) ;
imdb.images.id = 1:numel(imdb.images.name) ;
imdb.regions.name = horzcat(imdb.regions.name{:}) ;

randArray = rand(1, numel(imdb.images.name));
trainset = randArray < 0.6;
testset = randArray > 0.7;
valset = ~or(trainset, testset);
imdb.images.set(find(trainset)) = 1;
imdb.images.set(find(valset)) = 2;
imdb.images.set(find(testset)) = 3;

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



function detector = detector_setup(encoderFile, svmFile)
% DETECTOR_SETUP setup detector with pre-trained FV-CNN encoder and SVM.
if ~exist(encoderFile) || ~exist(svmFile)
    fprintf('Pre-trained file is missing, please check(encoder/svm).\n');
    fprintf('Use default pre-trained files instead.\n');
end

%sole encoder dcnn-fv

%opts.netFile = 'data/test/imagenet-vgg-m.mat';
opts.encoderFile = 'data/test/dcnnfv-encoder.mat';
opts.svmFile = 'data/test/svm-param-cnn.mat';

%if exist(netFile)  opts.netFile = netFile; end
if exist(encoderFile)  opts.encoderFile = encoderFile; end
if exist(svmFile)  opts.svmFile = svmFile; end

opts.useGpu = true ;
opts.gpuId = 1;
%[opts, varargin] = vl_argparse(opts,varargin) ;
if opts.useGpu
  gpuDevice(opts.gpuId) ;
end

%FIXME: don't need?
%net = load(netFile);

encoder = load(encoderFile) ;
if isfield(encoder, 'net')
    if opts.useGpu
        encoder.net = vl_simplenn_move(encoder.net, 'gpu') ;
        encoder.net.useGpu = true ;
    else
        encoder.net = vl_simplenn_move(encoder.net, 'cpu') ;
        encoder.net.useGpu = false ;
    end
end

%info.classes = find(imdb.meta.inUse) ;
svm_param = load(svmFile);
classes = numel(svm_param.b);
w = {} ;
b = {} ;
for c=1:numel(classes)
    w{c} = svm_param.w(:,c);
    b{c} = svm_param.b(:,c);
end

detector.encoder = encoder;
detector.w = w;
detector.b = b;

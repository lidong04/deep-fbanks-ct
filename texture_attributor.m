function [attr_set, label] = texture_attributor(image, regions, detector)
% TEXTURE_ATTRIBUTOR Get (multiple) texture labels for image/region with 
%   pre-trained FV-CNN encoder and SVM.

[code, area] = cnn_encode(image, regions, detector.encoder) ;
psi = cat(1, code{:});
%imdb.segments.area = area;

num_classes = size(detector.attr_classes, 2);
idx = 0;
res_set={};
for c=1:num_classes
  pred = detector.w{c}'*psi + detector.b{c} ;
  if pred > detector.threshold
    res_label(c) = true;
    idx = idx + 1;
    attr.description = detector.attr_classes(c);
    attr.belief = pred;
    res_set{idx} = attr;
  else
    res_label(c) = false;
  end
end

label = res_label;
attr_set = res_set;


function imdb = setupDTD(datasetDir, varargin)
% SETUPDTD    Setup Describable Textures Dataset
%    This is similar to SETUPCALTECH101(), with modifications to setup
%    the Describable Textures Dataset accroding to the standard
%    evaluation protocols.
%
%    See: SETUPCALTECH101().

% Author: Andrea Vedaldi

% Copyright (C) 2013 Andrea Vedaldi
% All rights reserved.
%
% This file is part of the VLFeat library and is made available under
% the terms of the BSD license (see the COPYING file).

  opts.lite = false ;
  opts.autoDownload = true ;
  opts.seed = 1;
  opts.keyOnly = true;
  opts = vl_argparse(opts, varargin) ;


  % Download and unpack
  vl_xmkdir(datasetDir) ;
  if exist(fullfile(datasetDir, 'dtd', 'images', 'zigzagged', ''), 'dir')
    % ok
  elseif opts.autoDownload
    url = 'http://www.robots.ox.ac.uk/~vgg/data/dtd/download/dtd-r1.0.1.tar.gz' ;
    fprintf('Downloading DTD data to ''%s''. This will take a while.', datasetDir) ;
    % Move manually to
    untar(url, datasetDir);
  else
    error('DTD not found in %s', datasetDir) ;
  end

  datasetDir = fullfile(datasetDir, 'dtd');

  imdb.images.id = [] ;
  imdb.images.set = uint8([]) ;
  imdb.images.name = {} ;
  imdb.images.size = zeros(2,0) ;
  imdb.meta.sets = {'train', 'val', 'test'} ;


  % load classes
  fid = fopen(fullfile(datasetDir, 'labels', 'classes.txt'));
  if (fid > 0)
    imdb.meta.classes = textscan(fid, '%s', 'Delimiter', '\n');
    imdb.meta.classes = imdb.meta.classes{1}';
    fclose(fid);

    for ci = 1:length(imdb.meta.classes)
      imdb.classes.imageIds{ci} = [];
      imdb.classes.difficult{ci} = false(0);
    end
  end

  imdb = setupGeneric(fullfile(datasetDir, 'images'), ...
      'numTrain', 40, 'numVal', 40, 'numTest', Inf,  ...
      'expectedNumClasses', 47, 'seed', opts.seed) ;

  if (~opts.keyOnly)
    fid = fopen(fullfile(datasetDir, 'labels', 'labels.txt'));
    if (fid > 0)
      lines = textscan(fid, '%s', 'Delimiter', '\n');
      lines = lines{1};
      imdb.images.id = 1 : numel(lines);
      for ii = 1 : numel(lines)
        parts = regexp(lines{ii}, ' ', 'split');
        img_labels = parts(2:end);
        img_labels = img_labels(strcmp(img_labels, '') == 0);
        imdb.images.name{ii} = parts{1};

        for jj = 1 : numel(img_labels)
          ci = find(strcmp(imdb.meta.classes, img_labels{jj}));
          imdb.classes.imageIds{ci}(end + 1) = ii;
          imdb.classes.difficult{ci}(end + 1) = false;
        end
      end
      fclose(fid);
    else
      assert(false, 'labels.txt was not found\n');
    end
  end

  % split into train, test, val
  for si = 1:numel(imdb.meta.sets)
    annoPath = fullfile(datasetDir, 'labels', sprintf('%s%d.txt', ...
      imdb.meta.sets{si}, opts.seed));
    fprintf('%s: reading %s\n', mfilename, annoPath);
    fid = fopen(annoPath);
    if (fid > 0)
      lines = textscan(fid, '%s');
      lines = lines{1};
      for ii = 1 : numel(lines)
        imdb.images.set(strcmp(imdb.images.name, lines{ii})) = si;
      end
      fclose(fid);
    else
      assert(false, sprintf('%s%d.txt was not found', imdb.meta.sets{si}, ...
        opts.seed));
    end
  end


  imdb.imageDir = fullfile(datasetDir, 'images');
  if opts.lite
    ok = {} ;

    if (~opts.keyOnly)
      for c = 1:3
        trainIds = intersect(imdb.images.id(imdb.images.set == 1), imdb.classes.imageIds{c});
        testIds = intersect(imdb.images.id(imdb.images.set == 3), imdb.classes.imageIds{c});

        ok{end+1} = vl_colsubset(find(ismember(imdb.images.id, trainIds)), 5);
        ok{end+1} = vl_colsubset(find(ismember(imdb.images.id, testIds)), 5);
      end
      ok = unique(cat(2, ok{:}));
      imdb.meta.classes = imdb.meta.classes(1:3);
      imdb.classes.imageIds = imdb.classes.imageIds(1:3);
      imdb.classes.difficult = imdb.classes.difficult(1:3) ;
      imdb.images.id = imdb.images.id(ok);
      imdb.images.name = imdb.images.name(ok);
      imdb.images.set = imdb.images.set(ok);
      for c = 1:3
        ok = ismember(imdb.classes.imageIds{c}, imdb.images.id);
        imdb.classes.imageIds{c} = imdb.classes.imageIds{c}(ok);
        imdb.classes.difficult{c} = imdb.classes.difficult{c}(ok);
      end
    else
      ok = {} ;
      for c = 1:3
        ok{end+1} = vl_colsubset(find(imdb.images.class == c & imdb.images.set == 1), 5) ;
        ok{end+1} = vl_colsubset(find(imdb.images.class == c & imdb.images.set == 2), 5) ;
        ok{end+1} = vl_colsubset(find(imdb.images.class == c & imdb.images.set == 3), 5) ;
      end
      ok = cat(2, ok{:}) ;
      imdb.meta.classes = imdb.meta.classes(1:3) ;
      imdb.images.id = imdb.images.id(ok) ;
      imdb.images.name = imdb.images.name(ok) ;
      imdb.images.set = imdb.images.set(ok) ;
      imdb.images.class = imdb.images.class(ok) ;
    end
  end

end


# Describing textures in the wild


The code provided runs the evaluation of IFV SIFT, VLAD, BoVW, (LLC, KCB and
DeCAF) on various texture and material datasets (CUReT, UMD, UIUC, KTH, KTH-TIPS
2a and 2b, as well as FMD and DTD). The results of these experiments are contained in Table 2 in the paper, ** Describing textures in the wild, M. Cimpoi et al., CVPR 2014. ** 

Once you have downloaded the code and datasets, simply run the `texture_experiments.m` file. The results are also saved in a `report.html` file, in the current location.

In `texture_experiments.m` you could remove (or add) dataset names to the
`datasetList` cell. Make sure you adjust the `numSplits` accordingly.
You could also change `encTypes` cell, to select only the experiments you need.

##   Getting starded

### Paths and datasets

The `setup<dataset`>.m` files download the datasets automatically, except for ALOT
dataset, which is about 4.5 GB, and we advise downloading manually.

The datasets are stored in individual folders under data, in the current code
folder, and experiment results are stored in experiments folder, in the same
location as the code. Alternatively, you could make data and experiments
symbolic links pointing to convenient locations.

Please be aware that the descriptors are stored on disk (in cache folder, under
`experiments/<experiment-dir>`), and may require some space (about 8GB for
the 10 splits, in case of DTD, for IFV only).


### Dependencies

The code relies on [vlfeat](http://www.vlfeat.org/), which should be in the path
before running the experiments.

For LLC and KCB features, please download the code from [http://www.robots.ox.ac.uk/~vgg/software/enceval_toolkit](http://www.robots.ox.ac.uk/~vgg/software/enceval_toolkit) and copy the following to the code folder (no subfolders!)

* `enceval/enceval-toolkit/+featpipem/+lib/KCBEncode.m`
* `enceval/enceval-toolkit/+featpipem/+lib/LLCEncode.m`
* `enceval/enceval-toolkit/+featpipem/+lib/LLCEncodeHelper.cpp`
* `enceval/enceval-toolkit/+featpipem/+lib/annkmeans.m`

Then add `llc10k`, and `kcb10k` to the list in `encTypes`.


### Dataset and evaluation

Describable Textures Dataset (DTD) is publicly available for download at:
[http://www.robots.ox.ac.uk/~vgg/data/dtd](http://www.robots.ox.ac.uk/~vgg/data/dtd). You can also download the  precomputed DeCAF features for DTD, the paper and evaluation results.

###   Citation

If you use the code and data please cite the following in your work:

	@inproceedings{cimpoi14describing,
  	Author    = {M. Cimpoi and S. Maji and I. Kokkinos and S. Mohamed and A. Vedaldi},
  	Title     = {Describing Textures in the Wild},
  	Booktitle = {Proceedings of the {IEEE} Conf. on Computer Vision and Pattern Recognition ({CVPR})},
  	Year      = {2014}}
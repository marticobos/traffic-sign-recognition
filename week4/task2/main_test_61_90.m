% Task 2: Template matching using Distance Transform and chamfer distance
tic
do_plots = true;
do_plots = false;

% Add repository functions to path
addpath(genpath('..'));

% Set paths (JON)
dataset = 'test';
root = '../../../';
inputMasksPath = fullfile(root, 'datasets', 'trafficsigns', 'm1', dataset);
groundThruthPath = fullfile(root, 'datasets', 'trafficsigns', 'split', dataset, 'mask');

% Set paths (Ferran)
% inputMasksPath = fullfile(root, 'm1-results', 'week3', 'm1', dataset);
%groundThruthPath = fullfile(root, 'datasets', 'trafficsigns', 'split', dataset, 'mask');
% groundThruthPath = fullfile(root, 'datasets', 'trafficsigns', dataset, 'mask');

tmpPath =  fullfile(root, 'datasets', 'trafficsigns', 'tmp2', dataset);
mkdir(tmpPath)

% Get all the files
inputMasks = dir(fullfile(inputMasksPath, '*.png'));
gtMasks = dir(fullfile(groundThruthPath, '*.png'));

% Load templates (circularModel, downTriangModel, rectModel, upTriangModel)
models_task1 = load('/home/jon/mcv_repos/team4/week4/task1/templateModels.mat');
models = zeros(40,40,4);
% consider_a_pixel_from_a_model_if_greater_than
th = 0.7;                                             %%%% HYPER-PARAMETER
models(:,:,1) = models_task1.circularModel > th;
models(:,:,2) = models_task1.downTriangModel > th;
models(:,:,3) = models_task1.rectModel > th;
models(:,:,4) = models_task1.upTriangModel > th;

% original scale is 40x40
scales = 1:0.5:5;

% For each mask
% for i = 1:size(inputMasks,1)
for i = 61:90
  tic
  % Load image
  inputMaskObject = inputMasks(i);
  sprintf('Checking mask %d: %s/%s', i, inputMasksPath, inputMaskObject.name)
  inputMaskPath = fullfile(inputMasksPath, inputMaskObject.name);
  iMask = imread(inputMaskPath);

  % Load ground thruth (comment it out when not validating)
  if ~strcmp(dataset,'test')
    gtMaskObject = gtMasks(i);
    gtMaskPath = fullfile(groundThruthPath, gtMaskObject.name);
    gtMask = imread(gtMaskPath);
    gtMask = gtMask > 0; % Convert it to logical (faster)
    do_plot = false;
  end

  % For each model
  regionsAll = zeros(0, 4);
  cancellingMaskComplete = false(size(iMask));
  for t = 1:size(models,3)
    % If there is nothing skip step
    if isnan(sum(iMask(:))) | sum(iMask(:)) == 0
      continue
    end

    modelOriginal = models(:,:,t);

    for scale = 1:size(scales,2)
      model = imresize(modelOriginal, scales(scale)) > th;
      modelSize = size(model);

      % Add a border to avoid losing contours when filtering
      template = padarray(model, [1,1], 0, 'both');
      featureMask = edge(iMask,'Canny');
      template = edge(template, 'Canny')+0;

      % Add padding to avoid contour effects when doing correlation
      paddedMask = padarray(featureMask, size(template)/2, 0, 'both');

      % Distance Transform the feature mask
      transformedMask = distanceTransform(paddedMask);

      % Do pattern matching with the mask and a template
      correlated = xcorr2(transformedMask, template);
      % correlated = normxcorr2(transformedMask, template);

      % Remove additional padding added before
      border = size(template,1);
      correlated = correlated(border:(end-border), border:(end-border));

      % Normalize result
      correlated = correlated./max(correlated(:));

      % Find local minimas using 8-connected neighbourhood
      minimasMask = imregionalmin(correlated ,8);
      [posy, posx] = find(minimasMask==1);

      % Filter out 'not-enough-minima'
      values = correlated(minimasMask==1);
      goodEnough = values < 3e-3;                        %%%% HYPER-PARAMETER
      posy = posy(goodEnough==1);
      posx = posx(goodEnough==1);

      % Extract bounding boxes
      regions = zeros(size(posy,1), 4);
      for position = 1:size(posy,1)
        regions(position,:) = [posy(position) - 0.5*modelSize(1), ...
                        posx(position) - 0.5*modelSize(2), ...
                        modelSize(1), ...
                        modelSize(2)];
      end % for each position

      % Compute a binary image of detections ('1' where a signal surface is detected)
      cancellingMask = false(size(iMask));
      for position = 1:size(posy)
        cancellingMask(posy(position), posx(position)) = true;
      end % for each position
      cancellingMask = imdilate(cancellingMask, logical(imresize(model,1.5)));
      cancellingMaskComplete = cancellingMaskComplete | cancellingMask;

      % Update regions for this mask
      numOfRegionsSaved = size(regionsAll,1);
      numOfRegionsFound = size(regions,1);
      regionsAll((numOfRegionsSaved+1):(numOfRegionsSaved+numOfRegionsFound), :) = regions;
    end % for each scale
  end  % for each model

  % Save mask
  oMaskPath = fullfile(tmpPath, inputMaskObject.name);
  sprintf('Writing in %s', oMaskPath)
  oMask = iMask & cancellingMaskComplete;
  %imshow(cancellingMaskComplete,[])
  imwrite(oMask, oMaskPath);

  % Save regions
  name = strsplit(inputMaskObject.name, '.png');
  name = name{1};
  region_path = fullfile(tmpPath, strcat(name, '.mat'));
  % windowCandidates = struct('x',[],'y',[], 'w', [], 'h', []);
  % for region = 1:size(regionsAll)
  %   r = regionsAll(region,:);
  %   windowCandidates(region).y = r(1);
  %   windowCandidates(region).x = r(2);
  %   windowCandidates(region).w = r(3);
  %   windowCandidates(region).h = r(4);
  % end % for each region
  % sprintf('Writing in %s, %d candidates', region_path, size(windowCandidates,1))
  % save(region_path, 'windowCandidates');

  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % SAVE REGIONS 2
  name = strsplit(inputMaskObject.name, '.png');
  name = name{1};
  region_path = fullfile(tmpPath, strcat(name, '.mat'));
  % Allocate outputs and check if any CC have been detected
  windowCandidates = struct([]);
  % Compute new CCs for 'constrainedMask'
  CC_constrMask = bwconncomp(oMask);
  CC_constrMask_stats = regionprops(CC_constrMask, 'BoundingBox');
  % Generate output structure (I cannot think of a method w/o for loop..)
  [windowCandidates] = createListOfWindows(CC_constrMask_stats);
  % Only the CC with indices in the outIdx are believed to be signals
  sprintf('Writing in %s, %d candidates', region_path, size(windowCandidates,1))
  save(region_path, 'windowCandidates');


  if do_plots
    figure(1)
    % figure('Name',sprintf('Mask %d', i));
    % Show input mask
    subplot(2,3,1);
    imshow(featureMask,[]);
    title('Feature mask');

    % Show transformed
    subplot(2,3,2);
    imshow(transformedMask,[]);
    title('distance transformed');
    %plot = false

    % Show output mask
    subplot(2,3,3);
    imshow(template,[]);
    title('template');
    % axis([1, size(featureMask,1), 1, size(featureMask,2)]);

    % Show ground truth mask
    subplot(2,3,4);
    imshow(gtMask,[]);
    title('GroundTruth mask');

    % Show ground truth mask
    subplot(2,3,5);
    imshow(correlated,[]);
    title('correlated mask');

    % Show ground truth mask
    subplot(2,3,6);
    imshow(correlated*256,hsv(256));
    title('correlated mask with pseudo-colour');

    % FIGURE 2
    figure(2)
    subplot(1,3,1);
    imshow(iMask, []);
    title('Input mask')

    subplot(1,3,2);
    imshow(cancellingMaskComplete, []);
    title('detection mask')

    subplot(1,3,3);
    imshow(oMask, []);
    title('Output mask')
  end % if do_plot
  toc
end % for each  mask
toc

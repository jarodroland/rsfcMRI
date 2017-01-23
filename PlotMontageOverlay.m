function figHandle = PlotMontageOverlay(anatData, funcData, varargin)
% figHandle = PlotMontageOveraly(anatData, funcData, varargin) 
% 
% Description:
%   Plots a montage of functional maps (funcData) overlaid on an anatomic image (anatData).
%   Various parameters for controlling layout of image slices, colormap, alpha blending,  
%   thresholding, etc, are passed as name-value parameter pairs. 
%   Format for anatData and functData is the same as returned from my Read4dfp() function, 
%   which is a 3D matrix [x, y, z] of intensity values.
%   The figure handle is returned.
%   Due to the way the overlay is added ontop of the anatomic image, the colormap must be 
%   set via parameters to the function. Trying to adjust the colormap with the returned 
%   figure handle will not work.
%
% Usage:
%   >> figMontage = PlotMontageOverlay(anatData, funcData);
%   >> figMeanPartialPost = PlotMontageOverlay(atlasData, meanHomoPartialPost, 'funcColorMap', newCMap, 'inMin', -totMax, 'inMax', totMax, 'cBarMin', -totMax, 'cBarMax', totMax, 'funcThreshold', 0.0, 'isKeepNegative', true, 'alphaOverlay', alpha, 'isShowColormap', true, 'sliceList', [9, 20, 24, 39], 'layout', [2 2]);
%
% Output:
%   figHandle - figure handle of the created image
%   
% Required Parameters:
%   anatData - The anatomic image to serves as underlay
%   funcData - The functional data to be overlaid on the anatomic image (must be same size as anatData)
%
% Optional Parameters:
%   layout - 1x2 matrix of the form [rows, columns] defining a 2-dimensional grid layout. e.g. [4, 12] yields 4-rows and 12 columns
%   funcColorMap - nx3 matrix with RGB color values. Must be valid input to colormap()
%   inMin - scalar value to force the expected minimum value of the input data space
%   inMax - scalar value to force the expected maximum value of the input data space
%   cBarMin - scalar value to force the minimum value of the colorbar
%   cBarMax - scalar value to force the maximum value of the colorbar
%   alphaOverlay - scalar fraction from [0, 1] for alpha blending of functional data overlay. Set to 1.0 (default) for no blending.
%   isKeepNegative - boolean value indicating only plot only positive funcData (true) or all positive/negative data (false | default)
%   isShowColormap - boolean value indicating whether to display the colorbar (default is false)
%   funcThreshold - scalar value used to threshold the funcData before plotting. If isKeepNegative = true, then abs(funcData) is used for threshold.
%   sliceList - list of image slices to plot. e.g, [9, 20, 24, 39] plots slices 9, 20, 34, and 39 in that order. Overrides sliceStart/sliceStop/sliceSkip
%   sliceStart - scalar index of slice at which to begin plotting
%   sliceStop - scalar index of slice at which to stop plotting
%   sliceStart - scalar value of number of slices to skip between adjacent slices to plot
%   
% Author:
%   Jarod L Roland
%   Department of Neurosurgery
%   Washington University in St. Louis
%
params = inputParser;
addRequired(params, 'anatData', @(x) true);
addRequired(params, 'funcData', @(x) true);
addParameter(params, 'layout', [4 12], @(x) (size(x, 1) == 1) & (size(x, 2) == 2));
addParameter(params, 'funcColorMap', 'jet', @(x) true);
addParameter(params, 'inMin', min(min(min(funcData))), @isnumeric);
addParameter(params, 'inMax', max(max(max(funcData))), @isnumeric);
addParameter(params, 'cBarMin', min(min(min(funcData))), @isnumeric);
addParameter(params, 'cBarMax', max(max(max(funcData))), @isnumeric);
addParameter(params, 'alphaOverlay', 1.0, @isnumeric);
addParameter(params, 'isKeepNegative', false, @islogical);
addParameter(params, 'isShowColormap', false, @islogical);
addParameter(params, 'funcThreshold', 0.0, @isnumeric);     % keep everything above threshold (or abs(threshold) if isKeepNegative = true)
addParameter(params, 'sliceList', [], @(x) (size(x, 1) == 1) & (ndims(x) <= 2));
addParameter(params, 'sliceStart', 1, @isnumeric);
addParameter(params, 'sliceStop', size(anatData, 3), @isnumeric);
addParameter(params, 'sliceSkip', 1, @isnumeric);
parse(params, anatData, funcData, varargin{:});

% set variables
inMin = params.Results.inMin;%0.0;
inMax = params.Results.inMax;%1.0;
cBarMin = params.Results.cBarMin;%-1.0;
cBarMax = params.Results.cBarMax;%1.0;
alphaOverlay = params.Results.alphaOverlay;%1.0;
funcThreshold = params.Results.funcThreshold;%0.2;%16;%
layout = params.Results.layout;%[4 12];%[6 8];%[2 6];%
isKeepNegative = params.Results.isKeepNegative;%false;%
isShowColormap = params.Results.isShowColormap;%false;%
funcColorMap = params.Results.funcColorMap;%'jet';%[1 0 0];%

sliceList = params.Results.sliceList;
sliceStart = params.Results.sliceStart;%1;%
sliceStop  = params.Results.sliceStop;%size(anatData, 3); 
sliceSkip  = params.Results.sliceSkip;%1;%
if(isempty(sliceList))
    sliceList = sliceStart:sliceSkip:sliceStop;
end

figHandle = figure();

% rotate data to row-major from column-major for display
anatData = permute(anatData, [2 1 3]);
funcData = permute(funcData, [2 1 3]);

% plot anatomy montage
anatData = TransformImageForMontage(anatData, 'isScale', true, 'outMin', 1, 'outMax', 100);  % (x, y, z) => (x, y, 1, z)
anatImg = montage(anatData(:, :, :, sliceList), colormap('gray'), 'Size', layout);
anatCData = round( get(anatImg, 'CData') );     % round to make integer index
anatRGB = ind2rgb(anatCData, colormap());

% apply threshold and render functional overlay
% fprintf( 'Min=%1.2f Mean=%1.2f Max=%1.2f\n', min(min(min(funcData))), mean(mean(mean(funcData))), max(max(max(funcData))) );
if(isKeepNegative)
    funcData(abs(funcData) < funcThreshold) = 0;
else
    funcData(funcData < funcThreshold) = 0;
end
funcMask = logical(funcData);

cMap = colormap(funcColorMap);
% symmetricCBar = true;

% % color bar used in the CC homotopic connectivity plots
% totMax = 1.2;
% colorMax = 0.5;
% colorStepSize = (colorMax * 2) / length(cMap);
% colorNumStep = round(totMax / colorStepSize);
% newCMap = zeros(colorNumStep * 2, 3);
% midCMap = round(length(cMap)/2);
% newCMap(1:(colorNumStep - midCMap), :) = repmat(cMap(1, :), (colorNumStep - midCMap), 1);
% newCMap((colorNumStep - midCMap + 1):colorNumStep, :) = cMap(1:midCMap, :);
% newCMap(colorNumStep+1:(colorNumStep + midCMap), :) = cMap(midCMap+1:end, :);
% newCMap((colorNumStep + midCMap + 1):end, :) = repmat(cMap(end, :), ((colorNumStep * 2) - (colorNumStep + midCMap)), 1);

funcData = TransformImageForMontage(funcData, 'isScale', true, 'inMin', inMin, 'inMax', inMax, 'outMin', 1, 'outMax', length(cMap));
% funcData = TransformImageForMontage(funcData, 'isScale', true, 'inMin', -totMax, 'inMax', totMax, 'outMin', 2, 'outMax', length(cMap)-1);     % used for Homotopic maps
% funcData = TransformImageForMontage(funcData, 'isScale', true, 'outMin', 0, 'outMax', length(cMap));
funcImg = montage(funcData(:, :, :, sliceList), cMap, 'Size', layout); %colormap('white')
funcCData = round( get(funcImg, 'CData') );
funcRGB = ind2rgb(funcCData, colormap());
funcFig = gcf();
funcCMap = funcFig.Colormap;

% create an alpha mask for the functional overlay
funcMask = TransformImageForMontage(funcMask);
% funcMask(1) = 0;
funcMaskImg = montage(funcMask(:, :, :, sliceList), colormap('gray'), 'Size', layout);
funcMaskCData = round( get(funcMaskImg, 'CData') );
funcMaskCData = funcMaskCData .* alphaOverlay;
% funcMaskCData = funcMaskCData .* funcCData;       % TODO: alpha mask by image intensity

% show the anatomy, functional, and alpha mask
imshow(anatRGB);
hold on;
funcImg = imshow(funcRGB);
colormap(funcCMap);         % apply colormap from functional plot

% caxis([funcMin funcMax]);
% caxis([-cBarMin cBarMax]);
caxis([cBarMin cBarMax]);
if(isShowColormap), colorbar(); end
set(funcImg, 'AlphaData', funcMaskCData);
set(funcImg, 'AlphaDataMapping', 'none');

return


function outImage = TransformImageForMontage(inImage, varargin)
% arrange the image data in the format that the montage() function expects
% i.e. array(x, y, 1, z)
params = inputParser;
addRequired(params, 'inImage', @(x) true);
addParameter(params, 'inMin', min(min(min(inImage))), @isnumeric);
addParameter(params, 'inMax', max(max(max(inImage))), @isnumeric);
addParameter(params, 'outMin', 1, @isnumeric);
addParameter(params, 'outMax', 64, @isnumeric);
addParameter(params, 'isScale', false, @islogical);
parse(params, inImage, varargin{:});

inImage = params.Results.inImage;
imageMin = params.Results.inMin; %min(min(min(inImage)));
imageMax = params.Results.inMax; %max(max(max(inImage)));
outMin = params.Results.outMin; %1;
outMax = params.Results.outMax; %100);
isScale = params.Results.isScale; % false;
if(imageMin == imageMax)
    imageMin = 0;
    if(imageMax == 0)
        imageMax = 1;
    end
end

% re-size to comply with montage format
imageSize = size(inImage);
inImage = reshape(inImage, [imageSize(1) imageSize(2) 1 imageSize(3)]);

if(isScale)
    % re-scale image data
    scaleFactor = (outMax - outMin) / (imageMax - imageMin);
    outImage = (inImage - imageMin) .* scaleFactor + outMin;
else
    outImage = inImage;
end

return 
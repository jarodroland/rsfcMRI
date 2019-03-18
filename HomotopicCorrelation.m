function zfrmWholeMask = HomotopicCorrelation(inDir, patid, varargin)
% zfrmWholeMask = HomotopicCorrelation(inDir, patid, varargin) 
% 
% Description:
%   Computes the Voxel-Mirrored Homotopic Connectivity
%
% Usage:
%   >> zfrmWholeMask = HomotopicCorrelation(inDir, patid);
%   >> zfrmWholeMask = HomotopicCorrelation('study_folder/PAT01/pre/', 'PAT01_pre');
%
% Output:
%   zfrmWholeMask - Fisher Z transformed VMHC volume data (NB: data is symmetric about mid-sagital plane)
%   
% Required Parameters:
%   inDir - Path to this specific subject's data
%   patid - The subject ID, including session if applicable (e.g. PAT01, or PAT01_pre)
%
% Optional Parameters:
%   fcDir - Directory within inDir of the Functional Connectivity data output from 4dfp suite (e.g. 'FCdir')
%   isPlotFig - Boolean flag for figure plotting
%   cBarMax - Value for +/- max vmhc value (Fisher Z) of color bar in figure
% 
%   
% Author:
%   Jarod L Roland
%   Department of Neurosurgery
%   Washington University School of Medicine in St. Louis
%
%% Parse parameters
params = inputParser;
addRequired(params, 'inDir', @(x) (exist(x, 'dir') == 7));
addRequired(params, 'patid', @(x) true);
addParameter(params, 'fcDir', 'FCmaps', @(x) (exist(fullfile(inDir, x), 'dir') == 7)); %fcDir is only used for the vals and dfndm, not for voxel data
addParameter(params, 'isPlotFig', false, @islogical);
addParameter(params, 'cBarMax', 1.2, @isnumeric);
parse(params, inDir, patid, varargin{:});

% set variables
inDir = params.Results.inDir;
patid = params.Results.patid;
fcDir = params.Results.fcDir;
isPlotFig = params.Results.isPlotFig;
cBarMax = params.Results.cBarMax;


%% Data defs
dvarLimit = 5.0;     % movement scrubbing threshold (ref: Power et al 2011)

% paths to data files
mprFilename     = fullfile(inDir, 'atlas', [patid '_mpr1_on_pre_CC_t2w_333.4dfp.img']);
brs1Filename    = fullfile(inDir, 'boldrs1', [patid '_brs1_faln_dbnd_xr3d_atl_g7_bpss_resid.4dfp.img']);
brs2Filename    = fullfile(inDir, 'boldrs2', [patid '_brs2_faln_dbnd_xr3d_atl_g7_bpss_resid.4dfp.img']);
% formatFilename  = fullfile(fcDir, [patid '_faln_dbnd_xr3d_atl_g7_bpss_resid.format']);
dvarsFilename   = fullfile(inDir, fcDir, [patid '_faln_dbnd_xr3d_atl_g7_bpss_resid.vals']);
maskFilename    = fullfile(inDir, fcDir, [patid '_faln_dbnd_xr3d_atl_dfndm.4dfp.img']);

%% Process Data
maskData = Read4dfp(maskFilename);
brs1Data = Read4dfp(brs1Filename);
if(exist(brs2Filename, 'file') == 2)
    brs2Data = Read4dfp(brs2Filename);
else
    brs2Data = [];
    disp(['No 2nd bold run available for ' patid]);
end
brsCatData = cat(4, brs1Data, brs2Data);

imgSpace = [48, 64, 48];        %MAGICNUMBER: assume data is in 333 space
sizeX = size(brsCatData, 1);
sizeY = size(brsCatData, 2);
sizeZ = size(brsCatData, 3);
% numFrames = size(brsCatData, 4);
assert(all([sizeX, sizeY, sizeZ] == imgSpace), 'Error: brsData is not in 3x3x3 space');

% read in dvars
hFileDvar = fopen(dvarsFilename);
dvars = textscan(hFileDvar, '');
dvars = dvars{1};
fclose(hFileDvar);

% make sure dVars and frames are same length
numDvars = size(dvars, 1);
numBoldFrames = size(brs1Data, 4) + (~isempty(brs2Data) * size(brs2Data, 4));
assert(numDvars == numBoldFrames, ['Error: Mismatch between number of dVars (' num2str(numDvars) ') and BOLD frames (' num2str(numBoldFrames) ')']);

% scrub frames by dVar
scrubMask = dvars < dvarLimit;
brsCatDataScrubbed = brsCatData(:, :, :, scrubMask);
numGoodFrames = size(brsCatDataScrubbed, 4);

%% Voxel Mirrored Homotopic Connectivity (VMHC)
% corelattion between signal from right & left homotopic voxel pairs
% brsCatDataScrubbed(24:25, :, :, :) = 0;
rightHemi = brsCatDataScrubbed(1:floor(sizeX / 2), :, :, :);
leftHemi = flip( brsCatDataScrubbed(floor(sizeX / 2) + 1:end, :, :, :), 1 );
assert(size(rightHemi, 1) == size(leftHemi, 1), 'Error: Unequal size hemispheres');

numVox = size(rightHemi, 1) * size(rightHemi, 2) * size(rightHemi, 3);
rightHemiVec = reshape(rightHemi, numVox, numGoodFrames);
leftHemiVec = reshape(leftHemi, numVox, numGoodFrames);

corrCoef = zeros(1, numVox);
parfor i = 1:numVox %for
    corrCoef(i) = corr(rightHemiVec(i, :)', leftHemiVec(i, :)');
end

corrCoef(isnan(corrCoef)) = 0;  % Note: Not sure why a NaN shows up for voxel 3194 due to a nearly zero signal in rightHemiVec at that vertex

corrCoefHemi = reshape(corrCoef, size(rightHemi, 1), size(rightHemi, 2), size(rightHemi, 3));
corrCoefWhole = cat(1, corrCoefHemi, flip(corrCoefHemi, 1));
corrCoefWholeMask = corrCoefWhole .* maskData;
zfrmWholeMask = atanh(corrCoefWholeMask);

%% Plot
if(isPlotFig)
    mprData = Read4dfp(mprFilename);

    % create a color bar with Jet in the middle and plateua at +/- colorMax
    colorMax = 0.5;
    cMap = jet(64);         % start from jet colormap and modify (default colormap is 64 long)
    colorStepSize = (colorMax * 2) / length(cMap);
    colorNumStep = round(cBarMax / colorStepSize);
    newCMap = zeros(colorNumStep * 2, 3);
    midCMap = round(length(cMap)/2);
    newCMap(1:(colorNumStep - midCMap), :) = repmat(cMap(1, :), (colorNumStep - midCMap), 1);
    newCMap((colorNumStep - midCMap + 1):colorNumStep, :) = cMap(1:midCMap, :);
    newCMap(colorNumStep+1:(colorNumStep + midCMap), :) = cMap(midCMap+1:end, :);
    newCMap((colorNumStep + midCMap + 1):end, :) = repmat(cMap(end, :), ((colorNumStep * 2) - (colorNumStep + midCMap)), 1);

    % plot montage
    PlotMontageOverlay(mprData, zfrmWholeMask, 'funcColorMap', newCMap, 'inMin', -cBarMax, 'inMax', cBarMax, 'cBarMin', -cBarMax, 'cBarMax', cBarMax, 'funcThreshold', 0.0, 'isKeepNegative', true, 'isShowColormap', true);

    % beautify figure
    title(strrep(patid, '_', '\_'))

end %if flags.plotfigure


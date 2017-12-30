function figDvarsComplete = PlotDVars(studyPath)
% PlotDVars(subjectDirectory)
% 
% Description:
%   Plots the DVars from the .vals file.
%   If a directory is passed, then it is searhced for a single .vals file, or for an FCmaps directory containing a single .vals file.
%   
% Usage:
%   >> PlotDVars('C:\path\to\subj001\FCmaps\subj001_session_faln_dbnd_xr3d_atl_g7_bpss_resid.vals');
%   >> PlotDVars('C:\path\to\subj001\FCmaps\');
%   >> PlotDVars('C:\path\to\subj001\');
%   
% Output:
%   figDvarsComplete - figure handle
%   
% Required Parameters:
%   filename - The path to either a .vals file, the directory containing a single .vals file (e.g. FCmaps), or the subject/study directory containing the FCmaps files.
%   
% Optional Parameters:
%   none 
%   
% Author:
%   Jarod L Roland
%   Department of Neurosurgery
%   Washington University School of Medicine in St. Louis
%

%% Parse params
if(exist(studyPath, 'file') == 2)
    assert(strcmp(studyPath(end-4:end), '.vals'), 'Error: File must end in .vals');
    filename = studyPath;
elseif(exist(studyPath, 'dir') == 7)
    dirSearch = dir([studyPath '/*.vals']);
    if(isempty(dirSearch) && exist([studyPath '/FCmaps'], 'dir') == 7)
        studyPath = [studyPath '/FCmaps'];
        dirSearch = dir([studyPath '/*.vals']);
    end
    
    filename = [studyPath '/' dirSearch(1).name];
    if(length(dirSearch) > 1)
        warning(['Error: Multiple .vals files found, using the first one: ' filename]);
    end 
end

%% Load DVars
hFileDvar = fopen(filename);
assert(hFileDvar > 0, ['Error: Failed to open file: ' filename]);
dvars = textscan(hFileDvar, '');
dvars = dvars{1};
fclose(hFileDvar);

%% Plot
dvarsLims = [0 50];
numFrames = length(dvars);
figDvarsComplete = figure();
plot(dvars', 'color', [0.4 0.4 0.4]);
ylim(dvarsLims);
hold on
plot([0 numFrames], [5 5], 'k', 'linewidth', 0.5);
[~, file, ext] = fileparts(filename);
title([file ext], 'Interpreter', 'none');
ax = figDvarsComplete.CurrentAxes;
ax.XLim = [0 numFrames];
ax.YTick = [0 5 10:10:50];
ax.YTickLabels = {'0.0', '0.5', '1.0', '2.0', '3.0', '4.0', '5.0'};
ylabel('DVARS %');
xlabel('Frame');

end

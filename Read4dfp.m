function imageData = Read4dfp(filename, varargin)
% imageData = Read4dfp(filename, varargin)
% 
% Description:
%   Loads a 4dfp image given the path to one of a pair of 4dfp.img or 4dfp.ifh files.
%   The associated 4dfp.img and 4dfp.ifh files must be in the same directory.
%   
% Usage:
%   >> imageData = Read4dfp('C:\path\to\subject_mpr.4dfp.img');
%   >> imageData = Read4dfp('C:\path\to\subject_mpr.4dfp.img');
%   
% Output:
%   imageData - 3D matrix in the form [x, y, z] => [medial/lateral, anterior/posterior, dorsal/ventral]
%   
% Required Parameters:
%   filename - The path to either the 4dfp.img or 4dfp.ifh file. The counterpart must be in the same directory.
%   
% Optional Parameters:
%   [littleendian|bigendian] - text string forcing endian byte order of data. 
%     If not passed it is read from the IFH (if not specified in IFH an error results).
%   
% Author:
%   Jarod L Roland
%   Department of Neurosurgery
%   Washington University in St. Louis
%
imageData = [];

% parse varagin
endianType = [];
if(nargin == 2)
    if(strcmpi(varargin{1}, 'littleendian'))
        endianType = 'ieee-le';
    elseif(strcmpi(varargin{1}, 'bigendian'))
        endianType = 'ieee-be';
    else
        disp(['Error: Unknown input parameter (' varargin ')'])
        return;
    end
elseif(nargin > 2)
        disp(['Error: Unknown input for ' num2str(nargin) ' parameters'])
        return;
end

% find the header (.ifh) file
[tokens] = regexpi(filename, '(.*).4dfp.(img|ifh)', 'tokens');
assert(~isempty(tokens), 'Error: Filename must end in .4dfp.(ifh|img)')
fileBase = tokens{1}{1};
fileExt = tokens{1}{2};
if(strcmp(fileExt, 'ifh'))
    headerFilename = filename;
    imageFilename = [fileBase '.4dfp.img'];
elseif(strcmp(fileExt, 'img'))
    headerFilename = [fileBase '.4dfp.ifh'];
    imageFilename = filename;
else
    error('Error: Filename must end in .4dfp.(ifh|img)')
end

% make sure files exist
assert(exist(headerFilename, 'file') == 2, ['Error: Header file not found (' headerFilename ')']);
assert(exist(imageFilename, 'file') == 2, ['Error: Image file not found (' imageFilename ')']);

% read and parse the header file
ifhRaw = fileread(headerFilename);
ifhRaw = strrep(ifhRaw, [char(13) char(10)], char(10));   % assure Linux end-line format (ie. \n instead of \r\n)
tokens = regexp(ifhRaw, '(.+?)[\s\t]*:=\s*([\w\s]*)\n', 'tokens');

% convert tokens to a map object
numTokens = size(tokens, 2);
key = cell(1, numTokens);
val = cell(1, numTokens);
for i = 1:numTokens
    key{i} = tokens{i}{1};
    val{i} = tokens{i}{2};
end
ifhMap = containers.Map(key, val);

% find endian byte order if it hasn't been specified via function parameter
if(isempty(endianType))
    if(strcmp(ifhMap('imagedata byte order'), 'littleendian'))
        endianType = 'ieee-le';
    elseif(strcmp(ifhMap('imagedata byte order'), 'bigendian'))
        endianType = 'ieee-be';
    else
        error(['Unknown endian type: ''' ifhMap('imagedata byte order') '''']);
    end
end

% find dimensions
sizeX = str2double(ifhMap('matrix size [1]'));
sizeY = str2double(ifhMap('matrix size [2]'));
sizeZ = str2double(ifhMap('matrix size [3]'));
numFrames = str2double(ifhMap('matrix size [4]'));
frameSize = sizeX * sizeY * sizeZ;

% read image data
imageFile = fopen(imageFilename, 'r', endianType);
imageData = single(fread(imageFile, 'float'));
fclose(imageFile);
assert(~isempty(imageData), 'Error: Failed to read image data');
assert(numFrames == length(imageData) / frameSize, 'Error: Frame Size (IFH) and Data Size (IMG) do not correspond');

% re-arrange data 
imageData = reshape(imageData, sizeX, sizeY, sizeZ, numFrames);
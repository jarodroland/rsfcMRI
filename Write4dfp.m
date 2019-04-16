function Write4dfp(imageData, filename)
% imageData = Write4dfp(imData, filename, varargin)
% 
% Description:
%   Writes a 4dfp image given the image data and a path for the filename.4dfp.{img,ifh} file pair.
%   
% Usage:
%   >> Write4dfp(imageData, 'C:\path\to\subject_mpr.4dfp.img');
%   
% Required Parameters:
%   imageData - a 3D or 4D image matrix in the format [x, y, z] or [x, y, z, time]
%   filename - A path to where the file.4dfp.{img,ifh} will be saved.
%   
% Author:
%   Jarod L Roland
%   Department of Neurosurgery
%   Washington University School of Medicine in St. Louis
%

% make sure imageData is 3D or 4D
assert(ndims(imageData) == 3 || ndims(imageData) == 4, 'Error')

% parse the filename
[tokens] = regexpi(filename, '(.*\.4dfp)(\.img|\.ifh)$?', 'tokens');
assert(~isempty(tokens), 'Error: Filename must of the form path\to\file.4dfp(.ifh|.img) where either .ifh or .img is required.')

imageFilename = [tokens{1}{1} '.img'];
headerFilename = [tokens{1}{1} '.ifh'];

% make sure files don't already exist
assert(~exist(imageFilename, 'file'), ['Error: File "' imageFilename '" already exists']);
assert(~exist(headerFilename, 'file'), ['Error: File "' headerFilename '" already exists']);

% write img file
imageFile = fopen(imageFilename, 'w');
assert(imageFile > 0, ['Error: Failed to open ' imageFilename])
fwrite(imageFile, single(imageData), 'float', 0, 'ieee-le');            %TODO: accept different endian
fclose(imageFile);

% write ifh file
[~, imageFilenameShort, ~] = fileparts(imageFilename);
headerFile = fopen(headerFilename, 'w');
assert(headerFile > 0, ['Error: Failed to open ' headerFilename])
fprintf(headerFile, 'INTERFILE	:=\r\n');
fprintf(headerFile, 'version of keys	:= 3.3\r\n');
fprintf(headerFile, 'number format		:= float\r\n');
fprintf(headerFile, 'conversion program	:= Matlab\r\n');
fprintf(headerFile, ['name of data file	:= ' imageFilenameShort '.img\r\n']);
fprintf(headerFile, 'number of bytes per pixel	:= 4\r\n');
fprintf(headerFile, 'imagedata byte order	:= littleendian\r\n');      %TODO: accept different endian
fprintf(headerFile, 'orientation		:= 2\r\n');
fprintf(headerFile, 'number of dimensions	:= 4\r\n');
fprintf(headerFile, 'matrix size [1]	:= 48\r\n');                    %TODO: accept different dimensions
fprintf(headerFile, 'matrix size [2]	:= 64\r\n');
fprintf(headerFile, 'matrix size [3]	:= 48\r\n');
fprintf(headerFile, 'matrix size [4]	:= 1\r\n');
fprintf(headerFile, 'scaling factor (mm/pixel) [1]	:= 3.000000\r\n');
fprintf(headerFile, 'scaling factor (mm/pixel) [2]	:= 3.000000\r\n');
fprintf(headerFile, 'scaling factor (mm/pixel) [3]	:= 3.000000\r\n');
fprintf(headerFile, 'mmppix	:=   3.000000 -3.000000 -3.000000\r\n');
fprintf(headerFile, 'center	:=    73.5000  -87.0000  -84.0000\r\n');
fclose(headerFile);

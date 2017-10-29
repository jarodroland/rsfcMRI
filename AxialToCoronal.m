function corData = AxialToCoronal(axialData)
% corData = AxialToCoronal(axialData)
% 
% Description:
%   Converts axial image data to coronal orientation.
%   
% Usage:
%   >> axialData = Read4dfp('C:\path\to\subject_mpr.4dfp.img');
%   >> coronalData = AxialToSagital(axialData);
%   
% Output:
%   sagitalData - Same as input data re-arranged in sagital orientation
%   
% Required Parameters:
%   coronalData - 3 or 4-dimensional axial image data as returned from Read4dfp().
%
% Author:
%   Jarod L Roland
%   Department of Neurosurgery
%   Washington University School of Medicine in St. Louis
%
assert(ismember(ndims(axialData), [3 4]), 'Error: Input must be 3 or 4-dimensional data');

if(ndims(axialData) == 3)
    corData = flip(permute(axialData, [1 3 2]), 2);
elseif(ndims(axialData) == 4)
    corData = flip(permute(axialData, [1 3 2 4]), 3);
else
    error('Error: Unknown number of dimensions');
end

end
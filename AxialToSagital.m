function sagData = AxialToSagital(axialData)
% sagData = AxialToSagital(axialData)
% 
% Description:
%   Converts axial image data to sagital orientation.
%   
% Usage:
%   >> axialData = Read4dfp('C:\path\to\subject_mpr.4dfp.img');
%   >> sagitalData = AxialToSagital(axialData);
%   
% Output:
%   sagitalData - Same as input data re-arranged in sagital orientation
%   
% Required Parameters:
%   axialData - 3 or 4-dimensional axial image data as returned from Read4dfp().
%
% Author:
%   Jarod L Roland
%   Department of Neurosurgery
%   Washington University School of Medicine in St. Louis
%
assert(ismember(ndims(axialData), [3 4]), 'Error: Input must be 3 or 4-dimensional data');

if(ndims(axialData) == 3)
    sagData = flip(permute(axialData, [2 3 1]), 2);
elseif(ndims(axialData) == 4)
    sagData = flip(permute(axialData, [2 3 1 4]), 3);
else
    error('Error: Unknown number of dimensions');
end

end
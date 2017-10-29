function angle = ErnstAngle(TR, T1)
% function angle = ErnstAngle(TR, T1)
%
% Description:
%   Calculates the Ernst angle (https://en.wikipedia.org/wiki/Ernst_angle) for a given TR and T1.
%   
% Usage:
%   >> angle = ErnstAngle(2200, 800);
%   
% Output:
%   angle - The optimal flip-angle in degrees for given TR and T1
%   
% Required Parameters:
%   TR - Repetition time in milliseconds (e.g. 2200)
%   T1 - Spin-lattice relaxation time (longitudinal relaxation) in milliseconds (for references see http://www.mritoolbox.com/ParameterDatabase.html)
%   
% Author:
%   Jarod L Roland
%   Department of Neurosurgery
%   Washington University School of Medicine in St. Louis
%

angle = rad2deg( acos( exp(-TR/T1) ) );

end
function obj = makeSpectralSensitivitiesStochastic(obj, varargin)
% obj = makeSpectralSensitivitiesStochastic(obj, varargin)
%
% This method resamples the spectral sensivities using the known
% variability of the individual difference parameters.
%
% Currently, does not support resampling the melanopsin and rod
% fundamentals
%
% 7/25/17    ms       Commented.

% Parse vargin for options passed here
p = inputParser;
p.addParameter('NSamples', 1000, @isnumeric);
p.addParameter('RandStream', 'mrg32k3a', @isstring); % RNG for the resampling
p.KeepUnmatched = true;
p.parse(varargin{:});
NSamples = p.Results.NSamples;
whichRandStream = p.Results.RandStream;

% The following individual difference parameters are supported:
%   indDiffParams.dlens - Deviation in % from CIE computed peak lens density
%   indDiffParams.dmac - Deviation in % from CIE peak macular pigment density
%   indDiffParams.dphotopigment - Vector of deviations in % from CIE photopigment peak density
%   indDiffParams.lambdaMaxShift - Vector of values (in nm) to shift lambda max of each photopigment absorbance by
%   indDiffParams.shiftType - 'linear' (default) or 'log'
%
% The standard deviations are given in Table 5 of Asano et al. (2016),
% doi.org/10.1371/journal.pone.0145671. The macular pigment parameter is
% reduced from 36.5 to 25, because resampling often lead to out-of-bounds
% for the macular pigment parameter.
%
% Note also that this assumes the standard deviation is constant for all
% baseline parameters.
dlensSD = 18.7; % Given in %
dmaculaSD = 25; % Given in %
dLConeSD = 9.0; % Given in %
dMConeSD = 9.0; % Given in %
dSConeSD = 7.4; % Given in %
lMaxLConeSD = 2.0; % Given nm
lMaxMConeSD = 1.5; % Given nm
lMaxSConeSD = 1.3; % Given nm

% Create 8 independent random number generators
[s1, s2, s3, s4, s5, s6, s7, s8] = RandStream.create(whichRandStream, 'NumStreams', 8);

% Print out some info if the verbosity level is high
NPrintStep = 200;
if strcmp(obj.verbosity, 'high')
    fprintf('* Generating resampled observers... \n');
end

% Resample!
for ii = 1:NSamples
    % Print out some info if the verbosity level is high
    if strcmp(obj.verbosity, 'high')
        if mod(ii, NPrintStep) == 0
            % Rudimentary status update
            fprintf('  %i/%i <strong>[%.2f%s]</strong>\n', ii, NSamples, 100*ii/NSamples, '%');
        end
    end
    
    % Sample the lens density
    indDiffParamsLMS.dlens = randn(s1)*dlensSD;
    indDiffParamsMel.dlens = randn(s1)*dlensSD;
    indDiffParamsRod.dlens = randn(s1)*dlensSD;
    
    % Sample the macular pigment density
    indDiffParamsLMS.dmac = randn(s2)*dmaculaSD;
    indDiffParamsMel.dmac = randn(s2)*dmaculaSD;
    indDiffParamsRod.dmac = randn(s2)*dmaculaSD;
    
    % Sample the optical pigment density
    indDiffParamsLMS.dphotopigment = [randn(s3)*dLConeSD randn(s4)*dMConeSD randn(s5)*dSConeSD];
    indDiffParamsMel.dphotopigment = [0];
    indDiffParamsRod.dphotopigment = [0];
    
    % Sample the shift in lambda max
    indDiffParamsLMS.lambdaMaxShift = [randn(s6)*lMaxLConeSD randn(s7)*lMaxMConeSD randn(s8)*lMaxSConeSD];
        indDiffParamsMel.lambdaMaxShift = [0];
    indDiffParamsRod.lambdaMaxShift = [0];
    indDiffParamsLMS.shiftType = 'linear';
    
    % Call ComputeCIEConeFundamentals to get the spectral sensitivities
    [T_quantalAbsorptionsNormalizedLMS,T_quantalAbsorptionsLMS,T_quantalIsomerizationsLMS,adjIndDiffParams] = ComputeCIEConeFundamentals(obj.S,...
        obj.fieldSizeDeg,obj.obsAgeInYrs,obj.obsPupilDiameterMm,[],[],[], ...
        false,[],[],indDiffParamsLMS);
    [T_quantalAbsorptionsNormalizedMel,T_quantalAbsorptionsMel,T_quantalIsomerizationsMel,adjIndDiffParams] = ComputeCIEMelFundamental(obj.S,...
        obj.fieldSizeDeg,obj.obsAgeInYrs,obj.obsPupilDiameterMm,[]);
    [T_quantalAbsorptionsNormalizedRod,T_quantalAbsorptionsRod,T_quantalIsomerizationsRod,adjIndDiffParams] = ComputeCIERodFundamental(obj.S,...
        obj.fieldSizeDeg,obj.obsAgeInYrs,obj.obsPupilDiameterMm,[]);
    T_quantalIsomerizations = [T_quantalIsomerizationsLMS ; T_quantalIsomerizationsMel ; T_quantalIsomerizationsRod];
    T_quantalAbsorptionsNormalized = [T_quantalAbsorptionsNormalizedLMS ; T_quantalAbsorptionsNormalizedMel ; T_quantalAbsorptionsNormalizedRod];
    T_quantalAbsorptions = [T_quantalAbsorptionsLMS ; T_quantalAbsorptionsNormalizedMel ; T_quantalAbsorptionsNormalizedRod];
    
    % Convert to energy
    T_energy = EnergyToQuanta(obj.S,T_quantalAbsorptionsNormalized')';
    T_energyNormalized = bsxfun(@rdivide,T_energy,max(T_energy, [], 2));
    
    % Assign the sub-fields in the "Ts" field
    obj.Ts{ii}.T_quantalIsomerizations = T_quantalIsomerizations;
    obj.Ts{ii}.T_quantalAbsorptions = T_quantalAbsorptions;
    obj.Ts{ii}.T_quantalAbsorptionsNormalized = T_quantalAbsorptionsNormalized;
    obj.Ts{ii}.T_energy = T_energy;
    obj.Ts{ii}.T_energyNormalized = T_energyNormalized;
    obj.Ts{ii}.indDiffParams = indDiffParamsRod;
    obj.Ts{ii}.adjIndDiffParams = adjIndDiffParams;
end
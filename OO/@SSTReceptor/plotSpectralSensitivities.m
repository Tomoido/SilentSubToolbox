function h = plotSpectralSensitivities(obj, varargin)
% plotSpectralSensitivities(obj,timebase,response,varargin)
% 
% Plot the time-varying response 
%
% Key/value pairs
%   'NewWindow' - true/false (default true).  Create new window?

%% Parse vargin for options passed here
%
% Setting 'KeepUmatched' to true means that we can pass the varargin{:})
% along from a calling routine without an error here, if the key/value
% pairs recognized by the calling routine are not needed here.
p = inputParser; p.KeepUnmatched = true;
p.addParameter('NewWindow',true,@islogical);
p.parse(varargin{:});

%% Make the figure
if (p.Results.NewWindow)
    h = figure; clf; hold on;
else
    h = gcf;
end
% Plot
wls = SToWls(obj.S);
NReceptorsToPlot = size(obj.T_receptors, 1);
for ii = 1:NReceptorsToPlot
    % Determine the peak wavelength
    [~, idx] = max(obj.T_receptors(ii, :));
    
    plot(wls, obj.T_receptors(ii, :), '-', 'LineWidth', 2, 'Color', 'k'); hold on;
end
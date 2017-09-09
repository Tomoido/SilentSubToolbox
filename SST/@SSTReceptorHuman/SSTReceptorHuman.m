classdef SSTReceptorHuman < SSTReceptor
    % SSTReceptorHuman
    %
    % Usage:
    %     receptorObj = SSTReceptorHuman;
    %
    % Description:
    %     @SSTReceptor is the class for the human photoreceptor spectral
    %     sensitivities. Upon instantiating an object of this class, a
    %     standard set of nominal spectral sensitivities will be generated
    %     using this class's makeSpectralSensitivities function.
    %
    % Input:
    %     None.
    %
    % Output:
    %     receptorObj - The receptor object
    % 
    % The receptor object has the following output fields at instantiation:
    %
    %     receptorObj.obsAgeInYrs - Age of the observer in years
    %     receptorObj.obsPupilDiameterMm - Observer pupil diameter
    %     receptorObj.T - Fundamentals created using the makeSpectralSensitivities method
    %     receptorObj.labels - Labels for the spectral sensitvities contained in receptorObj.T
    %     receptorObj.doPenumbralConesTrueFalse - Compute penumbral cone sensitivities?
    % 
    % Additional fields are created using methods of this class. These are:
    %     
    %     receptorObj.Tp - Fundamentals created using makeSpectralSensitivitiesParametricVariation.
    %                      These describe variation in steps along the parameters of the Asano et al.
    %                      model.
    %
    %     receptorObj.Tp_i - Information about the parametric variations
    %
    %     receptorObj.Ts - Fundamentals created using makeSpectralSensitivitiesStochastic.  These
    %                      represent draws from the statistical model of Asano et al.
    %
    %     receptorObj.MD5Hash - MD5 checksum of the receptor object. Useful to check for integrity of specific
    %                           resampled receptor sets.
    %
    % Optional key/value pairs:
    %     'obsAgeInYrs' - Observer age in years (Default: 32 years).
    %
    %     'obsPupilDiameter' - Assumed pupil diameter of the observer
    %                          (Default: 3 mm)
    %
    %     'fieldSizeDeg' - Assume field size (Default: 10 deg)
    %
    %     'doPenumbralConesTrueFalse' - Logical determining whether the
    %                                   penumbral cone spectral
    %                                   sensitivities should also be
    %                                   generated.
    %
    %     'verbosity' - Verbosity level for printing diagnostics. Possible
    %                   options:
    %                       'none' - No diagnostic print-out
    %                       'high' - Print everything that might be useful
    %
    %     'S' - The wavelength sampling specification in standard PTB
    %           notation. (Default: [380 2 201]).
    %
    % Methods that are implemented in this subclasses:
    %     makeSpectralSensitivities
    %     makeSpectralSensitivitiesParametricVariation
    %     makeSpectralSensitivitiesStochastic
    %     setMD5Hash
    %       
    % Methods implemented in the parent class SSTReceptor:
    %     plotSpectralSensitivities - Plots the spectral sensitivities
    %                                 generated by any subclass object
    %
    % See also:
    %     @SSTReceptor, makeSpectralSensitivities,
    %     makeSpectralSensitivitiesStochastic,
    %     makeSpectralSensitivitiesParametricVariation, setMD5Hash
    
    % 9/8/17  ms  Added header comments.
    
    % Public, read-only properties.
    properties (SetAccess = private, GetAccess = public)
        obsAgeInYrs; % Age of the observer in years
        obsPupilDiameterMm; % Pupil diameter
        fieldSizeDeg; % Field size in degrees
        T;  % Fundamentals created using makeSpectralSensitivities
        Tp; % Fundamentals created using makeSpectralSensitivitiesParametricVariation
        Tp_i; % Information about the parametric variation from makeSpectralSensitivitiesParametricVariation 
        Ts; % Fundamentals created using makeSpectralSensitivitiesStochastic
        labels; % Labels for the spectral sensitivities
        MD5Hash; % MD5 hash of the receptor object
        doPenumbralConesTrueFalse;
    end
    
    % Private properties. Only methods of the parent class can set these
    properties(Access = private)
    end
    
    % Public methods
    methods
    end
    
    properties (Dependent)
    end
    
    % Methods.  Most public methods are implemented in a separate
    % function, but we put the class constructor here.
    methods (Access=public)
        % Constructor
        function obj = SSTReceptorHuman(varargin)
            % Base class constructor
            obj = obj@SSTReceptor(varargin{:});
            
            % Parse vargin for options passed here
            p = inputParser;
            p.addParameter('obsAgeInYrs', 32, @isnumeric);
            p.addParameter('obsPupilDiameterMm', 3, @isnumeric);
            p.addParameter('fieldSizeDeg', 10, @isnumeric);
            p.addParameter('doPenumbralConesTrueFalse', false, @islogical);
            p.addParameter('verbosity', 'high', @ischar);
            p.addParameter('S',[380 2 201],@isnumeric);
            p.KeepUnmatched = true;
            p.parse(varargin{:});
            
            % Display the parameters and list any ones which didn't get matched
            theUnmatchedFields = fields(p.Unmatched);
            if ~isempty(theUnmatchedFields)
                warning('* There are unmatched parameters.');
                % Print the valid parameters
                fprintf('* Valid parameters for this model are:\n');
                for ii = 1:length(p.Parameters)
                    fprintf('  <strong>%s</strong>\n', p.Parameters{ii});
                end
                fprintf('\n');
                
                fprintf('* Unmatched input parameters for this model are:\n');
                for ii = 1:length(theUnmatchedFields)
                    fprintf('  <strong>%s</strong>\n', theUnmatchedFields{ii});
                end
                fprintf('\n');
            end
            
            % Assign the parameter values from the parser
            obj.obsAgeInYrs = p.Results.obsAgeInYrs;
            obj.obsPupilDiameterMm = p.Results.obsPupilDiameterMm;
            obj.fieldSizeDeg = p.Results.fieldSizeDeg;
            obj.doPenumbralConesTrueFalse = p.Results.doPenumbralConesTrueFalse;
            obj.makeSpectralSensitivities;
            
            % Print out some output
            if strcmp(obj.verbosity, 'high')
                fprintf('* Setting up receptor object with parameters:\n');
                fprintf('  <strong>Age [yrs]</strong>:\t\t\t%i\n', obj.obsAgeInYrs);
                fprintf('  <strong>Pupil diameter [mm]</strong>:\t\t%.2f\n', obj.obsPupilDiameterMm);
                fprintf('  <strong>Field size [deg]</strong>:\t\t%.2f\n', obj.fieldSizeDeg);
                if obj.doPenumbralConesTrueFalse == 1
                    fprintf('  <strong>Including penumbral cones?</strong>:\t%s\n\n', 'True');
                elseif obj.doPenumbralConesTrueFalse == 0
                    fprintf('  <strong>Including penumbral cones?</strong>:\t%s\n\n', 'False');
                end
            end
        end
        
        % Declare the rest of the methods
        makeSpectralSensitivitiesStochastic(obj, varargin);
        [parv, parvlabel, parvlabellong, parvreal] = makeSpectralSensitivitiesParametricVariation(obj, varargin); 
        setMD5Hash(obj);
    end
    

    % Get methods for dependent properties
    methods
    end
    
    % Methods may be called by the subclasses, but are otherwise private
    methods (Access = protected)
    end
    
    % Methods that are totally private (subclasses cannot call these)
    methods (Access = private)
    end
end
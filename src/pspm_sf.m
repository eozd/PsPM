function [sts, sf] = pspm_sf(model, options)
% ● Description
%   pspm_sf is a wrapper function for analysis of skin conductance as a
%   measure of tonic arousal. SF are analysed over time windows that
%   typically last 60 s and should at least be 15 s long. PsPM implements 3
%   different models.
%   (1) Skin conductance level (SCL): this is the mean signal over the
%   epoch.
%   (2) Area under the curve (AUC): this is the time-integral of the signal
%   with the minimum value subtracted (to account for pre-epoch arousal),
%   divided by epoch duration. This is designed to be independent from SCL
%   and ideally represents the number x amplitude of spontaneous
%   fluctuations (also termed non-specific SCR) in this epoch.
%   (3) Number of SF estimated by DCM: this is a non-linear estimation of
%   the number and onset of SF, and is the most sensitive indicator of
%   tonic arousal. For counting peaks, a threshold in mcS is applied; hence
%   it is important that the data are provided in the correct units. Estimated
%   SF onset is stored in the model and is expressed in CNS time, i.e. the
%   time point at which an SF was generated in the CNS. Thus, it already
%   takes into account the conduction delay from CNS into the periphery.
%   (4) Number of SF estimated by MP: This is the same model as in (3) but
%   estimated with an approximative matching pursuit (MP) algorithm.
% ● Format
%   [sts, sf] = pspm_sf(model, options)
% ● Arguments
%   ┌──────────model
%   ├──────.datafile :  one data filename
%   ├─────.modelfile :  one model filename
%   ├────────.timing :  can be one of the following
%   │                   - an SPM style onset file with two event types: onset &
%   │                     offset (names are ignored)
%   │                   - a .mat file with a variable 'epochs', see below
%   │                   - a two-column text file with on/offsets
%   │                   - e x 2 array of epoch on- and offsets, with
%   │                   e: number of epochs
%   │                   or cell array of any of these, for multiple files
%   ├─────.timeunits :  seconds, samples, markers, whole (in the last case, 'timing' will
%   │                   be ignored and the entire file will be used).
%   ├────────.method :  [optional, string/cell_array]
%   │                   [string] accept 'auc', 'scl', 'dcm', or 'mp', default as 'dcm'.
%   │                   [cell_array] a cell array of methods mentioned above.
%   ├────────.filter :  [optional] filter settings; modality specific default
%   ├───────.missing :  [optional, string] [default: no missing values]
%   │                   Allows to specify missing (e.g. artefact) epochs in the data file.
%   │                   See pspm_get_timing for epoch definition. This must always be specified in SECONDS.
%   └───────.channel :  [optional, integer, default: last SCR channel] Channel number.
%   ┌────────options
%   ├─────.overwrite :  [logical, default: determined by pspm_overwrite]
%   │                   Define whether to overwrite existing output files or not.
%   ├.marker_chan_num:  [integer] marker channel number
%   │                   if undefined or 0, first marker channel is used.
%   ├─────.threshold :  [numeric, default: 0.1] [unit: mcS]
%   │                   Threshold for counting estimated SN peaks (default
%   │                   0.1 mcS). (Used for DCM and MP only.)
%   ├─────────.theta :  [vector default: read from pspm_sf_theta]
%   │                   A (1 x 5) vector of theta values for f_SF. (Used for DCM and MP only.)
%   ├─────────.fresp :  [numeric, default: 0.5]
%   │                   (Maximum) frequency (in Hz) of responses in the model.
%   │                   (Used for DCM and MP only.)
%   ├───────.dispwin :  [logical, default: 1]
%   │                   Display progress plot (DCM) or result plot (MP).
%   ├──.dispsmallwin :  [logical, default: 0]
%   │                   Display intermediate progress windows. (Used for DCM only.)
%   └─.missingthresh :  [numeric, default: 2] [unit: second]
%                       Threshold value for controlling missing epochs.
%                       (Used for DCM only).
%
% ● References
%   [1] DCM for SF:
%       Bach DR, Daunizeau J, Kuelzow N, Friston KJ, Dolan RJ (2010). Dynamic
%       causal modelling of spontaneous fluctuations in skin conductance.
%       Psychophysiology, 48, 252-257.
%   [2] MP approximation:
%       Bach DR, Staib M (2015). A matching pursuit algorithm for inferring
%       tonic sympathetic arousal from spontaneous skin conductance
%       fluctuations. Psychophysiology, 52, 1106-12.
%   [3] AUC for SF:
%       Bach DR, Friston KJ, Dolan RJ (2010). Analytic measures for the
%       quantification of arousal from spontanaeous skin conductance
%       fluctuations. International Journal of Psychophysiology, 76, 52-55.
%
% ● Developer's Note
%   the output also contains a field .time that contains the inversion time
%   in ms (for DCM and MP)
% ● Copyright
%   Introduced in PsPM 3.0
%   Written in 2008-2015 by Dominik R Bach (WCHN, UCL and UZH)
%   Maintained in 2022 by Teddy

%% 1 Initialise
global settings
if isempty(settings)
    pspm_init;
end
outfile = [];
sts = -1;


%% 2 Check input
% 2.1 check missing input --
if nargin < 1; errmsg = 'Nothing to do.'; warning('ID:invalid_input', errmsg); return
elseif nargin < 2; options = struct(); end

% 2.2 check model and options
[model, options] = pspm_check_model(model, options, 'sf');
if model.invalid || options.invalid
    return
end

model.timing = model.timing{1};
model.datafile = model.datafile{1};
model.missing = model.missing{1};

%% 3. Parse methods
method = cell(numel(model.method), 1);
fhandle = method;
datatype = NaN(numel(model.method));
for k = 1:numel(model.method)
    switch model.method{k}
        case {'auc', 'AUC'}
            method{k} = 'auc';
            fhandle{k} = @pspm_sf_auc;
            datatype(k) = 2; % filtered
        case {'DCM', 'dcm'}
            method{k} = 'dcm';
            fhandle{k} = @pspm_sf_dcm;
            datatype(k) = 2; % filtered
        case {'MP', 'mp'}
            method{k} = 'mp';
            fhandle{k} = @pspm_sf_mp;
            datatype(k) = 2; % filtered
        case {'SCL', 'scl', 'level'}
            method{k} = 'scl';
            fhandle{k} = @pspm_sf_scl;
            datatype(k) = 1; % unfiltered
        case 'all'
            method = {'scl', 'auc', 'dcm', 'mp'};
            fhandle = {@pspm_sf_scl, @pspm_sf_auc,  @pspm_sf_dcm, @pspm_sf_mp};
            datatype = [1 2 2 2];
        otherwise
            warning('Method %s not supported', model.method{k}); return;
    end

end

% 2.6 Get timing --
if strcmpi(model.timeunits, 'whole')
    epochs = [1 1];
else
    [sts, epochs] = pspm_get_timing('epochs', model.timing, model.timeunits);
end


%% 3 Get data
% 3.1 User output
fprintf('SF analysis: %s ...', model.datafile);

% 3.2 get and filter data --
[sts_load_data, data] = pspm_load_channel(model.datafile, model.channel, 'scr');
if sts_load_data < 0, return; end
y{1} = data.data;
sr(1) = data.header.sr;
model.filter.sr = sr(1);
[sts_prepdata, y{2}, sr(2)] = pspm_prepdata(y{1}, model.filter);
% always use last data channels
if sts_prepdata == -1
    warning('ID:invalid_input', 'Call of pspm_prepdata failed.');
    return;
end
% 3.3 Check data units
if ~strcmpi(data.header.units, 'uS') && any(strcmpi('dcm', method))
    fprintf(['\nYour data units are stored as %s, ',...
        'and the method will apply an amplitude threshold in uS. ',...
        'Please check your results.\n'], ...
        data.header.units);
end
% 3.4 Get missing epochs --
if ~isempty(model.missing)
    [~, missing{iFile}] = pspm_get_timing('missing', model.missing, 'seconds');
    model.missing_data = zeros(size(y{2}));
    missing_index = pspm_time2index(missing, sr(datatype(k)));
    model.missing_data((missing_index(:,1)+1):(missing_index(:,2)+1)) = 1;
else
    missing= [];
end
% 3.5 Get marker data --
if any(strcmp(model.timeunits, {'marker', 'markers'}))
    [sts, ndata] = pspm_load_channel(model.datafile, options.marker_chan_num, 'marker');
    if sts < 1, return;  end
    events{iFile} = ndata.data(:);
end

for iEpoch = 1:size(epochs, 1)
    if iEpoch > 1, fprintf('\n\t\t\t'); end
    fprintf('epoch %01.0f ...', iEpoch);
    for k = 1:numel(method)
        fprintf('%s ', method{k});
        switch model.timeunits
            case 'seconds'
                win = round(epochs(iEpoch, :) * sr(datatype(k)));
            case 'samples'
                win = round(epochs(iEpoch, :) * sr(datatype(k)) / sr(1));
            case 'markers'
                win = round(events{iFile}(epochs(iEpoch, :)) * sr(datatype(k)));
            case 'whole'
                win = [1 numel(y{datatype(k)})];
        end
        if any(win > numel(y{datatype(k)}) + 1) || any(win < 0)
            warning('\nEpoch %2.0f outside of file %s ...', iEpoch, model.datafile);
            inv_flag = 0;
        else
            inv_flag = 1;
            % correct issues with using 'round'
            win(1) = max(win(1), 1);
            win(2) = min(win(2), numel(y{datatype(k)}));
        end
        if diff(win) < 4
            warning('\nEpoch %2.0f contains insufficient data ...', iEpoch);
            inv_flag = 0;
        end
        % 3.6.1 collect information --
        sf.model{k}(iEpoch).modeltype = method{k};
        sf.model{k}(iEpoch).boundaries = squeeze(epochs(iEpoch, :));
        sf.model{k}(iEpoch).timeunits  = model.timeunits;
        sf.model{k}(iEpoch).samples    = win;
        sf.model{k}(iEpoch).sr         = sr(datatype(k));
        %
        escr = y{datatype(k)}(win(1):win(end));
        sf.model{k}(iEpoch).data = escr;

        % 3.6.2 do the analysis and collect results --
        if ~isempty(model.missing)
            model_analysis = struct('scr', escr, 'sr', sr(datatype(k)), 'missing_data', model.missing_data(win(1):win(end)));
        else
            model_analysis = struct('scr', escr, 'sr', sr(datatype(k)));
        end
        if inv_flag ~= 0
            [sts, invrs] = fhandle{k}(model_analysis, options);
            sf.model{k}(iEpoch).inv = invrs;
        else
            sf.model{k}(iEpoch).inv = [];
        end
        if inv_flag == 0
            sf.stats(iEpoch, k) = NaN;
        elseif any(strcmpi(method{k}, {'dcm', 'mp'}))
            sf.stats(iEpoch, k)         = invrs.f;
        else
            sf.stats(iEpoch, k)         = invrs;
        end
    end
    sf.trlnames{iEpoch} = sprintf('Epoch #%d', iEpoch);
end
sf.names = method(:);
sf.infos.date = date;
sf.infos.file = model.modelfile;
sf.modelfile = model.modelfile;
sf.data = y;
if exist('events','var'), sf.events = events; end
sf.input = model;
sf.options = options;
sf.modeltype = 'sf';
sf.modality = settings.modalities.sf;
save(model.modelfile, 'sf');
fprintf('\n');
sts = 1;


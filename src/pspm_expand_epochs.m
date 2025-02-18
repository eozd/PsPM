function [sts, out] = pspm_expand_epochs(varargin)
% ● Description
% pspm_expand_epochs expands epochs in time, and merges overlapping epochs. 
% This is useful in processing missing data epochs. The function can take 
% a missing epochs file and creates a new file with the original name 
% prepended with 'e', a matrix of missing epochs, or a PsPM data file with 
% missing data in a given channel.
% ● Format
%   [sts, output_file]     = pspm_expand_epochs(epochs_fn, expansion, options)
%   [sts, expanded_epochs] = pspm_expand_epochs(epochs, expansion, options) 
%   [sts, channel_index]   = pspm_expand_epochs(data_fn, channel, expansion , options)
% ● Arguments
%   *   epochs_fn:  An epochs file as defined in pspm_get_timing.
%   *      epochs:  A 2-column matrix with epochs onsets and offsets in seconds.
%   *     data_fn:  A PsPM data file.
%   *     channel:  Channel identifier accepted by pspm_load_channel.
%   *   expansion:  A 2-element vector with positive numbers [pre, post]
%   ┌────────────options:
%   ├─────────.overwrite: Define if already existing files should be
%   │                     overwritten. Default ist 2. (Only used if input
%   │                     is epochs file.)
%   └────.channel_action: Channel action, add / replace existing data
%                         data (default: add)
% ● Output
%   *  channel_index: index of channel containing the processed data
% ● History
%   Introduced in PsPM 7.0
%   Written in 2024 by Bernhard Agoué von Raußendorf

% Initialise
% -------------------------------------------------------------------------
global settings
if isempty(settings)
  pspm_init;
end

sts = -1;
out = [];

% Input checks and parsing 
%  ------------------------------------------------------------------------
if nargin < 2 
  warning('ID:invalid_input', 'Not enough input arguments');
  return;
end

% parse first input and determine mode
if isnumeric(varargin{1})
    mode = 'epochs';
    [gsts, epochs] = pspm_get_timing('epochs', varargin{1}, 'seconds');
    if gsts < 1 
        return
    end

elseif ischar(varargin{1})
    fn = varargin{1};
    % we turn the downstream warning off because the return status is used to determine the
    % format of the first input argument
    warning off
    [dsts, infos, ~, filestruct] = pspm_load_data(fn, 'none');
    warning on

    if dsts == 1
        fprintf('Assuming input is a PsPM data file ...\n');
        mode = 'datafile';
    else
        % we turn the downstream warning off because we want to give a summary warning
        % below
        warning off
        [gsts, epochs] = pspm_get_timing('epochs', fn, 'seconds'); % if the epochfile is empty?
        warning on

        if gsts == 1
            mode = 'epochfile'; 
        else % neither a empty nor a normal epochfile gsts < 1
            warning('ID:invalid_input', 'First argument must be a file name or epoch matrix.');
            return
        end
    end
else 
    warning('ID:invalid_input', 'First argument must be a file name or epoch matrix.');
    return
end

% parse remaining arguments
if ismember(mode, {'epochs', 'epochfile'})
    expansion = varargin{2};
    k = 2;
else
    channel   = varargin{2};
    expansion = varargin{3};
    k = 3;
end

if nargin > k
    options = varargin{k+1};
else
    options = struct();
end

% finalise options structure
options = pspm_options(options, 'expand_epochs');

% check if expansion vector is valid
if   ~isnumeric(expansion)  || numel(expansion) ~= 2 || expansion(1) < 0 || expansion(2) < 0
    warning('ID:invalid_input','Expansion vector must have 2 positive elements.');
    return;
end



% work on input
% -------------------------------------------------------------------------

% construct epochs from data file
if strcmpi(mode, 'datafile')
    
    [lsts, ~, data] = pspm_load_data(fn, channel);
    if lsts < 1
        return;
    end

    channel_data = data{1};
    sr = channel_data.header.sr;

    % find NaN indices
    nan_indices = isnan(channel_data.data);
    
    % convert NaN indices to epochs
    epochs = pspm_logical2epochs(nan_indices, sr);

end

% expand epochs
if isempty(epochs)
    warning('No epochs found.');
    expanded_epochs = [];
else
    pre = expansion(1);
    post = expansion(2);
    expanded_epochs_temp = [epochs(:,1) - pre, epochs(:,2) + post];
    % remove negative values and merge overlapping epochs
    [ksts, expanded_epochs] = pspm_get_timing('missing', expanded_epochs_temp, 'seconds') ;
    if ksts < 1 
        return
    end
end

% generate output
switch mode
    case 'epochs'
        out = expanded_epochs;
    
    case 'epochfile'
        % save expanded epochs to a new file with 'e' prefix
        [pathstr, name, ext] = fileparts(fn);
        output_file = fullfile(pathstr, ['e', name, ext]);
        overwrite_final = pspm_overwrite(output_file, options.overwrite);
        if overwrite_final == 1
            epochs = expanded_epochs; 
            save(output_file, 'epochs'); 
            fprintf(['Expanded epochs saved to file: ', output_file, '\n']);
            out = output_file; % the function outputs the filename of the expanded epochfile
        end
    
    case 'datafile'

        % Convert expanded epochs back to logical indices
        expanded_indices = pspm_epochs2logical(expanded_epochs, numel(channel_data.data), sr);
    
        % Set data to NaN at expanded indices
        channel_data.data(logical(expanded_indices)) = NaN;
    
        % Save the data 
        [wsts, out] = pspm_write_channel(fn, {channel_data}, options.channel_action, struct('channel', channel)); 
        if wsts < 1
            return
        end
        out = out.channel;


    end

sts = 1;
end


function [sts, outchannel] = pspm_pp(varargin)
% ● Description
%   pspm_pp contains various preprocessing/filtering utilities for reducing noise in
%   the data. The 'butter' option also allows downsampling after
%   application of an anti-alias Butterworth filter. Note that all models
%   apply Butterworth filters automatically; additional filters should be added
%   with caution.
% ● Format
%   [sts, channel_index] = pspm_pp('median', fn, channel, n,    options)
%   [sts, channel_index] = pspm_pp('butter', fn, channel, filt, options)
%   [sts, channel_index] = pspm_pp('leaky_integrator', fn, channel, tau, options)
% ● Arguments
%   *    method :  [string] Method of filtering. Currently implemented methods are
%                  'median' and 'butter'.
%                  (1) 'median', a median filter will be applied.
%                  (2) 'butter', Butterworth band pass filter potentially including
%                                downsampling; any NaN data are interpolated before
%                                filtering and then removed.
%                  (3) 'leaky_integrator', Applies a leaky integrator filter where tau
%                                is specified in seconds.
%   *        fn :  [string] The datafile that saves data to process
%   *   channel :  A channel definition accepted by pspm_load_channel
%   *         n :  [numeric, only if method=='median'] Number of timepoints
%                  for median filter in number of samples.
%   *       tau :  [numeric, only if method=='leaky_integrator'] Time constant for
%                  the leaky integrator in seconds.
%   ┌──────filt
%   ├───.lpfreq :  low pass filt frequency or 'none' (default)
%   ├──.lporder :  low pass filt order (default: 1)
%   ├───.hpfreq :  high pass filt frequency or 'none' (default)
%   ├──.hporder :  high pass filt order (default: 1)
%   ├.direction :  filt direction ('uni' or 'bi', default 'uni')
%   └─────.down :  sample rate in Hz after downsampling or 'none' (default)
%   ┌───options
%   └.channel_action:
%                 [optional][string][Accepts: 'add'/'replace'][Default: 'add'] Defines
%                 whether corrected data should be added or the corresponding preprocessed
%                 channel should be replaced.
% ● Outputs
%   *  channel_index: index of channel containing the processed data
% ● History
%   Introduced in PsPM 3.0
%   Written    in 2009-2015 by Dominik R Bach (Wellcome Trust Centre for Neuroimaging)
%   Refactored in 2024      by Dominik R Bach (Uni Bonn)
%   Updated to include 'leaky_integrator' method in 2024 by Abdul Wahab Madni

%% 1 Initialise
global settings
if isempty(settings)
  pspm_init;
end
sts = -1;
outchannel = [];

%% 2 Check input arguments
if nargin < 1
  warning('ID:invalid_input', 'No input arguments. Don''t know what to do.');
elseif nargin < 2
  warning('ID:invalid_input', 'No datafile.'); return;
elseif nargin < 3
  warning('ID:invalid_input', 'No channel given.'); return;
elseif nargin < 4
  warning('ID:invalid_input', 'Missing filter specs.'); return;
elseif nargin < 5
  options = struct(); % build an empty struct if nothing is available
else
  options = varargin{5};
end
method  = varargin{1};
fn      = varargin{2};
channel = varargin{3};

options = pspm_options(options, 'pp');
if options.invalid
    return
end

%% 3 Load data
[sts, data, ~, pos_of_channel] = pspm_load_channel(fn, channel);
if sts ~= 1, return; end

%% 4 Do the job
switch method
  case 'median'
    n = varargin{4};
    % user output
    fprintf('\n\xBB Preprocess: median filtering datafile %s ... ', fn);
    data.data = medfilt1(data.data, n);
    msg = sprintf('median filter over %1.0f timepoints', n);
  case 'butter'
    filt = varargin{4};
    if ~isstruct(filt)
      warning('ID:invalid_input', 'Filter must be a struct.'); return;
    end
    % set defaults
    if ~isfield(filt, 'down')
      filt.down = 'none';
    end
    if ~isfield(filt, 'lpfreq')
      filt.lpfreq = 'none';
    end
    if ~isfield(filt, 'hpfreq')
      filt.hpfreq = 'none';
    end
    if ~isfield(filt, 'lporder')
      filt.lporder = 1;
    end
    if ~isfield(filt, 'hporder')
      filt.hporder = 1;
    end
    if ~isfield(filt, 'direction')
      filt.direction = 'uni';
    end
    filt.sr = data.header.sr;
    fprintf('\n\xBB Preprocess: butterworth filtering datafile %s ... ', fn);
    [sts, data.data, data.header.sr] = pspm_prepdata(data.data, filt);
    if sts == -1, return; end
    msg = sprintf('butterworth filter');
  case 'leaky_integrator'
    tau_sec = varargin{4};
    if ~isnumeric(tau_sec)
      warning('ID:invalid_input', 'Tau must be numeric.'); return;
    end
    % Convert tau from seconds to samples
    sample_rate = data.header.sr;  % Assuming the sample rate is stored here
    tau_samples = pspm_time2index(tau_sec, sample_rate);

    fprintf('\n\xBB Preprocess: applying leaky integrator to datafile %s ... ', fn);
    % Apply the leaky integrator function
    data.data = pspm_leaky_integrator(data.data, tau_samples);
    if isempty(data.data), return; end  % Check if the operation was successful
    msg = sprintf('leaky integrator with tau %1.0f samples', tau_samples);
  otherwise
    warning('ID:invalid_input', 'Unknown filter option ...');
    return;
end
fprintf('done.\n');
[sts, out] = pspm_write_channel(fn, data, options.channel_action, struct('prefix', msg, 'channel', pos_of_channel));
outchannel = out.channel;


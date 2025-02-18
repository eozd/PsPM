function missing = pspm_cfg_selector_missing_epochs(varargin) 

% run mode ----------------------------------------------------------------
if nargin > 1 && strcmpi(varargin{1}, 'run')
    job = varargin{2};
    missing = [];
    if isfield(job, 'missing')
        if isfield(job.missing,'epochfile')
            missing = job.missing.epochfile{1};
        elseif isfield(job.missing,'epochentry')
            missing = job.missing.epochentry;
        end
    end
    return
end

% - selector mode ---------------------------------------------------------

% standard item
epochfile        = pspm_cfg_selector_datafile('epochs');

% Missing epochs
no_epochs         = cfg_const;
no_epochs.name    = 'No Missing Epochs';
no_epochs.tag     = 'no_epochs';
no_epochs.val     = {0};
no_epochs.help    = {'The whole time series will be analyzed.'};

epochentry         = cfg_entry;
epochentry.name    = 'Enter Missing Epochs Manually';
epochentry.tag     = 'epochentry';
epochentry.strtype = 'i';
epochentry.num     = [Inf 2];
epochentry.help    = {'Enter the start and end points of missing epochs (m) manually.', ...
    ['Specify an m x 2 array, where m is the number of missing epochs. The first column marks the ' ...
    'start points of the epochs that are excluded from the analysis and the second column the end points.']};

missing        = cfg_choice;
missing.name   = 'Missing Epochs';
missing.tag    = 'missing';
missing.val    = {no_epochs};
missing.values = {no_epochs, epochfile, epochentry};
missing.help   = {['Indicate epochs in your data in which the ', ...
    ' signal is missing or corrupted (e.g., due to artifacts). Specified missing epochs, as well as NaN values ', ...
    'in the signal, will be interpolated for filtering and downsampling ', ...
    'and later automatically removed from data and design matrix. Epoch start and end points ' ...
    'have to be defined in seconds with respect to the beginning of the session.']};
function out = pspm_cfg_channel_selector(channame, varargin)
% Generates a standardised channel selector GUI entry

% check input
if nargin == 0 
    channame = '';
end

%% parse channel selection from matlabbatch
if strcmpi(channame, 'run')
    job = varargin{1};
    if isfield(job, 'chan_default')
        out = job.chan_default;
    elseif isfield(job, 'chan_nr')
        out = job.chan_nr;
    else
        out = 0;
    end

    if ischar(out)
        if strcmpi(out, num2str(int64(str2num(out))))
            out = str2num(out);
        end
    end

%% gather channel selection in matlabbatch  
% numerical or string definition
elseif strcmpi(channame, 'any')
    out         = str_chan(channame);

% numerical or string definition or default
elseif ismember(channame, {'pupil', 'pupil_both', 'pupil_none'})
    if strcmpi(channame, 'pupil')
        chan_menu = [1, 3:5];
        chan_default = 5;
    elseif strcmpi(channame, 'pupil_both')
        chan_menu = 1:5;
        chan_default = 5;
    elseif strcmpi(channame, 'pupil_none')
        chan_menu = [1, 3:6];
        chan_default = 6;
    end
    out = cfg_choice;
    out.name    = 'Channel';
    out.tag     = 'chan';
    out.val     = {pupil_chan(chan_menu, chan_default)};
    out.values  = {pupil_chan(chan_menu, chan_default), num_chan('pupil')};
    out.help    = {sprintf('Specification of %s channel (default: follow precedence order).', 'pupil')};

% numerical definition
elseif isempty(channame)
    out         = num_chan;

% numerical definition or default 
else
    if strcmpi(channame, 'marker')
        pos_str = 'First';
    else
        pos_str = 'Last';
    end
    out = cfg_choice;
    out.name    = 'Channel';
    out.tag     = 'chan';
    out.val     = {def_chan(channame, pos_str)};
    out.values  = {def_chan(channame, pos_str), num_chan(channame)};
    out.help    = {sprintf('Number of %s channel (default: %s %s channel).', channame, lower(pos_str), channame)};
end
end

% possible menu items -----------------------------------------------------
function out = def_chan(channame, pos_str)
    out      = cfg_const;
    out.name = 'Default channel';
    choutan_default.tag  = 'chan_def';
    out.val  = {0};
    out.help = {sprintf('%s %s channel.', pos_str, channame)};
end

function out = num_chan(channame)
    out = cfg_entry;
    out.name    = 'Channel number';
    out.tag     = 'chan_nr';
    out.strtype = 'i';
    out.num     = [1 1];
    out.help    = {sprintf('Specify %s channel number.', channame)};
end

function out = str_chan(channame)
    out         = cfg_entry;
    out.name    = 'Channel specification';
    out.tag     = 'chan_nr';
    out.strtype = 's';
    out.help    = {sprintf('Specify %s channel number or channel type (e.g., "scr", "ecg" or any other type accepted by PsPM.', channame)};
end

function out = pupil_chan(menu_set, menu_default)

    labels                 = {'Combined pupil channel', 'Both pupil channels', 'Left pupil', 'Right pupil', 'Default', 'None'};
    values                 = {'pupil_c', 'both', 'pupil_l', 'pupil_r', 'pupil', ''};
    
    out                    = cfg_menu;
    out.name               = 'Channel specification';
    out.tag                = 'chan_menu';
    out.labels             = labels(menu_set);
    out.values             = values(menu_set);
    out.val                = values(menu_default);
    out.help               = {['Specify pupil channel to process. This will ', ...
        'use the last channel of the specified type. Default is the first ', ...
        'existing option out of the following: ', ...
        '(1) Combined pupil, (2) non-lateralised pupil, (3) best ', ...
        'eye pupil, (4) any pupil channel. If there are multiple ', ...
        'channels in the first existing option, only last one will be ', ...
        'processed.']};
end


function out = pspm_cfg_selector_channel(channame, varargin)
% ● Description
% pspm_cfg_channel_selector generates a standardised matlabbatch entry for 
% channel selection 
% ● Format
%   sts = pspm_cfg_channel_selector(channeltype)
%   sts = pspm_cfg_channel_selector('run', job)
% ● Arguments
% channeltype: (1) a channeltype string - generates a default channel of 
%                  this type, and a numerical channel selector
%              (2) 'pupil' - generates a choice of 'combined', 'left',
%                  'right', 'pupil' (default), and a numerical channel 
%                   selector
%              (3) 'pupil_both' - like 'pupil' but with the option of
%                   selecting both pupils
%              (4) 'pupil_none' - like 'pupil' but with the option of
%                   selecting no channel (used for pspm_pupil_pp)
%              (5) 'gaze' - generates a choice of 'combined', 'left',
%                  'right', 'gaze' (default), and a numerical selector for 
%                   an x/y pair of channels 
%              (6) 'gaze_pair' - generates a choice of 'gaze' (default) and
%                   two x/y pairs of channels
%              (7) 'any' - generates a string channel selector for at most
%                   one channel
%              (8) 'many' - generates a numerical channel selector for an
%                   arbitrary number of channels
%              (9)  a number - generates a numerical channel selector for 
%                   the specified number of channels


% check input
if nargin == 0 
    channame = '';
end

%% parse channel selection from matlabbatch
if ischar(channame) && strcmpi(channame, 'run')
    job = varargin{1};
    if isfield(job, 'chan_default')
        out = job.chan_default;
    elseif isfield(job, 'chan_nr')
        out = job.chan_nr;
    elseif isfield(job, 'chan_menu')
        out = job.chan_menu;
    elseif isfield(job, 'gaze_pair')
        out = [job.gaze_pair.L_chan_nr(:), job.gaze_pair.R_chan_nr(:)];
    else
        out = 0;
    end

    % convert numbers provided as chars
    if ischar(out)
        if strcmpi(out, num2str(int64(str2num(out))))
            out = str2num(out);
        end
    end

%% gather channel selection in matlabbatch  
% vector definition
elseif isnumeric(channame)
    out         = vec_chan('any', channame);

% vector definition
elseif strcmpi(channame, 'many')
    out         = vec_chan('any', Inf);
    
% numerical or string definition
elseif strcmpi(channame, 'any')
    out         = str_chan(channame);

% numerical definition
elseif isempty(channame)
    out         = num_chan;


% specific pupil options or numerical definition
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
    out = chan_choice;
    out.val     = {pupil_chan(chan_menu, chan_default)};
    out.values  = {pupil_chan(chan_menu, chan_default), num_chan('pupil')};
    out.help    = {sprintf('Specification of %s channel (default: follow precedence order).', 'pupil')};

% specific gaze options or numerical definition
elseif strcmpi(channame, 'gaze')
    gaze_chan_nr = vec_chan('gaze', 2);
    gaze_chan_nr.help = {sprintf('Specify an x/y pair of %s channel numbers.', 'gaze')};
    out = chan_choice;
    out.val     = {gaze_chan(1:4, 4)};
    out.values  = {gaze_chan(1:4, 4), gaze_chan_nr};
    out.help    = {sprintf('Specification of %s channels (default: follow precedence order).', 'gaze')};

elseif strcmpi(channame, 'gaze_pair')
    gaze_chan_nr_L = vec_chan('left gaze', 2);
    gaze_chan_nr_L.tag = 'L_chan_nr';
    gaze_chan_nr_L.name = 'Left gaze channels (x/y pair)';
    gaze_chan_nr_L.help = {sprintf('Specify an x/y pair of %s channel numbers.', 'left gaze')};

    gaze_chan_nr_R = vec_chan('left gaze', 2);
    gaze_chan_nr_R.tag = 'R_chan_nr';
    gaze_chan_nr_R.name = 'Right gaze channels (x/y pair)';
    gaze_chan_nr_R.help = {sprintf('Specify an x/y pair of %s channel numbers.', 'right gaze')};
    
    gaze_pair = cfg_branch;
    gaze_pair.name = 'Numerically define x/y channel pairs'; 
    gaze_pair.tag  = 'gaze_pair';
    gaze_pair.val  = {gaze_chan_nr_L, gaze_chan_nr_R};

    gaze_def = def_chan('', '');
    gaze_def.help = {'Last gaze channel of each type (L x/y and R x/y).'};

    
    out = chan_choice;
    out.val     = {gaze_def};
    out.values  = {gaze_def, gaze_pair};
    out.help    = {sprintf('Specification of %s channels (default: last gaze channel of each type).', 'gaze')};

% numerical definition or default 
else
    if strcmpi(channame, 'marker')
        pos_str = 'First';
    else
        pos_str = 'Last';
    end
    out = chan_choice;
    out.val     = {def_chan(channame, pos_str)};
    out.values  = {def_chan(channame, pos_str), num_chan(channame)};
    out.help    = {sprintf('Number of %s channel (default: %s %s channel).', channame, lower(pos_str), channame)};
end
end

% possible menu items -----------------------------------------------------
function out = chan_choice
    out = cfg_choice;
    out.name    = 'Channel';
    out.tag     = 'chan';
end

function out = def_chan(channame, pos_str)
    out      = cfg_const;
    out.name = 'Default channel';
    out.tag  = 'chan_def';
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

function out = vec_chan(channame, n)
    out = cfg_entry;
    out.name    = 'Channel number';
    out.tag     = 'chan_nr';
    out.strtype = 'i';
    out.num     =  [1 n]; 
    out.help    = {sprintf('Specify %s channel numbers.', channame)};
end

function out = str_chan(channame)
    out         = cfg_entry;
    out.name    = 'Channel specification';
    out.tag     = 'chan_nr';
    out.strtype = 's';
    out.help    = {sprintf('Specify %s channel number or channel type (e.g., "scr", "ecg" or any other type accepted by PsPM.)', channame)};
end

function out = pupil_chan(menu_set, menu_default)

    labels                 = {'Combined pupil channel', 'Both pupil channels', 'Left pupil', 'Right pupil', 'Default', 'None'};
    values                 = {'pupil_c', 'both', 'pupil_l', 'pupil_r', 'pupil', 'none'};
    
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
        'channels in the first existing option, only last the one will be ', ...
        'processed.']};
end

function out = gaze_chan(menu_set, menu_default)

    labels                 = {'Combined gaze channels', 'Left eye', 'Right eye', 'Default'};
    values                 = {{'gaze_x_c', 'gaze_y_c'},{'gaze_x_l', 'gaze_y_l'}, {'gaze_x_r', 'gaze_y_r'}, 'gaze'};
    
    out                    = cfg_menu;
    out.name               = 'Channel specification';
    out.tag                = 'chan_menu';
    out.labels             = labels(menu_set);
    out.values             = values(menu_set);
    out.val                = values(menu_default);
    out.help               = {['Specify gaze channels to process. This will ', ...
        'use the last x/y channels of the specified type. Default is the first ', ...
        'existing option out of the following: ', ...
        '(1) Combined eyes, (2) non-lateralised gaze, (3) best ', ...
        'eye, (4) any gaze channel. If there are multiple ', ...
        'x or y channels in the first existing option, only the last one will be ', ...
        'processed.']};
end


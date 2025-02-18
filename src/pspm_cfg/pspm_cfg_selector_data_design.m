function [out1, out2] = pspm_cfg_selector_data_design(modeltype, varargin)
% pspm_cfg_data_design handles data and design specification for
% statistical models and data extraction. 
% pspm_cfg_data_design(modeltype)
% modeltype: 'glm', 'dcm', 'extract'
% varargin: further specification passed by glm
% session_rep = pspm_cfg_data_design_selector(modeltype, varargin)
% [model, options] = pspm_cfg_data_design_selector('run', varargin)

% run mode ----------------------------------------------------------------
if strcmpi(modeltype, 'run')
    model = struct(); 
    options = struct();
    job = varargin{1};
    nrSession = size(job.session,2);
    for iSession = 1:nrSession
        % datafile
        model.datafile{iSession,1} = job.session(iSession).datafile{1};
        % missing epochs
        model.missing{1,iSession} = pspm_cfg_selector_missing_epochs('run', job.session(iSession));
        % data & design
        if isfield(job.session(iSession).data_design,'no_condition')
            model.timing = {};
        elseif isfield(job.session(iSession).data_design,'condfile')
            model.timing{iSession,1} = job.session(iSession).data_design.condfile{1};
        elseif isfield(job.session(iSession).data_design,'marker_cond')
            if isfield(job.session(iSession).data_design.marker_cond.marker_values,'marker_values_names')
                model.timing{iSession,1}.markervalues = strsplit(job.session(iSession).data_design.marker_cond.marker_values.marker_values_names{1});
            else
                model.timing{iSession,1}.markervalues = job.session(iSession).data_design.marker_cond.marker_values.marker_values_val;
            end
            model.timing{iSession,1}.names  = strsplit(job.session(iSession).data_design.marker_cond.cond_names{1});
        else
            nrCond = size(job.session(iSession).data_design.condition,2);
            for iCond=1:nrCond
                model.timing{iSession,1}.names{1,iCond} = job.session(iSession).data_design.condition(iCond).name;
                model.timing{iSession,1}.onsets{1,iCond} = job.session(iSession).data_design.condition(iCond).onsets;
                if isfield(job.session(iSession).data_design.condition(iCond), 'durations')
                    model.timing{iSession,1}.durations{1,iCond} = job.session(iSession).data_design.condition(iCond).durations;
                end
                if isfield(job.session(iSession).data_design.condition(iCond), 'pmod')
                    nrPmod = size(job.session(iSession).data_design.condition(iCond).pmod,2);
                    if nrPmod ~= 0
                        for iPmod=1:nrPmod
                            model.timing{iSession,1}.pmod(1,iCond).name{1,iPmod} = job.session(iSession).data_design.condition(iCond).pmod(iPmod).name;
                            model.timing{iSession,1}.pmod(1,iCond).param{1,iPmod} = job.session(iSession).data_design.condition(iCond).pmod(iPmod).param;
                            model.timing{iSession,1}.pmod(1,iCond).poly{1,iPmod} = job.session(iSession).data_design.condition(iCond).pmod(iPmod).poly;
                        end
                    else
                        model.timing{iSession,1}.pmod(1,iCond).name = [];
                        model.timing{iSession,1}.pmod(1,iCond).param = [];
                        model.timing{iSession,1}.pmod(1,iCond).poly = [];
                    end
                end
            end
        end
        % nuisance
        if isfield(job.session(iSession), 'nuisancefile') && ~isempty(job.session(iSession).nuisancefile{1})
            model.nuisance{iSession,1} = job.session(iSession).nuisancefile{1};
        else
            model.nuisance{iSession,1} = [];
        end
    end
    % timeunits
    if isfield(job.session(iSession).data_design,'marker_cond')
        model.timeunits = 'markervalues';
    else
        model.timeunits = fieldnames(job.timeunits);
        model.timeunits = model.timeunits{1};
    end
    % marker channel
    if isfield(job.timeunits, 'markers')
        options.marker_chan_num = pspm_cfg_selector_channel('run', job.timeunits.markers.chan);
    end
    out1 = model;
    out2 = options;
    return
end
% input mode --------------------------------------------------------------

% parse input arguments ---------------------------------------------------
if nargin < 1
    modspec = varargin{1}.modspec;
else
    modspec = 'unknown';
end

% standard items
datafile         = pspm_cfg_selector_datafile();
missing          = pspm_cfg_selector_missing_epochs;

% Condition file
condfile         = cfg_files;
condfile.name    = 'Condition File';
condfile.tag     = 'condfile';
condfile.num     = [1 1];
condfile.filter  = '.*\.(mat|MAT)$';
helptext    = {{['Specificy a file with the following variables:']; ...
    ['- names: a cell array of string for the names of the experimental conditions']; ...
    ['- onsets: a cell array of number vectors for the onsets of events for '...
    'each experimental condition, expressed in seconds, marker numbers, '...
    'or samples, as specified in timeunits']}, ...
    {['- durations (optional, default 0): a cell array of vectors for '...
    '  the duration of each event. You need to use ''seconds'' or ''samples'' as time units']}, ...
    {['- pmod: this is used to specify regressors that specify how responses ', ...
    'in an experimental condition depend on a parameter to model the ', ...
    'effect e.g. of habituation, reaction times, or stimulus ratings. pmod ', ...
    'is a struct array corresponding to names and onsets and containing the fields']; ...
    ['  * name: cell array of names for each parametric modulator for this condition']; ...
    ['  * param: cell array of vectors for each parameter for this condition, ', ...
    'containing as many numbers as there are onsets']; ...
    ['  * poly (optional, default 1): specifies the polynomial degree']; ...
    [' - e.g. produce a simple multiple condition file by typing: ', ...
    'names = {''condition a'', ''condition b''}; onsets = {[1 2 3], [4 5 6]}; ' ,...
    'save(''testfile'', ''names'', ''onsets'');']}};
switch modeltype
    case 'glm'
        if strcmpi(modspec, 'sps_fc')
            condfile.help = vertcat(helptext{:});
        else
            condfile.help = vertcat(helptext{[1, 3]});
        end
    case 'extract'
        condfile.help = helptext{1};
end
            

% Name
name         = cfg_entry;
name.name    = 'Name';
name.tag     = 'name';
name.strtype = 's';
%name.num     = [1 1];
name.help    = {'Specify the name of the parametric modulator.'}; % Help text for name of pmod

% Onsets
onsets         = cfg_entry;
onsets.name    = 'Onsets';
onsets.tag     = 'onsets';
onsets.strtype = 'r';
onsets.num     = [1 Inf];
onsets.help    = {['Specify a vector of onsets. The length of the vector corresponds to ' ...
    'the number of events included in this condition. Onsets have to be indicated in the ' ...
    'specified time units.']};

% Parameter
param         = cfg_entry;
param.name    = 'Parameter Values';
param.tag     = 'param';
param.strtype = 'r';
param.num     = [1 Inf];
param.help    = {'Specify a vector with the same length as the vector for onsets.'};

% Polynomial degree
poly= cfg_entry;
poly.name    = 'Polynomial Degree';
poly.tag     = 'poly';
poly.strtype = 'r';
poly.num     = [1 1];
poly.val     = {1};
poly.help    = {['Specify an exponent that is applied to the parametric modulator. A value of 1 ' ...
    'leaves the parametric modulator unchanged and thus corresponds to a linear change over the ' ...
    'values of the parametric modulator (first-order). Higher order modulation introduces further ' ...
    'columns that contain the non-linear parametric modulators [e.g., second-order: (squared), third-order (cubed), etc].']};

% Name
pmodname         = cfg_entry;
pmodname.name    = 'Name';
pmodname.tag     = 'name';
pmodname.strtype = 's';
pmodname.help    = {'Specify the name of the parametric modulator.'};

% Pmod
pmod         = cfg_branch;
pmod.name    = 'Parametric Modulator';
pmod.tag     = 'pmod';
pmod.val     = {pmodname, poly, param};
pmod.help    = {''};

pmod_rep         = cfg_repeat;
pmod_rep.name    = 'Parametric Modulator(s)';
pmod_rep.tag     = 'pmod_rep';
pmod_rep.values  = {pmod};
pmod_rep.num     = [0 Inf];
pmod_rep.help    = {['If you want to include a parametric modulator, specify a vector with the same ' ...
    'length as the vector for onsets.'], ['For example, parametric modulators can model ' ...
    'reaction times, ratings of stimuli, or habituation effects over time. For each parametric ' ...
    'modulator a new regressor is included in the design matrix. The normalized parameters are ' ...
    'multiplied with the respective onset regressors.']};

% Durations vector
durations         = cfg_entry;
durations.name    = 'Durations';
durations.tag     = 'durations';
durations.strtype = 'r';
durations.num     = [1 Inf];
durations.val     = {0};
durations.help    = {['Typically, a duration of 0 is used to model an event onset. If all ' ...
    'events included in this condition have the same length specify just a single number. ' ...
    'If events have different durations, specify a vector with the same length as the vector for onsets.']};

% Name
condname         = cfg_entry;
condname.name    = 'Name';
condname.tag     = 'name';
condname.strtype = 's';
condname.help    = {'Specify the name of the condition.'}; % Help text for name of condition

% Conditions
condition         = cfg_branch;
condition.name    = 'Condition';
condition.tag     = 'condition';
switch modeltype
    case 'glm'
        if strcmpi(modspec, 'sps_fc')
            condition.val     = {condname, onsets, durations, pmod_rep};
        else
            condition.val     = {condname, onsets, pmod_rep};
        end
    case 'extract'
        condition.val     = {condname, onsets};
end
condition.help    = {''};

condition_rep         = cfg_repeat;
condition_rep.name    = 'Enter conditions manually';
condition_rep.tag     = 'condition_rep';
condition_rep.values  = {condition};
condition_rep.num     = [1 Inf];
condition_rep.help    = {'Specify the conditions that you want to include in your design matrix.'};

% markervalues vector of numbers
marker_values_val         = cfg_entry;
marker_values_val.name    = 'Values for conditions';
marker_values_val.tag     = 'marker_values_val';
marker_values_val.strtype = 'r';
marker_values_val.num     = [1 Inf];
marker_values_val.val     = {0};
marker_values_val.help    = {'Specify the values for the conditions.'};

% markervalues cell array of strings
marker_values_names         = cfg_entry;
marker_values_names.name    = 'Names for conditions';
marker_values_names.tag     = 'marker_values_names';
marker_values_names.strtype = 's+';
marker_values_names.num     = [1 Inf];
marker_values_names.help    = {'Specify the names for the conditions.',...
                               ' Separate each name by a whitespace.'};

% condition values for marker based conditions
marker_values        = cfg_choice;
marker_values.name   = 'Condition-defining values/names ';
marker_values.tag    = 'marker_values';
marker_values.values = {marker_values_val, marker_values_names};
marker_values.help   = {'Specify the values or names for the conditions.'};

% condition names for marker based conditions
cond_names         = cfg_entry;
cond_names.name    = 'Name';
cond_names.tag     = 'cond_names';
cond_names.strtype = 's+';
cond_names.num     = [1 Inf];
cond_names.help    = {'Specify the names of the conditions in the same order', ...
                      ' as the conditioning-defining values/names.',...
                      ' Separate each name by a whitespace.'};

% condition from marker
marker_cond        = cfg_branch;
marker_cond.name   = 'Define conditions from distinct values/names of event markers ';
marker_cond.tag    = 'marker_cond';
marker_cond.val    = {marker_values, cond_names};
marker_cond.help   = {'This option defines event onsets according to the values or',...
                     ' names of events stored in a marker channel. These names/values',...
                     ' are imported for some data types.'};
% no condition
no_condition        = cfg_const;
no_condition.name   = 'No condition';
no_condition.tag    = 'no_condition';
no_condition.val    = {0};
no_condition.help   = {['If there is no condition, it is mandatory to ', ...
    'specify a nuisance file. (e. g. for illuminance GLM).']};

% Timing
timing         = cfg_choice;
timing.name    = 'Design';
timing.tag     = 'data_design';
switch modeltype
    case 'glm'
        timing.values  = {condfile, condition_rep, marker_cond ,no_condition};
    case 'extract'
        timing.values  = {condfile, condition_rep, marker_cond};
end

timing.help    = {['Specify the timing of the events within the design matrix. Timing can '...
    'be specified in "seconds", "markers" or "samples" with respect to the beginning of the ' ...
    'data file. See "Time Units" settings. Conditions can be specified manually or by using ' ...
    'multiple condition files (i.e., an SPM-style mat file).']};

% Nuisance
nuisancefile         = cfg_files;
nuisancefile.name    = 'Nuisance File';
nuisancefile.tag     = 'nuisancefile';
nuisancefile.num     = [0 1];
nuisancefile.val{1}  = {''};
nuisancefile.filter  = '.*\.(mat|MAT|txt|TXT)$';
nuisancefile.help    = {['You can include nuisance parameters such as motion parameters in ' ...
    'the design matrix. Nuisance parameters are not convolved with the canonical response function. ', ...
    'This is also used for the illuminance GLM.'], ...
    ['The file has to be either a .txt file containing the regressors in columns, or a .mat file containing ' ...
    'the regressors in a matrix variable called R. There must be as many values for each column of R as there ' ...
    'are data values in your data file. PsPM will call the regressors pertaining to the different columns R1, R2, ...']};

% Sessions
session        = cfg_branch;
session.name   = 'Session';
session.tag    = 'session';
switch modeltype
    case 'glm'
        session.val    = {datafile, missing, timing, nuisancefile};
    case 'extract'
        session.val    = {datafile, missing, timing};
end
session.help   = {''};

session_rep         = cfg_repeat;
session_rep.name    = 'Data & Design';
session_rep.tag     = 'session_rep';
session_rep.values  = {session};
session_rep.num     = [1 Inf];
session_rep.help    = {'Add the appropriate number of sessions here. These will be concatenated.'};

% Marker Channel
mrk_chan         = pspm_cfg_selector_channel('marker');
mrk_chan.help    = {[mrk_chan.help{1}, ' Markers are only used if you have ' ...
    'specified the time units as ''markers''.']};

out1 = session_rep;
out2 = [];


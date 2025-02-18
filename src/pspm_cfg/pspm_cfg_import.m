function import_data = pspm_cfg_import

%% Initialise
global settings

%% Standard items
overwrite = pspm_cfg_selector_overwrite;

%% Get filetype
fileoptions={settings.import.datatypes.long};
channeltypesDescription = {settings.channeltypes.description};
channeltypesData = {settings.channeltypes.data};
cd(settings.path)
cd([settings.path,filesep,'pspm_cfg/'])

%% Predefined struct
% Channel/Column Search
chan_search      = cfg_const;
chan_search.name = 'Search';
chan_search.tag  = 'chan_search';
chan_search.val  = {true};
chan_search.help = {['Search for channel by its name - this only works ', ...
  'if the channel names are unambiguous.']};

% Sample Rate
sample_rate         = cfg_entry;
sample_rate.name    = 'Sample Rate';
sample_rate.tag     = 'sample_rate';
sample_rate.strtype = 'r';
sample_rate.num     = [1 1];
sample_rate.help    = pspm_cfg_help_format('pspm_import', 'import.sr');


% Transfer function
scr_file         = cfg_files;
scr_file.name    = 'File';
scr_file.tag     = 'file';
scr_file.num     = [1 1];
scr_file.filter  = '.*\.(mat|MAT)$';
scr_file.help    = {};

scr_transf_const         = cfg_entry;
scr_transf_const.name    = 'Transfer Constant';
scr_transf_const.tag     = 'transfer_const';
scr_transf_const.strtype = 'r';
scr_transf_const.num     = [1 1];
scr_transf_const.help    = pspm_cfg_help_format('pspm_transfer_function', 'c');

scr_offset         = cfg_entry;
scr_offset.name    = 'Offset';
scr_offset.tag     = 'offset';
scr_offset.strtype = 'r';
scr_offset.num     = [1 1];
scr_offset.help    = pspm_cfg_help_format('pspm_transfer_function', 'offset');

scr_resistor         = cfg_entry;
scr_resistor.name    = 'Series Resistor';
scr_resistor.tag     = 'resistor';
scr_resistor.strtype = 'r';
scr_resistor.num     = [1 1];
scr_resistor.help    = pspm_cfg_help_format('pspm_transfer_function', 'Rs');

scr_recsys           = cfg_menu;
scr_recsys.name      = 'Recording System';
scr_recsys.tag       = 'recsys';
scr_recsys.values    = {'conductance', 'resistance'};
scr_recsys.labels    = {'conductance', 'resistance'};
scr_recsys.val       = {'conductance'};
scr_recsys.help      = pspm_cfg_help_format('pspm_transfer_function', 'recsys');

scr_input       = cfg_branch;
scr_input.name  = 'Input';
scr_input.tag   = 'input';
scr_input.val   = {scr_transf_const,scr_offset,scr_resistor, scr_recsys};
scr_input.help  = {'Enter the transfer constants manually.'};

none      = cfg_const;
none.name = 'None';
none.tag  = 'none';
none.val  = {true};
none.help = {};

scr_transfer         = cfg_choice;
scr_transfer.name    = 'Transfer Function';
scr_transfer.tag     = 'scr_transfer';
scr_transfer.values  = {scr_file,scr_input,none};
scr_transfer.help    = pspm_cfg_help_format('pspm_transfer_function');

eyelink_trackdist         = cfg_entry;
eyelink_trackdist.name    = 'Eyetracker distance';
eyelink_trackdist.tag     = 'eyelink_trackdist';
eyelink_trackdist.val     = {-1};
eyelink_trackdist.num     = [1 1];
eyelink_trackdist.strtype = 'r';
eyelink_trackdist.help    = {['Distance between eyetracker camera and ', ...
  'recorded eyes. Not used if 0 or less. If ', ...
  'spedified (> 0) the data will be converted from arbitrary units to ', ...
  'length units.']};

distance_unit           = cfg_menu;
distance_unit.name      = 'Distance unit';
distance_unit.tag       = 'distance_unit';
distance_unit.values    = {'mm', 'cm', 'm', 'inches'};
distance_unit.labels    = {'mm', 'cm', 'm', 'inches'};
distance_unit.val       = {'mm'};
distance_unit.help      = {['The unit in which the eyetracker distance ', ...
  'is given and to which the pupil data should be converted.']};

viewpoint_target_unit           = cfg_menu;
viewpoint_target_unit.name      = 'Target unit';
viewpoint_target_unit.tag       = 'viewpoint_target_unit';
viewpoint_target_unit.values    = {'mm', 'cm', 'm', 'inches'};
viewpoint_target_unit.labels    = {'mm', 'cm', 'm', 'inches'};
viewpoint_target_unit.val       = {'mm'};
viewpoint_target_unit.help      = {'The unit to which the gaze data should be converted.'};

smi_target_unit           = cfg_menu;
smi_target_unit.name      = 'Target unit';
smi_target_unit.tag       = 'smi_target_unit';
smi_target_unit.values    = {'mm', 'cm', 'm', 'inches'};
smi_target_unit.labels    = {'mm', 'cm', 'm', 'inches'};
smi_target_unit.val       = {'mm'};
smi_target_unit.help      = {'The unit to which the data should be converted.'};

smi_stimulus_resolution           = cfg_entry;
smi_stimulus_resolution.name      = 'Stimulus Resolution';
smi_stimulus_resolution.tag       = 'smi_stimulus_resolution';
smi_stimulus_resolution.val       = {[-1 -1]};
smi_stimulus_resolution.num       = [1 2];
smi_stimulus_resolution.help      = {['The resolution of the stimulus window. This field is required' ...
  'to perform px to mm conversions for gaze channels']};

delimiter           = cfg_entry;
delimiter.name      = 'Delimiter';
delimiter.tag       = 'delimiter';
delimiter.strtype   = 's';
delimiter.help      = {['The delimiter to be used for file reading, ',...
  'leave blank to use any whitespace character.']};

header_lines           = cfg_entry;
header_lines.name      = 'Header lines';
header_lines.tag       = 'header_lines';
header_lines.strtype   = 'r';
header_lines.val       = {1};
header_lines.help      = {'The number of lines used by the header. By default 1.'};

channel_names_line         = cfg_entry;
channel_names_line.name    = 'Channel names line';
channel_names_line.tag     = 'channel_names_line';
channel_names_line.strtype = 'r';
channel_names_line.val     = {1};
channel_names_line.help    = {'The line number where the channel/column names are specified. By default 1.'};

exclude_columns           = cfg_entry;
exclude_columns.name      = 'Exclude columns';
exclude_columns.tag       = 'exclude_columns';
exclude_columns.strtype   = 'r';
exclude_columns.val       = {0};
exclude_columns.help      = {['The number of columns which have to be excluded for the importing. By default 0. ',...
  'It is useful if the first columns have non numeric data (e.g. timestamps). ', ...
  'Be aware that if you exclude some columns you have to adapt the channel number.']};

%% Datatype dependend items
datatype_item = cell(1,length(fileoptions));
for datatype_i=1:length(fileoptions)

  %% Settings
  if settings.import.datatypes(datatype_i).autosr == 1
    samplerate = -1;
  else
    samplerate = 0;
  end
  % If more than one channel can be defined
  multioption  = settings.import.datatypes(datatype_i).multioption;
  description  = settings.import.datatypes(datatype_i).chandescription;
  % Capitalize description
  description  = regexprep(description,'(\<\w)','${upper($1)}');
  searchoption = settings.import.datatypes(datatype_i).searchoption;
  automarker   = settings.import.datatypes(datatype_i).automarker;
  channeltypes    = settings.import.datatypes(datatype_i).channeltypes;
  short        = settings.import.datatypes(datatype_i).short;
  ext          = settings.import.datatypes(datatype_i).ext;
  help         = pspm_cfg_help_format('import', settings.import.datatypes(datatype_i).help);


  %% Channel/Column Number
  % Default Channel Nr.
  chan_nr_def         = cfg_const;
  chan_nr_def.name    = ['Default ' description ' Number'];
  chan_nr_def.tag     = 'chan_nr_def';
  chan_nr_def.val     = {0};
  chan_nr_def.help    = {''};

  % Sepcify Channel/Column Nr.
  chan_nr_spec         = cfg_entry;
  chan_nr_spec.name    = ['Specify ' description ' Number'];
  chan_nr_spec.tag     = 'chan_nr_spec';
  chan_nr_spec.strtype = 'i';
  chan_nr_spec.num     = [1 1];
  chan_nr_spec.help    = {};

  % Channel/Column Nr. (variable choice options)
  chan_nr        = cfg_choice;
  chan_nr.name   = [description ' Number'];
  chan_nr.tag    = 'chan_nr';
  chan_nr.help   = pspm_cfg_help_format('pspm_import', 'import.channel');

  %% Flank option for 'event' channel types
  flank_option        = cfg_menu;
  flank_option.name   = 'Marker flank (for continuous marker data only)';
  flank_option.tag    = 'flank_option';
  flank_option.values = {'both', 'ascending', 'descending', 'all'};
  flank_option.labels = {'both', 'ascending', 'descending', 'all'};
  flank_option.val    = {'both'};
  flank_option.help   = pspm_cfg_help_format('pspm_get_events', 'import.flank');

  %% Channel/Column Type Items
  importtype_item = cell(1,length(channeltypes));
  for importtype_i=1:length(channeltypes)
    importtype_item{importtype_i}       = cfg_branch;
    % Find channeltype description
    channeltypesDescIdx = find(strcmp({settings.channeltypes.type},channeltypes{importtype_i}));
    if ~isempty(channeltypesDescIdx)
      importtype_item{importtype_i}.name = channeltypesDescription{channeltypesDescIdx};
    else
      importtype_item{importtype_i}.name  = channeltypes{importtype_i};
    end
    importtype_item{importtype_i}.tag   = channeltypes{importtype_i};
    importtype_item{importtype_i}.help  = {''};

    % Check for different Channel/Column options
    if strcmp(channeltypes(importtype_i), 'marker') && automarker
      % Def->0
      chan_nr_def.val = {0};
      chan_nr.val    = {chan_nr_def};
      chan_nr.values = {chan_nr_def};
    elseif searchoption
      if multioption
        % Choice: Search->0; Spec->Nr
        chan_nr.val    = {};
        chan_nr.values = {chan_search,chan_nr_spec};
      else
        % Choice: Search->0; Def->1
        chan_nr_def.val = {1};
        chan_nr.val    = {};
        chan_nr.values = {chan_search,chan_nr_def};
      end
    else
      if multioption
        % Spec->Nr
        chan_nr.val    = {chan_nr_spec};
        chan_nr.values = {chan_nr_spec};
      else
        % Def->1
        chan_nr_def.val = {1};
        chan_nr.val    = {chan_nr_def};
        chan_nr.values = {chan_nr_def};
      end
    end

    if strcmp(channeltypesData{channeltypesDescIdx}, 'events')
      importtype_item{importtype_i}.val = {chan_nr,flank_option};
    else
      importtype_item{importtype_i}.val = {chan_nr};
    end


    % Check for sample rate
    if samplerate == 0
      importtype_item{importtype_i}.val = [importtype_item{importtype_i}.val,{sample_rate}];
    end

    % Check for scr transfer function
    if strcmp(channeltypes(importtype_i), 'scr')
      importtype_item{importtype_i}.val = [importtype_item{importtype_i}.val,{scr_transfer}];
    end

  end

  importtype         = cfg_choice;
  importtype.name    = [description ' Type'];
  importtype.tag     = 'importtype';
  importtype.values  = importtype_item;
  importtype.help    = {'Specify the type of data in this channel.'};

  if multioption == 1
    importchan         = cfg_repeat;
    importchan.name    = [description 's'];
    importchan.tag     = 'importchan';
    importchan.values  = {importtype};
    importchan.num     = [1 Inf];
    importchan.help    = {'Define all channels that you want to import.'};
  end


  %% ACQ related
  acq_import_python          = pspm_cfg_selector_python('Bioread', '3.0.1');
  acq_import_python.help     = {['Import Biopac Acqknowledge (ACQ) files with the python package "Bioread". ',...
                                  'Any ACQ version is supported.']};
  % Data File
  datafile         = pspm_cfg_selector_datafile(ext);
  if strcmpi(ext, 'any')
    datafile.filter ='.*';
  end

  if any(strcmpi(settings.import.datatypes(datatype_i).short, 'smi'))
    input_file = cfg_files;
    input_file.name = 'Sample and optional Event Files';
    input_file.num = [1 2];
    input_file.tag = 'datafile';
    if strcmpi(ext, 'any')
      event_file.filter ='.*';
    else
      event_file.filter  = ['.*\.(' ext '|' upper(ext) ')$'];
    end

    datafile         = cfg_repeat;
    datafile.name    = 'Data File(s)';
    datafile.tag     = 'datafile';
    datafile.num     = [1 Inf];
    datafile.values  = {input_file};
  end

  datatype_item{datatype_i}       = cfg_branch;
  datatype_item{datatype_i}.name  = fileoptions{datatype_i};
  datatype_item{datatype_i}.tag   = short;
  datatype_item{datatype_i}.help  = help;
  if multioption == 1
    datatype_item{datatype_i}.val   = {datafile,importchan};
  else
    datatype_item{datatype_i}.val   = {datafile,importtype};
  end

  % For eyelink: add stuff
  % TODO: this is a very bad (unsustainable/unmaintainable) way of doing this.
  % Refactor this part by even possibly dividing pspm_cfg_import to several files.
  if any(strcmp(settings.import.datatypes(datatype_i).short, 'eyelink'))
    datatype_item{datatype_i}.val = ...
      [datatype_item{datatype_i}.val, {eyelink_trackdist, distance_unit}];
  end

  if any(strcmpi(settings.import.datatypes(datatype_i).short, 'viewpoint'))
    datatype_item{datatype_i}.val = ...
      [datatype_item{datatype_i}.val, {viewpoint_target_unit}];
  end

  if any(strcmpi(settings.import.datatypes(datatype_i).short, 'smi'))
    datatype_item{datatype_i}.val = ...
      [datatype_item{datatype_i}.val, {smi_target_unit, smi_stimulus_resolution}];
  end

  if any(strcmpi(settings.import.datatypes(datatype_i).short, 'txt'))
    datatype_item{datatype_i}.val = ...
      [datatype_item{datatype_i}.val, {header_lines,channel_names_line,exclude_columns}];
  end

  if any(strcmpi(settings.import.datatypes(datatype_i).short, 'csv'))
    datatype_item{datatype_i}.val = ...
      [datatype_item{datatype_i}.val, {header_lines,channel_names_line,exclude_columns}];
  end

  if any(strcmpi(settings.import.datatypes(datatype_i).short, 'dsv'))
    datatype_item{datatype_i}.val = ...
      [datatype_item{datatype_i}.val, {delimiter,header_lines,channel_names_line,exclude_columns}];
  end

   if any(strcmpi(settings.import.datatypes(datatype_i).short, 'acq_any'))
     datatype_item{datatype_i}.val = ...
       [datatype_item{datatype_i}.val, {acq_import_python}];
   end
end

%% Data type
datatype         = cfg_choice;
datatype.name    = 'Data Type';
datatype.tag     = 'datatype';
datatype.values  = datatype_item;
datatype.help    = {''};

%% Executable branch
import_data      = cfg_exbranch;
import_data.name = 'Import';
import_data.tag  = 'import';
import_data.val  = {datatype, overwrite};
import_data.prog = @pspm_cfg_run_import;
import_data.vout = @pspm_cfg_vout_outfile;
import_data.help = pspm_cfg_help_format('pspm_import');


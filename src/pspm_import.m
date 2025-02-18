function [sts, outfile] = pspm_import(datafile, datatype, import, options)
% ● Description
%   pspm_import imports data from various formats and writes them to
%   a PsPM file on the same path, with the original file name prepended with 
%   'pspm_'. Please refer to the PsPM manual or the help of the individual 
%   'pspm_get_[datatype] functions for data-type specific information.
% ● Format
%   [sts, outfile] = pspm_import(datafile, datatype, import, options)
% ● Arguments
%   *          datafile : [char] file name
%   *          datatype : supported datatype as defined in pspm_init (see manual).
%   *            import : A cell array of struct, with one cell per
%                         channel to be imported.
%   ┌────────────import 
%   ├─────────────.type : [mandatory for all data types and each job] Channel  
%   │                     type as defined in pspm_init (see manual). Not all data
%   │                     types support all channel types.
%   ├───────────────.sr : [mandatory for some data types and each channel] Sampling rate
%   │                     for waveforms, or time units in second for event channels, in Hz.
%   ├──────────.channel : [mandatory for some data types and each channel, 
%   │                     positive integer; will search if set to 0 and data type allows] 
%   │                     Specify where in the data file to find the channel; 
%   │                     should be a positive integer (i. e. the n-th channel 
%   │                     in the file); for some data types it is also 
%   │                     possible to search for the channel by its name. 
%   │                     Note: the channel number refers to the n-th recorded 
%   │                     channel, not to its number or index in the 
%   │                     recording software. For some data types, these can differ.
%   ├────────────.flank : [optional, string] The flank option specifies which of the
%   │                     rising edge (ascending), falling edge (descending), both
%   │                     edges or their mean (middle) of a marker impulse should be
%   │                     imported into the marker channel;
%   │                     The flank option is applicable for continuous channels only
%   │                     and accepts 'ascending', 'descending', or 'both';
%   │                     The default value is 'both' that means to select the middle of
%   │                     the impulse; Some exceptions are Eyelink, ViewPoint and
%   │                     SensoMotoric Instruments data, for which the default are
%   │                     respectively ''both'', ''ascending'', ''ascending'';
%   │                     If the numbers of rising and falling edges differ, PsPM will
%   │                     throw an error.
%   ├─────────.transfer : [optional, string/struct] For SCR data only. Name of a .mat file containing values for
%   │                     the transfer function, OR a struct array containing the values
%   │                     OR 'none', when no conversion is required (c and optional
%   │                     Rs and offset; See pspm_transfer_function for more information).
%   ├.eyelink_trackdist : The distance between eyetracker and the participants' eyes; If
%   │                     is a numeric value the data in a pupil channel obtained with
%   │                     an eyelink eyetracking system are converted from arbitrary
%   │                     units to distance unit; If value is 'none' the conversion is
%   │                     disabled; (only for Eyelink imports).
%   ├────.distance_unit : Unit in which the eyelink_trackdist is measured; If
%   │                     eyelink_trackdist contains a numeric value, the default value is
%   │                     'mm' otherwise the distance unit is ''; Accepted values include
%   │                     'mm', 'cm', 'm', and 'inches'.
%   ├──────────.denoise : for continuous marker channels or those recorded as digital level
%   │                     with two values (e.g. CED spike); retains markers of duration
%   │                     longer than the value given here (in seconds).
%   └────────.delimiter : for delimiter separated values, value used as delimiter for
%                         file read.
%   ┌───────────options
%   └────────.overwrite : overwrite existing files by default. [logical] (0 or 1)
%                         Define whether to overwrite existing output files or not.
%                         Default value: determined by pspm_overwrite.
% ● Output
%   *           outfile : [char] name of a .mat file on the input file path containing the
%                         imported data. For datatypes that support multiple sessions
%                         of non-contiguous data in one file (e.g. ADInstruments LabChart),
%                         these will be saved separately, and outfile will be a cell
%                         array of file names.
% ● Developer notes
%   Structure of PsPM import
%     pspm_import is a general function for handling of import jobs. It checks
%     the import job, calls a datatype-specific function to extract data from
%     the file, then calls channel-specific functions to convert the data,
%     writes them to file, and checks the consistency of the output file using
%     pspm_load_data.
%   Guideline for new data type functions:
%   - functions are named as 'pspm_get_datatype' and called
%     [sts, import, sourceinfo] = pspm_get_datatype(filename, import)
%   - data type must be described in pspm_init - see there for details
%   - the function needs to take an import job and add, or each job, fields
%   -- .data - the actual data
%   -- .sr   - the sample rate for this channel (only if enabled in pspm_init)
%   - optional fields
%   -- .marker - for marker channels (see pspm_get_marker)
%   -- .markerinfo - same
%   -- .minfreq - minimum frequency for pulse channels
%   -- .units - if data units are defined by the recording software
%   - sourceinfo contains information on the source file, with field
%        -- .channel - a cell of string descriptions of the imported source
%                    channels, e. g. names, or numbers
%       and any optional fields that will be added to infos.source (e. g.
%           recording date & time, and others)
%   Guideline for new channel functions:
%   - functions are named as 'pspm_get_channeltype' and called
%      [sts, data] = pspm_get_channeltype(import)
%   - see pspm_load_data for the required structure of 'data'
%   Notes for multiple blocks:
%   file formats that support multiple block storage within one file can
%   return cell arrays import{1:blkno} and sourceinfo{1:blkno}; SCRalyze will
%   save individual files for each block, with a filename 'pspm_fn_blk0x.mat'
% ● History
%   Introduced in PsPM 3.0
%   Written in 2008-2015 Dominik R Bach (Wellcome Trust Centre for Neuroimaging)
%   Maintained in 2022 by Teddy

%% 1 Initialise
global settings
if isempty(settings)
    pspm_init;
end
sts = -1;
outfile = [];

%% 2 Input argument check & transform
if nargin < 1
    warning('ID:invalid_input', ...
        'No input file');
    return
elseif ~ischar(datafile)
    warning('ID:invalid_input', ...
        'Input file needs to be a string or cell array');
    return
elseif ~exist(datafile, 'file')
    warning('ID:nonexistent_file', ...
        'Input file %s does not exist.', datafile);
    return
elseif nargin < 2
    warning('ID:invalid_input', ...
        'No data type');
    return
elseif ~ischar(datatype)
    warning('ID:invalid_input', ...
        'Data type needs to be a string');
    return
elseif sum(strcmpi(datatype, {settings.import.datatypes.short})) == 0
    warning('ID:invalid_chantype', ...
        'Data type (%s) not recognised', datatype);
    return
elseif nargin < 3
    warning('ID:invalid_input', ...
        'No import job');
    return
elseif ~iscell(import)
    if isstruct(import) && numel(import) == 1
        import = {import};
    else
        warning('ID:invalid_input', ...
            'Import needs to be a cell array of struct, or a single struct');
        return
    end
end

if nargin < 4
    options = struct();
end
options = pspm_options(options, 'import');
if options.invalid
    return
end

%% 3 Check import jobs
% 3.1 determine datatype
datatype = find(strcmpi(datatype, {settings.import.datatypes.short}));
% 3.2 check number of jobs
% more than one job when only one is allowed?
if (~settings.import.datatypes(datatype).multioption) && (numel(import) > 1)
    % two jobs when one is an automatically assigned marker channel?
    if ~(settings.import.datatypes(datatype).automarker && numel(import) == 2 && ...
            any(strcmpi({import{1}.type, import{2}.type}, 'marker')))
        warning('ID:ivalid_import_struct', ...
            'Only one data channel can be imported at a time for data type ''%s''.\n', ...
            settings.import.datatypes(datatype).long); return
    end
end
% 3.3 check each job
for k = 1:numel(import)
    % channel type specified?
    if ~isfield(import{k}, 'type')
        warning('ID:ivalid_import_struct', ...
            'No type given for import job %2.0f.\n', k);
        return
        % channel type allowed for this datatype?
    elseif sum(strcmpi(import{k}.type, settings.import.datatypes(datatype).channeltypes)) == 0
        warning('ID:ivalid_import_struct', ...
            'Channel type ''%s'' in import job %2.0f is not supported for data type %s.\n', ...
            import{k}.type, k, settings.import.datatypes(datatype).long);
        return
        % sample rate given or automatically assigned?
    elseif ~isfield(import{k}, 'sr') && ~settings.import.datatypes(datatype).autosr
        warning('ID:ivalid_import_struct', ...
            'Sample rate needed for import job %02.0f of type %s.\n', ...
            k, import{k}.type);
        return
        % sample rate given AND automatically assigned? If yes, remove and say so.
    elseif isfield(import{k}, 'sr') && settings.import.datatypes(datatype).autosr
        import{k} = rmfield(import{k}, 'sr');
        fprintf('Sample rate for import job %02.0f of type %s discarded - will be automatically assigned.\n', ...
            k, import{k}.type);
    end
    % marker channel in data format where no channel name is needed?
    if strcmpi(import{k}.type, 'marker') && settings.import.datatypes(datatype).automarker
        import{k}.channel = 1;
    end
    % flank loading
    if ~isfield(import{k}, 'flank')
        l_type = {settings.channeltypes.data};
        if strcmp(l_type{strcmp({settings.channeltypes.type},{import{k}.type})},'wave')
            import{k}.flank = 'both'; % set both at the default flank
        end
    else
        if ~strcmp(import{k}.flank, 'ascending') && ...
                ~strcmp(import{k}.flank, 'descending') && ...
                ~strcmp(import{k}.flank, 'both')
            warning('ID:invalid_import_struct', ...
                'The option flank can only be ascending, descending or both.');
            return
        end
    end
    % channel number given? If not, set to zero, or assign automatically and display.
    if ~isfield(import{k}, 'channel')
        if ~isfield(import{k}, 'channel')
            if settings.import.datatypes(datatype).searchoption
                import{k}.channel = 0;
            else
                import{k}.channel = k;
                fprintf('\nAssigned channel/column %1.0f to import job %1.0f of type %s.', k, k, import{k}.type);
            end
        end
    end
    % assign channel type number
    import{k}.typeno = find(strcmpi(import{k}.type, {settings.channeltypes.type}));
end

%% Work on the data file
if ~settings.developmode
    fprintf('\n\xBB Importing %s: ', datafile);
end
% 4.1 pass over to import function if datafile exists, otherwise next file
[lsts, import, sourceinfo] = feval(settings.import.datatypes(datatype).funct, datafile, import);
if lsts < 1
    fprintf('\nImport unsuccesful for file %s.\n', datafile);
    return;
end
% 4.2 split blocks if necessary (e.g. for LabChart data with
% non-contiguous blocks). In this case, sourceinfo and import will have
% been split into blocks by the import function above
if iscell(sourceinfo)
    blkno = numel(sourceinfo);
else
    blkno = 1;
    sourceinfo = {sourceinfo};
    import{1} = import;
end
% 4.3 Loop
for blk = 1:blkno
    % 4.3.1 convert data into desired channel type format
    data = cell(numel(import{blk}), 1);
    for k = 1:numel(import{blk})
        if ~isfield(import{blk}{k}, 'units'), import{blk}{k}.units = 'unknown'; end
        channeltype = find(strcmpi(import{blk}{k}.type, {settings.channeltypes.type}));
        [lsts(k), data{k}] = feval(settings.channeltypes(channeltype).import, import{blk}{k});
        if isfield(import{blk}{k}, 'minfreq'), data{k}.header.minfreq = import{blk}{k}.minfreq; end
    end
    if any(lsts < 1), fprintf('\nData conversion unsuccesful for job %02.0f file %s.\n', ...
            find(slts < 1), datafile); return; end
    % 4.3.2 collect infos and save
    [pth, fn, ~] = fileparts(datafile);
    infos.source = sourceinfo{blk};
    infos.source.type = settings.import.datatypes(datatype).long;
    infos.source.file = datafile;
    infos.importdate = date;
    % 4.3.3 align data length
    [lsts, data, duration] = pspm_align_channels(data);
    if lsts < 1
        fprintf('\nData alignment unsuccesful for file %s.\n', datafile);
        return
    end
    infos.duration   = duration;
    infos.durationinfo = 'Recording duration in seconds';
    data = data(:);
    % 4.3.4 save file
    if blkno == 1
        outfile{blk}=fullfile(pth, ...
            [settings.import.fileprefix, fn, '.mat']);
    else
        outfile{blk}=fullfile(pth, ...
            sprintf('%s%s_blk%02.0f.mat', settings.import.fileprefix, fn, blk));
    end
    infos.importfile = outfile{blk};
    clear savedata
    savedata.data = data;
    savedata.infos = infos;
    savedata.options = options;
    lsts = pspm_load_data(outfile{blk}, savedata);
    if lsts ~= 1
        warning('Import unsuccessful for file %s.\n', datafile);
        outfile{blk} = [];
    end
end
if ~settings.developmode
    fprintf('Done.\n');
end

if numel(outfile) == 1
    outfile = outfile{1};
end
sts = 1;

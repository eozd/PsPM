function [sts, data] = pspm_check_data(data, infos)
% ● Description
%   pspm_checks_data checks a PsPM data (and, optional, infos) structure
%   This function is used throughout PsPM (and in particular in
%   pspm_load_data). It returns a data cell array with legacy and format
%   conversions.
% ● Format
%   [sts, data] = pspm_check_data(data, infos)
% ● Developer's notes
%   This code is taken from pspm_load_data; it could be improved using cellfun.
% ● History
%   Introducted in Version 7.0
%   Written by Dominik R Bach (Bonn)

global settings
if isempty(settings)
    pspm_init;
end
sts = -1;

if nargin < 1
    warning('ID:invalid_input', 'No input - don''t know what to do');
    return
end

% check infos
if nargin > 1
    flag_infos = 0;
    if ~isstruct(infos) || isempty(fieldnames(infos)) || ~isfield(infos, 'duration')
        warning('ID:invalid_data_structure', 'Invalid infos structure.');
        return
    end
else
    flag_infos = 1;
end

% initialise error flags --
vflag = zeros(numel(data), 1); % records data structure, valid if 0
wflag = zeros(numel(data), 1);
nflag = zeros(numel(data), 1);

% loop through channels
for k = 1:numel(data)
    % Check header --
    if ~isfield(data{k}, 'header')
        vflag(k) = 1;
    else
        % Convert header channeltype into chantype if there are --
        if isfield(data{k}.header, 'channeltype')
            data{k}.header.chantype = data{k}.header.channeltype;
            data{k}.header = rmfield(data{k}.header, 'channeltype');
        end
        if ~isfield(data{k}.header, 'chantype') || ...
                ~isfield(data{k}.header, 'sr') || ...
                ~isfield(data{k}.header, 'units')
            vflag(k) = 1;
        else
            if ~ismember(lower(data{k}.header.chantype), {settings.channeltypes.type})
                nflag(k) = 1;
            end
        end
    end
    % Check data --
    if vflag(k)==0 && nflag(k)==0
        % required information is available and valid in header and infos
        if ~isfield(data{k}, 'data')
            vflag(k) = 1;
        else
            if isempty(data{k}.data)
                warning('ID:missing_data', 'Channel %01.0f is empty.', k);
                % convert empty data to a generalised 1-by-0 matrix
                data{k}.data = zeros(1,0);
            elseif ~isvector(data{k}.data)
                vflag(k) = 1;
            elseif size(data{k}.data, 1) < size(data{k}.data, 2)
                data{k}.data = data{k}.data(:);
                warning('ID:invalid_data_structure', ...
                    'Channel %i seems to have the wrong orientation. Trying to transpose...', k);
            end
            if ~flag_infos && ~vflag(k)
                if strcmpi(data{k}.header.units, 'events')
                    if (any(data{k}.data > infos.duration) || any(data{k}.data < 0))
                        wflag(k) = 1;
                    end
                    if isfield(data{k}, 'markerinfo')
                        if ~isfield(data{k}.markerinfo, 'name') || ...
                                ~isfield(data{k}.markerinfo, 'value') || ...
                                numel(data{k}.markerinfo.name) ~= numel(data{k}.data) || ...
                                numel(data{k}.markerinfo.value) ~= numel(data{k}.data) || ...
                                ~iscell(data{k}.markerinfo.name) || ...
                                ~isvector(data{k}.markerinfo.value)
                            % invalid markerinfo structure is removed to
                            % ensure backwards compatibility (introduced in
                            % v7.0)
                            warning('ID:invalid_data_structure', 'Invalid markerinfo structure removed. This will become an error in the future.')
                            data{k} = rmfield(data{k}, 'markerinfo');
                        end
                    end
                else
                    if (length(data{k}.data) < infos.duration * data{k}.header.sr - 3 ||...
                            length(data{k}.data) > infos.duration * data{k}.header.sr + 3)
                        wflag(k) = 1;
                    end
                end
            end
        end
    end
end

if any(vflag)
    errmsg = [sprintf('Invalid data structure for channel %01.0f.', find(vflag,1))];
    warning('ID:invalid_data_structure', '%s', errmsg);
    return
end
if any(wflag)
    errmsg = [sprintf(['The data in channel %01.0f is out of ',...
        'the range [0, infos.duration]'], k)];
    warning('ID:invalid_data_structure', '%s', errmsg);
    return
end
if any(nflag)
    errmsg = [sprintf('Unknown channel type %s in channel %01.0f', data{find(nflag,1)}.header.chantype, find(nflag,1))];
    warning('ID:invalid_data_structure', '%s', errmsg);
    return
end

sts = 1;


function [sts, import] = pspm_get_events(import)
% ● Description
%   pspm_get_events processes events for different event channel types
% ● Format
%   [sts, data] = pspm_get_events(import)
% ● Arguments
%   ┌────import
%   ├─────.data : mandatory
%   ├───.marker : mandatory, accepts 'timestamps' and 'continuous'.
%   ├───────.sr : timestamps: timeunits in seconds, continuous: sample rate
%   │             in 1/seconds)
%   ├────.flank : [optional, string] Only used for importing continuous
%   │             event channels. This specifies which flank of the event 
%   │             marker to use. 'both' (default, specifies the event at 
%   │             the middle between the ascending and descending flank), 
%   │             'ascending', 'descending',  'all' (imports ascending and 
%   │             descending flank as separate events).
%   └──.denoise : for continuous marker channels: only retains markers of
%                 duration longer than the value given here (in seconds).
% ● Output
%   *    import : returns event timestamps in seconds in import.data
% ● History
%   Introduced in PsPM 3.0
%   Written in 2013-2015 by Dominik R Bach & Tobias Moser (University of Zurich)
%   Updated in 2024      by Dominik R Bach (Uni Bonn)

%% Initialise
global settings
if isempty(settings)
  pspm_init;
end
sts = -1;

% get data
% -------------------------------------------------------------------------
if ~isfield(import, 'marker')
  warning('ID:nonexistent_field', 'The field ''marker'' is missing'); return;
elseif strcmpi(import.marker, 'continuous')
  % determine relevant data points

  % filtering noise does not yet work! -> any kind of noise will be
  % identified as maxima/minima

  % copy from findLocalMaxima / findpeaks / signal processing toolbox
  % with a small change not to loose data with diff()
  data = import.data;

  % ensure the incoming data is in the format we need it to be
  % to process it accordingly (must be vertical)
  dim = size(data);
  if dim(1) == 1
    data = data';
  end

  possible_values = unique(data);
  min_values_indices = data == min(possible_values);
  max_values_indices = data == max(possible_values);
  data_orig = data;
  data = (data + min(possible_values)) / (max(possible_values) - min(possible_values));
  data(min_values_indices) = 0;
  data(max_values_indices) = 1;
  % add more data in order to prevent deleting values with diff
  data = [0; 0; 0; data; 0; 0; NaN;];
  % store information about finite and infinite in vector
  % used to reduce temp vector to relevant data
  finite = ~isnan(data);
  % initialize temp array and transpose to have a vertical vector
  temp = (1:numel(data)).';

  % just pick inequal neighbor values of which at least one has a valid
  % value
  iNeq = [1; 1+ find((data(1:end-1) ~= data(2:end)) ...
    & ((finite(1:end-1) | finite(2:end))))];
  temp = temp(iNeq);

  % we want to check for a difference within a trend
  % not for a difference between values -> usage of sign()
  % diff the whole dataset not to loose relevant data
  s = sign(diff(data));
  d = diff(s);

  % where are the sign changes of the corresponding differences
  % lo2hi should be minima
  % hi2lo should be maxima
  lo2hi = temp(1+find(d(temp(2:end-1)-2) > 0))-3;
  hi2lo = temp(1+find(d(temp(2:end-1)-2) < 0))-4;

  % denoise
  if isfield(import, 'denoise') && isnumeric(import.denoise) && import.denoise > 0
     initial_level = lo2hi(1) > hi2lo(1);
     last_level    = lo2hi(end) > hi2lo(end);
     if initial_level
         lo2hi = [1; lo2hi];
     end
     if last_level
         hi2lo = [hi2lo; numel(import.data)];
     end
     pulse_duration = diff([lo2hi(:), hi2lo(:)], [], 2)/import.sr;
     pulse_index = find(pulse_duration > import.denoise);
     lo2hi = lo2hi(pulse_index);
     hi2lo = hi2lo(pulse_index);
     if initial_level && lo2hi(1) == 1 % if initial level not already removed
         lo2hi = lo2hi(2:end);
     end
     if last_level && hi2lo(end) == numel(import.data) % if last level not already removed
         hi2lo = hi2lo(1:(end-1));
     end
  end

  if isempty(lo2hi) && isempty(hi2lo)
    fprintf('\n');
    warning('No markers, or problem with TTL channel.');
    import.data = [];
  elseif isfield(import,'flank') && strcmpi(import.flank, 'all')
    allMrk = find(import.data);
    import.data = allMrk./import.sr;
    mPos = allMrk+3;
  elseif isfield(import, 'flank') && strcmpi(import.flank, 'ascending')
    import.data = lo2hi./import.sr;
    mPos = lo2hi+3;
  elseif isfield(import, 'flank') && strcmpi(import.flank, 'descending')
    import.data = (hi2lo+1)./import.sr;
    mPos = hi2lo+3;
  elseif numel(lo2hi) == numel(hi2lo)
    % only use mean if amount of minima corresponds to amount of maxima
    % otherwise output a warning
    import.data = mean([lo2hi, hi2lo], 2)./import.sr;
    mPos = mean([lo2hi, hi2lo],2);
    mPos = mPos+3;
  else
    fprintf('\n');
    warning('Different number of hi2lo and lo2hi transitions in marker channel - please choose ascending or descending flank.');
    import.data = [];
    return;
  end

  % check if markerinfo should be set and if there are any data points
  if ~isfield(import, 'markerinfo') && ~isempty(import.data)

    % determine baseline
    v = unique(data_orig(~isnan(data_orig)));
    for i=1:numel(v)
      v(i,2) = numel(find(data_orig == v(i,1)));
    end

    % ascending sorting: most frequent value is at the end of this
    % vector
    v = sortrows(v, 2);
    baseline = v(end, 1);

    % we are interested in the delta -> remove `baseline offset`
    values = data_orig(round(mPos) - 3) - baseline;
    import.markerinfo.value = values;

    % prepare values to convert them into strings
    values = num2cell(values);
    import.markerinfo.name = cellfun(@num2str, values, 'UniformOutput', false);


    % add one second of tolerance because tails are added at the
    % beginning. and maybe sometimes values might not be exactly the
    % same
  elseif isfield(import, 'markerinfo') && ...
      (numel(data) - numel(import.markerinfo.value))/import.sr < 1
    % also translate marker info if necessary. this code was written
    % with and for import_eyelink function. there flank = 'all'
    % has to be set to use import.data as index for the marker values.

    n_minfo = struct('value', {import.markerinfo.value(round(import.data*import.sr))}, ...
      'name', {import.markerinfo.name(round(import.data*import.sr))});

    import.markerinfo = n_minfo;
  end

elseif strcmpi(import.marker, 'timestamp') || strcmpi(import.marker, 'timestamps')
  import.data = import.data(:) .* import.sr;
else
  warning('ID:invalid_field_content', 'The value of ''marker'' must either be ''continuous'' or ''timestamps'''); return;
end

% set status
% -------------------------------------------------------------------------
sts = 1;
return

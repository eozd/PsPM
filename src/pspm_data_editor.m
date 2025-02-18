function [sts, out] = pspm_data_editor(varargin)
% ● Description
%   pspm_data_editor MATLAB code for pspm_data_editor.fig
% ● Format
%   [sts, out]  = pspm_data_editor(indata, options)
% ● Arguments
%   *      indata:  a file name. 
%   ┌─────options 
%   ├.output_file:  When this is specified, marked epochs will be saved
%   │               to a missing epochs file when clicking 'save' or 'apply'.
%   │               It is also possible to specificy this file from within 
%   │               the interactive data editor.
%   ├─.epoch_file:  When this is specified, epochs will be imported from 
%   │               this file and can be changed further. This file must 
%   │               contain a variable 'epochs' which is an n x 2 matrix 
%   │               of epoch on- and offsets (n: number of epochs). It is 
%   │               also possible to specificy this file from within the
%   │               interactive data editor.
%   └──.overwrite:  [logical] (0 or 1)
%                   Define whether to overwrite existing output file or not.
%                   Default: 0.
% ● Outputs
%   *         out:  The output depends on the actual output type chosen in
%                   the graphical interface. At the moment either the
%                   interpolated data or epochs only can be chosen as
%                   output of the function.
% ● History
%   Introduced in PsPM 3.1
%   Written in 2015 by Tobias Moser (University of Zurich)
%   Maintained in 2021 by Teddy
%   Updated in 2024 by Teddy for UI controller display

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
  'gui_Singleton',  gui_Singleton, ...
  'gui_OpeningFcn', @pspm_data_editor_OpeningFcn, ...
  'gui_OutputFcn',  @pspm_data_editor_OutputFcn, ...
  'gui_LayoutFcn',  [] , ...
  'gui_Callback',   []);

if nargin && ischar(varargin{1}) && ...
    (numel(regexp(fullfile(varargin{1}), filesep)) == 0)
  gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
  [sts, out] = gui_mainfcn(gui_State, varargin{:});
else
  gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT


function pspm_data_editor_OpeningFcn(hObject, ~, handles, varargin)
% Feature
%   Executes just before pspm_data_editor is made visible.
%   This function has no output args, see OutputFcn.
% Variables
%   hObject    handle to figure
%   eventdata  reserved - to be defined in a future version of MATLAB
%   handles    structure with handles and user data (see GUIDATA)
% Varargin
%   command line arguments to pspm_data_editor (see VARARGIN)

%% Initialise
global settings
if isempty(settings)
  pspm_init;
end
sts = -1;
pspm_ui(hObject, handles, 'data_editor');
if get(handles.rbInterpolate, 'Value')
  set(handles.cbInterpolate, 'Enable', 'on');
  handles.output_type = 'interpolate';
else
  set(handles.cbInterpolate, 'Enable', 'off');
  handles.output_type = 'epochs';
end
% Choose default command line output for pspm_data_editor
handles.output = {};
handles.mode = 'default';
handles.select = struct();
handles.plots = {};
handles.selected_data = [];
handles.epochs = {};
handles.highlighted_epoch = -1;
handles.data = {};
handles.input_mode = '';
handles.input_file = '';
handles.output_file = '';
set(handles.pspm_data_editor, 'WindowButtonDownFcn', @buttonDown_Callback);
set(handles.pspm_data_editor, 'WindowButtonUpFcn', @buttonUp_Callback);
set(handles.pspm_data_editor, 'WindowButtonMotionFcn', @buttonMotion_Callback);
if numel(varargin) > 1 && isstruct(varargin{2}) % load options
  handles.options = varargin{2};
  handles.options = pspm_options(handles.options, 'data_editor');
  if handles.options.invalid
    return
  end
  if isfield(handles.options, 'output_file') && ischar(handles.options.output_file)
    % check if options are valid and assign accordingly
    handles.output_file = handles.options.output_file;
    set(handles.edOutputFile, 'String', handles.output_file);
  end
  if isfield(handles.options, 'epoch_file') && ischar(handles.options.epoch_file)
    handles.epoch_file = handles.options.epoch_file;
    set(handles.edOpenMissingEpochFilePath, 'String', handles.epoch_file);
  end
end
guidata(hObject, handles); % Update handles structure
if numel(varargin) > 0
  switch class(varargin{1})
    case 'char'
      if exist(varargin{1}, 'file')
        set(handles.pnlInput, 'Visible', 'on');
        set(handles.pnlOutput, 'Visible', 'on');
        loadFromFile(hObject, varargin{1});
      else
        warning('File ''%s'' does not exist.', varargin{1});
      end
    case 'double'
      set(handles.pnlInput, 'Visible', 'off');
      handles.data = varargin{1};
      handles.input_mode = 'raw';
  end
  handles = guidata(hObject);
  guidata(hObject, handles);
  PlotData(hObject);
  % % enable the following code if output file module wants to be enabled
  % if isfield(handles, 'options') && isfield(handles.options, 'output_file')
  %   set(handles.pnlOutput, 'Visible', 'off');
  % end
  % if isfield(handles, 'options') && ~isfield(handles.options, 'epoch_file')
  %   set(handles.pnlEpoch, 'Visible', 'off');
  % end
  if isfield(handles, 'options') && isfield(handles.options, 'epoch_file')
    handles.epoch_file = handles.options.epoch_file;
    Add_Epochs(hObject, handles)
  end
end
uiwait(handles.pspm_data_editor);

function [sts] = CreateOutput(hObject)
handles = guidata(hObject);
sts = -1;
if strcmpi(handles.input_mode, 'file') && strcmpi(handles.output_file, '')
  msgbox('No output file specified. Cannot create output.','Error','error');
else
  out_file = handles.output_file;
  switch handles.output_type
    case 'interpolate'
      InterpolateData(hObject); % again run interpolation
      plots = ~cellfun(@isempty, handles.plots);
      interp = cellfun(@(x) get(x.interpolate, 'YData'), ...
        handles.plots(plots), 'UniformOutput', 0);
      if strcmpi(handles.input_mode, 'file')
        channels = find(plots);
        newd.data = handles.data;
        newd.infos = handles.infos;
        for i=1:numel(channels) % replace interpolated data
          newd.data{i}.data = interp{i}';
        end
        write_file = 1;
        % Used to have a variable write_success = 0 here
        disp_success = 1;
        if exist(out_file, 'file')
          button = questdlg(sprintf(['File (%s) already exists. ', ...
            'Add channels or replace file?'], out_file), ...
            'Add or replace channels?', 'Add channels', ...
            'Replace file', 'Cancel', 'Cancel');
          if strcmpi(button, 'Add channels')
            [~, ~] = pspm_write_channel(out_file, ...
              newd.data(plots), 'add');
            write_file = 0;
          elseif strcmpi(button, 'Cancel')
            disp_success = 0;
            write_file = 0;
          end
        end
        if write_file
          newd.options.overwrite = pspm_overwrite(out_file, 1);
          [write_success, ~, ~] = pspm_load_data(out_file, newd);
          if disp_success
            if write_success
              helpdlg('File successfully written.',...
                'File successfully written.');
            else
              errordlg('Could not write file correctly.',...
                'Error while saving file.');
            end
          end
        end
      else
        handles.output = interp;
      end
      sts = 1;
    case 'epochs'
      ep = cellfun(@(x) x.range', handles.epochs, 'UniformOutput', 0);
      epochs = cell2mat(ep)';
      if strcmpi(handles.input_mode, 'file')
        ow = pspm_overwrite(out_file, 1);
        if ow
          save(out_file, 'epochs');
        end
      else
        handles.output = epochs;
      end
      sts = 1;
    otherwise
      handles.output = {};
      sts = 1;
  end
end
guidata(hObject, handles);

function loadFromFile(hObject, file)
handles = guidata(hObject);
handles.selected_data(:) = NaN; % clear epochs
guidata(hObject, handles);
UpdateEpochList(hObject);
handles = guidata(hObject);
handles.channels = {}; % clear channels
set(handles.lbChannel, 'String', '');
for i=1:numel(handles.plots) % remove plots
  if ~isempty(handles.plots{i})
    RemovePlot(hObject, i);
  end
end
[~, infos, data] = pspm_load_data(file); % load file
channels = cellfun(@(x) {x.header.chantype,x.header.units}, data, 'UniformOutput', 0);
set(handles.edOpenFilePath, 'String', file);
corder = get(handles.pspm_data_editor, 'defaultAxesColorOrder'); % format channels
cl = length(corder)-2;
disp_names = cell(numel(channels), 1);
for i = 1:numel(channels)
  if strcmpi(channels{i}(2), 'events')
    disp_names{i} = sprintf('<html><font color="#DDDDDD">%s</font></html>', channels{i}{1});
  else
    m = floor((i-0.1)/cl);
    color = corder(i - m*cl, :);
    disp_names{i} = sprintf('<html><font bgcolor="#%02s%02s%02s">%s</font></html>',...
      dec2hex(round(color(1)*255)), ...
      dec2hex(round(color(2)*255)), ...
      dec2hex(round(color(3)*255)), ...
      channels{i}{1});
  end
end
set(handles.lbChannel, 'String', disp_names);
handles.data = data;
handles.infos = infos;
handles.input_mode = 'file';
handles.plots = cell(size(data));
guidata(hObject, handles);
PlotData(hObject);

function PlotData(hObject)
global settings
handles = guidata(hObject);
channel = {};
switch handles.input_mode % load data
  case 'file'
    sr = max(cellfun(@(x) x.header.sr, handles.data)); % get highest sample rate
    xdata = (0:sr^-1:handles.infos.duration)';
    chan_id = get(handles.lbChannel, 'Value');
    if ~any(numel(handles.data) < chan_id)
      channel = chan_id;
    else
      warning('Cannot plot selected channel(s).');
    end
  case 'raw'
    xdata = (1:numel(handles.data))';
    channel = 1;
end
handles.selected_data = NaN(numel(xdata),1);
handles.x_data = xdata;
guidata(hObject, handles);
if ~isempty(channel)
  np = get(handles.axData, 'NextPlot');
  action = 'replace';
  for i=1:numel(channel)
    AddPlot(hObject, channel(i), action);
    % Update y-axis label based on selected channel
    action = 'add';
  end
  set(handles.axData, 'NextPlot', np);
end

function AddPlot(hObject, chan_id, action)
global settings
handles = guidata(hObject);
if isempty(action)
  action = 'replace';
end
np = get(handles.axData, 'NextPlot');
set(handles.axData, 'NextPlot', action);
corder = get(handles.pspm_data_editor, 'defaultAxesColorOrder');
cl = length(corder)-2;
m = floor((chan_id-0.1)/cl);
color = corder(chan_id - m*cl, :);
if strcmpi(handles.input_mode, 'file')
  sr = handles.data{chan_id}.header.sr;
  ydata = handles.data{chan_id}.data;
  xdata = (sr^-1:sr^-1:handles.infos.duration)';
  n_diff =  numel(ydata) - numel(xdata);
  if n_diff < 0
    xdata = xdata(1:end+n_diff);
  elseif n_diff > 0
    start_from = xdata(end);
    xdata(end:end+n_diff) = start_from:sr^-1:(start_from+n_diff*sr^-1);
  end
else
  xdata = 1:numel(handles.data); % used to have a transpose here, but seems a little irrelational
  ydata = handles.data;
  sr = 1;
end
handles.axData = gca;
p = plot(xdata,ydata, 'Color', color);
xlabel('time -- second');
ylabel([handles.data{chan_id}.header.chantype, ' -- ', handles.data{chan_id}.header.units]);
handles.axData.FontSize = 14;
set(handles.axData, 'NextPlot', 'add');
NaN_data = NaN(numel(xdata),1);
handles.plots{chan_id}.sr = sr;
handles.plots{chan_id}.data_plot = p;
handles.plots{chan_id}.y_data = ydata;
handles.plots{chan_id}.x_data = xdata;
handles.plots{chan_id}.sel_container = hggroup;
handles.plots{chan_id}.highlight_plot = plot(xdata,NaN_data, 'LineWidth', 1.5, 'Color', corder(end,:));
handles.plots{chan_id}.interpolate = plot(xdata,NaN_data, 'LineWidth', 0.5, 'Color', corder(end-1,:), 'LineStyle', '--');
uistack(handles.plots{chan_id}.interpolate, 'bottom');
for i=1:numel(handles.epochs) % add response plots
  rp_x = handles.plots{chan_id}.x_data;
  rp_y = NaN(1,numel(handles.plots{chan_id}.x_data));
  range = rp_x > handles.epochs{i}.range(1) & rp_x < handles.epochs{i}.range(2);
  rp_y(range) = handles.plots{chan_id}.y_data(range);
  p = plot(rp_x, rp_y, 'Color', 'green', 'Parent', handles.plots{chan_id}.sel_container);
  handles.epochs{i}.response_plots{chan_id} = struct('p', p);
end
set(handles.axData, 'NextPlot', np);
guidata(hObject, handles);

function RemovePlot(hObject, chan_id)
global settings
handles = guidata(hObject);
if numel(handles.plots) >= chan_id
  for i = 1:numel(handles.epochs) % remove response plots
    if numel(handles.epochs{i}.response_plots) >= chan_id ...
        && ~isempty(handles.epochs{i}.response_plots{chan_id})
      delete(handles.epochs{i}.response_plots{chan_id}.p);
      handles.epochs{i}.response_plots{chan_id} = [];
    end
  end
  delete(handles.plots{chan_id}.data_plot);
  delete(handles.plots{chan_id}.sel_container);
  delete(handles.plots{chan_id}.highlight_plot);
  delete(handles.plots{chan_id}.interpolate);
  handles.plots{chan_id} = []; % empty entry
end
guidata(hObject, handles);

function varargout = pspm_data_editor_OutputFcn(hObject, ~, handles)
% Feature
%   Outputs from this function are returned to the command line.
% Varargout
%   cell array for returning output args (see VARARGOUT);
% Variables
%   hObject    handle to figure
%   eventdata  reserved - to be defined in a future version of MATLAB
%   handles    structure with handles and user data (see GUIDATA)
% UIWAIT makes pspm_data_editor wait for user response (see UIRESUME)
% handles.lbEpochsvarargout{1} = handles.output;
delete(hObject);

function lbEpochs_Callback(hObject, ~, ~)
% Feature
%   Executes on selection change in lbEpochs.
% Variables
%   hObject    handle to lbEpochs (see GCBO)
%   eventdata  reserved - to be defined in a future version of MATLAB
%   handles    structure with handles and user data (see GUIDATA)
% Hints
%   contents = cellstr(get(hObject,'String')) returns lbEpochs contents as cell array
%   contents{get(hObject,'Value')} returns selected item from lbEpochs
epId = get(hObject,'Value');
HighlightEpoch(hObject, epId);

function ResetEpochHighlight(hObject)
handles = guidata(hObject);
for i=1:numel(handles.epochs)
  if handles.epochs{i}.highlighted
    for j=1:numel(handles.epochs{i}.response_plots)
      if ~isempty(handles.epochs{i}.response_plots{j})
        set(handles.epochs{i}.response_plots{j}.p, ...
          'Color', 'green',  ...
          'LineWidth',0.5 ...
          );
      end
    end
    handles.epochs{i}.highlighted = false;
  end
end
guidata(hObject, handles);

function HighlightEpoch(hObject, epId)
handles = guidata(hObject);
ResetEpochHighlight(hObject); % reset all epochs
if numel(handles.epochs) > 0 % is there anything to highlight?
  ep = handles.epochs{epId};
  ep.highlighted = true;
  handles.epochs{epId} = ep;
  for i = 1:numel(ep.response_plots) % highlight epochs
    if ~isempty(ep.response_plots{i})
      set(ep.response_plots{i}.p, 'Color', 'black', 'LineWidth', 1.5);
    end
  end
  cur_xlim = get(handles.axData, 'xlim');
  start = cur_xlim(1);
  stop = cur_xlim(2);
  x_dist = stop-start;
  new_dist = ep.range(2)-ep.range(1);
  dstart = min(handles.x_data);
  dstop = max(handles.x_data);
  data_dist = dstop - dstart;
  if (x_dist < data_dist)
    % try to set xlim
    if (new_dist > x_dist) % zoom out
      start = ep.range(1);
      stop = ep.range(2);
    else
      % try to center data
      offset = (x_dist-new_dist)/2;
      start = ep.range(1) - offset;
      stop = ep.range(2) + offset;
      if start < dstart
        start = dstart;
        stop = dstart+x_dist;
      elseif stop > dstop
        stop = dstop;
        start = stop-x_dist;
      end
    end
    set(handles.axData, 'xlim', [start,stop]);
  elseif x_dist >= data_dist
    start = dstart;
    stop = dstop;
    set(handles.axData, 'xlim', [start,stop]);
  end
  x_dist = stop - start;
  % try to set ylim
  plots = ~cellfun(@isempty, handles.plots);
  minmax = cellfun(@(x) [max(x.y_data(x.x_data >= ep.range(1)& x.x_data <= ep.range(2))), ...
    max(x.y_data), min(x.y_data(x.x_data >= ep.range(1)& x.x_data <= ep.range(2))), min(x.y_data)], ...
    handles.plots(plots), 'UniformOutput', false);
  minmax = cell2mat(minmax);
  to = max(minmax(:,1));
  from = min(minmax(:,3));
  dmax = max(minmax(:,2));
  dmin = min(minmax(:,4));
  cur_ylim = get(handles.axData, 'ylim');
  y_dist = cur_ylim(2) - cur_ylim(1);
  new_dist = to - from;
  if new_dist ~= y_dist
    if new_dist > y_dist
      start = from;
      stop = to;
    elseif new_dist < y_dist
      if data_dist > x_dist
        offset = (y_dist-new_dist)/2;
        start = from - offset;
        stop = to + offset;
        if (stop > dmax || start < dmin) && ...
            (round(dmax-dmin)==round(stop-start))
          stop = dmax;
          start = dmin;
        end
      else
        start = dmin;
        stop = dmax;
      end
    end
    set(handles.axData, 'ylim', [start,stop]);
  end
  handles.highlighted_epoch = epId;
  guidata(hObject, handles);
end

function lbEpochs_CreateFcn(hObject, ~, ~)
% Feature
%   Executes during object creation, after setting all properties.
% Variables
%   hObject    handle to lbEpochs (see GCBO)
%   eventdata  reserved - to be defined in a future version of MATLAB
%   handles    empty - handles not created until after all CreateFcns called
% Hint
%   listbox controls usually have a white background on Windows.
%   See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
  set(hObject,'BackgroundColor','white');
end

function pspm_data_editor_CreateFcn(~, ~, ~)
% Feature
%   Executes during object creation, after setting all properties.
% Variables
%   hObject    handle to pspm_data_editor (see GCBO)
%   eventdata  reserved - to be defined in a future version of MATLAB
%   handles    empty - handles not created until after all CreateFcns called

function tlCursor_ClickedCallback(~, ~, ~)
% Variables
%   hObject    handle to tlCursor (see GCBO)
%   eventdata  reserved - to be defined in a future version of MATLAB
%   handles    structure with handles and user data (see GUIDATA)
set(gcf, 'Pointer', 'arrow');

function tlAddEpoch_OffCallback(hObject, ~, handles)
% Variables
%   hObject    handle to tlAddEpoch (see GCBO)
%   eventdata  reserved - to be defined in a future version of MATLAB
%   handles    structure with handles and user data (see GUIDATA)
handles.mode = 'default';
set(gcf,'Pointer','arrow'); % change to crosshair
handles.select.start = [0,0];
handles.select.stop = [0,0];
handles.select.p = 0;
guidata(hObject, handles);

function tlAddEpoch_OnCallback(hObject, ~, handles)
% Variables
%   hObject    handle to tlAddEpoch (see GCBO)
%   eventdata  reserved - to be defined in a future version of MATLAB
%   handles    structure with handles and user data (see GUIDATA)
set(handles.tlRemoveEpoch, 'State', 'off');
set(handles.tlZoomin, 'State', 'off');
set(handles.tlZoomout, 'State', 'off');
set(handles.tlNavigate, 'State', 'off');
pan off;
zoom off;
handles.mode = 'addepoch';
set(gcf,'Pointer','crosshair'); % change to crosshair
handles.select.start = [0,0];
handles.select.stop = [0,0];
handles.select.p = 0;
guidata(hObject, handles);

function tlRemoveEpoch_OffCallback(hObject, ~, handles)
% Variables
%   hObject    handle to tlRemoveEpoch (see GCBO)
%   eventdata  reserved - to be defined in a future version of MATLAB
%   handles    structure with handles and user data (see GUIDATA)
handles.mode = 'default';
set(gcf,'Pointer','arrow');
guidata(hObject, handles);

function tlRemoveEpoch_OnCallback(hObject, ~, handles)
% Variables
%   hObject    handle to tlRemoveEpoch (see GCBO)
%   eventdata  reserved - to be defined in a future version of MATLAB
%   handles    structure with handles and user data (see GUIDATA)
set(handles.tlAddEpoch, 'State', 'off');
set(handles.tlZoomin, 'State', 'off');
set(handles.tlZoomout, 'State', 'off');
set(handles.tlNavigate, 'State', 'off');
pan off;
zoom off;
handles.mode = 'removeepoch';
set(gcf,'Pointer','crosshair'); % change to crosshair
handles.select.start = [0,0];
handles.select.stop = [0,0];
handles.select.p = 0;
guidata(hObject, handles);

function tlZoomin_OnCallback(~, ~, handles)
% Variables
%   hObject    handle to tlZoomin (see GCBO)
%   eventdata  reserved - to be defined in a future version of MATLAB
%   handles    structure with handles and user data (see GUIDATA)
set(handles.tlRemoveEpoch, 'State', 'off');
set(handles.tlAddEpoch, 'State', 'off');
set(handles.tlZoomout, 'State', 'off');
set(handles.tlNavigate, 'State', 'off');
pan off;
z = zoom;
set(z, 'Motion', 'horizontal');
set(z, 'Direction', 'in');
% unset OnCallback while enabling zoomin otherwise this would end up in a
% recurstion loop (dont know why exactly)
cb = get(handles.tlZoomin, 'OnCallback');
set(handles.tlZoomin, 'OnCallback', '');
set(z, 'Enable', 'on');
set(handles.tlZoomin, 'OnCallback', cb);

function drawSelection(hObject)
handles = guidata(hObject);
pt = get(handles.axData, 'CurrentPoint');
pos = pt(1,1:2);
start = handles.select.start;
x = [start(1), pos(1), pos(1), start(1)];
y = [start(2), start(2), pos(2), pos(2)];
if handles.select.p ~= 0
  p = handles.select.p;
  set(p, 'XData', x);
  set(p, 'YData', y);
else
  p = patch(x,y, 'white', 'FaceColor', 'none');
  handles.select.p = p;
end
guidata(hObject, handles);

function buttonDown_Callback(hObject, ~)
% Comment
%   Used to be `buttonDown_Callback(hObject, data)`, but the variable
%   data seems to be not used.
handles = guidata(hObject); % get current cursor position
switch handles.mode
  case {'addepoch','removeepoch'}
    pt = get(handles.axData, 'CurrentPoint');
    handles.select.start = pt(1,1:2);
end
guidata(hObject, handles);

function buttonUp_Callback(hObject, ~)
% Comment
%   Used to be `buttonUp_Callback(hObject, data)`, but the variable
%   data seems to be not used.
% get current cursor position
handles = guidata(hObject);
switch handles.mode
  case 'addepoch'
    pt = get(handles.axData, 'CurrentPoint');
    handles.select.stop = pt(1,1:2);
    if handles.select.p ~= 0
      delete(handles.select.p);
      handles.select.p = 0;
    end
    guidata(hObject, handles); % add selected area and draw
    SelectedArea(hObject, 'add');
  case 'removeepoch'
    pt = get(handles.axData, 'CurrentPoint');
    handles.select.stop = pt(1,1:2);
    if handles.select.p ~= 0
      delete(handles.select.p);
      handles.select.p = 0;
    end
    guidata(hObject, handles); % add selected area and draw
    SelectedArea(hObject, 'remove');
end
UpdateEpochList(hObject);

function buttonMotion_Callback(hObject, ~)
% Comment
%   Used to be `buttonMotion_Callback(hObject, data)`, but the variable
%   data seems to be not used.
handles = guidata(hObject);
if isfield(handles, 'mode')
  switch handles.mode
    case {'addepoch', 'removeepoch'}
      if isequal(handles.select.stop,[0,0]) && ...
          ~isequal(handles.select.start,[0,0])
        drawSelection(hObject);
        SelectedArea(hObject, 'highlight');
      end
  end
end

function SelectedArea(hObject, action)
handles = guidata(hObject);
if isfield(handles, 'x_data')
  start = handles.select.start;
  if strcmpi(action, 'highlight')
    pt = get(handles.axData, 'CurrentPoint');
    stop = pt(1,1:2);
  else
    stop = handles.select.stop;
    for i = 1:numel(handles.plots) % turn highlight off
      p = handles.plots{i};
      if ~isempty(p)
        xd = p.x_data;
        highlight_yd = NaN(numel(xd),1);
        set(p.highlight_plot, 'YData', highlight_yd');
      end
    end
  end
end
if start(1) > stop(1)
  x_from = stop(1);
  x_to = start(1);
else
  x_from = start(1);
  x_to = stop(1);
end
sel_x = handles.x_data;
switch action
  case 'add'
    handles.selected_data(sel_x >= x_from & sel_x <= x_to) = 1;
  case 'remove'
    handles.selected_data(sel_x >= x_from & sel_x <= x_to) = NaN;
  case 'highlight'
    for i=1:numel(handles.plots)
      p = handles.plots{i};
      if ~isempty(p)
        xd = p.x_data;
        yd = p.y_data;
        r = xd >= x_from & xd <= x_to;
        if strcmpi(handles.mode, 'removeepoch')
          ep = findSelectedEpochs(hObject);
          sel_d = zeros(size(xd));
          for j=1:size(ep,1)
            sel_d(xd >= ep(j,1) & xd <= ep(j,2)) = 1;
          end
          r = r & sel_d;
        end
        highlight_yd = NaN(numel(xd),1);
        highlight_yd(r) = yd(r);
        set(p.highlight_plot, 'YData', highlight_yd');
      end
    end
end
if ~strcmpi(action, 'highlight')
  handles.select.start = [0,0];
  handles.select.stop = [0,0];
end
guidata(hObject, handles);

function InterpolateData(hObject)
handles = guidata(hObject);
interp_state = get(handles.cbInterpolate, 'Value');
if strcmpi(handles.output_type, 'interpolate')
  for i=1:numel(handles.plots)
    if ~isempty(handles.plots{i})
      xd = handles.plots{i}.x_data;
      yd = handles.plots{i}.y_data;
      for j = 1:numel(handles.epochs)
        range = xd >= handles.epochs{j}.range(1) & xd <= handles.epochs{j}.range(2);
        yd(range) = NaN;
      end
      [~, newyd] = pspm_interpolate(yd);
      if ~isempty(newyd)
        set(handles.plots{i}.interpolate, 'YData', newyd);
      end
      if interp_state == 0
        set(handles.plots{i}.interpolate, 'Visible', 'off')
      else
        set(handles.plots{i}.interpolate, 'Visible', 'on')
      end
    end
  end
else
  for i=1:numel(handles.plots)
    if ~isempty(handles.plots{i})
      NaN_data = NaN(numel(handles.plots{i}.x_data),1);
      set(handles.plots{i}.interpolate, 'YData', NaN_data);
    end
  end
end
guidata(hObject, handles);

function epochs = findSelectedEpochs(hObject)
handles = guidata(hObject);
sd = handles.selected_data;
v_pos = find(~isnan(sd));
xd = handles.x_data;
if numel(v_pos)>=1
  epoch_end = xd([v_pos(diff(v_pos) > 1); v_pos(end)]);
  epoch_start = xd(v_pos([1;find(diff(v_pos) > 1)+1]));
  epochs = [epoch_start, epoch_end];
else
  epochs = [];
end

function UpdateEpochList(hObject)
handles = guidata(hObject);
if numel(handles.plots) > 0
  ep = findSelectedEpochs(hObject);
  epochs = handles.epochs;
  for i=1:size(ep,1) % add epochs if necessary
    response_plots = cell(numel(handles.plots),1);
    k = 1;
    epochFound = false;
    while ~epochFound && k <= numel(epochs)
      if epochs{k}.range == ep(i,1:2)
        epochFound = true;
      end
      k = k+1;
    end
    if ~epochFound % add epoch if not found
      hold on;
      for j=1:numel(handles.plots)
        if ~isempty(handles.plots{j})
          rp_y = NaN(1,numel(handles.plots{j}.x_data));
          rp_x = handles.plots{j}.x_data;
          sta = ep(i,1);
          sto = ep(i,2);
          r = rp_x >= sta & rp_x <= sto;
          rp_y(r) = handles.plots{j}.y_data(r);
          p = plot(rp_x, rp_y, 'Color', 'green', 'Parent', handles.plots{j}.sel_container);
          response_plots{j} = struct('p', p, 'p_id', j);
        end
      end
      hold off;
      epochs{numel(epochs) + 1} = struct( ...
        'name', sprintf('%d -- %d', ep(i,1), ep(i,2)) , ...
        'range', ep(i, 1:2), ...
        'highlighted', false, ...
        'response_plots', {response_plots} ...
        );
    end
  end
  if numel(epochs) ~= size(ep,1) % remove epochs if necessary
    i = 1;
    while i <= numel(epochs)
      epochFound = false;
      k = 1;
      while ~epochFound && k <= size(ep,1)
        if epochs{i}.range == ep(k, 1:2)
          epochFound = true;
        end
        k = k+1;
      end
      if ~epochFound
        for j=1:numel(epochs{i}.response_plots)
          if ~isempty(epochs{i}.response_plots{j})
            delete(epochs{i}.response_plots{j}.p);
          end
        end
        epochs(i) = [];
      else
        i = i+1;
      end
    end
  end
  names = cellfun(@(x) x.name, epochs, 'UniformOutput', 0); % add the new names to the current list
  % Used to have a line
  %   names = [handles.lbEpochs.String;names];
  % here, but seems not necessary
  sel_ep = get(handles.lbEpochs, 'Value');
  if sel_ep > numel(names)
    sel_ep = max(numel(names), 1);
    set(handles.lbEpochs, 'Value', sel_ep);
  elseif (sel_ep == 0) && (numel(names) > 0)
    sel_ep = 1;
    handles.highlighted_epoch = -1;
    set(handles.lbEpochs, 'Value', sel_ep);
  end
  set(handles.lbEpochs, 'String', names);
  handles.epochs = epochs;
  guidata(hObject, handles);
  InterpolateData(hObject);
end

function tlNavigate_OffCallback(~, ~, ~)
% Variables
%   hObject    handle to tlNavigate (see GCBO)
%   eventdata  reserved - to be defined in a future version of MATLAB
%   handles    structure with handles and user data (see GUIDATA)
pan off;

function tlNavigate_OnCallback(~, ~, handles)
% Variables
%   hObject    handle to tlNavigate (see GCBO)
%   eventdata  reserved - to be defined in a future version of MATLAB
%   handles    structure with handles and user data (see GUIDATA)
set(handles.tlRemoveEpoch, 'State', 'off');
set(handles.tlZoomin, 'State', 'off');
set(handles.tlZoomout, 'State', 'off');
set(handles.tlAddEpoch, 'State', 'off');
zoom off;
pan on;

function tlZoomout_OnCallback(~, ~, handles)
% Variables
%   hObject    handle to tlZoomout (see GCBO)
%   eventdata  reserved - to be defined in a future version of MATLAB
%   handles    structure with handles and user data (see GUIDATA)
set(handles.tlRemoveEpoch, 'State', 'off');
set(handles.tlZoomin, 'State', 'off');
set(handles.tlAddEpoch, 'State', 'off');
set(handles.tlNavigate, 'State', 'off');
pan off;
z = zoom;
set(z, 'Motion', 'horizontal');
set(z, 'Direction', 'out');
set(z, 'Enable', 'on');

function tlNext_ClickedCallback(hObject, ~, handles)
% Variables
%   hObject    handle to tlNext (see GCBO)
%   eventdata  reserved - to be defined in a future version of MATLAB
%   handles    structure with handles and user data (see GUIDATA)
if handles.highlighted_epoch == -1 || ...
    handles.highlighted_epoch >= numel(handles.epochs)
  new_ep = 1;
else
  new_ep = handles.highlighted_epoch + 1;
end
set(handles.lbEpochs, 'Value', new_ep);
HighlightEpoch(hObject, new_ep);

function tlPrevious_ClickedCallback(hObject, ~, handles)
% Variables
%   hObject    handle to tlPrevious (see GCBO)
%   eventdata  reserved - to be defined in a future version of MATLAB
%   handles    structure with handles and user data (see GUIDATA)
if handles.highlighted_epoch == -1 || ...
    handles.highlighted_epoch == 1 || ...
    handles.highlighted_epoch > numel(handles.epochs)
  new_ep = numel(handles.epochs);
else
  new_ep = handles.highlighted_epoch - 1;
end
set(handles.lbEpochs, 'Value', new_ep);
HighlightEpoch(hObject, new_ep);

function pbApply_Callback(hObject, ~, handles)
% Feature
%   Executes on button press in pbApply.
% Variables
%   hObject    handle to pbApply (see GCBO)
%   eventdata  reserved - to be defined in a future version of MATLAB
%   handles    structure with handles and user data (see GUIDATA)
if CreateOutput(hObject) == 1
  uiresume(handles.pspm_data_editor);
end

function pbCancel_Callback(hObject, ~, handles)
% Feature
%   Executes on button press in pbCancel.
% Variables
%   hObject    handle to pbCancel (see GCBO)
%   eventdata  reserved - to be defined in a future version of MATLAB
%   handles    structure with handles and user data (see GUIDATA)
handles.output = {};
guidata(hObject, handles);
if isfield(handles, 'pspm_data_editor')
  uiresume(handles.pspm_data_editor);
end

function cbInterpolate_Callback(hObject, ~, ~)
% Feature
%   Executes on button press in cbInterpolate.
% Variables
%   hObject    handle to cbInterpolate (see GCBO)
%   eventdata  reserved - to be defined in a future version of MATLAB
%   handles    structure with handles and user data (see GUIDATA)
% Hint
%   get(hObject,'Value') returns toggle state of cbInterpolate
InterpolateData(hObject);

function ppOutput_CreateFcn(hObject, ~, ~)
% Feature
%   Executes during object creation, after setting all properties.
% Variables
%   hObject    handle to ppOutput (see GCBO)
%   eventdata  reserved - to be defined in a future version of MATLAB
%   handles    empty - handles not created until after all CreateFcns called
% Hint
%   popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
  set(hObject,'BackgroundColor','white');
end

function pspm_data_editor_CloseRequestFcn(hObject, ~, handles)
% Feature
%   Executes when user attempts to close pspm_data_editor.
% Variables
%   hObject    handle to pspm_data_editor (see GCBO)
%   eventdata  reserved - to be defined in a future version of MATLAB
%   handles    structure with handles and user data (see GUIDATA)
% Hint
%   delete(hObject) closes the figure
handles.output = {};
if isfield(handles, 'pspm_data_editor')
  uiresume(handles.pspm_data_editor);
end
delete(hObject);

function lbChannel_Callback(hObject, ~, handles)
% Feature
%   Executes on selection change in lbChannel.
% Variables
%   hObject    handle to lbChannel (see GCBO)
%   eventdata  reserved - to be defined in a future version of MATLAB
%   handles    structure with handles and user data (see GUIDATA)
% Hints
%   contents = cellstr(get(hObject,'String')) returns lbChannel contents as cell array
%   contents{get(hObject,'Value')} returns selected item from lbChannel
if strcmpi(handles.input_mode, 'file')
  plots = find(cellfun(@(x) ~isempty(x), handles.plots));
  sel = get(hObject, 'Value');
  to_plot = sel(~ismember(sel, plots));
  to_remove = plots(~ismember(plots, sel));
  for i=1:numel(to_remove)
    RemovePlot(hObject, to_remove(i));
  end
  for i=1:numel(to_plot)
    if ~strcmpi(handles.data{to_plot(i)}.header.units, 'events')
      AddPlot(hObject, to_plot(i), 'add');
    end
  end
  InterpolateData(hObject);
end

function lbChannel_CreateFcn(hObject, ~, ~)
% Feature
%   Executes during object creation, after setting all properties.
% Variables
%   hObject    handle to lbChannel (see GCBO)
%   eventdata  reserved - to be defined in a future version of MATLAB
%   handles    empty - handles not created until after all CreateFcns called
% Hint
%   listbox controls usually have a white background on Windows.
%   See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
  set(hObject,'BackgroundColor','white');
end

function rbEpochs_Callback(hObject, eventdata, handles)
% Feature
%   Executes on button press in rbEpochs.
% Variables
%   hObject    handle to rbEpochs (see GCBO)
%   eventdata  reserved - to be defined in a future version of MATLAB
%   handles    structure with handles and user data (see GUIDATA)
% Hint
%   get(hObject,'Value') returns toggle state of rbEpochs
% call manually because matlab 2012b does not yet support
% selection changed callback
bgOutputFormat_SelectionChangedFcn(hObject, eventdata, handles);

function rbInterpolate_Callback(hObject, eventdata, handles)
% Feature
%   Executes on button press in rbInterpolate.
% Variables
%   hObject    handle to rbInterpolate (see GCBO)
%   eventdata  reserved - to be defined in a future version of MATLAB
%   handles    structure with handles and user data (see GUIDATA)
% Hint
%   get(hObject,'Value') returns toggle state of rbInterpolate
% call manually because matlab 2012b does not yet support
% selection changed callback
bgOutputFormat_SelectionChangedFcn(hObject, eventdata, handles);

function pbOpenInputFile_Callback(hObject, ~, handles, varargin)
% Feature
%   Executes on button press in pbOpenInputFile.
% Variables
%   hObject    handle to pbOpenInputFile (see GCBO)
%   eventdata  reserved - to be defined in a future version of MATLAB
%   handles    structure with handles and user data (see GUIDATA)
[file, path] = uigetfile('*.mat', 'Select input file');
if file ~= 0
  fn = [path,file];
  handles.input_file = fn;
  guidata(hObject, handles);
  loadFromFile(hObject, fn);
end

function pbOpenOutputFile_Callback(hObject, ~, handles)
% Feature
%   Executes on button press in pbOpenOutputFile.
% Variables
%   hObject    handle to pbOpenOutputFile (see GCBO)
%   eventdata  reserved - to be defined in a future version of MATLAB
%   handles    structure with handles and user data (see GUIDATA)
[file, path] = uiputfile('*.mat', 'Select output file');
if file ~= 0
  fn = [path,file];
  handles.output_file = fn;
  guidata(hObject, handles);
  set(handles.edOutputFile, 'String', handles.output_file);
end

function edOpenFilePath_Callback(hObject, ~, handles)
% Variables
%   hObject    handle to edOpenFilePath (see GCBO)
%   eventdata  reserved - to be defined in a future version of MATLAB
%   handles    structure with handles and user data (see GUIDATA)
% Hints: get(hObject,'String') returns contents of edOpenFilePath as text
%        str2double(get(hObject,'String')) returns contents of edOpenFilePath as a double
if isempty(handles.input_file)
  set(hObject, 'String', 'No input specified');
else
  set(hObject, 'String', handles.input_file);
end

function edOutputFile_Callback(hObject, ~, handles)
% Variables
%   hObject    handle to edOutputFile (see GCBO)
%   eventdata  reserved - to be defined in a future version of MATLAB
%   handles    structure with handles and user data (see GUIDATA)
% Hints: get(hObject,'String') returns contents of edOutputFile as text
%        str2double(get(hObject,'String')) returns contents of edOutputFile as a double
if isempty(handles.output_file)
  set(hObject, 'String', 'No output specified');
else
  set(hObject, 'String', handles.output_file);
end

function bgOutputFormat_SelectionChangedFcn(hObject, ~, handles)
% Feature
%   Executes when selected object is changed in bgOutputFormat.
% Variables
%   hObject    handle to the selected object in bgOutputFormat
%   eventdata  reserved - to be defined in a future version of MATLAB
%   handles    structure with handles and user data (see GUIDATA)
if get(handles.rbInterpolate, 'Value')
  set(handles.cbInterpolate, 'Enable', 'on');
  handles.output_type = 'interpolate';
else
  set(handles.cbInterpolate, 'Enable', 'off');
  handles.output_type = 'epochs';
end
guidata(hObject, handles);
InterpolateData(hObject);

function pbSaveOutput_Callback(hObject, ~, ~)
% Feature
%   Executes on button press in pbSaveOutput.
% Variables
%   hObject    handle to pbSaveOutput (see GCBO)
%   eventdata  reserved - to be defined in a future version of MATLAB
%   handles    structure with handles and user data (see GUIDATA)
CreateOutput(hObject);

function edOpenMissingEpochFilePath_Callback(hObject, ~, handles)
% Variables
%   hObject    handle to edOpenMissingEpochFilePath (see GCBO)
%   eventdata  reserved - to be defined in a future version of MATLAB
%   handles    structure with handles and user data (see GUIDATA)
% Hints
%   get(hObject,'String') returns contents of edOpenMissingEpochFilePath as text
%   str2double(get(hObject,'String')) returns contents of edOpenMissingEpochFilePath as a double
if isempty(handles.epoch_file)
  set(hObject, 'String', 'No input specified');
else
  set(hObject, 'String', handles.epoch_file);
end

function edOpenMissingEpochFilePath_CreateFcn(hObject, ~, ~)
% Feature
%   Executes during object creation, after setting all properties.
% Variables
%   hObject    handle to edOpenMissingEpochFilePath (see GCBO)
%   eventdata  reserved - to be defined in a future version of MATLAB
%   handles    empty - handles not created until after all CreateFcns called
% Hint
%   edit controls usually have a white background on Windows.
%   See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
  set(hObject,'BackgroundColor','white');
end

function edOpenMissingEpochFilePath_ButtonDownFcn(~, ~, ~)
% Feature
%   If Enable == 'on', executes on mouse press in 5 pixel border.
%   Otherwise, executes on mouse press in 5 pixel border or over edOpenMissingEpochFilePath.
% Variables
%   hObject    handle to edOpenMissingEpochFilePath (see GCBO)
%   eventdata  reserved - to be defined in a future version of MATLAB
%   handles    structure with handles and user data (see GUIDATA)


function pbOpenMissingEpochFile_Callback(hObject, ~, handles)
% Feature
%   Executes on button press in pbOpenMissingEpochFile.
% Variables
%   hObject    handle to pbOpenMissingEpochFile (see GCBO)
%   eventdata  reserved - to be defined in a future version of MATLAB
%   handles    structure with handles and user data (see GUIDATA)
[file, path] = uigetfile('*.mat', 'Select missing epoch file');
if file ~= 0
  handles.epoch_file = [ path, file ];
  Add_Epochs(hObject, handles);
end

function Add_Epochs(hObject, handles)
% Comment
%   handles seems to be modified in Add_Epochs
%   I changed it into a void function
E = load(handles.epoch_file, 'epochs');
epochs = transpose(sort(E.epochs));
for ep = epochs % for each ep add an area as if drawn by the user and add to epoch list
  handles = guidata(hObject);
  handles.select.start = [ ep(1), 0.5 ];
  handles.select.stop = [ ep(2), 0.5 ];
  handles.select.p = 0;
  guidata(hObject, handles);
  SelectedArea(hObject, 'add');
  UpdateEpochList(hObject);
end

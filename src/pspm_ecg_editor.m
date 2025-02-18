function [sts, R] = pspm_ecg_editor(varargin)
% ● Description
%   pspm_ecg_editor allows manual correction of ecg data and creates a hb
%   output. This function can be automatically called during data 
%   conversion or separately.
% ● Format
%   [sts, R] = pspm_ecg_editor(pt)
%   [sts, R] = pspm_ecg_editor(fn, channel, options)
% ● Arguments
%   *       pt:  A struct() from pspm_convert_ecg2hb detection.
%   *       fn:  A PsPM file containing the ecg channel to be edited
%   *  channel:  Index of ecg channel in the data file
%   ┌──options
%   ├─.channel:  Channel id of the existing hb channel
%   ├────.semi:  Defines whether to navigate between potentially wrong hb events
%   │            only (semi = 1), or between all hb events (semi = 0 => manual
%   │            mode)
%   ├.missing:   Epoch file with artefact periods to be considered missing.
%   │            These will be ignored for faulty heart beat detection.
%   ├.limits:    [struct with fields .upper, .lower] Upper and lower limits 
%   │            of the interbeat interval to be considered as potentially 
%   │            faulty. 
%   └──.factor:  Deviation by what factor of the standard deviation should 
%                lead to inter beat intervals highlighted as potentially 
%                faulty (Default: 1)
% ● Outputs
%   *        R:  r(1,:) ... original r vector
%                r(2,:) ... r vector containing potential faulty labeled qrs compl.
%                r(3,:) ... removed
%                r(4,:) ... added
% ● History
%   Introduced in PsPM 3.1
%   Written in 2013-2016 Philipp C Paulus, Tobias Moser
%   (Dresden University of Technology, University of Zurich)

%% Initialise
global settings
if isempty(settings)
  pspm_init;
end
sts = -1;

% Last Modified by GUIDE v2.5 23-Sep-2024 11:21:03

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
  'gui_Singleton',  gui_Singleton, ...
  'gui_OpeningFcn', @pspm_ecg_editor_OpeningFcn, ...
  'gui_OutputFcn',  @pspm_ecg_editor_OutputFcn, ...
  'gui_LayoutFcn',  [] , ...
  'gui_Callback',   []);
if nargin && ischar(varargin{1}) && ...
    (numel(regexp(varargin{1}, [filesep])) == 0)
  gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
  [sts, R] = gui_mainfcn(gui_State, varargin{:});
else
  gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT



% --- Executes just before pspm_ecg2hb_qc is made visible.
function pspm_ecg_editor_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to pspm_ecg2hb_qc (see VARARGIN)
global settings
pspm_ui(hObject, handles, 'ecg_editor');

% Choose default command line output for pspm_ecg2hb_qc
handles.output = hObject;
% -------------------------------------------------------------------------
% set default status for GUI

handles.edit_mode = '';
handles.gui_mode = ''; % file or inline
handles.missing_mode = ''; % file or inline
handles.hb_chan = -1;
handles.data_chan = -1;
handles.write_chan = -1;
handles.options = struct();
handles.draw_selection = false;
handles.selection = struct('p', -1, 'sh', []);
handles.fn = '';
handles.action=[];
handles.k=1;        % counter for the potential mislabeled qrs complexes
handles.s=[];
handles.s_h = [];
handles.e=0;        % flag for the status of the ecg plot.
handles.plot.p = -1;
handles.sts=[];       % outputvariable
handles.R=[];
handles.jo=0;       % default value for jump only - 0; plot data!
handles.missing_fn = '';
handles.missing_epochs = [];
handles.update_selection = true;
handles.plot.missing_layer = [];
set(handles.togg_add,'Value',0);
set(handles.togg_remove,'Value',0);
% settings for manual mode
handles.manualmode=0;       % default: deactivated
set(handles.cbManualMode, 'Value', handles.manualmode);
handles.winsize=4;          % winsize for the manual mode
handles.zoom_factor = 1;
handles.data = {};
% plot settings
handles.plot.factr = 1;
handles.plot.limits.upper = 120;
handles.plot.limits.lower = 40;
handles.plot.ecg = [];
handles.plot.r = [];
handles.plot.sr = 1;
handles.plot.dynamic_R = [];
handles.plot.faulties = [];
% -------------------------------------------------------------------------
% set color values
handles.clr{1}=[.0627 .3059 .5451; 0.0863 0.4510 0.8157]; % blue for ecg plot
handles.clr{2}=[0 .75 1; 0.6 0.9020 1]; % skyblue for correct ones
handles.clr{3}=[1 .6471 0; 1.0000 0.8588 0.6000]; % dark yellow for possibly wrong ones
handles.clr{4}=[.5412 .1686 .8863; 0.8039 0.6471 0.9529]; % violet for deleted ones
handles.clr{5}=[0 .3922 0; 0 0.8 0]; % darkgreen for added ones
% -------------------------------------------------------------------------
set(handles.edtArtefactFile, 'Enable', 'off');
set(handles.edtArtefactFile, 'String', '');
set(handles.pbArtefactsDisable, 'Enable', 'off');
set(handles.rbShowArtefacts, 'Enable', 'off');
set(handles.rbDisableArtefactDetection, 'Enable', 'off');
set(handles.rbHideArtefactEvents, 'Enable', 'off');
set(handles.rbIncludeArtefactQRS, 'Enable', 'off');
set(handles.rbExcludeArtefactQRS, 'Enable', 'off');
% -------------------------------------------------------------------------
set(handles.lstEvents, 'Value', 1);
% -------------------------------------------------------------------------
guidata(hObject,handles);

% load settings
load_settings(hObject, handles, varargin{:});
handles = guidata(hObject);

% reload hb channel
reload_hb_chan(hObject, handles);
handles = guidata(hObject);

reload_plot(hObject, handles);
handles = guidata(hObject);
% -------------------------------------------------------------------------
if strcmpi(handles.gui_mode, 'file')
  set(handles.pnlFileIO, 'visible', 'on');
else
  set(handles.pnlFileIO, 'visible', 'off');
end
% -------------------------------------------------------------------------
% Update handles structure
guidata(hObject, handles);
% -------------------------------------------------------------------------
% set detection settings
set(handles.edtFactor, 'String', num2str(handles.plot.factr));
set(handles.edtUpperLimit, 'String', num2str(handles.plot.limits.upper));
set(handles.edtLowerLimit, 'String', num2str(handles.plot.limits.lower));
% -------------------------------------------------------------------------
% UIWAIT makes pspm_ecg2hb_qc wait for user response (see UIRESUME)
uiwait(handles.pspm_ecg_editor);
% -------------------------------------------------------------------------

% --- Outputs from this function are returned to the command line.
function varargout = pspm_ecg_editor_OutputFcn(hObject, eventdata, handles)
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% Get default command line output from handles structure
handles=guidata(hObject);
if not(isempty(handles.sts))
  varargout{1} = handles.sts;
else
  varargout{1} = -1;
end
% -------------------------------------------------------------------------
if varargout{1} == -1
  varargout{2} = [];
elseif not(isempty(handles.R))
  if strcmpi(handles.gui_mode, 'inline')
    varargout{2} = handles.R;
  else
    varargout{2} = handles.write_chan;
  end
else
  varargout{2} = [];
end
delete(hObject);
% -------------------------------------------------------------------------

% --- Executes on button press in togg_add.
function togg_add_Callback(hObject, eventdata, handles)
% hObject    handle to togg_add (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% Hint: get(hObject,'Value') returns toggle state of togg_add
pan off;
set(handles.togg_remove,'Value',0)
if strcmpi(handles.edit_mode, 'add_qrs')
  exitModus;
else
  handles.edit_mode = 'add_qrs';
  set(handles.pspm_ecg_editor,'Pointer','crosshair');
  guidata(hObject, handles);
end


% --- Executes on button press in togg_remove.
function togg_remove_Callback(hObject, eventdata, handles)
% hObject    handle to togg_remove (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of togg_remove
% -------------------------------------------------------------------------
pan off;
if strcmpi(handles.edit_mode, 'remove_qrs')
  exitModus;
else
  handles.edit_mode = 'remove_qrs';
  set(handles.pspm_ecg_editor,'Pointer','crosshair');
  guidata(hObject, handles);
end
% -------------------------------------------------------------------------


% --- Executes on button press in push_cancel.
function push_cancel_Callback(hObject, eventdata, handles)
% hObject    handle to push_cancel (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
exitModus;
handles.sts=-1;
handles.R=[];
% Update handles structure
guidata(hObject,handles);
% -------------------------------------------------------------------------
uiresume
% delete(hObject);


% --- Executes on button press in push_next.
function push_next_Callback(hObject, eventdata, handles)
% hObject    handle to push_next (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% -------------------------------------------------------------------------
exitModus;
if ~handles.manualmode
  handles.k=handles.k+1;
else % manual mode
  handles.count=handles.count+(handles.winsize/2)*handles.zoom_factor;
end
check_navigation_buttons(hObject, handles);
handles.jo=1;
% call pp_plot
pp_plot(hObject,handles)




% --- Executes on button press in push_last.
function push_last_Callback(hObject, eventdata, handles)
% hObject    handle to push_last (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% -------------------------------------------------------------------------
exitModus;
if ~handles.manualmode
  handles.k=handles.k-1;
else % manual mode
  handles.count=handles.count-(handles.winsize/2)*handles.zoom_factor;
end
check_navigation_buttons(hObject, handles);
handles.jo=1;
% call pp_plot
pp_plot(hObject,handles)


% --- Executes on button press in push_done.
function push_done_Callback(hObject, eventdata, handles)
% hObject    handle to push_done (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles=guidata(hObject);
handles.edit_mode = '';
% -------------------------------------------------------------------------
r=handles.plot.r;
% get original R from reload_hb_chan
orig_R = handles.plot.R;

sr=handles.plot.sr;

% restore all events
r(1,orig_R) = 1;
% add mutatios
r(1,r(3,:)==1)=NaN; % deleted QRS markers
r(1,r(4,:)==1)=1;   % added QRS markers

% remove missing markers
if get(handles.rbExcludeArtefactQRS, 'Value') == 1 && any(handles.plot.missing_layer)
  r(1, handles.plot.missing_layer) = NaN;
end

handles.R=[];
handles.R=find(r(1,:)==1);
handles.sts=1;

% write channel accordingly
if strcmpi(handles.gui_mode, 'file') && numel(handles.R) > 0
  % assemble output settings
  output_settings = get(handles.rbAddChan, 'Value') + ...
    get(handles.rbReplaceHbChan, 'Value')*2;

  % prepare outputs
  out_d = struct();
  out_d.data = handles.R/sr;
  out_d.header = struct();
  out_d.header.chantype = 'hb';
  out_d.header.sr = 1;
  out_d.header.units = 'events';

  % transpose if necessary
  if max(size(out_d.data,1)) ~= length(out_d.data)
    out_d.data = transpose(out_d.data);
  end

  switch output_settings
    case 1
      w_action = 'add';
      w_chan = 0;
    case 2
      w_action = 'replace';
      w_chan = handles.hb_chan;
  end
  op = struct('channel', w_chan);
  [nsts, infos] = pspm_write_channel(handles.fn, out_d, w_action, op);

  if nsts ~= -1
    handles.write_chan = infos.channel;
  else
    warning('ID:invalid_input', 'Could not write channel.');
    handles.sts = nsts;
  end
end

guidata(hObject,handles);
uiresume
% -------------------------------------------------------------------------
% delete(hObject);

% --- plots the current segment
function load_settings(hObject,handles, varargin)

% parse input
if numel(varargin) == 0 || ~isstruct(varargin{1})
  handles.gui_mode = 'file';

  if numel(varargin) > 2
    handles.options = varargin{3};
  else
    handles.options = struct();
  end

  handles.options = pspm_options(handles.options, 'ecg_editor');

  if isfield(handles.options, 'hb')
    handles.hb_chan = handles.options.channel;
  end
  if isfield(handles.options, 'factor')
    handles.plot.factr = handles.options.factor;
  end
  if isfield(handles.options, 'semi')
    handles.manualmode = ~handles.options.semi;
  end
  if isfield(handles.options, 'missing') && ~isempty(handles.options.missing)
    load_data_missing(hObject, handles, handles.options.missing);
    % update handles
    handles = guidata(hObject);
  end
  if isfield(handles.options, 'limits')
    if isfield(handles.options.limits, 'lower')
      handles.plot.limits.lower = handles.options.limits.lower;
    end

    if isfield(handles.options.limits, 'upper')
      handles.plot.limits.upper = handles.options.limits.upper;
    end
  end

  if numel(varargin) >= 2
    handles.data_chan = varargin{2};
  end

  if numel(varargin) >= 1
    load_data_file(hObject, handles, varargin{1});
    % update handles
    handles = guidata(hObject);
  end
else
  handles.data = varargin{1};
  handles.gui_mode = 'inline';

  % IBIs larger than mean(IBI)+(factr*std(IBI)) will
  % be marked for checking as well as IBIs smaller
  % than mean(IBI)-(factor*std(IBI))
  handles.plot.factr=handles.data.settings.outfact;
  sr=handles.data.settings.filt.sr;
  % -------------------------------------------------------------------------
  % QRS complexes
  ecg = transpose(handles.data.data.x(:,1));

  handles.plot.sr = sr;
  handles.plot.ecg = ecg;
end

% -------------------------------------------------------------------------
% output.
handles.count = 0;
set(handles.cbManualMode, 'Value', handles.manualmode);

% Update handles structure
guidata(hObject,handles);

% --- update hb channel
function reload_hb_chan(hObject, handles)

ecg = handles.plot.ecg;
sr = handles.plot.sr;

if isstruct(handles.data)
  R = handles.data.set.R;
  r = transpose(handles.data.data.r);
  % set modification rows
  r(3:4, :) = NaN;
  handles.manualmode = 1 && get(handles.cbManualMode, 'Value');
else
  if handles.hb_chan ~= -1
    hb = handles.data{handles.hb_chan}.data;
    set(handles.cbManualMode, 'Enable', 'on');
    set(handles.rbReplaceHbChan, 'Enable', 'on');
    handles.manualmode = 1 && get(handles.cbManualMode, 'Value');
  else
    set(handles.rbReplaceHbChan, 'Enable', 'off');
    set(handles.cbManualMode, 'Value', 1);
    set(handles.cbManualMode, 'Enable', 'off');
    if get(handles.rbReplaceHbChan, 'Value')
      set(handles.rbAddChan, 'Value', 1);
    end
    handles.manualmode = 1;
    set(handles.cbManualMode, 'Value', 1);
    hb = {};
  end
  r = zeros(4,numel(ecg));
  if numel(hb) >= 1
    R = transpose(round(hb*sr));
    r(1,R) = 1;
    handles.manualmode = get(handles.cbManualMode, 'Value');
  else
    R = [];
  end
end

handles.plot.R = R;
handles.plot.r = r;
sr = handles.plot.sr;
y=1/sr:1/sr:length(r)/sr;
handles.plot.y = y;
guidata(hObject, handles);


% --- discriminate hb events
function discriminate_hb_events(hObject, handles)

up_lim = handles.plot.limits.upper;
lw_lim = handles.plot.limits.lower;
factr = handles.plot.factr;
R = handles.plot.R;
sr = handles.plot.sr;
r = handles.plot.r;

% create missing layer
% ------------------------------------------------------------------------
a_lay = false(1, length(r));
for i=1:length(handles.missing_epochs)
  a_coord = handles.missing_epochs(i, 1:end);
  start = max(1, round(a_coord(1)*handles.plot.sr));
  stop = min(length(a_lay), round(a_coord(2)*handles.plot.sr));
  a_lay(start:stop) = 1;
end

% reset old detections
r(1,R) = 1;
r(2,R) = 0;

% complexes
ibi=diff(R); % duration of IBI intervalls
flag=zeros(size(ibi));% flag variable to identify potential mislabeled
flag(end+1) = 0;
ibi_filter = ~a_lay(R);

if get(handles.rbDisableArtefactDetection, 'Value') || ...
    get(handles.rbHideArtefactEvents, 'Value')
  ibi_f = ibi(ibi_filter(1:end-1));
else
  ibi_f = ibi;
end
% -------------------------------------------------------------------------
% create vectors for potential mislabeled qrs complexes
flag(ibi>(mean(ibi_f)+(factr*std(ibi_f))))=1;   % too short
flag(ibi<(mean(ibi_f)-(factr*std(ibi_f))))=1;   % too long
flag(ibi/sr < 60/up_lim)=1;                    % get all ibis > 120 bpm
flag(ibi/sr > 60/lw_lim)=1;                     % get all ibis < 40 bpm

% transfer settings
r(2,R(flag==1))=1;
r(1,R(flag==1))=0;

% set default maxk
maxk=length(find(flag==1));

% reset according to missing epochs
if ~isempty(handles.missing_epochs) && numel(R) > 0
  chans = [];
  if get(handles.rbDisableArtefactDetection, 'Value')
    chans = 2;
  elseif get(handles.rbHideArtefactEvents, 'Value')
    chans = [1,2];
  end

  % update maxk if necessary
  if ~isempty(chans)
    maxk = length(find(flag==1 & ibi_filter));
  end

  if ~isempty(chans) && any(a_lay)
    r(chans, a_lay) = 0;
  end
end

% if detection is disabled and detected as faulty then channel 1 and
% are empty but flag is set; in order to display the blue marker we have to
% reset the flags in the first row.
idx = r(2,R)==0 & flag==1;
if get(handles.rbDisableArtefactDetection, 'Value') && any(idx)
  r(1,R(idx)) = 1;
end

% make zeros NaN
r(r==0)=NaN;

handles.plot.ibi = ibi;
handles.plot.r = r;
handles.plot.missing_layer = a_lay;

if exist('handles.maxk', 'var') == 0 && exist('maxk', 'var')
  handles.maxk = maxk;
end

% update dynamic R / make it global because its quite an expensive
% operation
handles.plot.dynamic_R = find(nansum(handles.plot.r));
handles.plot.faulties = find(handles.plot.r(2,:) == 1);

guidata(hObject, handles);

% --- plot data
function pp_plot(hObject,handles)
global settings
% where are potential mislabeled qrs complexes?
if any(not(isnan(handles.plot.r(2,:)))) && ~handles.manualmode
  fl = handles.plot.faulties;
  sample_id = fl(handles.k);
  count=sample_id/handles.plot.sr;
else
  count=handles.count;
  custom_R = handles.plot.dynamic_R;
  if count >= 0
    % find sample_id
    d = abs(custom_R - count*handles.plot.sr);
    [~, idx] = min(d);
    sample_id = custom_R(idx);
  else
    sample_id = 1;
  end
end
% -------------------------------------------------------------------------
if handles.jo==0 % check only if changes were done.
  % plot ecg signal
  if handles.e==0
    hold on;
    handles.plot.p = plot(handles.plot.y,handles.plot.ecg,'color',handles.clr{1}(1,:));
    ylim([min(handles.plot.ecg)*(1-.1), max(handles.plot.ecg)*(1+.1)]);
    handles.e=1;
  end
  % -------------------------------------------------------------------------
  if not(isempty(handles.s))
    try
      for i = 1:length(handles.s)
        if handles.s(i) > 0
          delete(handles.s(i));
        end
      end
      handles.s = [];
    catch
      warning('Could not properly clean up stem markers.');
    end
  end
  % ---------------------------------------------------------------------
  if ~isempty(handles.selection.sh)
    try
      for i =1:length(handles.selection.sh)
        delete(handles.selection.sh);
      end
      handles.selection.sh = [];
    catch
    end
  end
  % ---------------------------------------------------------------------
  % plot normal stems
  handles.s = plot_stems(handles, handles.s, [1 length(handles.plot.r)], 1);
  handles.jo = 1;
end
% plot or update highlight stems
if ~isempty(handles.plot.R)
  handles.selection.sh = plot_stems(handles, handles.selection.sh, [sample_id, sample_id], 2);
end
% -------------------------------------------------------------------------
if ~handles.manualmode
  left_border  = count-2*handles.zoom_factor;
  right_border = count+2*handles.zoom_factor;
  xlim([left_border right_border]);
  if left_border<=0
    left_border=1;
  elseif right_border<=0
    right_border=1;
  end
  y_lower_boud = min(handles.plot.ecg(round(left_border*handles.plot.sr):round(right_border*handles.plot.sr)));
  y_upper_boud = max(handles.plot.ecg(round(left_border*handles.plot.sr):round(right_border*handles.plot.sr)));
  ylim([y_lower_boud y_upper_boud]);
else
  left_border  = count-(handles.winsize/2)*handles.zoom_factor;
  right_border = count+(handles.winsize/2)*handles.zoom_factor;
  xlim([left_border right_border]);
  if left_border<=0
    left_border=1;
  elseif right_border<=0
    right_border=1;
  end
  y_lower_boud = min(handles.plot.ecg(round(left_border*handles.plot.sr):round(right_border*handles.plot.sr)));
  y_upper_boud = max(handles.plot.ecg(round(left_border*handles.plot.sr):round(right_border*handles.plot.sr)));
  ylim([y_lower_boud y_upper_boud]);
end
xlabel('time in seconds [s]')
% -------------------------------------------------------------------------
handles.count=count; % set current position.
% Update handles structure
guidata(hObject,handles);

update_selected(hObject, handles);
check_navigation_buttons(hObject, handles);

% --- Update selected
function update_selected(hObject, handles)
if handles.update_selection
  lst_id = get(handles.lstEvents, 'Value');
  if handles.manualmode
    custom_R = handles.plot.dynamic_R;
    if ~isempty(custom_R)
      if lst_id > length(custom_R)
        lst_id = 1;
      end
      lst_count = custom_R(lst_id);
      lst_sample = lst_count;
      sel_sample = handles.count;

      if lst_sample ~= sel_sample
        d = abs(custom_R-sel_sample*handles.plot.sr);
        idx = find(d == min(d));
        set(handles.lstEvents, 'Value', idx);
      end
    end
  else
    if lst_id ~= handles.k
      set(handles.lstEvents, 'Value', handles.k);
    end
  end
end

% --- Executes when user attempts to close pspm_ecg_editor.
function pspm_ecg_editor_CloseRequestFcn(hObject, eventdata, handles)
% hObject    handle to pspm_ecg_editor (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

handles.sts=-1;
handles.R=[];
% Update handles structure
guidata(hObject,handles);
% -------------------------------------------------------------------------
uiresume
% Hint: delete(hObject) closes the figure
% delete(hObject);


% --- Executes on key press with focus on pspm_ecg_editor and none of its controls.
function pspm_ecg_editor_KeyPressFcn(hObject, eventdata, handles)
% hObject    handle to pspm_ecg_editor (see GCBO)
% eventdata  structure with the following fields (see MATLAB.UI.FIGURE)
% Key: name of the key that was pressed, in lower case
% Character: character interpretation of the key(s) that was pressed
% Modifier: name(s) of the modifier key(s) (i.e., control, shift) pressed
% handles    structure with handles and user data (see GUIDATA)
if strcmpi(eventdata.Key, 'escape')
  exitModus;
end

% -------------------------------------------------------------------------
function exitModus()
handles = guidata(gca);
set(handles.pspm_ecg_editor, 'Pointer', 'Arrow');
handles.edit_mode = '';
guidata(gca, handles);

% --- Executes on mouse press over figure background, over a disabled or
% --- inactive control, or over an axes background.
function pspm_ecg_editor_WindowButtonDownFcn(hObject, eventdata, handles)
% hObject    handle to pspm_ecg_editor (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
if strcmpi(handles.edit_mode,'remove_qrs')
  handles.draw_selection = true;
  pt = get(handles.axes, 'CurrentPoint');
  handles.selection.start = pt(1,1:2);
  guidata(hObject, handles);
end

% --- Executes on button press in zoomIn.
function zoomIn_Callback(hObject, eventdata, handles)
% hObject    handle to zoomIn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.zoom_factor = handles.zoom_factor / 2;
pp_plot(hObject, handles);

% --- Executes on button press in zoomOut.
function zoomOut_Callback(hObject, eventdata, handles)
% hObject    handle to zoomOut (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.zoom_factor = handles.zoom_factor * 2;
pp_plot(hObject, handles);

function edtDataFile_Callback(hObject, eventdata, handles)
% hObject    handle to edtDataFile (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edtDataFile as text
%        str2double(get(hObject,'String')) returns contents of edtDataFile as a double
set(hObject, 'String', handles.fn);

% --- Executes during object creation, after setting all properties.
function edtDataFile_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edtDataFile (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
  set(hObject,'BackgroundColor','white');
end

% --- Executes on button press in pbChangeFile.
function pbChangeFile_Callback(hObject, eventdata, handles)
% hObject    handle to pbChangeFile (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

[fname, fpath] = uigetfile({'*.mat'}, 'Select file with ECG data');
if ischar(fname) && ~isempty(fname)
  fn = fullfile(fpath, fname);
  %handles.hb_chan = -1;
  load_data_file(hObject, handles, fn);
  handles = guidata(hObject);
  % reload hb channel
  reload_hb_chan(hObject, handles);
  handles = guidata(hObject);
  reload_plot(hObject, handles);
end


% --- Executes on selection change in ppHbChan.
function ppHbChan_Callback(hObject, ~, handles)
% hObject    handle to ppHbChan (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns ppHbChan contents as cell array
%        contents{get(hObject,'Value')} returns selected item from ppHbChan

if ~isempty(handles.data)
  contents = cellstr(get(hObject,'String'));
  new_hb_chan = contents{get(hObject,'Value')};
  if strcmpi(new_hb_chan, 'None')
    handles.hb_chan = -1;
  else
    handles.hb_chan = str2double(new_hb_chan);
  end
  % reload hb channel
  reload_hb_chan(hObject, handles);
  handles = guidata(hObject);
  reload_plot(hObject, handles);
end

% --- Executes on selection change in ppEcgChan.
function ppEcgChan_Callback(hObject, ~, handles)
% hObject    handle to ppEcgChan (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns ppEcgChan contents as cell array
%        contents{get(hObject,'Value')} returns selected item from ppEcgChan

if ~isempty(handles.data)
  contents = cellstr(get(hObject,'String'));
  new_ecg_chan = contents{get(hObject,'Value')};
  handles.ecg_chan = str2double(new_ecg_chan);

  % reload hb channel
  reload_hb_chan(hObject, handles);
  handles = guidata(hObject);
  handles.e = 0;
  if handles.plot.p ~= -1
    delete(handles.plot.p);
    handles.plot.p = -1;
  end
  reload_plot(hObject, handles);
end

% --- Executes during object creation, after setting all properties.
function ppEcgChan_CreateFcn(hObject, eventdata, handles)
% hObject    handle to ppEcgChan (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
  set(hObject,'BackgroundColor','white');
end

% --- Load Data file
function load_data_file(hObject, handles, fn)
[sts, ~, handles.data, ~] = pspm_load_data(fn);
if sts == 1
  ecg_chans = find(cellfun(@(x) any(strcmpi(x.header.chantype, {'ecg', 'ppg'})), handles.data));
  % set possible ecg chans
  sel_ecg_chan = find(ecg_chans == handles.data_chan, 1, 'first');
  if isempty(sel_ecg_chan)
    sel_ecg_chan = 1;
  end
  handles.data_chan = ecg_chans(sel_ecg_chan);
  set(handles.ppEcgChan, 'String', ecg_chans);
  set(handles.ppEcgChan, 'Value', sel_ecg_chan);

  hb_chans = find(cellfun(@(x) strcmpi(x.header.chantype, 'hb'), handles.data));
  hb_chan_list = cell(1,length(hb_chans)+1);
  hb_chan_list{1} = 'None';
  hb_chan_list(2:end) = num2cell(hb_chans);
  if handles.hb_chan == -1
    sel_hb_chan = -2;
    set(handles.cbManualMode, 'Enable', 'off');
  else
    sel_hb_chan = find(cell2mat(hb_chan_list(2:end)) == handles.hb_chan,1) + 1;
    if isempty(sel_hb_chan)
      sel_hb_chan = -2;
    end
  end

  if sel_hb_chan == -2
    if length(hb_chans) == 1
      sel_hb_chan = 2;
    else
      sel_hb_chan = 1;
    end
  end

  set(handles.ppHbChan, 'String', hb_chan_list);
  set(handles.ppHbChan, 'Value', sel_hb_chan);

  handles.hb_chan = hb_chan_list{sel_hb_chan};
  if strcmpi(handles.hb_chan, 'None')
    handles.hb_chan = -1;
    set(handles.rbReplaceHbChan, 'Enable', 'off');
  end

  handles.fn = fn;
  set(handles.edtDataFile, 'String', fn);

  % filter data
  ecg = handles.data{handles.data_chan}.data;
  sr = handles.data{handles.data_chan}.header.sr;

  handles.plot.ecg = ecg;
  handles.e = 0;
  if handles.plot.p ~= -1
    delete(handles.plot.p);
    handles.plot.p = -1;
  end
  handles.plot.sr = sr;

  guidata(hObject, handles);
end

% --- Reload plot settings
function reload_plot(hObject, handles)

if ~isempty(handles.data)

  % get selected timestamp
  if ~handles.manualmode
    fl = handles.plot.faulties;
    if ~isempty(fl)
      count = fl(handles.k)/handles.plot.sr;
    else
      count = 1/handles.plot.sr;
    end
  else
    count = handles.count;
  end

  sel_sample = count*handles.plot.sr;

  % set values
  discriminate_hb_events(hObject,handles);
  handles=guidata(hObject);

  % restore selected element
  if ~handles.manualmode
    fl = handles.plot.faulties;
    [~, idx] = min(abs(fl-sel_sample));
    handles.k = idx;
  else
    R = handles.plot.dynamic_R;
    [~, idx] = min(abs(R-sel_sample));
    handles.count = R(idx)/handles.plot.sr;
    if isempty(handles.count)
      handles.count = 0;
    end
  end

  % update event list
  update_event_list(hObject, handles);

  % plot
  handles.jo = 0;
  pp_plot(hObject,handles);
  handles=guidata(hObject);

  % check nex_prev button
  check_navigation_buttons(hObject, handles);
end

% --- Check navigation buttons
function check_navigation_buttons(hObject, handles)
% activate buttons accordingly
if handles.maxk==1
  set(handles.push_next,'enable','off')
  set(handles.push_last,'enable','off')
else
  if ~handles.manualmode
    next = handles.k + 1;
    maximum = handles.maxk;
    minimum = 1;
    prev = handles.k - 1;
  else
    next = handles.count + (handles.winsize/2)*handles.zoom_factor;
    maximum = length(handles.plot.r)/handles.plot.sr;
    minimum = 0;
    prev = handles.count - (handles.winsize/2)*handles.zoom_factor;
  end
  if  next > maximum
    set(handles.push_next,'enable','off');
  else
    set(handles.push_next, 'enable', 'on');
  end

  if prev < minimum
    set(handles.push_last, 'enable', 'off');
  else
    set(handles.push_last, 'enable', 'on');
  end
end

% --- Update event list
function update_event_list(hObject, handles)
if handles.manualmode
  new_el = handles.plot.dynamic_R;
  [~, idx] = min(abs(new_el - handles.count*handles.plot.sr));
  sel_el = idx;
else
  new_el = handles.plot.faulties;
  sel_el = handles.k;
end

new_list = cell(length(new_el),1);
for i=1:length(new_el)
  % find color
  new_list{i} = create_event_list_entry(hObject, handles, new_el(i));
end

set(handles.lstEvents, 'Value', 1);
set(handles.lstEvents, 'String', new_list);
set(handles.lstEvents, 'Value', sel_el);

function [entry] = create_event_list_entry(hObject, handles, sample_id)
el = handles.plot.r(:,sample_id);
% original, faulty, removed, added
if nansum(el, 1) > 0
  el_idx = find(el > 0);
  cl = handles.clr{max(el_idx)+1}(1,:);
else
  cl = handles.clr{2}(1,:);
end

if handles.plot.missing_layer(sample_id)
  f_cl = '777777';
else
  f_cl = '000000';
end

t = sample_id/handles.plot.sr;
entry = sprintf('<html><font bgcolor="#%02s%02s%02s" color="#%06s">%0.4f</font></html>',...
  dec2hex(round(cl(1)*255)), ...
  dec2hex(round(cl(2)*255)), ...
  dec2hex(round(cl(3)*255)), ...
  f_cl, ...
  t);



% --- Executes during object creation, after setting all properties.
function ppHbChan_CreateFcn(hObject, eventdata, handles)
% hObject    handle to ppHbChan (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
  set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in cbManualMode.
function cbManualMode_Callback(hObject, eventdata, handles)
% hObject    handle to cbManualMode (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of cbManualMode
handles.manualmode = get(hObject, 'Value');
% check nex_prev button
check_navigation_buttons(hObject, handles);
% update event list
update_event_list(hObject, handles);
% plot
pp_plot(hObject, handles);



function edtArtefactFile_Callback(hObject, eventdata, handles)
% hObject    handle to edtArtefactFile (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edtArtefactFile as text
%        str2double(get(hObject,'String')) returns contents of edtArtefactFile as a double

set(hObject, 'String', handles.missing_fn);


% --- Executes during object creation, after setting all properties.
function edtArtefactFile_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edtArtefactFile (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
  set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in pbArtefactFile.
function pbArtefactFile_Callback(hObject, eventdata, handles)
% hObject    handle to pbArtefactFile (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

[fname, fpath] = uigetfile({'*.mat'}, 'Select file with Artefact epochs');
if ischar(fname) && ~isempty(fname)
  fn = fullfile(fpath, fname);
  load_data_missing(hObject, handles, fn);
  handles = guidata(hObject);
  refresh_faulty(hObject, handles);
end

% --- Load missing epochs file
function load_data_missing(hObject, handles, missing)

[sts, handles.missing_epochs] = pspm_get_timing('epochs', missing, 'seconds');

if sts ~= -1
  set(handles.rbShowArtefacts, 'Enable', 'on');
  set(handles.rbHideArtefactEvents, 'Enable', 'on');
  set(handles.rbDisableArtefactDetection, 'Enable', 'on');
  set(handles.rbIncludeArtefactQRS, 'Enable', 'on');
  set(handles.rbExcludeArtefactQRS, 'Enable', 'on');

  if ischar(missing)
    handles.missing_mode = 'file';

    % enable
    set(handles.edtArtefactFile, 'String', missing);
    set(handles.edtArtefactFile, 'Enable', 'on');
    set(handles.pbArtefactsDisable, 'Enable', 'on');

    % show
    set(handles.pbArtefactFile, 'Visible', 'on');
    set(handles.pbArtefactsDisable, 'Visible', 'on');
    set(handles.edtArtefactFile, 'Visible', 'on');
    handles.missing_fn = missing;
  else
    handles.missing_mode = 'inline';

    % disable
    set(handles.edtArtefactFile, 'String', '');
    set(handles.pbArtefactsDisable, 'Enable', 'off');
    set(handles.edtArtefactFile, 'Enable', 'off');
    set(handles.rbIncludeArtefactQRS, 'Enable', 'off');
    set(handles.rbExcludeArtefactQRS, 'Enable', 'off');

    % hide
    set(handles.edtArtefactFile, 'Visible', 'off');
    set(handles.pbArtefactFile, 'Visible', 'off');
    set(handles.pbArtefactsDisable, 'Visible', 'off');
  end
else
  handles.missing_epochs = [];
  warning('ID:invalid_input', 'Could not load missing.');
end
guidata(hObject, handles);

% --- Executes during object creation, after setting all properties.
function lstEvents_CreateFcn(hObject, eventdata, handles)
% hObject    handle to lstEvents (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
  set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in lstEvents.
function lstEvents_Callback(hObject, eventdata, handles)
% hObject    handle to lstEvents (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns lstEvents contents as cell array
%        contents{get(hObject,'Value')} returns selected item from lstEvents
sel_id = get(hObject, 'Value');
if sel_id >= 0
  if handles.manualmode
    % put together own
    custom_R = handles.plot.dynamic_R;
    if sel_id > length(custom_R)
      sel_id = 1;
      set(hObject, 'Value', sel_id);
    end
    handles.count = custom_R(sel_id)/handles.plot.sr;
  else
    handles.k = sel_id;
  end
  handles.update_selection = false;
  pp_plot(hObject, handles);
  handles = guidata(hObject);
  handles.update_selection = true;
  guidata(hObject, handles);
end



% --- Executes during object creation, after setting all properties.
function edtFactor_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edtFactor (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
  set(hObject,'BackgroundColor','white');
end



function edtUpperLimit_Callback(hObject, eventdata, handles)
% hObject    handle to edtUpperLimit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edtUpperLimit as text
%        str2double(get(hObject,'String')) returns contents of edtUpperLimit as a double
if isnan(str2double(get(hObject, 'String')))
  errordlg('Value has to be numeric.');
  set(hObject, 'String', num2str(handles.plot.limits.upper));
end

% --- Executes during object creation, after setting all properties.
function edtUpperLimit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edtUpperLimit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
  set(hObject,'BackgroundColor','white');
end



function edtLowerLimit_Callback(hObject, eventdata, handles)
% hObject    handle to edtLowerLimit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edtLowerLimit as text
%        str2double(get(hObject,'String')) returns contents of edtLowerLimit as a double
if isnan(str2double(get(hObject, 'String')))
  errordlg('Value has to be numeric.');
  set(hObject, 'String', num2str(handles.plot.limits.lower));
end

% --- Executes during object creation, after setting all properties.
function edtLowerLimit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edtLowerLimit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
  set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in edtApplyDetSet.
function edtApplyDetSet_Callback(hObject, eventdata, handles)
% hObject    handle to edtApplyDetSet (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

factr = get(handles.edtFactor, 'String');
ul = get(handles.edtUpperLimit, 'String');
ll = get(handles.edtLowerLimit, 'String');

handles.plot.factr = str2double(factr);
handles.plot.limits.upper = str2double(ul);
handles.plot.limits.lower = str2double(ll);

refresh_faulty(hObject, handles);

% --- refresh_faulty
function refresh_faulty(hObject, handles)
% reset values but keep changes (3 and 4)
handles.plot.r(1,handles.plot.r(2,:)==1) = 1;
handles.plot.r(2,:) = NaN;
handles.k = 1;
handles.count = 1;
% reload plot
reload_plot(hObject, handles);

function edtFactor_Callback(hObject, eventdata, handles)
% hObject    handle to edtFactor (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edtFactor as text
%        str2double(get(hObject,'String')) returns contents of edtFactor as a double
if isnan(str2double(get(hObject, 'String')))
  errordlg('Value has to be numeric.');
  set(hObject, 'String', num2str(handles.plot.factr));
end


% --- Executes on button press in pbArtefactsDisable.
function pbArtefactsDisable_Callback(hObject, eventdata, handles)
% hObject    handle to pbArtefactsDisable (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

handles.missing_epochs = [];
handles.missing_fn = '';
handles.plot.missing_layer(:) = false;
set(handles.edtArtefactFile, 'Enable', 'off');
set(handles.edtArtefactFile, 'String', '');
set(handles.pbArtefactsDisable, 'Enable', 'off');
%
set(handles.rbShowArtefacts, 'Enable', 'off');
set(handles.rbDisableArtefactDetection, 'Enable', 'off');
set(handles.rbHideArtefactEvents, 'Enable', 'off');
set(handles.rbIncludeArtefactQRS, 'Enable', 'off');
set(handles.rbExcludeArtefactQRS, 'Enable', 'off');
% refresh faulty
refresh_faulty(hObject, handles);


% --- Executes on button press in rbShowArtefacts.
function rbShowArtefacts_Callback(hObject, eventdata, handles)
% hObject    handle to rbShowArtefacts (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of rbShowArtefacts
reload_plot(hObject, handles);


% --- Executes on button press in rbDisableArtefactDetection.
function rbDisableArtefactDetection_Callback(hObject, eventdata, handles)
% hObject    handle to rbDisableArtefactDetection (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of rbDisableArtefactDetection
reload_plot(hObject, handles);


% --- Executes on button press in rbHideArtefactEvents.
function rbHideArtefactEvents_Callback(hObject, eventdata, handles)
% hObject    handle to rbHideArtefactEvents (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of rbHideArtefactEvents
reload_plot(hObject, handles);


% --- Executes on mouse press over figure background, over a disabled or
% --- inactive control, or over an axes background.
function pspm_ecg_editor_WindowButtonUpFcn(hObject, eventdata, handles)
% hObject    handle to pspm_ecg_editor (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
pt = get(handles.axes, 'CurrentPoint');
no_change = 0;
custom_R = handles.plot.dynamic_R;
switch handles.edit_mode
  case 'add_qrs'
    x = pt(1);
    % -----------------------------------------------------------------
    % click input
    x=min(max(1,round(x*handles.plot.sr)), length(handles.plot.r));
    % -----------------------------------------------------------------
    % add qrs complex at position x and remove entry from r(2,x)
    handles.plot.r(4,x)=1;
    handles.plot.r(3,x)=NaN;
    % -----------------------------------------------------------------

    if handles.manualmode
      cur_events = cellstr(get(handles.lstEvents,'String'));
      lst_R = custom_R;

      ev_pos = min(find(lst_R >= x));
      if isempty(ev_pos)
        ev_pos = length(lst_R) + 1;
      end

      new_events = cell(length(cur_events)+1, 1);
      if length(cur_events) >= 1
        new_events(1:(ev_pos-1)) = cur_events(1:(ev_pos-1));
      end

      % set entry
      new_events{ev_pos} = create_event_list_entry(hObject, handles, x);
      if length(cur_events) >= ev_pos
        new_events((ev_pos+1):end) = cur_events(ev_pos:end);
      end
      set(handles.lstEvents, 'String', new_events);
      set(handles.lstEvents, 'Value', ev_pos);
    end


  case 'remove_qrs'        % click input
    % disable selection mode
    handles.draw_selection = false;
    if handles.selection.p ~= -1
      delete(handles.selection.p);
      handles.selection.p = -1;
    end

    % find start and stop positions
    if handles.selection.start(1) < pt(1)
      start = handles.selection.start(1)*handles.plot.sr;
      stop = pt(1)*handles.plot.sr;
    else
      stop = handles.selection.start(1)*handles.plot.sr;
      start = pt(1)*handles.plot.sr;
    end

    % sanitize
    start = max(1, round(start));
    stop = min(length(handles.plot.r), stop);
    x = (start + stop)/2;
    idx = find(custom_R > start & custom_R < stop);

    % set remove flag and remove add flag
    handles.plot.r(3, custom_R(idx)) = 1;
    handles.plot.r(4, custom_R(idx)) = NaN;

    % update lstevents
    if handles.manualmode
      lst_R = custom_R;
    else
      lst_R = find(handles.plot.r(2, :) == 1);
    end

    % replace selected objects
    cur_events = cellstr(get(handles.lstEvents,'String'));
    for i=1:length(idx)
      ev_pos = find(lst_R == custom_R(idx(i)), 1);
      if ~isempty(ev_pos)
        cur_events{ev_pos} = create_event_list_entry(hObject, handles, custom_R(idx(i)));
      end
    end
    set(handles.lstEvents, 'String', cur_events);
  otherwise
    no_change = 1;
end

if ~no_change
  % update dynamic R
  handles.plot.dynamic_R = find(nansum(handles.plot.r));
  handles.jo=0;   % changes were done, so set flag to 0
  % Update handles structure
  guidata(hObject,handles);
  % plot new
  if handles.manualmode
    handles.count = x/handles.plot.sr;
  else
    % find nearest k
    pos_R = find(handles.plot.r(2,:) == 1);
    [~, k] = min(abs(pos_R-x));
    handles.k = k;
  end

  pp_plot(hObject,handles);

end


% --- Executes on mouse motion over figure - except title and menu.
function pspm_ecg_editor_WindowButtonMotionFcn(hObject, eventdata, handles)
% hObject    handle to pspm_ecg_editor (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
if handles.draw_selection
  pt = get(handles.axes, 'CurrentPoint');
  pos = pt(1,1:2);
  start = handles.selection.start;

  x = [start(1), pos(1), pos(1), start(1)];
  y = [start(2), start(2), pos(2), pos(2)];

  if handles.selection.p ~= -1
    p = handles.selection.p;
    set(p, 'XData', x);
    set(p, 'YData', y);
  else
    p = patch(x,y, 'white', 'FaceColor', 'none');
    handles.selection.p = p;
  end


  guidata(hObject, handles);

  range = [start(1)*handles.plot.sr pos(1)*handles.plot.sr];

  handles.selection.sh = plot_stems(handles, handles.selection.sh, range, 2);
  guidata(hObject, handles);
end

% --- Plot selection highlight
function [stem_handles] = plot_stems(handles, stem_handles, range, cl_type)

% sample ids
if range(1) > range(2)
  stop = range(1);
  start = range(2);
else
  start = range(1);
  stop = range(2);
end

start = max(1, round(start));
stop = min(length(handles.plot.r), round(stop));

p_range = zeros(1, length(handles.plot.r));
p_range(start:stop) = 1;

stem_size = max(handles.plot.ecg);
baseline = min(handles.plot.ecg);

n_col = size(handles.plot.r,1);

multipl_r = handles.plot.r;
multipl_r(isnan(multipl_r)) = 0;
p_sum = power(2, 0:(n_col-1))*multipl_r;
p_rules = zeros(n_col, 1);

% plot if and only if
p_rules(1) = 1;
p_rules(2) = 2;

for k=1:n_col*2
  if mod(k, 2) == 0
    ev_idx = k/2;
    layer = handles.plot.missing_layer;
    cl = handles.clr{ev_idx+1}(cl_type,:);
    b_cl = rgb2gray(cl);
  else
    ev_idx = (k+1)/2;
    layer = ~handles.plot.missing_layer;
    cl = handles.clr{ev_idx+1}(cl_type,:);
    b_cl = cl;
  end

  layer = layer & p_range;
  if p_rules(ev_idx) ~= 0
    layer = layer & p_sum == p_rules(ev_idx);
  end


  if any(layer)
    if numel(stem_handles) < k || stem_handles(k) == -1
      % plot stems
      stem_handles(k) = stem(handles.plot.y(layer),...
        handles.plot.r(ev_idx,layer)*stem_size,'color',b_cl);
      % set stem layout
      set(stem_handles(k),'Linewidth',2,...
        'MarkerFaceColor',cl, 'MarkerEdgeColor', cl);

      % set baseline
      sbase = get(stem_handles(k),'baseline');
      set(sbase,'BaseValue',baseline,'Visible','off');
    else
      % update stemdata
      set(stem_handles(k), 'XData', handles.plot.y(layer), ...
        'YData', handles.plot.r(ev_idx,layer)*stem_size);
    end
    uistack(stem_handles(k), 'top');
  else
    if numel(stem_handles) >= k && stem_handles(k) ~= -1
      delete(stem_handles(k));
    end
    stem_handles(k) = -1;
  end
end
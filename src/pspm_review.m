function varargout = pspm_review(varargin)
% ● Description
%   pspm_review is the MATLAB code for pspm_review.fig
% ● History
%   Introduced in PsPM 3.0
%   Written in 2008-2015 by Gabriel Graeni (University of Zurich)
%   Maintained in 2022 by Teddy
%   Maintained in 2024 by Bernhard Agoué von Raußendorf

%% Initialise
global settings
if isempty(settings)
  pspm_init;
end
sts = -1;
% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
  'gui_Singleton',  gui_Singleton, ...
  'gui_OpeningFcn', @pspm_review_OpeningFcn, ...
  'gui_OutputFcn',  @pspm_review_OutputFcn, ...
  'gui_LayoutFcn',  [] , ...
  'gui_Callback',   []);
if nargin && ischar(varargin{1})
  gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
  [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
  gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT


% --- Executes just before pspm_review is made visible.
function pspm_review_OpeningFcn(hObject, ~, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to pspm_review (see VARARGIN)

% Left alignment of text fields
set(handles.textPlot1,'HorizontalAlignment','left')
set(handles.textPlot2,'HorizontalAlignment','left')
set(handles.textPlot3,'HorizontalAlignment','left')
set(handles.textPlot4,'HorizontalAlignment','left')
set(handles.textPlot5,'HorizontalAlignment','left')
set(handles.textPlot6,'HorizontalAlignment','left')
set(handles.textPlot7,'HorizontalAlignment','left')
set(handles.textStatus,'HorizontalAlignment','left')
set(handles.textStatus,'String','Select a model...');

handles.nrPlot = 7;
%handles.figCnt = 0;
handles.modelCnt = 0;
handles.currentModel = 1;
handles.listModelEntry{1} = '';

% buffer figure handles to keep
handles.figToKeep = findall(0, 'type', 'figure');

% Choose default command line output for pspm_review
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

pspm_ui(hObject, handles, 'review');

% UIWAIT makes pspm_review wait for user response (see UIRESUME)
% uiwait(handles.pspm_review);


% --- Outputs from this function are returned to the command line.
function varargout = pspm_review_OutputFcn(~, ~, handles)
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;



% --- Executes on button press in buttonAddModel_old.
function buttonAddModel_Callback(hObject, ~, handles)
% hObject    handle to buttonAddModel_old (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
filt='.*\.mat$';
[modelfileArray, sts]=spm_select([1 inf], filt, 'Select model file');
if sts==0, return; end

% check each model file
setButtonDisable(handles)
set(handles.textStatus,'String','Loading model. Please wait...');
drawnow
for iFile = 1:size(modelfileArray, 1)
  modelfile = spm_file(modelfileArray(iFile, :));
  [sts, model, modeltype] = pspm_load1(modelfile, 'all', 'any');
  if sts == -1 || ~any(strcmp(modeltype,{'glm','dcm','sf'}))
    set(handles.textStatus,'String','No supported modeltype detected');
    drawnow
    return;
  elseif strcmp(modeltype,'sf')
    dcm = cellfun(@(field) strcmpi(field(1).modeltype, 'dcm'), model.model);
    if ~any(dcm)
      set(handles.textStatus,'String','No supported modeltype detected');
      drawnow
      return;
    end
  end

  handles.modelCnt = handles.modelCnt+1;

  handles.modelData{handles.modelCnt}.modeltype = modeltype;
  handles.modelData{handles.modelCnt}.model = model;
  handles.modelData{handles.modelCnt}.modelfile = modelfile;
  if strcmp(modeltype,'dcm')
    handles.modelData{handles.modelCnt}.maxSessionNr = numel(model.sn);
  end
  if strcmp(modeltype,'sf')
    handles.modelData{handles.modelCnt}.maxEpochNr = numel(model.model{dcm});
  end
  [~,modelfileName,~] = fileparts(modelfile);
  handles.listModelEntry{handles.modelCnt} = modelfileName;
  set(handles.listModel, 'String', handles.listModelEntry);
  set(handles.listModel, 'Value', handles.modelCnt);
  handles.currentModel = handles.modelCnt;
  handles.modelData{handles.modelCnt}.fig = setFigureHandle(handles);

  showModel(handles);

end
setButtonEnable(handles)

if handles.modelCnt > 1 
  set(handles.buttonRemoveModel, 'Enable', 'on');
end
guidata(hObject, handles);

% --- Executes on button press in buttonRemoveModel.
function buttonRemoveModel_Callback(hObject, ~, handles)
% hObject    handle to buttonRemoveModel (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.modelData{handles.currentModel} = [];
handles.modelData(cellfun('isempty',handles.modelData)) = [];
handles.listModelEntry{handles.currentModel} = [];
handles.listModelEntry(cellfun('isempty',handles.listModelEntry)) = [];
handles.modelCnt = handles.modelCnt - 1;
set(handles.listModel, 'String', handles.listModelEntry);
if handles.currentModel > handles.modelCnt
  handles.currentModel = handles.modelCnt;
end
set(handles.listModel, 'Value', handles.currentModel);
if handles.modelCnt < 2 
  set(handles.buttonRemoveModel, 'Enable', 'off');
end
showModel(handles);

guidata(hObject, handles);


% --- Executes on button press in buttonExit.
function buttonExit_Callback(~, ~, handles)
% hObject    handle to buttonExit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
closeFigures(handles);
delete(gcbf)


% --- Executes when user attempts to close pspm_review.
function pspm_review_CloseRequestFcn(~, ~, handles)
% hObject    handle to pspm_review (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: delete(hObject) closes the figure
closeFigures(handles);
delete(gcbf)



% --- Executes on button press in buttonPlot1.
function buttonPlot1_Callback(hObject, ~, handles)
% hObject    handle to buttonPlot1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
tmpStatusString = get(handles.textStatus,'String');
set(handles.textStatus,'String','Plotting is in progress. Please wait...');
switch handles.modelData{handles.currentModel}.modeltype
  case 'glm'
    [~, handles.modelData{handles.currentModel}.fig] = ...
      pspm_rev_glm(handles.modelData{handles.currentModel}.modelfile, 1);

  case 'dcm'
    sessionNr = checkSessionNr(handles);
    if sessionNr
      pspm_rev_dcm(handles.modelData{handles.currentModel}.model, 'sum', sessionNr, []);
    end

  case 'sf'
    epochNr = str2double(get(handles.editEpochNr,'String'));
    if isempty(epochNr) || epochNr > handles.modelData{handles.currentModel}.maxEpochNr || epochNr < 1
      uiwait(msgbox(sprintf('Epoch number has to be within the range [1 - %d]',...
        handles.modelData{handles.currentModel}.maxEpochNr),'Warning'));
    else
      dcm_method = cellfun(@(field) strcmpi(field(1).modeltype, 'dcm'),...
        handles.modelData{handles.currentModel}.model.model);
      pspm_rev_dcm(handles.modelData{handles.currentModel}.model.model{dcm_method}, 'sf', epochNr, []);
    end
end
set(handles.textStatus,'String',tmpStatusString);
guidata(hObject, handles);


% --- Executes on button press in buttonPlot2.
function buttonPlot2_Callback(hObject, ~, handles)
% hObject    handle to buttonPlot2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
tmpStatusString = get(handles.textStatus,'String');
set(handles.textStatus,'String','Plotting is in progress. Please wait...');
switch handles.modelData{handles.currentModel}.modeltype
  case 'glm'
    [~, handles.modelData{handles.currentModel}.fig] = ...
      pspm_rev_glm(handles.modelData{handles.currentModel}.modelfile, 2);

  case 'dcm'
    sessionNr = checkSessionNr(handles);
    if sessionNr
      maxTrialNr = numel(handles.modelData{handles.currentModel}.model.sn{sessionNr}.u);
      trialNr = str2double(get(handles.editTrialNr,'String'));
      if isempty(trialNr) || trialNr > maxTrialNr || trialNr < 1
        uiwait(msgbox(sprintf('Trial number has to be within the range [1 - %d]',maxTrialNr),'Warning'));
      else
        pspm_rev_dcm(handles.modelData{handles.currentModel}.model, 'inv', sessionNr, trialNr);
      end
    end

end
set(handles.textStatus,'String',tmpStatusString);
guidata(hObject, handles);

% --- Executes on button press in buttonPlot3.
function buttonPlot3_Callback(hObject, ~, handles)
% hObject    handle to buttonPlot3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
tmpStatusString = get(handles.textStatus,'String');
set(handles.textStatus,'String','Plotting is in progress. Please wait...');
switch handles.modelData{handles.currentModel}.modeltype
  case 'glm'
    [~, handles.modelData{handles.currentModel}.fig] = ...
      pspm_rev_glm(handles.modelData{handles.currentModel}.modelfile, 3);

  case 'dcm'
    sessionNr = checkSessionNr(handles);
    if sessionNr
      pspm_rev_dcm(handles.modelData{handles.currentModel}.model, 'scrf', sessionNr, []);
    end

end
set(handles.textStatus,'String',tmpStatusString);
guidata(hObject, handles);

% --- Executes on button press in buttonPlot4.
function buttonPlot4_Callback(hObject, ~, handles)
% hObject    handle to buttonPlot4 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
tmpStatusString = get(handles.textStatus,'String');
set(handles.textStatus,'String','Plotting is in progress. Please wait...');
switch handles.modelData{handles.currentModel}.modeltype
  case 'glm'
    [~, handles.modelData{handles.currentModel}.fig] = ...
      pspm_rev_glm(handles.modelData{handles.currentModel}.modelfile, 4);
  case 'dcm'
    pspm_rev_dcm(handles.modelData{handles.currentModel}.model, 'names');
end
set(handles.textStatus,'String',tmpStatusString);
guidata(hObject, handles);

% --- Executes on button press in buttonPlot5.
function buttonPlot5_Callback(hObject, ~, handles)
% hObject    handle to buttonPlot5 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
tmpStatusString = get(handles.textStatus,'String');
set(handles.textStatus,'String','Plotting is in progress. Please wait...');
switch handles.modelData{handles.currentModel}.modeltype

  case 'glm'
    [~, handles.modelData{handles.currentModel}.fig] = ...
      pspm_rev_glm(handles.modelData{handles.currentModel}.modelfile, 5);
    
  case 'dcm'
      pspm_rev_dcm(handles.modelData{handles.currentModel}.modelfile, 'seg', [], []);

end
set(handles.textStatus,'String',tmpStatusString);
guidata(hObject, handles);


% --- Executes on button press in buttonPlot6.
function buttonPlot6_Callback(hObject, ~, handles)
% hObject    handle to buttonPlot6 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
tmpStatusString = get(handles.textStatus,'String');
set(handles.textStatus,'String','Plotting is in progress. Please wait...');
switch handles.modelData{handles.currentModel}.modeltype
    case 'glm'
       modelfile = handles.modelData{handles.currentModel}.modelfile;
       [~, handles.modelData{handles.currentModel}.fig] = pspm_rev_glm(modelfile, 6);


  % contrast in comand window     
  case 'dcm'
    [~, handles.modelData{handles.currentModel}.fig] = ...
      pspm_rev_con(handles.modelData{handles.currentModel}.model);

end

set(handles.textStatus,'String',tmpStatusString);
guidata(hObject, handles);


% --- Executes on button press in buttonPlot7.
function buttonPlot7_Callback(hObject, ~, handles)
% hObject    handle to buttonPlot7 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
tmpStatusString = get(handles.textStatus,'String');
set(handles.textStatus,'String','Plotting is in progress. Please wait...');
switch handles.modelData{handles.currentModel}.modeltype
  case 'glm'
    [~, handles.modelData{handles.currentModel}.fig] = ...
      pspm_rev_con(handles.modelData{handles.currentModel}.model);

end
set(handles.textStatus,'String',tmpStatusString);
guidata(hObject, handles);


% --- Executes on button press in buttonPlotClose.
function buttonPlotClose_Callback(~, ~, handles)
% hObject    handle to buttonPlotClose (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
closeFigures(handles)

function editTrialNr_Callback(~, ~, ~)
% hObject    handle to editTrialNr (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editTrialNr as text
%        str2double(get(hObject,'String')) returns contents of editTrialNr as a double


% --- Executes during object creation, after setting all properties.
function editTrialNr_CreateFcn(hObject, ~, ~)
% hObject    handle to editTrialNr (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
  set(hObject,'BackgroundColor','white');
end

% --- Executes on selection change in listModel.
function listModel_Callback(hObject, ~, handles)
% hObject    handle to listModel (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns listModel contents as cell array
%        contents{get(hObject,'Value')} returns selected item from listModel
entryNr = get(handles.listModel,'Value');
if ~isempty(entryNr)
  handles.currentModel = entryNr;
  showModel(handles);
  guidata(hObject, handles)
end


% --- Executes during object creation, after setting all properties.
function listModel_CreateFcn(hObject, ~, ~)
% hObject    handle to listModel (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), ...
    get(0,'defaultUicontrolBackgroundColor'))
  set(hObject,'BackgroundColor','white');
end



%--------------------------------------------------------------------------
% Functions
%--------------------------------------------------------------------------
function setInvisble(handles)
for i=1:handles.nrPlot
  eval(sprintf('set(handles.buttonPlot%d,''Visible'',''off'')',i));
  eval(sprintf('set(handles.textPlot%d,''Visible'',''off'')',i));
end
set(handles.buttonPlotClose,'Visible','off');
set(handles.editTrialNr,'Visible','off');
set(handles.editEpochNr,'Visible','off');
set(handles.editSessionNr,'Visible','off');
set(handles.textSessionNr,'Visible','off');
set(handles.textSessionRange,'Visible','off');

function setButtonPlotString(handles, inString)
for i=1:size(inString,2)
  if ~isempty(inString{i})
    eval(sprintf('set(handles.buttonPlot%d,''String'',inString{%d})',i,i));
    eval(sprintf('set(handles.buttonPlot%d,''Visible'',''on'')',i));
  end
end
set(handles.buttonPlotClose,'Visible','on');

function setButtonDisable(handles)
for i=1:handles.nrPlot
  eval(sprintf('set(handles.buttonPlot%d,''Enable'',''off'')',i));
end

function setButtonEnable(handles)
for i=1:handles.nrPlot
  eval(sprintf('set(handles.buttonPlot%d,''Enable'',''on'')',i));
end

function setTextPlotString(handles, inString)
for i=1:size(inString,2)
  if ~isempty(inString{i})
    eval(sprintf('set(handles.textPlot%d,''String'',inString{%d})',i,i));
    eval(sprintf('set(handles.textPlot%d,''Visible'',''on'')',i));
  end
end

function setTrial(handles)
set(handles.editTrialNr,'Visible','on');

function setSession(handles)
nr = handles.modelData{handles.currentModel}.maxSessionNr;
set(handles.editSessionNr,'Visible','on');
set(handles.textSessionNr,'Visible','on');
set(handles.textSessionRange,'Visible','on');
set(handles.textSessionRange,'String',sprintf('[1 - %d]',nr));

function setEpoch(handles)
set(handles.editEpochNr,'Visible','on');

function fig = setFigureHandle(handles)
for i = 1:handles.nrPlot
  fig(i).h=-1;
end

function closeFigures(handles)
if isfield(handles, 'figToKeep')
  close(setdiff(findobj('type','figure'),handles.figToKeep));
else
  close(setdiff(findobj('type','figure'),handles));
end

function sessionNr = checkSessionNr(handles)
sessionNr = str2double(get(handles.editSessionNr,'String'));
if isempty(sessionNr) || sessionNr > handles.modelData{handles.currentModel}.maxSessionNr || sessionNr < 1
  uiwait(msgbox(sprintf('Session number has to be within the range [1 - %d]',...
    handles.modelData{handles.currentModel}.maxSessionNr),'Warning'));
  sessionNr = [];
end

function showModel(handles)

% detect model
switch handles.modelData{handles.currentModel}.modeltype
  case 'glm'
    buttonPlotString = {'Plot', ...
      'Plot', ...
      'Plot', ...
      'Show', ...
      'Plot', ...
      'Plot'};
    textPlotString = {'Design matrix in SPM style', ...
      'Orthogonality in SPM style', ...
      'Predicted & observed', ...
      'Regressors in command window', ...
      'Reconstructed responses', ...
      'Plot data per condition'};
    % detect contrasts
    if isfield(handles.modelData{handles.currentModel}.model, 'con')
      buttonPlotString{7} = 'Show';
      textPlotString{7} = 'Contrast names in command window';
    end
    setInvisble(handles);
    setButtonPlotString(handles, buttonPlotString);
    setTextPlotString(handles, textPlotString);
    set(handles.textStatus,'String','Detected modeltype: GLM');
    drawnow

  case 'dcm'
    buttonPlotString = {'Display', ...
      'Display', ...
      'Display', ...
      'Show', ...
      'Plot'};
    textPlotString = {'All trials for one session', ...
      'Diagnostics for trial nr.', ...
      'Skin conductance response function (SCR)', ...
      'Trial and condition names in command window', ...
      'Plot data per condition'};
    % detect contrasts
    if isfield(handles.modelData{handles.currentModel}.model, 'con')
      buttonPlotString{6} = 'Show';
      textPlotString{6} = 'Contrast names in command window';
    end
    setInvisble(handles);
    setButtonPlotString(handles, buttonPlotString);
    setTextPlotString(handles, textPlotString);
    setSession(handles);
    setTrial(handles);
    set(handles.textStatus,'String','Detected modeltype: DCM')
    drawnow

  case 'sf'
    buttonPlotString = {'Display'};
    textPlotString = {'Diagnostics for epoch nr.'};
    if isfield(handles.modelData{handles.currentModel}.model, 'con')
      buttonPlotString{2} = 'Show';
      textPlotString{2} = 'Contrast names in command window';
    end
    setInvisble(handles);
    setButtonPlotString(handles, buttonPlotString);
    setTextPlotString(handles, textPlotString);
    setEpoch(handles);
    set(handles.textStatus,'String','Detected modeltype: SF')
    drawnow
end

% --- Executes during object creation, after setting all properties.
function editEpochNr_CreateFcn(hObject, ~, ~)
% hObject    handle to editEpochNr (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
  set(hObject,'BackgroundColor','white');
end

function editEpochNr_Callback(~, ~, ~)
% hObject    handle to editEpochNr (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editEpochNr as text
%        str2double(get(hObject,'String')) returns contents of editEpochNr as a double

% --- Executes on button press in pushbutton_quit.
function pushbutton_quit_Callback(~, ~, handles)
% hObject    handle to pushbutton_quit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
closeFigures(handles);
delete(gcbf)

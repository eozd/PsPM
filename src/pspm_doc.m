function sts = pspm_doc(func_name, varargin)
% ● Description
%    pspm_doc sorts the help text and save into a file or variable for future usage.
% ● Format
%    sts = pspm_doc(func_name, options)
% ● Arguments
%   * func_name: [string] The name of the function whose help text is to be saved.

%% 1 Initialise
global settings
if isempty(settings)
  pspm_init;
end
sts = -1;
%% 2 Read help text into a struct
S = pspm_help(func_name);
if nargin > 1
  options = varargin{1};
else
  options = struct();
end
%% 3 Convert to markdown
M = [];
% 3.1 Add title
Title       = pspm_doc_get_title(func_name);
M = [M, '---', newline];
M = [M, 'layout: post', newline];
M = [M, 'title: ', func_name, newline];
M = [M, 'permalink: /ref/', func_name, newline];
M = [M, '---', newline];
M = [M, ' ', newline];
M = [M, '[Back to index](/PsPM/ref/)', newline];
% 3.2 Add description
if isfield(S, 'Description')
  Description = pspm_doc_get_description(S.Description);
  M = [M, newline, '## ', 'Description',  newline, newline, Description, newline, newline];
end
% 3.3 Add format
if isfield(S, 'Format')
  Format      = pspm_doc_get_format(S.Format);
  M = [M, '## ', 'Format',       newline, newline, Format,      newline, newline];
end
% 3.4 Add arguments
if isfield(S, 'Arguments')
  Arguments   = pspm_doc_get_struct_fields(S.Arguments);
  M = [M, '## ', 'Arguments',    newline, newline, Arguments,   newline, newline];
end
% 3.5 Add outputs
if isfield(S, 'Outputs')
  Outputs   = pspm_doc_get_struct_fields(S.Outputs);
  M = [M, '## ', 'Outputs',      newline, newline, Outputs,     newline, newline];
end
% 3.6 Add references
if isfield(S, 'References')
  References  = pspm_doc_get_references(S.References);
  M = [M, '## ', 'References',   newline, newline, References,  newline, newline];
end
M = [M, '[Back to index](/PsPM/ref/)', newline];
%% 4 Write to file
if isfield(options, 'post') && options.post == 1
  PrefTitle = ['2024-01-01-',Title];
else
  PrefTitle = Title;
end
if isfield(options, 'path')
  writelines(M, [options.path, '/', PrefTitle,'.md']);
else
  writelines(M, [PrefTitle,'.md']);
end
sts = 1;
end

function Y = pspm_doc_get_title(X)
if strcmp(X(end-1:end),'.m')
  Y = X(1:end-2);
else
  Y = X;
end
end
function Y = pspm_doc_get_format(X)
Y = ['`',insertAfter(insertBefore(X, char(10), '` or'), char(10),'`'), '`'];
LocStar = strfind(Y, '`→');
LocOr   = strfind(Y, '` or');
LocRm   = [];
for iLocStar = 1:length(LocStar)
  LocBefore = LocOr(LocOr < LocStar(iLocStar));
  if ~isempty(LocBefore)
    LocBefore = max(LocBefore);
    LocRm = [LocRm, (LocBefore+1):(LocBefore+3)];
  end
  LocAfter  = LocOr(LocOr > LocStar(iLocStar));
  if ~isempty(LocAfter)
    LocAfter = min(LocAfter);
    LocRm = [LocRm, LocAfter:(LocAfter+3)];
  end
  LocRm = [LocRm,LocStar];
end
Y(LocRm) = [];
Y = [Y, newline];
end
function Y = pspm_doc_get_description(X)
X = insertAfter(X, newline, newline);
Y = [X, newline];
end
function Y = pspm_doc_get_struct_fields(X)
Y = ['| Variable | Definition |',newline,'|:--|:--|', newline];
list_arg = fieldnames(X);
for i_arg = 1:length(list_arg)
  switch class(X.(list_arg{i_arg}))
    case 'char'
      Y = [Y, '| ', list_arg{i_arg}, ' | ', X.(list_arg{i_arg}), ' |', newline];
    case 'struct'
      Y = [Y, '| ', list_arg{i_arg}, ' | ', 'See following fields.', ' |', newline];
      list_arg2 = fieldnames(X.(list_arg{i_arg}));
      for i_arg2 = 1:length(list_arg2)
        switch class(X.(list_arg{i_arg}).(list_arg2{i_arg2}))
          case 'char'
            Y = [Y, '| ', list_arg{i_arg}, '.', list_arg2{i_arg2}, ' | ', ...
              X.(list_arg{i_arg}).(list_arg2{i_arg2}), ' |'];
          case 'struct'
            Y = [Y, '| ', list_arg{i_arg}, '.', list_arg2{i_arg2}, ' | ', 'See following fields.', ' |', newline];
            list_arg3 = fieldnames(X.(list_arg{i_arg}).(list_arg2{i_arg2}));
            for i_arg3 = 1:length(list_arg3)
              Y = [Y, '| ', list_arg{i_arg}, '.', list_arg2{i_arg2}, '.', list_arg3{i_arg3}, ' | ', ...
                X.(list_arg{i_arg}).(list_arg2{i_arg2}).(list_arg3{i_arg3}), ' |'];
              if i_arg3 < length(list_arg3)
                Y = [Y, newline];
              end
            end
        end
        if i_arg2 < length(list_arg2)
          Y = [Y, newline];
        end
        if i_arg2 == length(list_arg2) && isstruct(X.(list_arg{i_arg}).(list_arg2{i_arg2}))
          Y = [Y, newline];
        end
      end
      Y = [Y, newline];
  end
end
end
function Y = pspm_doc_get_references(X)
Y = [];
for i_ref = 1:length(X)
  Y = [Y, X{i_ref}, newline, newline];
end
end
function Y = pspm_eye(X, feature)
% ● Description
%   pspm_eye converts legacy use of eye markers into the current version
% ● Format
%   Y = pspm_eye(X,feature)
% ● Arguments
%   * X: The input eye marker.
%   * feature: The feature used for converting eye marker. Accepted values
%   are 'lr2c', 'char2cell' and 'channel2lateral'.
% ● Outputs
%   * Y: The converted eye marker.
% ● History
%   Introduced in PsPM 6.0
%   Written in 2015 by Teddy

global settings
if isempty(settings)
  pspm_init;
end
switch feature
  case 'lr2c'
    % Examples
    % 'l'  →  'l'
    % 'R'  →  'r'
    % 'lr' →  'c'
    % 'rL' →  'c'
    % {'L','r','Lr','rl'}  →  {'l','r','c','c'}
    Y = lower(X);
    switch class(Y)
      case 'char'
        switch Y
          case {'lr', 'rl'}
              Y = settings.lateral.char.c;
            case 'l'
              Y = settings.lateral.char.l;
            case 'r'
              Y = settings.lateral.char.r;
        end
      case 'cell'
        %Y{Y=='l'} = settings.lateral.char.l; 
        %Y{Y=='r'} = settings.lateral.char.r;
        %Y{Y=='lr'} = settings.lateral.char.c;
        %Y{Y=='rl'} = settings.lateral.char.c;
        Y(strcmp(Y, 'l')) = {settings.lateral.char.l};
        Y(strcmp(Y, 'r')) = {settings.lateral.char.r};
        Y(strcmp(Y, 'lr')) = {settings.lateral.char.c};
        Y(strcmp(Y, 'rl')) = {settings.lateral.char.c};

    end
  case 'char2cell'
    % Examples
    % 'l'   →  {'l'}
    % 'R'   →  {'r'}
    % 'C'   →  {'l','r'}
    % 'lR'  →  {'l','r'}
    Y = lower(X);
    switch Y
      case {'l','r'}
        Y = {Y};
      case {'c','lr','rl'}
        Y = {'l','r'};
    end
  case 'channel2lateral'
    % Examples
    % 'pupil_l'    →  {'l'}
    %  'gaze_x_r'  → {'r'}
    Y = lower(X);
    switch class(Y)
      case 'char'
        Y = pspm_single_channel_lateral(Y);
      case 'cell'
        for i = 1:numel(Y)
          Y{i} = pspm_single_channel_lateral(Y{i});
        end
    end
end
return

function Y = pspm_single_channel_lateral(X)
if ~isempty(regexpi(X, '_lr', 'once'))
  Y = 'c';
elseif ~isempty(regexpi(X, '_rl', 'once'))
  Y = 'c';
elseif ~isempty(regexpi(X, '_c', 'once'))
  Y = 'c';
elseif ~isempty(regexpi(X, '_l', 'once'))
  Y = 'l';
elseif ~isempty(regexpi(X, '_r', 'once'))
  Y = 'r';
else
  Y = {};
end
return

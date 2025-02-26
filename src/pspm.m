function pspm(varargin)
% ● Description
%   pspm.m handles the main GUI for PsPM
% ● Developer
%   PsPM will no longer support GUIDE and only use App Designer for UI.
%   App Designer is available for MATLAB that is later than version R2016a (9.0).
% ● History
%   Last Updated in PsPM 7.0
%   Written in 12-2023 by Teddy
%   Updared in 06-2024 by Teddy


release_date_current = datetime(version('-date'));
release_date_win = datetime('01-Jan-2018');
release_date_appdesigner_cutoff = datetime('01-Jan-2020');
release_date_mac = datetime('01-Jan-2018');
release_date_linux = datetime('01-Jan-2022');
if ispc
  if release_date_current < release_date_win % MATLAB 2018
    msgbox(['PsPM UI is not supported by this version of MATLAB. ',...
      'Please consider updating your MATLAB to 2018a or newer, ',...
      'or alternatively using scripts only.']);
  else
    if release_date_current < release_date_appdesigner_cutoff % MATLAB 2018
      pspm_appdesigner2019
    else
      pspm_appdesigner
    end
  end
elseif ismac
  if release_date_current < release_date_mac % MATLAB 2018
    msgbox(['PsPM UI is not supported by this version of MATLAB. ',...
      'Please consider updating your MATLAB to 2018a for macOS or newer, ',...
      'or alternatively using scripts only.']);
    % pspm_guide
  else
    if release_date_current < release_date_appdesigner_cutoff % MATLAB 2018
      pspm_appdesigner2019
    else
      pspm_appdesigner
    end
  end
else % Linux
  if release_date_current < release_date_linux % MATLAB 2022
    msgbox(['PsPM UI is not supported by this version of MATLAB. ',...
      'Please consider updating your MATLAB to 2022a for Linux or newer, ',...
      'or alternatively using scripts only.']);
    % pspm_guide
  else
    if release_date_current < release_date_appdesigner_cutoff % MATLAB 2018
      pspm_appdesigner2019
    else
      pspm_appdesigner
    end
  end
end
return

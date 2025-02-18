function theta = pspm_get_rf(fn, events, outfile, channel, options)
% ● Description
%   pspm_get_rf estimates a response function from an event-related design
%   (e.g. for further use in a GLM analysis), using a regularisation as
%   third-order ODE and DCM machinery.
% ● Developer's Notes
%   the function returns an m-function for the RF, and the parameters of that
%   function
% ● Format
%   theta = pspm_get_rf(fn, events, outfile, channel, options)
% ● Arguments
%   *      fn : the file name of a PsPM data file
%   *  events : specified in seconds as either (1) a vector of onsets, or (2) an
%               SPM style onsets file with one event type, or (3) an epochs file
%               (see pspm_dcm or pspm_get_epochs).
%   * outfile : (optional) a file to write the response function to
%   * channel : (optional) data channel (default: look for first SCR channel)
%   * options : [struct] to be passed on to pspm_dcm
% ● History
%   Introduced in PsPM 3.0
%   Written in 2008-2015 by Dominik R Bach (Wellcome Trust Centre for Neuroimaging)

%% initialise
global settings
if isempty(settings)
  pspm_init;
end
sts = -1;
rf = [];

%% check input
if nargin < 1
  warning('No data to work on.'); return;
elseif nargin < 2
  warning('No events specified'); return;
elseif nargin < 3
  outfile = '';
end
if isempty(outfile) || ~ischar(outfile)
  [pth infn ext] = fileparts(fn);
  outfile = fullfile(pth, ['RF_', infn, ext]);
end
if nargin < 4
  channel = 'scr';
end

%% call DCM
options = pspm_options(options, 'get_rf');
% options.getrf = 1;
%try options.nosave, catch, options.nosave = 1; end;
options.channel = channel;
[foo dcm] = pspm_dcm(fn, '', events, options);
if numel(dcm{1}.prior.posterior) == 2
  % based on eSCR
  theta = dcm{1}.prior.posterior(2).muTheta(1:7)';
else
  % based on aSCR (i. e. updated RF)
  theta = dcm{1}.prior.posterior(3).muTheta(1:7)';
end

%% write response function to file
if ~isempty(outfile)
  [pth fn ext] = fileparts(outfile);
  c = clock;
  job{1}  = sprintf('function [rf, theta] = %s(td)', fn);
  job{2}  = '%-----------------------------------------------------------------------';
  job{3}  = ['% Response function created by pspm_get_rf, ', date, sprintf('  %02.0f:%02.0f', c(4:5))];
  job{4}  = '%-----------------------------------------------------------------------';
  job{5}  = sprintf('theta = [%f %f %f %f %f %f %f];', theta);
  job{6}  = sprintf('ut(1, :) = td:td:90;');
  job{7}  = sprintf('ut(2, :) = 0;');
  job{8}  = sprintf('ut(3, :) = 1;');
  job{9}  = sprintf('ut(4, :) = 0;');
  job{10} = sprintf('ut(5, :) = 0;');
  job{11} = sprintf('ut(6, :) = 0;');
  job{12} = sprintf('Theta = [theta(1:4) 0 0 0 log(1)];');
  job{13} = sprintf('Xt = zeros(7, 1);');
  job{14} = sprintf('in.dt = td;');
  job{15} = sprintf('for k = 1:size(ut, 2)');
  job{16} = sprintf('   Xt(:, k + 1) = f_SCR(Xt(:, k), Theta, ut(:, k), in);');
  job{17} = sprintf('end;');
  job{18} = sprintf('rf = Xt(1, :);');
  job{19} = sprintf('rf = rf/max(rf);');
  job{20} = sprintf('rf = rf(:);');
  job = strvcat(job');
  outfile = fullfile(pth, [fn, '.m']);
  dlmwrite(outfile, job, 'delimiter', '');
end
sts = 1;
return

function sts = pspm_rev_dcm(dcm, job, sn, trl)
% ● Description
%   pspm_rev_dcm displays DCM results post hoc. It is meant to be called by
%   pspm_review only.
% ● Developer's Notes
%   The development of this funcrion is still in progress.
%   More jobs to be implemented.
% ● Format
%   pspm_rev_dcm(dcm, job, sn, trl)
% ● Arguments
%   * dcm :  dcm struct or modelfile
%   * job :  [char], accepts 'inv', 'sf', 'sum', 'scrf', or 'names'.
%            'inv'   show inversion results, input argument session & trial number
%            'sf'    same for SF, input argument episode number
%            'sum'   show trial-by-trial summary, input argument session
%                    number, optional argument figure name (saves the figure)
%                    (can also be called as ...(dcm, 'sum', figname) for
%                    on-the-fly display and saving of figure)
%            'scrf'  show peripheral skin conductance response function as used
%                    for trial-by-trial estimation of sympathetic input
%            'names' show trial and condition names in command window
%            'seg'   show the mean responses of all segments identified in 
%                    the DCM model. ('pspm_extract_segments')
%   *  sn: session.
%   * trl: trial.
% ● History
%   Introduced In PsPM 3.0
%   Written in 2008-2015 by Dominik R Bach (Wellcome Trust Centre for Neuroimaging)
%   Maintained in 2022 by Teddy
%   Maintained in 2024 by Bernhard Agoué von Raußendorf


%% Initialise
global settings
if isempty(settings)
  pspm_init;
end
sts = -1;

try, sn; catch, sn = 1; end;

if ischar(dcm)
    [~, dcm, ~] = pspm_load1(dcm, 'all');
end

% check input
% ------------------------------------------------------------------------
if strcmp(job,'sf')
  if numel(dcm) < sn
    warning('Episode %1.0f does not exist', sn); return;
  end
else
  if numel(dcm.sn) < sn
    warning('Session %1.0f does not exist', sn); return;
  elseif strcmpi(job, 'inv') && numel(dcm.sn{sn}.u) < trl
    warning('Trial %1.0f in session %1.0f does not exist', trl, sn); return;
  end;
end


% do the job
% ------------------------------------------------------------------------
switch job
  % display single trial inversion results
  % ---------------------------------------------------------------------
  case 'inv'
    fprintf('Displaying inversion results for trial %1.0f in session %1.0f\n', trl, sn);
    VBA_ReDisplay(dcm.sn{sn}.posterior(trl), dcm.sn{sn}.output(trl), 1, []);

  case 'sf'
    fprintf('Displaying inversion results for epoch %1.0f\n', sn);
    VBA_ReDisplay(dcm(sn).inv.model.posterior, dcm(sn).inv.model.output, 1, []);

    % display trial-by-trial summary
    % ---------------------------------------------------------------------
  case 'sum'
    fprintf('Displaying observed and estimated responses for session %1.0f\n', sn);
    Xt = dcm.sn{sn}.Xt;
    trlno = numel(dcm.sn{sn}.a);
    trlstart = dcm.input.trlstart{sn};
    y = dcm.sn{sn}.y(:);
    yhat = dcm.sn{sn}.yhat(:);
    f.h = figure('Position', [50 50 750 750], 'PaperPositionMode', 'auto', 'PaperOrientation', 'Portrait', 'InvertHardCopy', 'off', 'Color', 'w', 'Name', 'Session summary');
    foo = ceil(sqrt(trlno));
    f.r = foo; f.c = ceil(trlno/foo);
    sr = 10;
    for n = 1:trlno
      if n < trlno
        win = floor(sr * ((trlstart(n)):(1/sr):(trlstart(n + 1))));
      else
        win = floor(sr * ((trlstart(n)):(1/sr):(numel(yhat)/sr)));
      end;
      win(win == 0) = [];
      data = [y(win), yhat(win)];
      subplot(f.r, f.c, n);
      plot(data);
      xt = get(gca, 'XTick');
      set(gca, 'XTickLabel', xt / dcm.input.sr);
      set(gca, 'YLim', [min(yhat), max(yhat)]);
    end;
    % display scrf
    % ---------------------------------------------------------------------
  case 'scrf'
    xt = zeros(1, 7);
    ut = 0:0.1:30;% time
    ut(2, :) = 0; % aSCR
    ut(3, :) = 1; % eSCR
    ut(4, :) = 0; % SF
    ut(5, :) = 0; % sCL changes
    ut(6, :) = 0; % eSCR onset at zero
    in.dt = 0.1;
    Theta = [dcm.sn{sn}.prior.theta 1];
    for x = 1:size(ut, 2)
      xt(x + 1, :) = f_SCR(xt(x, :), Theta, ut(:, x), in);
    end;
    figure; plot(xt(:, 1));
    set(gca, 'YTick', [], 'XTick', 0:50:300, 'XTickLabel', 0:5:30, 'FontWeight', 'Bold', 'FontSize', 12);
    set(get(gca, 'Title'), 'String', 'Skin conductance response function', 'FontWeight', 'Bold', 'FontSize', 16);
  case 'names'
    fprintf('Trial names for %s:\n---------------------------------------\n', dcm.dcmname);
    for n=1:numel(dcm.trlnames)
      fprintf('Trial %d: %s\n',n,dcm.trlnames{n});
    end;
    fprintf('---------------------------------------\n');
    fprintf('Condition names for %s:\n---------------------------------------\n', dcm.dcmname);
    for n=1:numel(dcm.condnames)
      fprintf('Condition %d: %s\n',n,dcm.condnames{n});
    end;
    fprintf('---------------------------------------\n');
  case 'seg'
         
    options = struct('plot', 1);
    [ssts, segments] = pspm_extract_segments('model', dcm, options);

end;

sts = 1;
return

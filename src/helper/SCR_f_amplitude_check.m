%% Check the scaling of SCR/SF amplitudes in functions f_SF and f_SCR as
% implemented in pspm_sf_dcm.m and pspm_dcm_inv.m
% Dominik R Bach 09.05.2014
% -------------------------------------------------------------------------
% last edited 12.05.2014

% $ Id: $%
% $ Rev $%

pspm_init;
test_scr = 0;
test_sf = 1;

% (1) check f_SCR and pspm_dcm_inv: the result is a variable 'amp' that gives
% the estimated SN pulse amplitude for an elicited eSCR of unit 1
% -------------------------------------------------------------------------
if test_scr
    
    % parameter estimates from pspm_dcm_inv
    crftheta = log([0.1225    1.4114    1.3421    1.5339, 0, 0, 0]);
    
    % =========================================================================
    % for individual response functions, insert parameters from individual
    % dcm{1}.prior.theta instead!
    % =========================================================================
    
    % create an eSCR input with unit amplitude
    theta = [crftheta, log(1), log(1)];
    sr = 1000;
    ut = (1/sr):(1/sr):300; % time
    ut(2, :) = 0;     % no of aSCR
    ut(3, :) = 2;     % no of eSCR
    ut(4, :) = 0;     % no of SF
    ut(5, :) = 0;     % no of SCL changes
    ut(6, :) = 0;     % 2 eSCR onsets
    ut(7, :) = 29.9;
    in.dt    = 1/sr;   % sampling interval
    Xt       = zeros(7, 1); % starting values
    
    % approximate numeric integration
    for iT = 1:(30*sr)
        Xt(:, iT + 1) = f_SCR(Xt(:, iT), theta, ut(:, iT), in);
    end
    
    % scale data
    Y = Xt(1, :) / max(Xt(1, :));
    
    % reduce sample rate
    Y = Y(1:(sr/10):end);
    
    % create and estimate model
    model.scr = {Y};
    model.sr  = 10;
    model.events{1}{1} = [];
    model.events{2}{1} = [0 30];
    model.trlstart = {[0 30]};
    model.trlstop  = {[0 30]};
    model.iti      = {30};
    options.depth  = 2;
    options.sfpost = 30;
    options.sclpost = 30;
    options.rf     = theta(1:7);
    global settings
    addpath([settings.path, 'DAVB']);
    addpath([settings.path, 'DAVB', filesep, 'subfunctions']);
    
    dcm = pspm_dcm_inv(model, options);
    
    amp = dcm.sn{1}.e(1).a;
    
end


% (2) check f_SF and pspm_sf_dcm: the result is a variable 'amp' that gives
% the estimated SN pulse amplitude for an elicited SF of unit 1
% -------------------------------------------------------------------------
if test_sf
    
    % parameter estimates as in pspm_sf_dcm
    sftheta = pspm_sf_theta;
    
    % create an file with an SF with unit 1
    theta = [sftheta(1:3), 10, log(1)];
    sr = 1000;
    ut = (1/sr):(1/sr):300; % time  
    ut(2, :) = 1;           % number of SF
    in.dt    = 1/sr;   % sampling interval
    Xt       = zeros(3, 1); % starting values

    % approximate numeric integration
    for iT = 1:(30*sr)
        Xt(:, iT + 1) = f_SF(Xt(:, iT), theta, ut(:, iT), in);
    end
    
    % scale data
    Y = Xt(1, :) / max(Xt(1, :));
    
    % reduce sample rate
    Y = Y(1:(sr/10):end);
    
    % create and estimate model
    scr = Y;
    sr  = 10;
    global settings
    addpath(pspm_path('ext','VBA'));
    addpath(pspm_path('ext','VBA','subfunctions'));
    options.fresp = 1/40;
    
    dcm = pspm_sf_dcm(scr, sr, options);
    
    
end

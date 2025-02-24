function theta = pspm_sf_get_theta(scr, sr, esr, fn, closewindow)
% create parameters for f_SF, given some data scr
% 
% FORMAT
% function theta = pspm_sf_get_theta(scr, sr, fn, closewindow)
% 
%   theta:  parameters
%   scr:    skin conductance epoch (maximum size depends on comp
%   sr:     data sampling rate 
%   esr:    sampling rate at which to evaluate
%   fn:     file where parameters are written to
%   closewindow: close graphic display of estimation (default: 1)
% 
%
% REFERENCE
% Bach DR, Daunizeau J, Kuelzow N, Friston K, Dolan R (2010). Dynamic
% causal modelling of spontaneous fluctuations in skin conductance.
% Psychophysiology, in press.
%
%__________________________________________________________________________
% PsPM 3.0
% (C) 2008-2015 Dominik R Bach (Wellcome Trust Centre for Neuroimaging)

% $Id$
% $Rev$

% v02 drb 27.4.2010 adapted for general release
% v01 drb 30.7.2009 

% initialise
% -------------------------------------------------------------------------
global settings;
if isempty(settings), pspm_init; end;
% -------------------------------------------------------------------------

% check input arguments
%==========================================================================
if nargin < 4
    closewindow = 1; 
elseif closewindow ~= 0, 
    closewindow = 1; 
end

if nargin < 3
    fn = 'pspm_sf_theta.m';
end

fid = fopen(fn, 'w');
[pth fn ext] = fileparts(fn);

if fid < 0
    errmsg = 'Could not open file for writing.';
elseif ~ischar(fn)
    errmsg = sprintf('No valid filename.');
elseif nargin < 2 || ~isnumeric(sr) || numel(sr) > 1
    errmsg = sprintf('No sample rate given.');
elseif (sr < 1) || (sr > 1e5)
    errmsg = sprintf('Sample rate out of range.');
elseif nargin < 1 || ~isnumeric(scr)
    errmsg = 'No data.';
elseif ~any(size(scr) == 1)
    errmsg = 'Input SCR is not a vector';
else
    scr = scr(:);
end

if exist('errmsg') == 1, warning(errmsg); return; end;
        

% initial conditions 
%==========================================================================
theta = [0.923269 3.919950 2.158973 1.091917 1.570259]; 
phi   = [0 0]; 

% DAVB settings
g_fname = 'g_Id';
f_fname = 'f_SF';
dim.n_phi   =  2;                       % nb of observation parameters
dim.n       =  3;                       % nb of hidden states
priors.muX0 = zeros(dim.n,1);
priors.SigmaX0 = 1e-8*eye(dim.n);
priors.a_sigma = 1e5;             % Jeffrey's prior
priors.b_sigma = 1e1;             % Jeffrey's prior
priors.a_alpha = Inf;
priors.b_alpha = 0;
options.inG.ind = 1;
options.inF.dt = 1/sr;
options.decim = round(sr/esr);
options.GnFigs = 0; % suppress intermediate figs

u = [];
u(1, :) = (1:numel(scr))/sr;
u(2, :) = 1;
priors.muTheta = theta';
dim.n_theta = numel(priors.muTheta);    % nb of evolution parameters
priors.muPhi = phi';
priors.SigmaPhi = zeros(dim.n_phi);
priors.SigmaTheta = 1.*eye(dim.n_theta);
options.priors = priors;

% prepare data
scr = (scr - min(scr));
scr = scr/max(scr);


% estimate params
%==========================================================================
c = clock;
fprintf(['\nEstimating model parameters for f_SF ... \t%02.0f:%02.0f:%02.0f', ...
    '\n=========================================================\n'], c(4:6));
[posterior,out] = VBA_NLStateSpaceModel(scr(:)',u,f_fname,g_fname,dim,options);
theta = posterior.muTheta';


% write parameters to file
%==========================================================================
job{1} = sprintf('function [theta  sr] = %s', fn);
job{2} = sprintf('%% Parameter values for skin conductance response function f_SF');
job{3} = sprintf('%% Estimated on %s', date);
job{4} = sprintf('%%__________________________________________________________________________');
job{5} = sprintf('%% SCRalyze');
job{6} = sprintf('%% (C) 2009 Dominik R Bach (Wellcome Trust Centre for Neuroimaging)');
job{7} = ' ';
job{8} = sprintf('theta = [%f %f %f %f %f];', theta);
job{9} = sprintf('sr = %f', sr);

for f = 1:numel(job)
    fprintf(fid, '%s\n', job{f});
end


fclose(fid);
if closewindow == 1, close(gcf); end;




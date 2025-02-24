function tropts = cfg_tropts(stopspec, clvl, mlvl, cnt, mcnt, dflag)

% function tropts = cfg_tropts(stopspec, clvl, mlvl, cnt, mcnt, dflag)
% This function is a shorthand that generates a traversal options structure
% from the following items:
% stopspec -   a find spec shorthand as input to cfg_findspec (see
%              cfg_findspec for details)
% clvl, mlvl - current/maximum tree level
% cnt, mcnt - found items/maximum #items
% dflag      - traverse val/values part of tree
%
% This code is part of a batch job configuration system for MATLAB. See 
%      help matlabbatch
% for a general overview.
%_______________________________________________________________________
% Copyright (C) 2007 Freiburg Brain Imaging

% Volkmar Glauche
% $Id: cfg_tropts.m 380 2016-11-08 07:47:23Z tmoser $

rev = '$Rev: 380 $'; %#ok

if nargin == 0
    tropts = struct('stopspec', {}, 'clvl', {}, 'mlvl', {}, 'cnt', {}, 'mcnt', {}, 'dflag', {});
    return;
end

tropts.stopspec = cfg_findspec(stopspec);
tropts.clvl = clvl;
tropts.mlvl = mlvl;
tropts.cnt = cnt;
tropts.mcnt = mcnt;
tropts.dflag = dflag;
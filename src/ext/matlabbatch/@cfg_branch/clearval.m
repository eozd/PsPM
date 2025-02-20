function item = clearval(item, dflag)

% function item = clearval(item, dflag)
% Clear val fields in all items found in item.val.
% dflag is ignored in a cfg_branch.
%
% This code is part of a batch job configuration system for MATLAB. See 
%      help matlabbatch
% for a general overview.
%_______________________________________________________________________
% Copyright (C) 2007 Freiburg Brain Imaging

% Volkmar Glauche
% $Id: clearval.m 380 2016-11-08 07:47:23Z tmoser $

rev = '$Rev: 380 $'; %#ok

for k = 1:numel(item.cfg_item.val)
    item.cfg_item.val{k} = clearval(item.cfg_item.val{k}, ...
                                    dflag);
end


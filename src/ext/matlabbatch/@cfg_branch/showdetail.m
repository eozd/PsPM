function str = showdetail(item)

% function str = showdetail(item)
% Display details for a cfg_choice and all of its options.
%
% This code is part of a batch job configuration system for MATLAB. See 
%      help matlabbatch
% for a general overview.
%_______________________________________________________________________
% Copyright (C) 2007 Freiburg Brain Imaging

% Volkmar Glauche
% $Id: showdetail.m 380 2016-11-08 07:47:23Z tmoser $

rev = '$Rev: 380 $'; %#ok

str = showdetail(item.cfg_item);
str{end+1} = 'Set the options listed as a struct:';
% Display detailed help for each cfg_choice value item
tags = tagnames(item, true);
for k = 1:numel(tags)
    str{end+1} = sprintf('.%s', tags{k});
end
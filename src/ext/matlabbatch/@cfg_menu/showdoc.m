function str = showdoc(item, indent)

% function str = showdoc(item, indent)
% Display help text for a cfg_menu and all of its options.
%
% This code is part of a batch job configuration system for MATLAB. See 
%      help matlabbatch
% for a general overview.
%_______________________________________________________________________
% Copyright (C) 2007 Freiburg Brain Imaging

% Volkmar Glauche
% $Id: showdoc.m 380 2016-11-08 07:47:23Z tmoser $

rev = '$Rev: 380 $'; %#ok

str = showdoc(item.cfg_item, indent);
str{end+1} = sprintf('One of the following options must be selected:');
% Display cfg_menu labels
for k = 1:numel(item.labels)
    str{end+1} = sprintf('* %s', item.labels{k});
end;

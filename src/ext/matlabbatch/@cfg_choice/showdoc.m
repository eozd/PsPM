function str = showdoc(item, indent)

% function str = showdoc(item, indent)
% Display help text for a cfg item and all of its options.
%
% This function is identical for all cfg_intree classes.
%
% This code is part of a batch job configuration system for MATLAB. See 
%      help matlabbatch
% for a general overview.
%_______________________________________________________________________
% Copyright (C) 2007 Freiburg Brain Imaging

% Volkmar Glauche
% $Id: showdoc.m 380 2016-11-08 07:47:23Z tmoser $

rev = '$Rev: 380 $'; %#ok

str = showmydoc(item, indent);
str{end+1} = '';
% Display detailed help for each default item
citems = subsref(item, substruct('.', treepart(item, true)));
for k = 1:numel(citems)
    str1 = showdoc(citems{k}, sprintf('%s%d.', indent, k));
    str = [str(:); str1(:); {''}]';
end

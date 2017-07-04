function outfile = hgsave_pre2008a(figname,doreplace)
% HGSAVE_PRE2008A
% Starting with MATLAB 2008a, GUIDE saves figures with '%automatic'
% functions (e.g. Callbacks, ResizeFcn ...) as anonymous function handles,
% where previous versions used strings instead. The problem is that MATLAB
% R14SP3 crashes on loading these anonymous function handles.
%
% The problem can be resolved in 2 ways: 
% a) replacing anonymous function handles with string callbacks or
% b) generating code with anonymous function handles which must be run in
% MATLAB R14SP3 to save a valid .fig or .mat file.
%
% function outfile = hgsave_pre2008a(figname,doreplace)
% Input arguments:
%  figname   - string containing full path and file of .fig/.mat file to
%              repair
%  doreplace - how to treat function handles
%              true  - try to replace function handles with strings. Useful
%                      if one needs to be compatible, but has no R14SP3 at
%                      hand.
%              false - create .m file that must be run in MATLAB R14SP3 to
%                      save a compatible .mat file.
% Output argument:
%  outfile - file name of output file. Depending on doreplace, this is
%            either a .fig/.mat file, or a .m file.
% 
% Details of the correction procedure:
% 1) load a MATLAB 2008a .fig or .mat file as variable
% 2) generate code for it using GENCODE
% if doreplace
%   3) look for the characteristic regexp 
%      @\(hObject,eventdata\)figname\(([^,]*).*
%   4) if found, replace it with string
%      figname($1,gcbo,[],guidata(gcbo))
%   if success
%     5) re-evaluate the code
%     6) save the new variable
%   else
%     generate semi-correct code
%   end
% else
%   generate code without replacements
% end
%
% If there are other anonymous function handles left, the tool will create
% an m-file with instructions which function handles may need to be
% corrected. After editing, this m-file can be run to save the corrected
% figure.
%
% See also GENCODE, GENCODE_RVALUE, GENCODE_SUBSTRUCT, GENCODE_SUBSTRUCTCODE.
%
% This code has been developed as part of a batch job configuration
% system for MATLAB. See  
%      http://sourceforge.net/projects/matlabbatch
% for details about the original project.
%_______________________________________________________________________
% Copyright (C) 2007 Freiburg Brain Imaging

% Volkmar Glauche
% $Id: hgsave_pre2008a.m 380 2016-11-08 07:47:23Z tmoser $

rev = '$Rev: 380 $'; %#ok
 
hvar = load(figname,'-mat');
hstr = gencode(hvar);
[p, fign, e] = fileparts(figname);
% save new figure under <figname>_R14SP3
nfigname = fullfile(p, sprintf('%s_R14SP3%s%s', fign, e));
% This regexp filters out automatically created/convertible code
if doreplace
    re  = sprintf('^([^=]*)= @\\(hObject,eventdata\\)%s\\(([^,]*),hObject,eventdata,guidata\\(hObject\\)\\)',fign);
    hstr1 = regexprep(hstr,re,sprintf('$1= ''%s(''$2'',gcbo,[],guidata(gcbo))''',fign));
else
    hstr1 = hstr;
end
% check, whether there may be other anonymous callbacks left
anon = ~cellfun(@isempty,regexp(hstr1,'^[^=]*= @\('));
if ~doreplace || any(anon)
    scriptname = fullfile(p, sprintf('%s_R14SP3.m', fign));
    if doreplace && any(anon)
        warning('hgsave_pre2008a:anon', ...
            ['There may be anonymous function handles left. ',...
            'An m-file\n ''%s''\n will be created. Please check this file, adjust the offending lines and run it once.'], ...
            scriptname);
    end
    [fid, msg] = fopen(scriptname, 'wt');
    if fid == -1
        cfg_message('matlabbatch:fopen', 'Failed to open ''%s'' for writing:\n%s', scriptname, msg);
    end
    % preamble, usage instructions
    fprintf(fid, '%% m-file generated by %s using GENCODE\n', upper(mfilename));
    fprintf(fid, '%% This file contains code to generate figure/variable ''%s_R14SP3''.\n', fign);
    fprintf(fid, ['%% To create a compatible .fig/.mat file, either run this file in MATLAB\n', ...
        '%% R14SP3 or fix the following lines, which may contain anonymous function handles\n', ...
        '%% that will make MATLAB R14SP3 crash on load:\n']);
    anind = find(anon);
    anfmt = floor(log10(numel(anind)))+1;
    for k = 1:numel(anind)
        fprintf(fid, '%% %0*d: %s\n', anfmt, anind(k)+7+numel(anind), hstr1{anind(k)});
    end
    fprintf(fid, '%% Please check these lines, and correct if necessary.\n');
    fprintf(fid, '%% Once you are finished, run this generated m-file to save the figure.\n');
    % save generated code
    fprintf(fid, '%s\n', hstr1{:});
    % code to save the variable
    fprintf(fid, ['try\n',...
        'save(''%s'', ''-v7'', ''-struct'',''hvar'');\n',...
        'catch\n',...
        'save(''%s'', ''-struct'',''hvar'');\n',...
        'end\n'], nfigname, nfigname);
    outfile = scriptname;
else
    % generated code will overwrite hvar
    eval(sprintf('%s\n',hstr1{:}));
    save(nfigname,'-v7','-struct','hvar');
    outfile = nfigname;
end
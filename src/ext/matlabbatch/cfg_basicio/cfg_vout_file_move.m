function dep = cfg_vout_file_move(job)

% Define virtual output for cfg_run_move_file. Output can be passed on to
% either a cfg_files or an evaluated cfg_entry.
%
% This code is part of a batch job configuration system for MATLAB. See 
%      help matlabbatch
% for a general overview.
%_______________________________________________________________________
% Copyright (C) 2007 Freiburg Brain Imaging

% Volkmar Glauche
% $Id: cfg_vout_file_move.m 380 2016-11-08 07:47:23Z tmoser $

rev = '$Rev: 380 $'; %#ok

if ~isfield(job.action,'delete')
    dep = cfg_dep;
    dep.sname = 'Moved/Copied Files';
    dep.src_output = substruct('.','files');
    dep.tgt_spec   = cfg_findspec({{'class','cfg_files','strtype','e'}});
else
    dep = [];
end
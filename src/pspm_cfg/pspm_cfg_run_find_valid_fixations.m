function [out] = pspm_cfg_run_find_valid_fixations(job)
% updated on 19-12-2023 by Teddy
%% Initialise
options = struct();
%% fn
fn = job.datafile{1};
%% bitmap
if isfield(job.val_method,'bitmap_file')
  % bitmap
  try
    indata = load(job.val_method.bitmap_file{1});
  catch
    errmsg = 'Not a matlab data file (i.e no .mat file).';
    warning('ID:invalid_input', errmsg); return;
  end
  if ~isfield(indata,'bitmap')
    warning('ID:invalid_input', ...
      'Indicated file ''%s'' does not contain a matrix called ''bitmap.''',...
      job.val_method.bitmap_file{1});
    return;
  end
  bitmap = indata.bitmap;
else
  % ValidSet
  circle_degree = job.val_method.validation_settings.circle_degree;
  distance = job.val_method.validation_settings.distance;
  unit = job.val_method.validation_settings.unit;
  options = pspm_update_struct(options, job.val_method.validation_settings, 'resolution');
  if isfield(job.val_method.validation_settings.fixation_point, 'fixpoint')
    options.fixation_point = job.val_method.validation_settings.fixation_point.fixpoint;
  elseif isfield(job.val_method.validation_settings.fixation_point, 'fixpoint_file')
    options.fixation_point = job.val_method.validation_settings.fixation_point.fixpoint_file{1};
  end
end

%% options
options.channel = pspm_cfg_selector_channel('run', job.chan); 
options.channel_action = job.channel_action;
options = pspm_update_struct(options, job.output_settings, {'add_invalid', ...
                                                            'plot_gaze_coords'});
%% run
if isfield(job.val_method,'bitmap_file')
  [~, out] = pspm_find_valid_fixations(fn, bitmap, options);
else
  [~, out] = pspm_find_valid_fixations(fn, circle_degree, ...
    distance, unit, options);
end

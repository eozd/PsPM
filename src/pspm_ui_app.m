function app = pspm_ui_app (app)
% ● Description
%   pspm_ui_app handles the ui controlling elements for app designer based GUI files.
%   Details of font styles can be found in the developer's guide.
% ● History
%   Written and updated in 2022 and 2024 by Teddy

%% General Settings
OS = ispc*1 + ismac*2 + (isunix-ismac)*3;
pspm_font_list = {'Segoe UI', '.AppleSystemUIFont', 'DejaVu Sans'};
pspm_font_size_list = {14, 14, 14};
pspm_font = pspm_font_list{OS};
pspm_font_size = pspm_font_size_list{OS};
pspm_colour = [0.54,0.10,0.20];
pspm_layout_component_list_full = {...
  'title_help',... %'title_quit',...
  'button_data_editor',...
  'button_data_display',...
  'button_ecg_editor',...
  'button_logo',...
  'text_attribution',...
  'button_discussion_forum',...
  'button_reference_manual',...
  'title_data_display',...
  'button_batch',...
  'title_data_processing',...
  'button_model_review',...
  'button_quit'...
  };
pspm_layout_component_list_buttons = {...
  'button_data_editor',...
  'button_data_display',...
  'button_ecg_editor',...
  'button_discussion_forum',...
  'button_reference_manual',...
  'button_batch',...
  'button_model_review',...
  'button_quit'...
  };
pspm_layout_component_list_panels = {...
  'panel_data_processing', ...
  'panel_data_display', ...
  'panel_quit', ...
  'panel_help' ...
  'button_logo' ...
  };
update_app_struct(app, pspm_layout_component_list_full, 'FontName', pspm_font);
update_app_struct(app, pspm_layout_component_list_buttons, 'BackgroundColor', [0.9608 0.9608 0.9608]);
update_app_struct(app, pspm_layout_component_list_buttons, 'FontColor', [0.1294 0.1294 0.1294]);
update_app_struct(app, pspm_layout_component_list_full, 'FontName', pspm_font);
update_app_struct(app, pspm_layout_component_list_buttons, 'FontSize', pspm_font_size);
update_app_struct(app, pspm_layout_component_list_buttons, 'FontWeight', 'normal');
% update colour
if isprop(app.GridLayout, 'BackgroundColor')
  app.GridLayout.BackgroundColor = pspm_colour;
end
update_app_struct(app, pspm_layout_component_list_panels, 'BorderColor', [1 1 1]);
%% Window specific settings
switch app.layout.Name
  case 'pspm'
    attribution_disp_text = ['Build 12-02-2025 with MATLAB 2024a, ',...
      'The PsPM Team'];
    app.text_attribution.Text{1,1} = 'Version 7.0';
    app.text_attribution.Text{2,1} = attribution_disp_text;
end
return

function update_app_struct(app, components, field_name, value)
for i_comp = 1:length(components)
  try
    app = setfield(app, components{i_comp}, field_name, value);
  catch
  end
end

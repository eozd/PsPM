function [sts, fig] = pspm_rev_glm(modelfile, plotNr)
% ● Description
%   pspm_rev_glm is a tool for reviewing a first level GLM designs. It is
%   meant to be called by pspm_review only.
% ● Format
%   [sts, fig] = pspm_rev_glm(modelfile, plotNr)
% ● Arguments
%   * modelfile : filename and path of modelfile
%   *    plotNr : defines which figure shall be plotted
%                 (several plots can be defined by a vector)
%                 1 - design matrix, SPM style
%                 2 - design orthogonality, SPM style
%                 3 - predicted & observed
%                 4 - print regressor names
%                 5 - reconstructed responses
%                 6 - plot mean responses of all segments 
% ● Outputs
%   *       sts : status variable indicating whether the function run successfully
%   *       fig : returns the figure handles
% ● History
%   Introduced In PsPM 3.0
%   Written in 2008-2015 by Dominik R Bach (Wellcome Trust Centre for Neuroimaging)
%   Maintained in 2022 by Teddy
%   Maintained in 2024 by Bernhard Agoué von Raußendorf

% initialise
global settings
if isempty(settings)
  pspm_init;
end
sts = -1;
fig = struct();

% check input
% ------------------------------------------------------------------------
if nargin < 2, return; end

[sts_glm_recon, glm] = pspm_glm_recon(modelfile);
if sts_glm_recon == -1, return; end

% prepare
% ------------------------------------------------------------------------

tmp.X = NaN(size(glm.X));
for c=1:size(glm.X,2)
  tmp.X(glm.M==0,c)=glm.XM(:,c)/std(glm.XM(:));
end

[~, filename, ~]=fileparts(modelfile);
filename=[filename, '.mat'];
XTick=1:1:size(glm.X,2);
YTickStep=glm.infos.sr*round(size(glm.X,1)/20/glm.infos.sr);
YTick=YTickStep:YTickStep:size(glm.X,1);
YTickLabel=round(YTick/glm.infos.sr);

pos0 = get(0,'screenSize');

for i=1:length(plotNr)
  if plotNr(i) <= 5 || plotNr(i) >= 1
    switch plotNr(i)
      case 1
        % --- plot design matrix in SPM style
        pos = [0.51*pos0(3),0.1*pos0(4),0.45*pos0(3),0.8*pos0(4)];
        fig(1).h = figure('Position', pos, ...
          'PaperPositionMode', 'auto', ...
          'PaperOrientation', 'Portrait', ...
          'InvertHardCopy', 'off', ...
          'Color', 'w', ...
          'Name', 'Design Matrix');%,'NumberTitle','off');
        colormap('gray');
        fig(1).ax(1).h=axes('Position', [0.1 0.05 0.85 0.9]);
        tmp.Xdisplay = tmp.X;
        tmp.Xdisplay(isnan(tmp.Xdisplay))=0;
        tmp.Xdisplay=tmp.Xdisplay-repmat(min(tmp.Xdisplay),size(tmp.Xdisplay,1),1);
        tmp.Xdisplay=tmp.Xdisplay./max(tmp.Xdisplay);
        fig(1).p(1)=imagesc(tmp.Xdisplay);
        set(fig(1).ax(1).h, ...
          'XTick', XTick, 'TickDir', 'out', 'YTick',YTick, 'YTickLabel', YTickLabel, 'FontWeight', 'Bold', 'FontSize', 10,  'TickLength', [0.005 0.025]);
        fig(1).ylabel=get(fig(1).ax(1).h, 'YLabel');
        fig(1).title=get(fig(1).ax(1).h, 'Title');
        set(fig(1).ylabel, 'String', 'Time (s)', 'FontWeight', 'Bold', 'FontSize', 14);
        set(fig(1).title, 'String', sprintf('Design Matrix: %s', filename), 'FontWeight', 'Bold', 'FontSize', 14, 'Interpreter', 'none');

      case 2
        % --- plot orthogonality in SPM style
        pos = [0.21*pos0(3),0.1*pos0(4),0.5*pos0(3),0.7*pos0(4)];
        % prepare
        cormat=abs(corrcoef(glm.XM));
        cormat(isnan(cormat))=0;
        cormat=1-cormat;
        % plot
        fig(2).h = figure('Position', pos,'PaperPositionMode', 'auto', 'PaperOrientation', 'Portrait', 'InvertHardCopy', 'off', 'Color', 'w', 'Name', 'Design Orthogonality');%,'NumberTitle','off');
        colormap('gray');
        fig(2).ax(1).h=axes('Position', [0.1 0.05 0.85 0.85]);
        fig(2).p(1)=imagesc(cormat);
        set(fig(2).ax(1).h, 'XTick', XTick, 'TickDir', 'out', 'YTick',XTick, 'FontWeight', 'Bold', 'FontSize', 10,  'TickLength', [0.005 0.025]);
        fig(2).title=get(fig(2).ax(1).h, 'Title');
        set(fig(2).title, 'String', sprintf('Design Orthogonality: %s', filename), 'FontWeight', 'Bold', 'FontSize', 14, 'Interpreter', 'none');

        % display regressornames
        % calculate width of a square
        ns = size(cormat,1);
        pat = '^Constant';
        idx_const = cell2mat(cellfun(@(x)~isempty(regexpi(x,pat)),glm.names,'UniformOutput',0));
        idx_const = find(idx_const);
        nr_const = numel(idx_const);
        legend_names = glm.names(1:ns-nr_const);
        legend_names(end+1:end+nr_const) = glm.names(end-(nr_const-1):end);

        YLim = get(fig(2).ax(1).h, 'YLim');
        sy = diff(YLim) / ns;
        XLim = get(fig(2).ax(1).h, 'XLim');
        sx = diff(XLim) / ns;

        % iterate through regressors and colors
        corder = get(fig(2).h, 'defaultAxesColorOrder');
        cl = length(corder);
        for j=1:ns
          if j > cl
            m = floor((j-0.1)/cl);
            color = corder(j - m*cl, :);
          else
            color = corder(j,:);
          end

          % draw lines
          space = -0.7;
          x = [space, sx*j];
          x = XLim(1) + x;
          y = [(j)*sy, (j)*sy];
          y = YLim(1) + y;

          fig(2).ax(1).p(j+1) = patch(x,y, color);
          set(fig(2).ax(1).p(j+1), 'EdgeColor', color, ...
            'FaceColor', 'none', ...
            'Clipping', 'off', ...
            'LineWidth', 1.5);

          % draw text
          fig(2).ax(1).t(j) = text(0.2, j*sy+0.4, legend_names(j));
          set(fig(2).ax(1).t(j), ...
            'Color', color, ...
            'FontSize', 7.5, ...
            'Clipping', 'off');
        end


      case 3
        % --- plot predicted & observed
        pos = [0.2*pos0(3),0.1*pos0(4),0.7*pos0(3),0.7*pos0(4)];
        % prepare
        predicted=glm.Yhat; observed=glm.Y; res=glm.e; timing=glm.timing;
        fig(3).h = figure('Position', pos,'PaperPositionMode', 'auto', 'PaperOrientation', 'Portrait', 'InvertHardCopy', 'off', 'Color', 'w', 'Name', 'Model fit');%,'NumberTitle','off');
        fig(3).ax(1).h=axes('Position', [0.05 0.1 0.9 0.8]);
        hold on;
        fig(3).ax(1).p(1)=plot(observed, 'k-');
        fig(3).ax(1).p(2)=plot(predicted, 'r-');
        fig(3).ax(1).p(3)=plot(res, 'k:');
        legend_text = {'Observed', 'Predicted', 'Residual'};
        set(fig(3).ax(1).h, 'XTick', YTick, 'XTickLabel', YTickLabel, 'TickDir', 'out', 'YTick',[],  'FontWeight', 'Bold', 'FontSize', 10,  'TickLength', [0.005 0.025], 'XLim', [0 size(glm.Y,1)]);
        YLim = get(fig(3).ax(1).h, 'YLim');
        corder = get(fig(3).h, 'defaultAxesColorOrder');
        cl = length(corder);
        k = 1;
        for j=1:length(timing.onsets)
          if j > cl
            m = floor((j-0.1)/cl);
            color = corder(j - m*cl, :);
          else
            color = corder(j,:);
          end
          fig(3).ax(1).p(k+3)=stem(timing.onsets{j}, zeros(numel(timing.onsets{j}),1) + YLim(2));
          set(fig(3).ax(1).p(k+3), 'BaseValue', YLim(1), 'Color', color);
          legend_text(end+1) = timing.names(j);
          if sum(timing.durations{j}) > 0
            % plot area with patch
            y_pos_base = [YLim(1); YLim(1); YLim(2); YLim(2)];
            y_pos = repmat(y_pos_base, 1,length(timing.onsets{j}));
            offsets = timing.onsets{j}' + timing.durations{j}';
            x_pos = [timing.onsets{j}'; offsets; offsets; timing.onsets{j}'];
            k = k + 1;
            fig(3).ax(1).p(k+3) = patch(x_pos, y_pos, color, ...
              'EdgeColor', 'none', 'FaceAlpha', 0.1);
            % do not show in legend
            annotation = get(fig(3).ax(1).p(k+3), 'Annotation');
            legend_info = get(annotation, 'LegendInformation');
            set(legend_info, 'IconDisplayStyle', 'off');
          end
          k = k + 1;
        end
        fig(3).xlabel=get(fig(3).ax(1).h, 'XLabel');
        fig(3).title=get(fig(3).ax(1).h, 'Title');
        fig(3).leg=legend(legend_text, 'Location', 'Best', 'FontSize', 14);
        set(fig(3).xlabel, 'String', 'Time (s)', 'FontWeight', 'Bold', 'FontSize', 14);
        set(fig(3).title, 'String', sprintf('Model fit: %s', filename), 'FontWeight', 'Bold', 'FontSize', 14, 'Interpreter', 'none');
        set(gca, 'LineWidth', 1.2);
        hold off;
      case 4
        % have to prepare the names such that SEBR works correct
        cormat=abs(corrcoef(glm.XM));
        ns = size(cormat,1);
        pat = '^Constant';
        idx_const = cell2mat(cellfun(@(x)~isempty(regexpi(x,pat)),glm.names,'UniformOutput',0));
        idx_const = find(idx_const);
        nr_const = numel(idx_const);
        legend_names = glm.names(1:ns-nr_const);
        legend_names(end+1:end+nr_const) = glm.names(end-(nr_const-1):end);

        fprintf('Regressors for %s:\n---------------------------------------\n', glm.glmfile);
        for n=1:numel(legend_names)
          fprintf('Regressor %d: %s\n',n,legend_names{n});
        end
        fprintf('---------------------------------------\n');
        fig(4).h = [];

      case 5
        % --- do plot of reconstructed responses
        pos = [0.21*pos0(3),0.1*pos0(4),0.5*pos0(3),0.7*pos0(4)];
        fig(5).h = figure('Position', pos,'PaperPositionMode', 'auto', 'PaperOrientation', 'Portrait', 'InvertHardCopy', 'off', 'Color', 'w', 'Name', 'Estimated responses');%,'NumberTitle','off');
        fig(5).ax(1).h=axes('Position', [0.05 0.1 0.9 0.8]);
        fig(5).p = plot(glm.resp);
        legend(glm.reconnames); legend boxoff;
        fig(5).title=get(fig(5).ax(1).h, 'Title');
        set(fig(5).ax(1).h, 'TickDir', 'out', 'YTick',[],  'FontWeight', 'Bold', 'FontSize', 10,  'TickLength', [0.005 0.025]);
        xlim = get(fig(5).ax(1).h, 'XTick');
        xlim = xlim ./ glm.infos.sr;
        XLim = num2cell(xlim);
        XLim = cellfun(@(x){num2str(x)}, XLim);
        set(fig(5).ax(1).h, 'XTickLabel',XLim);
        set(fig(5).title, 'String', sprintf('Estimated responses per condition: %s', filename), 'FontWeight', 'Bold', 'FontSize', 14, 'Interpreter', 'none');
      case 6

        options = struct('plot', 1);
        [ssts, segments] = pspm_extract_segments('model', glm, options);
     end
  end
end
sts = 1;
return

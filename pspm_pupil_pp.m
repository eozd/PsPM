function [sts, out_channel] = pspm_pupil_pp(fn, options)
    % pspm_pupil_pp preprocesses pupil diameter signals given in any unit of
    % measurement. It performs the steps described in [1]. This function
    % uses a modified version of [2]. The modified version with a list of
    % changes from the original is shipped with PsPM under pupil-size directory.
    %  
    % Once the pupil data is preprocessed, according to the option 'channel_action',
    % it will either replace an existing preprocessed pupil channel or add it as new
    % channel to the provided file.
    %
    %   FORMAT:  [sts, out_channel] = pspm_pupil_pp(fn)
    %            [sts, out_channel] = pspm_pupil_pp(fn, options)
    %
    %       fn:                      [string] Path to the PsPM file which contains 
    %                                the pupil data.
    %       options:
    %           Optional:
    %               channel:         [numeric/string] Channel ID to be preprocessed.
    %                                (Default: 'pupil')
    %
    %                                Preprocessing raw eye data:
    %                                The best eye is processed when channel is 'pupil'.
    %                                In order to process a specific eye, use 'pupil_l' or
    %                                'pupil_r'. 
    %
    %                                Preprocessing previously processed data:
    %                                Pupil channels created from other preprocessing steps
    %                                can be further processed by this function. To enable
    %                                this, pass one of 'pupil_l_pp' or 'pupil_r_pp'.
    %                                There is no best eye selection in this mode.
    %                                Hence, the type of the channel must be given exactly.
    %
    %                                Finally, a channel can be specified by its
    %                                index in the given PsPM data structure. It will be
    %                                preprocessed as long as it is a valid pupil channel.
    %
    %                                If channel is specified as a string and there are
    %                                multiple channels with the exact same type, only the
    %                                last one will be processed. This is normally not the
    %                                case with raw data channels; however, there may be
    %                                multiple preprocessed channels with same type if 'add'
    %                                channel_action was previously used. This feature can
    %                                be combined with 'add' channel_action to create
    %                                preprocessing histories where the result of each step
    %                                is stored as a separate channel. 
    %
    %                                .data field of the preprocessed channel contains
    %                                the smoothed, upsampled signal that is the result
    %                                of step 3 in [1].
    %
    %                                .header field of the preprocessed channel contains
    %                                information regarding which samples in the input
    %                                signal were considered valid in addition to the
    %                                usual information of PsPM channels. This valid sample
    %                                info is stored in .header.valid_samples field.
    %
    %               channel_combine: [numeric/string] Channel ID to be used for computing
    %                                the mean pupil signal.
    %                                (Default: 'none')
    %
    %                                The input format is exactly the same as the .channel
    %                                field. However, the eye specified in this channel
    %                                must be different than the one specified in .channel
    %                                field.
    %
    %                                By default, this channel is not used. Only specify
    %                                it if you want to combine left and right pupil eye
    %                                signals. When specified, the type of the output channel
    %                                is 'pupil_lr_pp'.
    %
    %               channel_action:  ['add'/'replace'] Defines whether corrected data
    %                                should be added or the corresponding preprocessed
    %                                channel should be replaced. Note that 'replace' mode
    %                                does not replace the raw data channel, but a previously
    %                                stored preprocessed channel with a '_pp' suffix at the
    %                                end of its type.
    %                                (Default: 'replace')
    %
    %               custom_settings: Settings structure to modify the preprocessing
    %                                steps. Default settings structure can be obtained
    %                                by calling pspm_pupil_pp_options function.
    %                                (Default: See <a href="matlab:help pspm_pupil_pp_options">pspm_pupil_pp_options</a>)
    %
    %               segments:        Statistics about user defined segments can be
    %                                calculated.  When specified, segments will be
    %                                stored in .header.segments field.
    %
    %                                segments must be a cell array of structures.
    %                                Each structure must have the the following
    %                                fields:
    %
    %                   start:       Starting time of the segment
    %                                (Unit: second)
    %
    %                   end:         Ending time of the segment
    %                                (Unit: second)
    %
    %                   name:        Name of the segment. Segment will be stored by this
    %                                name.
    %
    %               plot_data:       Plot the preprocessing steps if true.
    %                                (Default: false)
    %
    %       out_channel:             Channel ID of the preprocessed output.
    %
    % [1] Kret, Mariska E., and Elio E. Sjak-Shie. "Preprocessing pupil size data:
    %     Guidelines and code." Behavior research methods (2018): 1-7.
    % [2] https://github.com/ElioS-S/pupil-size
    %__________________________________________________________________________
    % (C) 2019 Eshref Yozdemir (University of Zurich)

    % initialise
    % -------------------------------------------------------------------------
    global settings;
    if isempty(settings), pspm_init; end
    sts = -1;

    % create default arguments
    % --------------------------------------------------------------
    if nargin == 1
        options = struct();
    end
    if ~isfield(options, 'channel')
        options.channel = 'pupil';
    end
    if ~isfield(options, 'channel_action')
        options.channel_action = 'replace';
    end
    if ~isfield(options, 'channel_combine')
        options.channel_combine = 'none';
    end
    if ~isfield(options, 'plot_data')
        options.plot_data = false;
    end
    if ~isfield(options, 'custom_settings')
        [lsts, options.custom_settings] = pspm_pupil_pp_options();
        if lsts ~= 1; return; end;
    end
    if ~isfield(options, 'segments')
        options.segments = {};
    end

    % input checks
    % -------------------------------------------------------------------------
    if ~ismember(options.channel_action, {'add', 'replace'})
        warning('ID:invalid_input', 'Option channel_action must be either ''add'' or ''replace''');
        return;
    end
    for seg = options.segments
        if ~isfield(seg{1}, 'start') || ~isfield(seg{1}, 'end') || ~isfield(seg{1}, 'name')
            warning('ID:invalid_input', 'Each segment structure must have .start, .end and .name fields');
            return;
        end
    end

    % load
    % -------------------------------------------------------------------------
    is_combined = ~strcmp(options.channel_combine, 'none');

    addpath(pspm_path('backroom'));
    [lsts, data] = pspm_load_single_chan(fn, options.channel, 'last', 'pupil');
    if lsts ~= 1; return; end;
    if is_combined
        [lsts, data_combine] = pspm_load_singe_chan(fn, options.channel_combine, 'last', 'pupil');
        if lsts ~= 1; return; end;
        if strcmp(get_eye(data{1}.header.chantype), get_eye(data_combine{1}.header.chantype))
            warning('ID:invalid_input', 'options.channel and options.channel_combine must specify different eyes');
            return;
        end
        if data{1}.header.sr ~= data_combine{1}.header.sr
            warning('ID:invalid_input', 'options.channel and options.channel_combine data have different sampling rate');
            return;
        end
        if ~strcmp(data{1}.header.units, data_combine{1}.header.units)
            warning('ID:invalid_input', 'options.channel and options.channel_combine data have different units');
            return;
        end
        if numel(data{1}.data) ~= numel(data_combine{1}.data)
            warning('ID:invalid_input', 'options.channel and options.channel_combine data have different lengths');
            return;
        end
    else
        data_combine{1}.data = [];
    end
    rmpath(pspm_path('backroom'));

    % preprocess
    % -------------------------------------------------------------------------
    [lsts, smooth_signal] = preprocess(data, data_combine, options.segments, options.custom_settings, options.plot_data);
    if lsts ~= 1; return; end;

    % save
    % -------------------------------------------------------------------------
    [lsts, out_id] = pspm_write_channel(fn, smooth_signal, options.channel_action);
    if lsts ~= 1; return; end;

    out_channel = out_id.channel;
    sts = 1;
end

function [sts, smooth_signal] = preprocess(data, data_combine, segments, custom_settings, plot_data)
    sts = 0;

    % definitions
    % -------------------------------------------------------------------------
    combining = ~isempty(data_combine{1}.data);
    data_is_left = strcmpi(get_eye(data{1}.header.chantype), 'l');
    n_samples = numel(data{1}.data);
    sr = data{1}.header.sr;
    diameter.t_ms = linspace(0, 1000 * n_samples / sr, n_samples)';

    if data_is_left
        diameter.L = data{1}.data;
        diameter.R = data_combine{1}.data;
    else
        diameter.L = data_combine{1}.data;
        diameter.R = data{1}.data;
    end
    if size(diameter.L, 1) == 1
        diameter.L = diameter.L';
    end
    if size(diameter.R, 1) == 1
        diameter.R = diameter.R';
    end
    segmentStart = cell2mat(cellfun(@(x) x.start, segments, 'uni', false))';
    segmentEnd = cell2mat(cellfun(@(x) x.end, segments, 'uni', false))';
    segmentName = cellfun(@(x) x.name, segments, 'uni', false)';
    segmentTable = table(segmentStart, segmentEnd, segmentName);
    new_sr = custom_settings.valid.interp_upsamplingFreq;
    upsampling_factor = new_sr / sr;
    desired_output_samples = int32(upsampling_factor * numel(data{1}.data));

    % load lib
    % -------------------------------------------------------------------------
    libbase_path = pspm_path('pupil-size', 'code');
    libpath = {fullfile(libbase_path, 'dataModels'), fullfile(libbase_path, 'helperFunctions')};
    addpath(libpath{:});

    % filtering
    % -------------------------------------------------------------------------
    model = PupilDataModel(data{1}.header.units, diameter, segmentTable, 0, custom_settings);
    model.filterRawData();
    if combining
        smooth_signal.header.chantype = 'pupil_lr_pp';
    elseif endsWith(data{1}.header.chantype, '_pp')
        smooth_signal.header.chantype = data{1}.header.chantype; 
    else
        smooth_signal.header.chantype = [data{1}.header.chantype '_pp'];
    end
    smooth_signal.header.units = data{1}.header.units;
    smooth_signal.header.sr = new_sr;
    smooth_signal.header.segments = segments;

    try
        % store signal and valid samples
        % ------------------------------
        model.processValidSamples();
        if combining
            validsamples_obj = model.meanPupil_ValidSamples;

            smooth_signal.header.valid_samples.data_l = model.leftPupil_ValidSamples.samples.pupilDiameter;
            smooth_signal.header.valid_samples.sample_indices_l = model.leftPupil_RawData.isValid;
            smooth_signal.header.valid_samples.valid_percentage_l = model.leftPupil_ValidSamples.validFraction;
            smooth_signal.header.valid_samples.data_r = model.rightPupil_ValidSamples.samples.pupilDiameter;
            smooth_signal.header.valid_samples.sample_indices_r = model.rightPupil_RawData.isValid;
            smooth_signal.header.valid_samples.valid_percentage_r = model.rightPupil_ValidSamples.validFraction;
        else
            if data_is_left
                validsamples_obj = model.leftPupil_ValidSamples;
                rawdata_obj = model.leftPupil_RawData;
            else
                validsamples_obj = model.rightPupil_ValidSamples;
                rawdata_obj = model.rightPupil_RawData;
            end

            smooth_signal.header.valid_samples.data = validsamples_obj.samples.pupilDiameter;
            smooth_signal.header.valid_samples.sample_indices = find(rawdata_obj.isValid);
            smooth_signal.header.valid_samples.valid_percentage = validsamples_obj.validFraction;
        end

        smooth_signal.data = validsamples_obj.signal.pupilDiameter;
        smooth_signal.data = complete_with_nans(smooth_signal.data, validsamples_obj.signal.t(1), ...
            new_sr, desired_output_samples);

        % store segment information
        % -------------------------
        if ~isempty(segments)
            seg_results = model.analyzeSegments();
            seg_results = seg_results{1};
            if combining
                seg_eyes = {'left', 'right', 'mean'};
            elseif data_is_left
                seg_eyes = {'left'};
            else
                seg_eyes = {'right'};
            end
            smooth_signal.header.segments = store_segment_stats(smooth_signal.header.segments, seg_results, seg_eyes);
        end

        if plot_data
            model.plotData();
        end
    catch err
        % https://www.mathworks.com/matlabcentral/answers/225796-rethrow-a-whole-error-as-warning
        warning('ID:invalid_data_structure', getReport(err, 'extended', 'hyperlinks', 'on'));
        smooth_signal.data = NaN(desired_output_samples, 1);
        sts = -1;
    end

    rmpath(libpath{:});
    if sts == 0
        sts = 1;
    end
end

function eyestr = get_eye(pupil_chantype)
    indices = strfind(pupil_chantype, '_');
    if numel(indices) == 1
        begidx = indices(1) + 1;
        endidx = numel(pupil_chantype);
    else
        begidx = indices(1) + 1;
        endidx = indices(2) - 1;
    end
    eyestr = pupil_chantype(begidx : endidx);
end

function segments = store_segment_stats(segments, seg_results, seg_eyes)
    stat_columns = {...
        'Pupil_SmoothSig_meanDiam', ...
        'Pupil_SmoothSig_minDiam', ...
        'Pupil_SmoothSig_maxDiam', ...
        'Pupil_SmoothSig_missingDataPercent', ...
        'Pupil_SmoothSig_sampleCount', ...
        'Pupil_ValidSamples_meanDiam', ...
        'Pupil_ValidSamples_minDiam', ...
        'Pupil_ValidSamples_maxDiam', ...
        'Pupil_ValidSamples_validPercent', ...
        'Pupil_ValidSamples_sampleCount', ...
    };
    for eyestr = seg_eyes
        for colstr = stat_columns
            eyecolstr = [eyestr{1} colstr{1}];
            col = seg_results.(eyecolstr);
            for i = 1:numel(segments)
                segments{i}.(eyecolstr) = col(i);
            end
        end
    end
end

function data = complete_with_nans(data, t_beg, sr, output_samples)
    % Complete the given data that possibly has missing samples at the
    % beginning and at the end. The amount of missing samples is determined
    % by sampling rate and the data beginning second t_beg.
    sec_between_upsampled_samples = 1 / sr;
    n_missing_at_the_beg = round(t_beg / sec_between_upsampled_samples);
    n_missing_at_the_end = output_samples - numel(data) - n_missing_at_the_beg;
    data = [NaN(n_missing_at_the_beg, 1) ; data ; NaN(n_missing_at_the_end, 1)];
end

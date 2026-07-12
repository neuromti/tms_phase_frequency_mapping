function [Y, epoch_status, error_status, EEG, EEG_continues, ME] = nin_cleaning_data_TESA(X, varargin)

%% This function performs TMS-EEG cleaning using the TESA pipeline
%
% - input:
% X: input structure containing raw eeg data
%
% - optional:
% eeg_device: name of device used for data recording
% stimuli: stimulation sample indices (default: [])
% TMS_features: pulse detection settings for TESA (default: 'refract', 4, 'rate', 1000, 'tmsLabel', 'TMS', 'plots', 'off')
% TMS_electrode: channel used for pulse detection (default: C3)
% badCh_flag: perform bad channel rejection (default: true)
% ch_rejection_feature: parameters for channel rejection (default: )
% epoch_len: epoch window in seconds (default: [-1 1])
% epoch_feature: parameters passed to epoching function (default: )
% bl_win: baseline correction window (ms) (default: [-900 -100])
% tms_win: TMS artifact removal window (ms) (default: [-2 10])
% interp_features: interpolation settings (default: {'cubic', [1 1]})
% epoch_rejection: epoch rejection parameters (default: {1, eegsys.ix_channels, 5, 5, 0, 0})
% ica_features: fastica parameters (default: )
% musle_artifacts_features: settings for tms muscle artifact rejection (default: )
% bp_settings: settings for bandpass filter lower freq/upper freq/order (default: [1, 100, 4])
% bs_settings: settings for bandstop/notch filter lower freq/upper freq/order (default: [48, 52, 4])
% other_artifacts_features: settings for non-tms artifact rejection (default: )
% disp_res: display intermediate processing results (default: false)
%
% - example:
% edata = nin_cleaning_data_TESA(cdata.eeg, [cemg.pulse_BV]);
% edata = nin_cleaning_data_TESA(cdata.eeg, [cemg.pulse_BV], 'id_event', [cemg.id_event]);

% -- read input parameters
nin_import_params(varargin);

%% -- set default parameters

% -- define eeg system
if ~exist('eeg_device', 'var')
    eeg_device = 'BrainVision';
end
eegsys = nin_eeg_system(eeg_device);

% -- define stimulation events
if ~exist('stimuli', 'var')
    stimuli = [];
end

% -- define bad epochs10 
if ~exist('bad_epoch', 'var')
    bad_epoch = [];
end

% -- define pulse detection settings
if ~exist('TMS_features', 'var')

    TMS_features = {'refract', 4,...
        'rate', 1000,...
        'tmsLabel', 'TMS',...
        'plots', 'off'};

end

% -- define pulse detection channel
if ~exist('TMS_electrode', 'var')

    TMS_electrode = 'C3';

end

% -- define channel rejection settings
if ~exist('ch_rejection_feature', 'var')
    ch_rejection_feature =  {'elec', eegsys.ix_channels,...
        'threshold', 5,...
        'norm', 'on',...
        'measure', 'kurt'};
end

% -- define epoch settings
if ~exist('epoch_len', 'var')
    epoch_len = [-1  1];
end

% -- epoched data settings
if ~exist('epoch_feature', 'var')
    epoch_feature = {'epochinfo', 'yes'};
end

% -- define baseline correction window
if ~exist('bl_win', 'var')
    bl_win = [-900 -100];
end

% -- define TMS artifact window
if ~exist('tms_win', 'var')
    tms_win = [-2 10];
end

% -- TMS window after musule rejection
if ~exist('tms_win_e', 'var')
    tms_win_e = [-2 15];
end

% -- define TMS interpolation settings
if ~exist('interp_features', 'var')
    interp_features = {'cubic', [1, 1]};
end

% -- define TMS interpolation settings after
if ~exist('interp_features_e', 'var')
    interp_features_e = {'cubic', [5, 5]};
end

% -- define epoch rejection settings
if ~exist('epoch_rejection', 'var')
    epoch_rejection = {1, eegsys.ix_channels, 5, 5, 0, 0};
end

% -- define ica settings
if ~exist('ica_features', 'var')
    ica_features = {'approach', 'symm',...
        'g', 'tanh',...
        'stabilization', 'off'};
end

% -- define tms muscle rejection settings
if ~exist('musle_artifacts_features', 'var')
    musle_artifacts_features = {'compCheck', 'off',...
        'comps', 15, ... % This arg doesn't exist in TESA 1.1.1
        'figSize', 'small',...
        'plotTimeX', [-200 500],...
        'plotFreqX', [1 100],...
        'tmsMuscle', 'on',...
        'tmsMuscleThresh', 8,...
        'tmsMuscleWin', [11 30],...
        'tmsMuscleFeedback', 'off',...
        'blink', 'off',...
        'blinkThresh', 2.5,...
        'blinkElecs', {'Fp1','Fp2'},...
        'blinkFeedback', 'off',...
        'move', 'off',...
        'moveThresh', 2,...
        'moveElecs', {'F7','F8'},...
        'moveFeedback', 'off',...
        'muscle', 'off',...
        'muscleThresh', 0.6,...
        'muscleFreqWin', [30 100],...
        'muscleFreqIn', [31,100],... % This was default in TESA 1.0.1, so lets keep that in in 1.1.1
        'muscleFeedback', 'off',...
        'elecNoise', 'off',...
        'elecNoiseThresh', 4,...
        'elecNoiseFeedback', 'off'};
end
 
% -- define filtering settings banspass
if ~exist('bp_settings', 'var')
    bp_settings = {1, 100, 4};
end

% -- define filtering settings bandstop
if ~exist('bs_settings', 'var')
    bs_settings = {48, 52, 4};
end

% -- define artifact rejection settings
if ~exist('other_artifacts_features', 'var')
    other_artifacts_features = {'compCheck', 'off',...
        'comps', [],... % This arg doesn't exist in TESA 1.1.1
        'figSize', 'small',...
        'plotTimeX', [-200 500],...
        'plotFreqX', [1 100],...
        'tmsMuscle', 'on',...
        'tmsMuscleThresh', 8,...
        'tmsMuscleWin', [11 30],...
        'tmsMuscleFeedback', 'off',...
        'blink', 'on',...
        'blinkThresh', 2.5,...
        'blinkElecs', {'Fp1','Fp2'},...
        'blinkFeedback', 'off',...
        'move', 'on',...
        'moveThresh', 2,...
        'moveElecs', {'F7','F8'},...
        'moveFeedback', 'off',...
        'muscle', 'on',...
        'muscleThresh', 0.6,...
        'muscleFreqWin', [30 100],...
        'muscleFreqIn', [31,100],... % This was default in TESA 1.0.1, so lets keep that in in 1.1.1
        'muscleFeedback', 'off',...
        'elecNoise', 'on',...
        'elecNoiseThresh', 4,...
        'elecNoiseFeedback', 'off'};
end

% -- define display settings
if ~exist('disp_res', 'var')
    disp_res = false;
end

%% -- transfer data in EEGLAB structure

EEG = eeg_emptyset;
EEG.nbchan = eegsys.nochannels;
EEG.trials = 1;
EEG.pnts = size(X.data, 2);
EEG.srate = X.strate;
EEG.xmin = 0;
EEG.xmax = (EEG.pnts-1)/EEG.srate;
EEG.times = 0:1/EEG.srate:(EEG.pnts-1)/EEG.srate;
EEG.data = X.data(eegsys.ix_channels, :);
EEG.chanlocs = eegsys.Channel_Location;
EEG.chaninfo = eegsys.Channel_Info;
EEG.specdata = [];
EEG.specicaact = [];
EEG.icachansind = [];
EEG.reject = [];
EEG.ref = 'common';

eeg_v = which('eeglab.m');
ix = strfind(eeg_v, 'eeglab');
eeg_v = eeg_v(ix(1):ix(1)+11);
EEG.etc.eeglabvers = eeg_v;

tesa_v = which('pop_tesa_compselect.m');
tesa_v = tesa_v(strfind(tesa_v, 'TESA'):strfind(tesa_v, 'TESA')+8);
EEG.etc.TESAvers = tesa_v;

EEG_continues = EEG;

try

    %% -- detect stimulation pulses

    if isempty(stimuli)

        % -- detect pulses automatically
        EEG = pop_tesa_findpulse(EEG, TMS_electrode, TMS_features{:});
        bad_epoch =  false(1, size(EEG.data, 3));

    else

        stimuli_name = repmat({'TMS'}, 1, length(stimuli))';
        stimuli_sample = num2cell(stimuli)';
        stimuli_no = num2cell(1:length(stimuli))';

        stimuli_table = cell2table([stimuli_name, stimuli_sample, stimuli_no], 'VariableNames', {'type', 'latency', 'urevent'});
        EEG.event = table2struct(stimuli_table);

        stimuli_table = cell2table([stimuli_name, stimuli_sample], 'VariableNames', {'type', 'latency'});
        EEG.urevent = table2struct(stimuli_table);

    end

    % -- store bad epoch information
    if isempty(bad_epoch)
        bad_epoch =  false(1, length(stimuli));
    end
    EEG.etc.bad_epoch.value = bad_epoch;
    EEG.etc.bad_epoch.index = 1:length(bad_epoch);

    %% -- reject bad channels

    % -- identify bad channels
    [EEG, idx_r, measure] = pop_rejchan(EEG, ch_rejection_feature{:});

    % -- store rejected channel information
    EEG.etc.bad_ch.ch_status = true(size(EEG_continues.data, 1), 1);
    EEG.etc.bad_ch.ch_removed = ~EEG.etc.bad_ch.ch_status;
    EEG.etc.bad_ch.ch_removed(idx_r) = true;
    EEG.etc.bad_ch.measure = measure;

    % -- update epoch rejection settings
    epoch_rejection{1, 2} = 1:size(EEG.data, 1);

    %% -- epoch data

    EEG = pop_epoch(EEG, {'TMS'}, epoch_len, epoch_feature{:});

    %% -- remove baseline

    EEG = pop_rmbase(EEG, bl_win);

    if disp_res
        cdata.data = nanmean(EEG.data, 3);
        cdata.data_rows = {EEG.chanlocs.labels};
        cdata.data_columns = cellfun(@num2str, num2cell(EEG.times), 'un', 0);
        f = nin_plot(cdata, 'fposition', [1921,1,1820,988]);
        sgtitle('Remove baseline');
    end

    %% -- remove TMS pulse artifact and peaks of TMS-evoked muscle activity

    EEG = pop_tesa_removedata(EEG, tms_win);

    if disp_res
        cdata.data = nanmean(EEG.data, 3);
        cdata.data_rows = {EEG.chanlocs.labels};
        cdata.data_columns = cellfun(@num2str, num2cell(EEG.times), 'un', 0);
        f = nin_plot(cdata, 'fposition', [1921,1,1820,988],'cyrange', [-50 50]);
        sgtitle('Remove TMS');
    end

    %% -- interpolate missing data around TMS pulse

    EEG = pop_tesa_interpdata(EEG, interp_features{:});

    if disp_res
        cdata.data = nanmean(EEG.data, 3);
        cdata.data_rows = {EEG.chanlocs.labels};
        cdata.data_columns = cellfun(@num2str, num2cell(EEG.times), 'un', 0);
        f = nin_plot(cdata, 'fposition', [1921,1,1820,988],'cyrange', [-50 50]);
        sgtitle('Interpolate removed data');
    end

    %% -- detect bad trials

    EEG = pop_jointprob(EEG, epoch_rejection{:});

    %% -- exclude bad epoch and keep their index

    % -- reorganize data to fit in size of epochs

    EEG.etc.bad_epoch.final = EEG.etc.bad_epoch.value;

    EEG.etc.reject.stimuli = [EEG.urevent([EEG.epoch.eventurevent]).latency];
    [~, ix] = setdiff(stimuli, EEG.etc.reject.stimuli);

    EEG.etc.bad_epoch.final(ix) = true;

    [~, EEG.etc.reject.ix] = intersect(stimuli, EEG.etc.reject.stimuli);
    EEG.etc.bad_epoch.reduced = EEG.etc.bad_epoch.final(EEG.etc.reject.ix);

    EEG.etc.reject.final = EEG.reject.rejjp | EEG.etc.bad_epoch.reduced;
    EEG.etc.bad_epoch.final(EEG.etc.reject.ix) = EEG.etc.reject.final;
    EEG_original = EEG;
    EEG_original.data = nan(size(EEG_continues.data, 1), size(EEG.data, 2), size(EEG.data, 3)); % no of channels took form EEG_continues, because in the mean time it could happen that some channels are rejected

    EEG = pop_rejepoch(EEG, EEG.etc.reject.final, 0);

    %% -- replace interpolated data around TMS pulse with constant amplitude data

    EEG = pop_tesa_removedata(EEG, tms_win);

    if disp_res
        cdata.data = nanmean(EEG.data, 3);
        cdata.data_rows = {EEG.chanlocs.labels};
        cdata.data_columns = cellfun(@num2str, num2cell(EEG.times), 'un', 0);
        f = nin_plot(cdata, 'fposition', [1921,1,1820,988]);
        sgtitle('Interpolate missing data after epoch rejection');
    end

    %% -- run first ICA decomposition

    EEG = pop_tesa_fastica(EEG, ica_features{:}); % this wont work if there is no additional script from third party folder FastICA_25 (some bug in TESA)

    %% -- remove TMS-evoked muscle activity (using FastICA and auto component selection)

    EEG = pop_tesa_compselect(EEG, musle_artifacts_features{:});

    %% -- extend data removal to 15 ms (-2 to 15 ms)

    EEG = pop_tesa_removedata( EEG, tms_win_e);

    if disp_res
        cdata.data = nanmean(EEG.data, 3);
        cdata.data_rows = {EEG.chanlocs.labels};
        cdata.data_columns = cellfun(@num2str, num2cell(EEG.times), 'un', 0);
        f = nin_plot(cdata, 'fposition', [1921,1,1820,988],'cyrange', [-50 50]);
        sgtitle('Remove data after musle detection');
    end

    %% -- interpolate missing data around TMS pulse

    EEG = pop_tesa_interpdata(EEG, interp_features_e{:});

    if disp_res
        cdata.data = nanmean(EEG.data, 3);
        cdata.data_rows = {EEG.chanlocs.labels};
        cdata.data_columns = cellfun(@num2str, num2cell(EEG.times), 'un', 0);
        f = nin_plot(cdata, 'fposition', [1921,1,1820,988],'cyrange', [-50 50]);
        sgtitle('Interpolate data after muscle rejection');
    end

    %% -- filter data: bandpass (1-100 Hz) and bandstop (48-52 Hz)

    EEG_f = EEG;
    EEG_f.data = [EEG_f.data, EEG_f.data, EEG_f.data];
    EEG_f.pnts = size(EEG_f.data, 2);

    EEG_f = pop_tesa_filtbutter(EEG_f, bp_settings{:}, 'bandpass');
    EEG_f = pop_tesa_filtbutter(EEG_f, bs_settings{:}, 'bandstop');

    EEG.data = EEG_f.data(:, EEG.pnts+1:2*EEG.pnts, :);

    %% -- replace interpolated data around TMS pulse with constant amplitude data (-2 to 15 ms)

    EEG = pop_tesa_removedata(EEG, tms_win_e);

    %% -- run first ICA decomposition

    EEG = pop_tesa_fastica(EEG, ica_features{:});

    %% -- remove all other artifacts (using FastICA and auto component selection)

    try
        EEG = pop_tesa_compselect(EEG, other_artifacts_features{:});
    catch
    end

    %% -- interpolate missing data around TMS pulse

    EEG = pop_tesa_interpdata(EEG, interp_features_e{:});

    if disp_res
        cdata.data = nanmean(EEG.data, 3);
        cdata.data_rows = {EEG.chanlocs.labels};
        cdata.data_columns = cellfun(@num2str, num2cell(EEG.times), 'un', 0);
        f = nin_plot(cdata, 'fposition', [1921,1,1820,988],'cyrange', [-50 50]);
        sgtitle('Interpolate data after other artifact rejection');
    end

    %% -- interpolate missing channels

    EEG = pop_interp(EEG, eegsys.Channel_Location, 'spherical');

    %% -- re-reference to average

    EEG = pop_reref(EEG, []);

    %% -- add info about component rejection depends on plugin version

    if strcmpi(EEG.etc.TESAvers, 'TESA1.0.1')
        EEG_original.etc.TESA = EEG.icaBadComp1;
    elseif strcmpi(EEG.etc.TESAvers, 'TESA1.1.1')
        EEG_original.etc.TESA.TESA1 = EEG.icaCompClass.TESA1;
        if isfield(EEG.icaCompClass, 'TESA2')
            EEG_original.etc.TESA.TESA2 = EEG.icaCompClass.TESA2;
        else
            EEG.icaCompClass.TESA2.rejectTmsMuscle = [];
            EEG.icaCompClass.TESA2.rejectBlink = [];
            EEG.icaCompClass.TESA2.rejectEyeMove = [];
            EEG.icaCompClass.TESA2.rejectMuscle = [];
            EEG.icaCompClass.TESA2.rejectElectrodeNoise = [];
            EEG.icaCompClass.TESA2.rejectSensory = [];
        end
        EEG_original.etc.TESA.tmsMuscle = EEG.icaCompClass.TESA1.rejectTmsMuscle;
        EEG_original.etc.TESA.eye = [EEG.icaCompClass.TESA2.rejectBlink, EEG.icaCompClass.TESA2.rejectEyeMove];
        EEG_original.etc.TESA.muscle = EEG.icaCompClass.TESA2.rejectMuscle;
        EEG_original.etc.TESA.electrodeNoise = EEG.icaCompClass.TESA2.rejectElectrodeNoise;
        EEG_original.etc.TESA.sensory = EEG.icaCompClass.TESA2.rejectSensory;
        EEG_original.etc.TESA.other = [];
    end

    %% -- turn back bad epoch due to consistency

    EEG_original.data(:, :, ~EEG.etc.reject.final) = EEG.data;
    EEG = EEG_original;
    EEG.etc = EEG_original.etc;

    %% -- turn back data in continues form

    EEG_continues.data = nan(size(EEG_continues.data));
    k = 1;
    while k <= length(EEG.etc.reject.stimuli)

        EEG_continues.data(:, EEG.etc.reject.stimuli(k)+epoch_len(1)*EEG.srate:EEG.etc.reject.stimuli(k)+epoch_len(2)*EEG.srate-1) = EEG.data(:, :, k);

        k = k + 1;
    end
    EEG_continues.etc = EEG.etc;

    %% -- export data

    Y = X;
    Y.data = EEG_continues.data; % copy from continues data data field
    epoch_status = EEG.etc.bad_epoch.final; % copy from continues data rejected epoch, 1 - should be rejected and 0 - cleaned
    error_status = '';
    ME = [];

catch ME

    %% -- handle processing errors
    
    Y = X;
    Y.data = nan(size(EEG_continues.data)); % copy from continues data data field
    epoch_status = EEG.etc.bad_epoch.final; % copy from continues data rejected epoch, 1 - should be rejected and 0 - cleaned

    if strcmpi(ME.message, 'Error: dataset is empty')

        error_status = 'all epochs are rejected';

    else

        error_status = ME.message;

    end

end

end


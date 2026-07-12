function [EEG] = nin_bad_channelsEEGLAB(EEG, varargin)

%% This function detects and interpolates bad eeg channels
%
% - input:
% EEG: input structure organised as EEGLAB structure
%
% - optional:
% arifact_feature: parameters passed to clean_artifacts (default: 'FlatlineCriterion', 5, ChannelCriterion',  .5)
%
% - example:
% edata = nin_bad_channelsEEGLAB(EEG);

% -- read input parameters
nin_import_params(varargin);

%% -- set default parameters

% -- define artifact detection parameters
if ~exist('arifact_feature', 'var')
    arifact_feature =  {'FlatlineCriterion', 5,...
        'Highpass',          'off',...
        'ChannelCriterion',  .5,...
        'LineNoiseCriterion','off',...
        'BurstCriterion',    'off',...
        'WindowCriterion',   'off'};
end

% -- get total number of channels
nch_total = size(EEG.data, 1);

% -- initialize channel quality information
EEG.etc.bad_ch.ch_status = true(nch_total, 1);
EEG.etc.bad_ch.ch_removed = ~EEG.etc.bad_ch.ch_status;

% -- keep original eeg structure
EEG_original = EEG;

% -- detect bad channels
EEG = clean_artifacts(EEG, arifact_feature{:});

% -- interpolate removed channels
if size(EEG.data, 1) < nch_total

    % -- store channel status
    EEG.etc.bad_ch.ch_status = EEG.etc.clean_channel_mask';

    % -- mark removed channels
    EEG.etc.bad_ch.ch_removed = ~EEG.etc.bad_ch.ch_status;

    try
        % -- interpolate removed channels
        EEG = eeg_interp(EEG_original, find(EEG.etc.bad_ch.ch_removed));
        % -- update channel status
        EEG.etc.bad_ch.ch_status = EEG.etc.clean_channel_mask';
        % -- update removed channel mask
        EEG.etc.bad_ch.ch_removed = ~EEG.etc.bad_ch.ch_status;
        % -- mark successful interpolation
        EEG.etc.bad_ch.ch_interpolated = true;
    catch
        % -- mark failed interpolation
        EEG.etc.bad_ch.ch_interpolated = false;
        % -- restore original eeg structure
        EEG = EEG_original;
    end

end

end


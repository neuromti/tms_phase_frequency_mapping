function [y] = nin_read_xdf(x)

%% This function loads and reorganizes xdf data streams
%
% - input:
% x.path_in: input directory (mandatory field)
% x.filename_in: input filename  (mandatory field)
%
% - optional:
% x.in_fetures: parameters passed to load_xdf (recommendation: {'HandleClockSynchronization', false})
%
% - example:
% y = nin_read_xdf(x);

% -- load data localy
if ~(isfield(x, 'path_in') && isfield(x, 'filename_in'))
    error('Input structure has to contain mandatory fields');
end

%% -- load data localy

% -- load xdf file using custom options
if isfield(x, 'in_fetures')
    [s, ~] = load_xdf([x.path_in, x.filename_in], x.in_fetures{:});
else
    [s, ~] = load_xdf([x.path_in, x.filename_in]);
end

%% -- reorganise data

% -- store input information
y.path_in = x.path_in;
y.filename_in = x.filename_in;

% -- process available xdf stream
k = 1;
while k <= length(s)

    % -- generate stream identifier
    cname = [s{1, k}.info.name, '_', s{1, k}.info.type];

    switch cname

        % -- marker stream
        case {'reiz-marker_Markers', 'reiz_marker_sa_Markers'}

            y.markers.data = s{1, k}.time_series;
            y.markers.ts = s{1, k}.time_stamps;
            if isfield(s{1, k}.info, 'first_timestamp')
                y.markers.first_ts = str2num(s{1, k}.info.first_timestamp);
                y.markers.last_ts = str2num(s{1, k}.info.last_timestamp);
            else
                y.markers.first_ts = y.markers.ts(1);
                y.markers.last_ts = y.markers.ts(end);
            end

            % -- response box stream
        case 'GDX-RB_0K200106_RB'

            y.rb.data = s{1, k}.time_series;
            y.rb.ts = s{1, k}.time_stamps;
            if isfield(s{1, k}.info, 'first_timestamp')
                y.rb.first_ts = y.markers.ts(1);
                y.rb.last_ts = str2num(s{1, k}.info.last_timestamp);
            else
                y.rb.first_ts = y.rb.ts(1);
                y.rb.last_ts = y.rb.ts(end);
            end

            % -- eye-tracking gaze stream
        case 'pupil_capture_Gaze'

            y.gaze.data = s{1, k}.time_series;
            y.gaze.ts = s{1, k}.time_stamps;
            if isfield(s{1, k}.info, 'first_timestamp')
                y.gaze.first_ts = str2num(s{1, k}.info.first_timestamp);
                y.gaze.last_ts = str2num(s{1, k}.info.last_timestamp);
            else
                y.gaze.first_ts = y.gaze.ts(1);
                y.gaze.last_ts = y.gaze.ts(end);
            end

            % -- brainvision marker stream
        case 'BrainVision RDA Markers_Markers'

            y.rdamarkers.data = s{1, k}.time_series;
            y.rdamarkers.ts = s{1, k}.time_stamps;

            % -- localite marker stream
        case 'localite_marker_Markers'

            y.lmarkers.data = s{1, k}.time_series;
            y.lmarkers.ts = s{1, k}.time_stamps;

            % -- eeg stream
        case {'BrainVision RDA_EEG', 'eego'}

            % -- convert eego data to microvolts
            if strcmpi(cname, 'eego')
                y.eeg.data = s{1, k}.time_series * 10^6;
            else
                y.eeg.data = s{1, k}.time_series;
            end
            y.eeg.ts = s{1, k}.time_stamps;
            if isfield(s{1, k}.info, 'first_timestamp')
                y.eeg.first_ts = str2num(s{1, k}.info.first_timestamp);
                y.eeg.last_ts = str2num(s{1, k}.info.last_timestamp);
            else
                y.eeg.first_ts = y.eeg.ts(1);
                y.eeg.last_ts = y.eeg.ts(end);
            end

            % -- store sampling information
            y.eeg.strate = str2num(s{1, k}.info.nominal_srate);
            y.eeg.estrate = s{1, k}.info.effective_srate;

            % -- initialize channel information
            y.eeg.channels = cell(1, length(s{1, k}.info.desc.channels.channel));
            y.eeg.unit = cell(1, length(s{1, k}.info.desc.channels.channel));

            % -- extract channel labels and units
            k1 = 1;
            while k1 < length(s{1, k}.info.desc.channels.channel)
                y.eeg.channels{1, k1} = s{1, k}.info.desc.channels.channel{1, k1}.label;
                y.eeg.unit{1, k1} = s{1, k}.info.desc.channels.channel{1, k1}.unit;
                k1 = k1 + 1;
            end

            % -- IMSD data
        case {'Spongebob-Data_EEG', 'LuckyLoop'}

            y.sd.data = s{1, k}.time_series;
            y.sd.ts = s{1, k}.time_stamps;
            if isfield(s{1, k}.info, 'first_timestamp')
                y.sd.first_ts = str2num(s{1, k}.info.first_timestamp);
                y.sd.last_ts = str2num(s{1, k}.info.last_timestamp);
            else
                y.sd.first_ts = y.sd.ts(1);
                y.sd.last_ts = y.sd.ts(end);
            end
            y.sd.strate = str2num(s{1, k}.info.nominal_srate);
            y.sd.estrate = s{1, k}.info.effective_srate;

    end

    k = k + 1;

end

end


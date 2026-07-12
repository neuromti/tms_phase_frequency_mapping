function [y] = nin_tms(x, varargin)

%%  This function extracts and reconstructs TMS stimulation events
%
% - input:
% x: marker structure obtained from xdf recordings
%
% - optional:
% spliter: primary delimiter used for parsing markers (defaule: ';')
% spliter2: secondary delimiter used for parsing markers (defaule: ':')
% study: name of the study (default: 'IMONAS')
% device: eeg recording system (default: 'BrainVision')
% fs: sampling frequency (default: 1000)
% eeg: eeg/emg recording structure used for pulse detection
% ch1: eeg channel used for tms artifact detection
% ch2: emg channel used for tms artifact detection
% pp_th_eeg/pp_th_emg: EEG/EMG peak-to-peak threshold (default: 800/50)
% amp_th_eeg/amp_th_emg: EEG/EMG amplitude threshold (default: 650/30)
%
% - example:
% psd  = nin_tms(rdata.markers);

% -- read input parameters
nin_import_params(varargin);

%% -- set default parameters

% -- define eeg recording system
if ~exist('device', 'var')
    device = 'BrainVision';
end

% -- define study name
if ~exist('study', 'var')
    study = 'IMONAS';
end

% -- define primary marker delimiter
if ~exist('spliter', 'var')
    spliter = ',';
end

% -- define secondary marker delimiter
if ~exist('spliter2', 'var')
    spliter2 = ':';
end

% -- define sampling frequency
if ~exist('fs', 'var')
    fs = 1000;
end

% -- define eeg structure used for pulse estimation
if ~exist('eeg', 'var')
    eeg = [];
end

% -- define eeg and emg channels for pulse detection
if ~exist('ch1', 'var')
    ch1 = 'C3';
end

if ~exist('ch2', 'var')
    ch3 = 'EDC_R';
end

% -- define peak-to-peak thresholds
if ~exist('pp_th_eeg', 'var')
    pp_th_eeg = 800;
end

if ~exist('pp_th_emg', 'var')
    pp_th_emg = 50;
end

% -- define amplitude thresholds
if ~exist('amp_th_eeg', 'var')
    amp_th_eeg = 650;
end

if ~exist('amp_th_emg', 'var')
    amp_th_emg = 30;
end


eegsys = nin_eeg_system(device);

%% -- extract tms information according to study protocol

switch study

    case 'IMONAS'

        % -- process marker stream
        k = 1;
        kk = 1;
        while k <= length(x.data)

            % -- extract current marker
            cdata = x.data{k};

            % -- remove json formatting characters
            cdata = strrep(cdata, '{', '');
            cdata = strrep(cdata, '}', '');

            cdata = strsplit(cdata, spliter);

            if length(cdata) == 4

                % -- split marker content into key-value pairs
                y(kk) = def_struct;

                k2 = 1;
                while k2 <= length(cdata)

                    ccdata = strrep(cdata{k2}, '"', '');
                    ccdata = strsplit(ccdata, spliter2);
                    ccdata = strtrim(ccdata);

                    % -- extract stimulation parameters
                    switch ccdata{1}

                        % -- stimulation identifier
                        case 'stimulus_idx'

                            y(kk).ixd = str2num(ccdata{2});

                            % -- stimulation type
                        case 'stim_type'

                            y(kk).type = ccdata{2};

                            % -- stimulation frequency
                        case 'freq'

                            y(kk).freq = str2num(ccdata{2});

                            % -- stimulation phase
                        case 'phase'

                            y(kk).phase = str2num(ccdata{2});

                    end

                    % -- assign default stimulation intensity
                    y(kk).amp = 120;
                    y(kk).time = x.ts(k);

                    k2 = k2 + 1;

                end

            elseif length(cdata) == 1

                ccdata = strrep(cdata{1}, '"', '');
                ccdata = strsplit(ccdata, spliter2);
                ccdata = strtrim(ccdata);

                switch ccdata{1}

                    % -- extract behavioral response
                    case 'reaction_time'

                        y(kk).rtime = str2num(ccdata{2});

                end

            end

            if strcmpi(y(kk).type, 'TMS')

                k = k + 1;
                kk = kk + 1;

            elseif strcmpi(y(kk).type, 'PVT')

                if isnan(y(kk).rtime)

                    k = k + 3;

                else

                    k = k + 1;
                    kk = kk + 1;

                end

            else

                k = k + 1;
                kk = kk + 1;

            end

        end

        %% -- estimate true tms pulse timing from eeg and emg signals

        % -- identify eeg and emg detection channels
        ix_ch1 = eegsys.ix_channels(strcmpi(eegsys.channels, ch1));
        ix_ch2 = eegsys.ix_channels_emg(strcmpi(eegsys.channels_emg, ch3));
        % -- extract detection signals
        ch1_data = eeg.data(ix_ch1, :);
        ch2_data = eeg.data(ix_ch2, :);

        % -- define pulse detection windows
        win = 1*fs;
        win_shift = 100;
        swin = 50;
        n = fix(length(ch1_data)/win);

        % -- scan recording for tms artifacts
        sample = [];
        k = 1;
        while k <= n

            % -- define current analysis window
            csample = (k-1)*win+1:k*win;

            cdata = ch1_data(csample);
            cdata2 = ch2_data(csample);

            % -- find eeg peak-to-peak artifact
            [val_max, ix_max] = max(cdata);
            [val_min, ix_min] = min(cdata);

            if abs(ix_max - ix_min) > 2*swin
                if abs(val_max) > abs(val_min)
                    rb = ix_max + swin;
                    lb = ix_max - swin - 1;
                    if rb > win
                        rb =  win;
                    end
                    if lb < 1
                        lb =  1;
                    end
                    crange = lb:rb;
                    [val_min, ix_min_new] = min(cdata(crange));
                    ix_min = crange(ix_min_new);
                else
                    rb = ix_min + swin;
                    lb = ix_min - swin - 1;
                    if rb > win
                        rb =  win;
                    end
                    if lb < 1
                        lb =  1;
                    end
                    crange = lb:rb;
                    [val_max, ix_max_new] = max(cdata(crange));
                    ix_max = crange(ix_max_new);
                end
            end

            % -- find emg peak-to-peak artifact
            [val_max2, ix_max2] = max(cdata2);
            [val_min2, ix_min2] = min(cdata2);

            if abs(ix_max2 - ix_min2) > 100
                if abs(val_max2) > abs(val_min2)
                    rb = ix_max2 + swin;
                    lb = ix_max2 - swin - 1;
                    if rb > win
                        rb =  win;
                    end
                    if lb < 1
                        lb =  1;
                    end
                    crange = lb:rb;
                    [val_min2, ix_min_new2] = min(cdata2(crange));
                    ix_min2 = crange(ix_min_new2);
                else
                    rb = ix_min2 + swin;
                    lb = ix_min2 - swin - 1;
                    if rb > win
                        rb =  win;
                    end
                    if lb < 1
                        lb =  1;
                    end
                    crange = lb:rb;
                    [val_max2, ix_max_new2] = max(cdata2(crange));
                    ix_max2 = crange(ix_max_new2);
                end
            end

            % -- calculate artifact amplitude
            cpeak = abs(val_max) + abs(val_min);
            cpeak2 = abs(val_max2) + abs(val_min2);

            % -- identify candidate tms pulse
            fsample = [];
            if (double(cpeak) > pp_th_eeg && (val_max > amp_th_eeg || val_min < -amp_th_eeg)) && (double(cpeak2) > pp_th_emg && (val_max2 > amp_th_emg || val_min2 < -amp_th_emg)) && (abs(ix_max - ix_max2) < 100 || abs(ix_min - ix_min2) < 100)

                fsample = csample(ix_max);

            end

            % -- search neighbouring window for delayed emg responseShow more lines
            if k ~= n

                csample_r = csample + win_shift;

                cdata_r = ch1_data(csample_r);
                cdata2_r = ch2_data(csample_r);


                [val_max_r, ix_max_r] = max(cdata_r);
                [val_min_r, ix_min_r] = min(cdata_r);

                if abs(ix_max_r - ix_min_r) > 100
                    if abs(val_max_r) > abs(val_min_r)
                        rb = ix_max_r + swin;
                        lb = ix_max_r - swin - 1;
                        if rb > win
                            rb =  win;
                        end
                        if lb < 1
                            lb =  1;
                        end
                        crange = lb:rb;
                        [val_min_r, ix_min_new_r] = min(cdata(crange));
                        ix_min_r = crange(ix_min_new_r);
                    else
                        rb = ix_min_r + swin;
                        lb = ix_min_r - swin - 1;
                        if rb > win
                            rb =  win;
                        end
                        if lb < 1
                            lb =  1;
                        end
                        crange = lb:rb;
                        [val_max_r, ix_max_new_r] = max(cdata(crange));
                        ix_max_r = crange(ix_max_new_r);
                    end
                end

                [val_max2_r, ix_max2_r] = max(cdata2_r);
                [val_min2_r, ix_min2_r] = min(cdata2_r);

                if abs(ix_max2_r - ix_min2_r) > 100
                    if val_max2_r > abs(val_min2_r)
                        rb = ix_max2_r + swin;
                        lb = ix_max2_r - swin - 1;
                        if rb > win
                            rb =  win;
                        end
                        if lb < 1
                            lb =  1;
                        end
                        crange = lb:rb;
                        [val_min2_r, ix_min_new2_r] = min(cdata2(crange));
                        ix_min2_r = crange(ix_min_new2_r);
                    else
                        rb = ix_min2_r + swin;
                        lb = ix_min2_r - swin - 1;
                        if rb > win
                            rb =  win;
                        end
                        if lb < 1
                            lb =  1;
                        end
                        crange = lb:rb;
                        [val_max2_r, ix_max_new2_r] = max(cdata2(crange));
                        ix_max2_r = crange(ix_max_new2_r);
                    end
                end

                cpeak_r = abs(val_max_r) + abs(val_min_r);
                cpeak2_r = abs(val_max2_r) + abs(val_min2_r);

            else

                cpeak_r = NaN(1, 1);
                cpeak2_r = NaN(1, 1);

            end

            fsample_r = [];
            if (double(cpeak_r) > pp_th_eeg && (val_max_r > amp_th_eeg || val_min_r < -amp_th_eeg) && csample_r(ix_max_r) <= csample(end)) && (double(cpeak2_r) > pp_th_emg && (val_max2_r > amp_th_emg || val_min2_r < -amp_th_emg)) && (abs(ix_max_r - ix_max2_r) < 100 || abs(ix_min_r - ix_min2_r) < 100)

                fsample_r = csample_r(ix_max_r);

            end

            %  -- pick up sample
            if ~isempty(fsample)
                sample = [sample; csample(ix_max)];
            elseif ~isempty(fsample_r) && isempty(fsample)
                sample = [sample; csample(ix_max_r)];
            end

            k = k+1;
        end

        %% -- match detected pulses with recorded stimulation markersShow more lines

        % -- extract tms markers
        [yTMS, ix_TMS] = nin_subselect_dstruct(y, 'type', 'TMS');
        % -- convert marker timestamps to sample domain
        ctime = round([yTMS.time]'*1000);
        ctime = ctime - ctime(1) + sample(1);

        % -- assign detected pulses to stimulation events
        k = 1;
        kk = 1;
        while k <= length(sample)

            % -- find nearest stimulation marker
            y_new(k) = def_struct;
            y_lost(k) = def_struct;
            [cmin, ix_min] = min(abs(ctime - sample(k)));

            % -- accept marker-pulse match
            if cmin < 3500

                y_new(k).ixd = yTMS(ix_min).ixd;
                y_new(k).type = yTMS(ix_min).type;
                y_new(k).amp = yTMS(ix_min).amp;
                y_new(k).freq = yTMS(ix_min).freq;
                y_new(k).phase = yTMS(ix_min).phase;
                y_new(k).rtime = yTMS(ix_min).rtime;
                y_new(k).time = yTMS(ix_min).time;
                y_new(k).stime = ctime(ix_min);
                y_new(k).sample = sample(k);

            else

                % -- create unmatched tms event
                y_new(k).type = 'TMS';
                y_new(k).amp = 120;
                y_new(k).sample = sample(k);

            end

            k = k + 1;

        end

        % -- identify stimulation markers without detected pulses
        [~, ix_lost] = setdiff([yTMS.ixd], [y_new.ixd]);
        y_lost = yTMS(ix_lost);
        ctime_lost = num2cell(ctime(ix_lost));
        [y_lost.stime] = ctime_lost{:};

        ctime_lost = cell2mat(ctime_lost);

        % -- reconstruct complete event sequence
        y_final = []; check = false(1, length(ctime_lost));
        k = 1;
        while k <= length(y_new)-1

            ix = (y_new(k).sample < ctime_lost) & (ctime_lost < y_new(k+1).sample);

            if ~all(check)
                if any(ix)

                    y_final =  [y_final, y_new(k), y_lost(ix)];
                    check(ix) = true;

                else

                    y_final =  [y_final, y_new(k)];

                end

                k = k + 1;

            else

                y_final =  [y_final, y_new(k:end)];
                k = length(y_new);

            end

        end

    case 'INTENS'

        % -- fixed timing correction between marker and pulse
        tconst = 221;

        % -- process stimulation markers
        k = 1;
        kk = 1;
        while k <= length(x.data)

            cdata = x.data{k};

            if ~any(contains(cdata, {'number', 'augen' 'None'}))

                cdata = strrep(cdata, 'ma', '');
                cdata = strrep(cdata, '''', '');

                ccdata = strsplit(cdata, spliter);

                % -- initialize stimulation record
                y(kk) = def_struct;

                y(kk).ixd = kk;
                y(kk).type = 'TMS';
                y(kk).amp = str2num(ccdata{1});
                y(kk).freq = 20;
                y(kk).phase = str2num(ccdata{2});
                y(kk).rtime = NaN(1, 1);
                y(kk).time = x.ts(k);
                y(kk).sample = x.ts(k);

                if isempty(tconst)
                    ix_m = 500;
                    c3 = eeg.data(strcmpi(eegsys.channels, 'C3'), y(kk).sample-ix_m:y(kk).sample+ix_m);
                    figure;
                    plot(-ix_m:ix_m, c3);
                    [pks, ix] = max(c3);
                    tconst = ix_m - ix + 1;
                end

                % -- initialize stimulation record
                y(kk).sample = y(kk).sample - tconst;
                ix_m = 500;
                c3 = eeg.data(strcmpi(eegsys.channels, 'C3'), y(kk).sample-ix_m:y(kk).sample+ix_m);
                figure;
                plot(-ix_m:ix_m, c3);

                kk = kk + 1;

            end

            k = k + 1;

        end

end

y = y_final;

end

%% -- create default stimulation structure

function [y] = def_struct()

y.ixd = NaN(1, 1);
y.type = '';
y.amp = NaN(1, 1);
y.freq = NaN(1, 1);
y.phase = NaN(1, 1);
y.rtime = NaN(1, 1);
y.time = NaN(1, 1);
y.stime = NaN(1, 1);
y.sample = NaN(1, 1);

end
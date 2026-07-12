function [y] = nin_data_epoching(x, samples, varargin)

%% This function extracts epochs around selected events
%
% - input:
% x: input structure containing continuous data
% samples: event sample indices
%
% - optional:
% id_event: event identifiers (default: 1:length(samples))
% fs: sampling frequency (default: 1000)
% win_len: epoch length in seconds (default: 3)
% id_event: event number (default: 1:length(samples))
% direction: epoch extraction direction pre/post/pre-post stimuli (default: 'pre')
%
% - example:
% edata = nin_data_epoching(cdata.eeg, [cemg.pulse_BV]);
% edata = nin_data_epoching(cdata.eeg, [cemg.pulse_BV], 'id_event', [cemg.id_event]);

% -- read input parameters
nin_import_params(varargin);

%% -- set default parameters

% -- define sampling frequency
if ~exist('fs', 'var') || isfield(x, 'strate')
    fs = 1000;
elseif exist('fs', 'var')
elseif isfield(x, 'strate')
    fs = x.strate;
end

% -- define epoch direction
if ~exist('direction', 'var')
    direction = 'post';
end

% -- define epoch length
if ~exist('win_len', 'var')
    win_len = 3;
end
if length(win_len) == 1
    win_len = [win_len, win_len];
end

% -- define event identifiers
if ~exist('id_event', 'var')
    id_event = 1:length(samples);
end

% -- get signal length
n = size(x.data, 2);

%% -- extract epochs

k = 1;
while k <= length(samples)

    switch direction

        case 'post'

            if samples(k)+win_len(1)*fs-1 <= n

                % -- extract post-stimulus epoch
                y(k).id_event = id_event(k);
                y(k).data = x.data(:, samples(k):samples(k)+win_len(1)*fs-1);
                y(k).data_rows = x.channels;
                y(k).data_columns = x.ts(1, samples(k):samples(k)+win_len(1)*fs-1);
                y(k).time = 0:win_len(1)*fs-1;
                y(k).strate = x.strate;
                y(k).estrate = x.estrate;
                y(k).unit = x.unit;

            end

        case 'pre'

            if ~(samples(k)-win_len(1)*fs+1 <= 0)

                % -- extract pre-stimulus epoch
                y(k).id_event = id_event(k);
                y(k).data = x.data(:, samples(k)-win_len(1)*fs+1:samples(k));
                y(k).data_rows = x.channels;
                y(k).data_columns = x.ts(1, samples(k)-win_len(1)*fs+1:samples(k));
                y(k).time = -win_len(1)*fs+1:0;
                y(k).strate = x.strate;
                y(k).estrate = x.estrate;
                y(k).unit = x.unit;

            end

        case 'pre-post'

            % -- extract pre- and post-stimulus epoch
            if ~(samples(k)-win_len(1)*fs+1 <= 0) && samples(k)+win_len(2)*fs-1 <= n

                y(k).id_event = id_event(k);
                y(k).data = x.data(:, samples(k)-win_len(1)*fs:samples(k)+win_len(2)*fs-1);
                y(k).data_rows = x.channels;
                y(k).data_columns = x.ts(1, samples(k)-win_len(1)*fs:samples(k)+win_len(2)*fs-1);
                y(k).time = -win_len(1)*fs:win_len(2)*fs-1;
                y(k).strate = x.strate;
                y(k).estrate = x.estrate;
                y(k).unit = x.unit;

            end

    end

    k = k + 1;

end

end

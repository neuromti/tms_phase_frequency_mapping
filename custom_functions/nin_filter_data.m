function [y] = nin_filter_data(x, ftype, varargin)

%% This function applies digital filtering to input data
%
% - input:
% x: iinput structure containing time-series data
% ftype: butter_zerophi - flter type
%
% - optional:
% Fs: sampling frequency (default: 1000)
% LP: lower cutoff frequency (default: 0.5)
% HP: upper cutoff frequency (default: 49)
% forder: filter order (default: 4)
%
% - example:
% perp  = nin_filter_data(x, 'bandpass_zerophi');

% -- read input parameters
nin_import_params(varargin);

%% -- set default parameters

% -- define sampling frequency
if ~exist('Fs', 'var')
    Fs = 1000;
end

% -- define lower cutoff frequency
if ~exist('LP', 'var')
    LP = 0.5;
end

% -- define upper cutoff frequency
if ~exist('HP', 'var')
    HP = 49;
end

% -- define filter order
if ~exist('forder', 'var')
    forder = 4;
end

% -- convert cutoff frequencies to cell format
if ~iscell(LP)
    LP = num2cell(LP);
end
if ~iscell(HP)
    HP = num2cell(HP);
end

% -- ensure row-wise structure format
if size(x, 2) == 1 && size(x, 1) > 1
    x = x';
end

%% -- filter data

% -- calculate nyquist frequency
Fn = Fs/2;

y = x;

% -- process structure elements
k = 1;
while k <= size(x, 2)

    % -- apply selected filter
    switch ftype

        case 'butter_zerophi'

            % -- skip structures containing nan values
            if ~any(isnan(y(k).data), 'all')

                % -- process frequency bands
                kf = 1;
                while kf <= length(LP)

                    % -- normalize cutoff frequencies
                    BP = [LP{kf} HP{kf}]/Fn; % normalizing frequency range.
                    % -- design butterworth filter
                    [b, a] = butter(forder, BP); % 4st order butterworth filter.

                    % -- filter each channel separately
                    kc = 1;
                    while kc <= length(y(k).data_rows)

                        warning('off');

                        % -- apply zero-phase filtering
                        y(k).data(kc, :, kf) = filtfilt(b, a, x(k).data(kc, :));  % Filter Signal

                        warning('on');

                        kc = kc + 1;

                    end

                    kf = kf + 1;

                end

            else

                % -- return nan output if input contains invalid data
                if isfield(x, 'data_layers')
                    y(k).data = nan(length(x(k).data_rows), length(x(k).data_columns), length(x(k).data_layers));
                else
                    y(k).data = nan(length(x(k).data_rows), length(x(k).data_columns));
                end

            end

    end

    k = k + 1;

end

end

function [y] = nin_erp_measure(x, measure, varargin)

%% This function calculates ERP measures
%
% - input:
% x: input structure created after date data cleaning/epoching
% measure: peak - erp measure to calculate: ('peak' or 'zscored_peak')
%
% - optional:
% peak: peak labels (default: {'P25', 'N45', 'P70', 'N100', 'P180'})
% win: peak search windows in milliseconds (default: {[15 35], [35 55], [60 80], [90 120], [170 190]})
%
% - example:
% perp  = nin_erp_measure(gdata, 'peak');

% -- read input parameters
nin_import_params(varargin);

%% -- set default parameters

% -- define peak labels
if ~exist('peak', 'var')
    peak = {'P25', 'N45', 'P70', 'N100', 'P180'};
end

% -- define peak search windows
if ~exist('win', 'var')
    win = {[15 35], [35 55], [60 80], [90 120], [170 190]};
end

%% -- calculate defined measure

% -- initialize output structure
y = x;

% -- calculate requested measure
switch measure

    case 'peak'

        % -- process erp dataset
        k = 1;
        while k <= length(x)

            % -- initialize output variables
            new_header = [];
            ndata = [];
            k2 = 1;
            while k2 <= length(peak)

                % -- create output column labels
                new_header = [new_header, strcat(peak(1, k2), '_', {'amp', 'latency'})];

                % -- define peak search window
                cwin = win{1, k2}(1):win{1, k2}(2);

                % -- locate samples within search window
                time = cell2mat(cellfun(@str2num, x(k).data_columns, 'un', 0));
                [~, tix, ~] = intersect(time, cwin);

                % -- extract data from current window
                if isfield(x, 'data')
                    cdata = x(k).data(:, tix);
                else
                    cdata = x(k).dataMEAN(:, tix);
                end

                % -- extract positive or negative peak
                if strcmpi(peak{1, k2}(1), 'P')
                    % -- locate maximum amplitude
                    [cpeak, cix] = max(cdata, [], 2);
                    ndata = [ndata, cpeak, cwin(cix)'];
                else
                    % -- locate minimum amplitude
                    [cpeak, cix] = min(cdata, [], 2);
                    ndata = [ndata, cpeak, cwin(:, cix)'];
                end

                k2 = k2 + 1;

            end

            % -- store extracted peak measures
            y(k).data = ndata;
            y(k).data_columns = new_header;

            k = k + 1;

        end

    case 'zscored_peak'

        k = 1;
        while k <= length(x)

            % -- initialize output variables
            new_header = [];
            ndata = [];
            k2 = 1;
            while k2 <= length(peak)

                % -- create output column labels
                new_header = [new_header, strcat(peak(1, k2), '_', {'amp_zscored', 'latency_zscored'})];

                % -- define peak search window
                cwin = win{1, k2}(1):win{1, k2}(2);

                % -- locate samples within search window
                time = cell2mat(cellfun(@str2num, x(k).data_columns, 'un', 0));
                [~, tix, ~] = intersect(time, cwin);

                % -- extract data from current window
                if isfield(x, 'data')
                    cdata = x(k).data(:, tix);
                else
                    cdata = x(k).dataMEAN(:, tix);
                end

                % -- standardize data within search window
                cdata = zscore(cdata);

                % -- extract positive or negative z-scored peak
                if strcmpi(peak{1, k2}(1), 'P')
                    % -- locate maximum amplitude
                    [cpeak, cix] = max(cdata, [], 2);
                    ndata = [ndata, cpeak, cwin(cix)'];
                else
                    % -- locate minimum amplitude
                    [cpeak, cix] = min(cdata, [], 2);
                    ndata = [ndata, cpeak, cwin(:, cix)'];
                end

                k2 = k2 + 1;

            end

            y(k).data = ndata;
            y(k).data_columns = new_header;

            k = k + 1;

        end

end

end

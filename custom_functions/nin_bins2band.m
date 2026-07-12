function [x] = nin_bins2band(x, varargin)

%% This function converts frequency bins into frequency bands
%
% - input:
% x: input structure containing PSD data
%
% - optional:
% joinmethod: add/replace add custom bands to default list of bands or keep just custom list (default: 'add')
% outmethod: add/replace add bands to bins in otput structure or keep just bands (default: 'replace')
% log_flag: unlog PSD before computation (default: false)
% ChList: list of channels used for band calculation
%
% - example:
% bpsd = nin_bins2band(cpsd, eegsys.channels);
% bpsd = nin_bins2band(cpsd, {'F7', 'F8'});
% bpsd = nin_bins2band(cpsd, {'F7', 'F8'}, 'CustomBands', {'GammaFast_41_60'});

% -- read input parameters
nin_import_params(varargin)

%% -- set default parameters

% -- define default frequency bands
BandList_default = {'Delta_1_3',...
    'Theta_4_7',...
    'Alpha_8_12',...
    'Mu_8_13',...
    'Beta_13_31',...
    'Gamma_32_40'};

% -- define band combination method
if ~exist('joinmethod', 'var')
    joinmethod = 'add';
end

% -- define frequency bands
if ~exist('CustomBands', 'var')
    BandList = BandList_default;
else
    if size(CustomBands, 1) > 1
        CustomBands = CustomBands';
    end
    if strcmp(joinmethod, 'add')
        BandList = [BandList_default, CustomBands];
    elseif strcmp(joinmethod, 'replace')
        BandList = CustomBands;
    end
end

% -- define output mode
if ~exist('outmethod', 'var')
    outmethod = 'replace';
end

% -- define log-transformed data flag
if ~exist('log_flag', 'var')
    log_flag = false;
end

% -- ensure column identifiers are strings
if ischar(x(1).data_columns)
    columns_name = x(1).data_columns;
else
    columns_name = cellfun(@num2str, x(1).data_columns, 'un', 0);
end

%% -- compute PSD bandwidths

k = 1;
while k <= size(x, 2)

    disp(['Computing epoch ', num2str(k), '/', num2str(size(x, 2))]);

    % -- convert structure to cell format if channels are selected
    if exist('ChList', 'var')
        y = nin_struct2cell_form(x(k), 'otype', 'cell', 'smeta', []);
    end

    kB = 1;
    % -- initialize band matrix
    band = NaN(size(x(k).data, 1), size(BandList, 2));
    while kB <= size(BandList, 2)

        % -- extract lower frequency bound
        lower_b = str2num(char(nin_strsplit(BandList(1, kB), 2, 2, 'spliter', '_')));

        % -- extract upper frequency bound
        upper_b = str2num(char(nin_strsplit(BandList(1, kB), 'last', [], 'spliter', '_')));

        % -- generate frequency bin labels
        bins = num2cell(lower_b:upper_b);
        bins = cellfun(@num2str, bins, 'un', 0);

        % -- calculate band power for selected channels
        if exist('ChList', 'var')

            kC = 1;
            while kC <= size(ChList, 2)

                % -- extract bins for current channel
                band_ch = nin_subselect_fields(y, strcat(ChList{1,kC}, '_', bins));
                band_ch = band_ch(2:end, :);

                % -- calculate average band power
                if size(band_ch, 2) == size(bins, 2) % in case that some bin is missing in input data bandwidth will not be calculated
                    band_ch = cell2mat(band_ch);
                    if log_flag
                        % -- convert to linear scale before averaging
                        band_ch = 10.^band_ch;
                        band(strcmp(x(k).data_rows, ChList{1,kC}), kB) = log10(mean(band_ch, 2));
                    else
                        band(strcmp(x(k).data_rows, ChList{1,kC}), kB) = mean(band_ch, 2);
                    end
                else
                    % -- report missing frequency bins
                    warning([BandList{1, kB} ' could not be calculated. It is not possible to extract all frequencies for defined range.']);
                end

                kC = kC + 1;
            end

        else

            % -- calculate band power for all channels
            band_ch = x(k).data(:, ismember(columns_name, bins));

            % -- calculate average band power
            if size(band_ch, 2) == size(bins, 2) % in case that some bin is missing in input data bandwidth will not be calculated
                band_ch = cell2mat(band_ch);
                if log_flag
                    % -- convert to linear scale before averaging
                    band_ch = 10.^band_ch;
                    band(:, kB) = log10(mean(band_ch, 2));
                else
                    band(:, kB) = mean(band_ch, 2);
                end
            else
                % -- report missing frequency bins
                warning([BandList{1, kB} ' could not be calculated. It is not possible to extract all frequencies for defined range.']);
            end

        end

        kB = kB + 1;
    end

    %% -- export data

    switch outmethod
        case 'add'
            x(k).data =  [x(k).data, band];
            x(k).data_columns = [x(k).data_header, BandList];
            x(k).unit =  [x(k).unit, x(k).unit(1:length(BandList))];
        case 'replace'
            x(k).data =  band;
            x(k).data_columns =  BandList;
            x(k).unit =  x(k).unit(1:length(BandList));
    end

    k = k + 1;

end

end

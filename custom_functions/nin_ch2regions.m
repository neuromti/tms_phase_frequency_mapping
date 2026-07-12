function [x] = nin_ch2regions(x, varargin)

%% This function converts channel-level data into regional averages
%
% - input:
% x: input structure containing channel-level data
%
% - optional:
% joinmethod: add custom regions to default regions or replace them (default: 'add')
% outmethod: add regional data to existing data or replace channels (default: 'replace')
% log_flag: convert log-transformed data to linear scale before averaging (default: false)
%
% - example:
% rpsd = nin_ch2regions(cpsd);
% rpsd = nin_ch2regions(cpsd, 'CustomRegion', {'Midline', {'Fz', 'Cz', 'CPz', 'POz', 'Oz'}});

% -- read input parameters
nin_import_params(varargin)

%% -- set default parameters

% -- load eeg channel information
eegsys = nin_eeg_system('BrainVision');

% -- define default regions
RegionList_default = {'Overall', eegsys.channels;...
    'FrontalLeft', {'Fp1', 'AF7', 'AF3', 'F7', 'F5', 'F3', 'F1'};...
    'FrontalRight', {'Fp2', 'AF8', 'AF4', 'F8', 'F6', 'F4', 'F2'};...
    'FrontalTotal', {'Fp1', 'AF7', 'AF3', 'F7', 'F5', 'F3', 'F1', 'Fpz', 'Fz', 'Fp2', 'AF8', 'AF4', 'F8', 'F6', 'F4', 'F2'};...
    'FrontoCentralLeft', {'FC5', 'FC3', 'FC1'};...
    'FrontoCentralRight', {'FC6', 'FC4', 'FC2'};...
    'FrontoCentralTotal', {'FC5', 'FC3', 'FC1', 'FC6', 'FC4', 'FC2'};...
    'CentralLeft', {'C5', 'C3', 'C1'};...
    'CentralRight', {'C6', 'C4', 'C2'};...
    'CentralTotal', {'C5', 'C3', 'C1', 'Cz', 'C6', 'C4', 'C2'};...
    'CentroParietalLeft', {'CP5', 'CP3', 'CP1'};...
    'CentroParietalRight', {'CP6', 'CP4', 'CP2'};...
    'CentroParietalTotal', {'CP5', 'CP3', 'CP1', 'CPz', 'CP6', 'CP4', 'CP2'};...
    'TemporalLeft', {'FT7', 'FT9', 'T7', 'TP7', 'TP9'};...
    'TemporalRight', {'FT8', 'FT10', 'T8', 'TP8', 'TP10'};...
    'ParietalLeft', {'P7', 'P5', 'P3', 'P1'};...
    'ParietalRight', {'P8', 'P6', 'P4', 'P2'};...
    'ParietalTotal', {'P7', 'P5', 'P3', 'P1', 'Pz', 'P8', 'P6', 'P4', 'P2'};...
    'OccipitalLeft', {'PO7', 'PO3', 'O1'};...
    'OccipitalRight', {'PO8', 'PO4', 'O2'};...
    'OccipitalTotal', {'PO7', 'PO3', 'O1', 'POz', 'Oz', 'PO8', 'PO4', 'O2'}};

% -- define region combination method
if ~exist('joinmethod', 'var')
    joinmethod = 'add';
end

% -- define region list
if ~exist('CustomRegions','var')
    RegionList = RegionList_default;
else
    % -- combine default and custom regions
    if strcmp(joinmethod, 'add')
        RegionList = [RegionList_default; CustomRegions];
    elseif strcmp(joinmethod, 'replace')
        RegionList = CustomRegions;
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


%% -- calculate regional averages

k = 1;
while k <= size(x, 2)

    disp(['Computing epoch ', num2str(k), '/', num2str(size(x, 2))]);

    kR = 1;
    % -- initialize region matrix
    region = NaN(size(RegionList, 1), size(x(k).data, 2));
    while kR <= size(RegionList, 1)

        % -- extract channels for current region
        selected_ch = x(k).data(ismember(upper(x(k).data_rows), upper(RegionList{kR, 2})), :);

        % -- calculate regional average
        if size(selected_ch, 1) == size(RegionList{kR, 2}, 2) % in case that some ch is missing in input data region will not be calculated
            if log_flag
                % -- convert data to linear scale
                selected_ch = 10.^selected_ch;
                % -- average channels and return to log scale
                region(kR, :) = log10(mean(selected_ch, 1));
            else
                % -- average channels
                region(kR, :) = mean(selected_ch, 1);
            end
        else
            % -- report missing channels
            warning([RegionList{kR, 1} ' could not be calculated. It is not possible to extract all channels for defined region.']);
        end

        kR = kR + 1;

    end

    %% -- export data

    switch outmethod
        case 'add'
            x(k).data =  [x(k).data, region];
            x(k).data_rows = [x(k).data_rows, RegionList(:, 1)];
        case 'replace'
            x(k).data =  region;
            x(k).data_rows =  RegionList(:, 1);
    end

    k = k + 1;

end

end

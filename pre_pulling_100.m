% -------------------------------------------------------------------------
%  Project: IMONAS 2020
%  Task:    Pulling data 100% RMT - Data Extraction and Conversion from XDF Files
% -------------------------------------------------------------------------

% -- clear workspace, close all figures, and clear command window
clear all; close all; clc;

% -- initialize project settings and enable saving of results
pout = def_pro('IA100_22a', 'saveWork', false);

%% -- diary and load eeglab

if pout.saveWork
    % -- extract timestamp information from archive path
    time = strsplit(pout.archive_NIN_path, filesep);
    time = time{contains(time, 'NIN')};

    % -- create diary file for software version tracking
    diary([pout.archive_path, 'softare_version', strrep(time, 'NIN', ''), '.txt'])

    % -- display current MATLAB version
    disp(['Matlab ', version]);

    diary off
end

%% -- define input parameters

% -- main directory containing subject folders and XDF files
pout.path_main = '/mnt/data/data08/RawData/2019_JG_IMONAS_acute/';

% -- options passed to XDF loading function
pout.in_fetures = {'HandleClockSynchronization', false};

% -- base output directory
pout.path_out = '/mnt/data/data09/2026_IMONAS_MSK/data_out/Raw_2021_10_08/';

%% -- create data out folder

% -- generate current timestamp
ctime = nin_ctime;

% -- create timestamped output directory
pout.path_out = [pout.path_out, 'Raw_', ctime, filesep];
if ~exist(pout.path_out, 'dir') && pout.saveWork
    mkdir(pout.path_out);
end

%% -- read xdf data subject by subject

% -- get all folders from the main directory
folderList = dir(pout.path_main);
folderList = {folderList([folderList.isdir]).name};
folderList = folderList(~ismember(folderList, {'.', '..'}));

k = 1; c1 = 1;
while k <= length(folderList)

    % -- define current input path
    pout.path_in = [pout.path_main, folderList{k}, filesep];

    % -- get xdf files for current subject
    fileList = dir([pout.path_in '*IMONAS*.xdf' ]);
    fileList = {fileList.name};

    k2 = 1;
    while k2 <= length(fileList)

        % -- store input information
        x(c1).path_in =  pout.path_in;
        x(c1).filename_in = fileList{k2};
        x(c1).in_fetures = pout.in_fetures;

        % -- display processing status
        disp(['Loading file ', num2str(k2), '/', num2str(length(fileList)), ' in folder ', num2str(k), '/', num2str(length(folderList))]);

        try

            %% -- load xdf data

            rdata = nin_read_xdf(x(c1));

            %% -- export data

            % -- define output filename
            x(c1).path_out =  pout.path_out;
            x(c1).filename_out = [folderList{k}, '_', x(c1).filename_in, '.mat'];

            % -- save data to mat file
            if pout.saveWork
                save([x(c1).path_out, x(c1).filename_out], 'rdata', '-v7.3');
            end

            % -- mark successful processing
            x(c1).passed =  true;

        catch

            % -- mark failed processing
            x(c1).passed =  false;

        end

        % -- increment file counters
        c1 = c1 + 1;
        k2  = k2 + 1;

    end

    % -- increment folder counter
    k = k + 1;

end

%% -- save processing report

if pout.saveWork
    save([pout.path_out, 'transfer_report.mat'], 'x');
end

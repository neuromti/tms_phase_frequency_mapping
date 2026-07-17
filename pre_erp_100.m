% -------------------------------------------------------------------------
%  Project: IMONAS 2020
%  Task:    gather ERP 100% RMT
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

% -- define input directory
pout.path_in = ['/mnt/data/data09/2026_IMONAS_MSK/data_out/Epoched_', pout.pro_name, '/'];

% -- define output directory
pout.path_out = ['/mnt/data/data09/2026_IMONAS_MSK/data_out/ERP_', pout.pro_name, '/'];

%% -- create data out folder

if ~exist(pout.path_out, 'dir') && pout.saveWork
    mkdir(pout.path_out);
end

%% -- define analysis parameters

% -- enable mep-based epoch rejection
flag_MEP_rejection = true;

%% -- calculate erp data for each subject

% -- get input files
fileList = dir([pout.path_in '*.mat' ]);
fileList = {fileList.name};
fileList = fileList(~contains(fileList, 'analysis_report.mat'));

k = 1;
while k <= length(fileList)

    % -- define input file information
    x(k).path_in =  pout.path_in;
    x(k).filename_in = fileList{k};
    disp(['Loading file ', num2str(k), '/', num2str(length(fileList))]);

    try

        %% -- load data

        load([x(k).path_in, x(k).filename_in]);

        %% -- reject bad epochs - replace data with NaN

        [edata(~([edata.valid] & [edata.valid_cleaning] & [edata.valid_distance])).data] = deal(NaN(size(edata(1).data, 1), size(edata(1).data, 2)));
        [edata(~([edata.valid] & [edata.valid_cleaning] & [edata.valid_distance])).MEP_logVpp] = deal(NaN(1, 1));

        %% -- apply MEP rejection criterion

        if flag_MEP_rejection
            edata = edata(exp([edata.MEP_logVpp]) > 50);
        end

        %% -- calculate ERP by phase and frquency

        erp = nin_erp_gather(edata);

        %% -- calculate MEP by phase nad frequency

        MEPdata = struct('data', {edata.MEP_logVpp}, 'tfreq', {edata.tfreq}, 'tphase', {edata.tphase});
        [MEPdata.sub] = deal(edata(1).sub);
        [MEPdata.data_rows] = deal({'MEP_logVpp'});
        [MEPdata.data_columns] = deal({'MEP_logVpp'});
        [MEPdata.unit] = deal({'mV'});
        [MEPdata.time] = deal(edata(1).time);

        % -- aggregate mep data
        MEPdata = nin_erp_gather(MEPdata);

        % -- remove unnecessary fields
        MEPdata = rmfield(MEPdata, {'data_rows', 'data_columns', 'unit', 'N', 'n'});

        % -- rename statistical outputs
        MEPdata = struct('MEPdataMEAN', {MEPdata.dataMEAN}, 'MEPdataSTD', {MEPdata.dataSTD}, 'MEPdataSEM', {MEPdata.dataSEM}, 'tfreq', {MEPdata.tfreq}, 'tphase', {MEPdata.tphase}, 'sub', {MEPdata.sub});

        %% -- merge ERP and EMG data

        erp = nin_merge_structures(erp, MEPdata, {'tphase', 'tfreq'});

        %% -- add missing fields

        [erp.filename] = deal(edata(1).filename);
        [erp.filename_new] = deal(edata(1).filename);

        %% -- export data

        x(k).path_out =  pout.path_out;
        x(k).filename_out = strrep(x(k).filename_in, '.mat', '_ERP.mat');

        if pout.saveWork
            save([x(k).path_out, x(k).filename_out], 'erp', '-v7.3');
        end

        % -- store processing status
        x(k).passed =  true;
        x(k).comment =  '';

    catch

        % -- store processing error
        x(k).path_out =  '';
        x(k).filename_out = '';
        x(k).passed =  false;
        x(k).comment =  'error';

    end

    k  = k + 1;

end

%% -- save analysis report

if pout.saveWork
    save([pout.path_out, 'analysis_report.mat'], 'x');
end
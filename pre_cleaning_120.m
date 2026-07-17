% -------------------------------------------------------------------------
%  Project: IMONAS 2020
%  Task:    EEG cleaning data 120% RMT
% -------------------------------------------------------------------------

% -- clear workspace, close all figures, and clear command window
clear all; close all; clc;

% -- initialize project settings and enable saving of results
pout = def_pro('IA100_22a', 'saveWork', false, 'loadEEGLAB', true);

%% -- define EEG system

eegsys = nin_eeg_system('BrainVision');

%% -- load EEGLAB

if pout.loadEEGLAB

    eeglab;

    % -- get eeglab version information
    desktop = com.mathworks.mde.desk.MLDesktop.getInstance;
    cmdWindow = desktop.getClient('Command Window');
    cmdWindowScrollPane = cmdWindow.getComponent(0);
    cmdWindowScrollPaneViewport = cmdWindowScrollPane.getComponent(0);
    cmdTextUI = cmdWindowScrollPaneViewport.getComponent(0);
    cmdText = cmdTextUI.getText;
    EEGLABv = cmdText;
    clear desktop cmdWindow cmdWindowScrollPane cmdWindowScrollPaneViewport cmdTextUI cmdText

else

    % -- initialize empty eeglab version string
    EEGLABv = '';

end

%% -- define input parameters

% -- define input directory
pout.path_in = '/mnt/data/data09/FinalizedStudies/2026_IMONAS_MSK/Raw_2021_3_11/';

% -- define output directory
pout.path_out = '/mnt/data/data09/FinalizedStudies/2026_IMONAS_MSK/data_out/';

% -- define supplementary directory and file
pout.path_supplementary = '/mnt/data/data09/FinalizedStudies/2026_IMONAS_MSK/Supplementary/';
pout.TMS_file = 'acute_120_2_pdTEP_spreadsheet.csv';

%% -- create data out folder

% -- get current timestamp
ctime = nin_ctime;

% -- create timestamped output directory
pout.path_out = [pout.path_out, 'Cleaned_', pout.pro_name, filesep];
if ~exist(pout.path_out, 'dir') && pout.saveWork
    mkdir(pout.path_out);
end

%% - TMS pulses across subjects

% -- read supplementary spreadsheet and convet the into structure
T = readtable([pout.path_supplementary, pout.TMS_file]);
TMS = table2struct(T);

% -- extract simplified filenames
filename = {TMS.filename};
filename_new = nin_strsplit(filename, 'last');
[TMS.filename_new] = filename_new{:};

% -- rename fields
tvar = {TMS.Var1};
[TMS.id_event] = tvar{:};
tvar = {TMS.pulse_BV};
[TMS.stimuli] = tvar{:};
tvar = {TMS.logVpp};
[TMS.MEP_logVpp] = tvar{:};
tvar = {TMS.tarphase};
[TMS.tphase] = tvar{:};
tvar = {TMS.freq};
[TMS.tfreq] = tvar{:};
tvar = {TMS.recording};
[TMS.sub] = tvar{:};
% -- remove original fields
TMS = rmfield(TMS, {'Var1', 'pulse_BV', 'logVpp', 'tarphase', 'freq', 'recording', 'index'});

% -- sort fields
sfields = {'id_event', 'sub', 'stimuli', 'tfreq', 'tphase', 'valid', 'MEP_logVpp', 'filename', 'filename_new'};
TMS = orderfields(TMS, sfields);

% -- convert valid field to logical values
TMS = nin_function(TMS, {@(x) strcmpi(x, 'True')}, 'valid', '');

clear T filename filename_new tvar

%% -- cleaning data subject by subject

% -- get all folders from the main directory
fileList = dir([pout.path_in '*.mat' ]);
fileList = {fileList.name};
fileList = fileList(~contains(fileList, 'transfer_report.mat'));

% -- settings for cleaning function
musle_artifacts_features = {'compCheck', 'off',... %    'comps', 15, ...
    'figSize', 'small',...
    'plotTimeX', [-200 500],...
    'plotFreqX', [1 100],...
    'tmsMuscle', 'on',...
    'tmsMuscleThresh', 8,...
    'tmsMuscleWin', [11 30],...
    'tmsMuscleFeedback', 'off',...
    'blink', 'off',...
    'blinkThresh', 2.5,...
    'blinkElecs', {'Fp1','Fp2'},...
    'blinkFeedback', 'off',...
    'move', 'off',...
    'moveThresh', 2,...
    'moveElecs', {'F7','F8'},...
    'moveFeedback', 'off',...
    'muscle', 'off',...
    'muscleThresh', 0.6,...
    'muscleFreqWin', [30 100],...
    'muscleFreqIn', [31,100],...
    'muscleFeedback', 'off',...
    'elecNoise', 'off',...
    'elecNoiseThresh', 4,...
    'elecNoiseFeedback', 'off'};

tms_win = [-5 10];
tms_win_e = [-5 15];

newTMS = [];
k = 1;
while k <= length(fileList)

    x(k).path_in =  pout.path_in;
    x(k).filename_in = fileList{k};
    disp(['Loading file ', num2str(k), '/', num2str(length(fileList))]);

    try

        %% -- load data

        load([x(k).path_in, x(k).filename_in]);

        % -- initialize output structure
        cdata = rdata;

        % -- keep only valid eeg channels
        ix_ch = cell2mat(cellfun(@ischar, cdata.eeg.channels, 'un', 0));
        cdata.eeg.channels(~ix_ch) = {''};
        ix = ismember(cdata.eeg.channels, eegsys.channels);
        cdata.eeg.channels = cdata.eeg.channels(ix);
        cdata.eeg.unit = cdata.eeg.unit(ix);
        cdata.eeg.data = cdata.eeg.data(ix, :);

        %% -- clean data


        % -- subselect TMS data for current subject
        % -- define filename split positions
        sleft = 2;
        sright = 5;
        % -- get tms events for current recording
        cTMS = nin_subselect_dstruct(TMS, 'sub', char(nin_strsplit({x(k).filename_in}, 'first', [], 'spliter', '_')), 'filename_new', strrep(char(nin_strsplit({x(k).filename_in}, sleft, sright, 'spliter', '_')), '.mat', ''));

        if ~isempty(cTMS)

            %% -- get rid of duplicated pulses

            [C, ia, ic] = unique([cTMS.stimuli]);
            cTMS = cTMS(ia);

            %% -- remove closely spaced pulses

            epoch_distance = num2cell(true(1, length([cTMS.stimuli])));
            stimuli_th = 1000;
            diffs = diff([cTMS.stimuli]);
            ix_e = find(diffs < stimuli_th);
            ix_e = sort([ix_e, ix_e+1]);
            if ~isempty(ix_e)
                if any(ix_e(end) == length([cTMS.stimuli]) - 1)
                    ix_e = [ix_e, ix_e(end) + 1];
                end
            end
            epoch_distance(ix_e) = {false};
            cTMS(ix_e) = [];

            %% -- cleaning data using TESA

            [cdata.eeg, epoch_status, error_status, EEG_cleaned, ~, ME] = nin_cleaning_data_TESA(cdata.eeg, 'stimuli', [cTMS.stimuli], 'bad_epoch', ~[cTMS.valid],...
                'musle_artifacts_features', musle_artifacts_features,...
                'tms_win' , tms_win,...
                'tms_win_e', tms_win_e);
            epoch_status = num2cell(~epoch_status);
            [cTMS.valid_cleaning] = epoch_status{:};
            [cTMS.valid_distance] = epoch_distance{:};
            [cTMS.bad_channels] = deal(nnz(EEG_cleaned.etc.bad_ch.ch_removed));

            if strcmpi(EEG_cleaned.etc.TESAvers, 'TESA1.0.1') || strcmpi(EEG_cleaned.etc.TESAvers, 'TESA1.1.1')
                if isfield(EEG_cleaned.etc, 'TESA')
                    [cTMS.bad_componentsM] = deal(length(EEG_cleaned.etc.TESA.tmsMuscle));
                    [cTMS.bad_componentsO] = deal(length(EEG_cleaned.etc.TESA.eye) + ...
                        length(EEG_cleaned.etc.TESA.muscle) + ...
                        length(EEG_cleaned.etc.TESA.electrodeNoise) + ...
                        length(EEG_cleaned.etc.TESA.sensory) + ...
                        length(EEG_cleaned.etc.TESA.other));
                else
                    [cTMS.bad_componentsM] = deal(0);
                    [cTMS.bad_componentsO] = deal(0);
                end
            end
            newTMS = [newTMS; cTMS];


            %% -- export data

            % -- define output filename
            x(k).path_out =  pout.path_out;
            x(k).filename_out = strrep(x(k).filename_in, '.mat', '_cleaned.mat');

            % -- save cleaned data
            if pout.saveWork
                save([x(k).path_out, x(k).filename_out], 'cdata', '-v7.3');
            end

            % -- store processing status
            if strcmpi(error_status, '')

                x(k).passed =  true;
                x(k).comment =  '';

            else

                x(k).passed =  false;
                x(k).comment =  error_status;

            end

        else

            % -- store missing marker information
            x(k).path_out =  '';
            x(k).filename_out = '';
            x(k).passed =  false;
            x(k).comment =  'markers are missing';

        end

    catch

        % -- store processing error
        x(k).path_out =  '';
        x(k).filename_out = '';
        x(k).passed =  false;
        x(k).comment =  'error';

    end

    k  = k + 1;

end

% -- reorder tms fields
TMS = newTMS;
sfields = {'id_event', 'sub', 'stimuli', 'tfreq', 'tphase', 'valid', 'valid_cleaning', 'valid_distance', 'bad_channels', 'bad_componentsM', 'bad_componentsO', 'MEP_logVpp', 'filename', 'filename_new'};
TMS = orderfields(TMS, sfields);

% -- save tms results
if pout.saveWork
    save([pout.path_supplementary, strrep(pout.TMS_file, '.csv', ''), '_', pout.pro_name, '.mat'], 'TMS');
end

% -- save analysis report
if pout.saveWork
    save([pout.path_out, 'analysis_report.mat'], 'x', 'EEGLABv');
end
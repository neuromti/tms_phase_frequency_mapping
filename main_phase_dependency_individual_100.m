% -------------------------------------------------------------------------
%  Project: IMONAS 2020
%  Task:    Fitting data and extracting MD and OP 100% RMT - individual level
% -------------------------------------------------------------------------

% -- clear workspace, close all figures, and clear command window
clear all; close all; clc;

% -- initialize project settings and enable saving of results
pout = def_pro('IA100_22a', 'saveWork', false, 'loadEEGLAB', true);

%% -- diary and load eeglab

if pout.saveWork
    % -- extract timestamp information from archive path
    time = strsplit(pout.archive_NIN_path, filesep);
    time = time{contains(time, 'NIN')};

    % -- create diary file for software version tracking
    diary([pout.archive_path, 'softare_version', strrep(time, 'NIN', ''), '.txt'])

    % -- launch EEGLAB
    if pout.loadEEGLAB
        eeglab;
    end
    eegsys = nin_eeg_system('BrainVision');

    % -- display current MATLAB version
    disp(['Matlab ', version]);

    diary off
end

%% -- define input parameters

% -- define input directory
pout.path_in = ['/mnt/data/data09/FinalizedStudies/2026_IMONAS_MSK/data_out/ERP_', pout.pro_name, '/'];

% -- define output directory
pout.path_out = ['/mnt/data/data09/FinalizedStudies/2026_IMONAS_MSK/data_results/', pout.function_name, '_', pout.pro_name, '_', nin_ctime, '/'];

% -- define gateway directory
pout.path_gateway = '';

% -- define supplementary directory and filename
pout.path_supplementary = '/mnt/data/data09/FinalizedStudies/2026_IMONAS_MSK/Supplementary/';
pout.TMS_file = ['acute_100_pdTEP_spreadsheet_', pout.pro_name, '.mat'];


%% -- create data out folder

% -- define output path
if ~exist(pout.path_out, 'dir') && pout.saveWork
    mkdir(pout.path_out);
end

%% -- load supplementary

load([pout.path_supplementary, pout.TMS_file]);

%% -- load data session by session

% -- get all ERP files from input directory
fileList = dir([pout.path_in '*.mat' ]);
fileList = {fileList.name};
fileList = fileList(~contains(fileList, 'analysis_report.mat'));

%% -- remove redundant data

session = {'JuGe_IMONAS-acute-study-intervention_R001.xdf_cleaned_epoched_ERP.mat'};
fileList = fileList(~contains(fileList, session));

flag_topo = false;
flag_clu = true;
flag_save_fit = true;

clu_all = [];
fit_all = [];
fit_all_rest = [];
kl = 1;
while kl <= length(fileList)

    x(kl).path_in =  pout.path_in;
    x(kl).filename_in = fileList{kl};
    disp(['Loading file ', num2str(kl), '\', num2str(length(fileList))]);


    %% -- load data

    load([x(kl).path_in, x(kl).filename_in]);

    %% -- remove unnecessary fields to reduce memory usage

    terp = rmfield(erp, {'dataSTD', 'dataSEM'});

    %% -- add metadata fields

    % -- visit
    [terp.visit] = deal(1);

    % -- subject
    sub = nin_strsplit({terp.sub}, 'first', [], 'spliter', '0');
    [terp.sub] = sub{:};

    % -- attempt
    iter = nin_strsplit({terp.filename_new}, 'last', [], 'spliter', '_');
    iter = strrep(nin_strsplit(iter, 'last', [], 'spliter', '0'), '.xdf', '');
    iter = cellfun(@str2num, iter, 'un', 0);
    [terp.iter] = iter{:};

    % -- assign all records to a single group
    [terp.group] = deal('all');

    % -- combine frequency and phase into a condition label
    cfreq = {terp.tfreq};
    cphase = {terp.tphase};
    condition = strcat(cfreq, 'Hz_', cphase, 'deg');
    [terp.condition] = condition{:};

    % -- reorganize ERP data structure
    cdata = {terp.dataMEAN};
    [terp.data] = cdata{:};
    terp = rmfield(terp, 'dataMEAN');
    [terp.time] = deal(cell2mat(cellfun(@str2num, terp(1).data_columns, 'un', 0)));

    clear sub visit iter cdata erp

    %% -- remove all sessions that have less than 50% of total no of stimuli (20*0.5) per phase and freq

    s_th = 10;
    terp = terp([terp.N] >= s_th);

    if ~isempty(terp)

        %% -- sessions which have less than 40% of total no of stimuli (0.4*1600)

        s_th = 0.4*1600;

        % -- combine all frequency and phase conditions per subject
        cdata = nin_subselect_dstruct(terp, 'tphase', 'all', 'tfreq', 'all');
        originalsub = cdata;

        % -- identify subjects below threshold
        sub = {cdata([cdata.N] < s_th).sub};
        visit = [cdata([cdata.N] < s_th).visit];

        keep_r = true(1, length(terp));
        k = 1;
        while k <= length(sub)

            keep_r = keep_r & ~(strcmpi({terp.sub}, sub{k}) & [terp.visit] == visit(k));

            k = k + 1;

        end

        % -- keep only valid sessions
        terp = terp(keep_r);

        %% -- calculate grand ERP for each phase-frequency combination

        % -- exclude subjects with phases outside the target range
        keep_phase = cellfun(@num2str, num2cell(0:45:315), 'un', 0);
        keep_r = false(1, length(terp));
        k = 1;
        while k <= length(terp)

            if any(strcmpi(keep_phase, terp(k).tphase))
                keep_r(k) = true;
            end

            k = k + 1;

        end
        terp = terp(keep_r);

        % -- remove empty entries
        terp = terp([terp.n] ~= 0);

        % -- remove 'all' frequency condition
        terp = terp(~contains({terp.tfreq}, 'all'));

        if ~isempty(terp)

            % -- keep ERP time window of interest
            keep_time = -100:400;
            [~, ix, ~] = intersect(cell2mat(cellfun(@str2num, terp(1).data_columns, 'un', 0)), keep_time);

            % -- reduce grand ERP data to selected time window
            terp = nin_function(terp, @(x) x(:, ix), 'data', 'data');
            data_columns = terp(1).data_columns(ix);
            [terp.data_columns] = deal(data_columns);

            % -- make a list of unique phase and freq
            ufreq = cellfun(@num2str, num2cell(4:4:40), 'un', 0);
            uphase = cellfun(@num2str, num2cell(0:45:315), 'un', 0);

            % -- perform sanity check
            sanity = [];
            k1 = 1;
            while k1 <= length(ufreq)

                k2 = 1;
                while k2 <= length(uphase)

                    % -- extract data for current frequency-phase combination
                    cdata = nin_subselect_dstruct(terp, 'tfreq', ufreq{k1}, 'tphase', uphase{k2});

                    % -- keep relevant metadata only
                    cdata = nin_subselect_fields(cdata, {'sub', 'visit', 'iter', 'N', 'n', 'tfreq', 'tphase'});

                    % -- standardize field order
                    cdata = orderfields(cdata, {'sub', 'visit', 'iter', 'N', 'n', 'tfreq', 'tphase'});

                    % -- append to sanity-check structure
                    sanity = [sanity, cdata];

                    k2 = k2 + 1;

                end

                k1 = k1 + 1;

            end

            % -- keep only frequencies with a complete phase set
            terp_last = terp;
            terp = [];
            sanity = [];
            k1 = 1;
            while k1 <= length(ufreq)

                % -- select data for current frequency
                cdata = nin_subselect_dstruct(terp_last, 'tfreq', ufreq{k1});

                % -- keep frequency only if all phases are present
                if size(cdata, 2) == length(uphase)
                    terp = [terp, cdata];
                end

                k1 = k1 + 1;

            end

            if ~isempty(terp)


                %% -- calculate TEP

                % -- peaks of interest
                npeaks = {'P25', 'N45', 'P70', 'N100', 'P180'};
                crange_top = {[-5 5], [-5  5], [-5 5], [-5 5], [-5 5]};
                crange_clu = {[-15 15], [-15  15], [-15 15], [-15 15], [-15 15]};

                % -- estimate peaks/TEP
                epeak = nin_erp_measure(terp, 'peak');

                %% -- prepare peak data for phase- and frequency-specific analysis

                % -- keep amplitude measures only
                epeak_mod = epeak;
                ix = contains(epeak_mod(1).data_columns, '_amp');

                % -- keep only frequency- and phase-specific conditions
                k1 = 1;
                while k1 <= size(epeak_mod, 2)

                    % -- select amplitude data and corresponding labels
                    epeak_mod(k1).data = epeak_mod(k1).data(:, ix, :);
                    epeak_mod(k1).data_columns = epeak_mod(k1).data_columns(ix);

                    k1 = k1 +1;

                end

                % -- group data by subject
                epeak_group = nin_group_data(epeak_mod, {'data'}, {'sub'});

                % -- preserve channel and peak labels
                [epeak_group.data_rows] = deal(epeak_mod(1).data_rows);
                [epeak_group.data_columns] = deal(epeak_mod(1).data_columns);

                % -- calculate number of sessions per subject
                epeak_group = nin_function(epeak_group, @(x) size(x, 3), {'data'}, {'N'});

                % -- calculate number of valid observations
                epeak_group = nin_function(epeak_group, @(x) sum(any(~isnan(x), 1), 3), {'data'}, {'n'});

                % -- average peak amplitudes across sessions
                epeak_group = nin_function(epeak_group, @(x) nanmean(x, 3), {'data'}, {'data'});

                if epeak_group.n ~= 0

                    %% -- TEP topoplots

                    if flag_topo

                        % -- create output directory
                        pout.path_out_subfolder = [pout.path_out, 'Topo per session\'];
                        if ~exist(pout.path_out_subfolder, 'dir') && pout.saveWork
                            mkdir(pout.path_out_subfolder);
                        end

                        % -- plot peak amplitude topographies
                        h = nin_topoplot(epeak_group, [], 'scolumns', strcat(npeaks, '_amp'), 'crange', crange_top);

                        % -- save figures
                        kh = 1;
                        while kh <= length(h)

                            set(0, 'CurrentFigure', h(kh));
                            text(0.5, 0, ['sub: ', epeak_mod(1).sub, ' ', num2str(epeak_mod(1).visit), ', N: ', num2str(epeak_mod(1).N), ', n: ', num2str(epeak_mod(1).n)], 'fontsize', 10, 'fontweight', 'bold', 'interpreter', 'none', 'units', 'normalized', 'HorizontalAlignment', 'center');

                            if pout.saveWork && flag_topo

                                output_path = pout.path_out_subfolder;
                                pout.fielname_out = [epeak_mod(1).sub, '_', num2str(epeak_mod(1).visit), '_', get(h(kh), 'Name')];
                                export_fig(h(kh), [output_path, pout.fielname_out, '.png'], '-png');

                            end

                            kh = kh + 1;

                        end

                        % -- close figures
                        kh = 1;
                        while kh <= length(h)

                            close(h(kh));

                            kh = kh + 1;

                        end
                        clear h

                    end

                    %% -- calculate observed t-statistics

                    % -- perform one-sample t-tests
                    z = nin_ttest(epeak_mod);

                    ks = 1;
                    while ks <= size(z, 2)

                        % -- store t-values and p-values
                        stat_o.data(:, ks) = z(ks).t';
                        stat_o.p(:, ks) = z(ks).p';

                        ks = ks + 1;

                    end

                    % -- store metadata
                    stat_o.data_rows = epeak_mod.data_rows;
                    stat_o.data_columns = strrep({z.name}, '_amp', '_t');
                    [stat_o.iter] = deal(0);

                    %% -- generate permutation-based null distribution

                    % -- number of permutations and initialize random seed for reproducibility
                    n_perm = 1000;
                    rng(1, 'twister');

                    % -- create mask defining permuted samples
                    zdata = false(size(epeak_mod(1).data, 1), size(epeak_mod(1).data, 2));
                    zdata(size(epeak_mod(1).data, 1)\2 + 1:end, :) = true;
                    stat_p = [];
                    kp = 1;
                    while kp <= n_perm

                        cstat_p = [];

                        % -- copy observed data
                        sepeak_mod = epeak_mod;
                        sepeak_zero = sepeak_mod;

                        % -- initialize null data
                        [sepeak_zero.data] = deal(zeros(size(sepeak_zero(1).data, 1), size(sepeak_zero(1).data, 2)));

                        ks = 1;
                        while ks <= size(sepeak_mod, 2)

                            % -- randomly assign data points to observed and null groups
                            ix = reshape(randperm(size(sepeak_zero(1).data, 1) * size(sepeak_zero(1).data, 2)), size(sepeak_zero(1).data, 1), size(sepeak_zero(1).data, 2));
                            sepeak_zero(ks).data(zdata(ix)) = sepeak_mod(ks).data(zdata(ix));
                            sepeak_mod(ks).data(zdata(ix)) = 0;

                            ks = ks + 1;

                        end

                        % -- calculate permutation t-statistics
                        z = nin_ttest(sepeak_mod, sepeak_zero);

                        ks = 1;
                        while ks <= size(z, 2)

                            % -- store permutation t-values and p-values
                            mz.data(:, ks) = z(ks).t';
                            mz.p(:, ks) = z(ks).p';

                            ks = ks + 1;

                        end

                        % -- store metadata
                        mz.data_rows = epeak_mod.data_rows;
                        mz.data_columns = strrep({z.name}, '_amp', '_t');
                        cstat_p = [cstat_p, mz];
                        clear mz
                        [cstat_p.iter] = deal(kp);

                        % -- append permutation result
                        stat_p = [stat_p, cstat_p];

                        kp = kp + 1;

                    end

                    %% -- perform cluster-based permutation analysis

                    % -- assign condition label required for clustering
                    stat_o.freq = 'all';
                    [stat_p.freq] = deal('all');

                    % -- identify significant spatial clusters
                    clu = nin_clustering(stat_o, stat_p, 'condition', {'freq', {'all'}}, 'f', {@(a, b) a > b, @(a, b) a > b, @(a, b) a > b, @(a, b) a > b, @(a, b) a > b}, 'c_th', {11, 5, 9, 6, 5}, 'method', 'sum');

                    if flag_clu

                        % -- save and visualize cluster results
                        pout.path_out_subfolder = [pout.path_out, 'clustered data\'];
                        if ~exist(pout.path_out_subfolder, 'dir') && pout.saveWork
                            mkdir(pout.path_out_subfolder);
                        end

                        % -- identify significant spatial clusters
                        h = nin_topoplot(clu, clu, 'map_style', 'pmask', 'crange', crange_clu);

                        % -- save figures
                        k1 = 1;
                        while k1 <= length(h)

                            if pout.saveWork

                                set(0, 'CurrentFigure', h(k1));
                                pout.fielname_out = [epeak_mod(1).sub, '_', num2str(epeak_mod(1).visit), '_', get(h(k1), 'Name')];
                                %                     saveas(h(k1), [pout.path_out_subfolder, pout.fielname_out, '.fig']);
                                export_fig(h(k1), [pout.path_out_subfolder, pout.fielname_out, '.png'], '-png');

                            end

                            k1 = k1 + 1;

                        end

                        % -- close figures
                        k1 = 1;
                        while k1 <= length(h)

                            close(h(k1));

                            k1 = k1 + 1;

                        end
                        clear h

                    end

                    %% -- extract clustered channels

                    % -- identify significant channels for each peak
                    common_ch = [];
                    kc = 1;
                    while kc <= length(clu.data_columns)

                        common_ch = [common_ch, {clu.data_rows(logical(clu.mask(:, kc)))}];

                        kc = kc +1 ;

                    end

                    %% -- average peak amplitudes across clustered channels

                    P25o = nin_ch2regions(epeak_mod, 'joinmethod', 'replace', 'CustomRegions', {'Clustered', common_ch{1}});
                    N45o = nin_ch2regions(epeak_mod, 'joinmethod', 'replace', 'CustomRegions', {'Clustered', common_ch{2}});
                    P70o = nin_ch2regions(epeak_mod, 'joinmethod', 'replace', 'CustomRegions', {'Clustered', common_ch{3}});
                    N100o = nin_ch2regions(epeak_mod, 'joinmethod', 'replace', 'CustomRegions', {'Clustered', common_ch{4}});
                    P180o = nin_ch2regions(epeak_mod, 'joinmethod', 'replace', 'CustomRegions', {'Clustered', common_ch{5}});

                    % -- reorganize clustered peak amplitudes
                    clu_erp = [];
                    kf = 1;
                    while kf <= length(ufreq)

                        kp = 1;
                        while kp <= length(uphase)

                            % -- extract data for current subject, visit, frequency and phase
                            cP25 = nin_subselect_dstruct(P25o, 'tfreq', ufreq{kf}, 'tphase', uphase{kp});
                            cN45= nin_subselect_dstruct(N45o, 'tfreq', ufreq{kf}, 'tphase', uphase{kp});
                            cP70 = nin_subselect_dstruct(P70o, 'tfreq', ufreq{kf}, 'tphase', uphase{kp});
                            cN100 = nin_subselect_dstruct(N100o, 'tfreq', ufreq{kf}, 'tphase', uphase{kp});
                            cP180 = nin_subselect_dstruct(P180o, 'tfreq', ufreq{kf}, 'tphase', uphase{kp});

                            if size(cP25, 2) ~= 0

                                % -- keep entry with the highest number of valid observations
                                if size(cP25, 2) > 1
                                    [~, ix_max] = max([cP25.n]);
                                    cP25 = cP25(ix_max);
                                    cN45 = cN45(ix_max);
                                    cP70 = cP70(ix_max);
                                    cN100 = cN100(ix_max);
                                    cP180 = cP180(ix_max);
                                end

                                % -- combine clustered peak amplitudes into a single data vector
                                cp = cP25;
                                cp.data(1, :) = [cP25.data(1, 1), cN45.data(1, 2), cP70.data(1, 3), cN100.data(1, 4), cP180.data(1, 5)];

                                % -- append to output structure
                                clu_erp = [clu_erp, cp];

                                clear cp

                            end

                            kp = kp + 1;

                        end

                        kf = kf + 1;

                    end

                    clu_erp_orig = clu_erp;

                    %% -- z-score peak amplitudes within subject and frequency

                    % -- calculate subject-specific mean and standard deviation
                    clu_tep_zsc = nin_group_data(clu_erp, {'data'}, {'tfreq', 'sub'});
                    clu_tep_zsc = nin_function(clu_tep_zsc, @(x) nanstd(x, 1), {'data'}, {'std'});
                    clu_tep_zsc = nin_function(clu_tep_zsc, @(x) nanmean(x, 1), {'data'}, {'mean'});

                    % -- keep normalization parameters only
                    clu_tep_zsc = rmfield(clu_tep_zsc, {'data'});

                    % -- merge normalization parameters with original data
                    clu_tep_zsc = nin_merge_structures(clu_erp, clu_tep_zsc,{'tfreq', 'sub'});

                    % -- apply z-score normalization
                    for kf = 1:size(clu_tep_zsc, 2)

                        clu_tep_zsc(kf).data = (clu_tep_zsc(kf).data-clu_tep_zsc(kf).mean)./clu_tep_zsc(kf).std;

                    end

                    % -- reorganize data by frequency
                    clu_tep = nin_group_data(clu_tep_zsc, {'data'}, {'tfreq'});
                    kf = 1;
                    while kf <= length(ufreq)

                        % -- create phase-specific row labels
                        if any(strcmpi({clu_tep.tfreq}, ufreq{kf}))
                            clu_tep(strcmpi({clu_tep.tfreq}, ufreq{kf})).data_rows = strcat(clu_erp(1).data_rows, ufreq{kf}, 'Hz', uphase, 'deg');
                        end

                        kf = kf + 1;

                    end

                    % -- preserve peak labels
                    [clu_tep.data_columns] = deal(clu_erp(1).data_columns);
                    clu_erp = clu_tep;

                    % -- sort frequencies in ascending order
                    [~, ix_f] = sort(cell2mat(cellfun(@str2num, {clu_erp.tfreq}, 'un', 0))); % sort freq
                    clu_erp = clu_erp(ix_f);

                    %% -- fit cosine model

                    if flag_save_fit

                        % -- create output directory for fit results
                        pout.path_out_subfolder = [pout.path_out, 'fit Clustered\', epeak_mod(1).sub, '_', num2str(epeak_mod(1).visit), '\'];
                        if ~exist(pout.path_out_subfolder, 'dir') && pout.saveWork
                            mkdir(pout.path_out_subfolder);
                        end

                    end

                    % -- invert negative peaks to align modulation direction
                    s = -2*contains(clu_erp(1).data_columns, 'N') + 1;
                    clu_erp_fit = nin_function(clu_erp, @(x) s.*x, {'data'}, {'data'});

                    % -- update peak labels after inversion
                    [clu_erp_fit.data_columns] = deal(strrep(clu_erp(1).data_columns, 'N', 'invN'));

                    % -- fit modulation separately for each frequency
                    k1 = 1;
                    while k1 <= length(ufreq)

                        cf = strcat('Clustered', ufreq{k1}, 'Hz');

                        if ~isempty(clu_erp_fit(strcmpi({clu_erp_fit.tfreq}, ufreq{k1})))
                            % -- fit sinusoidal modulation across phases
                            [h, y] = nin_fitplots(clu_erp_fit(strcmpi({clu_erp_fit.tfreq}, ufreq{k1})), 'crange', [],...
                                'cylabel', ['Clustered - ', ufreq{k1}, 'Hz (\muV)'],...
                                'cxlabel', 'Phase (deg)',...
                                'crange', [-3 3],...
                                'shift_data', false,...
                                'disp_status', flag_save_fit);

                            % -- extract fit parameters
                            tamp = cellfun(@(x) x', {y.oval}, 'un', 0);

                            % -- extract surrogate fit parameters
                            samp = cellfun(@(x) x', {y.pval}, 'un', 0);
                            g = [y.goodness];

                            % -- store fit results for current frequency
                            yy = struct('name', {y.name}, 'p', {y.p}, 'sse', {g.sse}, 'rsquare', {g.rsquare}, 'dfe', {g.dfe}, 'adjrsquare', {g.adjrsquare}, 'rmse', {g.rmse});
                            [yy.sub] =  deal(epeak_mod(1).sub);
                            [yy.visit] =  deal(epeak_mod(1).visit);
                            [yy.iter] =  deal(epeak_mod(1).iter);
                            [yy.tfreq] = deal(ufreq{k1});
                            [yy.data] = tamp{:};
                            [yy.data_surogat] = samp{:};
                            [yy.data_rows] = deal(y(1).oval_name);
                            ccol = strrep({y.name}, '_amp', '');
                            [yy.data_columns] = ccol{:};
                            fit_all = [fit_all, yy];

                            clear yy g

                            if flag_save_fit

                                % -- save fit figures
                                k2 = 1;
                                while k2 <= length(h)

                                    if pout.saveWork

                                        set(0, 'CurrentFigure', h(k2));
                                        pout.fielname_out = ['freq_', ufreq{k1} ,'_Clustered_', get(h(k2), 'Name')];
                                        export_fig(h(k2), [pout.path_out_subfolder, pout.fielname_out, '.png'], '-png');

                                    end

                                    k2 = k2 + 1;

                                end

                                % -- close fit figures
                                k2 = 1;
                                while k2 <= length(h)

                                    close(h(k2));

                                    k2 = k2 + 1;

                                end
                                clear h

                            end

                        end

                        k1 = k1 + 1;

                    end

                    [clu.sub] = epeak_mod(1).sub;
                    [clu.visit] = epeak_mod(1).visit;

                    clu_all = [clu_all, clu];

                end

            end

        end

    end

    kl = kl + 1;

end

%% -- prepare fit results for export

% -- extract field names
fit_all_c = fieldnames(fit_all)';
k = 1;
while k <= size(fit_all, 2)

    % -- append structure contents
    fit_all_c = [fit_all_c; struct2cell(fit_all(k))'];

    k = k + 1;

end

% -- transpose p-values for consistency
fit_all = nin_function(fit_all, @(x) x', {'p'}, {'p'});

%% -- save clustering and fitting results

if pout.saveWork

    save([pout.path_out, 'clustered_data.mat'], 'clu_all', 'fit_all', '-v7.3');

end
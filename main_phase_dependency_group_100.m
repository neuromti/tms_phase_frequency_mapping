% -------------------------------------------------------------------------
%  Project: IMONAS 2020
%  Task:    Fitting data and extracting MD and OP 100% RMT - group level
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
pout.path_gateway = '/mnt/data/data09/FinalizedStudies/2026_IMONAS_MSK/data_out/gateway/';

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

try

    % -- load previously compiled ERP dataset
    load([pout.path_gateway, 'ERP_', pout.pro_name, '.mat']);

catch

    % -- get all ERP files from input directory
    fileList = dir([pout.path_in '*.mat' ]);
    fileList = {fileList.name};
    fileList = fileList(~contains(fileList, 'analysis_report.mat'));

    terp = [];
    k = 1;
    while k <= length(fileList)

        % -- store file information
        x(k).path_in =  pout.path_in;
        x(k).filename_in = fileList{k};
        disp(['Loading file ', num2str(k), '\', num2str(length(fileList))]);


        %% -- load data

        load([x(k).path_in, x(k).filename_in]);

        %% -- remove unnecessary fields to reduce memory usage

        erp = rmfield(erp, {'dataSTD', 'dataSEM'});

        %% -- append ERP structure to combined dataset

        terp = [terp, erp];

        k  = k + 1;

    end

    disp('Loading completed.');

    clear edata

    %% -- add metadata fields

    % -- visit
    visit = nin_strsplit({terp.sub}, 'last', [], 'spliter', '0');
    visit = cellfun(@str2num, visit, 'un', 0);
    [terp.visit] = visit{:};

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

    % -- reorganize ERP data structure
    cdata = {terp.dataMEAN};
    [terp.data] = cdata{:};
    terp = rmfield(terp, 'dataMEAN');
    [terp.time] = deal(cell2mat(cellfun(@str2num, terp(1).data_columns, 'un', 0)));

    clear sub visit iter cdata

    %% -- save compiled ERP dataset

    if pout.saveWork
        save([pout.path_gateway, 'ERP_', pout.pro_name, '.mat'], 'terp', '-v7.3');
    end

end

% -- keep original ERP dataset
terp_o = terp;

%% -- remove redundant data

% -- assign all records to the same visit
[terp.visit] = deal(1);

% -- remove duplicate entries based on subject, visit, frequency and phase
terp = nin_session_exclusion(terp, {'sub', 'visit', 'tfreq', 'tphase'});

%% -- remove all sessions that have less than 50% of total no of stimuli (20*0.5) per phase and freq

s_th = 10;
terp = terp([terp.N] >= s_th);

%% -- remove redudant subjects or subjects

sub = {'JuGe'};
iter = 1;
ixr = ~(contains({terp.sub}, sub) & [terp.iter] == iter);
terp = terp(~(contains({terp.sub}, sub) & [terp.iter] == iter));

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

cdata = nin_subselect_dstruct(terp, 'tfreq', 'all', 'tphase', 'all');
sub = unique({cdata.sub});
n_sub = length(sub);
visit = cellfun(@num2str, num2cell(unique([cdata.visit])), 'un', 0);

% -- exclude subjects with phases outside the target range
keep_phase = 0:45:315;

% -- calculate grand ERP for each frequency-phase combination
gerp = nin_erp_gather(terp, 'group_keys', {'group'}, 'fphase', keep_phase, 'out_method', 'original');

% -- create condition labels
cfreq = {gerp.tfreq};
cphase = {gerp.tphase};
condition = strcat(cfreq, 'Hz_', cphase, 'deg');
[gerp.condition] = condition{:};

% -- calculate grand ERP collapsed across frequencies
gerpALL = nin_erp_gather(terp, 'group_keys', {'group'}, 'fphase', keep_phase, 'out_method', 'const_freq');

% -- create condition labels
cfreq = {gerpALL.tfreq};
cphase = {gerpALL.tphase};
condition = strcat(cfreq, 'Hz_', cphase, 'deg');
[gerpALL.condition] = condition{:};

% -- combine frequency-specific and pooled grand ERPs
gerp = [gerp; gerpALL];

% -- keep ERP time window of interest
keep_time = -100:400;
[~, ix, ~] = intersect(cell2mat(cellfun(@str2num, gerp(1).data_columns, 'un', 0)), keep_time);

% -- reduce grand ERP data to selected time window
gerp_red = nin_function(gerp, @(x) x(:, ix), 'dataMEAN', 'data');
data_columns = gerp_red(1).data_columns(ix);
[gerp_red.data_columns] = deal(data_columns);

% -- reduce pooled grand ERP data to selected time window
gerpALL_red = nin_function(gerpALL, @(x) x(:, ix), 'dataMEAN', 'data');
data_columns = gerpALL_red(1).data_columns(ix);
[gerpALL_red.data_columns] = deal(data_columns);

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

%% -- calculate TEP

% -- peaks of interest
npeaks = {'P25', 'N45', 'P70', 'N100', 'P180'};
crange_top = {[-5 5], [-5  5], [-5 5], [-5 5], [-5 5]};
crange_clu = {[-10 10], [-10  10], [-10 10], [-10 10], [-10 10]};

% -- estimate peaks/TEP
epeak = nin_erp_measure(terp, 'peak');

% -- save data of tep
if pout.saveWork

    save([pout.path_gateway, 'TEP_', pout.pro_name, '.mat'], 'epeak', '-v7.3');

end

%% -- prepare peak data for phase- and frequency-specific analysis

% -- keep only frequency- and phase-specific conditions
epeak_mod = epeak(~strcmpi({epeak.tfreq}, 'all'));
epeak_mod = epeak_mod(~strcmpi({epeak_mod.tphase}, 'all'));

% -- keep amplitude measures only
ix = contains(epeak_mod(1).data_columns, '_amp');

k1 = 1;
while k1 <= size(epeak_mod, 2)

    % -- select amplitude data and corresponding labels
    epeak_mod(k1).data = epeak_mod(k1).data(:, ix, :);
    epeak_mod(k1).data_columns = epeak_mod(k1).data_columns(ix);

    k1 = k1 +1;

end

% -- group data by subject and visit
cpeak_group = nin_group_data(epeak_mod, {'data'}, {'sub', 'visit'});

% -- preserve channel and peak labels
[cpeak_group.data_rows] = deal(epeak_mod(1).data_rows);
[cpeak_group.data_columns] = deal(epeak_mod(1).data_columns);

% -- calculate number of sessions per subject
cpeak_group = nin_function(cpeak_group, @(x) size(x, 3), {'data'}, {'N'});

% -- calculate number of valid observations
cpeak_group = nin_function(cpeak_group, @(x) sum(any(~isnan(x), 1), 3), {'data'}, {'n'});

% -- average peak amplitudes across sessions
cpeak_avg_o = nin_function(cpeak_group, @(x) nanmean(x, 3), {'data'}, {'data'});

%% -- calculate observed t-statistics

stat_o = [];

% -- perform one-sample t-tests
z = nin_ttest(cpeak_avg_o);

ks = 1;
while ks <= size(z, 2)

    % -- store t-values and p-values
    stat_o.data(:, ks) = z(ks).t';
    stat_o.p(:, ks) = z(ks).p';

    ks = ks + 1;

end

% -- store metadata
stat_o.data_rows = cpeak_avg_o.data_rows;
stat_o.data_columns = strrep({z.name}, '_amp', '_t');
[stat_o.iter] = deal(0);

%% -- generate permutation-based null distribution

% -- number of permutations and initialize random seed for reproducibility
n_perm = 1000;
rng(1, 'twister');

% -- create mask defining permuted samples
zdata = false(size(cpeak_avg_o(1).data, 1), size(cpeak_avg_o(1).data, 2));
zdata(size(cpeak_avg_o(1).data, 1)\2 + 1:end, :) = true;
stat_p = [];
kp = 1;
while kp <= n_perm

    cstat_p = [];

    % -- copy observed data
    sepeak_mod = cpeak_avg_o;
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
    mz.data_rows = cpeak_avg_o.data_rows;
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
clu = nin_clustering(stat_o, stat_p, 'condition', {'freq', {'all'}}, 'f', {@(a, b) a > b, @(a, b) a > b, @(a, b) a > b, @(a, b) a > b, @(a, b) a > b}, 'c_th', {3, 4, 2, 4, 2}, 'method', 'sum');

% -- save and visualize cluster results
pout.path_out_subfolder = [pout.path_out, 'clustered data\'];
if ~exist(pout.path_out_subfolder, 'dir') && pout.saveWork
    mkdir(pout.path_out_subfolder);
end

% -- save clustering results
if pout.saveWork

    save([pout.path_out_subfolder, 'clustered_data.mat'], 'clu', '-v7.3');

end

% -- generate topographical cluster maps
h = nin_topoplot(clu, clu, 'map_style', 'pmask', 'crange', crange_clu);

% -- save figures
k1 = 1;
while k1 <= length(h)

    if pout.saveWork

        set(0, 'CurrentFigure', h(k1));
        pout.fielname_out = get(h(k1), 'Name');
        saveas(h(k1), [pout.path_out_subfolder, pout.fielname_out, '.fig']);
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
ks = 1;
while ks <= length(sub)

    kv = 1;
    while kv <= length(visit)

        kf = 1;
        while kf <= length(ufreq)

            kp = 1;
            while kp <= length(uphase)

                % -- extract data for current subject, visit, frequency and phase
                cP25 = nin_subselect_dstruct(P25o, 'sub', sub{ks}, 'visit', visit{kv}, 'tfreq', ufreq{kf}, 'tphase', uphase{kp});
                cN45= nin_subselect_dstruct(N45o, 'sub', sub{ks}, 'visit', visit{kv}, 'tfreq', ufreq{kf}, 'tphase', uphase{kp});
                cP70 = nin_subselect_dstruct(P70o, 'sub', sub{ks}, 'visit', visit{kv}, 'tfreq', ufreq{kf}, 'tphase', uphase{kp});
                cN100 = nin_subselect_dstruct(N100o, 'sub', sub{ks}, 'visit', visit{kv}, 'tfreq', ufreq{kf}, 'tphase', uphase{kp});
                cP180 = nin_subselect_dstruct(P180o, 'sub', sub{ks}, 'visit', visit{kv}, 'tfreq', ufreq{kf}, 'tphase', uphase{kp});

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

        kv = kv + 1;

    end

    ks = ks + 1;

end

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

% -- average normalized data across subjects
clu_tep = nin_group_data(clu_tep_zsc, {'data'}, {'tfreq', 'tphase'});
[clu_tep.data_rows] = deal(clu_erp(1).data_rows);
[clu_tep.data_columns] = deal(clu_erp(1).data_columns);
clu_tep = nin_function(clu_tep, @(x) size(x, 1), {'data'}, {'N'});
clu_tep = nin_function(clu_tep, @(x) sum(~isnan(x), 1), {'data'}, {'n'});
clu_tep = nin_function(clu_tep, @(x) nanmean(x, 1), {'data'}, {'data'});

% -- reorganize data by frequency
clu_tep_new = nin_group_data(clu_tep, {'data'}, {'tfreq'});
kf = 1;
while kf <= length(ufreq)

    % -- create phase-specific row labels
    clu_tep_new(strcmpi({clu_tep_new.tfreq}, ufreq{kf})).data_rows = strcat(clu_tep(1).data_rows, ufreq{kf}, 'Hz', uphase, 'deg');

    kf = kf + 1;

end

% -- preserve peak labels
[clu_tep_new.data_columns] = deal(clu_tep(1).data_columns);
clu_tep = clu_tep_new;

% -- sort frequencies in ascending order
[~, ix_f] = sort(cell2mat(cellfun(@str2num, {clu_tep.tfreq}, 'un', 0))); % sort freq
clu_tep = clu_tep(ix_f);

%% -- fit cosine model

% -- create output directory for fit results
pout.path_out_subfolder = [pout.path_out, 'fit Clustered\'];
if ~exist(pout.path_out_subfolder, 'dir') && pout.saveWork
    mkdir(pout.path_out_subfolder);
end

% -- invert negative peaks to align modulation direction
s = -2*contains(clu_tep(1).data_columns, 'N') + 1;
clu_tep_fit = nin_function(clu_tep, @(x) s.*x, {'data'}, {'data'});

% -- update peak labels after inversion
[clu_tep_fit.data_columns] = deal(strrep(clu_tep(1).data_columns, 'N', 'invN'));

% -- fit modulation separately for each frequency
fit_amp = [];
k1 = 1;
while k1 <= length(ufreq)

    cf = strcat('Clustered', ufreq{k1}, 'Hz');

    % -- fit sinusoidal modulation across phases
    [h, y] = nin_fitplots(clu_tep_fit(strcmpi({clu_tep_fit.tfreq}, ufreq{k1})), 'crange', [],...
        'cylabel', ['Clustered - ', ufreq{k1}, 'Hz (\muV)'],...
        'cxlabel', 'Phase (deg)',...
        'crange', [-0.8 0.8],...
        'shift_data', false);

    % -- save fit figures
    k2 = 1;
    while k2 <= length(h)

        if pout.saveWork

            set(0, 'CurrentFigure', h(k2));
            pout.fielname_out = ['freq_', ufreq{k1} ,'_Clustered_', get(h(k2), 'Name')];
            saveas(h(k2), [pout.path_out_subfolder, pout.fielname_out, '.fig']);
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

    % -- extract fit parameters
    tamp = cellfun(@(x) x', {y.oval}, 'un', 0);

    % -- extract surrogate fit parameters
    samp = cellfun(@(x) x', {y.pval}, 'un', 0);
    g = [y.goodness];

    % -- store fit results for current frequency
    fit_amp(k1).freq = ufreq{k1};
    fit_amp(k1).data = [tamp{:}];
    fit_amp(k1).data_surogat = permute(cat(3, samp{:}), [1, 3, 2]);
    fit_amp(k1).data_rows = y(1).oval_name;
    fit_amp(k1).data_columns = {y.name};
    fit_amp(k1).p = reshape([y.p], 2, []);
    fit_amp(k1).sse = [g.sse];
    fit_amp(k1).rsquare = [g.rsquare];
    fit_amp(k1).dfe = [g.dfe];
    fit_amp(k1).adjrsquare = [g.adjrsquare];
    fit_amp(k1).rmse = [g.rmse];

    k1 = k1 + 1;

end

%% -- fit modulation using all remaining frequencies

fit_amp_rest = [];
k1 = 1;
while k1 <= length(ufreq)

    cf = strcat('Clustered', ufreq{k1}, 'Hz');

    % -- exclude current frequency
    cclu = clu_tep_fit(~strcmpi({clu_tep_fit.tfreq}, ufreq{k1}));

    % -- average remaining frequencies
    [cclu.group] = deal('all');
    cclu_group = nin_group_data(cclu, {'data'}, {'group'});
    cclu_group = nin_function(cclu_group, @(x) nanmean(x, 3), {'data'}, {'data'});
    [cclu_group.data_rows] = deal(clu_tep_fit(1).data_rows);
    [cclu_group.data_columns] = deal(clu_tep_fit(1).data_columns);

    % -- fit sinusoidal modulation across phases
    [h, y] = nin_fitplots(cclu_group, 'crange', [],...
        'cylabel', ['Clustered - ', ufreq{k1}, 'Hz (\muV)'],...
        'cxlabel', 'Phase (deg)',...
        'crange', [-0.8 0.8],...
        'shift_data', false);

    % -- close fit figures
    k2 = 1;
    while k2 <= length(h)

        close(h(k2));

        k2 = k2 + 1;

    end
    clear h

    % -- extract fit parameters from remaining frequencies
    tamp = cellfun(@(x) x', {y.oval}, 'un', 0);
    samp = cellfun(@(x) x', {y.pval}, 'un', 0);

    % -- store leave-one-frequency-out results
    fit_amp_rest(k1).freq = ufreq{k1};
    fit_amp_rest(k1).data = [tamp{:}];
    fit_amp_rest(k1).data_surogat = permute(cat(3, samp{:}), [1, 3, 2]);
    fit_amp_rest(k1).data_rows = y(1).oval_name;
    fit_amp_rest(k1).data_columns = {y.name};

    k1 = k1 + 1;

end

%% -- fit modulation across all frequencies

fit_amp_all = [];

% -- pool all frequencie
cclu = clu_tep_fit;
[cclu.group] = deal('all');

% -- average data across frequencies
cclu_group = nin_group_data(cclu, {'data'}, {'group'});
cclu_group = nin_function(cclu_group, @(x) nanmean(x, 3), {'data'}, {'data'});
[cclu_group.data_rows] = deal(clu_tep_fit(1).data_rows);
[cclu_group.data_columns] = deal(clu_tep_fit(1).data_columns);

% -- fit sinusoidal modulation across phases
[h, y] = nin_fitplots(cclu_group, 'crange', [],...
    'cylabel', ['Clustered - ', 'all frequencies (\muV)'],...
    'cxlabel', 'Phase (deg)',...
    'crange', [-0.8 0.8],...
    'shift_data', false);

% -- save fit figures
k2 = 1;
while k2 <= length(h)

    if pout.saveWork

        set(0, 'CurrentFigure', h(k2));
        pout.fielname_out = ['all_freq_Clustered_', get(h(k2), 'Name')];
        saveas(h(k2), [pout.path_out_subfolder, pout.fielname_out, '.fig']);
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

% -- extract fit parameters
tamp = cellfun(@(x) x', {y.oval}, 'un', 0);
samp = cellfun(@(x) x', {y.pval}, 'un', 0);

% -- store pooled-frequency fit results
fit_amp_all.freq = 'all';
fit_amp_all.data = [tamp{:}];
fit_amp_all.data_surogat = permute(cat(3, samp{:}), [1, 3, 2]);
fit_amp_all.data_rows = y(1).oval_name;
fit_amp_all.data_columns = {y.name};

%% -- save fit results

if pout.saveWork

    save([pout.path_out_subfolder, 'fit_amp.mat'], 'fit_amp', 'fit_amp_rest', 'fit_amp_all', '-v7.3');

end

%% -- plot modulation depth estimates

% -- collect modulation depth values across frequencies
cdata = [];
cdata_surogat = [];
k1 = 1;
while k1 <= length(ufreq)

    kc = strcmpi({fit_amp.freq}, ufreq{k1});

    % -- extract observed modulation depth
    cdata = [cdata; fit_amp(kc).data(strcmpi(fit_amp(kc).data_rows, 'amp'), :)];

    % -- extract surrogate modulation depth
    cdata_surogat = [cdata_surogat; mean(squeeze(fit_amp(kc).data_surogat(strcmpi(fit_amp(kc).data_rows, 'amp'), :, :))', 1)];
    k1 = k1 + 1;

end

% -- collect leave-one-frequency-out modulation depth estimates
cdata_rest = [];
k1 = 1;
while k1 <= length(ufreq)

    kc = strcmpi({fit_amp_rest.freq}, ufreq{k1});
    cdata_rest = [cdata_rest; fit_amp_rest(kc).data(strcmpi(fit_amp(kc).data_rows, 'amp'), :)];
    k1 = k1 + 1;

end

% -- line plot
crange = {[0.2, 0.8], [-0.8 -0.2], [0.2, 0.8], [-0.8, -0.2], [0.2, 0.8]};
kk = 1;
h = figure;

% -- convert frequency labels to numeric values
fnum = cell2mat(cellfun(@str2num, ufreq, 'un', 0));

% -- define peak colors
mycolor = [rgb('Gray'); rgb('DarkRed'); rgb('Gold'); rgb('DarkGreen'); rgb('DarkBlue')];
while kk <= length(npeaks)

    % -- plot observed modulation depth
    p(kk) = plot(fnum, cdata(:, kk), 'linewidth', 2.5, 'color', mycolor(kk, :));
    hold on;

    % -- plot surrogate modulation depth
    p(kk) = plot(fnum, cdata_surogat(:, kk), 'linewidth', 2.5, 'linestyle', '--', 'color', mycolor(kk, :));
    kk = kk + 1;

end

% -- format figure
legend(reshape([npeaks; strcat(npeaks, ' sur')], 1, length(npeaks)*2));
xlim([4, 40]);
cylim = ylim;
p(kk) = line([8, 8], [cylim(1), cylim(2)], 'linestyle', '--', 'color', 'k', 'linewidth', 1);
set(get(get(p(kk), 'Annotation'), 'LegendInformation' ), 'IconDisplayStyle', 'off');
kk = kk + 1;
p(kk) = line([13, 13], [cylim(1), cylim(2)], 'linestyle', '--', 'color', 'k', 'linewidth', 1);
set(get(get(p(kk), 'Annotation'), 'LegendInformation' ), 'IconDisplayStyle', 'off');
kk = kk + 1;
p(kk) = line([35, 35], [cylim(1), cylim(2)], 'linestyle', '--', 'color', 'k', 'linewidth', 1);
set(get(get(p(kk), 'Annotation'), 'LegendInformation' ), 'IconDisplayStyle', 'off');
kk = kk + 1;
xlabel('Frequency (Hz)');
ylabel('Strength Of Modulation Depth');
set(gca, 'FontWeight', 'bold');

% -- save figure
pout.path_out_subfolder = [pout.path_out, 'clustered data\'];
if pout.saveWork

    pout.fielname_out = 'strength_of_modutaltion_depth';
    saveas(h, [pout.path_out_subfolder, pout.fielname_out, '.fig']);
    export_fig(h, [pout.path_out_subfolder, pout.fielname_out, '.png'], '-png');

end

close(h);

% -- box plot
mycolor = flipud(pink(10));
h = figure('Color', [1 1 1], 'Position',  [46, 121, 1084, 460]);

% -- plot frequency-specific modulation depth
subplot(2, 1, 1)
[b] = bar(cdata');
k1 = 1;
while k1 <= length(b)
    b(k1).FaceColor = [mycolor(k1, :)];
    k1 = k1 + 1;
end
legend(strcat({fit_amp.freq}, 'Hz'), 'location', 'eastoutside');
title('Strength Of Modulation Depth');
set(gca, 'XTickLabel', strrep(fit_amp(1).data_columns, '_amp', ''));
set(gca, 'FontWeight', 'bold');
ylim([0, 0.5]);

% -- plot leave-one-frequency-out modulation depth
subplot(2, 1, 2)
[b] = bar(cdata_rest');
k1 = 1;
while k1 <= length(b)
    b(k1).FaceColor = [mycolor(k1, :)];
    k1 = k1 + 1;
end
legend(strcat({fit_amp.freq}, 'Hz'), 'location', 'eastoutside');
title('Strength Of Modulation Depth Rest');
set(gca, 'XTickLabel', strrep(fit_amp(1).data_columns, '_amp', ''));
set(gca, 'FontWeight', 'bold');
ylim([0, 0.5]);

% -- save summary figur
pout.path_out_subfolder = [pout.path_out, 'clustered data\'];
if pout.saveWork

    pout.fielname_out = 'strength_of_modutaltion_depth_bars';
    saveas(h, [pout.path_out_subfolder, pout.fielname_out, '.fig']);
    export_fig(h, [pout.path_out_subfolder, pout.fielname_out, '.png'], '-png');

end

close(h);

% -- plot frequency-independent modulation depth
kk = 1;
h = figure;

% -- convert frequency labels to numeric values
fnum = cell2mat(cellfun(@str2num, ufreq, 'un', 0));
while kk <= length(npeaks)

    % -- plot pooled-frequency modulation depth
    p(kk) = plot(fnum, repmat(fit_amp_all.data(strcmpi(fit_amp_all.data_rows, 'amp'), kk), 1, length(fnum)), 'linewidth', 2.5, 'linestyle', '--');
    hold on;

    kk = kk + 1;

end
legend(npeaks);
xlim([4, 40]);

% -- save figure
pout.path_out_subfolder = [pout.path_out, 'clustered data\'];
if pout.saveWork

    pout.fielname_out = 'strength_of_modutaltion_depth_all_freq';
    saveas(h, [pout.path_out_subfolder, pout.fielname_out, '.fig']);
    export_fig(h, [pout.path_out_subfolder, pout.fielname_out, '.png'], '-png');

end

close(h);



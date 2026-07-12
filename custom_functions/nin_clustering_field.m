function [clu] = nin_clustering_field(x, y, latency, varargin)

%% This function performs cluster-based permutation testing using FieldTrip
%
% - input:
% x: structure with input data
% y: comparison structure or permutation data
% latency: latency in msec
%
% - optional:
% method: see fieldtrip (default: 'montecarlo')
% statistic: see fieldtrip (default: 'indepsamplesT')
% correctm: see fieldtrip (default: 'cluster')
% clusteralpha: see fieldtrip (default: 0.05)
% clusterstatistic: see fieldtrip (default: 'clusterstatistic')
% minnbchan: see fieldtrip (default: 2)
% tail: see fieldtrip (default: 0)
% clustertail: see fieldtrip (default: 0)
% alpha: see fieldtrip (default: 0.025)
% n_perm: see fieldtrip (default: 1000)
% ivar: see fieldtrip (default: 1)
% fs: sampling frequency (default: 1000)
% eegsys: eeg montage definition (default: 'BrainVision')

%
% - example:
% [h, y] = nin_clustering(R);
% [h, y] = nin_clustering(R, 'dim', 1);

% -- read input parameters
nin_import_params(varargin);

%% -- set default parameters

% -- define permutation method
if ~exist('method', 'var')
    method = 'montecarlo';
end

% -- define sample-level statistic
if ~exist('statistic', 'var')
    statistic = 'indepsamplesT';
end

% -- define multiple-comparison correction
if ~exist('correctm', 'var')
    correctm = 'cluster';
end

% -- define cluster-forming threshold
if ~exist('clusteralpha', 'var')
    clusteralpha = 0.05;
end

% -- define cluster statistic
if ~exist('clusterstatistic', 'var')
    clusterstatistic = 'maxsum';
end

% -- define minimum cluster neighborhood
if ~exist('minnbchan', 'var')
    minnbchan = 2;
end

% -- define test tail
if ~exist('tail', 'var')
    tail = 0;
end

% -- define cluster tail
if ~exist('clustertail', 'var')
    clustertail = 0;
end

% -- define significance threshold
if ~exist('alpha', 'var')
    alpha = 0.025;
end

% -- define number of permutations
if ~exist('n_perm', 'var')
    n_perm = 1000;
end

% -- define independent variable
if ~exist('ivar', 'var')
    ivar = 1;
end

% -- define sampling frequency
if ~exist('fs', 'var')
    fs = 1000;
end

% -- load eeg montage information
if ~exist('eegsys', 'var')
    eegsys = 'BrainVision';
end
eegsys = nin_eeg_system(eegsys);


%% -- create fieldtrip structure for condition x

pdataX.time = (latency)/fs;
pdataX.label = x(1).data_rows';
pdataX.elec = [];
pdataX.grad = [];
pdataX.sampleinfo = [];
pdataX.trial = permute(x.data, [3, 1, 2]);
pdataX.trialinfo = ones(size(x.data, 3), 1);
pdataX.dimord = 'rpt_chan_time';
pdataX.cfg = [];

ix = any(any(isnan(pdataX.trial), 3), 2);
pdataX.trial(ix, :, :) = [];
pdataX.trialinfo = ones(size(x.data, 3), 1);

%% -- create fieldtrip structure for condition y

if isempty(y)

    pdataY = pdataX;
    pdataY.trial = zeros(size(pdataX.trial));

else

    pdataY.time = (latency)/fs;
    pdataY.label = y(1).data_rows';
    pdataY.elec = [];
    pdataY.grad = [];
    pdataY.sampleinfo = [];
    pdataY.trial = permute(y.data, [3, 1, 2]);
    pdataY.trialinfo = ones(size(y.data, 3), 1);
    pdataY.dimord = 'rpt_chan_time';
    pdataY.cfg = [];

    ix = any(any(isnan(pdataY.trial), 3), 2);
    pdataY.trial(ix, :, :) = [];
    pdataY.trialinfo = ones(size(y.data, 3), 1);

end

%% -- configure permutation test

pparam                  = [];
pparam.method           = method; % use the Monte Carlo Method to calculate the significance probability
pparam.statistic        = statistic; % use the independent samples T-statistic as a measure to
% -- evaluate the effect at the sample level
pparam.correctm         = correctm;
pparam.clusteralpha     = clusteralpha;       % alpha level of the sample-specific test statistic that
% -- will be used for thresholding
pparam.clusterstatistic = clusterstatistic;   % test statistic that will be evaluated under the
% -- permutation distribution
pparam.minnbchan        = minnbchan;          % minimum number of neighborhood channels that is
% -- required for a selected sample to be included
% in the clustering algorithm (default=0).
pparam.tail             = tail;          % -1, 1 or 0 (default = 0); one-sided or two-sided test
pparam.clustertail      = clustertail;
pparam.alpha            = alpha;      % alpha level of the permutation test
pparam.numrandomization = n_perm;        % number of draws from the permutation distribution

n_con  = size(pdataX.trial, 1);
m_con  = size(pdataY.trial, 1);

pparam.design           = [ones(1,n_con), 2*ones(1,m_con)]; % design matrix (label for the first and second condition)
pparam.ivar             = ivar; % number or list with indices indicating the independent variable(s)

pparam.neighbours    = eegsys.neighbours;  % the neighbours specify for each sensor with
% which other sensors it can form clusters
pparam.channel       = {'EEG'};     % cell-array with selected channel labels
pparam.tlatency       = latency/fs;

%% -- evaluate cluster statistics for each latency

clu.data = NaN(length(x.data_rows), length(latency));
clu.p = NaN(1, length(latency));
clu.mask = NaN(length(x.data_rows), length(latency));
clu.data_rows = x.data_rows;
clu.data_columns = strrep(x.data_columns, '_amp', '_t');
k = 1;
while k <= length(latency)

    pparam.latency       = latency(k)/fs;

    % -- run cluster-based permutation test
    cstat = ft_timelockstatistics(pparam, pdataX, pdataY);

    if ~isfield(cstat, 'posclusters')
        cstat.posclusters.prob = [];
        cstat.posclusters.clusterstat = [];
        cstat.posclusterslabelmat = zeros(length(cstat.stat), 1);
        cstat.posdistribution = zeros(1, 1000);
    end
    if ~isfield(cstat, 'negclusters')
        cstat.negclusters.prob = [];
        cstat.negclusters.clusterstat = [];
        cstat.negclusterslabelmat = zeros(length(cstat.stat), 1);
        cstat.negdistribution = zeros(1, 1000);
    end

    % -- store fieldtrip statistics
    stat(k) = cstat;

    % -- extract largest positive cluster
    pos_cluster_pvals = [stat(k).posclusters(:).prob];
    if ~isempty(pos_cluster_pvals)
        pos_cluster_sum = [stat(k).posclusters(:).clusterstat];

        [pos_clust_max, ix_pos] = max(pos_cluster_sum);
        pos_cluster_pvals = pos_cluster_pvals(ix_pos);
        pos_cluster_sum = pos_cluster_sum(ix_pos);
        pos       = ismember(stat(k).posclusterslabelmat, ix_pos);
    else
        pos_cluster_pvals = 1;
        pos_cluster_sum = 0;
    end

    % -- extract largest negative cluster
    neg_cluster_pvals = [stat(k).negclusters(:).prob];
    if ~isempty(neg_cluster_pvals)
        neg_cluster_sum = [stat(k).negclusters(:).clusterstat];

        [neg_clust_max, ix_neg] = max(neg_cluster_sum);
        neg_cluster_pvals = neg_cluster_pvals(ix_neg);
        neg_cluster_sum = neg_cluster_sum(ix_neg);
        neg       = ismember(stat(k).negclusterslabelmat, ix_neg);
    else
        neg_cluster_pvals = 1;
        neg_cluster_sum = 0;
    end

    % -- keep cluster with largest absolute cluster statistic
    if abs(pos_cluster_sum) > abs(neg_cluster_sum)

        % -- store sample-level statistics
        clu.data(:, k) = stat(k).stat;
        clu.p(k) = pos_cluster_pvals;
        clu.mask(:, k) = pos;

    elseif abs(pos_cluster_sum) < abs(neg_cluster_sum)

        % -- store sample-level statistics
        clu.data(:, k) = stat(k).stat;
        clu.p(k) = neg_cluster_pvals;
        clu.mask(:, k) = neg;

    else

        % -- store sample-level statistics
        clu.data(:, k) = zeros(1, 1);
        clu.p(k) = neg_cluster_pvals;
        clu.mask(:, k) = false;

    end

    k = k + 1;

end

end

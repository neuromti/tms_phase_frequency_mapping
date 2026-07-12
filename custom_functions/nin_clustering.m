function [x_o, h] = nin_clustering(x, y, varargin)

%% This function performs cluster-based permutation testing
%
% - input:
% x: structure containing original statistical maps
% y: structure containing permuted statistical maps
%
% - optional:
% n_perm: number of permutation (default: 1000)
% condition: grouping condition used for data selection (default: [])
% method: cluster size metric: 'counter', 'sum', or 'mean' (default: 'counter')
% f: thresholding function used for cluster formation (default: {@(a, b) a > b})
% c_th: cluster-forming threshold (default: {0.05})
% eegsys: eeg montage definition (default: 'BrainVision')
%
% - example:
% [h, y] = nin_clustering(R);
% [h, y] = nin_clustering(R, 'dim', 1);

% -- read input parameters
nin_import_params(varargin);

%% -- set default parameters

% -- define number of permutations
if ~exist('n_perm', 'var')
    n_perm = 1000;
end

% -- define grouping condition
if ~exist('condition', 'var') % firs row fields the second row is value
    condition = [];
end

% -- define cluster size metric
if ~exist('method', 'var')
    method = 'counter';
end

% -- define cluster-forming rule
if ~exist('f', 'var')
    f = {@(a, b) a > b};
end

if ~iscell(f)
    f = {f};
end

% -- define cluster-forming threshold
if ~exist('c_th', 'var')
    c_th = {0.05};
end

if ~iscell(c_th)
    c_th = {c_th};
end

% -- load eeg montage information
if ~exist('eegsys', 'var')
    eegsys = 'BrainVision';
end
eegsys = nin_eeg_system(eegsys);

%% -- prepare data selection

rng(1, 'twister');

if isempty(condition)

    % -- use complete dataset
    c_o = x;
    c_p = y;

else

    % -- process data separately for each condition
    x_o = [];
    k1 = 1;
    while k1 <= length(condition{1 , 2})

        % -- select original statistical map
        c_o = nin_subselect_dstruct(x, condition{1, 1}, condition{1, 2}{k1});

        % -- convert channel data to spatial layout
        [co_o, ix] = data_organisation(c_o, eegsys);

        % -- expand thresholding functions to all contrasts
        if length(f) ~=  length(c_o.data_columns)
            f = repmat(f, 1, length(c_o.data_columns));
        end

        % -- expand cluster thresholds to all contrasts
        if length(c_th) ~=  length(c_o.data_columns)
            c_th = repmat(c_th, 1, length(c_o.data_columns));
        end

        % -- identify clusters in original data
        n_o = zeros(1, size(co_o, 3));
        Mnn = nan(size(co_o, 1), size(co_o, 2), size(co_o, 3));
        Mpp = nan(size(co_o, 1), size(co_o, 2), size(co_o, 3));
        M = nan(size(co_o, 1), size(co_o, 2), size(co_o, 3));
        k2 = 1;
        while k2 <= size(co_o, 3)

            switch method

                case 'counter'

                    % -- compute cluster extent
                    tdata = abs(co_o(:, :, k2));

                    % -- label spatially connected clusters
                    [M(:, :, k2), cn_o] = bwlabel(f{k2}(tdata, c_th{k2}), 8);

                    % -- calculate size of each cluster
                    if cn_o ~= 0

                        k4 = 1; ncn_o = zeros(cn_o, 1);
                        while k4 <= cn_o

                            ncn_o(k4) = nnz(M(:, :, k2) == k4);

                            k4 = k4 + 1;

                        end

                        n_o(1, k2) = max(ncn_o);

                    end

                case 'sum'

                    % -- evaluate negative clusters
                    tdata = co_o(:, :, k2);
                    tdata(tdata > 0) = NaN;
                    tdata = abs(tdata);
                    [Mnn(:, :, k2), cnn_o] = bwlabel(f{k2}(tdata, c_th{k2}), 8);

                    if cnn_o ~= 0

                        k4 = 1; ncnn_o = zeros(cnn_o, 1);
                        while k4 <= cnn_o

                            ncnn_o(k4) = sum(tdata(Mnn(:, :, k2) == k4));

                            k4 = k4 + 1;

                        end

                        [nn_o(1, k2), ixn_max(1, k2)] = max(ncnn_o);

                    else

                        nn_o(1, k2) = 0;

                    end

                    % -- evaluate positive clusters
                    tdata = co_o(:, :, k2);
                    tdata(tdata <= 0) = NaN;
                    tdata = abs(tdata);
                    [Mpp(:, :, k2), cpn_o] = bwlabel(f{k2}(tdata, c_th{k2}), 8);

                    if cpn_o ~= 0

                        k4 = 1; ncpn_o = zeros(cpn_o, 1);
                        while k4 <= cpn_o

                            ncpn_o(k4) = sum(tdata(Mpp(:, :, k2) == k4));

                            k4 = k4 + 1;

                        end

                        [np_o(1, k2), ixp_max(1, k2)] = max(ncpn_o);

                    else

                        np_o(1, k2) = 0;

                    end


                    % -- keep cluster with largest cluster mass
                    if nn_o(1, k2) < np_o(1, k2)

                        M(:, :, k2) = Mpp(:, :, k2);
                        cn_o = cpn_o;
                        n_o(1, k2) = np_o(1, k2);
                        ix_max(1, k2) = ixp_max(1, k2);

                    elseif nn_o(1, k2) > np_o(1, k2)

                        M(:, :, k2) = Mnn(:, :, k2);
                        cn_o = cnn_o;
                        n_o(1, k2) = nn_o(1, k2);
                        ix_max(1, k2) = ixn_max(1, k2);

                    else

                        M(:, :, k2) = zeros(size(M, 1), size(M, 2));
                        cn_o = 0;
                        n_o(1, k2) = 0;
                        ix_max(1, k2) = 0;

                    end

                case 'mean'

                    tdata = abs(co_o(:, :, k2));
                    [M(:, :, k2), cn_o] = bwlabel(f{k2}(tdata, c_th{k2}), 8);

                    if cn_o ~= 0

                        k4 = 1; ncn_o = zeros(cn_o, 1);
                        while k4 <= cn_o

                            ncn_o(k4) = mean(tdata(M(:, :, k2) == k4));

                            k4 = k4 + 1;

                        end

                        n_o(1, k2) = max(ncn_o);

                    end

            end

            k2 = k2 + 1;

        end

        %% -- create significance mask

        ccdata = nan(eegsys.nochannels, size(co_o, 3));
        k2 = 1;
        while k2 <= size(ix, 1)

            k3 = 1;
            while k3 <= size(ix, 2)

                if ix(k2, k3)
                    ccdata(ix(k2, k3), :) = squeeze(M(k2, k3, :))';
                end

                k3 = k3 + 1;

            end

            k2 = k2 + 1;

        end

        % -- convert cluster labels back to channel space
        ccdata(ccdata ~= ix_max) = 0;

        % -- keep only the largest cluster
        ccdata(ccdata ~= 0) = 1;

        tc_o = c_o;
        tc_o.data = tc_o.data;

        % -- create binary cluster mask
        tc_o.mask = ccdata;

        %% -- evaluate permutation distribution

        c_p = nin_subselect_dstruct(y, condition{1, 1}, condition{1, 2}{k1});
        n_p = zeros(size(c_p, 2), length(c_p(1).data_columns));

        k3 = 1;
        while k3 <= size(c_p, 2)

            % -- convert permutation data to spatial layout
            co_p = data_organisation(c_p(k3), eegsys);

            % -- cluster data
            Mnn = nan(size(co_p, 1), size(co_p, 2), size(co_p, 3));
            Mpp = nan(size(co_p, 1), size(co_p, 2), size(co_p, 3));
            Mp = nan(size(co_p, 1), size(co_p, 2), size(co_p, 3));
            k2 = 1;
            while k2 <= size(co_p, 3)

                % -- identify clusters in permutation data
                switch method

                    case 'counter'

                        tdata = abs(co_p(:, :, k2));
                        [Mp, cn_p] = bwlabel(f{k2}(tdata, c_th{k2}), 8);

                        if cn_p ~= 0

                            k4 = 1; ncn_p = zeros(cn_p, 1);
                            while k4 <= cn_p

                                ncn_p(k4) = nnz(Mp == k4);

                                k4 = k4 + 1;

                            end

                            n_p(k3, k2) = max(ncn_p);

                        end

                    case 'sum'

                        % negative
                        tdata = co_p(:, :, k2);
                        tdata(tdata > 0) = NaN;
                        tdata = abs(tdata);
                        [Mnn(:, :, k2), cnn_p] = bwlabel(f{k2}(tdata, c_th{k2}), 8);

                        if cnn_p ~= 0

                            k4 = 1; ncnn_p = zeros(cnn_p, 1);
                            while k4 <= cnn_p

                                ncnn_p(k4) = sum(tdata(Mnn(:, :, k2) == k4));

                                k4 = k4 + 1;

                            end

                            nn_p(k3, k2) = max(ncnn_p);

                        else

                            nn_p(k3, k2) = 0;

                        end

                        % positive
                        tdata = co_p(:, :, k2);
                        tdata(tdata <= 0) = NaN;
                        tdata = abs(tdata);
                        [Mpp(:, :, k2), cpn_p] = bwlabel(f{k2}(tdata, c_th{k2}), 8);

                        if cpn_p ~= 0

                            k4 = 1; ncpn_p = zeros(cpn_p, 1);
                            while k4 <= cpn_p

                                ncpn_p(k4) = sum(tdata(Mpp(:, :, k2) == k4));

                                k4 = k4 + 1;

                            end

                            np_p(k3, k2) = max(ncpn_p);

                        else

                            np_p(k3, k2) = 0;

                        end

                        if nn_p(k3, k2) < np_p(k3, k2)

                            Mp(:, :, k2) = Mpp(:, :, k2);
                            cn_p = cpn_p;
                            n_p(k3, k2) = np_p(k3, k2);

                        elseif nn_p(1, k2) > np_p(1, k2)

                            Mp(:, :, k2) = Mnn(:, :, k2);
                            cn_p = cnn_p;
                            n_p(k3, k2) = nn_p(k3, k2);

                        else

                            Mp(:, :, k2) = zeros(size(Mp, 1), size(Mp, 2));
                            cn_p = 0;
                            n_p(k3, k2) = 0;
                            ix_max(k3, k2) = 0;

                        end

                    case 'mean'

                        tdata = abs(co_p(:, :, k2));
                        [Mp, cn_p] = bwlabel(f{k2}(tdata, c_th{k2}), 8);

                        if cn_p ~= 0

                            k4 = 1; ncn_p = zeros(cn_p, 1);
                            while k4 <= cn_p

                                ncn_p(k4) = mean(tdata(Mp == k4));

                                k4 = k4 + 1;

                            end

                            n_p(k3, k2) = max(ncn_p);

                        end

                end

                k2 = k2 + 1;

            end

            k3 = k3 + 1;

        end

        % -- calculate cluster-level p-value
        k2 = 1;
        while k2 <= size(co_p, 3)

            p(1, k2) = nnz(abs(n_p(:, k2)) >= abs(n_o(1, k2)))/n_perm;

            k2 = k2 + 1;

        end

        %% -- store clustering results
        
        tc_o.p = p;

        x_o = [x_o, tc_o];

        clear tc_o

        k1 = k1 + 1;

    end

end

%% -- subfunction for data oganisation

    function [y, ix] = data_organisation(xx, eegsys)

        y = nan(10, 11, length(xx.data_columns));
        kk1 = 1;
        while kk1 <= length(xx.data_columns)

            % create matix of channel distribution
            cdata = nan(10, 11); % This is for Brain Vision
            ix = zeros(10, 11); % This is for Brain Vision
            kk2 = 1; c1 = 1; c2 = 1;
            while kk2 <= length(eegsys.ix_plot)

                if eegsys.ix_plot(kk2) ~= 0
                    cdata(c1, c2) = xx.data(eegsys.ix_plot(kk2), kk1);
                    ix(c1, c2) = eegsys.ix_plot(kk2);
                end

                c2 = c2 + 1;

                if c2 > 11
                    c1 = c1 + 1;
                    c2 = 1;
                end

                kk2 = kk2 + 1;

            end

            y(:, :, kk1) = cdata;

            kk1 = kk1 + 1;

        end

    end

end

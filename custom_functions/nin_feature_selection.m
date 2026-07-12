function [cfeatures, sdata, y] = nin_feature_selection(x, fmethod, varargin)

%% This function performs feature selection or feature extraction
%
% - inputs:
% x: data structure
% fmethod: feature selection method (default: 'pca')
% pca
% cca
% ILFS - read FSLib_v7.0.1_2020_2/Demo.m
% InfFS - read FSLib_v7.0.1_2020_2/Demo.m
% ECFS - read FSLib_v7.0.1_2020_2/Demo.m
% mrmr - read FSLib_v7.0.1_2020_2/Demo.m
% relieff - read FSLib_v7.0.1_2020_2/Demo.m
% mutinffs - read FSLib_v7.0.1_2020_2/Demo.m
% fsv - read FSLib_v7.0.1_2020_2/Demo.m
% laplacian - read FSLib_v7.0.1_2020_2/Demo.m
% mcfs - read FSLib_v7.0.1_2020_2/Demo.m
% rfe - read FSLib_v7.0.1_2020_2/Demo.m
% L0 - read FSLib_v7.0.1_2020_2/Demo.m
% fisher - read FSLib_v7.0.1_2020_2/Demo.m
% UDFS - read FSLib_v7.0.1_2020_2/Demo.m
% llcfs - read FSLib_v7.0.1_2020_2/Demo.m
% cfs - read FSLib_v7.0.1_2020_2/Demo.m
% fsasl - read FSLib_v7.0.1_2020_2/Demo.m
% dgufs - read FSLib_v7.0.1_2020_2/Demo.m
% ufsol - read FSLib_v7.0.1_2020_2/Demo.m
% lasso - read FSLib_v7.0.1_2020_2/Demo.m
%
% - optional:
%
% - example:
% [y] = nin_feature_selection(f, 'pca');


% -- read input parameters
nin_import_params(varargin);

%% -- initialize output structure

% -- store input feature names
y.in_features = x.infeatures;
% -- store analysis parameters
y.in_param = x.in_param;
% -- get number of input features
y.n_features = length(y.in_features);

% -- configure feature selection toolbox
cpath = strsplit(path, ':')';
rpath = cpath(contains(cpath, 'FSLib_v7.0.1_2020_2'));
if strcmpi(fmethod, 'pca')
    % -- remove conflict path FSLib_v7.0.1_2020_2
    if ~isempty(rpath)
        rmpath(genpath(rpath{1}));
    end
else
    if isempty(rpath)
        rpath = cpath(contains(cpath, 'third party code'));
        addpath(genpath([rpath{1}, filesep,'FSLib_v7.0.1_2020_2']));
    else
        addpath(genpath(rpath{1}));
    end
end

%% -- feture selection

switch fmethod
    
    case 'pca'
        
        [coeff, score, latent, tsquared, explained, mu] = pca(x.data);
        
        y.pca.coeff = coeff;
        y.pca.score = score;
        y.pca.latent = latent;
        y.pca.tsquared = tsquared;
        y.pca.explained = explained;
        y.pca.mu = mu;
        y.pca.cumsum = cumsum(explained);
        y.pca.ranking = 1:length(explained);
        y.pca.idx = y.pca.ranking(1:y.in_param.n_components);
        if isfield(x.in_param.pca, 'pca_th')
            y.pca.idx = find(~(y.pca.cumsum >= x.in_param.pca.pca_th));
        end
     
    case 'cca'
        
        [A, B, r, U, V, stats] = canoncorr(x.data, x.resp);
        
        y.cca.A = A;
        y.cca.B = B;
        y.cca.r = r;
        y.cca.U = U; % U = (x.data - mean(x.data))*A
        y.cca.V = V; % V = (x.resp - mean(x.resp))*B
        y.cca.stats = stats;
        
    case 'inffs'
        
        [ranking, weights] = infFS(x.data, x.resp, y.in_param.inffs.alpha, y.in_param.inffs.sup, 0);
        
        y.inffs.ranking = ranking;
        y.inffs.weights = weights;
        y.inffs.idx = ranking(1:y.in_param.n_components);
        
    case 'ilfs'
        
        [ranking, weights] = ILFS(x.data, x.resp, 6, 0);
        
        y.ilfs.ranking = ranking;
        y.ilfs.weights = weights;
        y.ilfs.idx = ranking(1:y.in_param.n_components);
        
    case 'fsasl'
        
        [W, S, A, objHistory] = FSASL(x.data', y.in_param.fsasl.nClass, y.in_param.fsasl.options);
        [weights, ranking] = sort(abs(W(:,1)) + abs(W(:,2)), 'descend');
        
        y.fsasl.ranking = ranking;
        y.fsasl.weights = weights;
        y.fsasl.idx = ranking(1:y.in_param.n_components);
        
    case 'lasso'
        
        B = lasso(x.data, x.resp);
        
        if isempty(y.in_param.lasso.lambda)
            ix = find(any(B == 0, 1));
            y.in_param.lasso.lambda = ix(1);
        end
        
        [weights, ranking] = sort(B(:, y.in_param.lasso.lambda), 'descend');
        
        y.lasso.ranking = ranking;
        y.lasso.weights = weights;
        y.lasso.idx = ranking(1:y.in_param.n_components);
        
        if isfield(x.in_param.lasso, 'lasso_th')
            y.lasso.idx = ranking(weights < y.in_param.lasso.lasso_th);
        end
        
    case 'ufsol'
        
        [~ ,~ , ranking, ~] = UFSwithOL(x.data', y.in_param.ufsol.nClass, y.in_param.ufsol.para);
        
        y.ufsol.ranking = ranking;
        y.ufsol.idx = ranking(1:y.in_param.n_components);
        
    case 'dgufs'
        
        S = dist(X_train');
        S = -S./max(max(S)); % it's a similarity
        [Y, L, V, Label] = DGUFS(x.data', y.in_param.dgufs.nClass, S, y.in_param.dgufs.alpha, y.in_param.dgufs.beta, y.in_param.dgufs.nSel);
        [weights, ranking] = sort(Y(:,1) + Y(:,2), 'descend');
        
        y.dgufs.ranking = ranking;
        y.dgufs.weights = weights;
        y.dgufs.idx = ranking(1:y.in_param.n_components);
        
    case 'mrmr'
        
        ranking = mRMR(x.data, x.resp, y.n_features);
        
        y.mrmr.ranking = ranking;
        y.mrmr.idx = ranking(1:y.in_param.n_components);
        
    case 'relieff'
        
        [ranking, weights] = reliefF(x.data, x.resp, 20);
        
        y.relieff.ranking = ranking;
        y.relieff.weights = weights;
        y.relieff.idx = ranking(1:y.in_param.n_components);
        
    case 'mutinffs'
        
        [ranking, weights] = mutInfFS(x.data, x.resp, y.n_features);
        
        y.mutinffs.ranking = ranking;
        y.mutinffs.weights = weights;
        y.mutinffs.idx = ranking(1:y.in_param.n_components);
        
    case 'fsv'
        
        [ranking, weights] = fsvFS(x.data, x.resp, y.n_features);
        
        y.fsv.ranking = ranking;
        y.fsv.weights = weights;
        y.fsv.idx = ranking(1:y.in_param.n_components);
        
    case 'laplacian'
        
        W = dist(x.data');
        W = -W./max(max(W)); % it's a similarity
        [lscores] = LaplacianScore(x.data, W);
        [junk, ranking] = sort(-lscores);
        
        y.laplacian.ranking = ranking;
        y.laplacian.idx = ranking(1:y.in_param.n_components);
        
    case 'mcfs'
        
        [FeaIndex, ~] = MCFS_p(x.data, y.n_features, y.in_param.mcfs.options);
        ranking = FeaIndex{1};
        
        y.mcfs.ranking = ranking;
        y.mcfs.idx = ranking(1:y.in_param.n_components);
        
    case {'rfe', 'l0', 'fisher'}
        
        ranking = spider_wrapper(x.data, x.resp, y.n_features, lower(fmethod));
        
        y.(lower(fmethod)).ranking = ranking;
        y.(lower(fmethod)).idx = ranking(1:y.in_param.n_components);
        
    case 'ecfs'
        
        ranking = ECFS(x.data, x.resp, y.in_param.ecfs.alpha)  ;
        
        y.ecfs.ranking = ranking;
        y.ecfs.idx = ranking(1:y.in_param.n_components);
        
    case 'udfs'
        
        ranking = UDFS(x.data, y.in_param.udfs.nClass);
        
        y.udfs.ranking = ranking;
        y.udfs.idx = ranking(1:y.in_param.n_components);
        
    case 'cfs'
        
        ranking = cfs(x.data);
        
        y.cfs.ranking = ranking;
        y.cfs.idx = ranking(1:y.in_param.n_components);
        
    case 'llcfs'
        
        ranking = llcfs(x.data);
        
        y.llcfs.ranking = ranking;
        y.llcfs.idx = ranking(1:y.in_param.n_components);
        
end

%% -- create output data

switch fmethod
    
    case 'pca'
        
        cfeatures = strcat('PCA_', cellfun(@num2str, num2cell(1:length(explained)), 'un', 0));
        cfeatures = cfeatures(y.pca.idx);
        sdata = y.pca.score(:, y.pca.idx);
        
        case 'cca'
        
        cfeatures = {'CCA'};
        sdata = y.cca.U;
        
    otherwise
        
        cfeatures = y.in_features(y.(lower(fmethod)).idx);
        sdata = x.data(:, y.(lower(fmethod)).idx);
        
end

end


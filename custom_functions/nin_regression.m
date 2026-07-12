function [y] = nin_regression(x, dfield, ifield, keys, varargin)

%% This function builds linear regression models
%
% - inputs:
% x: input data structure
% dfield: dependent variable
% ifield: predictor variables
% keys: grouping fields
%
% - optional:
% spliter: delimiter used by nin_strsplit (default: '_')
% rn1: first row index used by nin_strsplit (default: 1)
% rn2: last row index used by nin_strsplit (default: 1)
% cn1: first column index used by nin_strsplit (default: 2)
% cn2: last column index used by nin_strsplit (default: 2)
% crossval_method: ''/'basic' (default: 'basic')
% ptest: percentage of data that will be randomly taken for testing (default: 0.3)
%
% - example:
% [y] = nin_regression(gpsd, 'logVpp', {'Fp1_1'}, {'sub'});

% -- read input parameters
nin_import_params(varargin);

%% -- set default parameters

% -- define lower border rows
if ~exist('rn1', 'var')
    rn1 = 1;
end

% -- define upper border rows
if ~exist('rn2', 'var')
    rn2 = 1;
end

% -- define lower border columns
if ~exist('cn1', 'var')
    cn1 = 2;
end

% -- define upper border columns
if ~exist('cn2', 'var')
    cn2 = 2;
end

% -- define delimiter
if ~exist('spliter', 'var')
    spliter = '_';
end

% -- define feature selection method
if ~exist('feature_selection', 'var')
    feature_selection = '';
end

% -- define feature selection parameters
if ~exist('in_param', 'var')
    in_param.n_components = 10;

    in_param.pca.pca_th = 98;

    in_param.inffs.alpha = 0.5;
    in_param.inffs.sup = 1;

    in_param.fsasl.options.lambda1 = 1;
    in_param.fsasl.options.LassoType = 'SLEP';
    in_param.fsasl.options.SLEPrFlag = 1;
    in_param.fsasl.options.SLEPreg = 0.01;
    in_param.fsasl.options.LARSk = 5;
    in_param.fsasl.options.LARSratio = 2;
    in_param.fsasl.nClass = 2;

    in_param.lasso.lambda = [];
    in_param.lasso.lasso_th = 0;

    in_param.ufsol.para.p0 = 'sample';
    in_param.ufsol.para.p1 = 1e6;
    in_param.ufsol.para.p2 = 1e2;
    in_param.ufsol.nClass = 2;

    in_param.dgufs.nClass = 2;
    in_param.dgufs.alpha = 0.5;
    in_param.dgufs.beta = 0.9;
    in_param.dgufs.nSel = 2;

    in_param.mcfs.options.k = 5;
    in_param.mcfs.options.nUseEigenfunction = 4;

    in_param.ecfs.alpha = 0.5;

    in_param.udfs.nClass = 2;
end

% -- define cross-validation method
if ~exist('crossval_method', 'var')
    crossval_method = 'basic';
end

% -- define test set proportion
if ~exist('ptest', 'var')
    ptest = 0.3;
end

% -- ensure predictors are stored as a row vector
if size(ifield, 1) > 1
    ifield = ifield';
end

%% -- make key combination

% -- convert grouping variable to cell array
if ~iscell(keys)
    keys = {keys};
end

% -- extract unique values for grouping fields
key_val = cell(length(keys), 1);
k = 1;
while k <= length(keys)

    cfield = {x.(keys{k})};
    if isnumeric(cfield{1, 1})
        cfield = cellfun(@num2str, cfield, 'un', 0);
    end

    key_val{k} = unique(cfield, 'stable');

    k = k + 1;

end

% -- generate all grouping combinations
key_val = allcomb(key_val{:});

key_selection = cell(size(key_val, 1), 2*size(key_val, 2));
k1 = 1;
while k1 <= size(key_selection, 1)
    k2 = 0;
    while k2 < size(key_val, 2)
        key_selection(k1, 2*k2+1) = keys(k2+1);
        key_selection(k1, 2*k2+2) = key_val(k1, k2+1);
        k2 = k2 + 1;
    end
    k1 = k1 + 1;
end

%% -- calculate regression

k1 = 1;
s = 1;
while k1 <= size(key_selection, 1)

    % -- select data for current group
    cpsd = nin_subselect_dstruct(x, key_selection{k1, :});

    if ~isempty(cpsd) && size(cpsd, 2) > 1

        % -- copy grouping information
        k2 = 1;
        while k2 <= length(keys)
            y(s).(keys{k2}) = cpsd.(keys{k2});
            k2 = k2 + 1;
        end

        % -- extract row and column identifiers
        crows = nin_strsplit(ifield, rn1, rn2, 'spliter', spliter);
        ccolumns = nin_strsplit(ifield, cn1, cn2, 'spliter', spliter);

        % -- extract dependent and predictor variables
        sdata = nin_struct2cell_form(cpsd, 'srows', crows, 'scolumns', ccolumns, 'otype', 'cell', 'smeta', {dfield});
        sdata = nin_subselect_fields(sdata, [{dfield}, ifield]);
        sdata(2:end, :) = cellfun(@double, sdata(2:end, :), 'un', 0);

        % -- identify dependent variable
        ix_d = strcmpi(sdata(1, :), dfield);
        infeatures = sdata(1, ~ix_d);
        cfeatures = sdata(1, ~ix_d);

        % -- convert data to numeric matrix
        sdata = cell2mat(sdata(2:end, :));

        % -- feture selection
        f.data = sdata(:, ~ix_d);
        f.resp = sdata(:, ix_d);
        f.infeatures = infeatures;
        f.in_param = in_param;

        % -- keep all predictors
        if strcmpi(feature_selection, '')

            y(s).feature.in_features = infeatures;
            y(s).feature.in_param = in_param;

        else

            % -- reduce feature space
            [cfeatures, cdata, cy] = nin_feature_selection(f, feature_selection);

            y(s).feature = cy;

            % -- store feature selection results
            switch feature_selection

                % -- use canonical variates as predictors
                case 'cca'

                    sdata = [y(s).feature.cca.V, cdata];

                otherwise

                    % -- replace predictors with selected features
                    sdata = [sdata(:, ix_d), cdata];

            end

            ix_d = false(1, size(sdata, 2));
            ix_d(1) = true;

        end

        % -- get number of observations
        n_obs = size(sdata, 1);

        %% -- split training and testing data

        switch crossval_method

            % -- use all observations for training
            case ''

                straining = sdata;
                stesting = [];
                ptest = 0;
                ix_tr = size(sdata, 1);
                ix_ts = NaN(1, 1);

                % -- generate random train-test split
            case 'basic'

                ix_r = randperm(n_obs);
                n_tr = fix((1-ptest)*n_obs);
                ix_tr = ix_r(1:n_tr-1);
                ix_ts = ix_r(n_tr:end);
                straining = sdata(ix_tr, :);
                stesting = sdata(ix_ts, :);

        end

        %% -- fit regression model

        cmdl = fitlm(straining(:, ~ix_d), straining(:, ix_d), 'VarNames', [cfeatures, {dfield}]);

        % -- perform cross-validation
        if ~isempty(stesting)
            [cpred, cipred] = predict(cmdl, stesting(:, ~ix_d));
        else
            cpred = NaN(1, 1);
            cipred = NaN(1, 1);
        end

        % -- predict testing observations
        cs = table2array(cmdl.Coefficients(2:end, :));
        csm = table2array(anova(cmdl, 'summary'));

        %% -- extract model statistics

        y(s).n = n_obs;
        y(s).data = cmdl.Rsquared.Ordinary;
        y(s).data_rows = {'Rsquared'};
        y(s).data_columns = {'Regression'};
        y(s).predictors = cfeatures;
        y(s).mdl = cmdl;

        y(s).cv.method = crossval_method;
        y(s).cv.ptest = ptest;
        y(s).cv.ix_tr = ix_tr;
        y(s).cv.ix_tr = ix_ts;
        y(s).cv.data = stesting(:, ~ix_d);
        y(s).cv.gt = sdata(ix_ts, ix_d);
        y(s).cv.pred = cpred;
        y(s).cv.cipred = cipred;
        [r, p] = corrcoef(y(s).cv.gt, y(s).cv.pred);
        y(s).cv.stat.r = r(2, 1);
        y(s).cv.stat.p = p(2, 1);
        y(s).cv.stat.Rquared = y(s).cv.stat.r^2;
        y(s).cv.stat.classified = false(length(cpred), 1);
        y(s).cv.stat.classified(cipred(:, 1) <= y(s).cv.gt & y(s).cv.gt <= cipred(:, 2)) = true;
        y(s).cv.stat.Accuracy = nnz(y(s).cv.stat.classified)/length(cpred)*100;

        y(s).stat.ttest.RMSE = cmdl.RMSE;
        y(s).stat.ttest.ctdf = cmdl.DFE;
        y(s).stat.ttest.est = cs(:, 1);
        y(s).stat.ttest.SE = cs(:, 2);
        y(s).stat.ttest.t = cs(:, 3);
        y(s).stat.ttest.p = cs(:, 4);

        y(s).stat.anova.df = csm(2, 2);
        y(s).stat.anova.F = csm(2, 4);
        y(s).stat.anova.p = csm(2, 5);

        s = s + 1;

    end

    k1 = k1 + 1;

end


end

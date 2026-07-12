function [y] = nin_cca(x, dfield, ifield, keys, varargin)

%% This function computes canonical correlation analysis
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
% [y] = nin_cca(gpsd, 'logVpp', {'Fp1_1'}, {'sub'});

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

% -- define spliter
if ~exist('spliter', 'var')
    spliter = '_';
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

%% -- generate key combination

% -- convert grouping variable to cell array
if ~iscell(keys)
    keys = {keys};
end

% -- extract unique values for each grouping field
key_val = cell(length(keys), 1);
k = 1;
while k <= length(keys)

    cfield = {x.(keys{k})};

    % -- convert numeric values to strings
    if isnumeric(cfield{1, 1})
        cfield = cellfun(@num2str, cfield, 'un', 0);
    end

    % -- get unique values
    key_val{k} = unique(cfield, 'stable');

    k = k + 1;

end

% -- generate all combinations of grouping variables
key_val = allcomb(key_val{:});

% -- create grouping selection matrix
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

%% -- calculate CCA

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

        % -- extract selected variables
        sdata = nin_struct2cell_form(cpsd, 'srows', crows, 'scolumns', ccolumns, 'otype', 'cell', 'smeta', {dfield});

        % -- keep dependent and predictor variables
        sdata = nin_subselect_fields(sdata, [{dfield}, ifield]);

        % -- convert values to numeric format
        sdata(2:end, :) = cellfun(@double, sdata(2:end, :), 'un', 0);

        % -- identify dependent variable
        ix_d = strcmpi(sdata(1, :), dfield);

        % -- store predictor names
        infeatures = sdata(1, ~ix_d);
        cfeatures = sdata(1, ~ix_d);

        % -- convert data matrix
        sdata = cell2mat(sdata(2:end, :));

        % -- get sample size
        n_obs = size(sdata, 1);

        %% -- split training and testing data

        switch crossval_method

            case ''

                % -- use all observations for training
                straining = sdata;
                stesting = [];
                ptest = 0;
                ix_tr = size(sdata, 1);
                ix_ts = NaN(1, 1);

            case 'basic'

                % -- generate random split
                ix_r = randperm(n_obs);
                n_tr = fix((1-ptest)*n_obs);
                ix_tr = ix_r(1:n_tr-1);
                ix_ts = ix_r(n_tr:end);
                straining = sdata(ix_tr, :);
                stesting = sdata(ix_ts, :);

        end

        %% -- fit cca model

        [A, B, r, U, V, stats] = canoncorr(straining(:, ~ix_d), straining(:, ix_d));

        % -- store model output
        cmdl.A = A;
        cmdl.B = B;
        cmdl.r = r;
        cmdl.Rsquared = r^2;
        cmdl.U = U;
        cmdl.V = V;
        cmdl.stats = stats;

        %% -- perform cross-validation

        if ~isempty(stesting)

            % -- project testing data
            Uc = (stesting(:, ~ix_d) - mean(stesting(:, ~ix_d)))*A;
            Vc = (stesting(:, ix_d) - mean(stesting(:, ix_d)))*B;

            % -- calculate canonical correlation
            [rc, pc] = corr(Uc, Vc);
        else
            rc = NaN(1, 1);
            pc = NaN(1, 1);
        end

        %% -- store outputs

        y(s).n = n_obs;
        y(s).data = cmdl.Rsquared;
        y(s).data_rows = {'Rsquared'};
        y(s).data_columns = {'CCA'};
        y(s).predictors = cfeatures;
        y(s).mdl = cmdl;

        y(s).cv.method = crossval_method;
        y(s).cv.ptest = ptest;
        y(s).cv.ix_tr = ix_tr;
        y(s).cv.ix_tr = ix_ts;
        y(s).cv.data = stesting(:, ~ix_d);
        y(s).cv.gt = sdata(ix_ts, ix_d);
        y(s).cv.r = rc;
        y(s).cv.p = pc;
        y(s).cv.Rquared = rc^2;

        s = s + 1;

    end

    k1 = k1 + 1;

end


end

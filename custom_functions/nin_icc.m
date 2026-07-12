function [y] = nin_icc(x, varargin)

%% This function calculates intraclass correlation coefficients (ICC)
%
% - input:
% x: structure with input data
%
% - optional:
% icc_method: ICC model type (default: '1-1')
% alpha: significance level (default: 0.05)
% ro: null hypothesis ICC value (default: 0)
%
% - example:
% [y] = icc(x);

% -- read input parameters
nin_import_params(varargin);

%% -- set default parameters

% -- define ICC model
if ~exist('icc_method', 'var')
    icc_method = '1-1';
end

% -- define null ICC value
if ~exist('ro', 'var')
    ro = 0;
end

% -- define significance level
if ~exist('alpha', 'var')
    alpha = 0.05;
end


%% -- calculate ICC statistics

k = 1;
while k <= size(x, 2)

    % -- calculate ICC and associated statistics
    [r, LB, UB, F, df1, df2, p] = ICC(x(k).data, icc_method, alpha, ro); % rows subjects, columns sessions

    % -- store results
    y(k).pro_name = x(k).pro_name;
    y(k).name = x(k).name;
    y(k).freq = x(k).freq;

    % -- store ICC estimate
    y(k).r = r;

    % -- store significance and confidence intervals
    y(k).p = p;
    y(k).LB = LB;
    y(k).UB = UB;

    % -- store test statistics
    y(k).F = F;
    y(k).df1 = df1;
    y(k).df2 = df2;

    k = k + 1;

end

end

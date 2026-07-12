function [y] = nin_subselect_fields(x, fnames, varargin)

%% This function keeps selected fields from a structure or cell array
%
% - inputs:
% x: input structure or cell array
% fnames: field names to retain
%
% - optional:
% match_case: exact/partial matching mode (default: 'exact')
%
% - example:
% [y] = nin_subselect_fields(x, {'data', 'data_rows', 'data_columns'});
% [y] = nin_subselect_fields(x, {'data'}, 'match_case', 'partial');

% -- read input parameters
nin_import_params(varargin);

%% -- set default parameters

% -- ensure field names are stored as a cell array
if ~iscell(fnames)
    fnames = {fnames};
end

% -- define matching mode
if ~exist('match_case', 'var')
    match_case = 'exact';
end

%% -- fields subselection

% -- extract available field names
if isstruct(x)
    all_fields = fieldnames(x);
else
    all_fields = x(1, :);
end

% -- identify selected fields
switch match_case

    % -- exact field matching
    case 'exact'

        k1 = 1;
        ix = false(1, length(all_fields));
        while k1 <= length(all_fields)
            if any(strcmpi(fnames, all_fields{k1}))
                ix(k1) = true;
            end
            k1 = k1 + 1;
        end

        % -- partial field matching
    case 'partial'

        ix = contains(all_fields, fnames);

end

%% -- create output
if isstruct(x)
    y = rmfield(x, all_fields(~ix));
else
    y = x(:, ix);
end

end

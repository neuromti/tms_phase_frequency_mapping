function [y] = nin_strsplit(x, n1, n2, varargin)

%% This function extracts selected parts of strings after splitting
%
% - input:
% x: cell array of strings
% n1: last/first/number - index of the first element to extract (default: 'last')
% n2: []/number - index of the last element to extract (default: [])
%
% - optional:
% spliter: delimiter used for string splitting (default: '/')
% joinc: delimiter used when joining multiple elements (default: '.')
%
% - example:
% filename = {emg.filename};
% [y] = nin_strsplit(filename, 'last');
% [y] = nin_strsplit(filename, 2);
% [y] = nin_strsplit(filename, 'first');
% [y] = nin_strsplit(filename, 'last', [], 'spliter', '/');
% [y] = nin_strsplit(filename, 2, 3, 'joinc', '.');

% -- read input parameters
nin_import_params(varargin);

%% -- set default parameters

% -- define extraction rule
if ~exist('n1', 'var') || isempty(n1)
    n1 = 'last';
else
    % -- validate extraction rule
    if ~(strcmpi(n1, 'first') || strcmpi(n1, 'last') || isnumeric(n1))
        error('n1 is not defined appropriate.');
    end
end

% -- define upper extraction index
if ~exist('n2', 'var')
    n2 = [];
else
    % -- validate extraction range
    if  ~isempty(n2)
        if n2 < n1
            error('n2 has to be greater than n1.');
        end
    end
end

% -- define split delimiter
if ~exist('spliter', 'var')
    spliter = '/';
end

% -- define join delimiter
if ~exist('joinc', 'var')
    joinc = '_';
end

%% -- extract string segments

% -- initialize output
y = cell(1, length(x));
k = 1;
while k <= length(x)

    % -- split current string
    c = strsplit(x{k}, spliter);

    % -- remove empty elements
    c = c(~cell2mat(cellfun(@isempty, c, 'un', 0))); % remove empty cells

    % -- extract requested segment
    switch n1

        % -- keep first segment
        case 'first'

            y(k) = c(1);

            % -- keep last segment
        case 'last'

            y(k) = c(end);

        otherwise

            % -- join multiple segments
            if ~isempty(n2)
                y{k} = strjoin(c(n1:n2), joinc);
            else
                y(k) = c(n1);
            end

    end

    k = k + 1;

end

end

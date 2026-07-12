function [y] = nin_spread_data(x, ofields, dim, varargin)

%% This function expands multidimensional fields into separate structure
%
% - input:
% x: structure with input data
% ofields: fields to spread
% dim: dimensions used for spreading
%
% - optional:
%
% - example:
% [y] = nin_spread_data(x, {'data', 'logVpp', 'zscored'}, {3, 2, 3})

% -- read input parameters
nin_import_params(varargin);

%% -- set default parameters

% -- ensure field list is stored as a cell array
if ~iscell(ofields)
    ofields = {ofields};
end

% -- check consistency of spreading dimensions
d = false(1, size(x, 2));
k1 = 1;
while k1 <= size(x, 2)

    % -- verify matching sizes across selected fields
    s = zeros(1, length(ofields));
    k2 = 1;
    while k2 <= length(ofields)
        s(k2) = size(x(k1).(ofields{k2}), dim{k2});
        k2 = k2 + 1;
    end

    % -- verify identical number of elements
    if all(s == s(1))
        d(k1) = true;
    end

    k1 = k1 + 1;

end

% -- stop if field dimensions are inconsistent
if ~all(d)
    error('Size is not consistent across all fields.');
end

%% -- spread data

% -- identify fields that will be copied unchanged
cfields = fieldnames(x);
tocopy = setdiff(cfields, ofields);

% -- process structure elements
y = [];
k1 = 1;
while k1 <= size(x, 2)

    % -- spread selected fields
    k2 = 1;
    while k2 <= length(ofields)

        % -- extract current field
        cdata = x(k1).(ofields{k2});

        % -- create separate structure element for each slice
        k3 = 1;
        while k3 <= size(cdata, dim{k2})

            switch dim{k2}
                % -- extract row
                case 1
                    cy(k3).(ofields{k2}) = cdata(k3, :);
                    % -- extract column
                case 2
                    cy(k3).(ofields{k2}) = cdata(:, k3);
                    % -- extract layer
                case 3
                    cy(k3).(ofields{k2}) = cdata(:, :, k3);
            end

            k3 = k3 + 1;
        end
        k2 = k2 + 1;

    end

    % -- copy metadata fields
    k2 = 1;
    while k2 <= length(tocopy)

        % -- replicate unchanged fields
        [cy.(tocopy{k2})] = deal(x(k1).(tocopy{k2}));

        k2 = k2 + 1;

    end

    % -- append expanded entries
    y = [y, cy];

    clear cy

    k1 = k1 + 1;

end

% -- restore original field order
y = orderfields(y, cfields);

end


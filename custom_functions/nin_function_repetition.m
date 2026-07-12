function [y] = nin_function_repetition(s, cfunction, cfields, nfields, varargin)

%% This function applies the same function to multiple structure fields
%
% - inputs:
% s: read nin_function
% cfunction: read nin_function
% cfields: read nin_function
% nfields: read nin_function
%
% - optional:
%
% - example:
% x(1).a1 = 5;
% x(1).a2 = 6;
% x(2).a1 = 3;
% x(2).a2 = 3;
% [y] = nin_function_repetition(x, @(x) x-1, {'a1', 'a2'}, {'', ''});
% [y] = nin_function_repetition(x, @(x) x-1, {'a1', 'a2'}, {'b1', 'b2'});

% -- read input parameters
nin_import_params(varargin);

%% -- apply function to all selected fields

y = s;
k = 1;
while k <= length(cfields)

    % -- apply function to current field
    y = nin_function(y, cfunction, cfields{k}, nfields{k});

    k = k + 1;

end

end


function [y] = nin_function(s, cfunction, cfields, nfields, varargin)

%% This function applies user-defined functions to selected structure fields2
%
% - inputs:
% s: input structure
% cfunction: function handle or cell array of function handles
% cfields: fields on which the functions are applied
% nfields: output fields used to store results
%
% - optional:
%
% - example:
% x(1).a1 = 5;
% x(1).a2 = 6;
% x(2).a1 = 3;
% x(2).a2 = 3;
% [y] = nin_function(x, @(x) x.a1+x.a2, '', 'b1');
% [y] = nin_function(x, @(x) x+2, 'a1', 'b1');
% [y] = nin_function(x, {@(x) x+2, @(x) x+5}, 'a1', '');
% [y] = nin_function(x, {@(x) x+2, @(x) x+5}, 'a1', 'b1');
% [y] = nin_function(x, {@(x) x+2, @(x) x+5}, {'a1', 'a1'}, {'a1', 'b1'});

% -- read input parameters
nin_import_params(varargin);

%% -- set default parameters

% -- ensure that cfunction is a cell array
if ~iscell(cfunction)
    cfunction = {cfunction};
end

% -- ensure that cfields is a cell array
if ~iscell(cfields)
    if ischar(cfields)
        cfields = {cfields};
    else
        if isempty(cfields)
            cfields = {''};
        end
    end
end

% -- ensure that nfields is a cell array
if ~iscell(nfields)
    if ischar(nfields)
        nfields = {nfields};
    else
        if isempty(nfields)
            nfields = {''};
        end
    end
end

% -- verify that function calls are properly defined
if ~any(contains(cellfun(@char, cfunction, 'un', 0), '.')) && any(strcmpi(cfields, ''))
    error('This is not allowed. There must be written name of field eather in function or in cfield.');
end

% -- if nfields is empty then cfields will be overwtitten
if any(strcmpi(nfields, ''))
    if any(strcmpi(cfields, ''))
        error('This field must be defined.')
    else
        nfields = cfields;
    end
end

% -- if nfields is empty then cfields will be overwtitten
if length(cfunction) ~= length(nfields)
    if length(nfields) == 1
        nfields = repmat(nfields, 1, length(cfunction));
    else
        error('Something is wrong.')
    end
end

% -- repmat operation field
if length(cfunction) ~= length(cfields)
    if length(cfields) == 1
        cfields = repmat(cfields, 1, length(cfunction));
    end
end

%% -- apply functions

y = s;
k1 = 1;
while k1 <= length(cfunction)
    
    k2 = 1;
    if size(y, 2) > size(y, 1)
        n = size(y, 2);
    else
        n = size(y, 1);
    end
    while k2 <= n
        
        if strcmpi(cfields(k1), '')
            y(k2).(nfields{k1}) = feval(cfunction{k1}, y(k2));
        else
            if ~iscell(y(k2).(cfields{k1}))
                y(k2).(nfields{k1}) = feval(cfunction{k1}, y(k2).(cfields{k1}));
            else
                y(k2).(nfields{k1}) = num2cell(feval(cfunction{k1}, cell2mat(y(k2).(cfields{k1}))));
            end
        end
        
        k2 = k2 + 1;
        
    end
    
    k1 = k1 + 1;
    
end

end


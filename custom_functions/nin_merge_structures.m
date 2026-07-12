function [s] = nin_merge_structures(s1, s2, keys, varargin)

%% This function mearge two structures according to some criteria
%
% - inputs:
% s1 and s2: input structures and they have to have at least one common field
% keys: cell array of field that would be used as key
%
% - optional:
% keepData: both/left/right/common/difference output structure form (default: 'both')
% fieldorder: stable/sorted order of fields in otuput structure (default: 'stable')
% sufix1/sufix2: sufix that would be added to name of fields that are common for both structures (default: 'L'/'R')
%
% - example:
% cemg = nin_subselect_dstruct(emg, 'recording', 'BeTr01', 'filename_new', 'IMONAS-acute_study_120RMT-intervention_R002.xdf');

% -- read input parameters
nin_import_params(varargin);

%% -- set default values

% -- output structure form
if ~exist('keepData', 'var')
    keepData = 'both';
end

% -- order of fielsd in output structure
if ~exist('fieldorder', 'var')
    fieldorder = 'stable';
end

% -- sufix for the first input
if ~exist('sufix1', 'var')
    sufix1 = 'L';
end

% -- sufix for the second input
if ~exist('sufix2', 'var')
    sufix2 = 'R';
end

% -- make sure that key are stored in cell array
if ~iscell(keys)
    keys = {keys};
end

% -- check the field in structures
s1_fnames = fieldnames(s1);
s2_fnames = fieldnames(s2);

% -- make sure that key fields could be found in both structures
u_fnames = union(s1_fnames, s2_fnames, fieldorder);
c_fnames = intersect(s1_fnames, s2_fnames);

if length(keys) > length(c_fnames)
    error('Number of common fields is less than number of keys.');
end

if ~all(ismember(keys, c_fnames))
    error('Key field is nt commont for both structures.');
end

%% -- prepare data for merging process

% -- extract field with keys from structures
KF1 = cell(length(s1), length(keys)); KF2 = cell(length(s2), length(keys));
k = 1;
while k <= length(keys)
    cKF1 = {s1.(keys{k})}';
    cKF2 = {s2.(keys{k})}';
    
    if isnumeric(cKF1{1})
        cKF1 = cellfun(@num2str, cKF1, 'un', 0);
    end
    if isnumeric(cKF2{1})
        cKF2 = cellfun(@num2str, cKF2, 'un', 0);
    end
    
    KF1(:, k) = cKF1;
    KF2(:, k) = cKF2;
    
    k = k + 1;
end

% -- find unique combination of keys
[uKF1, ndx1, pos1] = uniqueRowsCA(KF1, true, 'first');
uKF1 = uKF1(pos1, :);
[uKF2, ndx2, pos2] = uniqueRowsCA(KF2, true, 'first');
uKF2 = uKF2(pos2, :);
[uKF, ndx, pos] = uniqueRowsCA([uKF1; uKF2], true, 'first');
[~, pos] = sort(ndx);
uKF = uKF(pos, :);

% -- check if both structures contain all key combinations
ix1 = false(length(s1), length(keys));
ix2 = false(length(s2), length(keys));
k1 = 1;
while k1 <= size(uKF, 1)
    k2 = 1;
    while k2 <= length(keys)
        ix1(k1, k2) = any(strcmpi(uKF1(:, k2), uKF{k1, k2}));
        ix2(k1, k2) = any(strcmpi(uKF2(:, k2), uKF{k1, k2}));
        k2 = k2 + 1;
    end
    k1 = k1 + 1;
end
ix1 = all(ix1, 2);
ix2 = all(ix2, 2);

% -- decision which set of key inputs is going to be kept
switch keepData
    case 'both'
        
    case 'left'
        uKF = uKF(ix1, :);
    case 'rigth'
        uKF = uKF(ix2, :);
    case 'common'
        uKF = uKF(ix1&ix2, :);
    case 'difference'
        uKF = uKF(~(ix1&ix2), :);
    otherwise
        error('Method has not been found.')
end

%% -- merge structures

s = [];
k1 = 1;
while k1 <= size(uKF, 1)
    
    ix1 = false(size(KF1, 1), length(keys));
    ix2 = false(size(KF2, 1), length(keys));
    k2 = 1;
    while k2 <= length(keys)
        ix1(:, k2) = strcmp(KF1(:, k2), uKF{k1, k2});
        ix2(:, k2) = strcmp(KF2(:, k2), uKF{k1, k2});
        k2 = k2 + 1;
    end
    ix1 = all(ix1, 2);
    ix2 = all(ix2, 2);
    
    cs1 = s1(ix1);
    cs2 = s2(ix2);
    
    if isempty(cs1)
        cs1 = add_val(cs1, s1);
    end
    if isempty(cs2)
        cs2 = add_val(cs2, s2);
    end
    
    clear cs
    k = 1;
    k2 = 1;
    while k2 <= length(cs1)
        k3 = 1;
        while k3 <= length(cs2)
            cs(k) = struct_merge(cs1(k2), cs2(k3), u_fnames', sufix1, sufix2, keys);
            k = k + 1;
            k3 = k3 + 1;
        end
        k2 = k2 +1;
    end
    
    s = [s, cs];
    k1 = k1 + 1;
end

c_fnames = setdiff(c_fnames, keys)';

%% -- remove redundant fields
if ~isempty(c_fnames)
    s = check_double(s, c_fnames, sufix1, sufix2);
end

end

function y = add_val(x, s)

% -- fill structure with empty values
y = struct;
fnames = fieldnames(x);

k1 = 1;
while k1 <= length(fnames)
    if isnumeric(s(1).(fnames{k1}))
        y.(fnames{k1}) = NaN(size(s(1).(fnames{k1})));
    elseif ischar(s(1).(fnames{k1}))
        y.(fnames{k1}) = '';
    elseif iscell(s(1).(fnames{k1}))
        y.(fnames{k1}) = repmat({''}, size(s(1).(fnames{k1})));
    end
    k1 = k1 + 1;
end

end

function s = struct_merge(s1, s2 , u_fnames, name1, name2, keys)

s = struct;

% -- merge structures
for cname = u_fnames
    
    if isfield(s1, cname{1, 1}) && isfield(s2, cname{1, 1})
        
        if any(ismember(keys, cname{1, 1}))
            if isequal(s1.(cname{1, 1}), s2.(cname{1, 1}))
                s.(cname{1, 1}) = s1.(cname{1, 1});
            elseif any(isnan(s1.(cname{1, 1}))) || isempty(s1.(cname{1, 1})) || strcmpi(s1.(cname{1, 1}), '')
                s.(cname{1, 1}) =  s2.(cname{1, 1});
            elseif any(isnan(s2.(cname{1, 1}))) || isempty(s2.(cname{1, 1})) || strcmpi(s2.(cname{1, 1}), '')
                s.(cname{1, 1}) =  s1.(cname{1, 1});
            end
        else
            s.([cname{1, 1}, '_', name1]) = s1.(cname{1, 1});
            s.([cname{1, 1}, '_', name2]) = s2.(cname{1, 1});
        end
        
    elseif isfield(s1, cname{1, 1})
        
        s.(cname{1, 1}) = s1.(cname{1, 1});
        
    elseif isfield(s2, cname{1, 1})
        
        s.(cname{1, 1}) = s2.(cname{1, 1});
        
    end
    
end

end

function s_out = check_double(s_in, c_fields, sufix1, sufix2)

discard = [];

% -- check if common fields have the same values
for cname = c_fields
    
    if isnumeric(s_in(1).([cname{1, 1}, '_', sufix1]))
        x1 = [s_in.([cname{1, 1}, '_', sufix1])];
        x2 = [s_in.([cname{1, 1}, '_', sufix2])];
        
        same_rows = x1 == x2;
    elseif ischar(s_in(1).([cname{1, 1}, '_', sufix1]))
        x1 = {s_in.([cname{1, 1}, '_', sufix1])};
        x2 = {s_in.([cname{1, 1}, '_', sufix2])};
        k = 1;
        same_rows = false(length(x1), 1);
        while k <= length(x1)
            if strcmpi(x1{k}, x2{k})
                same_rows(k) = true;
%                 k = k + 1;
            end
            k = k + 1;
        end
    end
    
    if all(same_rows)
        discard = [discard, cname];
    end
    
end

% -- remove and rename fields
if ~isempty(discard)
    s_out = rmfield(s_in, strcat(discard, '_', sufix2));
    s_out = rnfield(s_out, strcat(discard, '_', sufix1), discard);
else
    s_out = s_in;
end

end

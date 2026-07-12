function [y] = nin_ctime(varargin)

%% This function returns current time and date
%
% - input:
%
% - optional:
% outFormat: output format 'date', 'time', or 'date_time' (default: 'date')
% joinmethod: separator used to join date and time components (default: '_')
%
% - example:
% cdate  = nin_ctime;
% ctime = nin_ctime('outFormat', 'time');

% -- read input parameters
nin_import_params(varargin);

% -- set default output format
if ~exist('outFormat', 'var')
    outFormat = 'date';
end

% -- set default separator
if ~exist('joinmethod', 'var')
    joinmethod = '_';
end

% -- get current date and time
format shortg
ctime = clock;

% -- remove fractional seconds
ctime(end) = fix(ctime(end));

% -- convert numeric values to strings
ctime = num2cell(ctime);
ctime = cellfun(@num2str, ctime, 'un', 0);

% -- find single-digit elements
l = cell2mat(cellfun(@length, ctime, 'un', 0));
ix = l < 2;

% -- add leading zeros where needed
if any(ix)
    ctime(ix) = strcat('0', ctime(ix));
end

% -- format output string
switch outFormat

    case 'date'
        y = strjoin(ctime(1:3), joinmethod);
    case 'time'
        y = strjoin(ctime(4:end-1), joinmethod);
    case 'date_time'
        y = strjoin(ctime(1:end-1), joinmethod);

end

end

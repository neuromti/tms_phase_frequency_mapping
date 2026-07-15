function [pro_struct] = def_pro(pro_name, varargin)

%% This function defines project directories and creates a backup copy
%
% -- inputs:
% pro_name: analysis name (e.g., JNS_2026a - analysis name and year)
%
% -- optional:
% saveWork: flag for making a copy of scripts
% loadEEGLAB: add EEGLab's folder to the path

% -- read input parameters
import_params(varargin);

% -- set saveWork flag
if ~exist('saveWork', 'var')
    pro_struct.saveWork = false;
else
    pro_struct.saveWork = saveWork;
end

% -- set loadEEGLAB flag
if ~exist('loadEEGLAB', 'var')
    pro_struct.loadEEGLAB = false;
else
    pro_struct.loadEEGLAB = loadEEGLAB;
end

% -- get caller function information
fname = dbstack;
pro_struct.function_name = fname(2).name;

% -- store project name
pro_struct.pro_name = pro_name;

% -- read local configuration file
A = textread('local_settings.config', '%s', 'whitespace', '');

% -- evaluate configuration settings
eval(A{:});

% -- define and add 'custom_funtions' path
pro_struct.NIN_path = NINpath;
addpath(genpath(pro_struct.NIN_path));

% -- add eeglab to matlab path if requested
if pro_struct.loadEEGLAB
    pro_struct.EEGLAB_path = EEGLABpath;
    addpath(pro_struct.EEGLAB_path);
end

% -- get current date and time
cdate = nin_ctime('outFormat', 'date');
chour = nin_ctime('outFormat', 'time');
ctime = nin_ctime;

if pro_struct.saveWork
    
    % -- define archive directory
    pro_struct.archive_path = [pwd, filesep, 'code_archive', filesep, pro_struct.function_name, '_', pro_struct.pro_name, filesep, cdate, filesep];
    
    % -- define nin backup directory and create backup directory if needed
    pro_struct.archive_NIN_path = [pro_struct.archive_path, 'NIN_', chour, filesep];
    if ~isfolder(pro_struct.archive_NIN_path)
        mkdir(pro_struct.archive_NIN_path)
    end
    
    % -- create backup copies
    if pro_struct.saveWork
        copyfile(pro_struct.NIN_path, pro_struct.archive_NIN_path);
        copyfile([pwd filesep pro_struct.function_name '.m'], [pro_struct.archive_path, pro_struct.function_name, '_', pro_struct.pro_name, '_', ctime, '.m']);
    end
    
end

end

% -- assign optional input parameters to caller workspace
function import_params(oinputs)
for kv = 1:2:length(oinputs)
    assignin('caller', oinputs{kv}, oinputs{kv+1})
end
end
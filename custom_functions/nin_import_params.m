function nin_import_params(oinputs)

%% This function imports optional input arguments into the caller workspace
%
% - input:
%  oinputs: cell array containing name-value pairs
%
% -- example: 
% nin_import_params({'alpha', 0.05, 'method', 'mean'});

%% -- assign optional inputs to caller workspace

for kv = 1:2:length(oinputs)

     % -- create variable from name-value pair
    assignin('caller', oinputs{kv}, oinputs{kv+1})
    
end

end

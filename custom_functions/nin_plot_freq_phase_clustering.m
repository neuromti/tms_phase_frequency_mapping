function [h] = nin_plot_freq_phase_clustering(x, varargin)

%% This function plots phase and frequency results
%
% - inputs:
% x: data structure
%
% - optional:
% eegsys: eegsystem used for data recording (default: 'BrainVision')
% match_case: exact/partial type of subselecting data (default: 'exact')
% fonts: figure font size (default: 10)
% fposition: figure position (default: full screen)
% dnorm: normalize data (default: '')
% crange: y range (default: [])
% barp: position of the color bar (default: [0.92 0.2 0.01 0.6])
% sp: number of subplots (default: [10 11])
% scolumns: subselect columns (deault: all)
% srows: subselect rows (deault: all)
% tphase: add legend or not (default: false)
% tfreq: subselect columns (deault: all)
% psort: minmax/mirror phase sorting (default: 'minmax')
% cdeg2rad: conversion deg into rad (default: false)
% mapcolor: color map (default: 'default')
% absval: plot the abs value of data (default: false)
% range_step: step of my range (default: 0.04)
% cdirection: clustering direction (default: 8)
%
% - example:
% [h] = nin_plot_freq_phase(cpeak_avg_o, 'scolumns', {'P25_amp'});
% [h] = nin_plot_freq_phase(cpeak_avg_o, 'scolumns', {'P25_amp'}, 'crange', [0 5]);
% [h] = nin_plot_freq_phase(cpeak_avg_o, 'scolumns', {'N100_amp'}, 'dnorm', 'normalized');
% [h] = nin_plot_freq_phase(cpeak_avg_o, 'scolumns', {'N100_amp'}, 'dnorm', 'normalized', 'crange', [0, 1], 'srows', {'C3'}, 'sp', [1 1]);

% -- read input parameters
nin_import_params(varargin);

%% -- set default values

if ~exist('eegsys', 'var')
    eegsys = 'BrainVision';
end

% -- set matching criteria
if ~exist('match_case', 'var')
    match_case = 'exact';
end

% -- font size of figure
if ~exist('fonts', 'var')
    fonts = 10;
end

% -- figure position
if ~exist('fposition', 'var')
    fposition = get(0, 'ScreenSize');
end

% -- data normalization
if ~exist('dnorm', 'var')
    dnorm = '';
end

% -- range of y axes
if ~exist('crange', 'var')
    crange = [];
else
    crange1 = crange(1);
    crange2 = crange(2);
end

% -- position of colorbar
if ~exist('barp', 'var')
    barp = [0.92 0.2 0.01 0.6];
end

% -- number of subplots
if ~exist('sp', 'var')
    sp = [10, 11];
end

% -- define eeg system
if ~strcmpi(eegsys, '')
    eegsystem = nin_eeg_system(eegsys);
else
    eegsystem.nochannels = length(x(1).data_rows);
end

% -- make sure that values in columns are char
if isnumeric(x(1).data_columns{1, 1})
    ccolumns = cellfun(@num2str, x(1).data_columns, 'un', 0);
else
    ccolumns = x(1).data_columns;
end

% -- find selected data columns
if ~exist('scolumns', 'var')
    ixc = 1:length(ccolumns);
else
    ixc = false(1, length(ccolumns));
    k = 1;
    while k <= length(ixc)
        switch match_case
            case 'exact'
                if any(strcmpi(scolumns, ccolumns{k}))
                    ixc(k) = true;
                end
            case 'partial'
                ixc = contains(ccolumns, scolumns);
        end
        k = k + 1;
    end
end
scolumns = ccolumns(ixc);
ixc = find(ixc);


% -- find selected data rows
crows = x(1).data_rows;
if exist('srows', 'var')
    ixr = false(1, length(crows));
    k = 1;
    while k <= length(ixr)
        switch match_case
            case 'exact'
                if any(strcmpi(srows, crows{k}))
                    ixr(k) = true;
                end
            case 'partial'
                ixr = contains(crows, srows);
        end
        k = k + 1;
    end
    x = nin_function(x, @(x) x(ixr, :), {'data'}, {'data'});
    [x.data_rows] = deal(srows);
    
    eegsys = '';
    eegsystem.nochannels = length(srows);
end

% -- phase field
if ~exist('tphase', 'var')
    tphase = 'tphase';
end

% -- freq field
if ~exist('tfreq', 'var')
    tfreq = 'tfreq';
end

% -- phase sort
if ~exist('psort', 'var')
    psort = 'minmax';
end

% -- deg 2 rad
if ~exist('cdeg2rad', 'var')
    cdeg2rad = false;
end

% -- mapcolor
if ~exist('cmapcolor', 'var')
    mapcolor = 'default';
end

% -- absval
if ~exist('absval', 'var')
    absval = false;
end

% -- range_step
if ~exist('range_step', 'var')
    range_step = 0.04;
end

% -- cdirection
if ~exist('cdirection', 'var')
    cdirection = 8;
end

%% -- sort data

switch psort
    
    case 'minmax'
        
        uphase = sort(cell2mat(cellfun(@str2num, unique({x.(tphase)}), 'un', 0)));
        uphase = cellfun(@num2str, num2cell(uphase), 'un', 0);
        
    case 'mirror'
        
        uphase = {'180', '225', '270', '315', '0', '45', '90', '135', '180'};
        
end

ufreq = sort(cell2mat(cellfun(@str2num, unique({x.(tfreq)}), 'un', 0)));
ufreq = cellfun(@num2str, num2cell(ufreq), 'un', 0);

x_sorted = [];
k1 = 1;
while k1 <= length(ufreq)
    
    cdata = nin_subselect_dstruct(x, tfreq, ufreq{k1});
    [~, ix] = ismember(uphase, {cdata.(tphase)});
    cdata = cdata(ix);
    
    x_sorted = [x_sorted, cdata];
    
    k1 = k1 + 1;
    
end
x_orig = x;
x = x_sorted;

clear x_sorted

% -- x-axes
uphase_p = uphase;
if cdeg2rad && strcmpi(psort, 'mirror')
    k1 = 1;
    while k1 <= length(uphase)
        switch uphase{k1}
            case '45'
                uphase_p{k1} = '\pi/4';
            case '90'
                uphase_p{k1} = '\pi/2';
            case '135'
                uphase_p{k1} = '\3pi/4';
            case '180'
                uphase_p{k1} = '\pi';
            case '225'
                uphase_p{k1} = '-3\pi/4';
            case '270'
                uphase_p{k1} = '-\pi/2';
            case '315'
                uphase_p{k1} = '-\pi/4';
        end
        k1 = k1 + 1;
    end
end


%% -- plot data

if eegsystem.nochannels > sp(1)*sp(2)
    error('Not enough subplots.');
end

if ~strcmpi(eegsys, '')
    last_plot = find(eegsystem.ix_plot ~= 0);
    last_plot = last_plot(end);
else
    last_plot = eegsystem.nochannels;
end

afreq = {x.(tfreq)};
aphase = {x.(tphase)};
k3 = 1;
while k3 <= length(scolumns)
    
    ix_ch = strcmpi(x(1).data_columns, scolumns{k3});
    
    h = figure('color', [1 1 1], 'name', 'All', 'position', fposition);
    kp = 1;
    
    k = 1;
    while k <= length(x(1).data_rows)
        
        cdata = NaN(length(ufreq), length(uphase));
        
        k1 = 1;
        while k1 <= length(ufreq)
            
            k2 = 1;
            while k2 <= length(uphase)
                
                [~, ix_f] = ismember(afreq, ufreq(k1));
                [~, ix_p] = ismember(aphase, uphase(k2));
                
                ixc = ix_f & ix_p;
                if nnz(ixc) > 1
                    ixcf = find(ixc);
                    ixc(ixcf(2:end)) = false;
                end
                cdata(k1, k2) = x(ixc).data(k, ix_ch);
                
                k2 = k2 + 1;
                
            end
            
            k1 = k1 + 1;
            
        end
        
        cdata = flipud(cdata);
        
        switch dnorm
            case 'normalized'
                cdata = cdata./max(abs(cdata), [], 'all');
            case 'zscored'
                cdata = zscore(cdata, 0, 'all');
        end
        
        subplot(sp(1), sp(2), kp);
        kp = kp + 1;
        
        if ~isempty(crange)
            imagesc(cdata, [crange1 crange2]);
        else
            imagesc(cdata);
        end
        colormap(mapcolor);
        cmap = get(gca, 'colormap');
        cmapu = fix(cmap*10);
        cmapu = cmapu(:, 2);
        cbar = colorbar;
        
        y_tx = 1:length(ufreq);
        set(gca, 'ytick', y_tx);
        y_txl = repmat({''}, 1, length(ufreq));
        y_txl = fliplr(ufreq);
        y_txl(length(ufreq):-2:2) = {''};
        set(gca, 'yticklabels', y_txl);
        ylabel('Frequency (Hz)');
        
        x_tx = 1:length(uphase);
        set(gca, 'xtick', x_tx);
        x_txl = repmat({''}, 1, length(uphase));
        
        switch psort
            case 'minmax'
                x_txl(1:2:end-1) = uphase_p(1:2:end-1);
            case 'mirror'
                x_txl(1:2:end) = uphase_p(1:2:end);
        end
        set(gca, 'xticklabels', x_txl);
        
        if cdeg2rad
            xlabel('Phase (rad)');
        else
            xlabel('Phase (deg)');
        end
        
        set(gca, 'fontweight', 'bold');
        
        title(x(k2).data_rows{k}, 'fontsize', fonts, 'fontweight', 'bold');
        
        crange = cbar.Limits;
        cscale = rescale(1:size(cmap, 1), crange(1), crange(2))';
        myscale = crange(1):range_step:crange(2);
        
        % -- find cluster
        kc_min = 1;
        kc_max = length(myscale);
        kc = kc_min;
        while kc <= kc_max
            
            if kc == 1
                ix_r = kc;
                % [CB, C, n] = bwboundaries(cdata <= myscale(ix_r), cdirection);
                [C, n] = bwlabel(cdata <= myscale(ix_r), cdirection);
                fName = ['amp < ', num2str(myscale(ix_r), '%.2f')];
            elseif kc == kc_max
                ix_l = kc;
                % [CB, C, n] = bwboundaries(cdata > myscale(ix_l), cdirection);
                [C, n] = bwlabel(cdata > myscale(ix_l), cdirection);
                fName = ['amp > ', num2str(myscale(ix_l), '%.2f')];
            else
                ix_l = kc;
                ix_r = kc + 1;
                % [CB, C, n] = bwboundaries(cdata > myscale(ix_l) & cdata <= myscale(ix_r), cdirection);
                [C, n] = bwlabel(cdata > myscale(ix_l) & cdata <= myscale(ix_r), cdirection);
                fName = [num2str(myscale(ix_l), '%.2f'), '< amp < ', num2str(myscale(ix_r), '%.2f')];
            end
            
            % -- find pixels
            CB = cell(n, 1);
            k1 = 1;
            while k1 <= n
                [I, J] = find(C == k1);
                CB{k1} = [I, J];
                k1 = k1 + 1;
            end
            
            if ~isempty(CB)
                
                s = cell2mat(cellfun(@(x) size(x, 1), CB, 'un', 0));
                [~, ix_maxc] = max(s);
                CB = CB(ix_maxc);
                
                subplot(sp(1), sp(2), kp);
                kp = kp + 1;
                imagesc(cdata, crange);
                hold on;
                
                kb = 1;
                while kb <= length(CB)
                    
                    cboundary = CB{kb};
                    
                    mask = C == ix_maxc;
                    
%                     % -- keep just these with eucliden distanve sqrt(2)
%                     m = size(mask, 1);
%                     n = size(mask, 2);
%                     cboundary_r = [];
%                     for kl = 1:min(size(mask))
%                         
%                         klc = kl;
%                         Ipl = (1 - min(klc, 0):min(m, n - klc))';
%                         Jpl = Ipl + klc;
%                         Ipr = (min(m, n - klc):-1:1 - min(klc, 0))';
%                         Jpr = Jpl;
%                         
%                         klc = -kl;
%                         Inl = (1 - min(klc, 0):min(m, n - klc))';
%                         Jnl = Inl + klc;
%                         Inr = (min(m, n - klc):-1:1 - min(klc, 0))';
%                        Jnr = Jnl;
% 
% %                        cboundary_r = [cboundary_r;...
% %                            [Jpl, Ipl];...
% %                            [Jnl, Inl];...
% %                            [Jpr, Ipr];...
% %                            [Jnr, Inr];];
%                        cboundary_r = [cboundary_r;...
%                                       [Ipl, Jpl];...
%                                       [Inl, Jnl];...
%                                       [Ipr, Jpr];...
%                                       [Inr, Jnr];];
%                     end
%                     
%                     cboundary_n = [];
%                     for kl = 1:size(cboundary, 1)
%                         if any(cboundary_r(:, 1) == (cboundary(kl, 1)) & cboundary_r(:, 2) == (cboundary(kl, 2)))
%                     cboundary_n = [cboundary_n; cboundary(kl, :)];
%                         end
%                     end
%                     
%                     cboundary = cboundary_n;
                    
                    for kl = 1:size(cboundary, 1)
                        
                        xb = cboundary(kl, 2);
                        yb = cboundary(kl, 1);
                        l_x = xb - 1;
                        a_x = xb;
                        r_x = xb + 1;
                        b_x = xb;
                        
                        l_y = yb;
                        a_y = yb - 1;
                        r_y = yb;
                        b_y = yb + 1;
                        
                        plot(xb, yb, 'w+', 'MarkerSize', 8);
                        
                        % down
                        if (b_y > size(cdata, 1))
                            % plot([xb - 0.5 xb + 0.5], [yb + 0.5 yb + 0.5], 'w-', 'LineWidth', 2);
                            line([xb - 0.5 xb + 0.5], [yb + 0.5 yb + 0.5], 'Color', 'w', 'LineStyle', '-', 'LineWidth', 3);
                        elseif mask(b_y, b_x) == false
                            % plot([xb - 0.5 xb + 0.5], [yb + 0.5 yb + 0.5], 'w-', 'LineWidth', 2);
                            line([xb - 0.5 xb + 0.5], [yb + 0.5 yb + 0.5], 'Color', 'w', 'LineStyle', '-', 'LineWidth', 3);
                        end
                        
                        % left
                        if (l_x < 1)
                            % plot([xb - 0.5 xb - 0.5], [yb - 0.5 yb + 0.5], 'w-', 'LineWidth', 2);
                            line([xb - 0.5 xb - 0.5], [yb - 0.5 yb + 0.5], 'Color', 'w', 'LineStyle', '-', 'LineWidth', 3);
                        elseif mask(l_y, l_x) == false
                            % plot([xb - 0.5 xb - 0.5], [yb - 0.5 yb + 0.5], 'w-', 'LineWidth', 2);
                            line([xb - 0.5 xb - 0.5], [yb - 0.5 yb + 0.5], 'Color', 'w', 'LineStyle', '-', 'LineWidth', 3);
                        end
                        
                        % up
                        if (a_y < 1)
                            % plot([xb - 0.5 xb + 0.5], [yb - 0.5 yb - 0.5], 'w-', 'LineWidth', 2);
                            line([xb - 0.5 xb + 0.5], [yb - 0.5 yb - 0.5], 'Color', 'w', 'LineStyle', '-', 'LineWidth', 3);
                        elseif mask(a_y, a_x) == false
                            % plot([xb - 0.5 xb + 0.5], [yb - 0.5 yb - 0.5], 'w-', 'LineWidth', 2);
                            line([xb - 0.5 xb + 0.5], [yb - 0.5 yb - 0.5], 'Color', 'w', 'LineStyle', '-', 'LineWidth', 3);
                        end
                        
                        % right
                        if (r_x > size(cdata, 2))
                            % plot([xb + 0.5 xb + 0.5], [yb - 0.5 yb + 0.5], 'w-', 'LineWidth', 2);
                            line([xb + 0.5 xb + 0.5], [yb - 0.5 yb + 0.5], 'Color', 'w', 'LineStyle', '-', 'LineWidth', 3);
                        elseif mask(r_y, r_x) == false
                            % plot([xb + 0.5 xb + 0.5], [yb - 0.5 yb + 0.5], 'w-', 'LineWidth', 2);
                            line([xb + 0.5 xb + 0.5], [yb - 0.5 yb + 0.5], 'Color', 'w', 'LineStyle', '-', 'LineWidth', 3);
                        end
                        
                    end
                    
                    kb = kb + 1;
                    
                end
                
            end
            
            y_tx = 1:length(ufreq);
            set(gca, 'ytick', y_tx);
            y_txl = repmat({''}, 1, length(ufreq));
            y_txl = fliplr(ufreq);
            y_txl(length(ufreq):-2:2) = {''};
            set(gca, 'yticklabels', y_txl);
            ylabel('Frequency (Hz)');
            
            x_tx = 1:length(uphase);
            set(gca, 'xtick', x_tx);
            x_txl = repmat({''}, 1, length(uphase));
            
            switch psort
                case 'minmax'
                    x_txl(1:2:end-1) = uphase_p(1:2:end-1);
                case 'mirror'
                    x_txl(1:2:end) = uphase_p(1:2:end);
            end
            set(gca, 'xticklabels', x_txl);
            
            if cdeg2rad
                xlabel('Phase (rad)');
            else
                xlabel('Phase (deg)');
            end
            
            set(gca, 'fontweight', 'bold');
            
            title(fName, 'fontsize', fonts, 'fontweight', 'bold');
            
            kc = kc + 1;
            
        end
        
        k = k + 1;
        
    end
    
    set(h, 'color', [1 1 1]);
    
    k3 = k3 + 1;
    
end

end
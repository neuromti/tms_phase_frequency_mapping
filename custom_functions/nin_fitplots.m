function [h, y] = nin_fitplots(x, varargin)

%% This function plots phase-dependent data, performs sinusoidal fitting, and estimates modulation strength
%
% - input:
% x: structure with input data
%
% - optional:
% match_case: matching mode for row and column selection: 'exact' or 'partial' (default: 'exact')
% spliter: delimiter used by nin_strsplit (default: '_')
% rn1: first row index used by nin_strsplit (default: 1)
% rn2: last row index used by nin_strsplit (default: 1)
% cn1: first column index used by nin_strsplit (default: 2)
% cn2: last column index used by nin_strsplit (default: 2)
% srowscolumns: row-column combinations to plot (default: all)
% srows: selected rows (default: all)
% scolumns: selected columns (default: all)
% dim: plotting dimension (default: 2)
% mycolors: color of bar (default: 'k')
% blinewidth: line width (default: 3)
% fonts: plot color (default: 10)
% fontm: annotation font size (default: 6)
% mycolorsl: fitting line color (default: 'r')
% cyrange: y-axis limits (default: [0 1])
% cxrange: x-axis limits (default: [-0.5 6])
% fmethod: fitting method (default: cos)
% cylabel: y-axis label (default: '')
% cxlabel: x-axis label (default: '')
% xx: x-axis values (default: [0:45:315] in rad)
% n_perm: number of permutation (default: 1000)
% shift_data: z-score data before fitting (default: true)
% disp_status: display figures (default: true)
% disp_p: display p-values (default: true)
% p_th: significance threshold (default: 0.05)
%
% - example:
% [h, y] = nin_fitplots(R);
% [h, y] = nin_fitplots(R, 'dim', 1);

% -- read input parameters
nin_import_params(varargin);

%% -- set default parameters

% -- define type of matching
if ~exist('match_case', 'var')
    match_case = 'exact';
end

% -- define lower border rows
if ~exist('rn1', 'var')
    rn1 = 1;
end

% -- define upper border rows
if ~exist('rn2', 'var')
    rn2 = 1;
end

% -- define lower border columns
if ~exist('cn1', 'var')
    cn1 = 2;
end

% -- define upper border columns
if ~exist('cn2', 'var')
    cn2 = 2;
end

% -- define delimiter
if ~exist('spliter', 'var')
    spliter = '_';
end

% -- convert row labels to strings
if isnumeric(x(1).data_rows{1, 1})
    crows = cellfun(@num2str, x(1).data_rows, 'un', 0);
else
    crows = x(1).data_rows;
end

% -- convert column labels to strings
if isnumeric(x(1).data_columns{1, 1})
    ccolumns = cellfun(@num2str, x(1).data_columns, 'un', 0);
else
    ccolumns = x(1).data_columns;
end

% -- determine rows and columns for plotting
if ~exist('srowscolumns', 'var')

    % -- find selected rows
    if ~exist('srows', 'var')
        ixr = 1:length(crows);
    else
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
    end
    srows = crows(ixr);

    % -- find selected columns
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

else

    % -- extract row and column identifiers
    crows = nin_strsplit(ifield, rn1, rn2, 'spliter', spliter);
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
    srows = crows(ixr);

    ccolumns = nin_strsplit(ifield, cn1, cn2, 'spliter', spliter);
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
    scolumns = ccolumns(ixc);

end

% -- define plotting dimension
if ~exist('dim', 'var')
    dim = 2;
end

% -- define fitting line color
if ~exist('mycolors', 'var')
    mycolors = 'k';
end

% -- define line width
if ~exist('blinewidth', 'var')
    blinewidth = 3;
end

% -- define fitting line color
if ~exist('mycolorsl', 'var')
    mycolorsl = 'r';
end

% -- define axis font size
if ~exist('fonts', 'var')
    fonts = 10;
end

% -- define annotation font size
if ~exist('fontm', 'var')
    fontm = 6;
end

% -- define y-axis limits
if ~exist('crange', 'var')
    range1 = 0;
    range2 = 1;
else
    if ~isempty(crange)
        if ischar(crange(1))
            if strcmpi(crange, 'minmax')
                % add this
            elseif strcmpi(crange, 'absmax')
                % add this
            end
        else
            range1 = crange(1);
            range2 = crange(2);
        end
    end
end

% -- define x-axis limits
if ~exist('cxrange', 'var')
    xrange1 = -0.5;
    xrange2 = 6;
else
    if ~isempty(cxrange)
        if ischar(crange(1))
            if strcmpi(crange, 'minmax')
                % add this
            elseif strcmpi(crange, 'absmax')
                % add this
            end
        else
            xrange1 = cxrange(1);
            xrange2 = cxrange(2);
        end
    end
end

% -- define y-axis label
if ~exist('cylabel', 'var')
    cylabel = '';
end

% -- define x-axis label
if ~exist('cxlabel', 'var')
    cxlabel = '';
end

% -- define x-axis values
if ~exist('xx', 'var')
    xx = [0:45*3.14/180:315*3.14/180];
end

% -- define fitting method
if ~exist('ffit', 'var')
    ffit = 'cos';
    %     ffit = 'sin';
end

% -- define number of permutation
if ~exist('n_perm', 'var')
    n_perm = 1000;
end

% -- define names of fitted statistics
if ~exist('fstat_name', 'var')
    fstat_name = {'amp', 'phase'};
end

% -- z-score data before fitting
if ~exist('shift_data', 'var')
    shift_data = true;
end

% -- display figures
if ~exist('disp_status', 'var')
    disp_status = true;
end

% -- display p-values on figures
if ~exist('disp_p', 'var')
    disp_p = true;
end

% -- significance threshold for highlighting p-values
if ~exist('p_th', 'var')
    p_th = 0.05;
end


rng(1, 'twister');

%% -- fit and plot phase-dependent data

if dim == 2

    % -- plot selected columns
    k = 1;
    while k <= length(scolumns)

        if disp_status
            h(k) = figure('color', [1 1 1], 'name', scolumns{k});
        else
            h = [];
        end

        % -- extract selected data
        sdata = nin_struct2cell_form(x, 'srows', srows, 'scolumns', scolumns{k}, 'otype', 'cell', 'smeta', []);

        % -- extract plot labels
        sdata(2:end, :) = cellfun(@double, sdata(2:end, :), 'un', 0);

        header = nin_strsplit(sdata(1, :), 'first', [], 'spliter', '_');
        sdata = double(cell2mat(sdata(2:end, :)));

        if all(~isnan(sdata))

            % -- normalize data across phases
            if shift_data

                sdata = zscore(sdata);

            end

            % -- calculate mean values
            avg = nanmean(sdata, 1);
            % -- calculate standard error of the mean
            sem = nanstd(sdata, 1)./sqrt(sum(~isnan(sdata), 1));

            % -- initialize permutation analysis
            n = size(sdata, 2);
            m = size(sdata, 1);
            ix = NaN(m, n);
            pavg = NaN(m, n);
            pcval = NaN(n_perm, 2);
            k3 = 1;
            while k3 <= n_perm

                % -- randomly shuffle phase labels
                k2 = 1;
                while k2 <= m

                    ix(k2, :) = randperm(n);
                    pcdata(k2, :) = sdata(k2, ix(k2, :));

                    k2 = k2 + 1;

                end

                % -- calculate permuted mean response
                pcdata = sdata(ix);
                pavg = nanmean(pcdata, 1);

                % -- fit sinusoidal model to permuted data
                switch ffit

                    case 'cos'

                        % -- fit model to permuted data
                        fmethod = fittype(@(a1,b1,c1,x) a1*cos(x+b1)+c1,...
                            'coefficients', {'a1', 'b1', 'c1'});

                        [curve, goodness, output] = fit(xx', pavg', fmethod);

                        % -- store fit results
                        py(k3).name = scolumns{k};
                        py(k3).x = xx';
                        py(k3).y = pavg';
                        py(k3).curve = curve;
                        py(k3).goodness = goodness;
                        py(k3).output = output;

                        % -- extract fitted coefficients and confidence intervals
                        py(k3).coeffnames = coeffnames(curve);
                        py(k3).coeffvalues = coeffvalues(curve)';
                        py(k3).confint = confint(curve)';

                        % -- extract modulation amplitude and phase
                        camp = py(k3).coeffvalues(1);
                        cphi = rad2deg(py(k3).coeffvalues(2));

                        % -- convert negative amplitudes to positive values
                        if camp < 0 % trigonometrical identity -cos(x) = cos(x-180)
                            camp = -1 * camp; % amp of each model
                            cphi = cphi - 180; % phase of each model
                        end

                        % -- wrap phase to the range [-360, 360]
                        if abs(cphi) > 360
                            if sign(cphi) == -1
                                cphi = cphi + 360;
                            else
                                cphi = cphi - 360;
                            end
                        end

                        % -- express phase as a phase lead
                        if cphi > 0 % make phi to be always leading
                            cphi = 360 - cphi; % phase of each model
                            cphi = -1 * cphi;
                        end

                        % -- store permutation amplitude and phase estimates
                        pcval(k3, 1) = camp; % amp of each model
                        pcval(k3, 2) = cphi; % phase of each model

                    case 'sin'

                        % -- fit model to permuted data
                        fmethod = fittype(@(a1,b1,c1,x) a1*sin(x+b1)+c1,...
                            'coefficients', {'a1', 'b1', 'c1'});

                        [curve, goodness, output] = fit(xx', pavg', fmethod);

                        % -- store fit results
                        py(k3).name = scolumns{k};
                        py(k3).x = xx';
                        py(k3).y = pavg';
                        py(k3).curve = curve;
                        py(k3).goodness = goodness;
                        py(k3).output = output;

                        % -- extract fitted coefficients and confidence intervals
                        py(k3).coeffnames = coeffnames(curve);
                        py(k3).coeffvalues = coeffvalues(curve)';
                        py(k3).confint = confint(curve)';

                        % -- extract modulation amplitude and phase
                        camp = py(k3).coeffvalues(1);
                        cphi = rad2deg(py(k3).coeffvalues(2));

                        % -- convert negative amplitudes to positive values
                        if camp < 0 % trigonometrical identity -cos(x) = cos(x-180)
                            camp = -1 * camp; % amp of each model
                            cphi = cphi - 180; % phase of each model
                        end

                        % -- wrap phase to the range [-360, 360]
                        if abs(cphi) > 360
                            if sign(cphi) == -1
                                cphi = cphi + 360;
                            else
                                cphi = cphi - 360;
                            end
                        end

                        % -- express phase as a phase lead
                        if cphi > 0 % make phi to be always leading
                            cphi = 360 - cphi; % phase of each model
                            cphi = -1 * cphi;
                        end

                        % -- store permutation amplitude and phase estimates
                        pcval(k3, 1) = camp; % amp of each model
                        pcval(k3, 2) = cphi; % phase of each model
                end

                k3 = k3 + 1;

            end

            % -- fit the line
            switch ffit

                case 'cos'

                    % -- fit model to permuted data
                    fmethod = fittype(@(a1,b1,c1,x) a1*cos(x+b1)+c1,...
                        'coefficients', {'a1', 'b1', 'c1'});

                    [curve, goodness, output] = fit(xx', avg', fmethod);

                    % -- store fit results
                    y(k).name = scolumns{k};
                    y(k).x = xx';
                    y(k).y = avg';
                    y(k).curve = curve;
                    y(k).goodness = goodness;
                    y(k).output = output;

                    % -- extract fitted coefficients and confidence intervals
                    y(k).coeffnames = coeffnames(curve);
                    y(k).coeffvalues = coeffvalues(curve)';
                    y(k).confint = confint(curve)';

                    % -- extract modulation amplitude and phase
                    camp = y(k).coeffvalues(1);
                    cphi = rad2deg(y(k).coeffvalues(2));

                    % -- convert negative amplitudes to positive values
                    if camp < 0 % trigonometrical identity -cos(x) = cos(x-180)
                        camp = -1 * camp; % amp of each model
                        cphi = cphi - 180; % phase of each model
                    end

                    % -- wrap phase to the range [-360, 360]
                    if abs(cphi) > 360
                        if sign(cphi) == -1
                            cphi = cphi + 360;
                        else
                            cphi = cphi - 360;
                        end
                    end

                    % -- express phase as a phase lead
                    if cphi > 0 % make phi to be always leading
                        cphi = 360 - cphi; % phase of each model
                        cphi = -1 * cphi;
                    end

                    % -- store permutation amplitude and phase estimates
                    cval(1, 1) = camp; % amp of each model
                    cval(1, 2) = cphi; % phase of each model

                    y(k).oval = cval;
                    y(k).oval_name = fstat_name;
                    y(k).pval = pcval;
                    y(k).p = sum(abs(pcval) >= abs(cval), 1)/n_perm;

                case 'sin'

                    % -- fit model to permuted data
                    fmethod = fittype(@(a1,b1,c1,x) a1*sin(x+b1)+c1,...
                        'coefficients', {'a1', 'b1', 'c1'});

                    [curve, goodness, output] = fit(xx', avg', fmethod);

                    % -- store fit results
                    y(k).name = scolumns{k};
                    y(k).x = xx';
                    y(k).y = avg';
                    y(k).curve = curve;
                    y(k).goodness = goodness;
                    y(k).output = output;

                    % -- extract fitted coefficients and confidence intervals
                    y(k).coeffnames = coeffnames(curve);
                    y(k).coeffvalues = coeffvalues(curve)';
                    y(k).confint = confint(curve)';

                    % -- extract modulation amplitude and phase
                    camp = y(k).coeffvalues(1);
                    cphi = rad2deg(y(k).coeffvalues(2));

                    % -- convert negative amplitudes to positive values
                    if camp < 0 % trigonometrical identity -cos(x) = cos(x-180)
                        camp = -1 * camp; % amp of each model
                        cphi = cphi - 180; % phase of each model
                    end

                    % -- wrap phase to the range [-360, 360]
                    if abs(cphi) > 360
                        if sign(cphi) == -1
                            cphi = cphi + 360;
                        else
                            cphi = cphi - 360;
                        end
                    end

                    % -- express phase as a phase lead
                    if cphi > 0 % make phi to be always leading
                        cphi = 360 - cphi; % phase of each model
                        cphi = -1 * cphi;
                    end

                    cval(1, 1) = camp; % amp of each model
                    cval(1, 2) = cphi; % phase of each model

                    % -- store permutation amplitude and phase estimates
                    y(k).oval = cval;
                    y(k).oval_name = fstat_name;
                    y(k).pval = pcval;
                    y(k).p = sum(abs(pcval) >= abs(cval), 1)/n_perm;

            end

            % -- plot phase-dependent data and fitted model
            if disp_status
                % -- plot mean response with sem
                errorbar(xx, avg, sem, 'linestyle', 'none', 'marker', 'o', 'color', mycolors, 'linewidth', blinewidth);
                set(gca, 'xtick', xx);
                xlim([xrange1, xrange2]);

                % -- format x-axis
                set(gca, 'xticklabel', cellfun(@num2str, num2cell(round(rad2deg(xx))), 'un', 0));
                hold on;

                % -- plot fitted curve
                t = plot(curve, xx',avg');

                % -- format data markers
                t(1).Color = mycolors;
                t(1).MarkerSize = 12;

                % -- format fitted curve
                t(2).Color = mycolorsl;
                t(2).LineWidth = blinewidth;
                grid;

                % -- display permutation p-value
                if disp_p

                    % -- highlight significant results
                    if y(k).p <=  p_th
                        tcolor = 'r';
                    else
                        tcolor = 'k';
                    end
                    text(0.05, 0.95, ['p <= ', num2str(y(k).p(1), '%.3g')], 'units', 'normalized', 'fontsize', fonts, 'fontweight', 'bold', 'color', tcolor);
                end

                % -- add axis labels
                if ~strcmpi(cylabel, '')
                    ylabel(cylabel);
                end

                if ~strcmpi(cxlabel, '')
                    xlabel(cxlabel);
                end

                % -- set y-axis limits
                if ~isempty(crange)
                    ylim([range1 range2]);
                end

                % -- format axes
                set(gca, 'FontWeight', 'bold', 'FontSize', fonts);

                % -- add figure title
                sgtitle(scolumns{k}, 'interpreter', 'none');

            end

        else

            % -- return empty output for invalid data
            y(k).name = scolumns{k};
            y(k).x = nan(length(sdata), 1);
            y(k).y = nan(length(sdata), 1);
            y(k).curve = [];
            y(k).goodness.sse = NaN(1, 1);
            y(k).goodness.rsquare = NaN(1, 1);
            y(k).goodness.dfe = NaN(1, 1);
            y(k).goodness.adjrsquare = NaN(1, 1);
            y(k).goodness.rmse = NaN(1, 1);

            y(k).output = [];
            y(k).coeffnames = [];
            y(k).coeffvalues = [];
            y(k).confint = [];
            y(k).oval = nan(1, size(fstat_name, 2));
            y(k).oval_name = fstat_name;
            y(k).pval = nan(1, n_perm);
            y(k).p = ones(size(fstat_name, 2), 1);

        end

        k = k + 1;

    end

else

    % -- plot selected columns
    k = 1;
    while k <= length(srows)

        if disp_status
            h(k) = figure('color', [1 1 1], 'name', srows{k});
        else
            h = [];
        end

        % -- extract selected data
        sdata = nin_struct2cell_form(x, 'srows', crows{k}, 'scolumns', scolumns, 'otype', 'cell', 'smeta', []);

        % -- extract plot labels
        sdata(2:end, :) = cellfun(@double, sdata(2:end, :), 'un', 0);

        header = nin_strsplit(sdata(1, :), 'last', [], 'spliter', '_');
        sdata = double(cell2mat(sdata(2:end, :)));

        if all(~isnan(sdata))

            % -- normalize data across phases
            if shift_data

                sdata = zscore(sdata);

            end

            % -- calculate mean values
            avg = nanmean(sdata, 1);
            % -- calculate standard error of the mean
            sem = nanstd(sdata, 1)./sqrt(sum(~isnan(sdata), 1));

            % -- initialize permutation analysis
            n = size(sdata, 2);
            m = size(sdata, 1);
            ix = NaN(m, n);
            pavg = NaN(m, n);
            pcval = NaN(n_perm, 2);
            k3 = 1;
            while k3 <= n_perm

                % -- randomly shuffle phase labels
                k2 = 1;
                while k2 <= m

                    ix(k2, :) = randperm(n);
                    pcdata(k2, :) = sdata(k2, ix(k2, :));

                    k2 = k2 + 1;

                end

                % -- calculate permuted mean response
                pcdata = sdata(ix);
                pavg = nanmean(pcdata, 1);

                % -- fit sinusoidal model to permuted data
                switch ffit

                    case 'cos'

                        % -- fit model to permuted data
                        fmethod = fittype(@(a1,b1,c1,x) a1*cos(x+b1)+c1,...
                            'coefficients', {'a1', 'b1', 'c1'});

                        [curve, goodness, output] = fit(xx', pavg', fmethod);

                        % -- store fit results
                        py(k3).name = scolumns{k};
                        py(k3).x = xx';
                        py(k3).y = pavg';
                        py(k3).curve = curve;
                        py(k3).goodness = goodness;
                        py(k3).output = output;

                        % -- extract fitted coefficients and confidence intervals
                        py(k3).coeffnames = coeffnames(curve);
                        py(k3).coeffvalues = coeffvalues(curve)';
                        py(k3).confint = confint(curve)';

                        % -- extract modulation amplitude and phase
                        camp = py(k3).coeffvalues(1);
                        cphi = rad2deg(py(k3).coeffvalues(2));

                        % -- convert negative amplitudes to positive values
                        if camp < 0 % trigonometrical identity -cos(x) = cos(x-180)
                            camp = -1 * camp; % amp of each model
                            cphi = cphi - 180; % phase of each model
                        end

                        % -- wrap phase to the range [-360, 360]
                        if abs(cphi) > 360
                            if sign(cphi) == -1
                                cphi = cphi + 360;
                            else
                                cphi = cphi - 360;
                            end
                        end

                        % -- express phase as a phase lead
                        if cphi > 0 % make phi to be always leading
                            cphi = 360 - cphi; % phase of each model
                            cphi = -1 * cphi;
                        end

                        % -- store permutation amplitude and phase estimates
                        pcval(k3, 1) = camp; % amp of each model
                        pcval(k3, 2) = cphi; % phase of each model

                    case 'sin'

                        % -- fit model to permuted data
                        fmethod = fittype(@(a1,b1,c1,x) a1*sin(x+b1)+c1,...
                            'coefficients', {'a1', 'b1', 'c1'});

                        [curve, goodness, output] = fit(xx', pavg', fmethod);

                        % -- store fit results
                        py(k3).name = scolumns{k};
                        py(k3).x = xx';
                        py(k3).y = pavg';
                        py(k3).curve = curve;
                        py(k3).goodness = goodness;
                        py(k3).output = output;

                        % -- extract fitted coefficients and confidence intervals
                        py(k3).coeffnames = coeffnames(curve);
                        py(k3).coeffvalues = coeffvalues(curve)';
                        py(k3).confint = confint(curve)';

                        % -- extract modulation amplitude and phase
                        camp = py(k3).coeffvalues(1);
                        cphi = rad2deg(py(k3).coeffvalues(2));

                        % -- convert negative amplitudes to positive values
                        if camp < 0 % trigonometrical identity -cos(x) = cos(x-180)
                            camp = -1 * camp; % amp of each model
                            cphi = cphi - 180; % phase of each model
                        end

                        % -- wrap phase to the range [-360, 360]
                        if abs(cphi) > 360
                            if sign(cphi) == -1
                                cphi = cphi + 360;
                            else
                                cphi = cphi - 360;
                            end
                        end

                        % -- express phase as a phase lead
                        if cphi > 0 % make phi to be always leading
                            cphi = 360 - cphi; % phase of each model
                            cphi = -1 * cphi;
                        end

                        % -- store permutation amplitude and phase estimates
                        pcval(k3, 1) = camp; % amp of each model
                        pcval(k3, 2) = cphi; % phase of each model

                        close(gcf);
                end

                k3 = k3 + 1;

            end

            % -- fit the line
            switch ffit

                case 'cos'

                    % -- fit model to permuted data
                    fmethod = fittype(@(a1,b1,c1,x) a1*cos(x+b1)+c1,...
                        'coefficients', {'a1', 'b1', 'c1'});

                    [curve, goodness, output] = fit(xx', avg', fmethod);

                    % -- store fit results
                    y(k).name = scolumns{k};
                    y(k).x = xx';
                    y(k).y = avg';
                    y(k).curve = curve;
                    y(k).goodness = goodness;
                    y(k).output = output;

                    % -- extract fitted coefficients and confidence intervals
                    y(k).coeffnames = coeffnames(curve);
                    y(k).coeffvalues = coeffvalues(curve)';
                    y(k).confint = confint(curve)';

                    % -- extract modulation amplitude and phase
                    camp = y(k).coeffvalues(1);
                    cphi = rad2deg(y(k).coeffvalues(2));

                    % -- convert negative amplitudes to positive values
                    if camp < 0 % trigonometrical identity -cos(x) = cos(x-180)
                        camp = -1 * camp; % amp of each model
                        cphi = cphi - 180; % phase of each model
                    end

                    % -- wrap phase to the range [-360, 360]
                    if abs(cphi) > 360
                        if sign(cphi) == -1
                            cphi = cphi + 360;
                        else
                            cphi = cphi - 360;
                        end
                    end

                    % -- express phase as a phase lead
                    if cphi > 0 % make phi to be always leading
                        cphi = 360 - cphi; % phase of each model
                        cphi = -1 * cphi;
                    end

                    % -- store permutation amplitude and phase estimates
                    cval(1, 1) = camp; % amp of each model
                    cval(1, 2) = cphi; % phase of each model

                    y(k).oval = cval;
                    y(k).oval_name = fstat_name;
                    y(k).pval = pcval;
                    y(k).p = nnz(abs(pcval) >= abs(cval))/n_perm;

                case 'sin'

                    % -- fit model to permuted data
                    fmethod = fittype(@(a1,b1,c1,x) a1*sin(x+b1)+c1,...
                        'coefficients', {'a1', 'b1', 'c1'});

                    [curve, goodness, output] = fit(xx', avg', fmethod);

                    % -- store fit results
                    y(k).name = scolumns{k};
                    y(k).x = xx';
                    y(k).y = avg';
                    y(k).curve = curve;
                    y(k).goodness = goodness;
                    y(k).output = output;

                    % -- extract fitted coefficients and confidence intervals
                    y(k).coeffnames = coeffnames(curve);
                    y(k).coeffvalues = coeffvalues(curve)';
                    y(k).confint = confint(curve)';

                    % -- extract modulation amplitude and phase
                    camp = y(k).coeffvalues(1);
                    cphi = rad2deg(y(k).coeffvalues(2));

                    % -- convert negative amplitudes to positive values
                    if camp < 0 % trigonometrical identity -cos(x) = cos(x-180)
                        camp = -1 * camp; % amp of each model
                        cphi = cphi - 180; % phase of each model
                    end

                    % -- wrap phase to the range [-360, 360]
                    if abs(cphi) > 360
                        if sign(cphi) == -1
                            cphi = cphi + 360;
                        else
                            cphi = cphi - 360;
                        end
                    end

                    % -- express phase as a phase lead
                    if cphi > 0 % make phi to be always leading
                        cphi = 360 - cphi; % phase of each model
                        cphi = -1 * cphi;
                    end

                    cval(1, 1) = camp; % amp of each model
                    cval(1, 2) = cphi; % phase of each model

                    % -- store permutation amplitude and phase estimates
                    y(k).oval = cval;
                    y(k).oval_name = fstat_name;
                    y(k).pval = pcval;
                    y(k).p = nnz(abs(pcval) >= abs(cval))/n_perm;

            end

            % -- plot phase-dependent data and fitted model
            if disp_status
                % -- plot mean response with sem
                errorbar(xx, avg, sem, 'linestyle', 'none', 'marker', 'o', 'color', mycolors, 'linewidth', blinewidth);
                set(gca, 'xtick', xx);
                xlim([xrange1, xrange2]);

                % -- format x-axis
                set(gca, 'xticklabel', cellfun(@num2str, num2cell(round(rad2deg(xx))), 'un', 0));
                hold on;

                % -- plot fitted curve
                t = plot(curve, xx',avg');

                % -- format data markers
                t(1).Color = mycolors;
                t(1).MarkerSize = 12;

                % -- format fitted curve
                t(2).Color = mycolorsl;
                t(2).LineWidth = blinewidth;
                grid;

                % -- display permutation p-value
                if disp_p

                    % -- highlight significant results
                    if y(k).p <=  p_th
                        tcolor = 'r';
                    else
                        tcolor = 'k';
                    end
                    text(0.05, 0.95, ['p <= ', num2str(y(k).p(1), '%.3g')], 'units', 'normalized', 'fontsize', fonts, 'fontweight', 'bold', 'color', tcolor);
                end

                % -- add axis labels
                if ~strcmpi(cylabel, '')
                    ylabel(cylabel);
                end

                if ~strcmpi(cxlabel, '')
                    xlabel(cxlabel);
                end

                % -- set y-axis limits
                if ~isempty(crange)
                    ylim([range1 range2]);
                end

                % -- format axes
                set(gca, 'FontWeight', 'bold', 'FontSize', fonts);

                % -- add figure title
                sgtitle(scolumns{k}, 'interpreter', 'none');

            end

        else

            % -- return empty output for invalid data
            y(k).name = scolumns{k};
            y(k).x = nan(length(sdata), 1);
            y(k).y = nan(length(sdata), 1);
            y(k).curve = [];
            y(k).goodness.sse = NaN(1, 1);
            y(k).goodness.rsquare = NaN(1, 1);
            y(k).goodness.dfe = NaN(1, 1);
            y(k).goodness.adjrsquare = NaN(1, 1);
            y(k).goodness.rmse = NaN(1, 1);

            y(k).output = [];
            y(k).coeffnames = [];
            y(k).coeffvalues = [];
            y(k).confint = [];
            y(k).oval = nan(1, size(fstat_name, 2));
            y(k).oval_name = fstat_name;
            y(k).pval = nan(1, n_perm);
            y(k).p = ones(size(fstat_name, 2), 1);

        end

        k = k + 1;

    end

end

end

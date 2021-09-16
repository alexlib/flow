function [dI, dI_box, dI_gss, bias_box, bias_gss] = ...
    impulse_err_run(vf, props, origin, fr, u0)
% For synthetic data set, impulse_err_run(vf, props, origin, fr, u0). The
% physical parameters 'fr', 'u0' are solely used to compute the theoretical
% vortical impulse of the Hill's vortex.
% For experimental data set,
% impulse_err_run(vf, props, origin, I0), where 'origin_ref' is the origin
% from which the impulse taken as correct is computed.
% 
% Introduce levels of noise proportional to the mean speed in the effective
% region, according to 'props', e.g. 0: 0.1: 3. 'vf' is presume to have
% range properly set. 'origin' specifies the reference point to which
% impulse calculations are performed. 'u0' provides the freestream speed by
% which the theoretical impulse is obtained.
%
% Derek Li, June 2021

range = vf.getRange();

props_count = length(props);

% Each velocity component associated with a unit cell.
vol = prod(range(:,2) - range(:,1) + 1)*vf.solver.dv;

% Set constant maximal magnitude of noise.
u_mean = vf.meanSpeed(0, 0);

% Theoretical momentum.
I0 = vf.fluid.density*[0 2*pi*fr^3*u0*vf.scale.len^4 0]';
i0 = I0(2);

% % Experimental momentum used as comparison level.
% I0 = vf.impulse(origin_ref, 0);
% i0 = norm(I0);

% Error in impulse computation given noise.
dI = zeros(3, props_count);
% Box smoothing.
dI_box = zeros(3, props_count);
% Gaussian smoothing.
dI_gss = zeros(3, props_count);

% Plot energy estimation error for small and large values of noise.
for i = 1: props_count
    vf.clearNoise();
    N = vf.noise_uniform(props(i)*u_mean);
    dI(:, i) = vf.impulse(origin, 1) - I0;
    % Result with box smoothing.
    vf.smoothNoise('box');
    dI_box(:, i) = vf.impulse(origin, 1) - I0;
    % Reset and smooth with gaussian filter.
    vf.setNoise(N)
    vf.smoothNoise('gaussian');
    dI_gss(:, i) = vf.impulse(origin, 1) - I0;
end

% Normalize by magnitude of impulse in the region.
dI = dI / i0;
di = sqrt(sum(dI.^2, 1));
dI_box = dI_box / i0;
di_box = sqrt(sum(dI_box.^2, 1));
dI_gss = dI_gss / i0;
di_gss = sqrt(sum(dI_gss.^2, 1));

abs_dI = abs(dI);
abs_dI_box = abs(dI_box);
abs_dI_gss = abs(dI_gss);

% Baseline smoother biases.
bias_box = dI_box(:, 1);
bias_gss = dI_gss(:, 1);

mag_bias_box = norm(bias_box);
mag_bias_gss = norm(bias_gss);

abs_bias_box = abs(bias_box);
abs_bias_gss = abs(bias_gss);

% Dimension, i.e., x, y, z, to plot, specified correspondingly by 1, 2, 3.
dims = [2 1 3];
dim_str = {'x', 'y', 'z'};

%%%%%%%%%%% Plot signed impulse error %%%%%%%%%%%%%%%

for dim = dims
    figure;
    scatter(props, dI(dim,:))
    hold on
    scatter(props, dI_box(dim,:), 'r', 'filled')
    hold on
    err_mean_box = mean(dI_box(dim,:));
    yline(err_mean_box, '-')
    hold on
    scatter(props, dI_gss(dim,:), 'b', 'filled')
    hold on
    err_mean_gss = mean(dI_gss(dim,:));
    yline(err_mean_gss, '-')
    
    legend({'unfiltered error', ...
        'box-filtered $\vec{u}$', ...
        strcat('box mean $\frac{\delta I_y}{I} = $', string(err_mean_box)), ...
        'Gaussian-filtered $\vec{u}$', ...
        strcat('Gaussian mean $\frac{\delta I_y}{I} = $', string(err_mean_gss))})
    xlabel('$\frac{|\delta u|}{\bar{u}}$')
    ylabel(strcat('$\frac{\delta I_', dim_str{dim}, '}{I}$'))
    title(strcat('$', dim_str{dim}, '$ Impulse Error'))
end


%%%%%%%%%%%%%%%%%% Plot absolute impulse error %%%%%%%%%%%%%%%%%%%%

for dim = dims
    figure;
    scatter(props, abs_dI(dim,:))
    hold on
    err_mean0 = mean(abs_dI(dim, :));
    yline(err_mean0, '-')
    hold on
    scatter(props, abs_dI_box(dim,:), 'r', 'filled')
    hold on
    err_mean_box = mean(abs_dI_box(dim,:));
    yline(err_mean_box, '-')
    hold on
    scatter(props, abs_dI_gss(dim,:), 'b', 'filled')
    hold on
    err_mean_gss = mean(abs_dI_gss(dim,:));
    yline(err_mean_gss, '-')
    
    legend({'unfiltered error', ...
        strcat('unfiltered mean $|\frac{\delta I_y}{I}| = $', string(err_mean0)), ...
        'box-filtered $\vec{u}$', ...
        strcat('box mean $|\frac{\delta I_y}{I}| = $', string(err_mean_box)), ...
        'Gaussian-filtered $\vec{u}$', ...
        strcat('Gaussian mean $|\frac{\delta I_y}{I}| = $', string(err_mean_gss))})
    xlabel('$\frac{|\delta u|}{\bar{u}}$')
    ylabel(strcat('$\left|\frac{\delta I_', dim_str{dim}, '}{I}\right|$'))
    title(strcat('Absolute', ' $', dim_str{dim}, '$ Impulse Error'))
end

%%%%%%%%%%% Error magnitude %%%%%%%%%%%%
figure;
scatter(props, di)
hold on
scatter(props, di_box, 'r', 'filled')
hold on
scatter(props, di_gss, 'b', 'filled')
hold on
yline(mag_bias_box, '-', 'Color', 'r')
hold on
yline(mag_bias_gss, '-', 'Color', 'b')

legend('unfiltered error', 'box-filtered', 'Gaussian-filtered', ...
    strcat('box bias $\kappa = $', string(mag_bias_box)), ...
    strcat('Gaussian bias $\kappa = $', string(mag_bias_gss)), ...
    'Interpreter', 'latex')

xlabel('$\frac{|\delta u|}{\bar{u}}$')
ylabel('$\frac{|\delta I|}{\bar{I}}$')
title('Magnitude of Impulse Error')


%%%%%%%%%%%% Impulse error vs impulse noise, in magnitude%%%%%%%%%%%%
% figure;
% scatter(di, di_box, 'r', 'filled')
% hold on
% scatter(di, di_gss, 'b', 'filled')
% hold on
% % 1-1 line.
% plot(di, di, 'black')
% hold on
% yline(mag_bias_box, '-', 'Color', 'r')
% hold on
% yline(mag_bias_gss, '-', 'Color', 'b')
% 
% legend('box-filtered', 'Gaussian-filtered', ...
%     'identity line', ...
%     strcat('box bias $\kappa = $', string(mag_bias_box)), ...
%     strcat('Gaussian bias $\kappa = $', string(mag_bias_gss)), ...
%     'Interpreter', 'latex')
% 
% xlabel('Unfiltered $|\frac{\delta I}{I}|$')
% ylabel('Filtered $\frac{|\delta I|}{\bar{I}}$')
% title('Smoother Efficacy')

%%%%%%%%%%%%% Smoothing errors as proportion of smoother bias %%%%%%%%%%%%
err_prop_box = abs(dI_box / mag_bias_box);
err_prop_gss = abs(dI_gss / mag_bias_gss);

% for dim = dims
%     figure;
%     scatter(props, err_prop_box(dim,:), 'r', 'filled')
%     hold on
%     scatter(props, err_prop_gss(dim,:), 'b', 'filled')
%     
%     legend({strcat('box $\kappa = $', string(mag_bias_box)), ...
%         strcat('Gaussian $\kappa = $', string(mag_bias_gss))}, ...
%         'Interpreter', 'latex')
%     xlabel('$\frac{|\delta u|}{\bar{u}}$')
%     ylabel(strcat('$\frac{\left|\frac{\delta I_', dim_str{dim}, '}{I}\right|}{\kappa}$'))
%     title(strcat('$', dim_str{dim}, '$ Error Proportional to Smoother Bias'))
% end

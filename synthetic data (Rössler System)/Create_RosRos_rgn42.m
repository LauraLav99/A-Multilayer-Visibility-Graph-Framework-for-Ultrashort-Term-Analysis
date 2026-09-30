clear all
close all
clc
rng(42) 

% _________________________________________________________________________
%% Setup Parameters

t_s = 0;                        % Starting time (s)
t_f = 2753;                     % Ending time (s)
fc = 4;                         % Sampling frequency (4 Hz)
dt = 1/fc;                      % Sampling step (0.25 s)
t_vector = t_s:dt:t_f;          % time vector (for ode45, s)

d_0 = [0, 0, 0.4, 0, 0, 0.4];   % Starting conditions [x1, x2, x3, y1, y2, y3]
c = [0, 0.35, 0.7, 1.1];        % Coupling strenght
noise = 0.03;                   % Noise amplitude 
Rep_n = 30;                     % N° of repetitions
N_transient = 1000;             % Transient samples to discard

% Saving paths
out_dir = fullfile(pwd, 'ufficiale dati');
if ~exist(out_dir, 'dir')
    mkdir(out_dir);
end
save_path = fullfile(out_dir, 'Dati_RosRos_rgn42.mat');

syst_name = "RosRos";
options = odeset;
Data = struct();

% _________________________________________________________________________
%% Data generation 

for k = 1:length(c)
    param = strcat("c_", num2str(k));
    fprintf('Simulation for k = %.2f...\n', c(k));
    
    for kk = 1:Rep_n
        name = strcat("s", num2str(kk));
        
        % Integration
        [t, d] = ode45(@RosRos, t_vector, d_0, options, c(k), noise);
        
        % Discarding the transient
        d_clean = d((N_transient + 1):end, :);
        
        % Saving of the time-series
        Data.(syst_name).(param).(name).x1 = d_clean(:,1);
        Data.(syst_name).(param).(name).x2 = d_clean(:,2);
        Data.(syst_name).(param).(name).x3 = d_clean(:,3);
        Data.(syst_name).(param).(name).y1 = d_clean(:,4);
        Data.(syst_name).(param).(name).y2 = d_clean(:,5);
        Data.(syst_name).(param).(name).y3 = d_clean(:,6);
        Data.(syst_name).(param).(name).c = c(k);
        Data.(syst_name).(param).(name).noise = noise;
        Data.(syst_name).(param).(name).fc = fc;
    end
end

% Saving of the time-vector
t_clean = t_vector((N_transient + 1):end) - t_vector(N_transient + 1); %removing the transient
Data.(syst_name).time = t_clean;

% _________________________________________________________________________
%% Plots

for k = 1:length(c)
    param = strcat("c_", num2str(k));
    
    figure('Name', sprintf('Coupling k = %.2f', c(k)));
    
    % Rössler Driver (X)
    subplot(2,2,1)
    plot3(Data.(syst_name).(param).s1.x1, ...
          Data.(syst_name).(param).s1.x2, ...
          Data.(syst_name).(param).s1.x3, 'b');
    title('Driver System (Oscillator 1: \omega_1 = 0.5)');
    xlabel('x_1'); ylabel('x_2'); zlabel('x_3'); grid on;
    
    % Rössler Driven (Y)
    subplot(2,2,2)
    plot3(Data.(syst_name).(param).s1.y1, ...
          Data.(syst_name).(param).s1.y2, ...
          Data.(syst_name).(param).s1.y3, 'r');
    title('Response System (Oscillator 2: \omega_2 = 2.515)');
    xlabel('y_1'); ylabel('y_2'); zlabel('y_3'); grid on;
    
    sgtitle(sprintf('Coupled Rössler system(\\k = %.2f)', c(k)))
    
    % Time series (x1 vs y1)
    subplot(2,1,2)
    plot(t_clean, Data.(syst_name).(param).s1.x1, 'b', ...
         t_clean, Data.(syst_name).(param).s1.y1, 'r');
    legend('Driver x_1', 'Response y_1');
    xlabel('Time [s]'); ylabel('Amplitude'); grid on;
end

% _________________________________________________________________________
%% Saving

save(save_path, 'Data');
fprintf('Dataset saved in: %s\n', save_path);

% _________________________________________________________________________
%% Coupled Rössler Dynamical System Function

function dd = RosRos(~, d, c, noise)
    w1 = 0.5; 
    w2 = 2.515;
    a1 = 0.15;
    a2 = 0.72;
    b  = 0.2;
    c1 = 10;
    
    dd = zeros(6,1);
    
    % Driver System (X)
    dd(1) = -w1*d(2) - d(3) + noise*randn(1,1);
    dd(2) =  w1*d(1) + a1*d(2) + noise*randn(1,1);
    dd(3) =  b + d(3)*(d(1) - c1) + noise*randn(1,1);
    
    % Response System (Y) con accoppiamento unidirezionale kappa*(x1 - y1)
    dd(4) = -w2*d(5) - d(6) + c*(d(1) - d(4)) + noise*randn(1,1);
    dd(5) =  w2*d(4) + a2*d(5) + noise*randn(1,1);
    dd(6) =  b + d(6)*(d(4) - c1) + noise*randn(1,1);
end

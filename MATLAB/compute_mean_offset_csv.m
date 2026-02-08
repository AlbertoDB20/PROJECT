
clear; clc; close all;
%% === PARAMETRI ROBOT ===
R_R = 0.0886;   % Raggio ruota destra [m]
R_L = 0.0876;   % Raggio ruota sinistra [m]
b = 0.8313;     % Distanza tra le ruote [m]
n0 = 4096;    % Tic per rivoluzione encoder

% Pose iniziale [x, y, theta]
x(1) = 0; 
y(1) = 0; 
delta(1) = 0;

%% === LETTURA FILE CSV ===
% Cartella dello script
scriptFolder = fileparts(mfilename('fullpath'));

% Cartella del progetto (parent folder di MATLAB)
projectFolder = fileparts(scriptFolder);

% Percorsi dei CSV
matrix = readmatrix('../CSV/IMU_offset.imu.csv');

mean(matrix(:,3))   % a_x_off_imu
median(matrix(:,3))   % a_x_off_imu

mean(matrix(:,4))   % a_y_off_imu
median(matrix(:,4))   % a_y_off_imu

mean(matrix(:,14))  % w_z_off_imu
median(matrix(:,14))  % w_z_off_imu


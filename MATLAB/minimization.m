
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
filename = fullfile(projectFolder, 'CSV', 'mads_calibration_encoders.csv');
filename_htc = fullfile(projectFolder, 'CSV', 'mads_calibration_htc.csv');

% Controllo file
if exist(filename, 'file') ~= 2
    error('File not found: %s', filename);
end
if exist(filename_htc, 'file') ~= 2
    error('File not found: %s', filename_htc);
end

% Leggi CSV
T = readtable(filename);
dataHTC = readtable(filename_htc);

%% === INTERPOLAZIONE HTC ===
% Estrai le coordinate x e y
x_htc = dataHTC.('message_pose_position_0_');
y_htc = dataHTC.('message_pose_position_1_');


% Estrai timestamp HTC e Encoders e convertilo in secondi (tempo relativo)
tHTC = datetime(dataHTC.message_timestamp, 'InputFormat', 'yyyy-MM-dd''T''HH:mm:ss.SSS''Z''');
tHTC = seconds(tHTC - tHTC(1)); % tempo relativo (parte da 0)

tEncoder = datetime(dataHTC.timestamp, 'InputFormat', 'yyyy-MM-dd''T''HH:mm:ss.SSS''Z''');
tEncoder = seconds(tEncoder - tEncoder(1)); % tempo relativo (parte da 0)


xInterp = interp1(tHTC, x_htc, tEncoder, 'linear', 'extrap');
yInterp = interp1(tHTC, y_htc, tEncoder, 'linear', 'extrap');

%% === ENCODERS PATH ===
% Estrazione colonne
timestamp = datetime(T.timestamp, ...
    'InputFormat', 'yyyy-MM-dd''T''HH:mm:ss.SSS''Z''', 'TimeZone', 'UTC');
enc_L = T.message_encoders_left;
enc_R = T.message_encoders_right;

% Calcolo variazioni encoder (Δtic)
n_Lk = diff(enc_L);
n_Rk = diff(enc_R);

% Calcolo intervallo temporale (non obbligatorio ma utile)
dt = seconds(diff(timestamp));

% Mantieni solo campioni validi
valid = dt > 0;
n_Lk = n_Lk(valid);
n_Rk = n_Rk(valid);
timestamp = timestamp(2:end);
timestamp = timestamp(valid);

%% === CICLO DI INTEGRAZIONE DISCRETO ===
for k = 1:length(n_Lk)
    % Modello cinematico discreto (dalla tua immagine)
    dx = pi * (n_Rk(k)*R_R + n_Lk(k)*R_L) / n0 * cos(delta(k));
    dy = pi * (n_Rk(k)*R_R + n_Lk(k)*R_L) / n0 * sin(delta(k));
    dtheta = 2*pi * (n_Rk(k)*R_R - n_Lk(k)*R_L) / (n0 * b);

    % Aggiorna la posa
    x(k+1) = x(k) + dx;
    y(k+1) = y(k) + dy;
    delta(k+1) = delta(k) + dtheta;
end




%% === VISUALIZZAZIONE COMPARISON TRAIETTORIA ===
figure;
plot(x, y, 'b', 'LineWidth', 2); hold on;                  
plot(x(1), y(1), 'co', 'MarkerFaceColor', 'c', ...         
    'DisplayName', 'Inizio Encoder');
plot(x(end), y(end), 'mo', 'MarkerFaceColor', 'm', ...     
    'DisplayName', 'Fine Encoder');
plot(xInterp, yInterp, 'r', 'LineWidth', 1.5); hold on;        
plot(x_htc(1), y_htc(1), 'gs', 'MarkerFaceColor', 'g', ... 
    'DisplayName', 'Inizio HTC');
plot(xInterp(end), yInterp(end), 'ks', 'MarkerFaceColor', 'k', ... 
    'DisplayName', 'Fine HTC');

xlabel('X [m]');
ylabel('Y [m]');
title('Traiettoria ENCODER vs HTC');
axis equal; grid on;

legend('Traiettoria Encoder', 'Inizio Encoder', 'Fine Encoder', ...
       'Traiettoria HTC', 'Inizio HTC', 'Fine HTC');








%% === VISUALIZZAZIONE TRAIETTORIA ENCODER ===
% figure;
% plot(x, y, 'b', 'LineWidth', 1.5); hold on;
% plot(x(1), y(1), 'go', 'MarkerFaceColor', 'g', 'DisplayName', 'Inizio');
% plot(x(end), y(end), 'ro', 'MarkerFaceColor', 'r', 'DisplayName', 'Fine');
% xlabel('X [m]');
% ylabel('Y [m]');
% title('Traiettoria con Encoder');
% axis equal; grid on;
% legend('Traiettoria', 'Inizio', 'Fine');

%% === VISUALIZZAZIONE TRAIETTORIA HTC ===
% figure;
% plot(x_htc, y_htc,'LineWidth',1.5); hold on;
% plot(x_htc(1), y_htc(1), 'go', 'MarkerFaceColor', 'g', 'DisplayName', 'Inizio');
% plot(x_htc(end), y_htc(end), 'ro', 'MarkerFaceColor', 'r', 'DisplayName', 'Fine');
% xlabel('X [m]');
% ylabel('Y [m]');
% title('Traiettoria con HTC');
% axis equal; grid on;
% legend('Traiettoria', 'Inizio', 'Fine');

%% === PLOT ANGOLO NEL TEMPO ===
% figure;
% plot(seconds(timestamp - timestamp(1)), rad2deg(unwrap(delta(1:end-1))), 'LineWidth', 1.5);
% xlabel('Tempo [s]');
% ylabel('Orientamento [°]');
% title('Orientamento del robot nel tempo');
% grid on;


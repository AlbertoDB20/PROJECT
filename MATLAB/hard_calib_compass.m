%% Script di Calibrazione Magnetometro (Hard-Iron & Soft-Iron)
clear; clc; close all;

% Cartella dello script
scriptFolder = fileparts(mfilename('fullpath'));

% Cartella del progetto (parent folder di MATLAB)
projectFolder = fileparts(scriptFolder);

% 1. CARICAMENTO DATI
% Sostituisci con il tuo file o incolla i vettori mx e my qui
% Ipotizziamo che tu abbia un file CSV con colonne: time, mx, my, mz
filename = fullfile(projectFolder, 'CSV/Sensor_Fusion_2ndDataset', 'SensorFusion2.imu.csv');

% Controllo file
if exist(filename, 'file') ~= 2
    error('File not found: %s', filename);
end

data = readtable(filename); 

mx_raw = data.('message_compass_1_');
my_raw = data.('message_compass_2_');

%% 2. CALCOLO HARD-IRON (Offset)
% Trova i valori estremi registrati durante la rotazione di 360 gradi
max_x = max(mx_raw);
min_x = min(mx_raw);
max_y = max(my_raw);
min_y = min(my_raw);

% Il centro del cerchio rappresenta l'offset dovuto ai metalli del robot
offset_x = (max_x + min_x) / 2;
offset_y = (max_y + min_y) / 2;

% Applica correzione Hard-Iron
mx_no_hard = mx_raw - offset_x;
my_no_hard = my_raw - offset_y;

%% 3. CALCOLO SOFT-IRON (Scaling - Opzionale ma consigliato)
% Se il cerchio è schiacciato (ellisse), uniformiamo i diametri
avg_delta_x = (max_x - min_x) / 2;
avg_delta_y = (max_y - min_y) / 2;
avg_delta = (avg_delta_x + avg_delta_y) / 2;

scale_x = avg_delta / avg_delta_x;
scale_y = avg_delta / avg_delta_y;

% Dati finali calibrati
mx_calibrated = mx_no_hard * scale_x;
my_calibrated = my_no_hard * scale_y;

%% 4. VISUALIZZAZIONE RISULTATI
figure('Color', 'w', 'Name', 'Magnetometer Calibration');

% Plot dati grezzi
subplot(1,2,1);
scatter(mx_raw, my_raw, 10, 'r', 'filled'); hold on;
grid on; axis equal;
title('Dati GREZZI (Spostati dall''origine)');
xlabel('m_x [\muT]'); ylabel('m_y [\muT]');
plot(offset_x, offset_y, 'kx', 'MarkerSize', 15, 'LineWidth', 2); % Centro

% Plot dati calibrati
subplot(1,2,2);
scatter(mx_calibrated, my_calibrated, 10, 'b', 'filled'); hold on;
grid on; axis equal;
title('Dati CALIBRATI (Centrati in 0,0)');
xlabel('m_x corr [\muT]'); ylabel('m_y corr [\muT]');
line([-50 50], [0 0], 'Color', 'k', 'LineStyle', '--'); % Assi
line([0 0], [-50 50], 'Color', 'k', 'LineStyle', '--');

%% 5. OUTPUT PER C++
fprintf('\n--- VALORI DA COPIARE NEL TUO CODICE C++ ---\n');
fprintf('double offset_x = %.4f;\n', offset_x);
fprintf('double offset_y = %.4f;\n', offset_y);
fprintf('double scale_x  = %.4f;  // (Se vuoi usare lo scaling)\n', scale_x);
fprintf('double scale_y  = %.4f;\n', scale_y);
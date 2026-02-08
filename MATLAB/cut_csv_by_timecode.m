%% ===== PARAMETRI DI INPUT =====

% File CSV (path completo o relativo)
file_encoder    = '../CSV/test_adb/test_adb.encoders.csv';
file_imu        = '../CSV/test_adb/test_adb.imu.csv';
file_realsense  = '../CSV/test_adb/test_adb.H_initial_walker_aruco.csv';

% Colonne del timecode (indice o nome)
col_timecode_encoder   = 8;     
col_timecode_imu       = 16;
col_timecode_realsense = 39;

% Timecode di taglio
timecode_cut = 45602.747;   % <-- valore di riferimento


%% ===== FUNZIONE DI TAGLIO =====
function n_rows = cut_csv(file_csv, col_timecode, timecode_cut)

    % Legge il CSV
    T = readtable(file_csv);

    % Estrae il vettore timecode
    if isnumeric(col_timecode)
        tc = T{:, col_timecode};
    else
        tc = T.(col_timecode);
    end

    % Trova righe valide
    idx_valid = tc >= timecode_cut;

    % Taglia tabella
    T_cut = T(idx_valid, :);

    % Nuovo nome file
    [pathstr, name, ext] = fileparts(file_csv);
    new_file = fullfile(pathstr, [name '_cut' ext]);

    % Salva CSV
    writetable(T_cut, new_file);

    % Numero righe rimanenti
    n_rows = height(T_cut);

    fprintf('File: %s → righe rimanenti: %d\n', new_file, n_rows);
end


%% ===== ESECUZIONE =====
fprintf('--- TAGLIO CSV PER TIMECODE ---\n');

n_encoder   = cut_csv(file_encoder, col_timecode_encoder, timecode_cut);
n_imu       = cut_csv(file_imu, col_timecode_imu, timecode_cut);
n_realsense = cut_csv(file_realsense, col_timecode_realsense, timecode_cut);

fprintf('--------------------------------\n');

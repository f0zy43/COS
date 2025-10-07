% Загрузка аудиофайла
[audio, Fs] = audioread('result.wav');

% Проверка стерео/моно
if size(audio, 2) > 1
    audio = mean(audio, 2); % Преобразование в моно
end

% Проверка, что частота дискретизации достаточна для 40 кГц
if Fs < 80000
    warning('Частота дискретизации может быть недостаточной для работы с частотами до 40 кГц');
end

% Параметры частот
f_low = 10000;      % 10 кГц - верхняя граница низкочастотного диапазона
f_band_start = 20000; % 20 кГц - начало выделяемой полосы
f_band_end = 40000;   % 40 кГц - конец выделяемой полосы
f_center = 30000;     % 30 кГц - центр полосы (для переноса в 0)

% Первый файл: диапазон 0-10 кГц
[b_low, a_low] = butter(6, f_low/(Fs/2), 'low');
audio_low = filtfilt(b_low, a_low, audio);

% Второй файл: перенос 20-40 кГц в диапазон -20кГц до +20кГц
% Выделяем полосу 20-40 кГц
[b_band, a_band] = butter(6, [f_band_start, f_band_end]/(Fs/2), 'bandpass');
audio_band = filtfilt(b_band, a_band, audio);

% Переносим центр полосы (30 кГц) в 0
t = (0:length(audio)-1)' / Fs;
shift_signal = exp(-1j * 2 * pi * f_center * t);
audio_shifted_center = audio_band .* shift_signal;

% Фильтрайия сигнала
[b_low_side, a_low_side] = butter(6, 20000/(Fs/2), 'low');
audio_shifted_center_filtered = filtfilt(b_low_side, a_low_side, audio_shifted_center);

% Теперь полоса находится в диапазоне -20кГц до +20кГц
% Выделяем правую боковую полосу (0 до +20 кГц)
right_sideband = real(audio_shifted_center_filtered); % Берем реальную часть для правой боковой полосы

% Нормализация сигналов
audio_low = audio_low / max(abs(audio_low));
right_sideband = right_sideband / max(abs(right_sideband));

% Сохранение результатов
audiowrite('structure_0-10kHz.wav', audio_low, Fs);
audiowrite('structure_20-40kHz.wav', right_sideband, Fs);

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

% Визуализация
figure;
% Исходный сигнал
subplot(3,1,1);
plot(t, audio);
title('Исходный сигнал - временная область');
xlabel('Время (с)');
ylabel('Амплитуда');
xlim([0, min(1, length(audio)/Fs)]);
grid on;
% Низкочастотный сигнал (0-10 кГц)
subplot(3,1,2);
plot(t, audio_low);
title('Низкочастотная компонента (0-10 кГц) - временная область');
xlabel('Время (с)');
ylabel('Амплитуда');
xlim([0, min(1, length(audio)/Fs)]);
grid on;
% Правая боковая полоса (0-20 кГц)
subplot(3,1,3);
plot(t, right_sideband);
title('Правая боковая полоса (0-20 кГц) - временная область');
xlabel('Время (с)');
ylabel('Амплитуда');
xlim([0, min(1, length(audio)/Fs)]);
grid on;

% Амплитудные спектры
% Спектр исходного сигнала
N = length(audio);
f = (0:N-1)*Fs/N;
figure;
spectrum_orig = abs(fft(audio));
plot(f(1:N/2), 20*log10(spectrum_orig(1:N/2)));
title('Исходный сигнал - амплитудный спектр');
xlabel('Частота (Гц)');
ylabel('Амплитуда (дБ)');
xlim([0, Fs/2]);
grid on;
% Спектр низкочастотного сигнала
figure;
spectrum_low = abs(fft(audio_low));
plot(f(1:N/2), 20*log10(spectrum_low(1:N/2)));
title('Низкочастотная компонента (0-10 кГц) - амплитудный спектр');
xlabel('Частота (Гц)');
ylabel('Амплитуда (дБ)');
xlim([0, Fs/2]);
grid on;
% Спектр правой боковой полосы
figure;
spectrum_right = abs(fft(right_sideband));
plot(f(1:N/2), 20*log10(spectrum_right(1:N/2)));
title('Правая боковая полоса (0-20 кГц) - амплитудный спектр');
xlabel('Частота (Гц)');
ylabel('Амплитуда (дБ)');
xlim([0, Fs/2]);
grid on;

% Спектрограммы
% Спектрограмма исходного сигнала
figure;
spectrogram(audio, 1024, 512, 1024, Fs, 'yaxis');
title('Исходный сигнал - спектрограмма');
colorbar;
ylim([0, 50]);
% Спектрограмма низкочастотного сигнала
figure;
spectrogram(audio_low, 1024, 512, 1024, Fs, 'yaxis');
title('Низкочастотная компонента (0-10 кГц) - спектрограмма');
colorbar;
ylim([0, 50]);
% Спектрограмма правой боковой полосы
figure;
spectrogram(right_sideband, 1024, 512, 1024, Fs, 'yaxis');
title('Правая боковая полоса (0-20 кГц) - спектрограмма');
colorbar;
ylim([0, 50]);

% Сравнение всех спектров
figure;
plot(f(1:N/2), 20*log10(spectrum_orig(1:N/2)), 'k', 'LineWidth', 1, 'DisplayName', 'Исходный');
hold on;
plot(f(1:N/2), 20*log10(spectrum_low(1:N/2)), 'b', 'LineWidth', 1, 'DisplayName', 'Низкочастотный (0-10 кГц)');
plot(f(1:N/2), 20*log10(spectrum_right(1:N/2)), 'r', 'LineWidth', 1, 'DisplayName', 'Правая боковая полоса (0-20 кГц)');
title('Сравнение всех спектров');
xlabel('Частота (Гц)');
ylabel('Амплитуда (дБ)');
xlim([0, Fs/2]);
legend;
grid on;

% Процесс переноса
N = length(audio);
f = (0:N-1)*Fs/N;
% Спектры на разных этапах обработки
spectrum_orig = abs(fft(audio));
spectrum_band = abs(fft(audio_band));
spectrum_shifted = abs(fft(audio_shifted_center));
spectrum_shifted_filtered = abs(fft(audio_shifted_center_filtered));
spectrum_right = abs(fft(right_sideband));
% Для двустороннего отображения (отрицательные частоты)
f_shifted = (-N/2:N/2-1)*Fs/N;
spectrum_shifted_shifted = fftshift(spectrum_shifted);
spectrum_shifted_filtered_shifted = fftshift(spectrum_shifted_filtered);
% Исходный высокочастотный сигнал (20-40 кГц)
figure;
plot(f(1:N/2), 20*log10(spectrum_band(1:N/2)));
title('Полосовой фильтр 20-40 кГц');
xlabel('Частота (Гц)');
ylabel('Амплитуда (дБ)');
xlim([10000, 50000]);
grid on;
line([f_band_start, f_band_start], ylim, 'Color', 'r', 'LineStyle', '--', 'LineWidth', 1);
line([f_band_end, f_band_end], ylim, 'Color', 'r', 'LineStyle', '--', 'LineWidth', 1);
text(f_band_start, max(ylim)-10, '20 кГц', 'Color', 'r');
text(f_band_end, max(ylim)-10, '40 кГц', 'Color', 'r');
% После переноса
figure;
plot(f_shifted, 20*log10(spectrum_shifted_shifted));
title('После переноса 30 кГц → 0 Гц');
xlabel('Частота (Гц)');
ylabel('Амплитуда (дБ)');
xlim([-50000, 50000]);
grid on;
line([-20000, -20000], ylim, 'Color', 'r', 'LineStyle', '--', 'LineWidth', 1);
line([20000, 20000], ylim, 'Color', 'r', 'LineStyle', '--', 'LineWidth', 1);
line([0, 0], ylim, 'Color', 'g', 'LineStyle', '-', 'LineWidth', 2);
text(-25000, max(ylim)-10, '-20 кГц', 'Color', 'r');
text(15000, max(ylim)-10, '+20 кГц', 'Color', 'r');
text(1000, max(ylim)-20, 'Центр: 0 Гц', 'Color', 'g');
% После низкочастотной фильтрации
figure;
plot(f_shifted, 20*log10(spectrum_shifted_filtered_shifted));
title('После НЧ фильтрации (0-20 кГц)');
xlabel('Частота (Гц)');
ylabel('Амплитуда (дБ)');
xlim([-30000, 30000]);
grid on;
line([-20000, -20000], ylim, 'Color', 'r', 'LineStyle', '--', 'LineWidth', 1);
line([20000, 20000], ylim, 'Color', 'r', 'LineStyle', '--', 'LineWidth', 1);
text(-18000, max(ylim)-10, '-20 кГц', 'Color', 'r');
text(15000, max(ylim)-10, '+20 кГц', 'Color', 'r');
% Правая боковая полоса
figure;
plot(f(1:N/2), 20*log10(spectrum_right(1:N/2)));
title('Правая боковая полоса (реальная часть)');
xlabel('Частота (Гц)');
ylabel('Амплитуда (дБ)');
xlim([0, 25000]);
grid on;
line([20000, 20000], ylim, 'Color', 'r', 'LineStyle', '--', 'LineWidth', 1);
text(15000, max(ylim)-10, '20 кГц', 'Color', 'r');
% Диаграмма процесса переноса
figure;
freq_ranges = {
    'Исходный: 0-40 кГц', 0, 40000;
    'Полоса 20-40 кГц', 20000, 40000;
    'После переноса: ±20 кГц', -20000, 20000;
    'Правая полоса: 0-20 кГц', 0, 20000
};

for i = 1:size(freq_ranges, 1)
    y_pos = size(freq_ranges, 1) - i + 1;
    plot([freq_ranges{i,2}, freq_ranges{i,3}], [y_pos, y_pos], 'LineWidth', 8);
    hold on;
    text(max([freq_ranges{i,2}, freq_ranges{i,3}]) + 5000, y_pos, freq_ranges{i,1}, 'FontSize', 10);
end
title('Диаграмма переноса частот');
xlabel('Частота (Гц)');
ylabel('Этап обработки');
xlim([-25000, 50000]);
ylim([0, size(freq_ranges, 1) + 1]);
grid on;

% Вывод информации о сигналах
fprintf('Информация о сигналах:\n');
fprintf('Частота дискретизации: %d Гц\n', Fs);
fprintf('Длина исходного сигнала: %d отсчетов (%.2f сек)\n', length(audio), length(audio)/Fs);
fprintf('Диапазон низкочастотного сигнала: 0-%d Гц\n', f_low);
fprintf('Исходный диапазон высокочастотного сигнала: %d-%d Гц\n', f_band_start, f_band_end);
fprintf('Центр переноса: %d Гц\n', f_center);
fprintf('Целевой диапазон после переноса: 0-%d Гц\n', 20000);
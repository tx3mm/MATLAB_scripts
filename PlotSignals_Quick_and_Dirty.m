clc
clear all

allMatFiles = dir('*.mat');

numberDifferentWaveforms = input('Enter number of different waveforms: ');

for i = 1 : numberDifferentWaveforms: length(allMatFiles)
    newStr = split(allMatFiles(i).name, '_');
    filename = '';
    for j = 1 : (length(newStr)-1)
        if j==1
            filename = [filename newStr{j}];
        else
            filename = [filename '_' newStr{j}];
        end
    end
end

%% Load the signals and save into corrseponding variables
DIFF_data = load([filename '_DIFF.mat']);
TXD_data = load([filename '_TXD.mat']);
CANH_data = load([filename '_CANH.mat']);
CANL_data = load([filename '_CANL.mat']);

DIFF_CANH_CANL_data.Time = CANH_data.Time;
DIFF_CANH_CANL_data.Amplitude = (CANH_data.Amplitude - CANL_data.Amplitude);

DIFF_data_minus_first_sample.Amplitude = DIFF_data.Amplitude - DIFF_data.Amplitude(1);

figure(1)
hold on; grid on;
plot (DIFF_data.Time, DIFF_data.Amplitude, 'Color', 'm');
plot (DIFF_CANH_CANL_data.Time, DIFF_CANH_CANL_data.Amplitude, 'Color', 'g');
% plot (DIFF_data.Time, DIFF_data_minus_first_sample.Amplitude, 'Color', 'r');
legend('CANH-CANL', 'Differential probe - (N first samples)'); %'Differential probe', 
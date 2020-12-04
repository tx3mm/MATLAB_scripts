% TODO: Find a way to detect the idle part of the signal automatically

clc
clear all
close all

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

% Compensate for the offset of the signal introduced by VirtGND
% Need to have idle time before the frame starts in order to have this
% correctly calculated
numberOfSamplesForAveraging = 300;
averageOfFirstSamples = 0;
for j = 1 : numberOfSamplesForAveraging
    averageOfFirstSamples = averageOfFirstSamples + DIFF_data.Amplitude(j);
end
averageOfFirstSamples = averageOfFirstSamples/numberOfSamplesForAveraging;
       
% averageOfFirstSamples = 1; %Manual measurement
DIFF_data_minus_first_sample.Amplitude = DIFF_data.Amplitude - averageOfFirstSamples;
% Compensate for the Gain scaling
DIFF_data_minus_first_sample.Amplitude = DIFF_data_minus_first_sample.Amplitude / 0.505;

figure(1)
hold on; grid on;
plot (DIFF_data.Time, DIFF_data.Amplitude, 'Color', 'm');
plot (DIFF_CANH_CANL_data.Time, DIFF_CANH_CANL_data.Amplitude, 'Color', 'g');
title(filename, 'Interpreter', 'none');
legend('Differential probe', 'CANH-CANL'); 

figure(2)
hold on; grid on;
set(gcf, 'Units', 'Normalized', 'OuterPosition', [0 0 1 1]); %make full screen
plot (DIFF_CANH_CANL_data.Time, DIFF_CANH_CANL_data.Amplitude, 'Color', 'g');
plot (DIFF_data.Time, DIFF_data_minus_first_sample.Amplitude, 'Color', 'm');
title([filename ', offset compensated'], 'Interpreter', 'none');
legend('CANH-CANL', 'Differential probe - (N first samples)');
savefig(gcf,[filename '_offsetCompensated_Figure.fig'])
print('-f2',[filename '_offsetCompensated_Plot'],'-dpng', '-r300'); %300dpi

figure(3)
hold on; grid on;
plot (DIFF_CANH_CANL_data.Time, smoothdata(DIFF_CANH_CANL_data.Amplitude, 'movmedian'), 'Color', 'g');
plot (DIFF_data.Time, smoothdata(DIFF_data_minus_first_sample.Amplitude, 'movmedian'), 'Color', 'm');
title([filename ', offset compensated, Data smoothed'], 'Interpreter', 'none');
legend('CANH-CANL Smoothed', 'Differential probe - (N first samples) Smoothed');


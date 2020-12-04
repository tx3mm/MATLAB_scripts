clc
clear all
close all

allMatFiles = dir('*.mat');

    filename = '';
    newStr = split(allMatFiles(1).name, '_');
    for j = 1 : (length(newStr)-1)
        if j==1
            filename = [filename newStr{j}];
        else
            filename = [filename '_' newStr{j}];
        end
    end

Data = load([filename '_TXD.mat']);

% t = linspace(0,3*pi)';
% duty = 50;
% columns = {'Time', 'Amplitude'};
% Data(:,1)= (t);
% Data(:,2) = square(t, duty);

plot(Data.Time, Data.Amplitude)
% plot(Data(:,1), Data(:,2))
hold on, grid on;

compare = @ (a, b) max (a, b);

TF1 = islocalmin(Data.Amplitude, 'FlatSelection', 'all');
flat_low = find(TF1 == 1);
TF2 = islocalmax(Data.Amplitude, 'FlatSelection', 'all');
flat_high = find(TF2 == 1);

for i = 1 : compare(length(flat_low), length(flat_high))
    if i <= length(flat_high)
        plot(Data.Time(flat_high(i)),Data.Amplitude(flat_high(i)),'cd', 'HandleVisibility', 'off');
        if i == 1
            text(Data.Time(flat_high(i)),Data.Amplitude(flat_high(i)),...
                'flat high','Color', 'b', 'VerticalAlignment','bottom', 'HorizontalAlignment', 'center');
        end
        text(Data.Time(flat_high(i)),Data.Amplitude(flat_high(i)),...
            '','Color', 'b', 'VerticalAlignment','bottom', 'HorizontalAlignment', 'center');
    end
    
    if i <= length(flat_low)
        plot(Data.Time(flat_low(i)),Data.Amplitude(flat_low(i)),'md', 'HandleVisibility', 'off');
        if i == 1
            text(Data.Time(flat_low(i)),Data.Amplitude(flat_low(i)),...
                'flat low','Color', 'r', 'VerticalAlignment','bottom', 'HorizontalAlignment', 'center');
        end
        text(Data.Time(flat_low(i)),Data.Amplitude(flat_low(i)),...
            '','Color', 'r', 'VerticalAlignment','bottom', 'HorizontalAlignment', 'center');
    end
end
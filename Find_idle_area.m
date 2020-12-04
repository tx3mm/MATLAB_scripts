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

TF1 = islocalmin(Data(:,2), 'FlatSelection', 'all');
flat_low = find(TF1 == 1);
TF2 = islocalmax(Data(:,2), 'FlatSelection', 'all');
flat_high = find(TF2 == 1);

for i = 1 : compare(length(flat_low), length(flat_high))
    if i <= length(flat_high)
    plot(Data((flat_high(i)),1),Data((flat_high(i)),2),'cd', 'HandleVisibility', 'off');
    if i == 1
         text(Data((flat_high(i)),1),Data((flat_high(i)),2),...
        'flat high','Color', 'b', 'VerticalAlignment','bottom', 'HorizontalAlignment', 'center');
    end
    text(Data((flat_high(i)),1),Data((flat_high(i)),2),...
        '','Color', 'b', 'VerticalAlignment','bottom', 'HorizontalAlignment', 'center');
    end
    
    if i <= length(flat_low)
    plot(Data((flat_low(i)),1),Data((flat_low(i)),2),'md', 'HandleVisibility', 'off');
    if i == 1
        text(Data((flat_low(i)),1),Data((flat_low(i)),2),...
        'flat low','Color', 'b', 'VerticalAlignment','bottom', 'HorizontalAlignment', 'center');
    end
    text(Data((flat_low(i)),1),Data((flat_low(i)),2),...
        '','Color', 'b', 'VerticalAlignment','bottom', 'HorizontalAlignment', 'center');
    end
end
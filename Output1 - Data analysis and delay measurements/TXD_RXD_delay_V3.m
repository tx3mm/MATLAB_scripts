% Only use frequencies up to 4MHz
% There are 6 different measurements to be made - DONE
% Use the transform2mat.m script from Axel for the data saved from the Osci
% TODO: Name signals and points
% TODO: Add calculated results in a table with their names and values


clc
close all
clear all

%% Load the signals and save into corrseponding variables
deviceModel = input('Enter device model: ', 's');
TXD_data = load('5.0VIO_5.5VCC_50Duty_TXD.mat');
newstr = split('5.0VIO_5.5VCC_50Duty_TXD.mat','_');
amplValueUsed = split(newstr(1), 'VIO');
fileNameVccValue = split(newstr(2), 'VCC');

fileNameAmplValue = amplValueUsed;
if contains(fileNameAmplValue{1}, '.')
    fileNameAmplValue{1} = strrep(fileNameAmplValue{1}, '.', ',');
end
if contains(fileNameVccValue{1}, '.')
    fileNameVccValue{1} = strrep(fileNameVccValue{1}, '.', ',');
end

amplValueUsed = str2double(amplValueUsed(1));

DIFF_data = load('5.0VIO_5.5VCC_50Duty_DIFF.mat');
RXD_data = load('5.0VIO_5.5VCC_50Duty_RXD.mat');

startTimeID = TXD_data.Time;

%% Plot the base signals
f1 = figure(1);
hold on; grid on;
set(gcf, 'Units', 'Normalized', 'OuterPosition', [0 0 1 1]); %make full screen
plot(TXD_data.Time, TXD_data.Amplitude,'-b');
plot(TXD_data.Time, DIFF_data.Amplitude,'-g');
plot(TXD_data.Time, RXD_data.Amplitude,'-m');
xlabel('Time');
ylabel('Volts');
title([deviceModel ' ' newstr{1} ' ' newstr{2}])
% title(['TJA1462, ' newstr{1} ' ' newstr{2}])
lgd = legend('TXD', 'BUS', 'RXD');
lgd.NumColumns = 1;

%% Find rising and falling edges and adjust the starting time accordingly
loc = (TXD_data.Amplitude >= 0.5*amplValueUsed);
d_loc = [false ; diff(loc)];
rising_edges_index = find(d_loc == 1);
loc = (TXD_data.Amplitude <= 0.5*amplValueUsed);
d_loc = [false ; diff(loc)];
falling_edges_index = find(d_loc == 1);
for i = 1 : length(falling_edges_index)
    plot(TXD_data.Time(falling_edges_index(i)),TXD_data.Amplitude(falling_edges_index(i)),'md', 'HandleVisibility', 'off');
    text(TXD_data.Time(falling_edges_index(i)),TXD_data.Amplitude(falling_edges_index(i)),...
        'Falling edge','Color', 'b', 'VerticalAlignment','bottom', 'HorizontalAlignment', 'center');
    plot(TXD_data.Time(rising_edges_index(i)),TXD_data.Amplitude(rising_edges_index(i)),'cd', 'HandleVisibility', 'off');   
    text(TXD_data.Time(rising_edges_index(i)),TXD_data.Amplitude(rising_edges_index(i)),...
        'Rising edge','Color', 'b', 'VerticalAlignment','bottom', 'HorizontalAlignment', 'center');
end

if rising_edges_index(1) < falling_edges_index(1)
    % Adjust time to start from 0
    clear startTimeID
    startTimeID = find(TXD_data.Time >= 0); % get indexes after time = 0
end
%% Find 30% of TXD falling edge and 0.9V of the differential signal
%   and calculate the delay between them (TXD_busdom)
id = (TXD_data.Amplitude(startTimeID(1):(end)) <= (0.3*amplValueUsed));
id_TXD_falling = find(id) + startTimeID(1)-1;

id = DIFF_data.Amplitude(id_TXD_falling(1):end) >= 0.9;
id_DIFF_rising = find(id)+id_TXD_falling(1)-1;

TXD_busdom = TXD_data.Time(id_DIFF_rising(1)) - TXD_data.Time(id_TXD_falling(1));

plot(TXD_data.Time(id_TXD_falling(1)),TXD_data.Amplitude(id_TXD_falling(1)),'rp', 'HandleVisibility', 'off');
text(TXD_data.Time(id_TXD_falling(1)),TXD_data.Amplitude(id_TXD_falling(1)),...
        '30%', 'VerticalAlignment','bottom', 'HorizontalAlignment', 'left');
plot(TXD_data.Time(id_DIFF_rising(1)),DIFF_data.Amplitude(id_DIFF_rising(1)),'rp', 'HandleVisibility', 'off');
text(TXD_data.Time(id_DIFF_rising(1)),DIFF_data.Amplitude(id_DIFF_rising(1)),...
        '0.9V', 'VerticalAlignment','bottom', 'HorizontalAlignment', 'left');
%% Find 70% of TXD and 0.5V of the differential signal
% and calculate the delay between them (TXD_busrec)

id = (TXD_data.Amplitude(id_DIFF_rising(1):end) >= (0.7 * amplValueUsed));
id_TXD_rising = find(id) + id_DIFF_rising(1) - 1;

id = DIFF_data.Amplitude(id_TXD_rising(1):end) <= 0.5;
id_DIFF_falling = find(id)+id_TXD_rising(1) - 1;

TXD_busrec = TXD_data.Time(id_DIFF_falling(1)) - TXD_data.Time(id_TXD_rising(1));

plot(TXD_data.Time(id_TXD_rising(1)),TXD_data.Amplitude(id_TXD_rising(1)),'rp', 'HandleVisibility', 'off');
text(TXD_data.Time(id_TXD_rising(1)),TXD_data.Amplitude(id_TXD_rising(1)),...
        '70%', 'VerticalAlignment','bottom', 'HorizontalAlignment', 'left');
plot(TXD_data.Time(id_DIFF_falling(1)),DIFF_data.Amplitude(id_DIFF_falling(1)),'rp', 'HandleVisibility', 'off');
text(TXD_data.Time(id_DIFF_falling(1)),DIFF_data.Amplitude(id_DIFF_falling(1)),...
        '0.5V', 'VerticalAlignment','bottom', 'HorizontalAlignment', 'left');
%% Loop delay - 30% TXD to 30% RXD

id = (RXD_data.Amplitude(startTimeID(1):(end)) <= (0.3*amplValueUsed));
id_RXD_falling = find(id) + startTimeID(1)-1;

TXDL_RXDL_delay = RXD_data.Time(id_RXD_falling(1))  - TXD_data.Time(id_TXD_falling(1));

p = plot(RXD_data.Time(id_RXD_falling(1)),RXD_data.Amplitude(id_RXD_falling(1)),'rp', 'HandleVisibility', 'off');
text(RXD_data.Time(id_RXD_falling(1)),RXD_data.Amplitude(id_RXD_falling(1)),...
        '30%', 'VerticalAlignment','bottom', 'HorizontalAlignment', 'left');

%% Loop delay - 70% TXD to 70% RXD

id = (RXD_data.Amplitude(id_TXD_rising(1):end) >= (0.7 * amplValueUsed));
id_RXD_rising = find(id) + id_TXD_rising(1) - 1;

TXDH_RXDH_delay = RXD_data.Time(id_RXD_rising(1))  - TXD_data.Time(id_TXD_rising(1));

plot(RXD_data.Time(id_RXD_rising(1)),RXD_data.Amplitude(id_RXD_rising(1)),'rp', 'HandleVisibility', 'off');
text(RXD_data.Time(id_RXD_rising(1)),RXD_data.Amplitude(id_RXD_rising(1)),...
        '70%', 'VerticalAlignment','bottom', 'HorizontalAlignment', 'left');
%% Bus Dominant to RXDL
BUSDOM_RXDL = RXD_data.Time(id_RXD_falling(1)) - TXD_data.Time(id_DIFF_rising(1));

%% Bus Recessive to RXDH
BUSREC_RXDH = RXD_data.Time(id_RXD_rising(1)) - TXD_data.Time(id_DIFF_falling(1));
text (2,3, sprintf('BUSREC_RXDH = %d', BUSREC_RXDH));

%% Display all the calculated values on the plot in ns
dim = zeros(6,4);
str = {['TXD\_busdom = ',num2str(TXD_busdom*1e9) 'ns'];...
       ['TXD\_busrec = ',num2str(TXD_busrec*1e9) 'ns'];...
       ['BUSDOM\_RXDL = ',num2str(BUSDOM_RXDL*1e9) 'ns'];...
       ['BUSREC\_RXDH = ',num2str(BUSREC_RXDH*1e9) 'ns'];...
       ['TXDL\_RXDL\_delay = ' num2str(TXDL_RXDL_delay*1e9) 'ns'];...
       ['TXDH\_RXDH\_delay = ',num2str(TXDH_RXDH_delay*1e9) 'ns']...
      };
dim(1,:) = [.79 .2 .79 .2];
for i = 1 : 6
    
    if i ~= 1
        dim(i,2:2:4) = dim(i-1,2:2:4)-0.02 ; 
        dim(i,1:2:3) = dim(i-1,1:2:3);
    end
    annotation('textbox',dim(i,:),'String',str{i},'FitBoxToText','on');

end

%% Save the measurements in a XLS file
fileName = [deviceModel '_' fileNameAmplValue{1} 'VIO_' fileNameVccValue{1} 'VCC'];
tableMeasurements = {'TXD_busdom' 'TXD_busrec' 'BUSDOM_RXDL' 'BUSREC_RXDH' 'TXDL_RXDL_delay' 'TXDH_RXDH_delay';...
                      TXD_busdom*1e9 TXD_busrec*1e9 BUSDOM_RXDL*1e9 BUSREC_RXDH*1e9 TXDL_RXDL_delay*1e9 TXDH_RXDH_delay*1e9};     
xlsFile = [fileName '.xlsx'];                  
writecell (tableMeasurements, xlsFile, 'Sheet' , 'Output1(ns)' , 'Range' , 'B1' );             

%% Save the plots to PNG and PDF files with an appropriate name
fileName = [fileName '_Plot'];
print('-f1',fileName,'-dpdf', '-bestfit');
print('-f1',fileName,'-dpng', '-r300'); %300dpi
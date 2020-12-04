% Only use frequencies up to 4MHz
% There are 6 different measurements to be made
% Use the transform2mat.m script from Axel for the data saved from the Osci
% TIME STARTS FROM 0 REGARDLESS OF THE DATA; MEASURING POINTS NEED TO BE FIXED
% NOT WORKING WELL. Use V3 instead
clc
close all
clear all

%% Load the signals and save into corrseponding variables
TXD_data = load('5.0VIO_4.5VCC_50Duty_TXD.mat');
newstr = split('5.0VIO_4.5VCC_50Duty_TXD.mat','_');
amplValueUsed = split(newstr(1), 'VIO');
amplValueUsed = str2double(amplValueUsed(1));

DIFF_data = load('5.0VIO_4.5VCC_50Duty_DIFF.mat');

%% Adjust time to start from 0
startTimeID = find(TXD_data.Time >= 0);

%% Plot the base signals
figure(1);
hold on; grid on;
plot(TXD_data.Time(startTimeID(1):(end)), TXD_data.Amplitude(startTimeID(1):(end)),'-b');
plot(TXD_data.Time(startTimeID(1):(end)), DIFF_data.Amplitude(startTimeID(1):(end)),'-b');


%% Find 30% of TXD falling edge and 0.9V of the differential signal
%   and calculate the delay between them (TXD_busdom)
id = (TXD_data.Amplitude < (0.3*amplValueUsed));
id_TXD_falling = find(id);

id = DIFF_data.Amplitude(id_TXD_falling(1):end) >= 0.9;
id_DIFF_rising = find(id)+id_TXD_falling(1)-1;

TXD_busdom = TXD_data.Time(id_DIFF_rising(1)) - TXD_data.Time(id_TXD_falling(1));

plot(TXD_data.Time(id_TXD_falling(1)),TXD_data.Amplitude(id_TXD_falling(1)),'rp');
plot(TXD_data.Time(id_DIFF_rising(1)),DIFF_data.Amplitude(id_DIFF_rising(1)),'rp');

%% Find 70% of TXD and 0.5V of the differential signal
% and calculate the delay between them (TXD_busrec)

id = (TXD_data.Amplitude(id_DIFF_rising(1):end) >= (0.7 * amplValueUsed));
id_TXD_rising = find(id) + id_DIFF_rising(1) - 1;

id = DIFF_data.Amplitude(id_TXD_rising(1):end) <= 0.5;
id_DIFF_falling = find(id)+id_TXD_rising(1) - 1;

TXD_busrec = TXD_data.Time(id_DIFF_falling(1)) - TXD_data.Time(id_TXD_rising(1));

plot(TXD_data.Time(id_TXD_rising(1)),TXD_data.Amplitude(id_TXD_rising(1)),'rp');
plot(TXD_data.Time(id_DIFF_falling(1)),DIFF_data.Amplitude(id_DIFF_falling(1)),'rp');
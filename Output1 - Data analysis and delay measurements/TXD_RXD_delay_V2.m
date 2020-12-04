% Only use frequencies up to 4MHz
% There are 6 different measurements to be made
% Use the transform2mat.m script from Axel for the data saved from the Osci
% WORKING FOR OUTPUT3 FILES FORMAT

clc
close all
clear all

%% Load the signals and save into corrseponding variables
TXD_data = load('5VIO_5,5VCC_50DUTY_1MHz_TXD.csv');
Time = TXD_data(:,1);
Ampl_TXD = TXD_data(:,2);
newstr = split('5VIO_5,5VCC_50DUTY_1MHz_TXD.csv','_');
amplValueUsed = split(newstr(1), 'VIO');
amplValueUsed = str2double(amplValueUsed(1));

VOUT_data = load('5VIO_5,5VCC_50DUTY_1MHz_VOUT.csv');
Ampl_VOUT = VOUT_data(:,2);

%% Plot the base signals
figure(1);
hold on; grid on;
plot(Time,Ampl_TXD,'-b')
plot(Time,Ampl_VOUT,'-b')

%% Find 30% of TXD falling edge and 0.9V of the differential signal
%   and calculate the delay between them (TXD_busdom)
id = (Ampl_TXD < (0.3*amplValueUsed));
id_TXD_falling=find(id);

id = Ampl_VOUT(id_TXD_falling(1):end) >= 0.9;
id_VOUT_rising = find(id)+id_TXD_falling(1)-1;

TXD_busdom = Time(id_VOUT_rising(1)) - Time(id_TXD_falling(1));

plot(Time(id_TXD_falling(1)),Ampl_TXD(id_TXD_falling(1)),'rp');
plot(Time(id_VOUT_rising(1)),Ampl_VOUT(id_VOUT_rising(1)),'rp');

%% Find 70% of TXD and 0.5V of the differential signal
% and calculate the delay between them (TXD_busrec)

id = (Ampl_TXD(id_VOUT_rising(1):end) >= (0.7 * amplValueUsed));
id_TXD_rising = find(id) + id_VOUT_rising(1) - 1;

id = Ampl_VOUT(id_TXD_rising(1):end) <= 0.5;
id_VOUT_falling = find(id)+id_TXD_rising(1) - 1;

TXD_busrec = Time(id_VOUT_falling(1)) - Time(id_TXD_rising(1));

plot(Time(id_TXD_rising(1)),Ampl_TXD(id_TXD_rising(1)),'rp');
plot(Time(id_VOUT_falling(1)),Ampl_VOUT(id_VOUT_falling(1)),'rp');
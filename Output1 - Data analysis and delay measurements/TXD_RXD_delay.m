% Only use frequencies up to 4MHz

clc
close all
clear all

%% Load the signals and save into corrseponding variables
TXD_data = load('5VIO_5,5VCC_50DUTY_1MHz_TXD.csv');
Time = TXD_data(:,1);
Ampl_TXD = TXD_data(:,2);
VOUT_data = load('5VIO_5,5VCC_50DUTY_1MHz_VOUT.csv');
Ampl_VOUT = VOUT_data(:,2);

%% Get the points where the data signal is changing
pts_TXD = findchangepts(Ampl_TXD,...
    'Statistic','linear','MinThreshold',20);
pts_VOUT = findchangepts(Ampl_VOUT,...    
    'Statistic','linear','MinThreshold',20);

%% ischange
TF = ischange(Ampl_TXD);
for i = 1 : length(TF)
    if (TF ~= 0)
        valuesTF = TF(i);
    end
end
%% 

[~,ind_TXD]=max(diff(Time(pts_TXD)));
start_TXD=Time(pts_TXD(ind_TXD-2));

[~,ind_VOUT]=max(diff(Time(pts_VOUT)));
start_VOUT=Time(pts_VOUT(ind_VOUT-1));

TXD_busdom = start_VOUT - start_TXD;
%% Testing
TXD_low = Time(pts_TXD(5,:)) - Time(pts_TXD(3,:)); 
TXD_high = Time(length(Time)) - TXD_low;

%%
maxAmpl = max(Ampl_TXD);
id=Ampl_TXD< (0.3*maxAmpl);
id_TXD=find(id);

maxAmpl = max(Ampl_VOUT(id_TXD(1):end));
id=Ampl_VOUT(id_TXD(1):end) > 0.9;
id_VOUT = find(id)+id_TXD(1)-1;

TXD_busdom = Time(id_VOUT(1)) - Time(id_TXD(1));
%% Plotting the results
figure(1);
hold on; grid on;
plot(Time,Ampl_TXD,'-b')%,...
%     Time(pts_TXD), Ampl_TXD(pts_TXD),'rx');
plot(Time,Ampl_VOUT,'-b')%,...
%     Time(pts_VOUT), Ampl_VOUT(pts_VOUT),'rx');

plot(Time(id_TXD(1)),Ampl_TXD(id_TXD(1)),'rx');
plot(Time(id_VOUT(1)),Ampl_VOUT(id_VOUT(1)),'rx');
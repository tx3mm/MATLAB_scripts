% This script is used to perform different frequency, voltages and duty 
% cycle tests on the TJA1462A and TJA1442A transceivers,
% and the differential probe board.
% Developed by Anton Angov, August 2020
% To be further developed:
% - have all different parameters input from the user at the beginning of
% the measurement
% - add an option to pause between measurements, in case something needs to
% be changed in the setup
% - make into a standalone SW with a GUI for easy use
clc
clear all
close all

%%
%Variables to be used
CH1 = 1;
CH2 = 2;
VCC = '5_5';
VIO = 3.3; % Use only 3.3 or 5
VIOstr = '3_3'; % Construct from the value of VIO
dutyCycle = 0;
freqValues = [1:20]; %in MHz
dutyValues = [20.0 50.0 80.0]; %values in the range 0:100
%% Instrument Connection
% Create a VISA-TCPIP object.
osciInterfaceObj = instrfind('Type', 'visa-tcpip', 'RsrcName', 'TCPIP0::169.254.178.98::inst0::INSTR', 'Tag', '');
sigGenInterfaceObj = instrfind('Type', 'visa-tcpip', 'RsrcName', 'TCPIP0::169.254.154.82::inst0::INSTR', 'Tag', '');

% Create the VISA-TCPIP object if it does not exist
% otherwise use the object that was found.
if isempty(osciInterfaceObj) || isempty(sigGenInterfaceObj)
    osciInterfaceObj = visa('TEK', 'TCPIP0::169.254.178.98::inst0::INSTR');
    sigGenInterfaceObj = visa('TEK', 'TCPIP0::169.254.154.82::inst0::INSTR');
else
    fclose(osciInterfaceObj);
    fclose(sigGenInterfaceObj);
    osciInterfaceObj = osciInterfaceObj(1);
    sigGenInterfaceObj = sigGenInterfaceObj(1);
end

% Create a device object. 
osciDeviceObj = icdevice('tektronix_tds5034.mdd', osciInterfaceObj);
sigGenDeviceObj = icdevice('tek_afg3000.mdd', sigGenInterfaceObj);
%%
props = set(osciDeviceObj);
values = get(osciDeviceObj);
%% 
% Connect device object to hardware.
connect(osciDeviceObj);
connect(sigGenDeviceObj);

%% Initial settings of oscilloscope
set(osciDeviceObj.Acquisition(CH1), 'State', 'run');
set(osciDeviceObj.Acquisition(CH1), 'Control', 'run-stop');
set(osciDeviceObj.Acquisition(CH1), 'Mode', 'average');
set(osciDeviceObj.Acquisition(CH1), 'NumberOfAverages', 10);
set(osciDeviceObj.Acquisition(CH1), 'FastAcquisition', 'off');
set(osciDeviceObj.Display(CH1), 'Style', 'vectors');
set(osciDeviceObj.Display(CH1), 'Format', 'yt');
        
% Format data to be transfered
fprintf(osciInterfaceObj, 'DATA:WIDTH 2');
fprintf(osciInterfaceObj, 'DATA:ENCdg RIBinary');
fprintf(osciInterfaceObj, 'WFMPre:BYT_Or LSB');
fprintf(osciInterfaceObj, 'DATA:START 1');
fprintf(osciInterfaceObj, 'DATA:STOP 100000');

% Set default scale
fprintf(osciInterfaceObj, 'HOR:RECO 100000');
fprintf(osciInterfaceObj, 'HOR:MAI:SCAL 80.000e-9');
%% Configure the signal generator
configSignGen(sigGenDeviceObj, sigGenInterfaceObj, freqValues(1), dutyValues(1), VIO);
set(sigGenDeviceObj.Output(CH1), 'State', 'On');

%% Enter data acquisition loop. 
%  The process goes through the different duty cycles specified in the
%  dutyValues array and for each value runs the different frequency tests
%  gets the data back from the oscilloscope and saves it into corresponding
%  files and plots. Depending on the different duty cycle values,
%  the scaling is changed differently based on the scaleMap containter. #
%  Those scaling values have been tested and found to work best, before the
%  measurements have started
for dutyLoopIdx = 1:length(dutyValues)

    if dutyLoopIdx > 1
        if dutyValues(dutyLoopIdx) < 100
            set(sigGenDeviceObj.Pulse(CH1), 'DutyCycle', dutyValues(dutyLoopIdx));
             %Needed as for higher freq. the values might have been changed
            set(sigGenDeviceObj.Frequency(CH1), 'Frequency', changeFreqMHz(1));
            fprintf(sigGenInterfaceObj, 'PULS:TRAN:LEAD 18e-9');
            fprintf(sigGenInterfaceObj, 'PULS:TRAN:TRA 18e-9');
        else
            printf('Duty cycle value not allowed');
        end       
    end
    
    horPos = 50;
    if dutyValues(dutyLoopIdx) == 20
       horPos = 10;
       scaleChangeAtMHz = [2 4 11];
       scaleChangeToNs = [40 20 10];
       scaleMap = containers.Map(scaleChangeAtMHz, scaleChangeToNs);
       fprintf(osciInterfaceObj, 'HOR:RECO 100000');
       fprintf(osciInterfaceObj, 'HOR:MAI:SCAL 40.000e-9');
       fprintf(osciInterfaceObj, 'HORizontal:POSition %d', horPos);       
    elseif dutyValues(dutyLoopIdx) == 50
       horPos = 75;
       scaleChangeAtMHz = [2 11];
       scaleChangeToNs = [40 20];
       scaleMap = containers.Map(scaleChangeAtMHz, scaleChangeToNs);
       fprintf(osciInterfaceObj, 'HOR:RECO 100000');
       fprintf(osciInterfaceObj, 'HOR:MAI:SCAL 80.000e-9');
       fprintf(osciInterfaceObj, 'HORizontal:POSition %d', horPos);    
    elseif dutyValues(dutyLoopIdx) == 80
       horPos = 60;
       scaleChangeAtMHz = [1 3];
       scaleChangeToNs = [40 20];
       scaleMap = containers.Map(scaleChangeAtMHz, scaleChangeToNs);
       fprintf(osciInterfaceObj, 'HOR:RECO 100000');
       fprintf(osciInterfaceObj, 'HOR:MAI:SCAL 40.000e-9');
       fprintf(osciInterfaceObj, 'HORizontal:POSition %d', horPos);  
    end
  
    
    for freqLoopIdx = 1:length(freqValues)
        set(sigGenDeviceObj.Frequency(CH1), 'Frequency', changeFreqMHz(freqValues(freqLoopIdx)));
        pause(1);
        Filename_prefix = sprintf('StoredData/%sVIO_%sVCC_%dDUTY_%dMHz_',VIOstr, VCC, dutyValues(dutyLoopIdx), freqValues(freqLoopIdx));
        
        timeBase = get(osciDeviceObj.Acquisition(CH1), 'Timebase');        
        %Change the SCALE based on the current freq. and duty cycle
        
        if isKey(scaleMap,freqValues(freqLoopIdx))          
           set(osciDeviceObj.Acquisition(CH1), 'Timebase', scaleMap(freqValues(freqLoopIdx))/(10^9));
           if dutyValues(dutyLoopIdx) == 20
               horPos = horPos + 3;               
           elseif dutyValues(dutyLoopIdx) == 50
               horPos = horPos - (4+freqLoopIdx);
           elseif dutyValues(dutyLoopIdx) == 80
               horPos = horPos - 10;
           end
           fprintf(osciInterfaceObj, 'HORizontal:POSition %d',horPos);
        end            
        
        %% Get data from the osci
        osciGroupObj = get(osciDeviceObj, 'Waveform');
        now = datestr(now,'mm-dd-yyyy_HH-MM-SS'); %might not be necessary later
        %% Save the data into corresponding vectors
        [Y_CH1,X_CH1,YUNIT_CH1,XUNIT_CH1] = invoke(osciGroupObj, 'readwaveform', 'CH1');
        [Y_CH2,X_CH2,YUNIT_CH2,XUNIT_CH2] = invoke(osciGroupObj, 'readwaveform', 'CH2');
        [Y_CH3,X_CH3,YUNIT_CH3,XUNIT_CH3] = invoke(osciGroupObj, 'readwaveform', 'CH3');
        [Y_CH4,X_CH4,YUNIT_CH4,XUNIT_CH4] = invoke(osciGroupObj, 'readwaveform', 'CH4');
        %% Plot the data
        FigH = figure ( 'position' , get (0, 'screensize' ));
        F = getframe(FigH);
        plot(X_CH1,Y_CH1, 'yellow'),grid on
        xlabel(XUNIT_CH1)
        ylabel(YUNIT_CH1)
        hold on
        plot(X_CH2,Y_CH2, 'blue')
        plot(X_CH3,Y_CH3, 'magenta')
        plot(X_CH4,Y_CH4, 'green')
        Delay_CH3_CH4 = finddelay(Y_CH3,Y_CH4);
        legend('CANH', 'CANL', 'VOUT', 'TXD');
        plotName = strcat(Filename_prefix, sprintf('%s_Plot', now));
        print('-f1',plotName,'-dpdf', '-bestfit');
        % imwrite (F.cdata, 'plotName', 'png' )
        print('-f1',plotName,'-dpng', '-r300'); %300dpi
        %% Store the data to CSV
        CANH = [X_CH1;Y_CH1];
        Filename = sprintf('%s_CANH.csv', now);
        Filename = strcat(Filename_prefix, Filename);
        writematrix(CANH', Filename, 'Delimiter', ';')
        
        CANL = [X_CH2;Y_CH2];
        Filename = sprintf('%s_CANL.csv', now);
        Filename = strcat(Filename_prefix, Filename);
        writematrix(CANL', Filename, 'Delimiter', ';')
        
        VOUT = [X_CH3;Y_CH3];
        Filename = sprintf('%s_VOUT.csv', now);
        Filename = strcat(Filename_prefix, Filename);
        writematrix(VOUT', Filename, 'Delimiter', ';')
        
        TXD = [X_CH4;Y_CH4];
        Filename = sprintf('%s_TXD.csv', now);
        Filename = strcat(Filename_prefix, Filename);
        writematrix(TXD', Filename, 'Delimiter', ';')
        
        % Clear objects and perform the next frequency measurement
        clear groupObj now;
        close all
    end    
        % reset so they can be used for different parameters
        clear scaleMap scaleChangeAtMHz scaleChangeToNs; 
end

%% Disconnect device object from hardware.
disconnect(osciDeviceObj);
disconnect(sigGenDeviceObj);

%% Clean and delete all objects
delete([osciDeviceObj osciInterfaceObj]);
delete([sigGenDeviceObj sigGenInterfaceObj]);
clear osciDeviceObj sigGenDeviceObj;
clear osciInterfaceObj sigGenInterfaceObj;

%% Helping functions
% TODO: Create a structure to hold all the current settings so it can be used in
% main
% Function to configure the signal generator with the starting settings
function configSignGen(deviceObj, interfaceObj, startFreq, startDuty, highLevel)
%better readability
CH1 = 1;
CH2 = 2;
% Execute device object function(s).
devicereset(deviceObj);
sigGenGroupObj = get(deviceObj, 'System');
% invoke(groupObj, 'beep');

% Query property value(s).
sigGenInstrumentModel = get(deviceObj, 'InstrumentModel');

% Configure property value(s).
set(deviceObj.Display(CH1), 'Contrast', 0.9);

% Query property value(s).
state = get(deviceObj.Output(CH1), 'State');

% Configure property value(s).
set(deviceObj.Output(CH1), 'State', 'Off');

%First need to find how to change the waveform to pulse
fprintf(interfaceObj, 'SOUR1:FUNCTION PULSE');

% Configure property value(s).
set(deviceObj.Frequency(CH1), 'Frequency', changeFreqMHz(startFreq));

% Query property value(s).
dutyCycle = get(deviceObj.Pulse(CH1), 'DutyCycle');

% Configure property value(s).
if dutyCycle ~= startDuty
    set(deviceObj.Pulse(CH1), 'DutyCycle', startDuty);
end
%Check if such funcitons exist with the device object
fprintf(interfaceObj, 'PULS:TRAN:LEAD 18e-9');
fprintf(interfaceObj, 'PULS:TRAN:TRA 18e-9');
% Make flexible
if highLevel == 5
    fprintf(interfaceObj, 'SOUR1:VOLT:LEV:IMM:HIGH 5');
else
    fprintf(interfaceObj, 'SOUR1:VOLT:LEV:IMM:HIGH 3.3');
end
fprintf(interfaceObj, 'SOUR1:VOLT:LEV:IMM:LOW 0');
end

% A helper function to create frequency values in MHz
function [freqStr] =  changeFreqMHz(newFreq)
    freqStr = strcat(num2str(newFreq),'e6');
end
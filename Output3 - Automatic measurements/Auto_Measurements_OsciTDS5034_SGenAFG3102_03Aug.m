%% Instrument Connection
clc
clear all
close all

%% In case I can't find a good way of setting the resolution here, 
% include the oscilloscope object script first, run, delete and continue
% executing the current script
%%
%Variables to be used
CH1 = 1;
CH2 = 2;
VCC = '5,5';
VIO = 3.3; % Use only 3.3 or 5
VIOstr = '3,3';
% freqMHz = 0;
dutyCycle = 0;
freqValues = [1:20]; %in MHz
dutyValues = [20.0 50.0 80.0]; %values in the range 0:100

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

%% Get input parameters and construct filename prefix

configSignGen(sigGenDeviceObj, sigGenInterfaceObj, freqValues(1), dutyValues(1), VIO);
set(sigGenDeviceObj.Output(CH1), 'State', 'On');
fprintf(osciInterfaceObj, 'HOR:RECO 50000');
fprintf(osciInterfaceObj, 'HOR:MAI:SCAL 80.000e-9');

for dutyLoopIdx = 1:length(dutyValues)
%% Find how to change the Horizontal position and the resolution between each Duty measurement
%%    
    if dutyLoopIdx > 1
        if dutyValues(dutyLoopIdx) < 100
            set(sigGenDeviceObj.Pulse(CH1), 'DutyCycle', dutyValues(dutyLoopIdx));
        else
            printf('Duty cycle value not allowed');
        end
        %Needed as for higher freq. the values might have been changed
        set(sigGenDeviceObj.Frequency(CH1), 'Frequency', changeFreqMHz(1));
        fprintf(sigGenInterfaceObj, 'PULS:TRAN:LEAD 18e-9');
        fprintf(sigGenInterfaceObj, 'PULS:TRAN:TRA 18e-9');
        
        fprintf(osciInterfaceObj, 'HOR:RECO 50000');
        fprintf(osciInterfaceObj, 'HOR:MAI:SCAL 80.000e-9');
    end

    for freqLoopIdx = 1:length(freqValues)
        set(sigGenDeviceObj.Frequency(CH1), 'Frequency', changeFreqMHz(freqValues(freqLoopIdx)));
        pause(1);
        Filename_prefix = sprintf('StoredData/%sVIO_%sVCC_%dDUTY_%dMHz_',VIOstr, VCC, dutyValues(dutyLoopIdx), freqValues(freqLoopIdx));
        %% Those are not needed to be executed more than once
        set(osciDeviceObj.Acquisition(CH1), 'State', 'run');
        set(osciDeviceObj.Acquisition(CH1), 'Control', 'run-stop');
        set(osciDeviceObj.Acquisition(CH1), 'Mode', 'average');
        set(osciDeviceObj.Acquisition(CH1), 'NumberOfAverages', 10);
        set(osciDeviceObj.Acquisition(CH1), 'FastAcquisition', 'off');
        timeBase = get(osciDeviceObj.Acquisition(1), 'Timebase');
        
        %Change the SCALE
        % if (timeBase ~= 8.0E-8)
        %     set(deviceObj.Acquisition(1), 'Timebase', 8.0E-8);
        % end
        
        set(osciDeviceObj.Display(CH1), 'Style', 'vectors');
        set(osciDeviceObj.Display(CH1), 'Format', 'yt');
        
        
        
        %% Get data from the osci
        osciGroupObj = get(osciDeviceObj, 'Waveform');
        now = datestr(now,'mm-dd-yyyy_HH-MM-SS');
        %%
        [Y_CH1,X_CH1,YUNIT_CH1,XUNIT_CH1] = invoke(osciGroupObj, 'readwaveform', 'CH1');
        [Y_CH2,X_CH2,YUNIT_CH2,XUNIT_CH2] = invoke(osciGroupObj, 'readwaveform', 'CH2');
        [Y_CH3,X_CH3,YUNIT_CH3,XUNIT_CH3] = invoke(osciGroupObj, 'readwaveform', 'CH3');
        [Y_CH4,X_CH4,YUNIT_CH4,XUNIT_CH4] = invoke(osciGroupObj, 'readwaveform', 'CH4');
        %%
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
        
        clear groupObj now;
        close all
        %     clear freqMHz Filename CANH CANL VOUT TXD;
    end
    
end

%% Disconnect device object from hardware.
disconnect(osciDeviceObj);
disconnect(sigGenDeviceObj);

%% Clean and delete all objects
% Clean up all objects.
delete([osciDeviceObj osciInterfaceObj]);
delete([sigGenDeviceObj sigGenInterfaceObj]);
% clear groupObj;
clear osciDeviceObj sigGenDeviceObj;
clear osciInterfaceObj sigGenInterfaceObj;

%% Helping functions
% TODO: Create a structure to hold all the current settings so it can be used in
% main
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


function [freqStr] =  changeFreqMHz(newFreq)
    freqStr = strcat(num2str(newFreq),'e6');
end
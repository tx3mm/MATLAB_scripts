% 16 Sep - Added automatic folder creation based on the file name

%% Instrument Connection
clc
clear all
close all
% Create a VISA-TCPIP object.
interfaceObj = instrfind('Type', 'visa-tcpip', 'RsrcName', 'TCPIP0::169.254.178.98::inst0::INSTR', 'Tag', '');

% Create the VISA-TCPIP object if it does not exist
% otherwise use the object that was found.
if isempty(interfaceObj)
    interfaceObj = visa('TEK', 'TCPIP0::169.254.178.98::inst0::INSTR');
else
    fclose(interfaceObj);
    interfaceObj = interfaceObj(1);
end

% Create a device object. 
deviceObj = icdevice('tektronix_tds5034.mdd', interfaceObj);
%% 
props = set(deviceObj);
values = get(deviceObj);
%% 
% Connect device object to hardware.
connect(deviceObj);
%% Get input parameters and construct filename prefix
%Enter those values manually before every type of measurement as they don't
%change
% VCC = '5,0';
% VIO = '5,0';
dutyCycle = 50;
freqMHz = 0;

scaleSteps = [80 40 20 10];

fprintf(interfaceObj, 'HOR:RECO 50000');
fprintf(interfaceObj, 'HOR:MAI:SCAL 80.000e-9'); % comment depending on
% the measurement
set(deviceObj.Acquisition(1), 'State', 'run');
set(deviceObj.Acquisition(1), 'Control', 'run-stop');
set(deviceObj.Acquisition(1), 'Mode', 'average');
set(deviceObj.Acquisition(1), 'NumberOfAverages', 10);
set(deviceObj.Acquisition(1), 'FastAcquisition', 'off');
set(deviceObj.Display(1), 'Style', 'vectors');
set(deviceObj.Display(1), 'Format', 'yt');    

fprintf(interfaceObj, 'DATA:WIDTH 2');
fprintf(interfaceObj, 'DATA:ENCdg RIBinary');
fprintf(interfaceObj, 'WFMPre:BYT_Or LSB');
fprintf(interfaceObj, 'DATA:START 1');
fprintf(interfaceObj, 'DATA:STOP 50000');
fprintf(interfaceObj, 'HOR:RECO 50000');

numberMeasurements = input('Enter number of planned measurements: ');
loopIdx = 0;
runTime = zeros(1, numberMeasurements);

while loopIdx < numberMeasurements
    [freqMHz, deviceModel, VCC, VIO] = inputParameters(); %, VCC, VIO, dutyCycle
    tic
    Filename_prefix = sprintf('%s_%sVIO_%sVCC_%dDUTY_%dMHz_',deviceModel, VIO, VCC, dutyCycle, freqMHz);
    %% Create corresponding folder - NOT able to save the files there at the moment
    folder_name = ['StoredData/' Filename_prefix 'directory'];
    if not(exist(folder_name,'dir'))
        mkdir(folder_name)
    else
        fprintf('Folder "%s" already exists!\n', folder_name);
    end
    
    baseName = [folder_name '/' Filename_prefix];
    
    %%
    timeBase = get(deviceObj.Acquisition(1), 'Timebase');
    
    %Change the SCALE; Specific for Output1 measurements
    if (freqMHz == 1) &&(timeBase ~= 8.0E-8)
        set(deviceObj.Acquisition(1), 'Timebase', 80.0E-9);   
        fprintf(interfaceObj, 'HOR:RECO 50000');
    elseif (freqMHz == 2) && (timeBase ~= 4.0E-8)
%         fprintf(interfaceObj, 'HOR:MAI:SCAL %d.000e-9', scaleSteps(2));
        set(deviceObj.Acquisition(1), 'Timebase', 40.0E-9);
    elseif (freqMHz == 10) && (timeBase ~= 2.0E-8)
%         fprintf(interfaceObj, 'HOR:MAI:SCAL %d.000e-9', scaleSteps(3));
        set(deviceObj.Acquisition(1), 'Timebase', 20.0E-9);
    end
    
    %% Get data from the osci
    groupObj = get(deviceObj, 'Waveform');
    now = datestr(now,'mm-dd-yyyy_HH-MM-SS'); %get time stamp
    %%
    [Y_CH1,X_CH1,YUNIT_CH1,XUNIT_CH1] = invoke(groupObj, 'readwaveform', 'CH1');
    [Y_CH2,X_CH2,YUNIT_CH2,XUNIT_CH2] = invoke(groupObj, 'readwaveform', 'CH2');
    [Y_CH3,X_CH3,YUNIT_CH3,XUNIT_CH3] = invoke(groupObj, 'readwaveform', 'CH3');
    [Y_CH4,X_CH4,YUNIT_CH4,XUNIT_CH4] = invoke(groupObj, 'readwaveform', 'CH4');
    %%
    plot(X_CH1,Y_CH1, 'yellow'),grid on
    xlabel(XUNIT_CH1)
    ylabel(YUNIT_CH1)
    hold on
    set(gcf, 'Units', 'Normalized', 'OuterPosition', [0 0 1 1]); %make full screen
    plot(X_CH2,Y_CH2, 'blue')
    plot(X_CH3,Y_CH3, 'magenta') % remove the scaling *2- (Y_CH3(1)*2-Y_CH4(1)))
    plot(X_CH4,Y_CH4, 'green')
    Delay_CH3_CH4 = finddelay(Y_CH3,Y_CH4);
    title([deviceModel ' ' VCC 'VCC ' VIO 'VIO'], 'Interpreter', 'none');
%     legend('CANH', 'DIFF', 'RXD', 'TXD');
    legend('CANH', 'CANL', 'DIFF', 'TXD');
    savefig(gcf,[baseName 'Figure.fig'])
    print('-f1',[baseName 'Plot'],'-dpng', '-r300'); %300dpi
    %% Store the data to CSV    
    CANH = [X_CH1;Y_CH1];
    writematrix(CANH', [baseName 'CANH.csv'], 'Delimiter', ';');
    
    CANL = [X_CH2;Y_CH2];
    writematrix(CANL', [baseName 'CANL.csv'], 'Delimiter', ';')
    
%     RXD = [X_CH3;Y_CH3];
%     writematrix(RXD', [baseName 'RXD.csv'], 'Delimiter', ';')

    DIFF = [X_CH3;Y_CH3];
    writematrix(DIFF', [baseName 'DIFF.csv'], 'Delimiter', ';')
    
    TXD = [X_CH4;Y_CH4];
    writematrix(TXD', [baseName 'TXD.csv'], 'Delimiter', ';')
    
    clear groupObj now;
    if numberMeasurements > 1
        close all
    end
%     clear freqMHz Filename CANH CANL VOUT TXD;

    loopIdx = loopIdx + 1;
    runTime(loopIdx) = toc;
end

%% Average measurement time
averageTime = 0;
for i = 1 : numberMeasurements
   averageTime = averageTime + runTime(i);
end
averageTime = averageTime / numberMeasurements;
fprintf('Average run-time per measurement: %fs\n', averageTime);
fprintf('Max run-time for a measurement: %fs\n', max(runTime));
%% 

% Disconnect device object from hardware.
disconnect(deviceObj);
%% 

% The following code has been automatically generated to ensure that any
% object manipulated in TMTOOL has been properly disposed when executed
% as part of a function or script.

% Clean up all objects.
delete([deviceObj interfaceObj]);
% clear groupObj;
clear deviceObj;
clear interfaceObj;
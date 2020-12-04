% Only use frequencies up to 4MHz
% There are 6 different measurements to be made - DONE
% Use the transform2mat.m script from Axel for the data saved from the Osci
% NEW: Automate measurements on all .mat files in the directory


clc
close all
clear all

allMatFiles = dir('*.mat');
numberDifferentWaveforms = input('Enter number of different waveforms: ');

for i = 1 : numberDifferentWaveforms: length(allMatFiles)
    filename = '';
    newStr = split(allMatFiles(i).name, '_');
    for j = 1 : (length(newStr)-1)
        if j==1
            filename = [filename newStr{j}];
        else
            filename = [filename '_' newStr{j}];
        end
    end
    
    %% Load the signals and save into corrseponding variables
    RXD_data = load([filename '_RXD.mat']);
    TXD_data = load([filename '_TXD.mat']);
    newstr = split([filename '_TXD.mat'],'_');
    % amplValueUsed = split(newstr(1), 'VIO');
    amplValueUsed = split(newstr(2), 'VIO');
    % fileNameVccValue = split(newstr(2), 'VCC');
    fileNameVccValue = split(newstr(3), 'VCC');
    
    fileNameAmplValue = amplValueUsed;
    if contains(fileNameAmplValue{1}, '.')
        fileNameAmplValue{1} = strrep(fileNameAmplValue{1}, '.', ',');
    elseif contains(fileNameAmplValue{1}, ',')
        amplValueUsed = strrep(amplValueUsed(1), ',', '.');
        %         amplValueUsed = split(fileNameAmplValue{1},',');
    end
    
    if contains(fileNameVccValue{1}, '.')
        fileNameVccValue{1} = strrep(fileNameVccValue{1}, '.', ',');
    end
    
    amplValueUsed = str2double(amplValueUsed(1));
    
    if (contains(allMatFiles(i).name, 'DIFF') || contains(allMatFiles(i+1).name, 'DIFF') ||...
            contains(allMatFiles(i+2).name, 'DIFF') || contains(allMatFiles(i+3).name, 'DIFF') )
        
        DIFF_data = load([filename '_DIFF.mat']');
    else
        CANL_data = load([filename '_CANL.mat']);
        CANH_data = load([filename '_CANH.mat']);
        
        DIFF_data.Time = CANH_data.Time;
        DIFF_data.Amplitude = (CANH_data.Amplitude - CANL_data.Amplitude);
    end
    
    %% Plot the base signals
    f1 = figure(1);
    hold on; grid on;
    set(gcf, 'Units', 'Normalized', 'OuterPosition', [0 0 1 1]); %make full screen
    plot(TXD_data.Time, TXD_data.Amplitude,'-b');
    plot(TXD_data.Time, DIFF_data.Amplitude,'-g');
    plot(TXD_data.Time, RXD_data.Amplitude,'-m');
    xlabel('Time');
    ylabel('Volts');
    % title([deviceModel ' ' newstr{1} ' ' newstr{2}], 'Interpreter', 'none')
    title([filename '_delays'], 'Interpreter', 'none')
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
    
    startTimeID = find(TXD_data.Time >= 0); % get indexes after time = 0
   
    %% Find 30% of TXD falling edge and 0.9V of the differential signal
    %   and calculate the delay between them (TXD_busdom)
    id = ( TXD_data.Amplitude(startTimeID(1):(end)) <= (0.3*amplValueUsed) );
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
    % fileName = [deviceModel '_' fileNameAmplValue{1} 'VIO_' fileNameVccValue{1} 'VCC'];
    tableMeasurements = {'TXD_busdom' 'TXD_busrec' 'BUSDOM_RXDL' 'BUSREC_RXDH' 'TXDL_RXDL_delay' 'TXDH_RXDH_delay';...
        TXD_busdom*1e9 TXD_busrec*1e9 BUSDOM_RXDL*1e9 BUSREC_RXDH*1e9 TXDL_RXDL_delay*1e9 TXDH_RXDH_delay*1e9};
    xlsFileName = [filename 'delays_RESULTS' '.xlsx'];
    writecell (tableMeasurements, xlsFileName, 'Sheet' , 'Output1(ns)' , 'Range' , 'B1' );
    
    %% Save the plots to PNG and PDF files with an appropriate name
    filename = [filename '_delays_Plot'];
    print('-f1',filename,'-dpdf', '-bestfit');
    print('-f1',filename,'-dpng', '-r300'); %300dpi
    
    close all
    clear RXD_data TXD_data DIFF_data
    
end
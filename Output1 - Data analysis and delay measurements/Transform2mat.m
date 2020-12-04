files = dir('*.csv');
for i=1:length(files)
    A=importdata(files(i).name);
    Time=A.data(:,1);
    if contains(files(i).name,'DIFF')
        Amplitude=-A.data(:,2);
    else
        Amplitude=A.data(:,2);
    end
    save([files(i).name(1:end-4) '.mat'],'Time','Amplitude')
end
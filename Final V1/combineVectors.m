filesCSV = dir('*.csv');

for i = 1 : 4: length(filesCSV)
    input1 = importdata(filesCSV(i).name, ';');
    header_input1=split(filesCSV(i).name(1:end-4),'_');
    Header{1,1}='Time';  
    Header{1,2}=header_input1{end};
    Data(:,1)=input1(:,1);
    Data(:,2)=input1(:,2);
    
    input2 = importdata(filesCSV(i+1).name, ';');
    header_input2=split(filesCSV(i+1).name(1:end-4),'_');
    Header{1,3}=header_input2{end};
    Data(:,3)=input2(:,2);
    
    input3 = importdata(filesCSV(i+2).name, ';');
    header_input3=split(filesCSV(i+2).name(1:end-4),'_');
    Header{1,4}=header_input3{end};   
    Data(:,4)=input3(:,2);
    
    input4 = importdata(filesCSV(i+3).name, ';');
    header_input4=split(filesCSV(i+3).name(1:end-4),'_');
    Header{1,5}=header_input4{end}; 
    Data(:,5)=input4(:,2);
    
    savename=header_input4;
    savename(end)=[];
    str='';
    for j = 1:length(savename)
        str=[str '_' savename{j}];
    end
    newsavename=[str(2:end) '_allSignals.csv'];
    
    %% Save the Header and Data to the same file
    celltest=Header;
    celltest(2:2+length(Data)-1,:)=num2cell(Data);
    writecell(celltest, newsavename, 'Delimiter', ';')
end

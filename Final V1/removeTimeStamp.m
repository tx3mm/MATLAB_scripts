clc
clear all

filesCSV = dir('*.csv');
filesPNG = dir('*.png');
filesPDF = dir('*.pdf');

% for i=1:length(filesCSV)
%    newstr=split(filesCSV(i).name,'_');
%    newName = [newstr{1} '_' newstr{2} '_' newstr{3} '_' newstr{4} '_' newstr{7}];
%    movefile(filesCSV(i).name, newName);
% end

for i=1:length(filesPDF)
   newstr=split(filesPDF(i).name,'_')
   newName = [newstr{1} '_' newstr{2} '_' newstr{3} '_' newstr{4} '_' newstr{7}]
   movefile(filesPDF(i).name, newName)  
end

% for i=1:length(filesPNG)
%    newstr=split(filesPNG(i).name,'_');
%    newName = [newstr{1} '_' newstr{2} '_' newstr{3} '_' newstr{4} '_' newstr{7}];
%    movefile(filesPNG(i).name, newName)  ;
% end
function compFC(path,subName)
%Runtime on a MacBook Pro 2011 Core i3: ~5 Sec
%Input:     Full path to the folder holding the aparc_stats.txt %
%           subID_ROIts.dat
%Output:    subName_fMRI_new.mat   
%
% =============================================================================
% Authors: Michael Schirner, Simon Rothmeier, Petra Ritter
% BrainModes Research Group (head: P. Ritter)
% Charité University Medicine Berlin & Max Planck Institute Leipzig, Germany
% Correspondence: petra.ritter@charite.de
%
% When using this code please cite as follows:
% Schirner M, Rothmeier S, Jirsa V, McIntosh AR, Ritter P (in prep)
% Constructing subject-specific Virtual Brains from multimodal neuroimaging
%
% This software is distributed under the terms of the GNU General Public License
% as published by the Free Software Foundation. Further details on the GPL
% license can be found at http://www.gnu.org/copyleft/gpl.html.
% =============================================================================


% tmp = load(fileName);
% 
% %To avoid error due to arbitrary ordering of the variables inside the
% %struct we first transform it to a cell and then check for the dimensions
% tmp = struct2cell(tmp);
% if (size(tmp{2},1) == 661)
%     fMRI = tmp{2};
%     ROI_table = tmp{1};
% else
%     fMRI = tmp{1};
%     ROI_table = tmp{2};
% end
% clear tmp

%Read the subID_ROIts.dat File
datFile = dir([path '/*_ROIts.dat']);
datFile = datFile.name;
fMRI = dlmread([path '/' datFile]);

%Read the ROI-Table
statFile = dir([path '/aparc*stats_cleared*']);
statFile = statFile(1).name;
%ROI_ID_table = importfile([path '/' statFile]);
ROI_ID_table = dlmread([path '/' statFile]);

%Clear the ROI-Table and leave only Desikan-Entries
%start1=size(ROI_ID_table,1)-68;
%stop1=start1+34-1;
%start2=stop1+2;
%stop2=size(ROI_ID_table,1);
%fMRI = fMRI(:,[start1:stop1 start2:stop2]);

%Compute FC
FC_cc=corr(fMRI);
FC_mi=FastPairMI(zscore(fMRI)',0.3);

%Fix for possible NaN values
FC_cc(isnan(FC_cc)) = 0;

v = genvarname([subName '_ROIts']);
eval([v '= fMRI;']);

%save([path '/' subName '_fMRI_new.mat'],[subName '_ROIts'],'FC_cc','FC_mi','ROI_ID_table');
save([path '/' subName '_fMRI_new.mat'],'-mat7-binary',[subName '_ROIts'],'FC_cc','FC_mi','ROI_ID_table');

end

function MIs  = FastPairMI(data,h)
% Source: http://pengqiu.gatech.edu/software/FastPairMI/FastPairMI.m
% data : the input data, rows correspond to genes
%        columns correspond to arrays (samples)  
% h    : the std of the Gaussian kernel for density estimation 



MIs = zeros(size(data,1));
h_square = h^2;
L = size(data,2);
for i=1:L
    tmp = data - repmat(data(:,i),1,L);
    tmp = exp(-(tmp.^2)/(2*h_square));
    tmp1 = sum(tmp,2);

    tmp2 = tmp*tmp';
    for j=1:size(tmp2,1)
        tmp2(j,:) = tmp2(j,:)./tmp1(j);
        tmp2(:,j) = tmp2(:,j)./tmp1(j);
    end
    MIs = MIs + log(tmp2);
    clear tmp2

% %   The following commented line does the same job as lines 16~22
%     MIs = MIs + log((tmp*tmp')./(tmp1*tmp1'));
end
MIs = MIs/L + log(L);

end

% function aparcstats = importfile(filename, startRow, endRow)
% %IMPORTFILE Import numeric data from a text file as a matrix.
% %   APARCSTATS = IMPORTFILE(FILENAME) Reads data from text file FILENAME
% %   for the default selection.
% %
% %   APARCSTATS = IMPORTFILE(FILENAME, STARTROW, ENDROW) Reads data from
% %   rows STARTROW through ENDROW of text file FILENAME.
% %
% % Example:
% %   aparcstats = importfile('aparc_stats.txt', 49, 160);
% %
% %    See also TEXTSCAN.
% 
% % Auto-generated by MATLAB on 2014/03/23 17:41:03
% 
% %% Initialize variables.
% delimiter = ' ';
% if nargin<=2
%     startRow = 49;
%     endRow = inf;
% end
% 
% %% Read columns of data as strings:
% % For more information, see the TEXTSCAN documentation.
% formatSpec = '%s%s%s%s%s%s%s%s%s%s%[^\n\r]';
% 
% %% Open the text file.
% fileID = fopen(filename,'r');
% 
% %% Read columns of data according to format string.
% % This call is based on the structure of the file used to generate this
% % code. If an error occurs for a different file, try regenerating the code
% % from the Import Tool.
% dataArray = textscan(fileID, formatSpec, endRow(1)-startRow(1)+1, 'Delimiter', delimiter, 'MultipleDelimsAsOne', true, 'HeaderLines', startRow(1)-1, 'ReturnOnError', false);
% for block=2:length(startRow)
%     frewind(fileID);
%     dataArrayBlock = textscan(fileID, formatSpec, endRow(block)-startRow(block)+1, 'Delimiter', delimiter, 'MultipleDelimsAsOne', true, 'HeaderLines', startRow(block)-1, 'ReturnOnError', false);
%     for col=1:length(dataArray)
%         dataArray{col} = [dataArray{col};dataArrayBlock{col}];
%     end
% end
% 
% %% Close the text file.
% fclose(fileID);
% 
% %% Convert the contents of columns containing numeric strings to numbers.
% % Replace non-numeric strings with NaN.
% raw = repmat({''},length(dataArray{1}),length(dataArray)-1);
% for col=1:length(dataArray)-1
%     raw(1:length(dataArray{col}),col) = dataArray{col};
% end
% numericData = NaN(size(dataArray{1},1),size(dataArray,2));
% 
% for col=[1,2,3,4,5,6,7,8,9,10]
%     % Converts strings in the input cell array to numbers. Replaced non-numeric
%     % strings with NaN.
%     rawData = dataArray{col};
%     for row=1:size(rawData, 1);
%         % Create a regular expression to detect and remove non-numeric prefixes and
%         % suffixes.
%         regexstr = '(?<prefix>.*?)(?<numbers>([-]*(\d+[\,]*)+[\.]{0,1}\d*[eEdD]{0,1}[-+]*\d*[i]{0,1})|([-]*(\d+[\,]*)*[\.]{1,1}\d+[eEdD]{0,1}[-+]*\d*[i]{0,1}))(?<suffix>.*)';
%         try
%             result = regexp(rawData{row}, regexstr, 'names');
%             numbers = result.numbers;
%             
%             % Detected commas in non-thousand locations.
%             invalidThousandsSeparator = false;
%             if any(numbers==',');
%                 thousandsRegExp = '^\d+?(\,\d{3})*\.{0,1}\d*$';
%                 if isempty(regexp(thousandsRegExp, ',', 'once'));
%                     numbers = NaN;
%                     invalidThousandsSeparator = true;
%                 end
%             end
%             % Convert numeric strings to numbers.
%             if ~invalidThousandsSeparator;
%                 numbers = textscan(strrep(numbers, ',', ''), '%f');
%                 numericData(row, col) = numbers{1};
%                 raw{row, col} = numbers{1};
%             end
%         catch me
%         end
%     end
% end
% 
% 
% %% Create output variable
% aparcstats = cell2mat(raw);
% 
% end
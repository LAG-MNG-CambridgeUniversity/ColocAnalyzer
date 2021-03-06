%This is the MainScript that runs program "Coloc" which measures different
%components of colocalisation coefficients, applies filters etc.
%This script is running when button "Run" in ApplicationMain is pressed
%basically thi is the main script that uses separate functions for
%filtering, computing different colocalisation parameteres etc.
%All questions can be addressed at sm2425@cam.ac.uk
%Stas Makarchuk, Molecular Neuroscience Group, 2020

function [] = MainScript(FolderWithImages, FilteringMethod, ManualThreshold, FolderFiltered, FolderResults, Pearson, PearsonNonZero, Distance, Manders, main_channel, sec_channel, BoxSideMedian, PixelSize, Spearman, SpearmanNonZero)

%% parameters
%define which channels are considered for use %1=red; 2=green; 3=blue;
%main_channel = 1; 
%sec_channel = 2;
%BoxSideMedian = 20; %in pixels
%PixelSize = 10; %in nm
w = warning ('off','all');

%choose correct separation symbol
if ismac==1
    SepSym = '/';
else
    SepSym = '\';
end

%% checks and warnings

%message in case if user didnt chose any of methods for analysis
if Pearson==0 & PearsonNonZero==0 & Distance==0 & Manders ==0 & Spearman==0 & SpearmanNonZero==0 
   opts.Interpreter = 'tex';
   opts.Default = 'Continue';
   quest = ['\fontsize{12} You did not chose any of coeffcients to be analyzed. Do you wish to continue?'];
   answer = questdlg(quest,'Message','Stop','Continue',opts);
   if strcmp(answer,'Continue')
      
   else 
      return
   end
end



%check for existence of the paths
if isempty(FolderWithImages)==1
    errordlg('Field for the folder path with images is empty!')
else
    ListOfFiles = dir(FolderWithImages);
end

if isempty(FolderResults)==1
    disp('Field for the folder path for saving results is empty! I will only perform images filtering.')
        
else
    %check for the folder existence
    if ~exist(FolderResults, 'dir')
        errordlg('Please check the path for saving results - folder does not exist!')
    end
end





 %% we search all tiff files and then open them
 AllImages = struct('Image',[], 'Name', []); nI=1;
   for i=1:size(ListOfFiles,1)
      if size(ListOfFiles(i).name,2)>4
            if ListOfFiles(i).name(end-3:end)=='.tif'
                AllImages(nI).Image = imread([FolderWithImages SepSym ListOfFiles(i).name]);
                AllImages(nI).Name = ListOfFiles(i).name(1:end-4);
                if size(AllImages(nI).Image,3)<3
                    errordlg('Image should be RGB type, where 2 channels (colors) are used for computing colocalisation!')
                end
                %message for user
                disp(['Image ' ListOfFiles(i).name(1:end-4) ' is taken into analysis'])

                %%message if one of the channels is empty
                if sum(sum(AllImages(nI).Image(:,:,main_channel)))==0
                    opts.Interpreter = 'tex';
                    opts.Default = 'Continue';
                    quest = ['\fontsize{12} Channel 1 in image ' AllImages(nI).Name  ' is empty. Do you wish to continue?'];
                    answer = questdlg(quest,'Message','Stop','Continue',opts);
                    if strcmp(answer,'Continue')
                        mkdir(path_output);
                    else 
                        return
                    end
                end

                if sum(sum(AllImages(nI).Image(:,:,sec_channel)))==0
                    opts.Interpreter = 'tex';
                    opts.Default = 'Continue';
                    quest = ['\fontsize{12} Channel 2 in image ' AllImages(nI).Name  ' is empty. Do you wish to continue?'];
                    answer = questdlg(quest,'Message','Stop','Continue',opts);
                    if strcmp(answer,'Continue')
                        mkdir(path_output);
                    else 
                        return
                    end
                end
                nI=nI+1;
            end
      end
   end
  
   NumberImages = nI-1;
   if NumberImages ==0 error('There are no tif files in a chosen directory!'); end
       
   
   
  %% Filtering of the images
  AllImagesFiltered = struct('Image',[], 'Name', []);
  if FilteringMethod(1:2) == 'Ma'
      %manual thresholding
      disp(['Applying manual thresholding with a threshold ' num2str(ManualThreshold)])
      for i=1:NumberImages
          AllImagesFiltered(i).Image = ManualFiltering(AllImages(i).Image, ManualThreshold,main_channel,sec_channel);
          AllImagesFiltered(i).Name = AllImages(i).Name;
      end
  elseif FilteringMethod(1:2) == 'Ot'
      %Otsu's thresholding
      disp('Applying Otsu thresholding')
      for i=1:NumberImages
          [AllImagesFiltered(i).Image threshold_main threshold_sec]= OtsuFiltering(AllImages(i).Image, main_channel,sec_channel);
          AllImagesFiltered(i).Name = AllImages(i).Name;
          disp(['Thresholds in ' AllImagesFiltered(i).Name ' image are: ' num2str(threshold_main) ' (main channel) and ' num2str(threshold_sec) ' (sec. channel)'])
      end
  elseif FilteringMethod(1:2) == 'Co'
      %Median thresholding
      disp('Applying Costes thresholding')
      for i=1:NumberImages
          [AllImagesFiltered(i).Image threshold_main threshold_sec]= CostesTreshold(AllImages(i).Image, main_channel,sec_channel);
          AllImagesFiltered(i).Name = AllImages(i).Name;
          disp(['Thresholds in ' AllImagesFiltered(i).Name ' image are: ' num2str(threshold_main) ' (main channel) and ' num2str(threshold_sec) ' (sec. channel)'])
      end
  elseif FilteringMethod(1:2) == 'Me' & size(FilteringMethod,2)<7
      %Median filtering + Otsu's thresholding
      disp('Applying Median filtering')
      for i=1:NumberImages
          [AllImagesFiltered(i).Image]= MedianeFiltering(AllImages(i).Image, main_channel,sec_channel, BoxSideMedian);
          AllImagesFiltered(i).Name = AllImages(i).Name;
      end
  elseif FilteringMethod(1:2) == 'Me' & size(FilteringMethod,2)>=7
      %Costes thresholding
      disp('Applying Median filtering with Otsu thresholding')
      for i=1:NumberImages
          [AllImagesFiltered(i).Image threshold_main threshold_sec]= MedianeOtsuFiltering(AllImages(i).Image, main_channel,sec_channel, BoxSideMedian);
          AllImagesFiltered(i).Name = AllImages(i).Name;
          disp(['Thresholds in ' AllImagesFiltered(i).Name ' image are: ' num2str(threshold_main) ' (main channel) and ' num2str(threshold_sec) ' (sec. channel)'])
      end
      
  elseif FilteringMethod(1:2) == 'No'
      %Costes thresholding
      disp('No filtering is applied')
      AllImagesFiltered = AllImages;
  end
   
  
  
  %% save filtered images if path is indicated
  if isempty(FolderFiltered)==0
      %check and add the separation symbol if needed
      if FolderFiltered(end) ~= SepSym
          FolderFiltered = [FolderFiltered SepSym];
      end
      %check if the folder exist and if not create one
      if ~exist(FolderFiltered, 'dir')
          mkdir(FolderFiltered)
      end
      
      %save images
      for i=1:NumberImages
          imwrite(AllImagesFiltered(i).Image, [FolderFiltered AllImagesFiltered(i).Name '_' FilteringMethod '_filtering.tif'])
      end
  end
  
  %% Check if some of filtred images have completely no signal in one of the chosed channels
  
  for i=1:size(AllImagesFiltered,2)
      %%message if one of the channels is empty
                if sum(sum(AllImagesFiltered(i).Image(:,:,main_channel)))==0
                    opts.Interpreter = 'tex';
                    opts.Default = 'Continue';
                    quest = ['\fontsize{12} Channel 1 in image ' AllImages(i).Name  ' is empty. Do you wish to continue?'];
                    answer = questdlg(quest,'Message','Stop','Continue',opts);
                    if strcmp(answer,'Continue')
                        
                    else 
                        return
                    end
                end
                
                if sum(sum(AllImagesFiltered(i).Image(:,:,sec_channel)))==0
                    opts.Interpreter = 'tex';
                    opts.Default = 'Continue';
                    quest = ['\fontsize{12} Channel 2 in image ' AllImages(i).Name  ' is empty. Do you wish to continue?'];
                    answer = questdlg(quest,'Message','Stop','Continue',opts);
                    if strcmp(answer,'Continue')
                        
                    else 
                        return
                    end
                end
      
  end
  
  
  
  
  
  %% Computing parameters from the filtered images and saving them
  if Pearson 
      TablePearson  = cell2table(cell(0,2), 'VariableNames', {'Name', 'PearsonCoef'});
      TablePearson.Name = string(zeros(0,1));  
      for i=1:NumberImages
          TablePearson.PearsonCoef(i) = PearsonAllPixels(double(AllImagesFiltered(i).Image(:,:,main_channel)),double(AllImagesFiltered(i).Image(:,:,sec_channel)));
          TablePearson.Name(i) = AllImagesFiltered(i).Name;
      end
      
      %save plot
      figure
      bar(1,mean(TablePearson.PearsonCoef), 'EdgeColor', 'k', 'FaceColor', [0.8 0.8 0.8])    
      hold on
      er = errorbar(1,mean(TablePearson.PearsonCoef),std(TablePearson.PearsonCoef),std(TablePearson.PearsonCoef));    
      er.Color = [0 0 0]; er.LineStyle = 'none';
      ylabel('Pearson coefficient')
      saveas(gcf, [FolderResults SepSym 'PearsonCoefficient.png'])
      close
      
      %save data to matlab workspace
      save([FolderResults SepSym 'AllResults.mat'], 'TablePearson')
        
      %save data to csv excel file
      writetable(TablePearson,[FolderResults SepSym 'Pearson.csv'])
  end

  if PearsonNonZero 
      TablePearsonNonZero  = cell2table(cell(0,2), 'VariableNames', {'Name', 'PearsonCoef'});
      TablePearsonNonZero.Name = string(zeros(0,1));  
      for i=1:NumberImages
          
          TablePearsonNonZero.PearsonCoef(i) = PearsonNonZeroFunc(double(AllImagesFiltered(i).Image(:,:,main_channel)), double(AllImagesFiltered(i).Image(:,:,sec_channel)));
          TablePearsonNonZero.Name(i) = AllImagesFiltered(i).Name;
      end
      
      %save plot
      figure
      bar(1,mean(TablePearsonNonZero.PearsonCoef), 'EdgeColor', 'k', 'FaceColor', [0.8 0.8 0.8])    
      hold on
      er = errorbar(1,mean(TablePearsonNonZero.PearsonCoef),std(TablePearsonNonZero.PearsonCoef),std(TablePearsonNonZero.PearsonCoef));    
      er.Color = [0 0 0]; er.LineStyle = 'none';  
      ylabel('Pearson coefficient for non-zero pixels')
      saveas(gcf, [FolderResults SepSym 'PearsonCoefficientNonZero.png'])
      close
      
      %save data to matlab workspace
      if exist([FolderResults SepSym 'AllResults.mat'])==0
          save([FolderResults SepSym 'AllResults.mat'], 'TablePearsonNonZero')
      else
          save([FolderResults SepSym 'AllResults.mat'], 'TablePearsonNonZero', '-append')
      end
      
      %save data to csv excel file
      writetable(TablePearsonNonZero,[FolderResults SepSym 'PearsonNonZero.csv'])
  end
  
  
  if Distance 
      DistanceAll=[];
      for i=1:NumberImages
          DistanceNeighbour(i).Image = DistanceFunc(AllImagesFiltered(i).Image(:,:,main_channel),AllImagesFiltered(i).Image(:,:,sec_channel)).'*PixelSize;
          DistanceNeighbour(i).Image
          DistanceAll = [DistanceAll; DistanceNeighbour(i).Image];
          DistanceNeighbour(i).Name = AllImagesFiltered(i).Name;
      end
      
      
      
      %save histogram
      figure
      histogram(DistanceAll, 'BinEdges', [0:100:2000], 'normalization', 'probability', 'FaceColor', [0.2 0.2 0.2], 'EdgeColor', 'k')
       
      xlabel('Distance [nm]')
      ylabel('Probability of occurence')
      title('Distance to closest neighbour')
      saveas(gcf, [FolderResults SepSym 'Distance.png'])
      close
      
      
      %save data to matlab workspace
      if exist([FolderResults SepSym 'AllResults.mat'])==0
          save([FolderResults SepSym 'AllResults.mat'], 'DistanceNeighbour', 'DistanceAll')
      else
          save([FolderResults SepSym 'AllResults.mat'], 'DistanceNeighbour', 'DistanceAll', '-append')
      end
      
      %save data to csv excel file
      TableDistance = table(DistanceAll, 'VariableNames', {'Distance_nm'});
      writetable(TableDistance,[FolderResults SepSym 'Distance.csv'])
  end
  
  
  if Manders  
      TableManders  = cell2table(cell(0,4), 'VariableNames', {'Name', 'MandersOverlapCoefficient', 'FractionalOverlapCoefficient_1', 'FractionalOverlapCoefficient_2'});
      TableManders.Name = string(zeros(0,1));  
      for i=1:NumberImages
          [TableManders.MandersOverlapCoefficient(i) TableManders.FractionalOverlapCoefficient_1(i) TableManders.FractionalOverlapCoefficient_2(i)] = MandersFunc(double(AllImagesFiltered(i).Image(:,:,main_channel)), double(AllImagesFiltered(i).Image(:,:,sec_channel)));          
          TableManders.Name(i) = AllImagesFiltered(i).Name;
      end
      
      %save plot
      figure
      bar(1,mean(TableManders.MandersOverlapCoefficient), 'EdgeColor', 'k', 'FaceColor', [0.8 0.8 0.8])    
      hold on
      er = errorbar(1,mean(TableManders.MandersOverlapCoefficient),std(TableManders.MandersOverlapCoefficient),std(TableManders.MandersOverlapCoefficient));    
      er.Color = [0 0 0]; er.LineStyle = 'none';  
      hold on
      bar(2,mean(TableManders.FractionalOverlapCoefficient_1), 'EdgeColor', 'k', 'FaceColor', [0.8 0.8 0.8])    
      hold on
      er = errorbar(2,mean(TableManders.FractionalOverlapCoefficient_1),std(TableManders.FractionalOverlapCoefficient_1),std(TableManders.FractionalOverlapCoefficient_1));    
      er.Color = [0 0 0]; er.LineStyle = 'none';  
      hold on
      bar(3,mean(TableManders.FractionalOverlapCoefficient_2), 'EdgeColor', 'k', 'FaceColor', [0.8 0.8 0.8])    
      hold on
      er = errorbar(3,mean(TableManders.FractionalOverlapCoefficient_2),std(TableManders.FractionalOverlapCoefficient_2),std(TableManders.FractionalOverlapCoefficient_2));    
      er.Color = [0 0 0]; er.LineStyle = 'none';  
      
      xticks([1 2 3])
      xticklabels({'MOC', 'Frac. coef. 1',  'Frac. coef. 2'})
      saveas(gcf, [FolderResults SepSym 'Manders.png'])
      close
      
      %save data to matlab workspace
      if exist([FolderResults SepSym 'AllResults.mat'])==0
          save([FolderResults SepSym 'AllResults.mat'], 'TableManders')
      else
          save([FolderResults SepSym 'AllResults.mat'], 'TableManders', '-append')
      end
      
      %save data to csv excel file
      writetable(TableManders,[FolderResults SepSym 'Manders.csv'])
  end
  
  
  
  if Spearman  
      TableSpearman  = cell2table(cell(0,2), 'VariableNames', {'Name', 'SpearmanRankCoefficient'});
      TableSpearman.Name = string(zeros(0,1));  
      for i=1:NumberImages
          
          [TableSpearman.SpearmanRankCoefficient(i)] = SpearmanFunc(double(AllImagesFiltered(i).Image(:,:,main_channel)), double(AllImagesFiltered(i).Image(:,:,sec_channel)));          
          TableSpearman.Name(i) = AllImagesFiltered(i).Name;
            
      end
      
      %save plot
      figure
      bar(1,mean(TableSpearman.SpearmanRankCoefficient), 'EdgeColor', 'k', 'FaceColor', [0.8 0.8 0.8])    
      hold on
      er = errorbar(1,mean(TableSpearman.SpearmanRankCoefficient),std(TableSpearman.SpearmanRankCoefficient),std(TableSpearman.SpearmanRankCoefficient));    
      er.Color = [0 0 0]; er.LineStyle = 'none';  
   
      
      xticks([1])
      xticklabels({'Spearman rank coefficient'})
      saveas(gcf, [FolderResults SepSym 'Spearman.png'])
      close
      
      %save data to matlab workspace
      if exist([FolderResults SepSym  'AllResults.mat'])==0
          save([FolderResults SepSym 'AllResults.mat'], 'TableSpearman')
      else
          save([FolderResults SepSym 'AllResults.mat'], 'TableSpearman', '-append')
      end
      
      %save data to csv excel file
      writetable(TableSpearman,[FolderResults SepSym 'Spearman.csv'])
  end
    
  

    if SpearmanNonZero  
      TableSpearmanNonZero  = cell2table(cell(0,4), 'VariableNames', {'Name', 'SpearmanRankCoefficient','FractionOfUsedPixels','NumberOfUsedPixels'});
      TableSpearmanNonZero.Name = string(zeros(0,1));  
      for i=1:NumberImages
          
          [TableSpearmanNonZero.SpearmanRankCoefficient(i) TableSpearmanNonZero.FractionOfUsedPixels(i) TableSpearmanNonZero.NumberOfUsedPixels(i)] = SpearmanFuncNonZero(double(AllImagesFiltered(i).Image(:,:,main_channel)), double(AllImagesFiltered(i).Image(:,:,sec_channel)));          
          TableSpearmanNonZero.Name(i) = AllImagesFiltered(i).Name;
            
      end
      
      %save plot
      figure
      bar(1,mean(TableSpearmanNonZero.SpearmanRankCoefficient), 'EdgeColor', 'k', 'FaceColor', [0.8 0.8 0.8])    
      hold on
      er = errorbar(1,mean(TableSpearmanNonZero.SpearmanRankCoefficient),std(TableSpearmanNonZero.SpearmanRankCoefficient),std(TableSpearmanNonZero.SpearmanRankCoefficient));    
      er.Color = [0 0 0]; er.LineStyle = 'none';  
   
      
      xticks([1])
      xticklabels({'Spearman rank coefficient (for "non-zero" pixels)'})
      saveas(gcf, [FolderResults SepSym 'SpearmanNonZero.png'])
      close
      
      %save data to matlab workspace
      if exist([FolderResults SepSym 'AllResults.mat'])==0
          save([FolderResults SepSym 'AllResults.mat'], 'TableSpearmanNonZero')
      else
          save([FolderResults SepSym 'AllResults.mat'], 'TableSpearmanNonZero', '-append')
      end
      
      %save data to csv excel file
      writetable(TableSpearmanNonZero,[FolderResults SepSym 'SpearmanNonZero.csv'])
  end

end


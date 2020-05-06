%This is the MainScript that runs program "Coloc" which measures different
%components of colocalisation coefficients, applies filters etc.
%This script is running when button "Run" in ApplicationMain is pressed
%basically thi is the main script that uses separate functions for
%filtering, computing different colocalisation parameteres etc.
%All questions can be addressed at sm2425@cam.ac.uk
%Stas Makarchuk, Molecular Neuroscience Group, 2020

function [] = MainScript(FolderWithImages, FilteringMethod, ManualThreshold, FolderFiltered, FolderResults, Pearson, PearsonNonZero, Distance, Manders, main_channel, sec_channel, BoxSideMedian, PixelSize, FolderShuffled, NumberTests, density_channel, BoxLengthDensity, DensityCorrections, DensityThreshold)

%% parameters
%define which channels are considered for use %1=red; 2=green; 3=blue;
%main_channel = 1; 
%sec_channel = 2;
%BoxSideMedian = 20; %in pixels
%PixelSize = 10; %in nm
w = warning ('off','all');

%% check for existence of the paths

if isempty(FolderWithImages)==1
    errordlg('Field for the folder path with images is empty!')
else
    ListOfFiles = dir(FolderWithImages);
end

if isempty(FolderResults)==1
    disp('Field for the folder path for saving results is empty! I will only perform images filtering and spots shuffling.')       
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
                AllImages(nI).Image = imread([FolderWithImages '\' ListOfFiles(i).name]);
                AllImages(nI).Name = ListOfFiles(i).name(1:end-4);
                nI=nI+1;
                %message for user
                disp(['Image ' ListOfFiles(i).name(1:end-4) ' is taken into analysis'])
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
      if FolderFiltered(end) ~= '\'
          FolderFiltered = [FolderFiltered '\'];
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
  
  
  
  
  %% defining "boundaries" of the cell and random shuffling
  %search positions of all spots in each channel separately abd define cell
  %boundaries
    disp('Im starting to define approximate cell boundaries where the spot shuffling will be happen')
  for i=1:NumberImages
      SpotPos(i).Channel1 = GetSpotPosIMG(AllImagesFiltered(i).Image(:,:,main_channel));
      SpotPos(i).Channel2 = GetSpotPosIMG(AllImagesFiltered(i).Image(:,:,sec_channel));
      SpotPos(i).ChannelDensity = GetSpotPosIMG(AllImagesFiltered(i).Image(:,:,density_channel)); %yes I know that it can be one of the channels above, but not neccesarly!
      
      for j=1:size(SpotPos(i).ChannelDensity,2) SpotsCenters(j,:) = SpotPos(i).ChannelDensity(j).Centers; end   
      %search areas with high density of spots in density_channel 
      SpotPos(i).DenseAreas = DensityMap(SpotsCenters, BoxLengthDensity, size(AllImagesFiltered(i).Image,1), DensityThreshold);
  
  end
  
for nTest = 1:NumberTests
  disp(['Test #' num2str(nTest) ' starts'])  

  AllImagesFilteredShuffled = struct('Image',[], 'Name', []);

  for i=1:NumberImages
      disp(['Shuffling spots in second channel for image ' AllImagesFiltered(i).Name]);
      %shuffle spots in second channel and save the image
      AllImagesFilteredShuffled(i).Test(nTest).Image = ShuffleSpots(SpotPos(i).DenseAreas, SpotPos(i).Channel1, SpotPos(i).Channel2, BoxLengthDensity, DensityCorrections, main_channel, sec_channel, AllImagesFiltered(i).Image);
      AllImagesFilteredShuffled(i).Test(nTest).Name = AllImagesFiltered(i).Name;
  end
  
  
    %% save filtered and shuffled images if path is indicated
    
  if isempty(FolderShuffled)==0
      %check and add the separation symbol if needed
      if FolderShuffled(end) ~= '\'
          FolderShuffled = [FolderShuffled '\'];
      end
      %check if the folder exist and if not create one
      if ~exist(FolderShuffled, 'dir')
          mkdir(FolderShuffled)
      end
      
      %save images
      for i=1:NumberImages
          imwrite(AllImagesFilteredShuffled(i).Test(nTest).Image, [FolderShuffled '\' AllImagesFilteredShuffled(i).Test(nTest).Name '_' FilteringMethod 'filtering_shuffled_testN' num2str(nTest) '.tif'])
      end
  end
  
  
  %% Computing parameters from the filtered images and saving them
  if Pearson 
      TablePearson  = cell2table(cell(0,2), 'VariableNames', {'Name', 'PearsonCoef'});
      TablePearson.Name = string(zeros(0,1));  
      for i=1:NumberImages
          TablePearson.PearsonCoef(i) = PearsonAllPixels(double(AllImagesFilteredShuffled(i).Test(nTest).Image(:,:,main_channel)),double(AllImagesFilteredShuffled(i).Test(nTest).Image(:,:,sec_channel)));
          TablePearson.Name(i) = AllImagesFilteredShuffled(i).Test(nTest).Name;
      end
      
      %save plot
      figure
      bar(1,mean(TablePearson.PearsonCoef), 'EdgeColor', 'k', 'FaceColor', [0.8 0.8 0.8])    
      hold on
      er = errorbar(1,mean(TablePearson.PearsonCoef),std(TablePearson.PearsonCoef),std(TablePearson.PearsonCoef));    
      er.Color = [0 0 0]; er.LineStyle = 'none';
      ylabel('Pearson coefficient')
      saveas(gcf, [FolderResults '\PearsonCoefficientTestNumber' num2str(nTest) '.png'])
      close
      
      %save data to matlab workspace
      
      save([FolderResults '\RandomTestNumber' num2str(nTest) '.mat'], 'TablePearson')
        
      %save data to csv excel file
      writetable(TablePearson,[FolderResults '\PearsonTestNumber' num2str(nTest) '.csv'])
  end

  if PearsonNonZero 
      TablePearsonNonZero  = cell2table(cell(0,2), 'VariableNames', {'Name', 'PearsonCoef'});
      TablePearsonNonZero.Name = string(zeros(0,1));  
      for i=1:NumberImages
          
          TablePearsonNonZero.PearsonCoef(i) = PearsonNonZeroFunc(double(AllImagesFilteredShuffled(i).Test(nTest).Image(:,:,main_channel)), double(AllImagesFilteredShuffled(i).Test(nTest).Image(:,:,sec_channel)));
          TablePearsonNonZero.Name(i) = AllImagesFilteredShuffled(i).Test(nTest).Name;
      end
      
      %save plot
      figure
      bar(1,mean(TablePearsonNonZero.PearsonCoef), 'EdgeColor', 'k', 'FaceColor', [0.8 0.8 0.8])    
      hold on
      er = errorbar(1,mean(TablePearsonNonZero.PearsonCoef),std(TablePearsonNonZero.PearsonCoef),std(TablePearsonNonZero.PearsonCoef));    
      er.Color = [0 0 0]; er.LineStyle = 'none';  
      ylabel('Pearson coefficient for non-zero pixels')
      saveas(gcf, [FolderResults '\PearsonCoefficientNonZeroTestNumber' num2str(nTest) '.png'])
      close
      
      %save data to matlab workspace
      if exist([FolderResults '\RandomTestNumber' num2str(nTest) '.mat'])==0
          save([FolderResults '\RandomTestNumber' num2str(nTest) '.mat'], 'TablePearsonNonZero')
      else
          save([FolderResults '\RandomTestNumber' num2str(nTest) '.mat'], 'TablePearsonNonZero', '-append')
      end
      
      %save data to csv excel file
      writetable(TablePearsonNonZero,[FolderResults '\PearsonNonZeroTestNumber' num2str(nTest) '.csv'])
  end
  
  
  if Distance 
      DistanceAll=[];
      for i=1:NumberImages
          DistanceNeighbour(i).Image = DistanceFunc(AllImagesFilteredShuffled(i).Test(nTest).Image(:,:,main_channel),AllImagesFilteredShuffled(i).Test(nTest).Image(:,:,sec_channel)).'*PixelSize;
          DistanceAll = [DistanceAll; DistanceNeighbour(i).Image];
          DistanceNeighbour(i).Name = AllImagesFilteredShuffled(i).Test(nTest).Name;
      end
      
      
      
      %save histogram
      figure
      histogram(DistanceAll, 'BinEdges', [0:100:2000], 'normalization', 'probability', 'FaceColor', [0.2 0.2 0.2], 'EdgeColor', 'k')
       
      xlabel('Distance [nm]')
      ylabel('Probability of occurence')
      title('Distance to closest neighbour')
      saveas(gcf, [FolderResults '\DistanceTestNumber' num2str(nTest) '.png'])
      close
      
      
      %save data to matlab workspace
      if exist([FolderResults '\RandomTestNumber' num2str(nTest) '.mat'])==0
          save([FolderResults '\RandomTestNumber' num2str(nTest) '.mat'], 'DistanceNeighbour', 'DistanceAll')
      else
          save([FolderResults '\RandomTestNumber' num2str(nTest) '.mat'], 'DistanceNeighbour', 'DistanceAll', '-append')
      end
      
      %save data to csv excel file
      TableDistance = table(DistanceAll, 'VariableNames', {'Distance_nm'});
      writetable(TableDistance,[FolderResults '\DistanceTestNumber' num2str(nTest) '.csv'])
  end
  
  
  if Manders  
      TableManders  = cell2table(cell(0,4), 'VariableNames', {'Name', 'MandersOverlapCoefficient', 'FractionalOverlapCoefficient_1', 'FractionalOverlapCoefficient_2'});
      TableManders.Name = string(zeros(0,1));  
      for i=1:NumberImages
          [TableManders.MandersOverlapCoefficient(i) TableManders.FractionalOverlapCoefficient_1(i) TableManders.FractionalOverlapCoefficient_2(i)] = MandersFunc(double(AllImagesFilteredShuffled(i).Test(nTest).Image(:,:,main_channel)), double(AllImagesFilteredShuffled(i).Test(nTest).Image(:,:,sec_channel)));          
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
      saveas(gcf, [FolderResults '\MandersTestNumber' num2str(nTest) '.png'])
      close
      
      %save data to matlab workspace
      if exist([FolderResults '\RandomTestNumber' num2str(nTest) '.mat'])==0
          save([FolderResults '\RandomTestNumber' num2str(nTest) '.mat'], 'TableManders')
      else
          save([FolderResults '\RandomTestNumber' num2str(nTest) '.mat'], 'TableManders', '-append')
      end
      
      %save data to csv excel file
      writetable(TableManders,[FolderResults '\MandersTestNumber' num2str(nTest) '.csv'])
  end
end
end


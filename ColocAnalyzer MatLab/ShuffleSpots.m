function [NewImage] = ShuffleSpots(areas, SpotPos1, SpotPos2, SegmLength, Density_Corrections, main_channel, sec_channel, image)
%This function uses information about spots in two channels and areas of
%interest to place spots from channel 1 at the same place while shuffle
%randomly spots from channel 2 but only in areas of interest. It takes

%main_channel = 1; %1-red 2-green, 3-blue
%sec_channel = 2; %1-red 2-green, 3-blue
%SegmLength = 300; %size of the segment for density map in nm
%Density_Corrections = -0.1; %could be from 1 (adding 100% new spots - twice more spots in 2 channel) to -1 (removing all spots from 2 channel). 0 means that number of new random spots is exactly the same as before shuffling


%% Program starts here 

Density_Corrections = Density_Corrections -1;


%here we remain main channel without changes, while randomly allocating spots in secondary channel. only in a selected areas
NewImage = zeros(size(image)); %that will be a new image
Mask = zeros(size(image)); %that will be a mask, where 1 is an areas of interest, 0 - not


%create a mask matrix

for i=1:size(areas,1)
            A = areas(i,1);
            B = areas(i,1)+SegmLength;
            C = areas(i,2);
            D = areas(i,2)+SegmLength;
            
            if A<1 A=1; end 
            if C<1 C=1; end
            
            Mask(A:B,C:D) = 1;
end


for i=1:size(SpotPos1,2) Centers1(i,:) = SpotPos1(i).Centers; end
for i=1:size(SpotPos2,2) Centers2(i,:) = SpotPos2(i).Centers; end

for i=1:size(areas,1)
            
            A = areas(i,1); B = areas(i,1)+SegmLength;
            C = areas(i,2); D = areas(i,2)+SegmLength;
            
            IN1 = inpolygon(Centers1(:,1), Centers1(:,2), [A B B A], [C C D D]);
            IN2 = inpolygon(Centers2(:,1), Centers2(:,2), [A B B A], [C C D D]);
            
            
            
            ClustersIn1 = SpotPos1(IN1);
            ClustersIn2 = SpotPos2(IN2);
            
            Spot_density(i,1) = size(ClustersIn1,2)/(SegmLength*SegmLength);
            Spot_density(i,2) =  size(ClustersIn2,2)/(SegmLength*SegmLength);
            %firstly we "place" all clusters from channel 1 at the same
            %places
            for j=1:size(ClustersIn1,2)
                for k=1:size(ClustersIn1(j).PixelPos,1)
                    xx = int16(ClustersIn1(j).PixelPos(k,1));
                    yy = int16(ClustersIn1(j).PixelPos(k,2));
                    NewImage(yy, xx, main_channel) = ClustersIn1(j).Intensities(k,1);
                end
            end


            %here we take clusters from second channel and randmly allocate
            %them following two constrains: (1) new position should be
            %still in one of the region of interests; (2) new position 
            %should not overwite any existing blob from the same channel
            %only
            
            %here we create a list with indeces of spots to use for
            %reshuffling. 
            ListOfIndeces = [];
            if Density_Corrections == 0
                ListOfIndeces = [1:size(ClustersIn2,2)].'; %use all spots from channel 2
            elseif Density_Corrections < 0
                Nspot = round((1+Density_Corrections)*size(ClustersIn2,2));
                ListOfIndeces = datasample([1:size(ClustersIn2,2)].',Nspot); %choose only some fraction of the spots in channel 2
            elseif Density_Corrections > 0
                NspotAdd = round(Density_Corrections*size(ClustersIn2,2));
                ListOfIndeces = [1:size(ClustersIn2,2)].'; %use all spots from channel 2
                ListOfIndeces = [ListOfIndeces; datasample([1:size(ClustersIn2,2)].',NspotAdd)]; %add some fraction of the spots in channel 2
                
            end
            
            for jj=1:size(ListOfIndeces,1)
                j = ListOfIndeces(jj);
                indicator = 0;
                while indicator==0
                    x_ran = round(rand*(size(NewImage,1)-1))+1;
                    y_ran = round(rand*(size(NewImage,2)-1))+1;
                    
                    %check if new position is inside one of roi
                    if Mask(x_ran,y_ran)==1
                        x_check = ClustersIn2(j).PixelPos(:,1)-min(ClustersIn2(j).PixelPos(:,1))+x_ran;
                        y_check = ClustersIn2(j).PixelPos(:,2)-min(ClustersIn2(j).PixelPos(:,2))+y_ran;
                        
                        
                        %check borders
                        if max(x_check)<size(NewImage,1) & max(y_check)<size(NewImage,2)
                            S=0;
                            for q=1:size(x_check,1)
                                xx = int16(x_check(q));
                                yy = int16(y_check(q));
                                S = S+NewImage(yy,xx,sec_channel);
                            end

                            if S==0

                                for qq=1:size(x_check,1)
                                    %q
                                    xx = int16(x_check(qq,1));
                                    yy = int16(y_check(qq,1));
                                    NewImage(yy, xx, sec_channel) = ClustersIn2(j).Intensities(qq,1);
                                end
                            indicator=1;
                            end
                        end
                    end 
                end
            end    
    
end
NewImage = uint8(NewImage);

end


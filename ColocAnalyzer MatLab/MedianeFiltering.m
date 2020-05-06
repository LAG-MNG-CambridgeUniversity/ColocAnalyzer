function [ImageFiltered] = MedianeFiltering(Image, main_channel, sec_channel, Boxsize)
%This function applies mediane filtering of two channels separately

Channel1 = double(Image(:,:,main_channel));
Channel2 = double(Image(:,:,sec_channel));

Background1 = zeros(size(Channel1));
Background2 = Background1;

for i=Boxsize/2+1:ceil(size(Channel1,1)/Boxsize)-Boxsize/2
    for j=Boxsize/2+1:ceil(size(Channel1,2)/Boxsize)-Boxsize/2
            Subarea1 = Channel1((i-1)*Boxsize+1:i*Boxsize,(j-1)*Boxsize+1:j*Boxsize);
            Background1(i,j) = median(median(Subarea1));   
            
            Subarea2 = Channel2((i-1)*Boxsize+1:i*Boxsize,(j-1)*Boxsize+1:j*Boxsize);
            Background2(i,j) = median(median(Subarea2));   
    end
end

Channel1Filtered = Channel1 - (Background1);
Channel2Filtered = Channel2 - (Background2);


ImageFiltered = zeros(size(Image));
ImageFiltered(:,:,main_channel) = Channel1Filtered;
ImageFiltered(:,:,sec_channel) = Channel2Filtered;
ImageFiltered = uint8(ImageFiltered);
end


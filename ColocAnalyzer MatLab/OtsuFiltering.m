function [ImageFiltered, threshold_main, threshold_sec] = OtsuFiltering(Image, main_channel, sec_channel)
%This function performs manual filtering with the same relative threshold
%separately for two channels

threshold_main = graythresh(Image(:,:,main_channel));
threshold_sec = graythresh(Image(:,:,sec_channel));

BWmain = im2bw(Image(:,:,main_channel),threshold_main);
BWsec = im2bw(Image(:,:,sec_channel),threshold_sec);

ImageFiltered = zeros(size(Image));
ImageFiltered(:,:,main_channel) = BWmain.*double(Image(:,:,main_channel));
ImageFiltered(:,:,sec_channel) = BWsec.*double(Image(:,:,sec_channel));

ImageFiltered = uint8(ImageFiltered);
end

 
function [ImageFiltered] = ManualFiltering(Image, threshold, main_channel, sec_channel)
%This function performs manual filtering with the same relative threshold
%separately for two channels

BWmain = im2bw(Image(:,:,main_channel),threshold);
BWsec = im2bw(Image(:,:,sec_channel),threshold);
ImageFiltered = zeros(size(Image));
ImageFiltered(:,:,main_channel) = BWmain.*double(Image(:,:,main_channel));
ImageFiltered(:,:,sec_channel) = BWsec.*double(Image(:,:,sec_channel));
ImageFiltered = uint8(ImageFiltered);
end


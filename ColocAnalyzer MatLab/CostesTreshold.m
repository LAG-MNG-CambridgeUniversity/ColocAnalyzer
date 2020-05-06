function [ImageFiltered T1 T2] = CostesTreshold(Image,main_channel, sec_channel)
%This function finds a Costes treshold by using Pearson's coefficient
%Original paperdoi: 10.1529/biophysj.103.038422

Imax = 255; %consider 8 bits images

Channel1 = double(Image(:,:,main_channel));
Channel2 = double(Image(:,:,sec_channel));


% 1)find automatic treshold
p = polyfit(Channel1,Channel2,1); %I_sec = I_main * a + b 
a = p(1);
b = p(2);


% 2) set the initial treshold value 
if a*1+b>=1 
    T2in = 1;
    T1in = (1-b)/a;
else
    T1in = 1;
    T2in = a*1+b;
end


    
% 3) scroll over treshold 
dT1 = T1in/100; dT2 = T2in/1005;
ind = 0; n=1; T1 = T1in; T2 = T2in;
while ind==0 & T1>=0 & T2>=0
    T1 = T1 - dT1;
    T2 = T2 - dT2;
    ch1 = Channel1;
    ch2 = Channel2;
    ch1(ch1<T1*Imax) = 0;
    ch2(ch2<T2*Imax) = 0;

    %using NONZERO pixels for computing PCC
    PCC(n) = PearsonNonZeroFunc(ch1, ch2);
    
    Treshold(n,:) = [T1 T2];

    if PCC(n)<0 ind=1; end
    n=n+1;
end
    

T1 = T1 + dT1;
T2 = T2 + dT2;

% 4) Applying found thresholds to image    

ImageFiltered = zeros(size(Image));

BWmain = im2bw(Image(:,:,main_channel),T1);
BWsec = im2bw(Image(:,:,sec_channel),T2);

ImageFiltered(:,:,main_channel) = BWmain.*double(Image(:,:,main_channel));
ImageFiltered(:,:,sec_channel) = BWsec.*double(Image(:,:,sec_channel));
ImageFiltered = uint8(ImageFiltered);


%only for imaging
% figure
% plot(PCC)

end


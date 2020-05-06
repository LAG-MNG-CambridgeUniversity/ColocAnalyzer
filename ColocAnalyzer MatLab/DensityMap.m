function [Areas] = DensityMap(XY, SegmLength, FoV, Trshld)
%This function create a density map based on xy positions and saves areas
%of the spot high densities
%INPUTS:    
%       XY - 2-column matrix with x and y positions
%       SegmLength - length of a square pixel that should be used for an
%       image
%       FoV - size of the image
%       Trshld - threshold to leave only 

%% parameters

%Trshld = 0.5; %treshold for filtering out low-density regions

%% Program starts here

xmin=0; xmax = FoV;
ymin=0; ymax = FoV;

[X,Y] = meshgrid(xmin:SegmLength:xmax,ymin:SegmLength:ymax);
Density =[]; 
I=1; J=1;
for i = 1:size(X,1)
    J=1;
    for j = 1:size(X,2)
        A = X(i,j); B = X(i,j)+SegmLength;
        C = Y(i,j); D = Y(i,j)+SegmLength;
        IN = inpolygon(XY(:,1), XY(:,2), [A B B A], [C C D D]);
        Density(I, J) = sum(sum(IN));
        J=J+1;
    end
    I=I+1;
end

DensityNorm = Density/(max(max(Density)));



%filtering out density matrix and leaving only those localisations that are
%inside denser regions


BinaryMatrix = im2bw(DensityNorm, Trshld);

Areas =[];


for i=1:size(BinaryMatrix,1)
    for j=1:size(BinaryMatrix,2)
        if BinaryMatrix(i,j)==1
            Areas = [Areas; X(i,j) Y(i,j)];
        end
    end
end
    

end


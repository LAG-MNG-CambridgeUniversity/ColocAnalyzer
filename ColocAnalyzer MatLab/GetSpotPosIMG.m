function [SpotPos] = GetSpotPosIMG(IMG)
%This fucntion gets positions of all clusters in  image witheir intensities
%in one channel
s=size(IMG);
BW = im2bw(IMG,0);
con = bwconncomp(BW);
so=size(con.PixelIdxList);%number of clusters
SpotPos = struct('PixelPos', [], 'Centers', [], 'Intensities', []);
n=1;
    for i=1:so(2)
        x=floor(con.PixelIdxList{i}/s(1))+1;
        y=(con.PixelIdxList{i}/s(1) - floor(con.PixelIdxList{i}/s(1)))*s(1)+1;
        SpotPos(n).PixelPos = [x y];
        SpotPos(n).Centers = [round(mean(x)) round(mean(y))];
        for k=1:size(x,1) SpotPos(n).Intensities = [SpotPos(n).Intensities; double(IMG(int16(y(k,1)),int16(x(k,1))))]; end
        n=n+1;
    end
end



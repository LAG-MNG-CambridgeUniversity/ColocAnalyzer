function [SpotPos] = GetSpotPosBW(BW)
%This fucntion gets positions of all clusters in  image
s=size(BW);
con = bwconncomp(BW);
so=size(con.PixelIdxList);%number of clusters
SpotPos = struct('PixelPos', [], 'Centers', []);
n=1;
    for i=1:so(2)
        x=floor(con.PixelIdxList{i}/s(1))+1;
        y=(con.PixelIdxList{i}/s(1) - floor(con.PixelIdxList{i}/s(1)))*s(1)+1;
        SpotPos(n).PixelPos = [x y];
        SpotPos(n).Centers = [round(mean(x)) round(mean(y))];
        n=n+1;
    end
end


function [D] = DistanceFunc(Channel1,Channel2)
%This function computes distance for each point in Channel1 to the closest
%spot in Channel 2

BWCh1_filtered = im2bw(Channel1);
BWCh2_filtered = im2bw(Channel2);

SpotPos1 = GetSpotPosBW(BWCh1_filtered); %Positions of all clusters in channel 1
SpotPos2 = GetSpotPosBW(BWCh2_filtered); %Positions of all clusters in channel 2

xy1=[]; xy2=[];
for i=1:size(SpotPos1,2) xy1=[xy1; SpotPos1(i).Centers]; end
for i=1:size(SpotPos2,2) xy2=[xy2; SpotPos2(i).Centers]; end


%compute the distance to closest spot from 2 channel
for i=1:size(SpotPos1,2)
    D(i) = min(sqrt((xy1(i,1)-xy2(:,1)).^2 + (xy1(i,2)-xy2(:,2)).^2));
end

end


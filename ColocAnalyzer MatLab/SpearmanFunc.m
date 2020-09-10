function [S, n, N] = SpearmanFunc(Channel1,Channel2)
%This function computes Spearman's coefficient using pixel intensity values
%Here we assume all pixels


Coloc1 = reshape(Channel1, [size(Channel1,1)*size(Channel1,2),1]); 
Coloc2 = reshape(Channel2, [size(Channel2,1)*size(Channel2,2),1]); 

%sortin an array in increasing order 

[IntSorted1 Index1] = sort(Coloc1, 'descend');
[IntSorted2 Index2] = sort(Coloc2, 'descend');





%construct rank array

RankUns1 = zeros(size(IntSorted1));
RankUns2 = zeros(size(IntSorted2));

RankRange1 = 1; RankRange2 = 1;

N = size(IntSorted1,1);

%as many pixels will have the same level of intensity we need to average
%the rank values for those pixels
for i=2:N
%disp([num2str(i) '/' num2str(N)])   
    if IntSorted1(i)==IntSorted1(i-1)
       RankRange1 = [RankRange1; i];
    else
       MeanRank1 = mean(RankRange1);
       RankUns1(RankRange1,1) = double(MeanRank1);
       RankRange1 = [i];
    end
    
    if IntSorted2(i)==IntSorted2(i-1)
       RankRange2 = [RankRange2; i];
    else
       MeanRank2 = mean(RankRange2);
       RankUns2(RankRange2,1) = double(MeanRank2);
       RankRange2 = [i];
    end
end


%here we fill up the "tails"

MeanRank1 = mean(RankRange1);
AllZeros1 = RankUns1==0;
RankUns1(AllZeros1) = MeanRank1;

MeanRank2 = mean(RankRange2);
AllZeros2 = RankUns2==0;
RankUns2(AllZeros2) = MeanRank2;


%now we restore the order
Rank1=[]; Rank2=[];
for i=1:N
    %disp([num2str(i) '/' num2str(N)])   
    IndNew1 = find(Index1==i);

    Rank1(i,1) = RankUns1(IndNew1);
    
    IndNew2 = find(Index2==i);
    Rank2(i,1) = RankUns2(IndNew2);
end

%Compute Spearman coefficient
if isempty(Rank1)==0 & isempty(Rank2)==0
    di = (Rank1-Rank2).^2;
    S = 1 - 6*sum(di)/(N^3-N);
    %n = N/max(NonZero1Sum,NonZero2Sum);
    n=1;
else
    S = nan;
    n = 0; 
end
end


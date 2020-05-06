function [MOC M1 M2] = Manders(Channel1,Channel2)
%This function computes Manders Coefficients

%MOC
A = sum(sum(Channel1.*Channel2));
B = sum(sum(Channel1.^2));
C = sum(sum(Channel2.^2));

MOC = A / (sqrt(B*C));


NonZero1 = Channel1>0;
NonZero2 = Channel2>0;

NonZero = NonZero1+NonZero2;
NonZeroAll = NonZero<2 == 0;

Coloc1 = Channel1(NonZeroAll);
Coloc2 = Channel2(NonZeroAll);
M1 = sum(sum(Coloc1))/sum(sum(Channel1));
M2 = sum(sum(Coloc2))/sum(sum(Channel2));
end


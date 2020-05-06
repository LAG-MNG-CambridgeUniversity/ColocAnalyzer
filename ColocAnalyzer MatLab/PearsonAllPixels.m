function [Coef] = PearsonAllPixels(Matrix1,Matrix2)
%this function computes a Pearson's correlation coefficient between two
%matrices for the points (pixels)


A = sum(sum((Matrix1-mean(Matrix1)).*(Matrix2-mean(Matrix2))));
B = sum(sum((Matrix1-mean(Matrix1)).^2));
C = sum(sum((Matrix2-mean(Matrix2)).^2));

Coef = A/sqrt(B*C);
end


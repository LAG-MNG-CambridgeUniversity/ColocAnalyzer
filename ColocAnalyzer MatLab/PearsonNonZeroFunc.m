function [Coef] = PearsonNonZero(Matrix1,Matrix2)
%this function computes a Pearson's correlation coefficient between two
%matrices for the points (pixels) which are not zero in both matrices.


%find nonzero pixels in both matrices

NonZero1 = Matrix1>0;
NonZero2 = Matrix2>0;
NonZero = NonZero1 + NonZero2;
NonZeroBoth = NonZero>1;

Pix1 = Matrix1(NonZeroBoth);
Pix2 = Matrix2(NonZeroBoth);

A = sum((Pix1-mean(Pix1)).*(Pix2-mean(Pix2)));
B = sum((Pix1-mean(Pix1)).^2);
C = sum((Pix2-mean(Pix2)).^2);

Coef = A/sqrt(B*C);
end


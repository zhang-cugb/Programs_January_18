%...  The Matmol group (2016)
     function [x] = ewwe_exact(z,t)
%...
%... this function computes an exact solution to the ewwe
%...
     global a p mu c zi
%...
%...     
     x = (((p+1)*(p+2)*c*(sech(0.5*p*sqrt(1/mu)*(z-c*t-zi))).^2)/(2*a)).^(1/p);

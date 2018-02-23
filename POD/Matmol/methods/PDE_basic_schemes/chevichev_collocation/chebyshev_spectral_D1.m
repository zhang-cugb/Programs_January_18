%...  The Matmol group (2016)
     function [D,z] = chebyshev_spectral_D1(z0,zL,n)
%...    
%... function chebishev_spectral_D1 returns the differentiation
%... matrix for computing the first derivative, x_z  , of a variable
%... x over the spatial domain z0 < x < zL from a spectral method on
%... a clustered grid.
%... This code is a slight adapatation of a code taken from
%... (Trefethen, 2000) 
%...
%... argument list
%...
%...   z0    left value of the spatial independent variable (input)
%...   zL    right value of the spatial independent variable (input)
%...   n     number of spatial grid points, including the end points
%...         (input) 
%...   D     differentiation matrix (output)
%...   z     Chebishev points (output)

%... compute the spatial grid
    L = zL-z0;
    n = n-1;                           %... zi, i = 0,...,n-1
    z = cos(pi*(n:-1:0)/n)';           %... Chebishev points on [-1, 1]

%... discretization matrix
    Z = repmat(z,1,n+1);   %... create a (nxn) square matrix by 
                           %... replicating each Chebishev point in a 
                           %... line of the matrix
    dZ = Z-Z';     %... create a matrix whose elements represent the 
                   %... distance to the diagonal elements
    c = [2; ones(n-1,1); 2].*(-1).^(0:n)';
    D = (c*(1./c)')./(dZ+(eye(n+1)));  %... compute off-diagonal entries
    D = D - diag(sum(D'));             %... adjust diagonal entries
    z = z0+(z+1)*(zL-z0)/2;            %... convert to interval [z0, zL]
    D = 2/(zL-z0)*D;

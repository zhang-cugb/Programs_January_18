%...  The Matmol group (2016)
     function [D]=two_point_upwind_uni_D1(z0,zL,n,v)
%...
%...  function two_point_upwind_uni_D1 returns the differentiation matrix 
%...  for computing the first derivative, xz, of a variable x over the spatial 
%...  domain z0 < z < zL from upwind two-point, first-order finite difference 
%...  approximations (this function replaces dss012)
%...
%...  argument list
%...
%...     z0      lower boundary value of z (input)
%...
%...     zL      upper boundary value of z (input)
%...
%...     n       number of grid points in the z domain including the
%...             boundary points (input)
%...
%...     v       fluid velocity (positive from left to right - only the sign is used) (input)
%...
%...  origin of the approximation
%...
%...  this function is an application of first-order directional
%...  differencing in the numerical method of lines.  it is intended
%...  specifically for the analysis of convective systems modelled by
%...  first-order hyperbolic partial differential equations with the
%...  simplest form
%...
%...                            x  + v*x  = 0                        (1)
%...                             t      z
%...
%...  the parameter, v, must be provided so that the direction of flow 
%...  in equation (1) can be used to select the appropriate finite difference 
%...  approximation for the first-order spatial derivative in equation (1).  
%...  the convention for the sign of v is                         
%...
%...     flow left to right                 v > 0
%...     (i.e., in the direction            
%...     of increasing x)                   
%...
%...     flow right to left                 v < 0
%...     (i.e., in the direction            
%...     of decreasing x)                   
%...
%...  compute the spatial increment, then select the finite difference
%...  approximation depending on the sign of v in equation (1).  the
%...  origin of the finite difference approximations used below is given
%...  at the end of the code.
%...
%...
%...  compute the spatial increment
        dz=(zL-z0)/(n-1);
        r1fdz=1/dz;
%...
%...     (1)  finite difference approximation for positive v     
              if v > 0
%...
%...             sparse discretization matrix      
%...
%...             interior points      
                 e = ones(n,1);
		         D = spdiags([-e e], -1:0, n, n);
%...
%...             boundary point      
                 D(1,1:2) = [-1 +1];
              end;
%...
%...     (2)  finite difference approximation for negative v
              if v < 0
%...
%...             sparse discretization matrix      
%...
%...             interior points      
                 e = ones(n,1);
		         D = spdiags([-e e], 0:1, n, n);
%...
%...             boundary point      
                 D(n,(n-1):n) = [-1 +1];
              end;                
%...      
        D=r1fdz*D;
%...
%...  the backward differences in section (1) above are based on the
%...  taylor series
%...
%...                                  2           3
%...  xi-1 = xi + xi (-dz) + xi  (-dz) + xi  (-dz) + ...
%...                z  1f      2z  2f      3z  3f
%...
%...                                          2
%...  if this series is truncated after the dz  term and the resulting
%...  equation solved for x ,  we obtain immediately
%...                       z
%...
%...  xi  = (xi - xi-1)/dz + o(dz)
%...    z
%...
%...  which is the first-order backward difference used in section 1.
%...  the derivative x1  is computed by using the point to the right of
%...                   z
%...  x1, i.e., x2, since this is the only point available if fictitioxs
%...  points to the left of x1 are to be avoided.
%...
%...  the forward differences in section (2) above are based on the
%...  taylor series
%...
%...                                  2           3
%...  xi+1 = xi + xi ( dz) + xi  ( dz) + xi  ( dz) + ...
%...                z  1f      2z  2f      3z  3f
%...
%...                                          2
%...  if this series is truncated after the dz  term and the resulting
%...  equation solved for x ,  we obtain immediately
%...                       z
%...
%...  xi  = (xi+1 - xi)/dz + o(dz)
%...    z
%...
%...  which is the first-order forward difference used in section 2.
%...  the derivative xn  is computed by using the point to the left of
%...                   z
%...  xn (xn-1), since this is the only point available if fictitious
%...  points to the right of xn are to be avoided.

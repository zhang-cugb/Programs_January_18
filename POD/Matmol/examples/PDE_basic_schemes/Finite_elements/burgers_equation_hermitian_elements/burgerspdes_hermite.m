%... The MatMol Group (2016)    
    function xt = burgerspdes_hermite(t,x)
    
%... Global variables    
    global mu
    global wquad xquad
    global n z0 zL D2 xx

%... Second spatial derivative xzz computed through the second
%... differentiation matrix
    xzz = D2*x;

%... Rename state variable x to pass it to integrands functions
    xx = x;

%... Spatial integration of the integrands in the nonlinear term of
%... Burgers equation. The nonlinear term is fx = x*xz  
    y1 = feval('integrand1_hermite',xquad')*wquad';
    y2 = feval('integrand2_hermite',xquad')*wquad';
    y3 = feval('integrand3_hermite',xquad')*wquad';
    y4 = feval('integrand4_hermite',xquad')*wquad';
    fx = y1+y2+y3+y4;

%... Boundary conditions
    gL          = burgers_exact(z0,t);
    gR          = burgers_exact(zL,t);
    gv(1,1)     = x(1)-gL;
    gv(2*n-1,1) = x(2*n-1)-gR;
    gv(2*n,1)   = 0;

%... ODEs
    xt = mu*xzz - fx - gv;

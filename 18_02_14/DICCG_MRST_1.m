% This program solves the linear system Ax = b with deflation and split
% preconditioner. The error, true residual and approximation residual are
% plotted.
%
% programmer: Gabriela Diaz
% e-mail    : diazcortesgb@gmail.com
% date      : 09-11-2017
function [result,flag,res,its,resvec,resulte] = DICCG_MRST_1(A,b,Z,tol,maxit,M1,M2,x0,varargin)
%warning on backtrace
%warning off verbose
% size(x0)
% size(b)
% size(A)
resulte = [];
opt = struct('Error', 1e-6, ...
'opts', {{false, false, false, false, false, false,false,false,false,false}}, ...
'wells', []);

 opt   = merge_options(opt, varargin{:});
 Error = opt.Error;
 opts  = opt.opts;
 W     = opt.wells;

 % Display message of options
 dopts      = opts{1}(1);
 % Compute condition number of the matrix A
 A_cn       = opts{1}(2);
 % Compute true solution
 x_true     = opts{1}(3);
 % Checks the convergence of the method, in the case of DICCG the residual
 % can increas, in that case, the solution will be the solution with
 % minimal residual
 Convergence = opts{1}(4);
 % Save the variables to plot residual
 Residual    = opts{1}(5);
 % Display the number of iterations
 Iter_m      = opts{1}(6);
 % Compute eigenvalues of matrix A  
 Amatrix_eigs = opts{1}(7);
 % Compute eigenvalues of matrix M^{-1}A
 MAmatrix_eigs = opts{1}(8);
  % Compute eigenvalues of matrix PM^{-1}A
 PMAmatrix_eigs = opts{1}(9);
   % Compute eigenvalues and condition number of matrix E
 E_cn = opts{1}(10);
 
 
[n,m] = size(A);
nw = numel(W);
if nw > 0
    na = n - nw;
else
    na = n;
end 
if (A_cn{1})
    SZ_A =size(A);
    C_A = cond(A);
    if(dopts{1})
        display(dopts)
    disp(['The size of A is: ' num2str(SZ_A)])
    disp(['The condition number of A is: ' num2str(C_A)])
    end
end
A(na+1 : n,:);
b(na+1 : n);
A(:,na+1 : n);
if (m ~= n)
    warning(['NonSquareMatrix'])
    error(message());
end
if ~isequal(size(b),[n,1])
   warning('RSHsizeMatchCoeffMatrix', m);
end
[nz,mz] = size(Z);
if ~isequal(size(b),[nz,1])
   warning(['WrongDeflationMAtrixSize', nz]);
end

if (nargin < 4) || isempty(tol)
    tol = 1e-6;
end
warned = 0;
if tol < eps
    warning('tooSmallTolerance');
    warned = 1;
    tol = eps;
elseif tol >= 1
    warning(['tooBigTolerance']);
    warned = 1;
    tol = 1-eps;
end
if (nargin < 5) || isempty(maxit)
    maxit = min(n,20);
end

if (nw > 0)
for i = 1 : nw
    i;
    n-nw+i;
    bw = b(n-nw+i,1);
    Aw = A(n-nw+i,n-nw+i);
pw(n-nw+i,1) = bw / Aw;
end

A1(1:n-nw,1:n-nw)=A(1:n-nw,1:n-nw);
M11(1:n-nw,1:n-nw)=M1(1:n-nw,1:n-nw);
M22(1:n-nw,1:n-nw)=M2(1:n-nw,1:n-nw);
b1(1:n-nw,1)=b(1:n-nw,1);
x01(1:n-nw,1)=x0(1:n-nw,1);
A = A1;
M1 = M11;
M2 = M22;
b = b1;
x0 = x01;
clear A1 Z1 M11 M22 b1 x01
n = n-nw ;
end

%% Set up deflation matrices

Z  = sparse(Z);
AZ = sparse(A*Z);
E  = Z'*AZ;
EI = inv(E);
%P = sparse(eye(n)-AZ*EI*Z');
[u]=qvec(Z,EI,b);
%u = Z*EI*Z'*b;


if(x_true{1})
    xtrue = A\b;
    normxtrue = norm(xtrue);
end




%% Tun the simulation

i = 1;
x = x0;
Mb = M1 \ b;
r = b - A * x;
r = defvec(Z,EI,A,r);
r = M1 \ r;
%p = r;
p = M2 \ r;
residu(i) = norm(r);
tol =tol*norm(Mb);
if(x_true{1} )
    [xk]=tdefvec(Z,EI,A,x);
    [Qb] = qvec(Z,EI,b);
    xk = Qb + xk;
    fout(i)   = norm(xtrue-x)/normxtrue;
    tresidu(i) = norm(b-A*xk);
end


if(residu(i) < tol) 
   disp(['DICCG only needs one iteration, initial residual is, r_1 = ||P*M^{-1}(b-A*xk)||_2' num2str(residu(i))])
   if(x_true{1})
   disp(['True residual is, r_1 = ||b-A*xk||_2: ' num2str(tresidu(i))])
   end
end
while  (i < maxit) && (residu(i) > tol)

   if(Convergence{1})
        E = Error;
        ri_1 = residu(i);
        if ( ri_1 < E )
            % If the residual increases, the approximation will be the previous
            % solution
            xacc = x;
            % If the residual increases, the approximation will be the previous
            % solution
            flagr = 1;
            rmin = residu(i-1)
                    plot(i,residu(i),'*')
                        hold on
            if (residu(i) < rmin)
                rmin = residu(i);
                flagr = 1;
            else if (abs(rmin -residu(i)) > 10*E)
                    
                    rmin = residu(i-1);
                    flagr = 0;
                end
            end
            if flagr == 0
                warning(['Maximum accuracy is : ' num2str(residu(i))])
                x =  xacc;
                break
            end
            pause
        end
    end
    
    i = i+1;
    w = A * p;
    PAp = defvec(Z,EI,A,w);
    alpha = (r'*r)/(p'*PAp);
    x = x + alpha * p;
    y = M1 \ PAp;
    r = r - alpha * y; 
    beta = (r' * r)/(residu(i-1)^2);
    %z = r;
    z = M2 \ r;
    p = z + beta * p;
    residu(i) = norm(r);
    ronmr= norm(r) 
    pause
    normbax=norm(b-A*x)/norm(b);
    if(x_true{1} )
        [xk]=tdefvec(Z,EI,A,x);
        [Qb] = qvec(Z,EI,b);
        xk = Qb + xk;
        tresidu(i) = norm(b-A*xk);
        fout(i) = norm(xtrue-xk)/normxtrue;
    end
    
end
if (Iter_m{1} )
disp(['Number of iterations is: ' num2str(i)])
end
%Compute the solution back
[xk] = tdefvec(Z,EI,A,x);
[Qb] = qvec(Z,EI,b);
xk = Qb + xk;
tr = norm(b-A*xk)/norm(b);
Mr = M1 \ (b-A*xk);
ptr = norm(Mr)/norm(Mb);

result = xk;
flag= 0;
res = residu(i);
its =i;
resvec = residu;

if (nw > 0)
    for i = 1 : nw
        result(n-nw+i,1) = pw(n-nw+i,1);
    end
end


%% Eigenvalues eigenvectors
if(Amatrix_eigs{1} )
    [VA,DA] = eigs(A,n);
    CA = cond(A,2);
end
if(MAmatrix_eigs{1} )
    IM = inv(M1);
    [VMA,DMA] = eigs(IM*A*IM',n);
    CMA = cond(IM*A*IM',2);
end
if (E_cn{1})
    C_E = cond(E);
    [VE,DE] = eigs(E);
    disp(['The condition number of E is: ' num2str(C_E)])
end
if(PMAmatrix_eigs{1})
Q = Z * EI * Z';
P = sparse(eye(n)-AZ*EI*Z');
[VPMA,DPMA] = eigs(P*IM*A*IM',n);
DPMA = diag(DPMA);
DPMA = real(DPMA(mz+1:n));
DPMA = abs(DPMA);
lmax = max(DPMA);
lmin = min(DPMA);
CPMA = lmax/lmin;
end

%% Save values for plots
if(E_cn{1})
    resulte.E   =  E;
    resulte.VE  =  VE;
    resulte.DE  =  DE;
end
if(A_cn{1})
    resulte.SZ_A =  SZ_A;
    resulte.C_A  =  C_A;
end

if(x_true{1})
    resulte.xtrue     = xtrue;
    resulte.fout      = fout;
    resulte.tresidu   = tresidu;
end
if (Residual{1})
    resulte.residu = residu;
    resulte.b      = b;
    resulte.Mb     = Mb;
    resulte.tr     = tr;
    resulte.ptr    = ptr;    
end
if(Amatrix_eigs{1} )
    resulte.VA = VA;
    resulte.DA = diag(DA);
    resulte.CA = CA;
end
if(MAmatrix_eigs{1} )
    resulte.IM  = IM;
    resulte.VMA = VMA;
    resulte.DMA = diag(DMA);
    resulte.CMA = CMA;
end
if(PMAmatrix_eigs{1} )
    resulte.VPMA = VPMA;
    resulte.DPMA = diag(DPMA);
    resulte.CPMA = CPMA;
end


end

function[Qx]=qvec(Z,EI,x)
Qx=Z'*x;
Qx=EI*Qx;
Qx=Z*Qx;
end
function[Px]=defvec(Z,EI,A,x)
[Qx]=qvec(Z,EI,x);
Px=x-A*Qx;
end
function[Px]=tdefvec(Z,EI,A,x)
Ax=A'*x;
[QAx]=qvec(Z,EI,Ax);
Px=x-QAx;
end
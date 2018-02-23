      function [fmon]=padding(z,fmon,lambda)
%...
%...  The MatMol Group (2009)
%...
%...  [fmon]=padding(z,fmon,lambda)
%...
%...  padding computes a padded monitor function in two sweeps
%...  (forward and backward) of the mesh
%...
%...  this implementation is based on SPRINT
%...  modifications by P. Saucez, W.E. Schiesser and A. Vande Wouwer (2001)  
%...
%...  input parameters:
%...
%...  fmon(nz) :   monitor function  
%...  z(nz)    :   location of the nodes
%...  lambda   :   parameter of the padding function
%...
%...  ouput parameters:
%...
%...  fmon(nz) :   padding function
%...
%...  internal parameters:
%...
%...  work(nz)   :   workspace
%...
      nz=length(z);
      work=zeros(1,nz);
%...
%...  Forward sweep:
%...
      i=1;
      ind=0;
      j=i+1;
%...      
      while j <= nz;
%...         
%...
%...       padding function work(j) fitted at point z(i) as a function of z(j)
%...
           work(j) = fmon(i)/(1+lambda*(z(j)-z(i))*fmon(i));
%...      
                  if work(j) > fmon(j)
%...
%...              padding function work(j) greater than monitor fmon(j)
%...
                     ind=ind+1;
                     fmon(j)=work(j);
                     j=j+1;
%...         
                  elseif and((work(j) < fmon(j)),(ind ~= 0))
%...         
%...              if padding function was greater than monitor function
%...              at previous points z(j) and becomes lower than monitor 
%...              function at current point z(j), then complete padding in
%...              interval z(i=j)....z(i+ind)
%...
                     i=j;
                     ind=0;
                     j=i+1;
%...
                  else   
%...
%...              padding function lower than monitor function so far 
%...              go to the next point z(i+1) and restart
%...
                      i=i+1;
                      j=i+1;
%...                  
                  end
      end;
%      
%...  Backward sweep:
%
      i=nz;
      ind=0;
      j=i-1;
%      
      while j >= 1;
%...         
%...
%...       padding function work(j) fitted at point z(i) as a function of z(j)
%...
           work(j)=fmon(i)/(1-lambda*(z(j)-z(i))*fmon(i));
%...      
                  if work(j) > fmon(j)
%...
%...              padding function work(j) greater than monitor fmon(j)
%...
                     ind=ind+1;
                     fmon(j)=work(j);
                     j=j-1;
%...         
                  elseif and((work(j) < fmon(j)),(ind ~= 0))
%...         
%...              if padding function was greater than monitor function
%...              at previous points z(j) and becomes lower than monitor 
%...              function at current point z(j), then complete padding in
%...              interval z(i=j)....z(i-ind)
%...
                     i=j;
                     ind=0;
                     j=i-1;
%...
                  else   
%...
%...              padding function lower than monitor function so far 
%...              go to the next point z(i+1) and restart
%...
                      i=i-1;
                      j=i-1;
%...                  
                  end
      end;

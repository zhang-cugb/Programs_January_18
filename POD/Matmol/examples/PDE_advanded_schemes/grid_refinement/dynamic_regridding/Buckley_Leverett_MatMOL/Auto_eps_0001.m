%...  The MatMol Group (2016)

%... 
    clear all, close all
    eps = 0.001; n = 51;
    Buckley_Leverett_MatMOL_DynamicRegridding(eps,n,1.0e-4,1.0e-4)

%...
    clear all, close all
    eps = 0.001; n = 101;
    Buckley_Leverett_MatMOL_DynamicRegridding(eps,n,1.0e-6,1.0e-6)

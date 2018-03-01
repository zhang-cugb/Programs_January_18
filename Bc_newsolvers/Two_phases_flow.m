% programmer: Gabriela Diaz
% e-mail    : g.b.diazcortes@gmail.com
% date      : 03-02-2018
%% Two-phase reservoir simulation
% This program simulates two-phase flow in heterogeneous porous media.
% The models are:
% The SPE 10 benchmark
% Academic layered problem
% Sequential schemes are used to model the problem, the Saturation is solve
% with MRST, and the solution of the pressure can be obtained with diverse
% methods ('\',agmg,ICCG,DICCG)
% We solve
% $$\nabla\cdot v = q, \qquad
%    v=\textbf{--}\frac{K}{\mu} \bigl[\nabla p+\rho g\nabla z\bigr],$$
for tol = [ 6]
for per = [6]
    for optls = [ 1:2 ]
        
        switch optls
            case 1
                use_ICCG   = true;
                use_DICCG  = false;
                use_POD    = false;
        
            case 2
                
              % clear  terr tres tresm  nterr ntres ntresm nres 
                use_ICCG   = false;
                use_DICCG  = true;
                use_POD    = false;
            case 3
                clear  terr tres tresm  nterr ntres ntresm nres 
                use_ICCG   = false;
                use_DICCG  = true;
                use_POD    = true;
        end
        if use_DICCG
        clearvars -except use_ICCG use_DICCG use_POD optls per tol terr tres tresm  nterr ntres ntresm nres 
        else
        clearvars -except use_ICCG use_DICCG use_POD optls per tol
        end
        close all
        clc
        mrstModule add incomp
        
        %% Define the model
        % To set up a model, we need: a grid, rock properties (permeability), a
        % fluid object with density and viscosity, and boundary conditions.
        Options
        
        %Initial cell
        [nxi, nyi, nzi] = deal(1, 1, 1);
        if(model_SPE)    % SPE 10
            layers = 1 : 1;
            % Create the grid
            [nx, ny, nz] = deal(60, 220, numel(layers));
        else              % Layered model
            % Create the grid
            [nx, ny, nz] = deal(25, 25, 25);
            % Contrast in permeability layers
            %per = 6;
            % Number of layers
            szl = 7;
            % Direction of the layers
            l_dir = 'y';
        end
        N = nx*ny*nz;
        [Lx, Ly, Lz] = deal(nx, ny, nz);
        if(model_SPE)
            [cartDims, physDims, G, rock] = Create_rock_f(model_SPE, nx, ny, nz, ...
                Lx, Ly, Lz, 'layers' , layers);
        else
            [cartDims, physDims, G, rock] = Create_rock_f(model_SPE, nx, ny, nz, ...
                Lx, Ly, Lz, 'per', per, ...
                'szl', szl, 'l_dir', l_dir);
            
        end
        
        perm = rock.perm(:,1);
        permD = log10(perm/darcy);
        
        % dir ='/dev/media/Sphinx/Doctorado_Delft/2018/February/02_14/';
        % Plot_mesh(permD, G, 'dnames', {{'Premeability_1'}},'o_daspect',[6 6 1], ...
        %     'o_ax', 0, 'l_cb', false, 'o_cb', 1, 'figure', 1, 'showgrid', 1, ...
        %     'EA', 0.050, 'FA', 0.375, 'titl', '','x_lab', 'xdir', 'y_lab', 'ydir', ...
        %     'inter',   [], 'o_view', [0 90],'o_daspect', [3 9 3],  'o_cb', 1,...
        %     'l_cb', [],  'o_ax',  2, 'dir', dir)
        %
        
        
        %% Fluids properties
        Fluid_props
        
        % % 1. Marker, 2. Color, 3. Markersize, 4. Linestyle, 5. LineWidth
        % % linestyles = {'none', '-',  '--', '-.', ':' };
        % % markerstyles = {'none', '.', 'o', 'd', '*' '+' 'x' 's'} ;
        % % colors = {'r',  [0 0.7 0], 'b', 'm', [0 0.7 0.7], [0.7 0 0.7], [0.5 0.5 0.7]};
        % % time = (DT:DT:t)/day;
        %optp = { [2 2 3 4 5 6 7], [1 2], 5, [1 2 3 4], [1.8] };
        % Plot_val(kr,'x',s,'savename','Relative_permeability','optp',optp,'x_lab',...
        %     'S','y_lab', 'Permeability','o_legend', [{'kr_1', 'kr_2'}], ...
        %     'revx', false, 'dir', dir, 'figure', 200, 'titl', 'Relperm','o_ax', 3)
        
        %% Temporal variables
        % Time steps
        DT    = 5*day;
        nstep = 11;
        % Solver variables
        %tol= 4;
        tol_p     = 5.0*10^(-tol);
        tol_t   = 5.0*10^(-tol);
        maxIter = 1000;
        
        %% Deflation parameters
        % Number of deflation vectors for the window
        dv    = 10;
        dp    = 5;
        if(window)
            if use_POD
                dpod   = [dv-dp+1 : dv];
            else
                dpod   = [1 : dv];
            end
        else    %Training run
            % POD vectors
            dpod   = [nstep-dv+1:nstep];
        end
        % Last experiment, to close the table
        last       = false;
        
        %% Initial values
        % Units of the pressure
        pu = {'barsa', 'stb/day', 'meter^3/day'};
        if(use_wells)
            units_P = pu{1};
            units_I = pu{1};
            % Pressure of the training run
            P = 275;
            if (training)
                % Pressure of the example
                P = 400;
            end
            % Pressure of the injector
            I = 1100;
            % Pressure of the reservoir
            P0 = 500;
        else
            %Pressure of the boundary
            P_b = 4;
            units_Pb = meter^3/day;
            % Pressure of the reservoir
            P0 = 100;
        end
        % Number of time steps with same pressure (variation in wells)
        tch =2;
        
        %% Compute sources
        if(use_wells)
            % Include wells
            wtype    = {'bhp', 'bhp', 'bhp', 'bhp', 'bhp'};
            wtarget  = [P * barsa, P * barsa, P * barsa, P * barsa, I * barsa];
            wrad     = [0.125, 0.125, 0.125, 0.125, 0.125] .* meter;
            wloc     = [  nxi,   nxi,     nx,   nx, round(nx/2);
                nyi,   ny,     nyi,   ny, round(ny/2)];
            wname    = {'P1', 'P2', 'P3', 'P4', 'I'};
            sgn      = [ 1 ,  1 ,  1 ,  1 , -1 ];
            W = [];
            for w = 1 : numel(wtype),
                W = verticalWell(W, G, rock, wloc(1,w), wloc(2,w), [], ...
                    'Type', wtype{w}, 'Val', wtarget(w), ...
                    'Radius', wrad(w), 'Name', wname{w}, ...
                    'Sign', sgn(w), 'InnerProduct', 'ip_tpf');
            end
            
            % Plot_1(permD, G, 'dnames', {{'Premeability'}},'o_daspect',[6 6 1], ...
            %     'o_ax', 1, 'l_cb', true, 'o_cb', 0, 'W',W, 'figure', 3 ,'o_save', ...
            %     dir,'o_view',[0 90])
            Changing_w
            
        else
            %Injection through boundary
            %Boundary conditions. We set boundary conditions,
            %waterflooding, right boundary / wells
            pv = poreVolume(G, rock);
            %injRate = -sum(pv)/(500*day);
            injRate = -(P_b/10)*meter^3/day;
            bc = fluxside([], G, 'xmin', -injRate, 'sat', [1, 0]);
            bc = pside(bc, G, 'xmax', 0*barsa, 'sat', [0, 1]);
            
        end
        
        
        
        %% Assemble and solve the linear system
        % To solve the flow problem, we use the standard two-point
        % flux-approximation method (TPFA), which for a Cartesian grid is the same
        % as a classical seven-point finite-difference scheme for Poisson's
        % equation. This is done in two steps: first we compute the
        % transmissibilities and then we assemble and solve the corresponding
        % discrete system.
        T   = computeTrans(G, rock);
        
        % Initialize the reservoir
        if(use_wells)
            %x         = initResSol (G, P0*barsa);
            x         = initState(G, [], P0*barsa, [0 1]);
            x.wellSol = initWellSol(W, 0);
        else
            %x         = initResSol (G, P0*barsa);
            x          = initState(G, [], P0*barsa, [0 1]);
        end
        
        
        %% Set Transport Solver
        
        linsolve_t = @(J, F) agmg(J, F, 50, tol_t, maxIter, 0);
        
        if(use_wells)
            tsolve = @(x, dt) ...
                implicitTransport(x, G, dt, rock, fluid, 'wells', W, ...
                'LinSolve', linsolve_t, 'verbose',false);
        else
            tsolve = @(x, dt) ...
                implicitTransport(x, G, dt, rock, fluid, 'bc', bc, ...
                'LinSolve', linsolve_t, 'verbose',false);
        end
        %%
        
        create_dir
        
        if(use_wells)
            Prod = struct('t'  , []                  , ...
                'vpt', zeros([0, numel(W)]), ...
                'opr', zeros([0, numel(W)]), ...
                'wpr', zeros([0, numel(W)]), ...
                'wc' , zeros([0, numel(W)]));
            
            append_wres = @(x, t, vpt, opr, wpr, wc) ...
                struct('t'  , [x.t  ; t                  ], ...
                'vpt', [x.vpt; reshape(vpt, 1, [])], ...
                'opr', [x.opr; reshape(opr, 1, [])], ...
                'wpr', [x.wpr; reshape(wpr, 1, [])], ...
                'wc' , [x.wc ; reshape(wc , 1, [])]);
            
            wres = cell([1, 4]);
        end
        if (use_DICCG) && (~window)
            filep=['Pressure'];
            filename=[dir1 filep];
            load(filename)
            [U,S]=POD_basis(Pressure,'U_norm',true);
            Z = U(:,dpod);
        end
        
        
       % nstep =10;
        for k = 1 : nstep
            
            %   simulation_2ph
            
            %% TRANSPORT SOLVER
            t0 = tic;
            for i=1
                [x,treport(k)]   = tsolve(x, DT/i);
            end
            dt_t(k) = toc(t0);
            fprintf('[%02d]: Transport: %12.5f [s]\n', k, dt_t(k));
            
            %% PRESSURE SOLVER
            p0 = x.pressure;
            if  use_ICCG
                use_ICCG
                
                if(use_wells)
                    if training
                        W = W1{k};
                        %  W(5).val = I_P(k);
                    else
                        W = W0{k};
                        %   W(5).val = I_P(k);
                    end
                    %   W(5).val = PI_1;
                    solver = ICCGSolverAD('tolerance', tol_p,'maxIterations',  maxIter,'x0',p0,'W', W);
                    linsolve_p = @(A, b) solver.solveLinearSystem(A, b);
                    psolve = @(x) incompTPFA_Def(x, G, T, fluid, 'wells', W,'LinSolve', linsolve_p);
                else
                    solver = ICCGSolverAD('tolerance', tol_p,'maxIterations',  maxIter,'x0',p0,'bc', bc);
                    linsolve_p = @(A, b) solver.solveLinearSystem(A, b);
                    psolve = @(x) incompTPFA_Def(x, G, T, fluid, 'bc',bc,'LinSolve', linsolve_p,'MatrixOutput',true);
                    
                    
                end
                t0 = tic;
                [x,preport(k)]= psolve(x);
                dt_p(k) = toc(t0);
               
            else if(use_DICCG)
                    use_DICCG
                    if (window)
                        if k < dv+1
                            
                            if(use_wells)
                                solver = ICCGSolverAD('tolerance', tol_p,'maxIterations',  maxIter,'x0',p0,'W', W);
                                linsolve_p = @(A, b) solver.solveLinearSystem(A, b);
                                psolve = @(x) incompTPFA_Def(x, G, T, fluid, 'wells', W,'LinSolve', linsolve_p);
                                use_ICCG_w = 1
                            else
                                solver = ICCGSolverAD('tolerance', tol_p,'maxIterations',  maxIter,'x0',p0,'bc', bc);
                                linsolve_p = @(A, b) solver.solveLinearSystem(A, b);
                                psolve = @(x) incompTPFA_Def(x, G, T, fluid, 'bc',bc,'LinSolve', linsolve_p,'MatrixOutput',true);
                                use_ICCG_w = 1
                            end
 
                        else
                            %                 % Number of POD vectors
                            %                 if use_POD
                            %                     dpod   = [k-dp : k-1];
                            %                 else
                            %                     dpod   = [k-dv : k-1];
                            %                 end
                            
                            %                 podi=podi+1;
                            %                 Z=POD_V(:,podi:podi+dv-1);
                            %                 if use_POD
                            %
                            %                     [U,S]=defpodf_Dt(Z,dir2,dv,t/day(),dTplot/day());
                            %                     Z=U(:,dpod);
                            %                 end
                            
                            [U,S,V]=POD_basis(POD_V(:,k-dv:k-1),'U_norm',true);
                            Z = U(:,dpod);
                            if(use_wells)
                                for i=1:numel(W)
                                    Z(N+i,1)=0;
                                end
                                
                            end
                            if(use_wells)
                                W = W0{k};
                                %  W(5).val = I_P(k);
                                solver = DICCGSolverAD('tolerance', tol_p,'maxIterations',  maxIter,'Z',Z,'x0',p0,'W', W,'dir',dir2);
                                linsolve_p = @(A, b) solver.solveLinearSystem(A, b);
                                psolve = @(x) incompTPFA_Def(x, G, T, fluid, 'wells', W,'LinSolve', linsolve_p);
                           
                            else
                                solver = DICCGSolverAD('tolerance', tol_p,'maxIterations',  maxIter,'Z',Z,'x0',p0,'bc', bc,'dir',dir2);
                                linsolve_p = @(A, b) solver.solveLinearSystem(A, b);
                                psolve = @(x) incompTPFA_Def(x, G, T, fluid, 'bc', bc,'LinSolve', linsolve_p);
                            end
                        end
                    else
                        if(use_wells)
                            W = W0{k};
                            for i=1:numel(W)
                                Z(N+i,1)=0;
                            end
                            %  W(5).val = I_P(k);
                            solver = DICCGSolverAD('tolerance', tol_p,'maxIterations',  maxIter,'Z',Z,'x0',p0,'W', W);
                            linsolve_p = @(A, b) solver.solveLinearSystem(A, b);
                            psolve = @(x) incompTPFA_Def(x, G, T, fluid, 'wells', W,'LinSolve', linsolve_p);
                        else
                            solver = DICCGSolverAD('tolerance', tol_p,'maxIterations',  maxIter,'Z',Z,'x0',p0,'bc', bc);
                            linsolve_p = @(A, b) solver.solveLinearSystem(A, b);
                            psolve = @(x) incompTPFA_Def(x, G, T, fluid, 'bc', bc,'LinSolve', linsolve_p);
                        end
                    end
                    t0 = tic;
                    [x,preport(k)]= psolve(x);
                    dt_p(k) = toc(t0);
                    fprintf('[%02d]: Pressure: %12.5f [s]\n', k, dt_p(k));
                    if(window)
                        POD_V(:,k) = x.pressure;
                    end
                    
                    
                
                    

                    %%
%                      Plot_mesh(x.pressure, G, 'dnames', {{'Pressurefield'}},'o_daspect',[6 6 1], ...
%                         'o_ax', 0, 'l_cb', false, 'o_cb', 1, 'figure', 1, 'showgrid', 1, ...
%                         'EA', 0.050, 'FA', 0.375, 'titl', '','x_lab', 'xdir', 'y_lab', 'ydir', ...
%                         'inter',   [], 'o_view', [0 90],'o_daspect', [3 3 3],  'o_cb', 1,...
%                         'l_cb', [],  'o_ax',  2, 'dir', [])
                    %%
                end
            end
            
        end
                            
                    %% Save results
                    if save_res
                        if(training)
                            for i=1:k
                                its(i,1)=preport(1,i).iter;
                            end
                            ttits_t = sum(its);
                            save([dir1  'ttits_t.mat'],'ttits_t')
                            if(use_wells)
                                save([dir1  'I_P.mat'],'I_P')
                            end
                            filetx = ['results.txt'];
                            
                            
                        else
                            filetx = ['results.txt'];
                            % Save only DICCG iterations
                            % saveits_pp_lay(dir1,filetx,use_ICCG,use_DICCG,use_POD,dpod,k,dv,preport,last,'ex', [])
                            if window
                                ex = [];
                                if use_POD
                                    ex = [num2str(numel(dpod)) ' POD vectors'];
                                end
                                if model_SPE
                                    
                                    saveits_pp_spe(dir1,filetx,use_ICCG,use_DICCG,use_POD,dpod,k,dv,preport,last,use_cp,'ex',ex)
                                else
                                    saveits_pp_lay(dir1,filetx,use_ICCG,use_DICCG,use_POD,dpod,k,dv,preport,last,use_cp,'per', per,'ex',ex)
                                end
                            else
                                if model_SPE
                                    saveits_tp_spe(dir1,filetx,use_ICCG,use_DICCG,use_POD,dpod,k,dv,preport,last,use_cp,'ex', 'Training')
                                else
                                    saveits_tp_lay(dir1,filetx,use_ICCG,use_DICCG,use_POD,dpod,k,dv,preport,last,use_cp,'ex', 'Training', 'per', per)
                                end
                                
                            end
                            
                        end
                        filews=['workspace'];
                        filename=[dir2 filews];
                        save(filename)
                        %  clearvars -except Pressure dir1 plot_sol
                        if training
                            filews=['Pressure'];
                            filename=[dir1 filews];
                            save(filename,'Pressure') 
                        end
                        if ~use_POD
                            plot_extra_res_1_log
                           
                        end
                        
                    end
                    for i=1:nstep; a(i,1)= preport(i).iter; end
sum(a)
    end
end
end

rSol =x;
plot_props


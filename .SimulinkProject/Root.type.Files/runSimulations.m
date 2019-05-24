function [result] = runSimulations(numSimulations, lenRoad, numActors)
%RUNSIMULATIONS 
%   set up parallel running of driving simulations w set parameters
    
    % get testing file
    global fid;
    % Some parallel toolbox functions, not in use yet
    %poolobj = gcp;
    %addAttachedFiles(poolobj, {});
    
    disp("Runnning " + numSimulations + " simulations.");
    
    % clears previous file, this stores the input to the different 
    % simulations that were run 
    delete('matrixFile.txt');
    
    %Load Simulation Simulink Model
    %load_system('AV_Verification_System');
    
    % Runs simulations in parallel by distributing each iteration to
    % pool of workers, uses iterator as rng seed
    
    % Parfor giving errors where variables are empty w/ size 0 0 
    %for i=0:numSimulations
        [rMatrix, aMatrix] = getRandMatrix(lenRoad, numActors, 0);

        %disp(vpa(rMatrix))
        % set_param('AV_Verification_System/Main_Program',
        % 'Scene_Description');
        % sim('AV_Verification_System');
        matrix2scen(rMatrix, aMatrix);
        
        try
            fprintf(fid, "%d\n", ((floor(i/20)*10)+70));
        catch
            disp("Error printing");
            fid = fopen("placedRoadNet.txt","a");
            fprintf(fid, "%d\n", ((floor(i/20)*10)+70));
        end
    %end

    result = true;
   
end


%%======= After study 1, N=24 ====
% 
% Script to merge EAT outputs
% Data from TUE002 (grEAT behavioral)
% 
% Merge all Data sets
%
% Written by Monja Neuser, Nov 2017, adapted by Mechteld, Jan 2019
%%======================================

% Clear workspace
close all;
clear all; 


%Define Output: Merged Data of all 10 subjects

TUE002_MergedTraining = [];

TUE002_MergedExp = [];

restforce = 34000;


%Define main directory
%effort_directory = 'C:\Users\Monja\MATLAB\Effort_task';
effort_directory = 'C:\Users\tchand\Documents\Mechteld\Effort_task_scripts14';
cd(effort_directory);


% % Load stimulation conditions (stimulation tVNS either at the correct or
% incorrect ear (1 or 0))
% stim_cond_filename = [pwd '\TUE001_conditions.mat'];
% load(stim_cond_filename, 'StimConditions_pseudo');

%IDs used [20.11.2017]: 24 of 40
%         ID    1  2  3  4  5  6  7  8  9 10 
data_present = [1  1  1  1  1  1  1  1  1  1 ];        

            
%Loops for merging output data (time based)
for runLabel = 1:2
    
    for i_subj = 1:10

        if data_present(i_subj) == 1
            
            if runLabel == 1
                
                trialnum = 8;
                
%               training_searchname = [[pwd 'Data\Training\grEATPilot_Training_TUE001_' num2str(i_subj,'%02d') '_S' num2str(i_sess)] '*'];
                training_searchname = [[pwd '\grEATdata\Training\grEATPilot_Training_TUE001_' num2str(i_subj,'%02d')] '*'];
                training_searchname = dir(training_searchname);
                training_filename = sprintf('%s\\grEATdata\\Training\\%s', pwd, training_searchname.name);
                
                load(training_filename, 'output');
                
            else
                
                trialnum = 64;
                
%               data_searchname = [[pwd '\Data\Experiment\grEATPilot_TUE001_' num2str(i_subj,'%02d') '_S' num2str(i_sess)] '*'];
                data_searchname = [[pwd '\grEATdata\Experiment\grEATPilot_TUE001_' num2str(i_subj,'%02d')] '*'];
                data_searchname = dir(data_searchname);
                data_filename = sprintf('%s\\grEATdata\\Experiment\\%s', pwd, data_searchname.name);
               
                load(data_filename, 'output');
                
            end
       
        clmnnmbr = size(output.values_per_trial_flipped, 2) + 1;
            
%       start to create new output file
        output.values_per_trial_merged = output.values_per_trial_flipped; 
        
        %approximation of the time points
        
        trial_length = 24; % seconds
        sampling_rate = 1440; % sampling rate
        smple_per_sec = trial_length/sampling_rate; % average time between two samples
        
        output.values_per_trial_merged(:,clmnnmbr) = output.values_per_trial_flipped(:,5) * smple_per_sec;
        clmn_apprx_time = clmnnmbr;
        clmnnmbr = clmnnmbr + 1;
        
        %add more values for analysis
        %amount of seconds ball was kept above the line
        if runLabel == 1
            win_inSec = max(output.values_per_trial_flipped(:,10),output.values_per_trial_flipped(:,11));
        else
            win_inSec = max(output.values_per_trial_flipped(:,11),output.values_per_trial_flipped(:,12));
        end
        
        output.values_per_trial_merged(:,clmnnmbr) = win_inSec ./ output.values_per_trial_flipped(:,9);
        clmnnmbr = clmnnmbr + 1;

        
        %relate Force to individual max_Force
        if output.values_per_trial_flipped(:,7) > restforce
            rel_Force = 0;
        else
            rel_Force = (((restforce - output.values_per_trial_flipped(:,7)) * 100)./(restforce - output.values_per_trial_flipped(:,2)));
        end
        output.values_per_trial_merged(:,clmnnmbr) = rel_Force;
        clmn_rel_Force = clmnnmbr;
        clmnnmbr = clmnnmbr + 1;

        clmnnmbr_der = clmnnmbr;
        
        %Compute area under curve trialwise for absolute frequency
               
        for i_trial = 1 : trialnum
            
            
        %Compute derivations over time for absolute frequency at timepoint
        X = output.values_per_trial_merged(output.values_per_trial_flipped(:,3)==i_trial,clmn_apprx_time);
        
        Y_abs = output.values_per_trial_flipped(output.values_per_trial_flipped(:,3)==i_trial,7);
       
            deriv1_abs = diff(Y_abs,1);        
            deriv2_abs = diff(Y_abs,2);

            integral_abs = cumtrapz(X,Y_abs);
        
        
        Y_rel = output.values_per_trial_merged(output.values_per_trial_merged(:,3)==i_trial,clmn_rel_Force);
        
            deriv1_rel = diff(Y_rel,1);        
            deriv2_rel = diff(Y_rel,2);

            integral_rel = cumtrapz(X,Y_rel);
 
        %Merge deriv1/deriv2/auc vector with output matrix    
        output.values_per_trial_merged(output.values_per_trial_merged(:,3)==i_trial,clmnnmbr) = [0;deriv1_abs];
        clmnnmbr = clmnnmbr + 1;
        output.values_per_trial_merged(output.values_per_trial_merged(:,3)==i_trial,clmnnmbr) = [0;0;deriv2_abs];
        clmnnmbr = clmnnmbr + 1;
        output.values_per_trial_merged(output.values_per_trial_merged(:,3)==i_trial,clmnnmbr) = integral_abs;
        clmnnmbr = clmnnmbr + 1;
        
        output.values_per_trial_merged(output.values_per_trial_merged(:,3)==i_trial,clmnnmbr) = [0;deriv1_rel];
        clmnnmbr = clmnnmbr + 1;
        output.values_per_trial_merged(output.values_per_trial_merged(:,3)==i_trial,clmnnmbr) = [0;0;deriv2_rel];
        clmnnmbr = clmnnmbr + 1;
        output.values_per_trial_merged(output.values_per_trial_merged(:,3)==i_trial,clmnnmbr) = integral_rel;
            
        clmnnmbr = clmnnmbr_der;    
            
       clear X
       clear Y_abs
       clear Y_rel
            
        
       
       
       
        end
                       
        

        
        if runLabel == 1
            
            %Merge output data into 1 data sheet (with button press as reference)
            TUE002_MergedTraining = vertcat(TUE002_MergedTraining, output.values_per_trial_merged);
            
        else
            
            %Merge output data into 1 data sheet (with button press as reference)
            TUE002_MergedExp = vertcat(TUE002_MergedExp, output.values_per_trial_merged);

        end

          clearvars input;
          clearvars output;
          clearvars subj;
          clearvars conditions;


        end
        
    end

end




%%Save merged output

if runLabel == 1
    
    %Replace NaNs with 999999
    TUE002_MergedTraining(isnan(TUE001_MergedExp)) = 9999;


        %Save training output (button press)
        fullSample_filename = sprintf('%s\\Training\\TUE002_MergedTraining_%s', effort_directory, datestr(now, 'yyyymmdd'));
        save([fullSample_filename '.mat'], 'TUE002_MergedTraining')

        file_directory = [effort_directory '\Training'];
        cd(file_directory);
        csv_filename = ['TUE002_MergedTraining_' datestr(now, 'yyyymmdd') '.dat'];
        csvwrite(csv_filename, TUE002_MergedTraining)

        cd(effort_directory);

else

    %Replace NaNs with 999999
    TUE002_MergedExp(isnan(TUE002_MergedExp)) = 9999;


        %Save experiment output (button press)
        fullSample_filename = sprintf('%s\\grEATdata\\grEATPilot_ExpMerged\\TUE002_MergedExp_%s', effort_directory, datestr(now, 'yyyymmdd'));
        save([fullSample_filename '.mat'], 'TUE002_MergedExp')

        file_directory = [effort_directory '\grEATdata\grEATPilot_ExpMerged'];
        cd(file_directory);
        csv_filename = ['TUE002_MergedExp_' datestr(now, 'yyyymmdd') '.dat'];
        csvwrite(csv_filename, TUE002_MergedExp)

        cd(effort_directory);
    
end




% %%============================
% %%Merge VAS output
% %%============================
% 
% TUE001_MergedVAS = [];
% 
% %Define directory
% VASstate_directory = 'C:\Users\Monja\Masterarbeit\05_Data\VAS_state';
% cd(VASstate_directory);
% 
% 
% for i_sess = 1:2
%     
%     for i_subj = 1:20
%         
%         for i_t = 1:3
% 
%             if data_present(i_sess,i_subj) == 1
%                 
%                 vas_searchname = [[pwd '\Raw_Data\VASstate_TUE001_' num2str(i_subj,'%02d') '_' num2str(i_sess) '_' num2str(i_t)] '*'];
%                 vas_searchname = dir(vas_searchname);
%                 vas_filename = sprintf('%s\\Raw_Data\\%s', pwd, vas_searchname.name);
%                 load(vas_filename, 'output');
%               
%                 %output.ratings_merged = output.rating;
%                 output.ratings_merged = [(ones(length(output.rating(:,1)), 1) * i_subj), output.rating];
% 
%                 %Add 1 row with session number
% 
%                 for i_cell = 1 : length(output.rating(:,1))
% 
%                     output.ratings_merged(i_cell,7) = i_sess;
%                     output.ratings_merged(i_cell,8) = i_t;
%                     output.ratings_merged(i_cell,9) = StimConditions_pseudo(i_sess,i_subj);
%                     
%                 end
%                 
%                 %Merge output data into 1 data sheet
%                 TUE001_MergedVAS = vertcat(TUE001_MergedVAS, output.ratings_merged);
%                 
%                 clearvars output;
%                 clearvars subj;
%           
%             end
%             
%         end
%         
%     end
%         
% end
%     
% 
% %%Save merged output
% 
%     %Replace NaNs with 999999
%     TUE001_MergedVAS(isnan(TUE001_MergedVAS)) = 9999;
%        
%     %Save output
%     fullSample_vas_filename = sprintf('%s\\TUE001_MergedVAS_%s', VASstate_directory, datestr(now, 'yyyymmdd'));
%     save([fullSample_vas_filename '.mat'], 'TUE001_MergedVAS');
% 
% %     file_directory = [VASstate_directory];
% %     cd(file_directory);
%     csv_vas_filename = ['TUE001_MergedVAS_' datestr(now, 'yyyymmdd') '.dat'];
%     csvwrite(csv_vas_filename, TUE001_MergedVAS);
%     
% 
%     
% %%end    
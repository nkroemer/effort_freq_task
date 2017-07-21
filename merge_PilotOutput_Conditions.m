%%=======After Pilot 1====
%Merge Pilot output with conditions

% Clear workspace
close all;
clear all; 
sca;


%Define Output: Merged Data of all 9 pilot subjects
fullSample_output = [];


%Define main directory
effort_directory = 'C:\Users\Monja\MATLAB\Effort_task';
cd(effort_directory);

%Load Conditions files
cd([effort_directory '/conditions'])
pilot_cond = dir('cond_*');

%Load Output files    
cd([effort_directory '/data'])
pilot_output = dir('effort_pilot_*');



%Pilot: 9 Subjects
for i_subj = 1:9
    
    cd([effort_directory '/data'])
    load(pilot_output(i_subj).name);
    
    cd([effort_directory '/conditions']);
    load(pilot_cond(i_subj).name);
    
    output.values_per_trial_merged = output.values_per_trial_flipped;
    
    
    
    for i = 1 : length(output.values_per_trial_flipped(:,2));
        
        output.values_per_trial_merged(i,6) = input.maxFrequency;
        
        
        trial_nr = output.values_per_trial_flipped(i,2);
        cond_value = conditions(1,trial_nr);        
        output.values_per_trial_merged(i,7) = cond_value;
        
        freq_threshold = input.maxFrequency * (cond_value/100);
        output.values_per_trial_merged(i,8) = freq_threshold;
        
        clearvars trial_nr;
        clearvars cond_value;
        clearvars freq_threshold;
        
    end
    
      fullSample_output = vertcat(fullSample_output, output.values_per_trial_merged);
      
      clearvars input;
      clearvars output;
      clearvars subj;
      clearvars conditions;
 
  
end


fullSample_filename = sprintf('%s\\data\\fullSample_output', effort_directory);
save([fullSample_filename '.mat'], 'fullSample_output')





%%==========After Pilot 2=======
%Merge Pilot output with conditions

% Clear workspace
close all;
clear all; 
sca;


%Define Output: Merged Data of all 9 pilot subjects
fullSample_pilot2_output = [];


%Define main directory
effort_directory = 'C:\Users\Monja\MATLAB\Effort_task';
cd(effort_directory);

%Load Conditions files
cd([effort_directory '/conditions'])
pilot_cond = dir('cond_diff_rewrd_*');

%Load Output files    
cd([effort_directory '/data'])
pilot_output = dir('effort_pilot2_*');



%Pilot2: 3 Subjects
for i_subj = 1:3
    
    cd([effort_directory '/data'])
    load(pilot_output(i_subj).name);
    
    cd([effort_directory '/conditions']);
    load(pilot_cond(i_subj).name);
    
    output.values_per_trial_merged = output.values_per_trial_flipped;
    
    
    
%     for i = 1 : length(output.values_per_trial_flipped(:,2));
%         
%         output.values_per_trial_merged(i,6) = input.maxFrequency;
%         
%         
%         trial_nr = output.values_per_trial_flipped(i,2);
%         cond_value = conditions(1,trial_nr);        
%         output.values_per_trial_merged(i,7) = cond_value;
%         
%         freq_threshold = input.maxFrequency * (cond_value/100);
%         output.values_per_trial_merged(i,8) = freq_threshold;
%         
%         clearvars trial_nr;
%         clearvars cond_value;
%         clearvars freq_threshold;
%         
%     end
    
      fullSample_pilot2_output = vertcat(fullSample_pilot2_output, output.values_per_trial_merged);
      
%     for SPSS import substitute NaN with 9999
      fullSample_pilot2_output(isnan(fullSample_pilot2_output)) = 9999;
      
      clearvars input;
      clearvars output;
      clearvars subj;
      clearvars conditions;
 
  
end


fullSample_filename = sprintf('%s\\data\\fullSample_pilot2_output', effort_directory);
save([fullSample_filename '.mat'], 'fullSample_pilot2_output')


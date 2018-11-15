

%%======Effort allocation task_ Randomise Conditions=======
%Script for creating condition files -18/06/2017-
%author: Monja P. Neuser

%For piloting of effort task: Use 16 different conditions
%Percent of MaxFreq between 60% and 90%

%For experiment use 2 conditions:
% LowDiff = 75%
% HighDiff = 85%
% No randomization for difficulty


%TO DO:
%Randomize incentives
%========================================================

subj.studyID = 'TUE001'; %Prefix of tVNS project
subj.study_part_ID = 'S5';

%%=========================
%%Conditions for training
%%=========================
%%Create difficulty+Incentive conditions for experiment
Money = 1;
Food = 2;

LowRwrd = 1;      %1  Cent, kCal / Sec
HighRwrd = 10;    %10 Cent, kCal / Sec

LowDiff = 75; %percent of MaxForce
HighDiff = 85; %percent of MaxForce

Value_labels = {'Money', Money; 'Food', Food; 'LowRwrd', LowRwrd; 'HighRwrd', HighRwrd; 'LowDiff', LowDiff; 'HighDiff', HighDiff};

%all possible combinations
LowDiff_M_low = [LowDiff, Money, LowRwrd];
LowDiff_M_high = [LowDiff, Money, HighRwrd];
LowDiff_F_low = [LowDiff, Food, LowRwrd];
LowDiff_F_high = [LowDiff, Food, HighRwrd];

HighDiff_M_low = [HighDiff, Money, LowRwrd];
HighDiff_M_high = [HighDiff, Money, HighRwrd];
HighDiff_F_low = [HighDiff, Food, LowRwrd];
HighDiff_F_high = [HighDiff, Food, HighRwrd];

%Condition vector
LowDiff_vector = [LowDiff_M_low; LowDiff_M_high; LowDiff_F_low; LowDiff_F_high];
HighDiff_vector = [HighDiff_M_low; HighDiff_M_high; HighDiff_F_low; HighDiff_F_high];


for i_id = 1:99
    
    conditions = [];
    
    %Random selection without displacement of indices
    perm_i_LowDiff = randperm(length(LowDiff_vector));
    perm_i_HighDiff = randperm(length(LowDiff_vector));


    %Create conditions vector, HighDiff and LowDiff alternating
    for k = 1:length(LowDiff_vector)

        l_k = LowDiff_vector(perm_i_LowDiff(k),1:3);
        h_k = HighDiff_vector(perm_i_HighDiff(k),1:3);

        if mod(i_id,2) 
        conditions = [conditions; l_k; h_k];
        else
        conditions = [conditions; h_k; l_k];
        end

    end

    output.filename = sprintf('%s\\conditions\\EAT-cond-Training_%s_%02d_%s_R1', pwd, subj.studyID, i_id,subj.study_part_ID);

    save([output.filename '.mat'], 'conditions', 'Value_labels')


end


%%================================
%%Diff+Rewrd Cond for experiment
%%================================

%%Create difficulty+Incentive conditions for experiment
Money = 1;
Food = 2;

LowRwrd = 1;      %1  Cent, kCal / Sec
HighRwrd = 10;    %10 Cent, kCal / Sec

Step1 = 60; %percent of MaxForce
Step2 = 66; %percent of MaxForce
Step3 = 72; %percent of MaxForce
Step4 = 78; %percent of MaxForce
Step5 = 84; %percent of MaxForce
Step6 = 90; %percent of MaxForce

Certainty = 0; %Bar you have to get higher than
Uncertainty = 1; %Uncertainty box

Value_labels = {'Money', Money; 'Food', Food; 'LowRwrd', LowRwrd; 'HighRwrd', HighRwrd; 'Step1', Step1; 'Step2', Step2; 'Step3', Step3; 'Step4', Step4; 'Step5', Step5;'Step6', Step6};

%all possible combinations
Step1_M_low_cer = [Step1, Money, LowRwrd, Certainty];
Step1_M_low_un = [Step1, Money, LowRwrd, Uncertainty];
Step1_M_high_cer = [Step1, Money, HighRwrd, Certainty];
Step1_M_high_un = [Step1, Money, HighRwrd, Uncertainty];
Step1_F_low_cer = [Step1, Food, LowRwrd, Certainty];
Step1_F_low_un = [Step1, Food, LowRwrd, Uncertainty];
Step1_F_high_cer = [Step1, Food, HighRwrd, Certainty];
Step1_F_high_un = [Step1, Food, HighRwrd, Uncertainty];

Step2_M_low_cer = [Step2, Money, LowRwrd, Certainty];
Step2_M_low_un = [Step2, Money, LowRwrd, Uncertainty];
Step2_M_high_cer = [Step2, Money, HighRwrd, Certainty];
Step2_M_high_un = [Step2, Money, HighRwrd, Uncertainty];
Step2_F_low_cer = [Step2, Food, LowRwrd, Certainty];
Step2_F_low_un = [Step2, Food, LowRwrd, Uncertainty];
Step2_F_high_cer = [Step2, Food, HighRwrd, Certainty];
Step2_F_high_un = [Step2, Food, HighRwrd, Uncertainty];

Step3_M_low_cer = [Step3, Money, LowRwrd, Certainty];
Step3_M_low_un = [Step3, Money, LowRwrd, Uncertainty];
Step3_M_high_cer = [Step3, Money, HighRwrd, Certainty];
Step3_M_high_un = [Step3, Money, HighRwrd, Uncertainty];
Step3_F_low_cer = [Step3, Food, LowRwrd, Certainty];
Step3_F_low_un = [Step3, Food, LowRwrd, Uncertainty];
Step3_F_high_cer = [Step3, Food, HighRwrd, Certainty];
Step3_F_high_un = [Step3, Food, HighRwrd, Uncertainty];

Step4_M_low_cer = [Step4, Money, LowRwrd, Certainty];
Step4_M_low_un = [Step4, Money, LowRwrd, Uncertainty];
Step4_M_high_cer = [Step4, Money, HighRwrd, Certainty];
Step4_M_high_un = [Step4, Money, HighRwrd, Uncertainty];
Step4_F_low_cer = [Step4, Food, LowRwrd, Certainty];
Step4_F_low_un = [Step4, Food, LowRwrd, Uncertainty];
Step4_F_high_cer = [Step4, Food, HighRwrd, Certainty];
Step4_F_high_un = [Step4, Food, HighRwrd, Uncertainty];

Step5_M_low_cer = [Step5, Money, LowRwrd, Certainty];
Step5_M_low_un = [Step5, Money, LowRwrd, Uncertainty];
Step5_M_high_cer = [Step5, Money, HighRwrd, Certainty];
Step5_M_high_un = [Step5, Money, HighRwrd, Uncertainty];
Step5_F_low_cer = [Step5, Food, LowRwrd, Certainty];
Step5_F_low_un = [Step5, Food, LowRwrd, Uncertainty];
Step5_F_high_cer = [Step5, Food, HighRwrd, Certainty];
Step5_F_high_un = [Step5, Food, HighRwrd, Uncertainty];

Step6_M_low_cer = [Step6, Money, LowRwrd, Certainty];
Step6_M_low_un = [Step6, Money, LowRwrd, Uncertainty];
Step6_M_high_cer = [Step6, Money, HighRwrd, Certainty];
Step6_M_high_un = [Step6, Money, HighRwrd, Uncertainty];
Step6_F_low_cer = [Step6, Food, LowRwrd, Certainty];
Step6_F_low_un = [Step6, Food, LowRwrd, Uncertainty];
Step6_F_high_cer = [Step6, Food, HighRwrd, Certainty];
Step6_F_high_un = [Step6, Food, HighRwrd, Uncertainty];

%Condition vectors
Step1_vector = [Step1_M_low_cer; Step1_M_low_un; Step1_M_high_cer; Step1_M_high_un;...
    Step1_F_low_cer; Step1_F_low_un; Step1_F_high_cer; Step1_F_high_un];
Step2_vector = [Step2_M_low_cer; Step2_M_low_un; Step2_M_high_cer; Step2_M_high_un;...
    Step2_F_low_cer; Step2_F_low_un; Step2_F_high_cer; Step2_F_high_un];
Step3_vector = [Step3_M_low_cer; Step3_M_low_un; Step3_M_high_cer; Step3_M_high_un;...
    Step3_F_low_cer; Step3_F_low_un; Step3_F_high_cer; Step3_F_high_un];
Step4_vector = [Step4_M_low_cer; Step4_M_low_un; Step4_M_high_cer; Step4_M_high_un;...
    Step4_F_low_cer; Step4_F_low_un; Step4_F_high_cer; Step4_F_high_un];
Step5_vector = [Step5_M_low_cer; Step5_M_low_un; Step5_M_high_cer; Step5_M_high_un;...
    Step5_F_low_cer; Step5_F_low_un; Step5_F_high_cer; Step5_F_high_un];
Step6_vector = [Step6_M_low_cer; Step6_M_low_un; Step6_M_high_cer; Step6_M_high_un;...
    Step6_F_low_cer; Step6_F_low_un; Step6_F_high_cer; Step6_F_high_un];

for i_id = 1:99
    
    conditions = [];

    %Random selection without displacement of indices
    perm_i_Step1 = randperm(length(Step1_vector));
    perm_i_Step2 = randperm(length(Step2_vector));
    perm_i_Step3 = randperm(length(Step3_vector));
    perm_i_Step4 = randperm(length(Step4_vector));
    perm_i_Step5 = randperm(length(Step5_vector));
    perm_i_Step6 = randperm(length(Step6_vector));

    %Create conditions vector, HighDiff and LowDiff alternating
    for k = 1:length(LowDiff_vector)
        
        step1_k = Step1_vector(perm_i_Step1(k),1:4);
        step2_k = Step2_vector(perm_i_Step2(k),1:4);
        step3_k = Step3_vector(perm_i_Step3(k),1:4);
        
        
        l_k = LowDiff_vector(perm_i_LowDiff(k),1:4);
        h_k = HighDiff_vector(perm_i_HighDiff(k),1:4);

        if mod(i_id,2) 
        conditions = [conditions; l_k; h_k];
        else
        conditions = [conditions; h_k; l_k];
        end

    end

    output.filename = sprintf('%s\\conditions\\EAT-cond-Experiment_%s_%02d_%s_R1', pwd, subj.studyID, i_id,subj.study_part_ID);

    save([output.filename '.mat'], 'conditions', 'Value_labels')


end


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


%%=========================
%%Conditions for training
%%=========================
%%Create difficulty+Incentive conditions for experiment
Money = 1;
Food = 2;

LowRwrd = 1;      %1  Cent, kCal / Sec
HighRwrd = 10;    %10 Cent, kCal / Sec

LowDiff = 75; %percent of MaxFreq
HighDiff = 85; %percent of MaxFreq

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


for i_id = 1:80
    
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
        conditions = [conditions; h_k, l_k];
        end

    end

    output.filename = sprintf('%s\\conditions\\cond_training_%02d', pwd, i_id);

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

LowDiff = 75; %percent of MaxFreq
HighDiff = 85; %percent of MaxFreq

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
LowDiff_vector = repmat([LowDiff_M_low; LowDiff_M_high; LowDiff_F_low; LowDiff_F_high], 6, 1);
HighDiff_vector = repmat([HighDiff_M_low; HighDiff_M_high; HighDiff_F_low; HighDiff_F_high], 6, 1);


for i_id = 1:80
    
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
        conditions = [conditions; h_k, l_k];
        end

    end

    output.filename = sprintf('%s\\conditions\\cond_exp_%02d', pwd, i_id);

    save([output.filename '.mat'], 'conditions', 'Value_labels')


end






%%Create difficulty conditions for piloting 
%{
LowDiff = 75; %percent of MaxFreq
HighDiff = 85; %percent of MaxFreq

conditions_diff = repmat([LowDiff HighDiff],1,16);

output.filename = sprintf('%s\\conditions\\cond_exp_75-85', pwd);

save([output.filename '.mat'], 'conditions_diff')


%%Create reward conditions for experiment
%With replacement?
money_low = 1;
money_high = 10;
food_low = 2;
food_high = 20;

cond_vector = [money_low , money_high , food_low , food_high];
num_cond = 32;

for i_id = 1:10
    
    cond__rewrd_shuffled = datasample(cond_vector,num_cond);
    conditions = [cond__rewrd_shuffled; conditions_diff]';
    
    output.filename = sprintf('%s\\conditions\\cond__rewrd_%02d', pwd, i_id);

    save([output.filename '.mat'], 'conditions')

end
}%
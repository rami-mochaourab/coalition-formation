function [C,values_after,bin] = group_dev_Split(C,values_before)

% outputs:
% C: the new coalition structure
% value_after: vector of utilities for each user with the new coalition
% structure
% bin: (binary) true if no deviation occurs

% inputs:
% C: current coalition structure
% value_before: vector of utilities for each user with the old coalition
% structure


% initialize
bin = false;
values_after = values_before;

% find the nonempty coalitions
bin_nonempty_coals = any(C);
bin_coals_larger_two = logical(sum(C) > 1); % coalitions that can split

idx_coals = find(bin_coals_larger_two);
num_coals_to_split = length(idx_coals);

bin_empty_coals = ~bin_nonempty_coals;
if any(bin_empty_coals)
    idx_empty = find(bin_empty_coals, 1); % one of those empty coalitions will be used to add one of the coalitions which split
end

% for each coalition which has more than 1 element, find all spliting structures
for idx_T = 1:1:num_coals_to_split
    
    % select the coalition
    coalition_to_split = idx_coals(idx_T);
    
    % array consisting of the players in the coalition
    bin_members_T = C(:,coalition_to_split);
    idx_members_T = find(bin_members_T);
    
    subsets = SetPartition(length(idx_members_T),2); % sets of all 2-subsets of 1:length(T)
    
    number_of_splits = length(subsets);
    
    for k = 1:1:number_of_splits
        coalition1 = idx_members_T(subsets{k}{1});
        coalition2 = idx_members_T(subsets{k}{2});
        
        
        % create coaliton structure according to the split in subsets{k}
        C_temp = C;
        
        % form coalition structure by splitting T into two coalitions
        C_temp(:,coalition_to_split) = 0; % reset coalition at index coalition_to_split
        C_temp(coalition1,coalition_to_split) = 1; % add first coalition at index coalition_to_split
        C_temp(coalition2,idx_empty(1)) = 1; % % add first coalition at index idx_empty(1) which is an empty coalition in C
        
        % calculate utilities for the temp coalition structure C_temp
        values_temp = calc_utility(C_temp);
        
        if bin_PO(values_before(bin_members_T), values_temp(bin_members_T))
            
            C = C_temp;
            values_after = values_temp;
            bin = true;
            return
            
        end
    end
end

function [C,values_after,bin,H_Merge] = group_dev_Merge(C,values_before,H_Merge)

% outputs:
% C: the new coalition structure
% value_after: vector of utilities for each user with the new coalition
% structure
% bin: (binary) true if no deviation occurs
% H_Merge: History sets

% inputs:
% C: current coalition structure
% value_before: vector of utilities for each user with the old coalition
% structure
% H_Merge: History sets


% initialize
global q
bin = false;
values_after = values_before;

% find the nonempty coalitions
bin_nonempty_coals = any(C);
idx_coals = find(bin_nonempty_coals);
num_coals = length(idx_coals);

if num_coals > 1
    
    % k is the number of coaltions which merge
    % the maximum is restricted to q
    % start with largest number of coalitions
    
    for k = min(q,num_coals):-1:2
        
        T_all = combnk(idx_coals,k); % choose coalitions that want to merge
        
        for j = 1:1:size(T_all,1) % j is the index for a coalition structure
            
            idx_T = T_all(j,:); % indexes of the coalitions to merge
            
            C_temp = C;
            
            bin_T = logical(sum(C(:,idx_T),2)); % form coalition by merging coalitions in T
            
            % check if bin_T has been a coalition before
            if all(any(H_Merge - repmat(bin_T,[1, size(H_Merge,2)])))
                
                
                C_temp(:,idx_T) = 0; % set coalitions of T to zeros
                C_temp(:,idx_T(1)) = bin_T; % add coalition T at position idx_T(1) in C_temp
                
                % calculate utilities for the temp coalition structure C_temp
                values_temp = calc_utility(C_temp);
                
                if bin_PO(values_before(bin_T), values_temp(bin_T))
                    
                    C = C_temp;
                    values_after = values_temp;
                    H_Merge = [H_Merge,bin_T];
                    bin = true;
                    return
                    
                end
            end
        end
    end
end

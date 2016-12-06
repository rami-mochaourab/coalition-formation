function [C, values_after, stability_user, H] = individual_dev(C, values_before, i_user, H)

% outputs:
% C: the new coalition structure
% value_after: vector of utilities for each user with the new coalition
% structure
% stability_user: (binary) true if no deviation occurs
% H: History sets

% inputs:
% C is the current coalition structure
% i_user : the user considered for deviaiton
% H: History sets

stability_user = true;

% initialize payoffs
values_after = values_before;

% find the nonempty coalitions
nonempty_cells = any(C);
idx_poss_join = find(nonempty_cells);

i_user_current_coalition_index = find(C(i_user,:)); % find the coalition of user i_user

% add empty set as possible coalition to join if user is not in singlton coalition
empty_cells = ~nonempty_cells;
if any(empty_cells)
    idx_empty = find(empty_cells, 1);
    idx_poss_join = [idx_poss_join,idx_empty(1)];
end

% remove current coalition of i_user in the possible coalitions to join set
idx_poss_join = idx_poss_join(idx_poss_join~=i_user_current_coalition_index);

num_Coals = length(idx_poss_join);

% going over all possible coalitions for user to join
for i_S = 1:num_Coals
    
    % joining_set_index : the set i_user tests if he would join
    joining_coalition_index = idx_poss_join(i_S);
    
    % user joins new coalition and leaves the old one
    C_temp = C;
    C_temp(i_user,joining_coalition_index) = true; % join new coalition
    C_temp(i_user,i_user_current_coalition_index) = false; % leave old coalition
    
    
    % if new coalition is not in history set
    history_matrix = H{i_user};
    
    
    if all(any(history_matrix - repmat(C_temp(:,joining_coalition_index),[1, size(history_matrix,2)])))
        
        % calculate utilities in the new coalition structure
        value_after_temp = calc_utility(C_temp);
        
        % check individual stability
        [bin] = bin_stab(values_before, value_after_temp, C_temp(:,i_user_current_coalition_index), C_temp(:,joining_coalition_index), i_user);
        
        if bin(2) % either of bin_Nash = 1, bin_Indivdual = 2, bin_Contractual = 3
            
            C = C_temp;
            values_after = value_after_temp;
            H{i_user} = [H{i_user},C_temp(:,joining_coalition_index)];
            stability_user = false; % unstable since user changed coalition
            break
            
        end
    end
end


end


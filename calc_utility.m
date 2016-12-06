function utility = calc_utility(C)

% C is an NxN matrix, columns correspond to coalitions and rows to users

global N t H P noise

utility = zeros(N,1);
w = calc_ZF_beams_CS(C);

for i = 1:N
    
    desired = abs(H(:,i,i)'*w(:,i))^2;
    channels_to_user = reshape(H(:,i,:),[t,N]);
    g = diag(channels_to_user'*w);
    
    interference = g'*g - desired;
    utility(i) =  log2(1 + desired/(interference + noise));
    
end

    function w = calc_ZF_beams_CS(C)
        
        w = zeros(t,N);
        
        % calculate the beamforming vectors
        coalition_indexes = find(any(C));
        for idx_S = 1:1:length(coalition_indexes)
            
            % idx_S is the coalition index
            users_in_coalition = find(C(:,coalition_indexes(idx_S)));
            num_users_in_coalition = length(users_in_coalition);
            
            % j is the member of the coalition that will perform ZF to the
            % others
            if num_users_in_coalition <= t % ZF condition
                for j = 1:1:num_users_in_coalition
                    
                    s_user = users_in_coalition(j); % user that will perform ZF
                    not_s = users_in_coalition(users_in_coalition~=s_user); % other users than s_user in the coalition
                    w(:,s_user) = calc_ZF_coal(s_user,not_s); % calculate ZF beamformers
                    
                end
            end
        end
    end

    function w_user = calc_ZF_coal(s,not_s)

        F = eye(t) - H(:,not_s,s)*((H(:,not_s,s)'*H(:,not_s,s))\H(:,not_s,s)');
        v_zf = F*H(:,s,s);
        w_user = sqrt(P)*v_zf/norm(v_zf);
        
    end

end
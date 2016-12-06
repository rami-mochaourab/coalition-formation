
global N t P noise
global q

N = 17;         % number of systems
t = 8;          % number of antennas
q_vec = 2:6;    % parameter q (see paper)

rng(1234);

% transmission power and noise at the receivers. Values taken from
% reference [10] from the paper

transmit_powers_dBm = 46;
transmit_powers_dBm_sim = transmit_powers_dBm - 10*log10(600); % simulating one 15 kHz subcarrier, of which there are 600 in a 10 MHz system
bandwidth = 15e3; % bandwidth of one subcarrier [Hz]
receiver_noise_figure_dB = 9; % how many dB 'worse' the receiver is than the optimal one. Value taken from 3gpp.
noise_power_dBm = -174 + 10*log10(bandwidth) + receiver_noise_figure_dB; % thermal noise power
noise = 10.^(noise_power_dBm./10);
P = 10^(transmit_powers_dBm_sim/10);

%% initialize

samples = 1000; % number of deployment samples

performance_Nash = zeros(length(N),samples);
performance_Nash_equilibrium = zeros(length(N),samples);
performance_Grand = zeros(length(N),samples);
performance_Indi = zeros(length(N),samples);
performance_Cont = zeros(length(N),samples);

performance_Merge = zeros(length(N),samples);
performance_Split = zeros(length(N),samples);
performance_MergeSplit = zeros(length(N),samples);

coalition_size_Merge = zeros(length(N),samples);
coalition_size_Split = zeros(length(N),samples);
coalition_size_MergeSplit = zeros(length(N),samples);
coalition_size_Indi = zeros(length(N),samples);

adj_C_Indi = zeros(N,N,samples);
adj_C_Merge = zeros(N,N,samples,length(q_vec));
adj_C_MergeSplit = zeros(N,N,samples,length(q_vec));

%  The following values for the geometry of the topology are taken from reference [10] in the paper
ISD = 500; % average inter site distance [m]. Value taken from 3gpp.
BS_density = 1/(sqrt(3)/2*ISD^2);   % BSs per m^2, for hexagonal cells
box_width = sqrt(N/BS_density); % This gives a box with average BS density similar to hexagonal grid case

topology_TX = box_width*rand(N,2);
topology_TX(:,1) = topology_TX(:,1) - 200;
topology_TX(:,2) = topology_TX(:,2) + 100;

for idx_sample = 1:samples
    
    % deploxment of BSs
    topology_RX = topology_TX;
    
    topology_RX(:,1) = topology_RX(:,1) + 200*(2*rand(N,1) - 1);
    topology_RX(:,2) = topology_RX(:,2) + 200*(2*rand(N,1) - 1);
    
    % channels
    generate_channels(topology_TX,topology_RX); % H_kj = H(:,j,k); transmitter k receiver j
    
    fprintf('\n Sample %d out of %d, q: ',idx_sample, samples);
    
    for idx_links = 1:length(q_vec)
        
        q = q_vec(idx_links);
        
        fprintf('%d,', q);
        
        % coalition structure is initialized to singleton coalitions
        coal_initialization = logical(eye(N)); % columns correspond to coalitions, rows to users
        
        C_Nash = coal_initialization;
        C_Indi = coal_initialization;
        C_Cont = coal_initialization;
        
        C_Merge = coal_initialization;
        C_Split = coal_initialization;
        C_MergeSplit = coal_initialization;
        
        % History sets
        History_ini = cell(N,1); [History_ini{:}] = deal(zeros(N,1));
        
        H_Nash = History_ini;
        H_Indi = History_ini;
        H_Cont = History_ini;
        H_Merge = zeros(N,1);
        H_MergeSplit = zeros(N,1);
        
        %% Nash equilibrium
        
        utilities_Nash_equilibrium = calc_utility(C_Nash);
        performance_Nash_equilibrium(idx_links,idx_sample) = sum(utilities_Nash_equilibrium);
               
        %% Individual Deviation: Individual Stability
        
        bin_ind = true; % unstable.
        bin_ind_user = false(1,N); % false if user i is unstable
        utilities_Indi = utilities_Nash_equilibrium;
        
        while bin_ind
            
            randomize_users = 1:N;
            
            for idx_user = 1:N
                
                i_user = randomize_users(idx_user);
                [C_Indi, utilities_Indi, bin_ind_user(i_user), H_Indi] = individual_dev(C_Indi, utilities_Indi, i_user, H_Indi);
                
            end
            
            if all(bin_ind_user)
                bin_ind = false; % stability
            end
            
        end
        
        % create graph
        for i=1:N
            adj_C_Indi(:,i,idx_sample) = C_Indi(:,C_Indi(i,:));
        end
        
        performance_Indi(idx_links,idx_sample) = sum(utilities_Indi);
        nonempty_coalitions = logical(sum(C_Indi)>1);
        
        if any(nonempty_coalitions)
            coalition_sizes = sum(C_Indi(:,nonempty_coalitions));
        else
            coalition_sizes = 1;
        end
        
        coalition_size_Indi(idx_links,idx_sample) = mean(coalition_sizes);
        
        %% Merge
        
        bin_Merge = 1; % unstablity
        utilities_Merge = utilities_Nash_equilibrium;
        
        while bin_Merge
            
            [C_Merge, utilities_Merge, bin_Merge, H_Merge] = group_dev_Merge(C_Merge, utilities_Merge, H_Merge);
            
        end
        for i=1:N
            
            adj_C_Merge(:,i,idx_sample,idx_links) = C_Merge(:,C_Merge(i,:));
            
        end
        
        performance_Merge(idx_links,idx_sample) = sum(utilities_Merge);
        nonempty_coalitions = logical(sum(C_Merge)>1);
        
        if any(nonempty_coalitions)
            coalition_sizes = sum(C_Merge(:,nonempty_coalitions));
        else
            coalition_sizes = 1;
        end
        
        coalition_size_Merge(idx_links,idx_sample) = mean(coalition_sizes);
        
        %% Merge and Split
        
        bin_MergeSplit = 1; % unstablity
        utilities_MergeSplit = utilities_Nash_equilibrium;
        
        while bin_MergeSplit

            [C_MergeSplit, utilities_MergeSplit, bin_Merge, H_MergeSplit] = group_dev_Merge(C_MergeSplit, utilities_MergeSplit, H_MergeSplit);
            [C_MergeSplit, utilities_MergeSplit, bin_Split] = group_dev_Split(C_MergeSplit, utilities_MergeSplit);

            if bin_Split
                a = 1 ;
            end
            
            if ~bin_Merge && ~bin_Split
                bin_MergeSplit = 0;
            end
        end
        
        for i=1:N
            adj_C_MergeSplit(:,i,idx_sample,idx_links) = C_MergeSplit(:,C_MergeSplit(i,:));
        end
        
        performance_MergeSplit(idx_links,idx_sample) = sum(utilities_MergeSplit);
        nonempty_coalitions = logical(sum(C_MergeSplit)>1);
        
        if any(nonempty_coalitions)
            coalition_sizes = sum(C_MergeSplit(:,nonempty_coalitions));
        else
            coalition_sizes = 1;
        end
        
        coalition_size_MergeSplit(idx_links,idx_sample) = mean(coalition_sizes);
        
    end
end


%% Plots

% sum rate vs q

sum_rate = figure;
grid on
hold on
figure(sum_rate)

plot(q_vec,mean(performance_MergeSplit,2)','s-')
text(q_vec,mean(performance_MergeSplit,2)',num2str(round( mean(coalition_size_MergeSplit,2) ,2)),'HorizontalAlignment','right','VerticalAlignment','bottom')

plot(q_vec,mean(performance_Merge,2)','s-')
text(q_vec,mean(performance_Merge,2)',num2str(round( mean(coalition_size_Merge,2) ,2)),'HorizontalAlignment','left','VerticalAlignment','top')

plot(q_vec,mean(performance_Indi,2)','d-')
text(q_vec,mean(performance_Indi,2)',num2str(round( mean(coalition_size_Indi,2) ,2)),'HorizontalAlignment','left','VerticalAlignment','top')
plot(q_vec,mean(performance_Nash_equilibrium,2)','x-')

legend('Merge-and-Split based Stability', 'Merge based Stability', 'Individual Stability' ,'Nash equilibrium')

% Graph plot
% Requires Matlab R2016b

G_MergeSplit = graph((sum(adj_C_MergeSplit(:,:,:,3),3) - samples*eye(N))/samples);

topology = figure;
grid on
hold on
legend('show')
figure(topology)

colormap(flipud(gray))

graph_plot = plot(G_MergeSplit,'LineWidth',2,'EdgeCData',G_MergeSplit.Edges.Weight);
graph_plot.XData = topology_TX(:,1)';
graph_plot.YData = topology_TX(:,2)';
graph_plot.Marker = 'o';
graph_plot.NodeColor = [0 0 0];
graph_plot.MarkerSize = 8;
colorbar
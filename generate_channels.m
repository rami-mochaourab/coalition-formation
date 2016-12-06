function generate_channels(topology_TX,topology_RX)

% topology_TX: positions of the transmitters
% topology_RX: Positions of the receivers

global N t H

% scenario parameters
H_wpl = 1/sqrt(2)*(randn(t,N,N) + 1i * randn(t,N,N));

% The following values are chosen as in reference [10] in the paper
% fading parameters (values taken from 3gpp)
PL_alpha = 37.6; % path loss exponent
PL_beta = 15.3; % path loss offset [dB]
PeL_dB = 10; % outdoor-indoor penetration loss [dB]
shadow_sigma_dB = 8; % std.dev of log-normal shadow fading

% Large scale parameter realization:
% 1. Draw BS and MS locations. (I think you have code for this already?)
% 2. Draw i.i.d. shadow fading realizations for all BS/MS pairs:
shadow_realizations_dB = shadow_sigma_dB*randn(N, N);

% topology_RX = box_width*rand(N,2);
XTx = topology_TX(:,1); % x-coordinates of nodes
YTx = topology_TX(:,2); % y-coordinates of nodes

% generate the receiver nodes
XRx = topology_RX(:,1);
YRx = topology_RX(:,2);

H = zeros(t,N,N);

dist = zeros(N,N);

for i = 1:N % receiver
    for j = 1:N % transmitter
        dist(i,j) = sqrt(abs(XTx(j) - XRx(i))^2 + abs(YTx(j)-YRx(i))^2);
        
        pathloss_factor = sqrt(10^(-(PL_beta + PL_alpha*log10(dist(i,j)))/10));
        shadow_factor = sqrt(10^(shadow_realizations_dB(i,j)/10));
        penetration_loss_factor = sqrt(10^(-PeL_dB/10));
        H(:,i,j) = pathloss_factor*shadow_factor*penetration_loss_factor*H_wpl(:,i,j);
        
    end
end
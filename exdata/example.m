%
% example data plotting
%
% Author: Eric DeWitt

%
% 

addpath('matmesh');

tuna_packet = get_tuna_packets('exdata/tuna.bin');
[tuna_data tuna_state tuna_channelmap] = packet_to_ndarray(tuna_packet);

plot(squeeze(tuna_data(1601:2800, 1, 1:3)));
% packet_to_ndarray
% 
% a simple function to convert a packet structarray to an ND array
function [nd_array, state, channelmap] = packet_to_ndarray(packet)
% frequency should be encoded in the data!?
%
%

    % we only parse for identical packets (we could handle packets of different sizes)
    if (numel(unique([packet.num_samples])) ~= 1 || ...
        numel(unique([packet.frequency])) ~= 1 || ...
        numel(unique([packet.num_channels])) ~= 1)
        error('unhandled heterogeneticy of packets');
    else
        num_channels = packet(1).num_channels;
        num_samples = packet(1).num_samples;
        frequency = packet(1).frequency;
    end
    mintime = min([packet.second]);
    maxtime = max([packet.second]);
    ids = unique([packet.id]);
    channelmap = [1:numel(ids); ids]'; % could be struct array
    nsamples = (maxtime - mintime + 1) * frequency;
    nd_array = NaN([nsamples, numel(ids), num_channels]);
    state = NaN([(nsamples / 4), numel(ids), 7]);
    for packet_n = 1:numel(packet)
        i = channelmap(find(packet(packet_n).id==channelmap(:,2),1));
        t = (packet(packet_n).second - mintime) * frequency + packet(packet_n).counter;
        nd_array(t:t+(num_samples-1),i,:) = packet(packet_n).data;

        state(t/4,i,:) = [packet(packet_n).id,
                      packet(packet_n).sync,
                      packet(packet_n).button,
                      packet(packet_n).aligned,
                      packet(packet_n).error,
                      packet(packet_n).second,
                      packet(packet_n).counter];
    end
    
end

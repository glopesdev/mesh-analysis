%
% basic import function for tuna data
%
%

% Author: Eric E J DeWitt
%
function [mesh_packet] = get_tuna_packets(stream, num_channels, num_samples)
    % internal vars to be externalized?
    if nargin < 3
        num_samples = 4;
    end
    if nargin < 2
        num_channels = 9;
    end
    message_length = 80; % is this fixed always?
    buffer_size = 16384;   % this is our internal read buffer.
    debug_f = false;
    safe_f = true;
    safe_gap_limit = 1;
    
    % We assume that stream is a character vector representing a file path &
    % name or that it is a file handle already opened externally. Only very
    % simple testing and checks are being done right now. This could be extended
    % easily to include arbitrary binary streams, for example if you wanted to
    % parse incoming data live.
    
    if ischar(stream)
        % open for reading
        stream = fopen(stream, 'r', 'ieee-le');
    else
        % test to see if it is a file object in the right mode
        [fname,fpermission,fmachinefmt,fencoding] = fopen(stream);
        if isempty(fname) | fmachinefmt ~= 'ieee-le'
            error('stream error', 'expected file i/o but not valid');
        end
    end
    
    % we have a file stream, lets read and parse
    % we'll read in chunks and parse (in the future should handle continuous
    % streams
    
    % let us pre-allocate the data struct
    fseek(stream, 0, 'eof');
    data_size = floor(ftell(stream)/message_length);
    mesh_packet = repmat(struct( ...
            'id', [], ...
            'sync', [], ...
            'button', [], ...
            'aligned', [], ...
            'error', [], ...
            'num_channels', [], ...
            'num_samples', [], ...
            'second', [], ...
            'counter', [], ...
            'data', []), ...
        data_size, 1);
    frewind(stream);
        
    % assuming file-like stream
    pkts_read = 0;
    while (~feof(stream))
        [buffer read_size] = fread(stream, buffer_size*message_length, '*uint8', 0, 'ieee-le');
        if rem(read_size, message_length) ~= 0
            warning('partial packet received? data possibly bad!');
        else
            valid_pkts = floor(read_size/message_length);
            for msg_n = 1:valid_pkts % implicit trunk?
                buf_pos = (((msg_n-1):msg_n)*message_length) + [1 0];
                mesh_packet(pkts_read+msg_n) = read_mesh_packet(buffer(buf_pos(1):buf_pos(2)), message_length, num_channels, num_samples);
            end
            pkts_read = pkts_read + valid_pkts;
        end
        if debug_f
            fprintf(2,'%d packets read\n', pkts_read);
        end
    end
    
    %
    % internal function for packet reading
    % could be easily refactored out later
    function [packet] = read_mesh_packet(message, message_length, num_channels, num_samples)
        % parse a packet from a binary data stream

        % binary masks
        id_mask = hex2dec('0FFF');
        sync_flag = hex2dec('8000');
        button_flag = hex2dec('4000');
        aligned_flag = hex2dec('2000');
        error_flag = hex2dec('1000');

        % parse packet
        message_id = typecast(message(2:3), 'uint16'); % probably actually uint16?
        % message_id = message(2) | bitshift(message(3), 8); % probably actually uint16?
        packet.id = bitand(message_id, id_mask);
        packet.sync = bitand(message_id, sync_flag) ~= 0;
        packet.button = bitand(message_id, button_flag) ~= 0;
        packet.aligned = bitand(message_id, aligned_flag) ~= 0;
        packet.error = bitand(message_id, error_flag) ~= 0;
        % this is inefficent; we could have a seperate header structarray
        packet.num_channels = num_channels;
        packet.num_samples = num_samples;
        packet.second = typecast(message(4:7), 'uint32'); % probably actually uint32
        % packet.second = bitor(message(4), bitshift(message(5), 8));
        % packet.second = bitor(packet.second, bitshift(message(6), 16));
        % packet.second = bitor(packet.second, bitshift(message(7), 24));
        packet.counter = uint32(message(8)); % is this necessary?
        packet.data = message(9:message_length);
        packet.data = reshape(typecast(packet.data, 'int16'), num_channels, num_samples)'; 
    end
    
   if safe_f
       times = [mesh_packet.second];
       unique_times = unique(times);
       last_good_time = unique_times(find(diff(unique_times)>safe_gap_limit));
       bad_packets = times>last_good_time;
       mesh_packet = mesh_packet(~bad_packets);
       warning(sprintf('%d packets dropped following a gap in data greater than mesh-second %d.', ...
                sum(bad_packets), last_good_time));
   end
end
%
% basic import function for tuna data
%
function [mesh_packet] = get_tuna_packets(stream, num_channels, num_samples)
    % internal vars to be externalized?
    if nargin < 3
        num_samples = 4;
    end
    if nargin < 2
        num_channels = 9;
    end
    frequency = 200;
    message_length = 80;
    buffer_size = 100;
    
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
    frewind(stream);
    
    % if we know that the output is fixed lenth, we could pre-allocate the output?
    mesh_packet = [];
    
    % assuming file-like stream
    while (~feof(stream))
        [buffer read_size] = fread(stream, buffer_size*message_length, '*uint8', 0, 'ieee-le');
        if rem(read_size, message_length) ~= 0
            warning('partial packet received? data possibly bad!');
        else
            for msg_n = 1:floor(read_size/message_length) % implicit trunk?
                buf_pos = (((msg_n-1):msg_n)*message_length) + [1 0];
                mesh_packet = [mesh_packet; read_mesh_packet(buffer(buf_pos(1):buf_pos(2)), message_length, num_channels, num_samples, frequency)];
            end    
        end
    end
    
    %
    % internal function for packet reading
    % could be easily refactored out later
    function [packet] = read_mesh_packet(message, message_length, num_channels, num_samples, frequency)
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
        packet.frequency = frequency;
        packet.second = typecast(message(4:7), 'uint32'); % probably actually uint32
        % packet.second = bitor(message(4), bitshift(message(5), 8));
        % packet.second = bitor(packet.second, bitshift(message(6), 16));
        % packet.second = bitor(packet.second, bitshift(message(7), 24));
        packet.counter = uint32(message(8)); % is this necessary?
        packet.data = message(9:message_length);
        packet.data = reshape(typecast(packet.data, 'int16'), num_channels, num_samples)'; 
    end
    
end
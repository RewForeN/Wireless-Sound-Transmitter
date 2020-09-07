
%%% BASK Trnasmitter by Ruan %%%

% Constructor %
function Transmitter()

    clc

    global sampleFrequency;
    sampleFrequency = 300;
    
    % Ask user to type their message
    message = input('Enter message:\n> ', 's');
    
    % Bit stream
    msg = "10101010101010101010001111111"; % Preamble & Start of message
    msg = msg + TextToBin(message); % Convert message to binary
    msg = msg + "0000100"; % End of message

    SendMessage(msg); % Play bit stream
    
end

% Convert text string to binary string %
function msg = TextToBin(message)

    % Convert message to binary
    temp = dec2bin(message);
    [y,x] = size(temp);
    msg = "";

    % Generate string based on message
    for i = 1:y
        for j = 1:x
            msg = msg + temp(i,j);
        end
    end

end

% Send binary message through sound waves %
function SendMessage(msg)
    
    global sampleFrequency

    x = strlength(msg);
    
    values = 1/sampleFrequency : 1/sampleFrequency : x; % start : 1/sample frequency : duration
    
    carrierWave = 100 * sin(2*pi * 100 * values); % Sound wave (amp * sin(2pi * freq * values))
    squareWave = zeros(1, length(values)); % Create square wave as all zeros
    
    fprintf("%s\n", msg);
    temp = char(msg);
    
    % Loop through message
    for i = 1:x
        
        % If message(i) has a one
        if (temp(i) == '1')
            % Add one to square wave at the corrisponding position
            index = (i-1) * sampleFrequency + 1; 
            squareWave(index : index + sampleFrequency - 1) = 1;
        end
        
        
    end
    
    % Multiply final square wave with carrier wave
    soundWave = carrierWave .* squareWave;
    
    % Play soundWave
    sound(soundWave);
    audiowrite('test.wav', soundWave, 8192);
    
    
    % Graphs %
    subplot(3, 1, 1);
    plot(carrierWave)
    
    subplot(3, 1, 2);
    plot(squareWave);
    
    subplot(3, 1, 3);
    plot(soundWave);
    % % % % % %
    
end
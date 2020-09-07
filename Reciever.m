
%%% BASK Reciever by Ruan %%%

% Instructions:
%   1. Set the desired recordTime
%   2. Start recording 5 seconds before transmitting
%           to give the mic time to "warm up"

% Contructor %
function Reciever()

    clc
    byteSize = 7;
    recordTime = 10; % in seconds
    
    % Get message
    msg = GetAudioData(recordTime);
    
    % Convert message to text
    message = BinaryToText(msg, byteSize);
    
    % Display original message
    fprintf("Original message: \n%s\n", message);
    
end

% Get audio bit stream from recording %
function msg = GetAudioData(time)

    obj = audiorecorder(8192, 8, 1); % Create obj for recording
    record(obj); % Record using the obj from record function (Matlab)
    pause(time);
    rawAudio = getaudiodata(obj, 'double'); %Collect data for graph
    audiowrite('test.wav', rawAudio, 8192);
    
    %[rawAudio,~] = audioread('test.wav');
    
    % Filter %
    % Find the most frequencies and centre around it
    y = rawAudio/8000;
    x = abs(fft(y));
    nums = length(y);
    vals = 0 : 1 / (nums/2 - 1) : 1;
    x = x(1:nums/2);
    max_X = max(x);

    for i = 1:length(x)
        if (x(i) == max_X)
            centre = vals(i);
            break;
        end
    end

    radius = 0.007;
    lower = centre - radius;    upper = centre + radius;

    [b,a] = butter(2, [lower upper], 'bandpass');
    filtered = filtfilt(b, a, rawAudio);

    % Envelope detector %
    [b,a] = butter(2, 0.01, 'low');
    envelope = filtfilt(b, a, abs(filtered));


    % Start at first peak of preamble %
    [pk, lk] = findpeaks(envelope);

    for i = 1:length(pk)
        if (pk(i) > mean(envelope))
            envelope = envelope(lk(i):end);
            %==================
            rawAudio = rawAudio(lk(i):end);
            %==================
            break;
        end
    end


    % Normalizer %
    normal = envelope / max(envelope);
    normalized = normal - (max(normal) / 3);
    [pk, lk] = findpeaks(normalized);


    % Square wave %
    squared = square(normalized);


    % Timing of preamble %
    l_start = 1;
    curState = 1;
    index = 1;
    lengths = zeros(1, 6);
    curLength = 0;

    for i = 1:length(squared)

        if (squared(i) ~= curState) % state change

            curState = squared(i);
            curLength = i - l_start;
            l_start = i;

            % compare lengths
            if (index > 1)
                disp("CHEKC");
                l = lengths(index - 1);
                lower = l - l*0.5;
                upper = l + l*0.5;
                if (curLength > lower) && (curLength < upper)
                    lengths(index) = curLength;
                    index = index + 1;
                    if (index > 6) % if index is grater than 6 we know we are done
                        break;
                    end
                else
                    lengths(1) = curLength;
                    index = 2;
                end
            else
                lengths(1) = curLength;
                index = 2;
            end

        end

    end

    timing = round(mean(lengths), 0);
    if (timing < 290 || timing > 310)
        timing = 300;
    end

    % Get bitstream %
    % Check middle values of each bit according to the timing
    curIndex = lk(1);
    bits = "";
    bitval = 0;

    while (true)

        % Break if message is done
        if (curIndex > length(normalized))
            break;
        end

        % Get value of current bit
        if (normalized(curIndex) > 0)
            bitval = 1;
        else
            bitval = 0;
        end

        % expand final message
        bits = bits + bitval;
        curIndex = curIndex + timing; 

    end
    
    % Remove preamble %
    bits = char(bits);
    for i = 1:length(bits)
        
        testbyte = "";
        for j = i:i+6
            testbyte = testbyte + bits(j);
        end
        
        if (testbyte == "1111111")
            bits = bits(i+7:end);
            break;
        end
        
    end    
    
    % Remove EOT character %
    for i = length(bits):-1:1
       
        testbyte = "";
        for j = i-6:i
            testbyte = testbyte + bits(j);
        end
        
        if (testbyte == "0000100")
            bits = bits(1:i-7);
            break;
        end
        
    end
    
    % The final bits %
    msg = bits;

    
    % PLOTS %

    % % % % % % % % %  Filter Process  % % % % % % % % %
    figure(2)

    ax1 = subplot(5,1,1);
    plot(rawAudio);

    ax2 = subplot(5,1,2);
    plot(filtered);

    ax4 = subplot(5,1,3);
    plot(normalized);

    ax5 = subplot(5,1,4);
    plot(squared);
    % % % % % % % % % % % % % % % % % % % % % % % % % % %


    % % % % % % % % %  Original vs square  % % % % % % % % %
    figure(3);
    hold on
    plot(rawAudio, 'c');
    plot(squared, 'r');
    plot(normalized, 'k');
    % % % % % % % % % % % % % % % % % % % % % % % % % % % % %


end

% Convert binary string to text string %
function message = BinaryToText(msg, byteSize)

    % Devide binary string into segments of 7 bits
    x = strlength(msg) / byteSize;
    temp = char(msg);
    message = "";

    % Convert each binary segment into a character
    for i = 1:x
        section = "";
        for j = 1:byteSize
            section = section + temp(1,j + ((i-1)*byteSize));
        end
        message = message + char(bin2dec(section));
    end
    
end
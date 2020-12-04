userInput = input('Enter hexadecimal value for the bit pattern: ', 's');
binVal = hexToBinaryVector(userInput); % change HEX to BIN
numericValues = double(binVal); % change Logical to Numerical values

% replace all 0 with -1 as required by the AFG3102 signal generator
for i = 1 : length(numericValues)
    if (numericValues(i) == 0)
        numericValues(i) = -1;
    end    
end
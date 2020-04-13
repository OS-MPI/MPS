function [Out] = DigitalDiscretize_V1(In,ResolutionBit)
LSB = 2^(-(ResolutionBit-1)); %Least Significant Bit if the greatest bit is 1
Out = round(In/LSB)*LSB;
end
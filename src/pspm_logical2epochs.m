function epochs = pspm_logical2epochs(index, sr)
% ● Description
%   logical2pspm_epochs converts a logical index vector into an nx2 
%   onset/offset epoch matrix.
% ● Format
%   epochs = logical2pspm_epochs(index, sr)
% ● Arguments
%   *        index : [logical] index vector of length datalength
%   *           sr : sample rate used when index was created
%                    
% ● Outputs
%   *       epochs : nx2 (onset/offset) epoch matrix
% ● History
%   Written in 2024 by Bernhard Agoué von Raußendorf

    
% Compute the differences between consecutive elements in the index array,
% with padding at the start and end
diff_index = diff([0; index(:); 0]);

% Onsets are where the difference is 1 (0 to 1 transition)
onsets = find(diff_index == 1);

% Offsets are where the difference is -1 (1 to 0 transition)
offsets = find(diff_index == -1);

% Combine onsets and offsets into an nx2 matrix
epochs = double([onsets, offsets]);

% If the sample rate (sr) is not 1, convert indices back to time
if nargin > 1 && sr ~= 1
    epochs = (epochs - 1) / sr;
end
end
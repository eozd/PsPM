classdef pspm_butter_test < matlab.unittest.TestCase
  % ● Description
  % unittest class for the pspm_butter function
  % ● History
  % (C) 2019 Ivan Rojkov (University of Zurich)
  methods (Test)
    function invalid_input(this)
      global settings;
      if isempty(settings), pspm_init; end
      settings.signal = 0;
      % Verify not enough input
      this.verifyWarning(@() pspm_butter(), 'ID:invalid_input');
      % Verify that pass is either 'high' or 'low'
      this.verifyWarning(@() pspm_butter(1,1,'abc'), 'ID:invalid_input');
      % Verify that Signal processing toolbox is missing #1
      this.verifyWarning(@() pspm_butter(2,1), 'ID:toolbox_missing');
      % Verify that Signal processing toolbox is missing #2
      this.verifyWarning(@() pspm_butter(1,1), 'ID:toolbox_missing');
    end
  end
end

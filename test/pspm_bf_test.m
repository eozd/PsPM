classdef pspm_bf_test < matlab.unittest.TestCase
  % -------------------------------------------------------------------------
  % Testfunction to test the generic settings of a basis function.
  % The generic settings are:
  %
  % [y,x] = pspm_bf_<name>(td,<more args>)
  % [y,x] = pspm_bf_<name>([td,<more args>])
  %__________________________________________________________________________
  % PsPM TestEnvironment
  % (C) 2015 Tobias Moser (University of Zurich)
  % Update 2021 Teddy Chao (WCHN, UCL)
  
  properties(Constant)
    basis_function_prefix = 'pspm_bf_';
  end
  
  properties
    bf;
  end
  
  properties(MethodSetupParameter)
    % Parameters for TestMethodSetup
    basis_function = {'FIR', 'hprf', 'hprf_e', ...
      'hprf_fc', 'lcrf_gm', 'ldrf_gm', 'ldrf_gu', 'scrf', 'rarf_fc', ...
      'psrf_fc', 'rarf_e', 'rarf_fc', 'rfrrf_e', 'rprf_e', 'sebrf',...
      'spsrf_box'};
  end
  
  properties(TestParameter)
    time_res_log = num2cell(-2:2);
  end
  
  methods(TestMethodSetup)
    function set_basis_function(this, basis_function)
      fh_str = [this.basis_function_prefix, basis_function];
      this.bf = str2func(fh_str);
    end
  end
  
  methods(Test)
    
    function invalid_input(this)
      % test with no parameters
      this.verifyWarning(@() this.bf(), 'ID:invalid_input');
      % test with td > duration
      % get duration
      [~, t] = this.bf(0.1);
      dur = numel(t)*0.1;
      % test with td > duration
      td = dur + 1;
      this.verifyWarning(@() this.bf(td), 'ID:invalid_input');
      % test with td = 0
      this.verifyWarning(@() this.bf(0), 'ID:invalid_input');
    end
    
    function test_basic(this, time_res_log)
      % test function for all basis functions
      
      % try to find out duration
      td = 0.1;
      [~, t] = this.verifyWarningFree(@() this.bf(td));
      dur = numel(t)*td;
      
      % calculate expected amount of returned elements with new td setting
      td = 0.01;
      n2 = dur/td;
      
      % call function and test if returned number of elements equals the
      % expected number of elements
      [~, t] = this.verifyWarningFree(@() this.bf(td));
      this.verifyEqual(n2, numel(t));
      
      % test if the timepoints begin at either zero or at below zero -
      % which then would cause a bfshift in glm
      [~, t] = this.verifyWarningFree(@() this.bf(td));
      this.verifyTrue(t(1) <= 0);
      
      % test time res log if dur > 10^time_res_log
      td = 10^time_res_log;
      if dur > td
        [~, ~] = this.verifyWarningFree(@() this.bf(td));
      end
      
      % test pspm_bf_spsrf_box
      if isequal(this.bf,@pspm_bf_spsrf_box)
        td = 0.1;
        this.verifyWarningFree(@() this.bf(td));
        this.verifyWarningFree(@() this.bf([td,3.5]));
        this.verifyWarningFree(@() this.bf(td,3.5));
      end
    end
  end
end
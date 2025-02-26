classdef (Abstract) pspm_get_superclass < pspm_testcase
  % ● Description
  %   Abstract superclass for the pspm_get_<datatype>_test classes. All the testclasses
  %   for the file import functions (pspm_get_<datatype>_test) must inherit this
  %   class and implement its abstract methods and properties.
  properties (Abstract)
    testcases;
    fhandle;
  end
  methods (Abstract)
    define_testcases(this)
  end
  methods (Static)
    function import = assign_chantype_number(import)
      global settings;
      if isempty(settings), pspm_init; end
      for m = 1:numel(import)
        import{m}.typeno = find(strcmpi(import{m}.type, {settings.channeltypes.type}));
      end
    end
  end
  methods (TestClassSetup)
    function init(this)
      define_testcases(this);
      global settings
      if isempty(settings), pspm_init; end
      % assign channel type number
      for k = 1:numel(this.testcases)
        for m = 1:numel(this.testcases{k}.import)
          this.testcases{k}.import{m}.typeno = find(strcmpi(this.testcases{k}.import{m}.type, {settings.channeltypes.type}));
        end
      end
    end
  end
  methods (Test)
    function valid_datafile(this)
      global settings;
      if isempty(settings), pspm_init; end
      fprintf('\n');
      for k = 1:numel(this.testcases)
        [sts, import, sourceinfo] = this.fhandle(this.testcases{k}.pth, this.testcases{k}.import);
        this.verifyEqual(sts, 1, sprintf('Status is negativ in testcase %i', k));
        if isprop(this, 'blocks') && this.blocks
          blkno = numel(sourceinfo);
          this.verifyEqual(blkno, this.testcases{k}.numofblocks, sprintf('Wrong number of blocks in testcase %i', k));
          % check if number of blocks is equal in sourceinfo and
          % import
          this.verifyEqual(numel(import), numel(sourceinfo), ...
          sprintf('Number of blocks differs between sourceinfo and import in testacase %i',k));
        else
          blkno = 1;
          import = {import};
          sourceinfo = {sourceinfo};
        end
        for blk = 1:blkno
          if blkno > 1, fprintf('\n\tProcess block %i. ', blk); end
          this.verifyNumElements(import{blk}, numel(this.testcases{k}.import), ...
          	sprintf('The number of elements of ''import'' does not match in testcase %i', k));
          for m = 1:numel(this.testcases{k}.import)
            % test if data exists and has correct datatype
            this.verifyTrue(isfield(import{blk}{m}, 'data'), ...
            	sprintf('There is no field ''data'' in importjob %i in testcase %i', m, k));
            this.verifyTrue(isnumeric(import{blk}{m}.data) || islogical(import{blk}{m}.data), ...
            	sprintf('The field ''data'' in importjob %i in testcase %i is not numeric', m, k));
            this.verifyTrue(isvector(import{blk}{m}.data), ...
            	sprintf('The field ''data'' in importjob %i in testcase %i is not a vector', m, k));
            % check if sr exists and has a correct datatype
            this.verifyTrue(isfield(import{blk}{m}, 'sr'), ...
            	sprintf('There is no field ''sr'' in importjob %i in testcase %i', m, k));
            this.verifyTrue(isnumeric(import{blk}{m}.sr), ...
            	sprintf('The field ''sr'' in importjob %i in testcase %i is not numeric', m, k));
            this.verifyTrue(numel(import{blk}{m}.sr) == 1, ...
            	sprintf('The field ''sr'' in importjob %i in testcase %i is not a number', m, k));
            % check if there is a field type
            this.verifyTrue(isfield(import{blk}{m}, 'type'), sprintf('There is no field ''type'' in importjob %i in testcase %i', m, k));
            % if data is of kind event check if there is field
            % marker present
            if strcmpi(settings.channeltypes(this.testcases{k}.import{m}.typeno).data, 'events')
              this.verifyTrue(isfield(import{blk}{m}, 'marker'), sprintf('There is no field ''marker'' in event importjob %i in testcase %i', m, k));
            end
            % check if sr is within a possible range
            if strcmpi(settings.channeltypes(this.testcases{k}.import{m}.typeno).data, 'wave') || ...
            	strcmpi(import{blk}{m}.marker, 'continuous')
              this.verifyTrue(1 <= import{blk}{m}.sr && import{blk}{m}.sr <= 10000, ...
              	sprintf('The samplerate of wave importjob %i in testcase %i is out of the range [1,10000]', m, k));
              this.verifyTrue(numel(import{blk}{m}.data) / import{blk}{m}.sr <= 3600, ...
              	sprintf('The duration of the data of wave importjob %i in testcase %i is longer then 3600s', m, k))
            elseif strcmpi(settings.channeltypes(this.testcases{k}.import{m}.typeno).data, 'events') && ...
            	(strcmpi(import{blk}{m}.marker, 'timestamps') || strcmpi(import{blk}{m}.marker, 'timestamp'))
              this.verifyTrue(10^-6 <= import{blk}{m}.sr && import{blk}{m}.sr <= 1, ...
              sprintf('The samplerate of event importjob %i in testcase %i is out of the range [10^-6,1]', m, k));
              this.verifyTrue(max(import{blk}{m}.data) * import{blk}{m}.sr <= 3600, ...
              sprintf('The duration of the data of wave importjob %i in testcase %i is longer then 3600s', m, k))
            else
              warning('Invalid channel type! (settings.channeltypes.data{%i} is neither ''wave'' nor ''events'')', channeltype);
            end
            if strcmpi(settings.channeltypes(this.testcases{k}.import{m}.typeno).data, 'events') && ...
            (strcmpi(import{blk}{m}.marker, 'timestamps') || strcmpi(import{blk}{m}.marker, 'timestamp'))
              duration = import{blk}{m}.data(end);
            else
              duration = numel(import{blk}{m}.data) / import{blk}{m}.sr;
            end
            % issue warning if duration is less than 10 seconds
            if duration < 1
              warning('The amount of data in channel %g corresponds to less than 1 seconds.', m);
            end
          end
          if strcmpi(settings.channeltypes(this.testcases{k}.import{1}.typeno).data, 'events') && ...
          (strcmpi(import{blk}{1}.marker, 'timestamps') || strcmpi(import{blk}{1}.marker, 'timestamp'))
            duration = import{blk}{1}.data(end);
          else
            duration = numel(import{blk}{1}.data) / import{blk}{1}.sr;
          end
          fprintf('The samplerate of importjob 1 is %g and the duration is %gs.', import{blk}{1}.sr, duration);
        end
        fprintf('\n');
      end
    end
  end
end
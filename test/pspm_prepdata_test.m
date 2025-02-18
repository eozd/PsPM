classdef pspm_prepdata_test < matlab.unittest.TestCase
  % ● Description
  % unittest class for the pspm_prepdata function
  % ● Authorship
  % (C) 2013 Linus Rüttimann (University of Zurich)
  properties
  end
  methods
    function filter_test(this, data, filt)
      %unidirectional test
      filt.direction = 'uni';
      [sts, outdata, newsr] = pspm_prepdata(data, filt);
      this.verifyTrue(sts == 1, 'sts is negativ (at unidirectional test)');
      this.verifyTrue(newsr == filt.sr, 'newsr != filt.sr (at unidirectional test)');
      this.verifyTrue(~isempty(outdata), 'outdata is empty (at unidirectional test)');
      this.verifyTrue(length(outdata) == length(data), 'The length of outdata is not equal to the length of data (at unidirectional test)');
      %bidirectioanal test
      filt.direction = 'bi';
      [sts, outdata, newsr] = pspm_prepdata(data, filt);
      this.verifyTrue(sts == 1, 'sts is negativ (at bidirectional test)');
      this.verifyTrue(newsr == filt.sr, 'newsr != filt.sr (at bidirectional test)');
      this.verifyTrue(~isempty(outdata), 'outdata is empty (at bidirectional test)');
      this.verifyTrue(length(outdata) == length(data), 'The length of outdata is not equal to the length of data (at bidirectional test)');
    end
  end
  methods (Test)
    function invalid_input(this)
      filt.sr = 100;
      filt.lpfreq = 100;
      filt.lporder = 1;
      filt.hpfreq = 50;
      filt.direction = 'uni';
      filt.down = 'none';
      data = rand(100, 1);
      this.verifyWarning(@()pspm_prepdata([1 NaN 3]), 'ID:invalid_input'); %NaN values in data
      this.verifyWarning(@()pspm_prepdata([1 2 3]), 'ID:invalid_input');
      this.verifyWarning(@()pspm_prepdata(data, filt), 'ID:invalid_input');  %missing hporder field
      filt.hporder = 1;
      this.verifyWarning(@()pspm_prepdata('foo', filt), 'ID:invalid_input'); %no numeric data
      filt.lpfreq = 'foo';
      this.verifyWarning(@()pspm_prepdata(data, filt), 'ID:invalid_input'); %no valid lpfreq field
    end
    function lowpassfilter_test(this)
      data = rand(1000,1);
      filt.sr = 100;
      filt.lpfreq = 40;
      filt.lporder = 1;
      filt.hpfreq = 'none';
      filt.hporder = 1;
      filt.down = 'none';
      this.filter_test(data, filt);
      filt.hpfreq = NaN;
      this.filter_test(data, filt);
      filt.lpfreq = 60;
      filt.direction = 'uni';
      this.verifyWarning(@()pspm_prepdata(data, filt), 'ID:no_low_pass_filtering');
    end
    function hipassfilter_test(this)
      data = rand(1000,1);
      filt.sr = 100;
      filt.lpfreq = 'none';
      filt.lporder = 1;
      filt.hpfreq = 20;
      filt.hporder = 1;
      filt.down = 'none';
      this.filter_test(data, filt);
      filt.lpfreq = NaN;
      this.filter_test(data, filt);
    end
    function bandpassfilter_test(this)
      filt.sr = 200;
      filt.lpfreq = 99;
      filt.lporder = 1;
      filt.hpfreq = 20;
      filt.hporder = 1;
      filt.down = 'none';
      data = rand(filt.sr * 10,1);
      this.filter_test(data, filt);
    end
    function int_sr_ratio_downsample_test(this)
      ratio = 2; %ratio between filt.sr and filt.down
      filt.down = 100;
      filt.sr = ratio * filt.down;
      filt.lpfreq = 40;
      filt.lporder = 1;
      filt.hpfreq = 'none';
      filt.hporder = 1;
      filt.direction = 'uni';
      data = rand(filt.sr * 10,1);
      [sts, outdata, newsr] = pspm_prepdata(data, filt);
      this.verifyTrue(sts == 1, 'sts is negativ');
      this.verifyTrue(newsr == filt.down, 'newsr != filt.sr');
      this.verifyTrue(~isempty(outdata), 'outdata is empty');
      this.verifyTrue(ratio*length(outdata) == length(data), sprintf('The length of outdata (%i) is invalid', length(outdata)));
    end
    function int_sr_downsample_test(this)
      filt.down = 100;
      filt.sr = 150;
      filt.lpfreq = 40;
      filt.lporder = 1;
      filt.hpfreq = 'none';
      filt.hporder = 1;
      filt.direction = 'uni';
      data = rand(filt.sr * 10,1);
      [sts, outdata, newsr] = pspm_prepdata(data, filt);
      this.verifyTrue(sts == 1, 'sts is negativ');
      this.verifyTrue(newsr == filt.down, 'newsr != filt.sr');
      this.verifyTrue(~isempty(outdata), 'outdata is empty');
    end
    function nonint_sr_downsample_test(this)
      filt.down = 100.5;
      filt.sr = 150;
      filt.lpfreq = 40;
      filt.lporder = 1;
      filt.hpfreq = 'none';
      filt.hporder = 1;
      filt.direction = 'uni';
      data = rand(filt.sr * 10,1);
      [sts, outdata, newsr] = this.verifyWarning(@()pspm_prepdata(data, filt), 'ID:freq_change');
      this.verifyTrue(sts == 1, 'sts is negative');
      this.verifyTrue(newsr == round(filt.down), 'newsr != filt.sr');
      this.verifyTrue(~isempty(outdata), 'outdata is empty');
    end
    function below_nyquist_downsample_test(this)
      filt.down = 60;
      filt.sr = 150;
      filt.lpfreq = 40;
      filt.lporder = 1;
      filt.hpfreq = 'none';
      filt.hporder = 1;
      filt.direction = 'uni';
      data = rand(filt.sr * 10,1);
      [sts, outdata, newsr] = this.verifyWarning(@()pspm_prepdata(data, filt), 'ID:freq_change');
      this.verifyTrue(sts == 1, 'sts is negativ');
      this.verifyTrue(newsr == 2*filt.lpfreq, 'newsr != 2*filt.lpfreq');
      this.verifyTrue(~isempty(outdata), 'outdata is empty');
    end
  end
end
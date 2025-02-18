function filtered_data = pspm_leaky_integrator(data, tau)
% ● Description
%   pspm_leaky_integrator applies a leaky integrator filter to the input data
% ● Arguments
%   * data: A numerical vector representing the input signal to be filtered.
%   * tau: The time constant of the leaky integrator, representing the
%        leak rate. The leak constant defines how quickly previous values
%        "leak out" of the integrator (or decay). A higher tau value
%        results in slower decay, meaning the integrator has a longer memory.
% ● Outputs
%   * filtered_data: The filtered signal, of the same size as the input data,
%                 processed by the leaky integrator.

    % Initialize the filteredData vector with the same size as input data
    filtered_data = zeros(size(data));
    % Start with the first value of the input data
    filtered_data(1) = data(1);
    % Apply the leaky integrator formula to each data point
    for i = 2:length(data)
        filtered_data(i) = filtered_data(i - 1) + (data(i) - filtered_data(i - 1)) / tau;
    end
end

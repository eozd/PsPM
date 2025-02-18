function v = pspm_struct2vec(S, field, warningtype)
% ● Description
%   pspm_struct2vec turns a numerical field in a multi-element structure
%   array into a numerical vector. If in every element of the structure 
%   array, the field has one element, this returns the same output as
%   [S(:).field]. If fields ar empty or have more than one element, the
%   output vector will be made to have the same number of elements as S,
%   and a warning will be thrown. 
% ● Format
%   v = pspm_struct2vec(S, field, warningtype)
% ● Arguments
%   *           S : a structure array.
%   *       field : name of a numerical field.
%   * warningtype : ['marker' or 'generic'] Type of warning to the displayed
%                   for the user.
% ● Output
%   *     v : numerical vector.
% ● History
%   Introduced in PsPM 7.0
%   Written in 2024 Dominik R Bach (Uni Bonn)

if nargin < 3 || strcmpi(warningtype, 'generic')
    warningstr = 'Element';
else
    warningstr = 'Marker value';
end

% for loops are faster than arrayfun
n = numel(S);
v = NaN(n, 1);
for k = 1:n
    if numel(S(k).(field)) == 1
        v(k) = S(k).(field);
    elseif numel(S(k).(field)) > 1
        v(k) = S(k).(field)(1);
        warning('pspm_struct2vec:MultiField','%s #%01.0f contained more than one entry. Only the first one will be retained.\n', warningstr, k);
    else
        warning('pspm_struct2vec:EmptyField','%s #%01.0f contained no entry and will be assigned NaN.\n', warningstr, k);
    end
end



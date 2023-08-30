function [logical_ids, row_ids] = getIds(keys, TimeSeries)
%GET_IDS Get row-ids for certain keywords
%
% Inputs:
%   keys = 1D cell array; each cell contains a keyword to match
%   TimeSeries = matrix; TimeSeries matrix from HCTSA file
%
% Outputs:
%   logical_ids = 1D logical vector; 1s correspond to rows in TimeSeries
%       which have to required keywords
%   row_ids = 1D vector; holds rows in TimeSeries which have the required
%       keywords

% SUB_cell2cellcell() is a HCTSA function which converts table column of
%   csv strings into a column of cells, each cell containing a cell array
%   with each cell containing a csv value
keywords = SUB_cell2cellcell(TimeSeries.Keywords);
ids = ones(size(keywords));

for k = 1 : length(keys)
    key = keys{k};
    ids = ids & cellfun(@(x) any(ismember(key, x)), keywords);
end

logical_ids = ids;
row_ids = find(ids);

end


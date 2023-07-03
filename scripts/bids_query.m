BIDSDIR = 'D:\Download\data\workshop\BIDS\BIDS';

reproaPath = 'D:\Projects\reproanalysis';

%%
addpath(fullfile(reproaPath,'external','bids-matlab'));

%% Query
BIDS = bids.layout(BIDSDIR);

% entities
bids.query(BIDS, 'entities')

% levels
bids.query(BIDS, 'subjects')
bids.query(BIDS,'sessions')
bids.query(BIDS,'runs')

% data
bids.query(BIDS, 'suffixes')
bids.query(BIDS, 'modalities')
bids.query(BIDS, 'tasks')

% - specific
bids.query(BIDS, 'runs', 'suffix', 'meg')

%% Get data

% images
bids.query(BIDS, 'data', 'sub', '15909001', 'suffix', 'T1w')
bids.query(BIDS, 'data', 'sub', '15909001', 'suffix', 'meg')
bids.query(BIDS, 'data', 'sub', '15909001', 'run', '3', 'suffix', 'meg')

% metadata
bids.query(BIDS, 'metadata', 'sub', '15909001', 'run', '3', 'suffix', 'meg')


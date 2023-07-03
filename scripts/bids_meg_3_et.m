%% Your data
ETDIR = 'D:\Download\data\workshop\BIDS\MEG\ET_DATA';
ETFORMAT = 'et_data_[0-9]{8}\.asc'; % subj#

BIDSDIR = 'D:\Download\data\workshop\BIDS\MEG\BIDS';

% Your environment
reproaPath = 'D:\Projects\reproanalysis';
SPMPath = 'D:\Programs\spm12';
FTPath = 'D:\Programs\fieldtrip';

%% Init tools
% load SPM
addpath(fullfile(reproaPath,'external','toolboxes'));
addpath(fullfile(reproaPath,'external','bids-matlab'));
SPM = spmClass(SPMPath); SPM.load();
FT = fieldtripClass(FTPath); FT.load();

%% BIDS for the dataset
cfg = [];
cfg.bidsroot = BIDSDIR;
cfg.method = 'convert'; % the original data is in a BIDS-compliant format and can simply be copied

cfg.InstitutionName             = 'University of Nottingham';
cfg.InstitutionalDepartmentName = 'School of Psychology';
cfg.InstitutionAddress          = 'University Park Campus, Nottingham, NG7 2RD, United Kingdom';

% required for dataset_description.json
cfg.dataset_description.Name                = 'demo dataset';
cfg.dataset_description.BIDSVersion         = 'v1.5.0';

% optional for dataset_description.json
cfg.dataset_description.License             = 'MIT';
cfg.dataset_description.Authors             = {'Joaquin Gonzalez' 'Matias Ison'};
cfg.dataset_description.ReferencesAndLinks  = {'https://doi.org/some_paper'};
cfg.dataset_description.EthicsApprovals     = {'UoN Ethics ID'};

cfg.eyetracker.Columns = {'time' 'x' 'y' 'dil'};
cfg.eyetracker.StartTime = 0; % delta

cfg.TaskDescription = 'Hybrid (memory and visual) search task';
cfg.task = 'hybridsearch';

%% Loop through data
cfg.datatype = 'eyetracker';
for dsdir = cellstr(spm_select('FPListRec',ETDIR,ETFORMAT))'
    cfg.dataset = dsdir{1}; % this is the intermediate name
    cfg.sub = regexp(spm_file(dsdir{1},'basename'),'[0-9]{8}','once','match');

    data2bids(cfg);
end

%% Correct for validator
% dataset
json = ft_read_json(fullfile(BIDSDIR,'dataset_description.json'));
json.GeneratedBy = {json.GeneratedBy};
ft_write_json(fullfile(BIDSDIR,'dataset_description.json'),json);

% eyetracker
for f = cellstr(spm_select('FPListRec',BIDSDIR,'.*_eyetracker.tsv'))'
    gzip(f{1},spm_file(f{1},'path'));
    delete(f{1});
end
for f = cellstr(spm_select('FPListRec',BIDSDIR,'.*_eyetracker.*'))'
    movefile(f{1},strrep(f{1},'_eyetracker','_recording-eyetracking_physio'));
end
for f = cellstr(spm_select('FPListRec',BIDSDIR,'.*_scans.tsv'))'
    scans = readcell(f{1},'FileType','text','Delimiter',' ');
    for s = find(contains(scans,'eyetracker.tsv'))
        scans{s} = strrep(scans{s},'_eyetracker.tsv','_recording-eyetracking_physio.tsv.gz');
    end
    writecell(scans,f{1},'FileType','text');
end

% events
for f = cellstr(spm_select('FPListRec',BIDSDIR,'.*_events.tsv'))'
    tsv = ft_read_tsv(f{1});
    if any(strcmp(tsv.Properties.VariableNames,'type'))
        tsv.Properties.VariableNames{strcmp(tsv.Properties.VariableNames,'type')} = 'trial_type';
        ft_write_tsv(f{1},tsv);
    end    
end


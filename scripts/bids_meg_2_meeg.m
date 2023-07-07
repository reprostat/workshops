%% 
CTFDIR = 'D:\Download\data\workshop\BIDS\MEG\CTF_DATA';
DSFORMAT = '[0-9]{8}_[a-zA-Z]*_[0-9]{8}_[0-9]{2}\.ds'; % subj#_prot_date_run#

BIDSDIR = 'D:\Download\data\workshop\BIDS\MEG\BIDS';

reproaPath = 'D:\Projects\reproanalysis';
SPMPath = 'D:\Programs\spm12';
FTPath = 'D:\Programs\fieldtrip';

%% Init tools
addpath(fullfile(reproaPath,'external','toolboxes'));
addpath(fullfile(reproaPath,'external','bids-matlab'));
SPM = spmClass(SPMPath); SPM.load();
FT = fieldtripClass(FTPath); FT.load();

%% BIDS for the dataset
cfg = [];
cfg.bidsroot = BIDSDIR; 
cfg.method = 'copy'; % the original data is in a BIDS-compliant format and can simply be copied

cfg.InstitutionName             = 'University of Nottingham';
cfg.InstitutionalDepartmentName = 'School of Psychology';
cfg.InstitutionAddress          = 'University Park Campus, Nottingham, NG7 2RD, United Kingdom';

% required for dataset_description.json
cfg.dataset_description.Name                = 'demo dataset';
cfg.dataset_description.BIDSVersion         = 'v1.5.0';

% optional for dataset_description.json
cfg.dataset_description.License             = 'MIT';
cfg.dataset_description.Authors             = {'Joaquin Gonzalez'};
cfg.dataset_description.ReferencesAndLinks  = {'https://doi.org/some_paper'};
cfg.dataset_description.EthicsApprovals     = {'UoN Ethics ID'};

cfg.meg.PowerLineFrequency = 50;
cfg.meg.DewarPosition = 'upright';
cfg.meg.SoftwareFilters = 'n/a';
cfg.meg.DigitizedLandmarks = false;
cfg.meg.DigitizedHeadPoints = false;

cfg.TaskDescription = 'Hybrid (memory and visual) search task';
cfg.task = 'hybridsearch';

%% Loop through data
cfg.datatype = 'meg';
for dsdir = cellstr(spm_select('FPListRec',CTFDIR,'dir',DSFORMAT))'
    cfg.dataset = dsdir{1}; % this is the intermediate name
    cfg.sub = regexp(spm_file(dsdir{1},'basename'),'^[0-9]{8}','once','match');
    cfg.run = str2double(regexp(spm_file(dsdir{1},'basename'),'[0-9]{2}$','once','match'));

    data2bids(cfg);
end

%% Correct for validator
% dataset
json = bids.util.jsondecode(fullfile(BIDSDIR,'dataset_description.json'));
json.GeneratedBy = {json.GeneratedBy};
bids.util.jsonwrite(fullfile(BIDSDIR,'dataset_description.json'),json);

% electrodes.tsv
writecell({'*_electrodes.tsv'},fullfile(BIDSDIR,'.bidsignore.txt'));
movefile(fullfile(BIDSDIR,'.bidsignore.txt'),fullfile(BIDSDIR,'.bidsignore'))

% events
for f = cellstr(spm_select('FPListRec',BIDSDIR,'.*_events.tsv'))'
    tsv = ft_read_tsv(f{1});
    tsv.Properties.VariableNames{strcmp(tsv.Properties.VariableNames,'type')} = 'trial_type';
    ft_write_tsv(f{1},tsv);
end


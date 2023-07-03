%% 
MRIDIR = 'D:\Download\data\workshop\BIDS\MRI\MRI_DATA';
MRIFORMAT = '[0-9]{5}_[0-9]{3}'; % subj_sess
PROTOCOLS = {'anat' 'sMPRAGEs3' 'sub-%s_ses-%s_T1w';...
             'func' 'RSfMRI' 'sub-%s_ses-%s_task-rest_echo-%%e_bold';...
             'perf' 'SOURCE' 'sub-%s_ses-%s_asl';...
             'perf' 'M0' 'sub-%s_ses-%s_m0scan';...
             'fmap' 'A_SE' 'sub-%s_ses-%s_dir-a_epi';...
             'fmap' 'P_SE' 'sub-%s_ses-%s_dir-p_epi'};

BIDSDIR = 'D:\Download\data\workshop\BIDS\MRI\BIDS';

CONVBIN = 'dcm2niix.exe'; % in the current folder

reproaPath = 'D:\Projects\reproanalysis';
SPMPath = 'D:\Programs\spm12';

%% Init tools
addpath(fullfile(reproaPath,'external','toolboxes'));
addpath(fullfile(reproaPath,'external','bids-matlab'));
SPM = spmClass(SPMPath); SPM.load();

%% Init dataset
bids.init(BIDSDIR)

% Dataset description
fn = fullfile(BIDSDIR, 'dataset_description.json');
json = bids.util.jsondecode(fn);
json.Name                = 'demo dataset';
json.BIDSVersion         = 'v1.8.0';

% optional for dataset_description.json
json.License             = 'MIT';
json.Authors             = {'Sue Francis' 'Denis Schluppeck'};
json.ReferencesAndLinks  = {'https://doi.org/some_paper'};
json.EthicsApprovals     = {'UoN Ethics ID'};
bids.util.jsonwrite(fn,json);

%% Convert
participants = {};
scans = cell(0,3);
for dcmdir = cellstr(spm_select('FPListRec',MRIDIR,'dir',MRIFORMAT))'
    subjsess = strsplit(spm_file(dcmdir{1},'basename'),'_');
    [subj, sess] = deal(subjsess{:});

    % collect participants for BIDS
    participants{end+1,1} = ['sub-' subj];
    scans{end+1,1} = ['sub-' subj];
    scans{end,2} = ['ses-' sess];
    scans{end,3} = {};

    % convert each sequence
    for p = 1:size(PROTOCOLS,1)
        NIFTIDIR = fullfile(BIDSDIR,['sub-' subj],['ses-' sess],PROTOCOLS{p,1});
        if ~exist(NIFTIDIR,'dir'), mkdir(NIFTIDIR); end
        srcDir = fullfile(spm_select('FPListRec',dcmdir{1},'dir',['.*' PROTOCOLS{p,2} '.*']),'resources','DICOM','files');

        % convert
        fnameRoot = sprintf(PROTOCOLS{p,3},subj,sess);
        system(sprintf('%s -o %s -f %s -b 1 -z 1 %s',...
                       CONVBIN, NIFTIDIR, fnameRoot, srcDir));
        for fn = cellstr(spm_select('List',NIFTIDIR,[regexprep(fnameRoot,'%[a-z]','.*') '.nii.gz']))'
            scans{end,3}{end+1,1} = fullfile(PROTOCOLS{p,1},fn{1});
        end

        % update JSONs
        for fn = cellstr(spm_select('FPList',NIFTIDIR,[regexprep(fnameRoot,'%[a-z]','.*') '.json']))'
            json = bids.util.jsondecode(fn{1});
            json = renameStructField(json,'EstimatedTotalReadoutTime','TotalReadoutTime');
            json = renameStructField(json,'PhaseEncodingAxis','PhaseEncodingDirection');
            if contains(fn{1},'dir-a'), json.PhaseEncodingDirection = 'j+';
            elseif contains(fn{1},'dir-p'), json.PhaseEncodingDirection = 'j-';
            end
            bids.util.jsonwrite(fn{1},json);
        end
    end
end

%% Create files for BIDS
% Participants
writetable(table(participants,'VariableName',{'participant_id'}),fullfile(BIDSDIR,'participants.tsv'),'FileType','text');

% Scans 
for sess = 1:size(scans,1)
    writetable(table(strrep(scans{sess,3},filesep,'/'),'VariableName',{'filename'}),fullfile(BIDSDIR,scans{sess,1},scans{sess,2},[scans{sess,1} '_' scans{sess,2} '_scans.tsv']),'FileType','text');
end

% Task (rest)
bids.util.jsonwrite(fullfile(BIDSDIR,'task-rest_bold.json'),struct('TaskName', 'Rest'));

% Missing ASL metadata (double-check!!!)
for subj = participants' % workaround
    bids.util.jsonwrite(fullfile(BIDSDIR,subj{1},[subj{1} '_asl.json']),struct('ArterialSpinLabelingType','PCASL',...
                                                            'PostLabelingDelay',0,... % madeup
                                                            'BackgroundSuppression',true,... % madeup
                                                            'M0Type','Separate',...
                                                            'SliceTiming',[],... % madeup
                                                            'LabelingDuration',1,...
                                                            'RepetitionTimePreparation',4.55)); % madeup
    bids.util.jsonwrite(fullfile(BIDSDIR,subj{1},[subj{1} '_m0scan.json']),struct('RepetitionTimePreparation',4.55)); % madeup
    
    % _aslcontext.tsv is also needed. See https://bids-specification.readthedocs.io/en/stable/04-modality-specific-files/01-magnetic-resonance-imaging-data.html#_aslcontexttsv
end
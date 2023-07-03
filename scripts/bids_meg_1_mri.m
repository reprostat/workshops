%% 
MRIDIR = 'D:\Download\data\workshop\BIDS\MEG\MRI_DATA';
MRIFORMAT = '[0-9]{8}'; % subj
PROTOCOLS = {'WIP_sMPRAGEs3' 'T1w';...
             'T2W_TSE_32chSHC' 'T2w'};

BIDSDIR = 'D:\Download\data\workshop\BIDS\MEG\BIDS';

CONVBIN = 'dcm2niix.exe'; % in the current folder

reproaPath = 'D:\Projects\reproanalysis';
SPMPath = 'D:\Programs\spm12';

%% Init tools
addpath(fullfile(reproaPath,'external','toolboxes'));
addpath(fullfile(reproaPath,'external','bids-matlab'));
SPM = spmClass(SPMPath); SPM.load();

%% Init dataset
bids.init(BIDSDIR)

%% Convert
participants = {};
scans = cell(0,2);
for dcmdir = cellstr(spm_select('FPList',MRIDIR,'dir',MRIFORMAT))'
    subj = spm_file(dcmdir{1},'basename');

    % collect participants for BIDS
    participants{end+1,1} = ['sub-' subj];
    scans{end+1,1} = ['sub-' subj];
    scans{end,2} = {};

    NIFTIDIR = fullfile(BIDSDIR,['sub-' subj],'anat');
    if ~exist(NIFTIDIR,'dir'), mkdir(NIFTIDIR); end
    
    % convert
    system(sprintf('%s -o %s -f %s -b 1 -z 1 %s',...
                   CONVBIN,...
                   NIFTIDIR,...
                   ['sub-' subj '_%p'],...
                   fullfile(dcmdir{1},'DICOM')));
    
    % refine
    for p = 1:size(PROTOCOLS,1)
        for f = cellstr(spm_select('List',NIFTIDIR,['.*' PROTOCOLS{p,1} '.*']))'
            newFn = fullfile(NIFTIDIR,strrep(f{1},PROTOCOLS{p,1},PROTOCOLS{p,2}));
            movefile(fullfile(NIFTIDIR,f{1}), newFn);
            
            % collect scans for BIDS
            if endsWith(newFn,'nii.gz'), scans{end,2}{end+1,1} = strrep(newFn,[fullfile(BIDSDIR,['sub-' subj]) filesep],''); end
        end
    end
end

%% Create files for BIDS
writetable(table(participants,'VariableName',{'participant_id'}),fullfile(BIDSDIR,'participants.tsv'),'FileType','text');
for subj = 1:size(scans)
    writetable(table(strrep(scans{subj,2},filesep,'/'),'VariableName',{'filename'}),fullfile(BIDSDIR,scans{subj,1},[scans{subj,1} '_scans.tsv']),'FileType','text');
end
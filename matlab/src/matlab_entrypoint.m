function matlab_entrypoint(varargin)

% Just quit, if requested - needed for docker build
if numel(varargin)==1 && strcmp(varargin{1},'quit') && isdeployed
    disp('Exiting as requested')
    exit
end

% Filenames are hard coded so we can rely on them in the post-matlab part
% of the processing
inp = struct( ...
    'fmri_niigz','/INPUTS/fmri.nii.gz', ...
    'fmri_json','/INPUTS/fmri.json', ...
    't1_niigz','/INPUTS/t1.nii.gz', ...
    't1_json','/INPUTS/t1.json', ...
    'out_dir','/OUTPUTS' ...
    );
disp(inp)

% Unzip the fmri and run the actual pipeline
gunzip(inp.fmri_niigz)
inp.fmri_nii = strrep(inp.fmri_niigz,'.gz','');

batch_preprocess(inp);

batch_alff(inp);


% Exit
if isdeployed
    exit
end

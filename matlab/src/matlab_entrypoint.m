function matlab_entrypoint(varargin)

% Just quit, if requested - needed for docker build
if numel(varargin)==1 && strcmp(varargin{1},'quit') && isdeployed
    disp('Exiting as requested')
    exit
end

% Parse inputs. Filenames used should be these defaults so we can rely on
% them in the post-matlab part of the processing
P = inputParser;
addOptional(P,'fmri_niigz','/INPUTS/fmri.nii.gz')
addOptional(P,'fmri_json','/INPUTS/fmri.json')
addOptional(P,'t1_niigz','/INPUTS/t1.nii.gz');
addOptional(P,'t1_json','/INPUTS/t1.json');
addOptional(P,'slicetiming','ascend');
addOptional(P,'filetype','dGSRwrafmri.nii');
addOptional(P,'out_dir','/OUTPUTS');
parse(P,varargin{:});
inp = P.Results;
disp(inp)


% Unzip the fmri and run the actual pipeline
gunzip(inp.fmri_niigz)
inp.fmri_nii = strrep(inp.fmri_niigz,'.gz','');
gunzip(inp.t1_niigz)
inp.t1_nii = strrep(inp.t1_niigz,'.gz','');

batch_preprocess(inp);

batch_alff(inp);


% Exit
if isdeployed
    exit
end

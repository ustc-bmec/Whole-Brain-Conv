% function design = make_design_cnv(cfg,mFoldCross)
%
% Modified from decoding.m of the TDT toolbox
% Function to generate design matrix for cross validation using the
% decoding toolbox. This function uses a "n-fold cross validation" cross
% validation method.
%
% IN
%   cfg.files.chunk: a vector, one chunk number for each file in
%       cfg.files.name. Chunks can be used to keep data together in
%       decoding iterations, e.g. when cross-validation should be
%       performed across runs.
%   cfg.files.label: a vector, one label number for each file in
%       cfg.files.name
%   cfg.files.set (optional): a vector, one set number for each file in
%       cfg.files.name. This variable is used to run several different
%       decodings at once. This might be useful e.g. if they overlap.
%   mFoldCross: define the n of n-fold cross validation
%
%
% OUT
%   design.label: matrix with one column for each CV step, containing a
%       label for each image used for decoding (a replication of the vector
%       cfg.files.label across CV steps)
%   design.train: binary matrix with one column for each CV step, containing
%       a 1 for each image used for training in this CV step and 0 for all
%       images not used
%   design.test: same as in design.train, but this time for all test images
%   design.set: 1xn vector, describing the set number of each CV step
%   design.function: Information about function used to create design
%
%
%
% See also: make_design_xclass.m, make_design_xclass_cv.m,
%   make_design_boot_cv.m
%
% By: Kai Goergen & Martin Hebart, 2010/06/13
%
% See also MAKE_DESIGN_BOOT_CV, MAKE_DESIGN_XCLASS, MAKE_DESIGN_PERMUTATION

% History:
% - Gululu: leave n out cross validation -- 19-03-03
% - removed bug with multiple sets MH: 16-12-01
% - throwing error if cfg.files.xclass is not empty
% - introduced sets variable MH: 11-06-13
% - Changed fieldname cfg.cond to cfg.label, output of train and test
%   to be binary and label names to be separately provided (more general
%   purpose) MH: 10-08-01
% - MH: Made more general to allow steps that don't go from 1:n to be
%   cross-validated


function design = make_design_cnv(cfg,mFoldCross)

%% generate design matrix (CV)

design.function.name = mfilename;
design.function.ver = 'v20140107';

% Downward compatibility (cfg.files.chunk used to be called cfg.files.step)
if isfield(cfg.files,'step')
    if isfield(cfg.files,'chunk')
        if any(cfg.files.step-cfg.files.chunk)
        error('Both cfg.files.step and cfg.files.chunk were passed. Not sure which one to use, because both are different')
        end
    else
        cfg.files.chunk = cfg.files.step;
        cfg.files = rmfield(cfg.files,'step');
    end
    warningv('MAKE_DESIGN_CV:deprec','Use of cfg.files.step is deprecated. Please change your scripts to cfg.files.chunk.')
end

if isfield(cfg.files, 'xclass') && ~isempty(cfg.files.xclass)
    error(sprintf(['xclass for standard cross-validation design\n' ...
           'You tried to create a standard cross-validation design, but cfg.files.xclass contains data.\n' ...
           'The xclass field is only needed if you want to do cross-set decoding.\n' ...
           'Possible solutions:\n' ...
           '1. For standard cv decoding: set cfg.files.xclass = [] before calling make_design_cv.\n' ...
           '2. For cross-set cross-validation, use make_design_xclass_cv.m instead.']))
end

if ~isfield(cfg.files,'set') || isempty(cfg.files.set)
    cfg.files.set = ones(size(cfg.files.label));
end

% Make sure that input has the right orientation
if size(cfg.files.chunk,1) == 1
    warningv('MAKE_DESIGN:ORIENTATION_CHUNK','cfg.files.chunk has the wrong orientation. Flipping.');
    cfg.files.chunk = cfg.files.chunk';
end
if size(cfg.files.label,1) == 1
    warningv('MAKE_DESIGN:ORIENTATION_LABEL','cfg.files.label has the wrong orientation. Flipping.');
    cfg.files.label = cfg.files.label';
end
if size(cfg.files.set,1) == 1
    warningv('MAKE_DESIGN:ORIENTATION_SET','cfg.files.set has the wrong orientation. Flipping.');
    cfg.files.set = cfg.files.set';
end

n_files = length(cfg.files.chunk);

if n_files ~= length(cfg.files.label)
    error('Number of chunks %i does not fit to number of labels %i. Please make sure both reflect the number of samples.',n_files,length(cfg.files.label))
end

% reorganize the chunks of input files
mFileBeta = numel( cfg.files.name );
iIDSubjs = zeros( 1, mFileBeta );
for iFile = 1 : mFileBeta
    % to get the subj IDs
    cTmpStrParts = strsplit( cfg.files.name{iFile}, '_' );
    iIDSubjs( iFile )= str2double( cTmpStrParts{1} );
end % for iFile
for iFile = mFileBeta:-1:1
    % to organize the chunks
    iTmpMatch = find( cfg.files.chunk(iFile) == cfg.files.chunk, 1 );
    cfg.files.chunk( iFile )= cfg.files.chunk( iTmpMatch );
end % for iFile


%% let's make the disign on the chunks
% get values
% nChunkAll = unique( cfg.files.chunk );
% mChunkAll = numel( nChunkAll );
nSetAll = unique( cfg.files.set );
mSetAll = numel( nSetAll );

% initialize the values
design.train = zeros( mFileBeta, mFoldCross*mSetAll );
design.test = zeros( mFileBeta, mFoldCross*mSetAll );
design.label = repmat(cfg.files.label, 1, mFoldCross*mSetAll );
design.set = zeros( 1,  mFoldCross*mSetAll );


% make the random group
rng( 3487 );
for iSet = 1 : mSetAll
    % to get the temp chunks in the set
    nTmpChunk = unique( cfg.files.chunk( cfg.files.set == nSetAll( iSet ) ) );
    mTmpChunk = numel( nTmpChunk );

    iRnds = randperm( mTmpChunk );
    nGroups = ceil( iRnds/( mTmpChunk/mFoldCross ) );

    % do it
    for iFold = 1 : mFoldCross
        design.set( (iSet-1)*mFoldCross + iFold )= nSetAll( iSet );
        for iChunk = 1 : mTmpChunk
            design.train( cfg.files.chunk == nTmpChunk(iChunk), iFold)= ...
                double( iFold ~= nGroups(iChunk) );
            design.test( cfg.files.chunk == nTmpChunk(iChunk), iFold)= ...
                double( iFold == nGroups(iChunk) );
        end % for iChunk
    end % for iFold
end % for iSet

% introduce check that no column of design.train is zeros only
emptyind = find(sum(design.train)==0);
if ~isempty(emptyind)
    error('Empty decoding steps found in design in step(s) %s. Maybe you have only one chunk and want to do cross-validation (which doesn''t make sense).',num2str(emptyind));
end


msg = 'Design for CV decoding for %i files x %i steps created\n';
if check_verbosity(msg,1)
    dispv(1, msg, n_files, mFoldCross)
end

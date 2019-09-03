% function [results, cfg, passed_data, misc] = decoding_par(cfg, passed_data, misc)
%
% Modified from decoding.m of the TDT toolbox
% The Decoding Toolbox, Version: 3.995, by Martin Hebart & Kai Goergen
%
% This is the main function of The Decoding Toolbox which links to all
% subfunctions performed for brain image decoding. This toolbox is capable
% of running several different brain image decoding analyses (searchlight
% decoding, region of interest (ROI) decoding, and wholebrain decoding).
% Several commonly used methods are implemented, including classification,
% regression, and correlation.
% The toolbox has several subfunctions to which new methods can easily be
% appended for individual adjustments (see tutorial for details).
%
% To get started, type "help decoding_example" and run that function
% to perform a standard decoding analysis (searchlight, ROI, or wholebrain)
% on your specified data.
%
% Please see LICENSE.txt on how to cite us (Hebart, Goergen, et al, 2015).
%
% REQUIRED INPUT:
%   cfg: Structure containing all necessary configuration information
%       Required fields:
%           files: Information about the input files.
%               cfg.files must contain
%           files.name: Full path to each input file
%           files.descr: (optional) description of each file (e.g. the SPM
%               regressor name)
%
%           design: Design matrix with entries label, train, test, and set
%               (see folder 'design' for example functions on how to
%               generate a design and the necessary structure).
%           design.train: n_files x n_steps matrix, specifying the files
%               used as training data for each decoding step (e.g. run)
%           design.test: n_files x n_steps matrix, specifying the files
%               used as test data for each decoding step (e.g. run)
%           design.label: n_files x n_steps matrix, specifying the labels
%               of each file for each decoding step (e.g. run)
%           design.set: 1 x n vector, describing the set number of each
%               step. The set number can also be used to save results of each
%               decoding_step independently (see cfg.results.setwise).
%       Alternatively, you can create the design in this function by
%       providing the following field:
%           design.function.name: string named after the design creation
%               function that should be used (e.g. 'make_design_cv'). Check
%               the folder 'design' for all options. If a design already
%               exists, this field is ignored.
%
% PROGRESS DISPLAY:
%       cfg.plot_selected_voxels: if positive, plots searchlight in 3d.
%           For many ROIs (as is the case for searchlight analyses), this
%           slows down decoding ENORMOUSLY if every step is plotted, but
%           looks nice and might be helpful for bug-tracking.
%           Any number n means:
%               1: plot every step,
%               2: every second step, 100: every hundredth step...
%           Default: 0 (no plotting)
%           cfg.plot_selected_voxels_writerObj (optional): writerObj to
%               store each plotted selected voxel figure, e.g. to create a
%               VIDEO (see "help plot_selected_voxels").
%       cfg.fighandles.plot_selected_voxels (optional): Figure handle to
%           plot selected voxels (updated in background)
%       cfg.display_progress.string: Can contain any string that will be
%           shown in front of the progress display (e.g. 'Bin2/8')
%
% DISPLAY:
%   cfg.plot_design = 1 (default); will plot your design.
%       See decoding_defaults for possible values.
%   cfg.fighandles.plot_design (optional): Figure handle to plot design
%
% OUTPUT:
%   results: 1 x n structure array, containing the decoding results of each
%       of the n requested outputs (see. cfg.results.output)
%       Fields of results:
%           output: contains the results of the decoding analysis (e.g. all
%               searchlight analyses or all ROI analyses)
%           mask_index: contains the brain mask indices of all masks in
%               case they are needed again.
%   cfg: returns the configuration file that was used in the decoding.
%   passed_data: all brain imaging data is necessary to pass to decoding.m
%        to perform another analyses using the same data.
%   misc: miscellaneous data or parameters that can be passed separately (usually
%       quite large, e.g. residuals)
%
%
% All other input is provided in decoding_defaults unless changed.
% The most important of these input fields are:
%   cfg.analysis: Determines the type of analysis that is performed
%       ('searchlight', 'ROI', or 'wholebrain')
%   cfg.decoding.method: method of decoding ('classification', 'regression',
%       or 'classification_kernel' [default = 'classification_kernel', only useful for libsvm]
%   cfg.decoding.software: Software used for decoding [default = 'libsvm']
%   cfg.decoding.train.classification.model_parameters: Model parameters
%       that the external software needs for training [set for libsvm classification]
%   cfg.decoding.test.classification.model_parameters: Model parameter that the external
%       software needs for testing [default = '']
%   cfg.results.write: Should results be written to hard disk
%       (0 = no, 1 = .mat-file and image, 2 = .mat-file) [default = 1]
%   cfg.results.output: 1xn cell array specifying which output should be
%       generated, with possible fields specified in function
%       decoding_transform_results.m  [default = {'accuracy'}]
%   cfg.results.dir: Output directory [default = fullfile(pwd,'decoding_results')]
%   cfg.software: Software used to access images and files [default = 'SPM8']
%
% If searchlight analysis is selected, often the following parameters want
% to be set manually:
%   cfg.searchlight.unit: searchlight unit ('voxels' or 'mm') [default = 'voxels']
%   cfg.searchlight.radius: searchlight radius [default = 4]
%   cfg.searchlight.spherical: should the searchlight be spherical, i.e.
%       should we correct for a non-isotropic voxel [default = 0]
%
% Other optional input includes:
%   cfg.scale: Perform scaling on data (may improve decoding performance)
%       See function 'decoding_scale_data' for details
%   cfg.feature_transformation: Rearranges features and possibly reduces
%       number of dimensions (e.g. PCA)
%   cfg.parameter_selection: Optimize parameters for decoding in nested CV
%       See function 'decoding_parameter_selection' for details
%   cfg.feature_selection: Select most important features (voxels) for
%       decoding. See function 'decoding_feature_selection' for details
%   cfg.searchlight.subset: if you want to execute only a subset of
%       searchlights, you can either enter an Nx1 vector where each value of
%       n corresponds to the index within the searchlight mask is executed
%       (not the voxel index of the whole volume!), or you can enter an
%       Nx3 matrix corresponding to the XYZ coordinates of the volume
%   cfg.decoding.kernel.function: Kernel function passed, (default linear: @(X,Y) X*Y')
%       Will only be used, if cfg.design.method ends on "_kernel"
%   cfg.decoding.kernel.pass_vectors: If 1, the original data will be passed
%       in addition to the kernel as data_train.vectors/data_test.vectors
%   cfg.decoding.use_loaded_results: If 1, training/testing will be
%       skipped, and data from passed_data.loaded_results will be used
%       instead.
%   cfg.results.overwrite: Overwrite existing result file(s) [default = 0]
%   cfg.results.setwise: Save results of each set separately [default = 1]
%   cfg.results.filestart: Manually define start of output filename [default: 'res']
%   cfg.sn: Provide subject number for status messages
%   cfg.verbose: How much output should be printed to the screen
%       (0 = minimum, 1 = normal, 2 = all) [default = 1]
%   cfg.testmode: Test mode, only the first decoding step (e.g. the first
%       searchlight) will be calculated
%   cfg.check_software: Useful to switch check off e.g. for compiling TDT [default = 1]
%
% Explanation of important variables:
%   n_decodings: Number of decoding analyses that are performed, e.g.
%       number of ROIs or number of searchlight voxels.
%   n_steps: Number of decoding steps, e.g. cross-validation iterations.
%       Essentially the number of times a train/test cycle is performed to
%       achieve one results.
%   n_sets: Number of decoding sets which are performed. Essentially a
%       chunking scheme for decoding steps. Several decodings with
%       different outputs may be performed interleaved (e.g. when doing
%       cross-classification with different test data in each set). These
%       could of course be called in different analyses, but it saves
%       time to do them all together, e.g. when they rely on the same
%       training data.
%
%
% PASSING DATA (optional):
% If you pass passed_data, then these will be
% taken instead of reading both from files. Some checks are done to
% make sure that the data fits to the filenames. See HOWTOUSEPASSEDDATA.txt
% on how to use it.
%
% misc (optional):
% Contains miscellaneous data that can be passed (it is
% passed separately from passed_data, because misc can become quite large
% (e.g. when residuals are used).
%
% See also DECODING_DEFAULTS, DECODING_SCALE_DATA,
% DECODING_FEATURE_SELECTION, DECODING_PARAMETER_SELECTION,
% DECODING_FEATURE_TRANSFORMATION

% TODO: repeatedly calculating i_train and i_test across searchlights doesn't
% make sense. Best externalize this which could also be passed to feature
% selection and parameter selection. This would also simplify the check for
% previously identical training data

% HISTORY (only major changes)
% 2019-03 gululu
%   Replaced SVMlib with Matlab fitcecoc
%   Added Matlab parfor
% 2016-07 Martin
%   Added compatibility with AFNI
% 2016-06 Martin
%   Added support for reading 4D files
% 2015-11 Martin
%   Added ensemble classification method for balancing of unbalanced data
%   and for balancing confounds
% 2015-08 Martin
%   Added flexible representational similarity analysis and pattern
%   component modeling capabilities (currently as decoding)
%   added a similarity analysis template
% 2015-07-21 Martin
%   Added misc as new input (e.g. for passing residuals)
%   Allow scaling of each chunk separately
%   Allow scaling using covariance of residuals
%   New function decoding_load_misc to load e.g. residuals
%   New function residuals_from_spm in case residuals haven't been written
%       to files
%   Improved readability of main function
% 2015-07-07 Martin
%   Added multi-ROI capability and possibility to write as nii-nifti
%   (previously: img-nifti only)
% 2015-03-02 Martin
%   Added LDA as classifier and GUI
% 2014-07-31 Kai
%   Added possibility to skip calculating decoding again and use loaded
%   data instead (Flag: cfg.decoding.use_loaded_results = 1; result data in
%   passed_data.loaded_results). See also read_resultdata.m
% 2014-01-07 Martin
%   Renamed cfg.files.step to cfg.files.chunk, because steps (i.e. decoding
%   iterations, e.g. cross-validation steps) can be different from chunks
%   (i.e. data that should be kept together when cross-validation is
%   performed)
%   Externalized basic_checks to decoding_basic_checks and report_results
%   Improved readability and speed of feature_selection
% 2013-09-05 Kai
%   Added passed_data.masks.mask_data{} to provide ROI data.
% 2013-09-05 Kai
%   Changed Kernel passing, now: data_train.kernel/data_test.kernel.
%   Previous version had too much potential for confusion.
%   Original data vectors can be passed additionally using
%   cfg.decoding.kernel.pass_vectors.
% 2013-04-23 Kai
%   Rewrote Kernel related stuff
% 2013-04-22 Martin
%   Added possibility to use kernels
% 2013-04-14 Kai
%   Separated i_decoding into i_decoding and curr_decoding. Detailed
%   explanation what is what below.

%% Main start
function [results, cfg, passed_data, misc] = decoding_par(cfg, passed_data, misc)

%% Prepare decoding analysis

cfg = decoding_defaults(cfg); % set defaults
cfg.feature_transformation = inherit_settings(cfg.feature_transformation,cfg,'analysis','software','verbose','decoding');
cfg.parameter_selection    = inherit_settings(cfg.parameter_selection,cfg,'analysis','software','verbose','decoding');
cfg.feature_selection      = inherit_settings(cfg.feature_selection,cfg,'analysis','software','verbose','decoding');
cfg.feature_selection      = decoding_defaults(cfg.feature_selection);

cfg.progress.starttime = datestr(now);

global verbose % MH: don't worry, Kai, this is the only case where global is better than passing!! ;)
global reports % and this is the second only case (there actually is a third somewhere else)...
verbose = cfg.verbose;
reports = []; % init

% create a SVM template
oTemSvm = templateSVM( 'Standardize', true, 'KernelFunction', 'linear' );

% Display version
ver = 'The Decoding Toolbox (by Martin Hebart & Kai Goergen), v2019/01/23 3.995'; % also change header of this file and in LOG.txt
cfg.info.ver = ver;
dispv(1,ver)
dispv(1,'Preparing analysis: ''%s''',cfg.analysis)

%% Basic checks

[cfg, n_files, n_steps] = decoding_basic_checks(cfg,nargout); %#ok<ASGLU>
if ~exist('misc','var'), misc = []; end

%% Plot and save design as graphics if requested

cfg = tdt_plot_design_init(cfg);

%% Open file to write all filenames that we load

if cfg.results.write
    % Open filename to save details for each decoding step
    inputfilenames_fname = [cfg.results.filestart '_filedetails.txt'];
    inputfilenames_fpath = fullfile(cfg.results.dir,inputfilenames_fname);
    dispv(1,'Writing input filenames for each decoding iteration to %s', inputfilenames_fpath)
    inputfilenames_fid = fopen(inputfilenames_fpath, 'wt');
else
    inputfilenames_fid = '';
end

%% Load masked datacfg

if exist('passed_data', 'var') && ~isempty(passed_data)
    % check that passed_data fits to cfg, otherwise load data from files
    [passed_data, misc, cfg] = decoding_load_data(cfg, misc, passed_data);
else
    % load data the standard way
    [passed_data, misc, cfg] = decoding_load_data(cfg, misc);
end

% unpack all fields from passed_data to shorten names in this function
data = passed_data.data;
mask_index = passed_data.mask_index;
if isfield(passed_data, 'mask_index_each')
    % do nothing
elseif isfield(cfg.files, 'mask') && length(cfg.files.mask) <= 1
    dispv(1, 'Filling passed_data.mask_index_each with data from passed_data.mask_index, because mask_index_each is not provided and one or less masks are used.')
    passed_data.mask_index_each = {passed_data.mask_index};
else
    error('passed_data is used and multiple mask files are provided, but indices of this masks, that should be provided in passed_data.mask_index_each, are not. Please provide these or use only one mask.')
end
mask_index_each = passed_data.mask_index_each;
sz = passed_data.dim;

%% If requested, load miscellaneous data (e.g. residuals or raw data)
misc = decoding_load_misc(cfg, passed_data, misc);

%% Check if result data should be used to only calculate transformations

cfg = tdt_check_transform_only(cfg,passed_data,mask_index);

%% Prepare the decoding

% Scale all data in advance if requested
if strcmpi(cfg.scale.estimation,'all')
    dispv(1,'Scaling all data, using scaling method %s',cfg.scale.method)
    if ~isfield(misc,'residuals')
        data = decoding_scale_data(cfg,data);
    else
        data = decoding_scale_data(cfg,data,[],misc.residuals);
    end
end

% Get number of decodings for searchlight and number of ROIs for ROI (and 1 for wholebrain)
[n_decodings,decoding_subindex] = get_n_decodings(cfg,mask_index,mask_index_each,sz);

% Initialize results vectors
n_outputs = length(cfg.results.output);
cfg.design.n_sets = length(unique(cfg.design.set));

% Set kernel method if used
cfg.decoding.use_kernel = false;
use_kernel = cfg.decoding.use_kernel;

% Prepare searchlight template (sl_template will be empty for other methods than searchlight)
[cfg,sl_template] = decoding_prepare_searchlight(cfg);

% Initialize results vector and save some information to results, including mask_index and n_decodings
results = tdt_prepare_results(cfg,mask_index,passed_data,n_decodings,n_outputs,decoding_subindex);


%% PERFORM Decoding Analysis

dispv(1,'Starting decoding...')

% Save start time (for time estimate)
start_time = now;

% Preloading
msg_length = [];
previous_fs_data = []; % init
kernel = []; % init
nAccu = zeros( 1, n_decodings );

% init states of parameter_selection, feature_selection, and scaling
feature_transformation_all_on = strcmpi(cfg.feature_transformation.estimation,'all');
feature_transformation_across_on = strcmpi(cfg.feature_transformation.estimation,'across');
parameter_selection_on = ~strcmpi(cfg.parameter_selection.method,'none');
feature_selection_on = ~strcmpi(cfg.feature_selection.method,'none');
scaling_iter_on = strcmpi(cfg.scale.estimation,'all_iter');
scaling_across_on = strcmpi(cfg.scale.estimation,'across');
scaling_separate_on = strcmpi(cfg.scale.estimation,'separate');

% Warn if test mode
if cfg.testmode
    warningv('DECODING:testmode','TEST MODE: Only one decoding step is calculated!');
    n_decodings = 1;
end

% Report files
report_files(cfg,n_steps,inputfilenames_fid);

% General remark how final accuracy values are calculated before we start
if cfg.verbose == 1
    dispv(1, 'All samples in final estimate (e.g. accuracy) weighted equally (see README.txt)...')
elseif cfg.verbose == 2
    dispv(2, sprintf(['\n', ...
    'General remark: The final accuracy (and most other measures) for each voxel is calculated by weighting all test examples equally.\n', ...
    'This means that if e.g. one decoding step contains 2 test examples, and another contains 5, the average of all 7 will be taken.\n', ...
    'If you want to weight all decoding steps equally, please use cfg.results.setwise=1 and cfg.design.set = 1:length(cfg.design.set) and average over the resulting output images']))
end

if scaling_separate_on || scaling_iter_on
    dispv(1,'Using scaling estimation type: %s',cfg.scale.estimation)
end

% setup for progress displaying
gFinished = false( 1, n_decodings );
sTemplateDisp = 'OneIter:%5.1fSec\n\b';
disp( 'Progressing~~~' );
mCharNum = length( sprintf( sTemplateDisp, 1 ) );
sRemove = repmat( '\b', [ 1, mCharNum - 2 ] );

% Start
% parfor i_decoding = 1:n_decodings % e.g. voxels for searchlight (decoding_subindex in most cases is 1:n_decodings)

for i_decoding = 1:1 % e.g. voxels for searchlight (decoding_subindex in most cases is 1:n_decodings)
    tic
    curr_decoding = decoding_subindex(i_decoding); % if cfg.searchlight.subset wasn't called, then curr_decoding is identical to i_decoding


    % Get the current maskindices (e.g. of the current searchlight or of the current ROI)
    indexindex = get_ind(cfg,mask_index,curr_decoding,sz,sl_template,passed_data);
    current_data = data(:,indexindex);



    % Loop over design columns (e.g. cross-validation runs)
    cLabelPred = cell( 1, n_steps );
    cLabelTrue = cell( 1, n_steps );
    for i_step = 1:n_steps

        % Get indices for training
        i_train = cfg.design.train(:, i_step) > 0;
        % Get indices for testing
        i_test = cfg.design.test(:, i_step) > 0;

        % Separate current data in training and test data
        [data_train,data_test] = tdt_get_train_test(cfg,current_data,kernel,use_kernel,i_train,i_test);

        labels_train = cfg.design.label(i_train, i_step);
        labels_test = cfg.design.label(i_test, i_step);

        % Skip feature selection and training if training set & training
        % labels are identical to previous iteration (saves time)
        % never skip on first decoding step
        skip_training = false;

        % also skip training if data should be used directly
        if cfg.decoding.use_loaded_results
            if i_decoding == 1 && i_step == 1
                warningv('decoding:skip_training_loading_results', 'NEVER EXECUTING TRAINING because results should be loaded from data (cfg.decoding.use_loaded_results = 1)');
            end
            skip_training = true;
        end


        %%%%%%%%%%%%%%%%%%%%
        % PERFORM DECODING %
        %%%%%%%%%%%%%%%%%%%%

        %   TRAIN DATA    %
        %%%%%%%%%%%%%%%%%%%

        % Do scaling on all used data if requested
        % TODO: include variable set here and rename to scaling within set

        % Do scaling on training set if requested
        if ~skip_training && scaling_across_on
            if i_decoding == 1 && i_step == 1, dispv(1,'Using scaling estimation type: %s',cfg.scale.estimation), end
            [data_train,scaleparams] = decoding_scale_data(cfg,data_train);
        end

        % run the svm decoding
        if ~skip_training
            % e.g. when software is libsvm, then:
            % model = libsvm_train(labels_train,data_train,cfg);
%             oModelSVM = fitcsvm(data_train,labels_train,'KernelFunction','linear');
            oModelSVM = fitcecoc(data_train,labels_train,'Learners', oTemSvm);
        end

        %    TEST DATA    %
        %%%%%%%%%%%%%%%%%%%

        % Do scaling on test data if requested
        if scaling_across_on
            data_test = decoding_scale_data(cfg,data_test,scaleparams); % if skip_training is active, scaleparams from previous iteration are used
        end

        % Test Estimated Model
        if cfg.decoding.use_loaded_results
            % get decoding_out from passed_data
            tTmpDecodOut = get_decoding_out_from_passed_data(cfg,labels_test,passed_data,i_decoding,mask_index(curr_decoding),i_step);
            cLabelPred{ i_step } = tTmpDecodOut.predicted_labels(:);
            cLabelTrue{ i_step } = tTmpDecodOut.true_labels(:);
        else
            % do standard testing
            % e.g. when software is libsvm, then:
            % decoding_out(i_step) = libsvm_test(labels_test,data_test,cfg,model);
            cLabelPred{ i_step } = predict( oModelSVM, data_test );
            cLabelTrue{ i_step } = labels_test(:);
        end

    end % i_step

    %%%%%%%%%%%%%%%%%%%
    % Generate output %
    % This is where result transformations are called
    % (so they can use all decoding steps of the current voxel at once)
    nAccu( i_decoding ) = mean( double( cat(1,cLabelPred{:}) == cat(1,cLabelTrue{:}) ) )*100;
    nTmpDurSec = toc;

    % For display
    fprintf( sRemove );
    fprintf( sTemplateDisp, nTmpDurSec );
end % End decoding iterations (e.g. voxel)

sNamOut = char( cfg.results.output{1} );
nChance = 1/results.n_cond_per_step * 100;
results.(sNamOut).output = nAccu - nChance;

results.accuracy_minus_chance.chancelevel = 1/results.n_cond_per_step * 100;

% done
dispv(1,'All %s steps finished successfully!',cfg.analysis)

%% Save and write results

% TODO: when results are not written, all results are still returned as
% indices, not volumes. Is that desirable?
if cfg.results.write
    % Close txt files to store filenames
    dispv(1,['Closing file to store filenames ' inputfilenames_fname])
    fclose(inputfilenames_fid);
    dispv(1,'done!')

    % Write results
    dispv(1,'Writing results to disk...')
    decoding_write_results(cfg,results)
    dispv(1,'done!')
end

% save end time
cfg.progress.endtime = datestr(now);


%% plot & save design again at the end (to show that job is finished)
% Endtime shows user that job is over
cfg = tdt_plot_design_final(cfg);


%% END OF MAIN FUNCTION


%% SUBFUNCTIONS

function cfg = tdt_plot_design_init(cfg)

try
    if cfg.plot_design == 1 % plot + save fig, save hdl
        cfg.fighandles.plot_design = plot_design(cfg);
        save_fig(fullfile(cfg.results.dir, 'design'), cfg, cfg.fighandles.plot_design);
        drawnow;
    elseif cfg.plot_design == 2 % only save fig, plot invisible, dont save hdl
        fighdl = plot_design(cfg, 0);
        save_fig(fullfile(cfg.results.dir, 'design'), cfg, fighdl);
        close(fighdl); clear fighdl
    end
catch
    warningv('DECODING:PlotDesignFailed', 'Failed to plot design')
end

% show design as text
try display_design(cfg); catch, warningv('DECODING:PrintDesignFailed', 'Failed to print design to screen'), end

%%
function cfg = tdt_check_transform_only(cfg,passed_data,mask_index)

% By default, calculate the data, if not specified otherwise
if ~isfield(cfg.decoding, 'use_loaded_results') || cfg.decoding.use_loaded_results == 0
    cfg.decoding.use_loaded_results = 0; % set default
else
    % check that passed_data contains the loaded results
    if ~isfield(passed_data, 'loaded_results')
        error('cfg specifies that loaded results should be used instead of recomputing them (cfg.decoding.use_loaded_results = 1), but no result data is passed in passed_data.loaded_results. See read_resultdata.m on how to use this feature.')
    end
    % check that mask_index agrees
    if ~isequal(mask_index, passed_data.loaded_results.mask_index)
        error('mask_index in decding does not fit to passed_data.loaded_results.mask_index')
    end

    warningv('decoding:loaded_results_experimental', 'cfg specifies that loaded results should be used instead of recomputing them (cfg.decoding.use_loaded_results = 1). This features is still experimental. Use with care.')
    display('Skip calculating data and using results from passed_data.loaded_results instead.')
end

%%
function results = tdt_prepare_results(cfg,mask_index,passed_data,n_decodings,n_outputs,decoding_subindex)

% initialize results vector
results = {};

% Save analysis type
results.analysis        = cfg.analysis;
% Save number of conditions (e.g. to get the chancelevel later)
results.n_cond          = cfg.design.n_cond;
results.n_cond_per_step = cfg.design.n_cond_per_step;
% Save mask_index
results.mask_index      = mask_index;
% Save all mask indices separately (useful if several masks are provided)
results.mask_index_each = passed_data.mask_index_each;
% Save number of decodings that could be performed
results.n_decodings     = n_decodings;
% save data info (voxel dimensions, size)
results.datainfo        = cfg.datainfo;
% Save subindices if they are provided
if isfield(cfg.searchlight,'subset')
    results.decoding_subindex = decoding_subindex;
end

for i_output = 1:n_outputs
    outname = char(cfg.results.output{i_output}); % char necessary to get name of objects

    if strcmp(cfg.analysis, 'searchlight')
        % use number of voxels to allocate space independent of number of
        % decodings (because cfg.searchlight.subset allows to choose fewer
        % voxels, but we want in the end an image that has the same
        % dimension as the original image)
        n_dim = length(mask_index);  % n_voxel = length(mask_index)
    else
        % otherwise, get as many output dimensions as decodings (no subset
        % selection possible at the moment)
        n_dim = n_decodings;
    end

    % Preallocation
    results.(outname).output = zeros(n_dim,1);

    if cfg.results.setwise && cfg.design.n_sets > 1
        for i_set = 1:cfg.design.n_sets
            results.(outname).set(i_set).output = zeros(n_dim,1);
        end
    end
    clear n_dim
end

%%

function data = tdt_scale_separate(cfg,data,misc,miscindex)

use_misc = ~isempty(misc);

uchunk  = uniqueq(cfg.files.chunk);
for i_chunk = 1:length(uchunk)
    dataind  = cfg.files.chunk==uchunk(i_chunk);
    if use_misc
        residind = cfg.files.residuals.chunk==uchunk(i_chunk);
        data(dataind,:) = decoding_scale_data(cfg,data(dataind,:),[],misc.residuals(residind,miscindex));
    else
        data(dataind,:) = decoding_scale_data(cfg,data(dataind,:));
    end
end

function data = tdt_scale_iter(cfg,data,misc,miscindex)


if isfield(misc,'residuals')
    data = decoding_scale_data(cfg,data,[],misc.residuals(:,miscindex));
else
    data = decoding_scale_data(cfg,data);
end



%%
function cfg = tdt_plot_selected_voxels(cfg, i_decoding, n_decodings, mask_index, indexindex, sz, currdata)

if isfield(cfg, 'plot_selected_voxels') && cfg.plot_selected_voxels > 0 && (cfg.plot_selected_voxels == 1 || mod(i_decoding, cfg.plot_selected_voxels) == 1 || i_decoding == n_decodings)
    if ~isfield(cfg, 'fighandles') || ~isfield(cfg.fighandles, 'plot_selected_voxels')
        cfg.fighandles.plot_selected_voxels = ''; % will be set during call
    end
    try
        % plot searchlight with brain projection
        cfg.fighandles.plot_selected_voxels = plot_selected_voxels(mask_index(indexindex), sz, currdata, mask_index, [], cfg.fighandles.plot_selected_voxels, cfg);
    catch
        warningv('DECODING:PlotSelectedVoxelsFailed', 'plot_selected_voxels failed');
    end
end

%%
function [data_train,data_test] = tdt_get_train_test(cfg,current_data,kernel,use_kernel,i_train,i_test)

% Get data for training & testing at current position
if use_kernel
    % get relevant parts of kernel
    data_train.kernel = kernel(i_train, i_train);
    data_test.kernel = kernel(i_test, i_train);
    % additionally pass original data vectors, if selected
    if cfg.decoding.kernel.pass_vectors
        data_train.vectors = current_data(i_train, :);
        data_test.vectors = current_data(i_test, :);
    end
else
    % no kernel used, set the training vectors as training data
    data_train = current_data(i_train, :);
    data_test = current_data(i_test, :);
end

%%
function cfg = tdt_plot_design_final(cfg)

try
    if cfg.plot_design
        cfg.fighandles.plot_design = plot_design(cfg,1);
        if cfg.results.write
            save_fig(fullfile(cfg.results.dir, 'design'), cfg, cfg.fighandles.plot_design);
        end
    end
catch %#ok<*CTCH>
    warningv('DECODING:PlotDesignFailed', 'Failed to plot design')
end

% To plot each CohenD map using tksurfer
% plot_plotSurfs( DirMain, NamDirInput, NamDirOutput, DirTmp )
function plot_plotSurfs( varargin )

% Basic setups
if nargin > 0
    % parameters
    sDirData = varargin{1};
    sDirOut = varargin{2};
    sFileTcl = fullfile( varargin{3}, 'tmp189.tcl' );
    nThresholdPercMMM = varargin{4};
else
    % for debug
    sDirMain = '/home/gululu/Disks/DataMore/Data2017/ProjBoldNN/Analysis_ForAll_0510';
    sDirData = fullfile( sDirMain, 'Results_ActivityMaps' );
    sDirOut = fullfile( sDirMain, 'Plots_ActivityMaps' );
    sFileTcl = '/home/gululu/Disks/Fast/TMP/tmp189.tcl';
    nThresholdPercMMM = [ 0.95 0.995 ]; % min, max

end

if ~exist( sDirOut, 'dir' )
    mkdir( sDirOut );
end % if ~exist

% get surf lists
tLstDataLH = dir( fullfile( sDirData, '*_lh_s4.func.gii' ) );
mDataLH = numel( tLstDataLH );

% go
% read each LH gii file
for iDataLH = 1 : mDataLH
    % get the data name
    [ csTmpNamSplit, csTmpMatch ]= strsplit( tLstDataLH(iDataLH).name, '_' );
    sTmpNamData = strjoin(strcat(csTmpNamSplit(1:end-2),[csTmpMatch(1:end-2),{''}]),'');
    fprintf( '### %s\n', sTmpNamData );

    % First, read in gii's and get the thresholds
    tTmpDataLH = gifti( fullfile( sDirData, strcat( sTmpNamData, '_lh_s4.func.gii' ) ) );
    tTmpDataRH = gifti( fullfile( sDirData, strcat( sTmpNamData, '_rh_s4.func.gii' ) ) );
    nTmpDataBoth = cat( 1, tTmpDataLH.cdata(:), tTmpDataRH.cdata(:) );
    nThresholdMMM = round( prctile( abs( nTmpDataBoth ), nThresholdPercMMM*100 ), 1 );
%     nThresholdMMM(1) = 1;

    % Second, plot it
    % LH
    % generate the tmp tksurfer script for LH
    hFileTcl = fopen( sFileTcl, 'w' );
    fprintf( hFileTcl, '%s', [ ...
        % set colscalebarflag 1
        sprintf( 'set fthresh %f\n', nThresholdMMM(1) ), ...
        sprintf( 'set fmid %f\n', mean(nThresholdMMM(1:2)) ), ...
        sprintf( 'set fslope %f\n', 1/( nThresholdMMM(2) - nThresholdMMM(1) ) ), ...
        sprintf( 'make_lateral_view\n' ), ...
        sprintf( 'scale_brain 1.20\n'), ...
        sprintf( 'redraw\n' ), ...
        sprintf( 'save_tiff %s%s%s_lh_s4_outer.tif\n', sDirOut, filesep, sTmpNamData ), ...
        sprintf( 'rotate_brain_y 180\n' ), ...
        sprintf( 'redraw\n' ), ...
        sprintf( 'save_tiff %s%s%s_lh_s4_inner.tif\n', sDirOut, filesep, sTmpNamData ), ...
        'exit' ] );
    % do it
    system( sprintf( 'tksurfer fsaverage lh inflated -overlay %s -tcl %s', ...
        fullfile( sDirData, strcat( sTmpNamData, '_lh_s4.func.gii' ) ), ...
        sFileTcl ) );

    % RH
    % generate the tmp tksurfer script for RH
    hFileTcl = fopen( sFileTcl, 'w' );
    fprintf( hFileTcl, '%s', [ ...
        sprintf( 'set fthresh %f\n', nThresholdMMM(1) ), ...
        sprintf( 'set fmid %f\n',mean(nThresholdMMM(1:2)) ), ...
        sprintf( 'set fslope %f\n', 1/( nThresholdMMM(2) - nThresholdMMM(1) ) ), ...
        sprintf( 'make_lateral_view\n' ), ...
        sprintf( 'set colscalebarflag 1\n' ), ... colorbar added
        sprintf( 'scale_brain 1.20\n'), ...
        sprintf( 'redraw\n' ), ...
        sprintf( 'save_tiff %s%s%s_rh_s4_outer.tif\n', sDirOut, filesep, sTmpNamData ), ...
        sprintf( 'rotate_brain_y 180\n' ), ...
        sprintf( 'set colscalebarflag 0\n' ), ... colorbar added
        sprintf( 'redraw\n' ), ...
        sprintf( 'save_tiff %s%s%s_rh_s4_inner.tif\n', sDirOut, filesep, sTmpNamData ), ...
        'exit' ] );
    % do it
    system( sprintf( 'tksurfer fsaverage rh inflated -overlay %s -tcl %s', ...
        fullfile( sDirData, strcat( sTmpNamData, '_rh_s4.func.gii' ) ), ...
        sFileTcl ) );

%     break % for debug
end % foreach File_Data

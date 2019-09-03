% To get cluster locations of each CohenD map using
% anot_anotSurfs( DirMain, DirOutput, nThresholdPercentile, nMinArea )
function annot_annotSurfs( varargin )

% Basic setups
if nargin > 0
    % parameters
    sDirData = varargin{1};
    nThresholdPercMMM = varargin{2};
    nMinArea = varargin{3}; % unit, square minimeter
else
    % for debug
    sDirMain = '/home/gululu/Disks/DataMore/Data2017/ProjBoldNN/Analysis_ForAll_0510';
    sDirData = fullfile( sDirMain, 'Results_ActivityMaps' );
    nThresholdPercMMM = [ 0.95 1 ]; % min, max
    nMinArea = 400; % unit, square minimeter
end

if ~exist( sDirData, 'dir' )
    mkdir( sDirData );
end % if ~exist

% get surf lists
tLstDataLH = dir( fullfile( sDirData, '*WM*_lh_s4.func.gii' ) ); % for debug
% tLstDataLH = dir( fullfile( sDirData, '*_lh_s4.func.gii' ) );
mDataLH = numel( tLstDataLH );

% go
% read each LH gii file
for iDataLH = 1 : mDataLH
    % get the data name
    [ csTmpNamSplit, csTmpMatch ]= strsplit( tLstDataLH(iDataLH).name, '_' );
    sTmpNamData = strjoin(strcat(csTmpNamSplit(1:end-2),[csTmpMatch(1:end-2),{''}]),'');

    % First, read in gii's and get the thresholds
    tTmpDataLH = gifti( fullfile( sDirData, strcat( sTmpNamData, '_lh_s4.func.gii' ) ) );
    tTmpDataRH = gifti( fullfile( sDirData, strcat( sTmpNamData, '_rh_s4.func.gii' ) ) );
    nTmpDataBoth = cat( 1, tTmpDataLH.cdata(:), tTmpDataRH.cdata(:) );
    nThresholdMMM = round( prctile( abs( nTmpDataBoth ), nThresholdPercMMM*100 ), 1 );

    % Second, annotate it
    % LH
    % do it
    system( sprintf( [ ...
        'mri_surfcluster --in %s --subject %s --hemi %s --thmin %f ', ...
        '--no-adjust --sum %s --annot %s --minarea %d' ], ...
        fullfile( sDirData, strcat( sTmpNamData, '_lh_s4.func.gii' ) ), ...
        'fsaverage', 'lh', nThresholdMMM(1), ...
        fullfile( sDirData, strcat( sTmpNamData, '_lh_s4.clust.txt' ) ), ...
        'PALS_B12_Brodmann',  nMinArea ) );

    % RH
    system( sprintf( [ ...
        'mri_surfcluster --in %s --subject %s --hemi %s --thmin %f ', ...
        '--no-adjust --sum %s --annot %s --minarea %d' ], ...
        fullfile( sDirData, strcat( sTmpNamData, '_rh_s4.func.gii' ) ), ...
        'fsaverage', 'rh', nThresholdMMM(1), ...
        fullfile( sDirData, strcat( sTmpNamData, '_rh_s4.clust.txt' ) ), ...
        'PALS_B12_Brodmann',  nMinArea ) );

%     break % for debug
end % foreach File_Data

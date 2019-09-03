% plot figures into 1
function allsub_plotIntoOne( sDirData, sDirOut )
% Basic Setups
close all
if ~exist( 'sDirData', 'var' )
    sDirData = '/home/gululu/Disks/DataMore/Data2017/ProjBoldNN/Analysis_ForAll_0510/Plots_ActivityMaps';
    sDirOut = '/home/gululu/Disks/DataMore/Data2017/ProjBoldNN/Analysis_ForAll_0510/Plots_Finals';
end

sFileOut = fullfile( sDirOut, 'Figure_Alls');
if ~exist( sDirOut, 'dir' )
    mkdir( sDirOut );
end

csGroups = { 'GLM', 'DNN' };
csPrfs = { 'HCP', 'Grad' }; % the prefix of the inputted data for the two groups, separately
% csPrfs = { 'HCP', 'HCP' }; % for debug
mGroups = numel( csGroups );
csTasks = { 'EMOTION' 'GAMBLING' 'LANGUAGE' 'MOTOR' 'RELATIONAL' 'SOCIAL' 'WM' };
csDescripts = { ...
    'Fear vs. baseline',    'Fear heatmap'; ...
    'Loss vs. baseline',    'Loss heatmap'; ...
    'Present story vs. baseline',   'Present story heatmap'; ...
    'Right hand vs. baseline',      'Right hand heatmap'; ...
    'Relation vs. baseline',        'Relation heatmap'; ...
    'Mental vs. baseline',          'Mental heatmap'; ...
    '2bk places vs. baseline',      '2bk-places heatmap' };
nsIndices = 97:122; % a-z, lower case
csIndices = { ...
    'A',    'H'; ...
    'B',    'I'; ...
    'C',    'J'; ...
    'D',    'K'; ...
    'E',    'L'; ...
    'F',    'M'; ...
    'G',    'N' };
mTasks = numel( csTasks );
mTotalAxis = mTasks*mGroups;
hAxis = zeros( mTasks, mGroups );
csImageSeq = { 'lh_s4_outer', 'lh_s4_inner', 'rh_s4_inner', 'rh_s4_outer' };
mImage = numel( csImageSeq );
nSizeImg = [600 600];
nRectPairs = [ 525 420 557 590; 575 420 595 590];
nSizeColorbar = [500 150];
nWidthColorbar = nSizeColorbar(2)/nSizeImg(1);
nOffsetImg = .5*( nSizeImg(1) - nSizeColorbar(1) );
[ iXs, iYs] = meshgrid( 1:nSizeImg(1), 1:nSizeImg(2), 1:3 );

nSizeFigureCm = [ 18 24 ];
% now make the plot grids
nYs = linspace( 0.95, 0.08, mTasks + 1 );
nYs = nYs( 2: end )*nSizeFigureCm(2); % normalized
nXs = linspace( 0.05, 1, mGroups + 1 );
nXs = nXs( 1: end-1 )*nSizeFigureCm(1);
nHeight = 0.65*( nYs(1) - nYs(2) );
nWidth = 0.8*( nXs(2) - nXs(1) );

hGcf = figure;
set( hGcf, 'resize', 'off', ...
    'Units', 'centimeters', 'Position', [ 0 0 nSizeFigureCm ], ...
    'Color', 'black', 'NextPlot', 'add', ...
    'InvertHardcopy', 'off' );


for iAxis = 1 : mTotalAxis
    iGroup = mod( iAxis+1, mGroups )+1;
    iTask = ceil( iAxis/mGroups );
    
    hAxis( iTask, iGroup )= subplot( mTasks, mGroups, iAxis );
    set( gca, 'Units', 'centimeters', ...
        'Position', [ nXs(iGroup), nYs(iTask), nWidth, nHeight ], ...
        'XTick', [], 'YTick', [], 'xlim', [0 4+nWidthColorbar], 'ylim', [0 1], ...
        'color', 'black', ...
        'fontname', 'Arial' );
    hold on;
    
    if iAxis == 1
        text( 0.5, 1.7, csGroups{1}, 'Units', 'Normalized', ...
        'HorizontalAlignment', 'center', ...
        'FontName', 'Arial', 'FontSize', 12, 'FontWeight', 'normal', ...
        'color', 'white' );
    elseif iAxis == 2
        text( 0.5, 1.7, csGroups{2}, 'Units', 'Normalized', ...
        'HorizontalAlignment', 'center', ...
        'FontName', 'Arial', 'FontSize', 12, 'FontWeight', 'normal', ...
        'color', 'white' );
    end % if iAxis==1
        
    
    % the plot name
    title( gca, csDescripts{ iTask, iGroup }, 'Units', 'Normalized', ...
        'HorizontalAlignment', 'left', 'Position', [ 0.025 1 0 ], ...
        'FontName', 'Arial', 'FontSize', 9, 'FontWeight', 'normal', ...
        'color', 'white' );
    % the plot Index
    text( 0.015, 1.15, sprintf('(%s)',nsIndices( iTask + (iGroup-1)*mTasks )), ...
        'Units', 'Normalized', ...
        'HorizontalAlignment', 'right', ...
        'FontName', 'Arial', 'FontSize', 9, 'FontWeight', 'bold', ...
        'color', 'white' );
    % the task
    if iGroup == 1        
        text( 1.1, 1.5, csTasks{ iTask }, 'Units', 'Normalized', ...
            'HorizontalAlignment', 'center', ...
            'FontName', 'Arial', 'FontSize', 10, 'FontWeight', 'normal', ...
            'color', 'white' );
    end % if iGroup = =1
    % coborbar legend
    if iTask == 1
        text( 1, 1, 'Cohen''s D', 'Units', 'Normalized', ...
            'HorizontalAlignment', 'center', ...
            'FontName', 'Arial', 'FontSize', 6, 'FontWeight', 'normal', ...
            'color', 'white' );
    end
    
    % now plot each image on the current axis
    nTmpImage = [];
    for iImage = 1 : mImage
        % read in the images
        tTmpImage = dir( fullfile( sDirData, ...
            sprintf( '%s*%s*%s.tif', csPrfs{ iGroup }, csTasks{ iTask }, csImageSeq{ iImage } ) ) );
        nTmpImageThis = imread( fullfile( tTmpImage(1).folder, tTmpImage(1).name ) );
        if iImage == mImage
            % the last figure, plot the colorbar
            nTmpBar = nTmpImageThis( nRectPairs(1,2): nRectPairs(1,4), ...
                [nRectPairs(1,1):nRectPairs(1,3), nRectPairs(2,1): nRectPairs(2,3) ], : );
            nTmpBarPart = nTmpBar(1:40,1:20, :);
            nTmpBarPart( nTmpBarPart < 100 )= 0;
            nTmpBar( 1:40, 1:20, : )=nTmpBarPart;
            nTmpBar = imresize( nTmpBar, nSizeColorbar );
            nTmpColorbar = uint8( zeros( nSizeImg(1), nSizeColorbar(2),3 ) );
            nTmpColorbar( nOffsetImg+( 1:nSizeColorbar(1) ), :, : )= nTmpBar;
            gNoBrains = ( nTmpImageThis > 100 );
            gMightBrain = ( iXs>=nRectPairs(1,1) & iXs<=nRectPairs(1,1)+40 & ...
                iYs>=nRectPairs(1,2) & iYs<=nRectPairs(1,2)+20 );
            gCrop = ( iXs>=nRectPairs(1,1) & iXs<=nRectPairs(2,3) & ...
                iYs>=nRectPairs(1,2) & iYs<=nRectPairs(2,4) );
            nTmpImageThis( xor( gMightBrain, gCrop) | ( gMightBrain & gNoBrains ) ) = 0;
            nTmpImageThis = cat( 2, nTmpImageThis, nTmpColorbar );
            
        end % if iImage
        if isempty( nTmpImage )
            nTmpImage = nTmpImageThis;
        else
            nTmpImage = cat( 2, nTmpImage, nTmpImageThis );
        end
        
    end % for iImage
    % plot the images
    imshow( nTmpImage, 'XData', [0 4+nWidthColorbar], 'YData', [0 1] );
    
    
    pause(0.1);
%     break % for debug
end % for iAxis

export_fig( sFileOut, '-r600', '-jpg' );
print( gcf, '-dsvg', sFileOut );

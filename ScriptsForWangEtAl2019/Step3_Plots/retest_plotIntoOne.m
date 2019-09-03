% plot figures into 1
function retest_plotIntoOne( sDirData, sDirOut )
% Basic Setups
close all
if nargin < 1
    sDirData = '/home/gululu/Disks/DataMore/Data2017/ProjBoldNN/Analysis_ForAll_0510/Plots_TestRetestMaps';
    sDirOut = '/home/gululu/Disks/DataMore/Data2017/ProjBoldNN/Analysis_ForAll_0510/Plots_Finals';
end
if ~exist( sDirOut, 'dir' )
    mkdir( sDirOut );
end


ccTasks = { ...
    {'MOTOR_lf' 'MOTOR_rf' 'MOTOR_lh' 'MOTOR_t' ; ...
    'MOTOR_lf' 'MOTOR_rf'  'MOTOR_lh' 'MOTOR_t' ; ...
    'Motor_lf' 'Motor_rf'  'Motor_lh' 'Motor_t'}, ...
    { 'WM_0bk-body' 'WM_2bk-body'; ...
    'WM_0bk-body' 'WM_2bk-body' ; ...
    'WM_0bk-body' 'WM_2bk-body' } };
ccDescripts = { ...
    { 'Left foot vs. baseline',    'Left foot heatmap',    'Left foot F1 Score'; ...
    'Right foot vs. baseline',    'Right foot heatmap',    'Right foot F1 Score'; ...
    'Left hand vs. baseline',    'Left hand heatmap',    'Left hand F1 Score'; ...
    'Tongue vs. baseline',    'Tongue heatmap',    'Tongue F1 Score'}, ...
    {'0bk-body vs. baseline',   '0bk-body heatmap',   '0bk-body F1 Score'; ...
    '2bk-body vs. baseline',   '2bk-body heatmap',   '2bk-body F1 Score'} };
csColobarLegend = { 'Cohen''s D', 'Cohen''s D', 'F1 Score (%)' };
nsIndices = 97:122; % a-z, lower case
mStats = numel( ccTasks );
csKeyTest = { 'Retest' };
nSizeImg = [600 600];
nRectPairs = [ 525 420 557 590; 575 420 595 590];
nSizeColorbar = [500 150];
nWidthColorbar = nSizeColorbar(2)/nSizeImg(1);
nOffsetImg = .5*( nSizeImg(1) - nSizeColorbar(1) );
[ iXs, iYs] = meshgrid( 1:600, 1:600, 1:3 );

for iTest = 1 : 1
    sKeyTest = csKeyTest{ iTest };
    
    for iStat = 1 : mStats
        
        close all
        
        csTasks = ccTasks{iStat};
        csDescripts = ccDescripts{iStat};
        
        sFileOut = fullfile( sDirOut, ['Figure_TestRetests_' sKeyTest '_' csTasks{1}] );
        
        csGroups = { 'GLM', 'DNN', 'MVPA' };
        csPfxs = { 'HCP-Cope', 'Grad', 'Searchlight' }; % the prefix of the inputted data for the two groups, separately
        % csPfxs = { 'HCP', 'HCP' }; % for debug
        mGroups = numel( csGroups );
        mTasks = size( csTasks, 2 );
        mTotalAxis = mTasks*mGroups;
        hAxis = zeros( mTasks, mGroups );
        csImageSeq = { 'lh_s4_inner', 'lh_s4_outer', 'rh_s4_inner', 'rh_s4_outer' };
        mImage = numel( csImageSeq );
        
        if iStat == 1
            nSizeFigureCm = [ 18 24 ];
        else
            nSizeFigureCm = [ 18 12 ];
        end % if iStat
        
        % now make the plot grids
        nYs = linspace( 0.95, 0.08, mTasks + 1 );
        nYs = nYs( 2: end )*nSizeFigureCm(2); % normalized
        nXs = linspace( 0.05, 1, mGroups + 1 );
        nXs = nXs( 1: end-1 )*nSizeFigureCm(1);
        nHeight = 0.75*( nYs(1) - nYs(2) );
        nWidth = 0.8*( nXs(2) - nXs(1) );
        
        hGcf = figure;
        set( hGcf, 'resize', 'off', ...
            'Units', 'centimeters', 'Position', [ 0 0 nSizeFigureCm ], ...
            'Color', 'k', 'NextPlot', 'add', ...
             'InvertHardcopy', 'off' );
        
        
        for iAxis = 1 : mTotalAxis
            iGroup = mod( iAxis-1, mGroups )+1;
            iTask = ceil( iAxis/mGroups );
            
            hAxis( iTask, iGroup )= subplot( mTasks, mGroups, iAxis );
            set( gca, 'Units', 'centimeters', ...
                'Position', [ nXs(iGroup), nYs(iTask), nWidth, nHeight ], ...
                'XTick', [], 'YTick', [], 'xlim', [0 2+nWidthColorbar], 'ylim', [0 2], ...
                'color', 'black' );
            hold on;
            
            if iAxis < 4
                text( 0.4, 1.3, csGroups{iAxis}, 'Units', 'Normalized', ...
                    'HorizontalAlignment', 'center', ...
                    'FontName', 'Arial', 'FontSize', 12, 'FontWeight', 'normal', ...
                    'color', 'white' );
            end % if iAxis==1
            
            
            % the plot name
            title( gca, csDescripts{ iTask, iGroup }, 'Units', 'Normalized', ...
                'HorizontalAlignment', 'left', 'Position', [ 0.02 1.05 0 ], ...
                'FontName', 'Arial', 'FontSize', 9, 'FontWeight', 'normal', ...
                'color', 'white' );
            % the plot Index               
            text( -0.05, 1.1, sprintf('(%s)',nsIndices( iTask + (iGroup-1)*mTasks )), 'Units', 'Normalized', ...
                'HorizontalAlignment', 'right', ...
                'FontName', 'Arial', 'FontSize', 12, 'FontWeight', 'bold', ...
                'color', 'white' );
            % Hemisphere and colobar legend
            if iTask == 1
                text( 1, 1, csColobarLegend{iGroup} , 'Units', 'Normalized', ...
                    'HorizontalAlignment', 'center', ...
                    'FontName', 'Arial', 'FontSize', 8, 'FontWeight', 'normal', ...
                    'color', 'white' );
            elseif iTask == mTasks
                xlabel( 'LH           RH         ', ...
                    'FontName', 'Arial', 'FontSize', 9, 'FontWeight', 'normal', ...
                    'color', 'white' );
            end 
%             % the task
%             if iGroup == 2
%                 text( -0.12, 1.4, csTasks{ iGroup, iTask }, 'Units', 'Normalized', ...
%                     'HorizontalAlignment', 'center', ...
%                     'FontName', 'Arial', 'FontSize', 10, 'FontWeight', 'normal', ...
%                     'color', 'white', 'interpreter', 'none' );
%             end % if iGroup = =1
            
            % now plot each image on the current axis
            nTmpImage = zeros( [ nSizeImg*2, 3 ] );
            for iImage = 1 : mImage
                % read in the images
                tTmpImage = dir( fullfile( sDirData, ...
                    sprintf( '%s*%s_%s*%s.tif', csPfxs{ iGroup }, sKeyTest, csTasks{ iGroup, iTask }, csImageSeq{ iImage } ) ) );
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
                end % if iImage
                iImgX = mod( iImage,2 );
                iImgY = ceil( iImage/2 )-1;
                nTmpImage( ...
                    (1:nSizeImg(1)) + iImgX*nSizeImg(1), ... 
                    (1:nSizeImg(2)) + iImgY*nSizeImg(2), : )= ...
                    nTmpImageThis;
                if iImage == mImage
                    nTmpImage = cat( 2, nTmpImage, imresize( nTmpColorbar, 2 ) );
                end % if iImage
              
            end % for iImage
            
            % plot the images
            imshow( nTmpImage, 'XData', [0 2+nWidthColorbar], 'YData', [0 2] );
            
            
            pause(0.1);
            %     break % for debug
        end % for iAxis
        export_fig( sFileOut, '-r600', '-jpg' );
        pause(0.2);
        print( gcf, '-dsvg', sFileOut );
%         break % debug
    end % for iStat
%     bread % debug
end % for iTest

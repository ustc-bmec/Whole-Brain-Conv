% the main script for generating all sub average brain activity maps
% plz replace the file pathes in basic setups with yours.
% 2019-05   Xiaoxiao    wrote it

% Basic setups
sDirMain = './';
sDirTmp = './TMP';
csDirGrads = { ...
    './Visualize_MOTOR_vis_4_24_with_logsoft/Retest', ...
    './Visualize_WM_vis_4_24_with_logsoft/Retest' };
sDirMaxGrads = fullfile( sDirMain, 'MaxSignGradients_TestRetests' );
sDirNormMaxGrads = fullfile( sDirMain, 'NormMaxSignGradients_TestRetests' );
sDirResults = fullfile( sDirMain, 'Results_TestRetestMaps' );
sDirPlots = fullfile( sDirMain, 'Plots_TestRetestMaps' );
sDirPlotFinals = fullfile( sDirMain, 'Plots_Finals' );
sDirCopes = fullfile( sDirMain, 'Copes_HCP' );
csDirFScore = { ...
      './HCP_SVM_TestRetest_Motor/DecodingOutputsMotor_20190626T182320/Vali-1' , ...
      './HCP_SVM_TestRetest_WM/DecodingOutputsWM_20190702T153403/Vali-1' };
ccKeyFScore = { {'lf' 'lh' 'rf' 't'} {'0bkbody' '2bkbody'} };
csTasks = { 'rf' 'lf' 'lh' 't' '0bk-body' '2bk-body' };
sKeyTest = 'Retest';

sTmpFileScript = mfilename( 'fullpath' );
sDirScript = fileparts( sTmpFileScript );

disp( 'step 1, get maxis' );
for iDir = 1 : numel( csDirGrads )
    system( [ sDirScript, '/retest_getGradsMax', ' ', csDirGrads{iDir}, ...
        ' ', sDirMaxGrads, ' ', sDirTmp ] );
end

disp( 'step 2, get 4mm smoothed surf of gradients' );
system( [ sDirScript, '/allsub_getGradsSurfS4', ' ', sDirMaxGrads, ' ', sDirTmp ] );
system( [ sDirScript, '/allsub_getGradNormMaxSignSurf', ...
    ' ', sDirMaxGrads, ' ', sDirNormMaxGrads, ' ', sDirTmp ] );

disp( 'step 3, get 4mm smoothed surf of HCP and Searchlight' );
system( [ sDirScript, '/retest_makeRetestCopesS4'] ); % for HCP
for iDir = 1 : numel( csDirFScore )
    % for searchlight
    sLstTasks = [ '(''', strjoin( ccKeyFScore{iDir}, ''' '''), ''')' ];
    system( [ 'Lst=', sLstTasks, '; ', sDirScript, '/retest_getFScore', ...
        ' ', csDirFScore{iDir}, ' "${Lst[*]}" ', sDirResults ] );
end % for iDir
system( [ sDirScript, '/allsub_getGradsSurfS4', ' ', sDirResults, ' ', sDirTmp ] ); % for searchlight


disp( 'step 4, get CohenD of all right surfs' );
sLstTasks = [ '(''', strjoin( csTasks, ''' '''), ''')' ];
system( [ 'Lst=', sLstTasks, '; ', sDirScript, '/retest_getCohenDSurfRightS4', ...
    ' ', sDirNormMaxGrads, ' ', sDirResults, ' ', sDirTmp, ' "${Lst[*]}"' ] );
system( [ 'Lst=', sLstTasks, '; ', sDirScript, '/retest_getCohenDSurfCopeS4', ...
    ' ', sDirCopes, ' ', sDirResults, ' ', sDirTmp, ' "${Lst[*]}"' ] );


disp( 'step 4, plot all these figures' );
plot_plotSurfs( sDirResults, sDirPlots, sDirTmp, [0.95 1] ); % to plot
annot_annotSurfs( sDirResults, [0.95 1], 400 )% to annotate

disp( 'step 5, plot figures into one figure' );
retest_plotIntoOne( sDirPlots, sDirPlotFinals );

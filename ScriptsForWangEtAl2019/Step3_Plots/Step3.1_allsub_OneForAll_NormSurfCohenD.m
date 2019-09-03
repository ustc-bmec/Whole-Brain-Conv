% the main script for generating all sub average brain activity maps
% plz replace the file pathes in basic setups with yours.
% 2019-05   Xiaoxiao    wrote it

% Basic setups
sDirMain = './';
sDirTmp = './TMP';
sDirGrads = './Visualize_ALL_vis_4_24_with_logsoft/AllRepeatsCutAndLabel';
% sDirNormMinusMaxGrads = fullfile( sDirMain, 'NormMinusMaxGradients' );
sDirMaxGrads = fullfile( sDirMain, 'MaxSignGradients' );
sDirNormMaxGrads = fullfile( sDirMain, 'NormMaxSignGradients' );
sDirResults = fullfile( sDirMain, 'Results_ActivityMaps' );
sDirPlots = fullfile( sDirMain, 'Plots_ActivityMaps' );
sDirPlotFinals = fullfile( sDirMain, 'Plots_Finals' );
csTasks = { 'EMOTION' 'GAMBLING' 'LANGUAGE' 'MOTOR' 'RELATIONAL' 'SOCIAL' 'WM' };

sTmpFileScript = mfilename( 'fullpath' );
sDirScript = fileparts( sTmpFileScript );

disp( 'step 1, get maxis' );
system( [ sDirScript, '/allsub_getGradsMaxSign', ' ', sDirGrads, ...
    ' ', sDirMaxGrads, ' ', sDirTmp ] );

disp( 'step 2, get 4mm smoothed surf of gradients' );
system( [ sDirScript, '/allsub_getGradsSurfS4', ' ', sDirNormMaxGrads, ' ', sDirTmp ] );
system( [ sDirScript, '/allsub_getGradNormMaxSignSurf', ...
    ' ', sDirMaxGrads, ' ', sDirNormMaxGrads, ' ', sDirTmp ] );

disp( 'step 3, get CohenD surfs of all Right surfs' );
sLstTasks = [ '(''', strjoin( csTasks, ''' '''), ''')' ];
system( [ 'Lst=', sLstTasks, '; ', sDirScript, '/allsub_getCohenDSurfRightS4', ...
    ' ', sDirNormMaxGrads, ' ', sDirResults, ' ', sDirTmp, ' ', '"${Lst[*]}"' ] ); % do the stat

disp( 'step 4, plot all these figures' );
plot_plotSurfs( sDirResults, sDirPlots, sDirTmp, [0.95 1] );
annot_annotSurfs( sDirResults, [0.95 1], 400 )% to annotate

disp( 'step 5, plot figures into one figure' );
allsub_plotIntoOne( sDirPlots, sDirPlotFinals );

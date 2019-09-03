#!/bin/bash
# To cut and label all repeats of one sub-task of one person
# plz replace the file pathes in basic setups with yours.
# 2018-05-13   Xiaoxiao     write it
# 2019-09-02   Xiaoxiao     modified, to add some comments

# basic setups
Dir_Inputs=(\
    "./HCP_Emotion_3T" \
    "./HCP_Language_3T" \
    "./HCP_Motor_3T" \
    "./HCP_Relational_3T" \
    "./HCP_WorkingMemory_3T" \
    "./HCP_Gambling_3T" \
    "./HCP_Social_3T") # folders for preprocessed HCP S1200 data of each task
Num_Dir_Inputs=${#Dir_Inputs[*]}
Dir_TMP=./tmp541 # a temporary folder
Dir_Output=./AllRepeatsCutAndLabel # folder for output
Lst_Measures="LR RL"
Key_Tests=("EMOTION" "LANGUAGE" "MOTOR" "RELATIONAL" "WM" "GAMBLING" "SOCIAL")
Key_TaskEVs=("fear" "present_story" "rh" "relation" "2bk_places" "loss" "mental")
Dig_TR_Sec=0.72
Dig_DurPostTask_Sec=8;

# go
for ((iTest = 0; iTest<$Num_Dir_Inputs; iTest++ ))
do
    Dir_Input=${Dir_Inputs[$iTest]}
    echo "Go into $Dir_Input"
    Lst_DataZips=$(ls -1 $Dir_Input/*.zip)

    for File_DataZip in $Lst_DataZips
    do
        for Key_Measure in $Lst_Measures
        do
            let Ind_TheTask=0
            echo $File_DataZip
            # reset the tmp folder
            rm -rf $Dir_TMP
            mkdir $Dir_TMP
            # Now get the key names of the file
            Nam_DataZip=$(basename $File_DataZip)
            Nam_Subject=$(echo $Nam_DataZip | cut -d '_' -f 1)

            # First Go unzip!
            unzip -oj $File_DataZip \
                $Nam_Subject/MNINonLinear/Results/tfMRI_${Key_Tests[$iTest]}_$Key_Measure/tfMRI_${Key_Tests[$iTest]}_$Key_Measure.nii.gz \
                $Nam_Subject/MNINonLinear/Results/tfMRI_${Key_Tests[$iTest]}_$Key_Measure/EVs/* \
                -d $Dir_TMP

            File_InputNii=$Dir_TMP/tfMRI_${Key_Tests[$iTest]}_$Key_Measure.nii.gz

            # get the number of timing
            Key_TaskEV=${Key_TaskEVs[$iTest]}
            let Num_Repeat=`cat $Dir_TMP/$Key_TaskEV.txt|wc -l`

            ## Go cut&label!
            for ((iRepeat = 1; iRepeat<=$Num_Repeat; iRepeat++ ))
            do
                let Ind_TheTask++
                # Get the timing
                echo "Reading $Key_TaskEV.txt"
                Dig_TaskBegin_Sec=`sed -n "$iRepeat, 1p" $Dir_TMP/$Key_TaskEV.txt|awk '{print $1}'`
                Dig_DurTask_Sec=`sed -n "$iRepeat, 1p" $Dir_TMP/$Key_TaskEV.txt|awk '{print $2}'`
                Num_DurTask_Ind=$(echo "scale=0;($Dig_DurTask_Sec+$Dig_DurPostTask_Sec)/$Dig_TR_Sec" |bc)
                # Get the volume indices
                Ind_TaskBegin=$(echo "scale=0;$Dig_TaskBegin_Sec/$Dig_TR_Sec" |bc)
                Ind_TaskEnd=$(echo "$Ind_TaskBegin+$Num_DurTask_Ind" |bc)
                # Do the cut
                3dTcat -prefix $Dir_Output/$Nam_Subject'_'${Key_Tests[$iTest]}'_'$Key_Measure-$(echo "$Ind_TheTask" |bc)'_'$(echo $Key_TaskEV | tr _ -).nii.gz \
                    $File_InputNii'['$Ind_TaskBegin'..'$Ind_TaskEnd']'

                # break # for debug
            done # for iRepeat
        done # for Key_Measure
        # break # for debug
    done # for File_DataZip
    # break # for debug
done # for iTest

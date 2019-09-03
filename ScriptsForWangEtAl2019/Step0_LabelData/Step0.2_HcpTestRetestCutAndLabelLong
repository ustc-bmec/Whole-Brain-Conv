#!/bin/bash
# To cut and label all repeats of test-retest one sub-task of one person
# plz replace the file pathes in basic setups with yours.
#
# 2018-10-15    Xiaoxiao    wrote it
# 2019-09-03    Xiaoxiao    add some comments

# basic setups
Dir_Inputs=(\
    "./HCP_Motor_3T" \
    "./HCP_WorkingMemory_3T" ) # folders for TEST dataset
Dir_Retests="./HCP_Retest" # folder for RETEST dataset
Num_Dir_Inputs=${#Dir_Inputs[*]}
Dir_TMP=./tmp547 # a temporary folder
Dir_Output=./AllTestRetestCutAndLabel
Lst_Measures="LR RL"
Key_Tests=("MOTOR" "WM")
Key_TaskEVs=("lf rf t lh" "0bk_body 2bk_body")
Dig_TR_Sec=0.72
Dig_DurPostTask_Sec=8;

# go
for ((iTest = 0; iTest<$Num_Dir_Inputs; iTest++ ))
do
    echo "Go into $Dir_Input"
    Lst_DataZips=$(ls -1 $Dir_Retests/*${Key_Tests[iTest]}*.zip)

    for File_DataZip in $Lst_DataZips
    do
        echo $File_DataZip

        # Now get the key names of the file
        Nam_DataZip=$(basename $File_DataZip)
        Nam_Subject=$(echo $Nam_DataZip | cut -d '_' -f 1)

        for Key_Retest in Test Retest
        do
            if [ ! -e ${Dir_Inputs[iTest]}/$Nam_DataZip ]; then
                continue
            fi # the Test file missing, continue

            if [ "$Key_Retest" == "Retest" ]; then
                Dir_Input=$Dir_Retests
            else
                Dir_Input=${Dir_Inputs[iTest]}
            fi
            File_Data=$Dir_Input/$Nam_DataZip

            for Key_Measure in $Lst_Measures
            do
                let Ind_TheTask=0

                # reset the tmp folder
                rm -rf $Dir_TMP
                mkdir $Dir_TMP

                # First Go unzip!
                unzip -oj $File_Data \
                    $Nam_Subject/MNINonLinear/Results/tfMRI_${Key_Tests[$iTest]}_$Key_Measure/tfMRI_${Key_Tests[$iTest]}_$Key_Measure.nii.gz \
                    $Nam_Subject/MNINonLinear/Results/tfMRI_${Key_Tests[$iTest]}_$Key_Measure/EVs/* \
                    -d $Dir_TMP

                File_InputNii=$Dir_TMP/tfMRI_${Key_Tests[$iTest]}_$Key_Measure.nii.gz

                # get the number of timing
                for Key_TaskEV in ${Key_TaskEVs[iTest]}
                do
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
                        if [ ! -e $Dir_Output/$Key_Retest/$Nam_Subject'_'${Key_Tests[iTest]}'_'$Key_Retest-$Key_Measure-$(echo "$Ind_TheTask" |bc)'_'$(echo $Key_TaskEV | tr _ -).nii ]; then
                            3dTcat -prefix $Dir_Output/$Key_Retest/$Nam_Subject'_'${Key_Tests[iTest]}'_'$Key_Retest-$Key_Measure-$(echo "$Ind_TheTask" |bc)'_'$(echo $Key_TaskEV | tr _ -).nii \
                                $File_InputNii'['$Ind_TaskBegin'..'$Ind_TaskEnd']'
                        fi # ! -e
                        # break # for debug
                    done # for iRepeat
                done # for key_TaskEV
              # break # for debug
            done # for Key_Measure
        done # for Key_Retest
      # break # for debug
    done # for File_DataZip
  # break # for debug
done # for iTest

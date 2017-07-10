#!/bin/bash
#PBS -N arrFPldaHiv
#PBS -l select=1:ncpus=8:mem=30gb,walltime=72:00:00
#PBS -J 1-70
#PBS -o /home/jsybran/jobLogs/pldaHIV.out
#PBS -e /home/jsybran/jobLogs/pldaHIV.err
#PBS -M jsybran@clemson.edu
#PBS -m ea

PATH=$PATH:/zfs/safrolab/users/jsybran/moliere/code/pipeline/tools

module load gcc mpich2/1.4-eth

DATA=/scratch2/jsybran/moliere/
DATA_DIR=$DATA/HIV_DATA_FILES
MODEL_DIR=$DATA/HIV_MODEL_FILES
VIEW_DIR=$DATA/HIV_VIEW_FILES

NUM_FILES=$(ls -f $DATA_DIR | wc -l)
#echo "There are $NUM_FILES files in the data dir."
NUM_NEW_FILES=$(for f in $(ls -f $DATA_DIR/); do if [ ! -f $VIEW_DIR/$f ]; then echo $f; fi; done | wc -l)
echo "$NUM_NEW_FILES have not yet been processed"

JOB_RANGE=$(($NUM_NEW_FILES/100 + 1))
#START=$(($PBS_ARRAY_INDEX * $JOB_RANGE))
#END=$((($PBS_ARRAY_INDEX+1) * $JOB_RANGE))
COUNT=0

#echo "This job is responsible for files $START - $END"

for f in $(ls -f $DATA_DIR/); do
  if [ $f != '.' ] && [ $f != '..' ] && [ ! -f $VIEW_DIR/$f ]; then
    COUNT=$(($COUNT+1))
    #if [ $COUNT -lt $END ] && [ $COUNT -ge $START ]; then
      #echo "$COUNT $f"
      echo "Model for $f does not exist"
      in=$DATA_DIR/$f
      out=$MODEL_DIR/$f
      mpiexec -n 8 mpi_lda --num_topics 100 \
                           --alpha 1 \
                           --beta 0.01 \
                           --training_data_file $in \
                           --model_file $out \
                           --total_iterations 100 \
                           --burn_in_iterations 50 \
                           > /dev/null 2>&1
      #echo "Created Model for $f"
      view_model.py "$MODEL_DIR/$f"'_0' $VIEW_DIR/$f
      #echo "Created view"
    fi
  #fi
done
#!/bin/bash
nChannels=15
increment=1
# Loop through channels
for (( ch=1; ch<=$nChannels; ch=$ch+1 )); do
	echo $ch
	sbatch --job-name="${ch}_multidose" --output="logs/multidose_${ch}.out" --error="logs/multidose_${ch}.err" sbatch_hctsa_2_multidose.bash $ch
	echo "submitted channel ${ch}"
done

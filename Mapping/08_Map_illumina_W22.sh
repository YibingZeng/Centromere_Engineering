#Download the W22 genome
wget https://download.maizegdb.org/Zm-W22-REFERENCE-NRGENE-2.0/Zm-W22-REFERENCE-NRGENE-2.0.fa.gz
#Create the 100k window
ml BWA/0.7.17-GCCcore-11.3.0
cd /scratch/yz77862/MaizeGenome
#it is impossible to build fai index for W22 genome assembly, so I download their fai in maizegdb by following command
# wget https://download.maizegdb.org/Zm-W22-REFERENCE-NRGENE-2.0/Zm-W22-REFERENCE-NRGENE-2.0.chr_scaffolds.fa.gz.fai
#bwa index Zm-W22-REFERENCE-NRGENE-2.0.fa

#Get the genome index file
ml BEDTools
head Zm-W22-REFERENCE-NRGENE-2.0.chr_scaffolds.fa.gz.fai > W22_genome.size
bedtools makewindows -g W22_genome.size -w 100000 > W22_100k_win.bed


mkdir -p /scratch/yz77862/illumina_neo4Ls/shell_W22
mkdir -p /scratch/yz77862/illumina_neo4Ls/output/W22/SAM
mkdir -p /scratch/yz77862/illumina_neo4Ls/output/W22/BAM
mkdir -p /scratch/yz77862/illumina_neo4Ls/output/W22/BAMQ20
mkdir -p /scratch/yz77862/illumina_neo4Ls/output/W22/TDF
mkdir -p /scratch/yz77862/illumina_neo4Ls/output/W22/genomecov
list=/scratch/yz77862/illumina_neo4Ls/data/list
while read i; do
out=/scratch/yz77862/illumina_neo4Ls/shell_W22/${i}_mapping.sh
echo '#!/bin/bash' >> ${out}
echo "#SBATCH --job-name=map_${i}" >> ${out}                  
echo "#SBATCH --partition=batch">> ${out}  		                            
echo "#SBATCH --ntasks=1">> ${out}  			                            
echo "#SBATCH --cpus-per-task=4">> ${out}  		                       
echo "#SBATCH --mem=200gb">> ${out}  			                               
echo "#SBATCH --time=48:00:00">> ${out}    		                          
echo "#SBATCH --output=map_${i}.out">> ${out}  			  
echo "#SBATCH --error=map_${i}.err">> ${out}  
echo " " >> ${out}  
echo "ml BWA/0.7.17-GCCcore-11.3.0" >> ${out}  
echo "ml BEDTools/2.29.2-GCC-8.3.0" >> ${out}  
echo "ml SAMtools/1.16.1-GCC-11.3.0" >> ${out}  
echo "ml IGV/2.16.1-Java-11" >> ${out} 
echo " #The trimmed fastq files " >> ${out}
echo "fastq1=/scratch/yz77862/illumina_neo4Ls/data/${i}_R1_001_val_1.fq.gz" >> ${out} 
echo "fastq2=/scratch/yz77862/illumina_neo4Ls/data/${i}_R2_001_val_2.fq.gz" >> ${out} 
echo "#The genome file  " >> ${out}
echo "genome=/scratch/yz77862/MaizeGenome/Zm-W22-REFERENCE-NRGENE-2.0.fa" >> ${out}
echo "#The windows files  " >> ${out}
echo "win_100k=/scratch/yz77862/MaizeGenome/W22_100k_win.bed" >> ${out} 
echo " #The output file lists " >> ${out}
echo "SAM=/scratch/yz77862/illumina_neo4Ls/output/W22/SAM" >> ${out}
echo "BAM=/scratch/yz77862/illumina_neo4Ls/output/W22/BAM" >> ${out}
echo "BAMQ20=/scratch/yz77862/illumina_neo4Ls/output/W22/BAMQ20 " >> ${out}
echo "TDF=/scratch/yz77862/illumina_neo4Ls/output/W22/TDF" >> ${out}
echo "genomecov=/scratch/yz77862/illumina_neo4Ls/output/W22/genomecov" >> ${out}
echo "bwa mem \${genome} \${fastq1} \${fastq2} -M -t 24  > \${SAM}/${i}_ABS.sam" >> ${out}  
echo "samtools view -b -F 4 -S \${SAM}/${i}_ABS.sam -o \${BAM}/${i}_ABS.bam" >> ${out}  
echo "samtools sort -o \${BAM}/${i}_ABS.sorted.bam \${BAM}/${i}_ABS.bam" >> ${out}    
echo "samtools view -q 20 -o \${BAMQ20}/${i}_ABS.sorted_q20.bam \${BAM}/${i}_ABS.sorted.bam" >> ${out}  
echo "samtools index \${BAM}/${i}_ABS.bam" >> ${out}  
echo "samtools index \${BAMQ20}/${i}_ABS.sorted_q20.bam" >> ${out}  
echo "flagstat=/scratch/yz77862/illumina_neo4Ls/output/W22/flagstat_result.txt" >> ${out}  
echo "touch \${flagstat}" >> ${out}  
echo "echo '\${BAM}/${i}_ABS.sorted.bam' >> \${flagstat}" >> ${out}  
echo "samtools flagstat \${BAM}/${i}_ABS.sorted.bam >> \${flagstat}" >> ${out}  
echo "echo '\${BAMQ20}/${i}_ABS.sorted_q20.bam' >> \${flagstat}" >> ${out}  
echo "samtools flagstat \${BAMQ20}/${i}_ABS.sorted_q20.bam >> \${flagstat}" >> ${out}  
echo "igvtools count -w 100000 \${BAMQ20}/${i}_ABS.sorted_q20.bam \${TDF}/${i}_ABS.sorted_q20.100Kb.tdf \${genome}" >> ${out} 
echo "  " >> ${out}
echo "bedtools genomecov -ibam  \${BAMQ20}/${i}_ABS.sorted_q20.bam -bg | awk '{print \$0,(\$3-\$2)*\$4}' OFS=\"\\t\" > \${genomecov}/${i}_q20_genomecov.bed" >> ${out}
echo "bedtools intersect -wa -wb -a \${win_100k} -b \${genomecov}/${i}_q20_genomecov.bed | bedtools groupby -c 8 -o sum > \${genomecov}/${i}_win_100k_q20_genomecov.bed1" >> ${out}
echo " " >> ${out} 
echo "bedtools intersect -wa -wb -a \${win_100k} -b \${genomecov}/${i}_q20_genomecov.bed -v | awk '{print \$1,\$2,\$3,0}' OFS=\"\\t\" > \${genomecov}/${i}_win_100k_q20_genomecov.bed2" >> ${out} 
echo " " >> ${out} 
echo "cat \${genomecov}/${i}_win_100k_q20_genomecov.bed1 \${genomecov}/${i}_win_100k_q20_genomecov.bed2 | sort -b -k1,1 -k2,2n -k3,3n > \${genomecov}/${i}_win_100k_q20_genomecov.bed" >> ${out} 
echo "rm \${genomecov}/${i}_win_100k_q20_genomecov.bed1 \${genomecov}/${i}_win_100k_q20_genomecov.bed2" >> ${out} 
done < <(cut -f1 ${list} | grep -v 'skip' | sort -u)
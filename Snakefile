configfile: "config.yaml"

SAMPLES = ["BAM1_PREFIX","BAM2_PREFIX","BAM3_PREFIX"]
outPath = config["outPath"]
bamPath = config["bamPath"]
cramPath = config["cramPath"]


rule all:
   input:
        expand(outPath + "filter/{sample}.bed", sample=SAMPLES),
        expand(outPath + "confirmed/{sample}.retroseqHitsConfirmed.bed",sample=SAMPLES)

rule CramToBam:
    input:
        cram_file=cramPath + "{sample}.cram"
    output:
        bamPath + "{sample}.bam",
        bamPath + "{sample}.bam.bai"
    benchmark:
        "benchmarks/{sample}.CramToBam.benchmark.tsv"
    conda:
        "envs/sam_only.yaml"
    threads: 4
    resources:
        mem_mb=16000,
    shell:
        """
        samtools view -b -h -@ {threads} -T {config[refHg19]} -o {output[0]} {input.cram_file}
        samtools index -@ {threads} {output[0]}
        """

rule retroseqDiscover:
    input:
        bamPath + "{sample}.bam",
        bamPath + "{sample}.bam.bai"
    output:
        outPath + "discover/{sample}.bed"
    threads: 8
    log:
        "logs/discover/{sample}.log"
    
    params:
        identity=80
    benchmark:
       #repeat("benchmarks/{sample}.retroseqDiscover.benchmark.txt",3)
       "benchmarks/{sample}.retroseqDiscover.benchmark.txt"
    conda:
       "envs/retroseq.yaml"
    shell:
        "retroseq.pl -discover -bam {input[0]} -output {output} -eref {config[HERVK_eref]} -id {params.identity}"
 
rule retroseqCall:
    input:
        bam=bamPath + "{sample}.bam",
        bai=bamPath + "{sample}.bam.bai",
        discover=outPath + "discover/{sample}.bed"
    output:
        outPath + "call/{sample}.vcf"
    threads: 8
    benchmark:
       "benchmarks/{sample}.retroCall.benchmark.txt"
    conda:
       "envs/retroseq.yaml"
    log:
        "logs/call/{sample}.log"
    shell:
        "retroseq.pl -call -bam {input.bam} -input {input.discover} -ref {config[refHg19]} -output {output}"

rule filterCalls:
   input:
      outPath + "call/{sample}.vcf"
   output:
      outPath + "filter/{sample}.pos",
      outPath + "filter/{sample}.bed"
   log:
        "logs/filter/{sample}.log"
   benchmark:
       "benchmarks/{sample}.filterCalls.benchmark.txt"
   shell:
       "python {config[pythonScripts]}/filterHighQualRetroseqForDownstream.py  {input} {output}"


rule verify:
    input:
      outPath + "filter/{sample}.pos",
      bamPath + "{sample}.bam",
      bamPath + "{sample}.bam.bai"
    output:
      outPath + "confirmed/{sample}.retroseqHitsConfirmed.bed"
    benchmark:
      "benchmarks/{sample}.verify.tsv"
    params:
        verificationLevel="low"
    conda:
       "envs/verification.yaml"
    log:
        "logs/call/{sample}.log"
    shell:
      """
      python {config[pythonScripts]}/assembleAndRepeatMasker.py {input[0]} {config[bamPath]}{wildcards.sample}.bam {config[outPath]} {config[RepeatMaskerPath]} {config[pythonScripts]} {config[element]} {params.verificationLevel} {output} 
      """ 

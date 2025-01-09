include { DOWNLOAD_SRA                         } from '../../modules/local/local'
include { DATASETS_DOWNLOAD as DOWNLOAD_GENOME } from '../../modules/local/datasets'

workflow TEST {
    take:
    ch_sra_accessions
    ch_genome_accessions

    main:
    ch_versions = Channel.empty()

    if ( ! params.sra_accessions.isEmpty()  || ! params.genome_accessions.isEmpty() ) {
        DOWNLOAD_SRA(ch_sra_accessions)
        //ch_versions = ch_versions.mix(DOWNLOAD_SRA.out.versions.first())

        DOWNLOAD_SRA.out.fastq
            .map { it ->
                def meta = [id:it[0]] 
                tuple( meta, [file(it[1][0]), file(it[1][1])])
            }
            .set { ch_fastq }
    } else {
        ch_fastq = Channel.empty()
    }

    if ( ! params.genome_accessions.isEmpty() ) {
        DOWNLOAD_GENOME(ch_genome_accessions.collectFile(name: 'ids.csv', newLine: true))
        ch_versions = ch_versions.mix(DOWNLOAD_GENOME.out.versions.first())

        DOWNLOAD_GENOME.out.genomes
            .flatten()
            .map { it ->
                def meta = [id:it.baseName]
                tuple( meta, it)
            }
            .set { ch_fasta }
    } else {
        ch_fasta    = Channel.empty()
    }

    emit:
    fastq   = ch_fastq
    fasta    = ch_fasta
    versions = ch_versions
}
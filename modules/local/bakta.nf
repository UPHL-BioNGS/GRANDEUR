process BAKTA {
  tag           "${meta.id}"
  label         "process_high"
  container     'staphb/bakta:1.9.4-5.1-light'

  input:
  tuple val(meta), file(contigs), val(organism)

  output:
  path "bakta/*/*"                  , emit: prokka_files
  path "bakta/*/*.txt"              , emit: for_multiqc
  path "gff/*.gff"                  , emit: gff, optional: true
  path "logs/${task.process}/*.log" , emit: log
  tuple val(meta)                   , emit: meta
  path "versions.yml"               , emit: versions

  when:
  task.ext.when == null || task.ext.when

  script:
  def args   = task.ext.args   ?: '--mincontiglen 500 --compliant'
  def prefix = task.ext.prefix ?: "${meta.id}"
  def gen_sp = organism ? "--genus ${organism[0]} --species ${organism[1]}" : ""
  """
    mkdir -p bakta gff logs/${task.process}
    log_file=logs/${task.process}/${prefix}.${workflow.sessionId}.log

    bakta ${args} \
      --threads ${task.cpus} \
      --output bakta \
      --prefix ${prefix} \
      ${gen_sp} \
      --force ${contigs} \
      | tee -a \$log_file

    cp bakta/${prefix}/${prefix}.gff gff/${prefix}.gff

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
      bakta: \$(echo \$(bakta --version ) | awk '{print \$2}')
    END_VERSIONS
  """
}

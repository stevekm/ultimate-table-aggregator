params.filtered_tsvs = "variant_paths.txt"
params.output_dir = "output"
Channel.fromPath( file(params.filtered_tsvs) )
    .splitCsv()
    .map { items ->
        File dirname = new File(items[0]).getParentFile()
        def item_file = file(items[0])

        // parse header comment
        def lines = new File(items[0]).readLines().grep(~/^#.*/)
        lines = lines.collect { "${it}".replaceFirst(/^##/, "") }
        def fileparams = lines.collect { "${it}".tokenize('=') }

        return [ dirname, item_file, fileparams ]
    }
    .set { filtered_tsvs }
    // .subscribe { println "${it}" }

process add_params {
    publishDir "${params.output_dir}", overwrite: true, mode: 'copy'
    publishDir "${path}", overwrite: true, mode: 'copy'

    input:
    set val(path), file(filtered_tsv), val(fileparams) from filtered_tsvs

    output:
    file("${output_file}") into updated_tsvs

    script:
    output_file = "${filtered_tsv}".replaceFirst(/.tsv$/, ".headercols.tsv")
    param_string = fileparams.collect { "paste-col.py --header '${it[0]}' -v '${it[1]}' --doublequote" }.join(" | ")
    """
    cat "${filtered_tsv}" | \
    grep -v '^#' | \
    ${param_string} | \
    paste-col.py --header 'Source' -v '${filtered_tsv}' --doublequote \
    > "${output_file}"
    """
}
//
// process collect_tables {
//     publishDir "${params.output_dir}", overwrite: true, mode: 'copy'
//
//     input:
//     file('table*') from updated_tsvs.collect()
//
//     output:
//     file("${output_file}")
//
//     script:
//     output_file = 'Oncomine_all_filtered_annotations.tsv'
//     """
//     concat-tables.py * > "${output_file}"
//     """
// }

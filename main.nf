params.input_tsvs = "variant_paths.txt"
params.output_dir = "output"

Channel.fromPath( file(params.input_tsvs) )
    .splitCsv() // read in the list of files to be processed
    .map { items ->
        // file's parent directory
        File dirname = new File(items[0]).getParentFile()
        // create 'file' object for Nextflow from path
        def item_file = file(items[0])

        // parse header comment into params for later, split into arrays
        def lines = new File(items[0]).readLines().grep(~/^#.*/)
        lines = lines.collect { "${it}".replaceFirst(/^##/, "") }
        def fileparams = lines.collect { "${it}".tokenize('=') }

        return [ dirname, item_file, fileparams ]
    }
    .set { input_tsvs }
    // .subscribe { println "${it}" } // to print channel to console

// Add the extra parameters from the header as new columns in the table
process add_params {
    // save a copy of the output next to the original file
    publishDir "${path}", overwrite: true, mode: 'copy'

    input:
    set val(path), file(filtered_tsv), val(fileparams) from input_tsvs

    output:
    file("${output_file}") into updated_tsvs

    script:
    output_file = "${filtered_tsv}".replaceFirst(/.tsv$/, ".headercols.tsv")
    // create character string with commands for adding params as columns
    param_string = fileparams.collect { "paste-col.py --header '${it[0]}' -v '${it[1]}' --doublequote" }.join(" | ")
    """
    # strip the header lines from the table, then add the extra params as new columns
    # add the original filename as an extra column as well
    cat "${filtered_tsv}" | \
    grep -v '^#' | \
    ${param_string} | \
    paste-col.py --header 'Source' -v '${filtered_tsv}' --doublequote \
    > "${output_file}"
    """
}

process collect_tables {
    // output to the 'output' directory
    publishDir "${params.output_dir}", overwrite: true, mode: 'copy'

    input:
    file('t*') from updated_tsvs.collect()

    output:
    file("${output_file}")

    script:
    output_file = 'all_variants.tsv'
    """
    concat-tables.py * > "${output_file}"
    """
}

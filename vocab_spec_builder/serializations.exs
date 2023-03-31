Mix.install([
  {:rdf, "~> 1.1"},
  {:rdf_xml, "~> 1.0"},
])

{vocab_file, outputs} =
  case System.argv() do
    [vocab_file | outputs] -> {vocab_file, outputs}
    [] -> "missing input file"
  end

vocab_graph = RDF.read_file!(vocab_file)

Enum.each(outputs, &RDF.write_file!(vocab_graph, &1, force: true))


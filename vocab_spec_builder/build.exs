Mix.install([
  {:rtc, path: "../src/rtc"},
  {:rdf, "~> 1.0"}

])

defmodule VocabSpec do
  alias RDF.{Description, Graph}
  alias RDF.NS.{RDFS, OWL}

  @ontology RTC.NS.RTC.__base_iri__()

  @classes [
    RTC.NS.RTC.Compound
  ]

  @properties [
    RTC.elementOf(),
    RTC.elements(),
    RTC.subCompoundOf()
  ]

  def build(vocab) do
    check_unspecified_resources!(vocab)

    """
    ## Classes ## {#classes}

    #{Enum.map_join(@classes, &class_spec(vocab[&1], vocab))}


    ## Properties ## {#properties}

    #{Enum.map_join(@properties, &property_spec(vocab[&1], vocab))}

    """
  end

  defp check_unspecified_resources!(vocab) do
    unspecified_resources = Graph.delete_subjects(vocab, [@ontology | @classes ++ @properties])

    unless Enum.empty?(unspecified_resources) do
      raise "vocab contains unspecified resources: #{inspect(unspecified_resources)}"
    end
  end

  defp spec_table(description, additional_defs) do
    name = Description.first(description, RDFS.label()) |> to_string()
    underscored_name = underscored_name(name)

    """
    <table class="def">
      <tr>
        <th>Name: </th>
        <td>
          <dfn data-dfn-type="property" data-export="" id="def-#{underscored_name}" dfn>
            #{name}
            <a class="self-link" href="#def-#{underscored_name}"></a>
          </dfn>
        </td>
      </tr>
      <tr>
        <th>URI: </th>
        <td>`#{description.subject}`</td>
      </tr>
      <tr>
        <th>Description: </th>
        <td>#{Description.first(description, RDFS.comment())}</td>
      </tr>
      #{additional_defs}
    </table>
    """
  end

  def class_spec(description, vocab) do
    in_domain_of =
      Graph.query(vocab, {:property?, RDFS.domain(), description.subject})
      |> Enum.map(& &1[:property])
      |> Enum.map(&link(&1, vocab))
      |> Enum.join(", ")

    in_range_of =
      Graph.query(vocab, {:property?, RDFS.range(), description.subject})
      |> Enum.map(& &1[:property])
      |> Enum.map(&link(&1, vocab))
      |> Enum.join(", ")

    spec_table(
      description,
      """
      <tr>
        <th style="width:6em">In domain of: </th>
        <td>#{in_domain_of}</td>
      </tr>
      <tr>
        <th style="width:6em">In range of: </th>
        <td>#{in_range_of}</td>
      </tr>
      """
    )
  end

  def property_spec(description, vocab) do
    spec_table(
      description,
      """
      <tr>
        <th>Domain: </th>
        <td>#{Description.first(description, RDFS.domain()) |> link(vocab)}</td>
      </tr>
      <tr>
        <th>Range: </th>
        <td>#{Description.first(description, RDFS.range()) |> link(vocab)}</td>
      </tr>
      <tr>
        <th>Inverse of: </th>
        <td>#{Description.first(description, OWL.inverseOf()) |> link(vocab)}</td>
      </tr>
      """
    )
  end

  defp underscored_name(name) do
    name
    |> Macro.underscore()
    |> String.replace(" ", "_")
  end

  defp link(nil, _), do: "-"

  defp link(iri, vocab) do
    name =
      vocab[iri]
      |> Description.first(RDFS.label())
      |> to_string()

    "[=#{name}=]"
  end
end

{vocab_file, output_file} =
  case System.argv() do
    [vocab_file, output_file] -> {vocab_file, output_file}
    [] -> "missing output file"
  end

spec =
  vocab_file
  |> RDF.Turtle.read_file!()
  |> VocabSpec.build()

File.write!(output_file, spec)

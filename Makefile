bikeshed = env/bin/bikeshed
build_vocab_spec = vocab_spec_builder/build.exs
build_vocab_serializations = vocab_spec_builder/serializations.exs

objects = index.html
vocab = vocab/rtc.ttl
local_vocab_src = ../rtc-ex/priv/vocabs/rtc.ttl

all : index.html serializations

index.html : index.bs vocab_spec.bs
	${bikeshed} spec $<

vocab_spec.bs : $(vocab) $(build_vocab_spec) $(vocab)
	elixir $(build_vocab_spec) $< $@

serializations: $(vocab)
	elixir $(build_vocab_serializations) $< vocab/rtc.nt vocab/rtc.rdf

# This can be used when you have the vocab at another place locally.
# You'll need to adapt local_vocab_src to your setup.
update_vocab :
	@test -f $(local_vocab_src) && cp -v $(local_vocab_src) $(vocab)

watch : all
	${bikeshed} watch index.bs
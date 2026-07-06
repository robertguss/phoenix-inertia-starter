# Dialyzer warning filters. Keep each entry scoped as tightly as possible so real
# warnings in our own code still fail the gate.
[
  # `use Phoenix.Router` generates the dispatch match (`__match_route__`) inside our
  # router. In the test env (dev_routes off, /api scope still empty) there are no
  # reachable routes yet, so the generated 4-tuple match branch is unreachable and
  # dialyzer reports it against Phoenix's macro source. Scoped to that one framework
  # file + warning type; real router warnings still surface.
  # ponytail: empty-router false positive — remove once real routes exist (U4+).
  {"deps/phoenix/lib/phoenix/router.ex", :pattern_match}
]

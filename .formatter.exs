# KTD10: Spark.Formatter is the only formatter plugin (Styler deliberately omitted).
# It sorts Ash/Spark DSL sections per the `config :spark, formatter:` config.
[
  import_deps: [
    :ash_admin,
    :ash_authentication,
    :ash_json_api,
    :ash_oban,
    :ash_phoenix,
    :ash_postgres,
    :ecto,
    :ecto_sql,
    :oban,
    :phoenix
  ],
  plugins: [Spark.Formatter],
  subdirectories: ["priv/*/migrations"],
  inputs: ["*.{ex,exs}", "{config,lib,test}/**/*.{ex,exs}", "priv/*/seeds.exs", "bin/*"]
]

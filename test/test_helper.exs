ExUnit.start()
Ecto.Adapters.SQL.Sandbox.mode(StarterKit.Repo, :manual)

# Mimic (R17): mark modules that tests may mock. `Mimic.copy/1` must run before
# any stubbing. Tests stub/expect on StarterKit.Mailer to simulate delivery
# failures without sending real mail.
Mimic.copy(StarterKit.Mailer)

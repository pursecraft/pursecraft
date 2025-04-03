{:ok, _app} = Application.ensure_all_started(:ex_machina)
ExUnit.start()
Ecto.Adapters.SQL.Sandbox.mode(PurseCraft.Repo, :manual)
Faker.start()
